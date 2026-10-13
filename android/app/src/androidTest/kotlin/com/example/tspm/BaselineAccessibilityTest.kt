package com.example.tspm

import android.app.UiAutomation
import android.os.Bundle
import android.os.Build
import android.os.ParcelFileDescriptor
import android.view.accessibility.AccessibilityNodeInfo
import java.io.File
import org.json.JSONObject
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Assert.*
import org.junit.Assume.assumeTrue
import org.junit.Test
import org.junit.runner.RunWith

/** Run with -e baselineAccessibility true on a disposable, unfinished baseline. */
@RunWith(AndroidJUnit4::class)
class BaselineAccessibilityTest {
    private val instrumentation = InstrumentationRegistry.getInstrumentation()
    private val automation by lazy {
        instrumentation.getUiAutomation(UiAutomation.FLAG_DONT_SUPPRESS_ACCESSIBILITY_SERVICES)
    }

    @Test fun ac13NativeLabelsFocusAndFiveStepOrder() {
        assumeTrue(InstrumentationRegistry.getArguments().getString("baselineAccessibility") == "true")
        openProduct()
        for (back in 0 until 4) {
            if (nodes().any { label(it).contains("Step 1 of 5") }) break
            click("Back")
        }
        assertOrder("Step 1 of 5", "Start with what you know", "A starting weight", "Weight units")
        focus("Weight units")
        click("Continue")
        assertOrder("Step 2 of 5", "A starting point", "Age (years)", "Equation input")
        enter("Age (years)", "30")
        click("Equation input")
        click("Male")
        enter("Height (cm)", "175")
        enter("Starting weight (kg)", "80")
        click("Continue")
        assertOrder("Step 3 of 5", "Measurements, if known", "Waist (cm)", "Neck (cm)")
        focus("Waist (cm)")
        click("Continue")
        assertOrder("Step 4 of 5", "Your usual activity", "Activity level", "Typical daily steps")
        focus("Activity level")
        click("Continue")
        assertOrder("Step 5 of 5", "Your intention", "Goal intention")
        click("Goal intention")
        click("Weight loss")
        enter("Target weight (kg)", "75")
        click("Intended weekly loss rate")
        click("0.75% of weight per week")
        focus("Intended weekly loss rate")
        waitFor("Draft saved on this device", scroll = true)
        // Keep this draft for host-driven back, failure and timestamp checks.
    }

    @Test fun ac8And12SystemBackWarnsOnFailedSaveAndRetryRetainsAnswers() {
        assumeTrue(InstrumentationRegistry.getArguments().getString("baselineRecovery") == "true")
        openProduct()
        for (back in 0 until 4) {
            if (nodes().any { label(it).contains("Step 1 of 5") }) break
            click("Back")
        }
        waitFor("Draft saved on this device", scroll = true)
        val context = instrumentation.targetContext
        val directory = context.noBackupFilesDir
        val base = File(directory, "tspm-baseline.bin")
        val acknowledged = base.readBytes()
        val previousUnit = JSONObject(ProtectedBaselineStore(context).read()!!)
            .getJSONObject("payload").getJSONObject("units").getString("weight")
        val nextUnit = if (previousUnit == "kg") "lb" else "kg"
        assertTrue(directory.setWritable(false, true))
        try {
            click("Weight units")
            click(nextUnit)
            waitFor("Draft not saved", scroll = true)
            assertArrayEquals(acknowledged, base.readBytes())
            automation.executeShellCommand("input keyevent 4").close()
            waitFor("Leave with unsaved answers?")
            click("Keep editing")
            waitFor("Draft not saved", scroll = true)
        } finally {
            assertTrue(directory.setWritable(true, true))
        }
        click("Retry")
        waitFor("Draft saved on this device", scroll = true)
        val json = JSONObject(ProtectedBaselineStore(context).read()!!)
        assertEquals(nextUnit, json.getJSONObject("payload").getJSONObject("units").getString("weight"))
        repeat(4) { click("Continue") }
        click("Save baseline")
        waitFor("Baseline saved", scroll = true)
        click("Review profile")
        assertOrder("Saved profile", "Read-only review", "Reported baseline inputs", "Age (years)")
        focus("Age (years)")
    }

