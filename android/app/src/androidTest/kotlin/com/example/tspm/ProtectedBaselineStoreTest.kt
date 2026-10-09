package com.example.tspm

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import android.system.Os
import java.io.File
import java.io.IOException
import java.security.KeyStore
import java.util.UUID
import org.junit.After
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class ProtectedBaselineStoreTest {
    private lateinit var directory: File
    private lateinit var alias: String
    private lateinit var store: ProtectedBaselineStore
    private val oldJson = "{\"privateBaseline\":\"native-old-73.125\"}"
    private val nextJson = "{\"privateBaseline\":\"native-new-74.375\"}"
    private val base: File get() = File(directory, "tspm-baseline.bin")
    private val pending: File get() = File(directory, "tspm-baseline.bin.pending")

    @Before fun setup() {
        val context = InstrumentationRegistry.getInstrumentation().targetContext
        val id = UUID.randomUUID().toString()
        directory = File(context.noBackupFilesDir, "protected-baseline-test-$id")
        assertTrue(directory.mkdir())
        alias = "tspm.test.$id"
        store = ProtectedBaselineStore(directory, alias)
    }

    @After fun cleanup() {
        directory.deleteRecursively()
        keyStore().deleteEntry(alias)
    }

    @Test fun encryptedRoundTripSurvivesNewStoreAndContainsNoPlaintext() {
        assertNull(store.read())
        store.replace(null, oldJson)
        assertEquals(oldJson, ProtectedBaselineStore(directory, alias).read())
        val ciphertext = base.readBytes().toString(Charsets.ISO_8859_1)
        assertFalse(ciphertext.contains("privateBaseline"))
        assertFalse(ciphertext.contains("73.125"))
    }

    @Test fun expectedValueConflictPreservesCommittedBytes() {
        store.replace(null, oldJson)
        val original = base.readBytes()
        assertFailure("conflict", "notCommitted") { store.replace(null, nextJson) }
        assertArrayEquals(original, base.readBytes())
        store.replace(oldJson, nextJson)
        assertEquals(nextJson, store.read())
    }

    @Test fun authenticationFailurePreservesCorruptBytesAndBlocksReplace() {
        store.replace(null, oldJson)
        val damaged = base.readBytes().also { it[it.lastIndex] = (it.last().toInt() xor 1).toByte() }
        base.writeBytes(damaged)
        assertFailure("corrupt") { store.read() }
        assertFailure("corrupt", "notCommitted") { store.replace(oldJson, nextJson) }
        assertArrayEquals(damaged, base.readBytes())
    }

    @Test fun missingKeyPreservesArtifactsAndNeverRegeneratesKey() {
        store.replace(null, oldJson)
        val original = base.readBytes()
        keyStore().deleteEntry(alias)
        assertFailure("keyUnavailable") { store.read() }
        assertFailure("keyUnavailable", "notCommitted") { store.replace(oldJson, nextJson) }
        assertArrayEquals(original, base.readBytes())
        assertFalse(keyStore().containsAlias(alias))
    }

    @Test fun abandonedFirstWriteIsNotPromotedAndMissingKeyBlocksNewWrite() {
        val interrupted = ProtectedBaselineStore(directory, alias) {
            if (it == WriteStage.BEFORE_RENAME) throw IOException("injected")
        }
        assertFailure("io", "notCommitted") { interrupted.replace(null, oldJson) }
        assertFalse(base.exists())
        assertTrue(pending.exists())
        assertNull(ProtectedBaselineStore(directory, alias).read())
        val artifact = pending.readBytes()
        keyStore().deleteEntry(alias)
        assertFailure("keyUnavailable", "notCommitted") { store.replace(null, nextJson) }
        assertArrayEquals(artifact, pending.readBytes())
        assertFalse(keyStore().containsAlias(alias))
    }

    @Test fun failureBeforeRenamePreservesOldCommittedSnapshot() {
        store.replace(null, oldJson)
        val original = base.readBytes()
        for (stage in listOf(WriteStage.AFTER_PENDING_SYNC, WriteStage.BEFORE_RENAME)) {
            val failing = ProtectedBaselineStore(directory, alias) {
                if (it == stage) throw IOException("injected")
            }
            assertFailure("io", "notCommitted") { failing.replace(oldJson, nextJson) }
            assertArrayEquals(original, base.readBytes())
            assertEquals(oldJson, ProtectedBaselineStore(directory, alias).read())
        }
    }

    @Test fun failureAfterRenameIsUnknownAndNewSnapshotRemainsComplete() {
        for (stage in listOf(WriteStage.AFTER_RENAME, WriteStage.BEFORE_DIRECTORY_SYNC, WriteStage.BEFORE_VERIFICATION)) {
            val current = store.read()
            val failing = ProtectedBaselineStore(directory, alias) {
                if (it == stage) throw IOException("injected")
            }
            assertFailure("io", "unknown") { failing.replace(current, nextJson) }
            assertEquals(nextJson, ProtectedBaselineStore(directory, alias).read())
        }
    }

    @Test fun pendingAliasCannotTruncateCommittedBase() {
        store.replace(null, oldJson)
        val original = base.readBytes()
        Os.symlink(base.absolutePath, pending.absolutePath)
        val interrupted = ProtectedBaselineStore(directory, alias) {
            if (it == WriteStage.BEFORE_RENAME) throw IOException("injected")
        }
        assertFailure("io", "notCommitted") { interrupted.replace(oldJson, nextJson) }
        assertArrayEquals(original, base.readBytes())
        assertEquals(oldJson, store.read())
    }

    @Test fun actualRenameFailurePreservesBaseAndCiphertextVerificationFailureIsUnknown() {
        store.replace(null, oldJson)
        val original = base.readBytes()
        val failedRename = ProtectedBaselineStore(directory, alias) {
            if (it == WriteStage.BEFORE_RENAME) assertTrue(pending.delete())
        }
        assertFailure("io", "notCommitted") { failedRename.replace(oldJson, nextJson) }
        assertArrayEquals(original, base.readBytes())
        val changedCiphertext = ProtectedBaselineStore(directory, alias) {
            if (it == WriteStage.BEFORE_VERIFICATION) {
                base.writeBytes(base.readBytes().also { bytes ->
                    bytes[bytes.lastIndex] = (bytes.last().toInt() xor 1).toByte()
                })
            }
        }
        assertFailure("io", "unknown") { changedCiphertext.replace(oldJson, nextJson) }
        assertTrue(base.exists())
        assertFailure("corrupt") { store.read() }
    }

    @Test fun malformedAndUnsupportedContainersRemainUntouched() {
        base.writeBytes(byteArrayOf(1, 2, 3))
        val malformed = base.readBytes()
        assertFailure("corrupt") { store.read() }
        assertArrayEquals(malformed, base.readBytes())
        base.delete()
        store.replace(null, oldJson)
        val future = base.readBytes().also { it[6] = 99 }
        base.writeBytes(future)
        val failure = assertFailure("unsupportedVersion") { store.read() }
        assertEquals(99, failure.unsupportedVersion)
        assertFailure("unsupportedVersion", "notCommitted") { store.replace(oldJson, nextJson) }
        assertArrayEquals(future, base.readBytes())
    }

    @Test fun inaccessibleParentDoesNotAppearAbsent() {
        val missing = File(directory, "missing-parent")
        assertFailure("io") { ProtectedBaselineStore(missing, alias).read() }
        val regularFile = File(directory, "not-directory").also { it.writeText("x") }
        assertFailure("io") { ProtectedBaselineStore(regularFile, alias).read() }
    }

    private fun keyStore(): KeyStore = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }

    private fun assertFailure(code: String, outcome: String? = null, action: () -> Unit): StorageFailure {
        try {
            action()
            fail("Expected $code with outcome $outcome")
        } catch (failure: StorageFailure) {
            assertEquals(code, failure.code)
            assertEquals(outcome, failure.writeOutcome)
            return failure
        }
        throw AssertionError("Expected storage failure")
    }
}
