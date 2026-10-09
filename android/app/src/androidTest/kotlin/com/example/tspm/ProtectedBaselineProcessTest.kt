package com.example.tspm

import android.os.Process
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import java.io.File
import java.security.KeyStore
import org.junit.Assert.*
import org.junit.Assume.assumeTrue
import org.junit.Test
import org.junit.runner.RunWith

/** Host-driven process-death checks. Hooks exist only in instrumentation construction. */
@RunWith(AndroidJUnit4::class)
class ProtectedBaselineProcessTest {
    @Test fun interruptionLeavesOneCompleteSnapshot() {
        val scenario = InstrumentationRegistry.getArguments().getString("scenario")
        assumeTrue("Run separately with a scenario argument", scenario != null)
        val context = InstrumentationRegistry.getInstrumentation().targetContext
        val directory = File(context.noBackupFilesDir, "protected-baseline-process-test")
        val alias = "tspm.test.process-interruption"
        val old = "{\"baseline\":\"process-old-71.5\"}"
        val next = "{\"baseline\":\"process-new-72.5\"}"
        val store = ProtectedBaselineStore(directory, alias)
        when (scenario) {
            "prepare" -> {
                directory.deleteRecursively()
                KeyStore.getInstance("AndroidKeyStore").apply { load(null); deleteEntry(alias) }
                assertTrue(directory.mkdir())
                store.replace(null, old)
                assertEquals(old, store.read())
            }
            "interruptBeforeRename", "interruptAfterRename" -> {
                val stage = if (scenario == "interruptBeforeRename") {
                    WriteStage.BEFORE_RENAME
                } else {
                    WriteStage.AFTER_RENAME
                }
                ProtectedBaselineStore(directory, alias) {
                    if (it == stage) Process.killProcess(Process.myPid())
                }.replace(old, next)
                fail("The process should die at the requested write boundary")
            }
            "verifyOld", "verifyNew", "verifyAcknowledged" -> {
                assertEquals(if (scenario == "verifyNew") next else old, store.read())
                directory.deleteRecursively()
                KeyStore.getInstance("AndroidKeyStore").apply { load(null); deleteEntry(alias) }
            }
            else -> fail("Unknown instrumentation scenario")
        }
    }
}