    private fun openProduct() {
        ParcelFileDescriptor.AutoCloseInputStream(automation.executeShellCommand(
            "am start -n com.example.tspm/.MainActivity",
        )).use { it.readBytes() }
        repeat(40) {
            if (nodes().any { label(it).contains("Open baseline setup") }) {
                click("Open baseline setup")
                waitFor("Step ")
                return
            }
            if (nodes().any { label(it).contains("Step ") }) return
            Thread.sleep(100)
        }
        throw AssertionError("No unfinished baseline available on disposable device")
    }

    private fun nodes(): List<AccessibilityNodeInfo> {
        val result = mutableListOf<AccessibilityNodeInfo>()
        fun visit(node: AccessibilityNodeInfo) {
            result.add(node)
            for (index in 0 until node.childCount) node.getChild(index)?.let { visit(it) }
        }
        automation.rootInActiveWindow?.let { visit(it) }
        return result
    }

    private fun label(node: AccessibilityNodeInfo) =
        "${node.text ?: ""} ${node.contentDescription ?: ""} ${if (Build.VERSION.SDK_INT >= 26) node.hintText ?: "" else ""}".trim()

    private fun waitFor(text: String, scroll: Boolean = false): AccessibilityNodeInfo {
        repeat(40) {
            val visible = nodes()
            visible.firstOrNull { label(it).contains(text) && it.isVisibleToUser }?.let { return it }
            if (scroll) visible.firstOrNull { it.isScrollable }?.performAction(
                if (it < 20) AccessibilityNodeInfo.ACTION_SCROLL_FORWARD else AccessibilityNodeInfo.ACTION_SCROLL_BACKWARD,
            )
            Thread.sleep(100)
        }
        throw AssertionError("Missing native accessibility label: $text; ${nodes().map { label(it) }}")
    }

    private fun assertOrder(vararg labels: String) {
        waitFor(labels.first())
        val visible = nodes().map { label(it) }
        val indices = labels.map { text -> visible.indexOfFirst { it.contains(text) } }
        assertTrue("Reading order: $visible", indices.all { it >= 0 } && indices.zipWithNext().all { it.first < it.second })
    }

    private fun click(text: String) {
        assertTrue(waitFor(text, scroll = true).performAction(AccessibilityNodeInfo.ACTION_CLICK))
        Thread.sleep(150)
    }

    private fun focus(text: String) {
        repeat(40) {
            waitFor(text, scroll = true).performAction(AccessibilityNodeInfo.ACTION_ACCESSIBILITY_FOCUS)
            Thread.sleep(100)
            val focused = automation.rootInActiveWindow?.findFocus(AccessibilityNodeInfo.FOCUS_ACCESSIBILITY)
            if (focused != null && label(focused).contains(text)) return
        }
        throw AssertionError("Screen-reader focus did not settle on $text")
    }

    private fun enter(text: String, value: String) {
        click(text)
        var field = waitFor(text, scroll = true)
        assertTrue(field.isEditable)
        for (attempt in 0 until 40) {
            field = waitFor(text)
            if (field.actionList.any { it.id == AccessibilityNodeInfo.ACTION_SET_TEXT }) break
            Thread.sleep(100)
        }
        assertTrue("Field must accept editing before entering $text",
            field.actionList.any { it.id == AccessibilityNodeInfo.ACTION_SET_TEXT })
        val args = Bundle().apply { putCharSequence(AccessibilityNodeInfo.ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE, value) }
        assertTrue(field.performAction(AccessibilityNodeInfo.ACTION_SET_TEXT, args))
        Thread.sleep(200)
        repeat(40) {
            if (nodes().any { label(it).contains(text) && it.text?.toString() == value }) return
            Thread.sleep(100)
        }
        throw AssertionError("Text entry not acknowledged for $text: ${nodes().map { label(it) }}")
    }
}
