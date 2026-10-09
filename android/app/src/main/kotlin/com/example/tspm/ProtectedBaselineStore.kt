package com.example.tspm

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.system.ErrnoException
import android.system.Os
import android.system.OsConstants
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileDescriptor
import java.io.IOException
import java.nio.ByteBuffer
import java.nio.charset.CharacterCodingException
import java.nio.charset.CodingErrorAction
import java.security.GeneralSecurityException
import java.security.KeyStore
import java.util.concurrent.Executors
import javax.crypto.AEADBadTagException
import javax.crypto.BadPaddingException
import javax.crypto.Cipher
import javax.crypto.IllegalBlockSizeException
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

internal enum class WriteStage {
    AFTER_PENDING_SYNC, BEFORE_RENAME, AFTER_RENAME, BEFORE_DIRECTORY_SYNC, BEFORE_VERIFICATION
}

internal class StorageFailure(
    val code: String,
    val writeOutcome: String? = null,
    val unsupportedVersion: Int? = null,
) : Exception(code)

class ProtectedBaselineStore internal constructor(
    private val directory: File,
    private val keyAlias: String,
    private val fault: (WriteStage) -> Unit = {},
) {
    constructor(context: Context) : this(context.noBackupFilesDir, "tspm.protected-baseline.v1")

    private val base = File(directory, "tspm-baseline.bin")
    private val pending = File(directory, "tspm-baseline.bin.pending")
    private var channel: MethodChannel? = null

    fun read(): String? = synchronized(accessLock) {
        try {
            readCommitted()
        } catch (failure: StorageFailure) {
            throw failure
        } catch (_: Exception) {
            throw StorageFailure("io")
        }
    }

    fun replace(expectedJson: String?, nextJson: String): Unit = synchronized(accessLock) {
        var renamed = false
        try {
            if (readCommitted() != expectedJson) throw StorageFailure("conflict")
            val candidate = encrypt(nextJson)
            // A stale pending alias must never let a write open/truncate the committed base.
            if (entryExists(pending)) Os.remove(pending.absolutePath)
            withDescriptor(
                pending,
                OsConstants.O_WRONLY or OsConstants.O_CREAT or OsConstants.O_EXCL or
                    OsConstants.O_NOFOLLOW,
                0x180, // 0600: owner read/write only.
            ) { descriptor ->
                var offset = 0
                while (offset < candidate.size) {
                    val count = Os.write(descriptor, candidate, offset, candidate.size - offset)
                    if (count <= 0) throw IOException("Incomplete protected write")
                    offset += count
                }
                descriptor.sync()
            }
            fault(WriteStage.AFTER_PENDING_SYNC)
            fault(WriteStage.BEFORE_RENAME)
            Os.rename(pending.absolutePath, base.absolutePath)
            renamed = true
            fault(WriteStage.AFTER_RENAME)
            fault(WriteStage.BEFORE_DIRECTORY_SYNC)
            withDirectory { Os.fsync(it) }
            fault(WriteStage.BEFORE_VERIFICATION)
            val actual = readContainer()
            if (!actual.contentEquals(candidate)) throw StorageFailure("io")
            if (decrypt(actual) != nextJson) throw StorageFailure("io")
        } catch (failure: StorageFailure) {
            throw StorageFailure(
                failure.code,
                if (renamed) "unknown" else "notCommitted",
                failure.unsupportedVersion,
            )
        } catch (_: Exception) {
            throw StorageFailure("io", if (renamed) "unknown" else "notCommitted")
        }
    }

    fun register(messenger: BinaryMessenger) {
        close()
        val main = Handler(Looper.getMainLooper())
        channel = MethodChannel(messenger, "tspm/protected_baseline").also { registered ->
            registered.setMethodCallHandler { call, result ->
                if (call.method != "read" && call.method != "replace") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                executor.execute {
                    try {
                        val value = when (call.method) {
                            "read" -> read()
                            else -> {
                                val arguments = call.arguments as? Map<*, *>
                                val expected = arguments?.get("expectedJson")
                                val next = arguments?.get("nextJson")
                                if (arguments == null || !arguments.containsKey("expectedJson") ||
                                    (expected != null && expected !is String) || next !is String
                                ) throw StorageFailure("io", "notCommitted")
                                replace(expected as String?, next)
                                null
                            }
                        }
                        main.post { result.success(value) }
                    } catch (failure: StorageFailure) {
                        val details = mutableMapOf<String, Any>()
                        failure.writeOutcome?.let { details["writeOutcome"] = it }
                        failure.unsupportedVersion?.let { details["unsupportedVersion"] = it }
                        main.post {
                            result.error(
                                failure.code,
                                "Protected storage operation failed.",
                                details.takeIf { it.isNotEmpty() },
                            )
                        }
                    } catch (_: Exception) {
                        main.post {
                            result.error(
                                "io", "Protected storage operation failed.",
                                if (call.method == "replace") mapOf("writeOutcome" to "unknown") else null,
                            )
                        }
                    }
                }
            }
        }
    }

    fun close() {
        channel?.setMethodCallHandler(null)
        channel = null
        // The process-wide queue also serializes an old Activity's outstanding work
        // with a new Activity's channel; disposing a channel must not cancel a save.
    }

    private fun readCommitted(): String? {
        // Open and close the actual parent: File.exists alone hides inaccessible paths.
        withDirectory { }
        if (!entryExists(base)) return null
        return decrypt(readContainer())
    }

    private fun entryExists(file: File): Boolean = try {
        Os.lstat(file.absolutePath)
        true
    } catch (failure: ErrnoException) {
        if (failure.errno == OsConstants.ENOENT) false else throw failure
    }

    private fun readContainer(): ByteArray = withDescriptor(
        base, OsConstants.O_RDONLY or OsConstants.O_NOFOLLOW,
    ) { descriptor ->
        val stat = Os.fstat(descriptor)
        if (!OsConstants.S_ISREG(stat.st_mode)) throw StorageFailure("io")
        if (stat.st_size < HEADER_SIZE + IV_SIZE + TAG_SIZE || stat.st_size > MAX_CONTAINER_SIZE) {
            throw StorageFailure("corrupt")
        }
        val bytes = ByteArray(stat.st_size.toInt())
        var offset = 0
        while (offset < bytes.size) {
            val count = Os.read(descriptor, bytes, offset, bytes.size - offset)
            if (count <= 0) throw StorageFailure("corrupt")
            offset += count
        }
        if (Os.read(descriptor, ByteArray(1), 0, 1) != 0) throw StorageFailure("corrupt")
        bytes
    }

    private fun encrypt(json: String): ByteArray {
        val plaintext = try {
            val encoded = Charsets.UTF_8.newEncoder()
                .onMalformedInput(CodingErrorAction.REPORT)
                .onUnmappableCharacter(CodingErrorAction.REPORT)
                .encode(java.nio.CharBuffer.wrap(json))
            ByteArray(encoded.remaining()).also { encoded.get(it) }
        } catch (_: CharacterCodingException) {
            throw StorageFailure("io")
        }
        if (plaintext.size > MAX_CONTAINER_SIZE - HEADER_SIZE - IV_SIZE - TAG_SIZE) {
            throw StorageFailure("io")
        }
        val key = key(allowCreate = !entryExists(base) && !entryExists(pending))
        try {
            val cipher = Cipher.getInstance("AES/GCM/NoPadding")
            cipher.init(Cipher.ENCRYPT_MODE, key)
            val iv = cipher.iv
            if (iv.size != IV_SIZE) throw StorageFailure("keyUnavailable")
            val header = ByteBuffer.allocate(HEADER_SIZE)
                .put(MAGIC).put(FORMAT_VERSION.toByte()).put(iv.size.toByte())
                .putInt(cipher.getOutputSize(plaintext.size)).array()
            authenticate(cipher, header, iv)
            return header + iv + cipher.doFinal(plaintext)
        } catch (_: GeneralSecurityException) {
            throw StorageFailure("keyUnavailable")
        } finally {
            plaintext.fill(0)
        }
    }

    private fun decrypt(bytes: ByteArray): String {
        if (bytes.size < HEADER_SIZE + IV_SIZE + TAG_SIZE ||
            !bytes.copyOfRange(0, MAGIC.size).contentEquals(MAGIC)
        ) throw StorageFailure("corrupt")
        val version = bytes[MAGIC.size].toInt() and 0xff
        if (version != FORMAT_VERSION) throw StorageFailure("unsupportedVersion", unsupportedVersion = version)
        val ivSize = bytes[MAGIC.size + 1].toInt() and 0xff
        val ciphertextSize = ByteBuffer.wrap(bytes, MAGIC.size + 2, 4).int
        if (ivSize != IV_SIZE || ciphertextSize < TAG_SIZE ||
            ciphertextSize != bytes.size - HEADER_SIZE - ivSize
        ) throw StorageFailure("corrupt")
        val header = bytes.copyOfRange(0, HEADER_SIZE)
        val iv = bytes.copyOfRange(HEADER_SIZE, HEADER_SIZE + ivSize)
        val key = key(allowCreate = false)
        val plaintext = try {
            val cipher = Cipher.getInstance("AES/GCM/NoPadding")
            cipher.init(Cipher.DECRYPT_MODE, key, GCMParameterSpec(TAG_SIZE * 8, iv))
            authenticate(cipher, header, iv)
            cipher.doFinal(bytes, HEADER_SIZE + ivSize, ciphertextSize)
        } catch (_: AEADBadTagException) {
            throw StorageFailure("corrupt")
        } catch (_: BadPaddingException) {
            throw StorageFailure("corrupt")
        } catch (_: IllegalBlockSizeException) {
            throw StorageFailure("corrupt")
        } catch (_: GeneralSecurityException) {
            throw StorageFailure("keyUnavailable")
        }
        try {
            return Charsets.UTF_8.newDecoder()
                .onMalformedInput(CodingErrorAction.REPORT)
                .onUnmappableCharacter(CodingErrorAction.REPORT)
                .decode(ByteBuffer.wrap(plaintext)).toString()
        } catch (_: CharacterCodingException) {
            throw StorageFailure("corrupt")
        } finally {
            plaintext.fill(0)
        }
    }

    private fun authenticate(cipher: Cipher, header: ByteArray, iv: ByteArray) {
        cipher.updateAAD(STORE_ID)
        cipher.updateAAD(header)
        cipher.updateAAD(iv)
    }

    private fun key(allowCreate: Boolean): SecretKey {
        try {
            val store = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
            if (store.containsAlias(keyAlias)) {
                return store.getKey(keyAlias, null) as? SecretKey ?: throw StorageFailure("keyUnavailable")
            }
            if (!allowCreate) throw StorageFailure("keyUnavailable")
            return KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore").apply {
                init(
                    KeyGenParameterSpec.Builder(
                        keyAlias, KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT,
                    ).setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                        .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                        .setKeySize(256).setRandomizedEncryptionRequired(true).build(),
                )
            }.generateKey()
        } catch (failure: StorageFailure) {
            throw failure
        } catch (_: Exception) {
            throw StorageFailure("keyUnavailable")
        }
    }

    private fun <T> withDescriptor(
        file: File, flags: Int, mode: Int = 0, action: (FileDescriptor) -> T,
    ): T {
        val descriptor = Os.open(file.absolutePath, flags, mode)
        var closing = false
        try {
            val value = action(descriptor)
            closing = true
            Os.close(descriptor)
            return value
        } catch (failure: Exception) {
            if (!closing) {
                try {
                    Os.close(descriptor)
                } catch (closeFailure: Exception) {
                    failure.addSuppressed(closeFailure)
                }
            }
            throw failure
        }
    }

    private fun <T> withDirectory(action: (FileDescriptor) -> T): T = withDescriptor(
        directory, OsConstants.O_RDONLY or OsConstants.O_NOFOLLOW,
    ) {
        if (!OsConstants.S_ISDIR(Os.fstat(it).st_mode)) throw StorageFailure("io")
        action(it)
    }

    private companion object {
        val accessLock = Any()
        val executor = Executors.newSingleThreadExecutor()
        val MAGIC = "TSPMBL".toByteArray(Charsets.US_ASCII)
        val STORE_ID = "tspm/protected_baseline".toByteArray(Charsets.US_ASCII)
        const val FORMAT_VERSION = 1
        const val HEADER_SIZE = 12
        const val IV_SIZE = 12
        const val TAG_SIZE = 16
        const val MAX_CONTAINER_SIZE = 4 * 1024 * 1024
    }
}
