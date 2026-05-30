package com.evchargeassistant.app

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.GestureDescription
import android.content.Context
import android.graphics.Path
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import java.util.Locale
import java.util.regex.Pattern

class EvAccessibilityService : AccessibilityService() {
    companion object {
        var instance: EvAccessibilityService? = null
            private set
    }

    private val handler = Handler(Looper.getMainLooper())
    private val socPattern = Pattern.compile("(\\d{1,3})\\s?%")
    private val odometerPattern = Pattern.compile("(\\d{1,3}(?:,\\d{3})+)\\s?(?:km|KM)")

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        AutomationEventStreamHandler.emit(
            mapOf(
                "type" to "event",
                "packageName" to event?.packageName?.toString(),
                "className" to event?.className?.toString(),
            )
        )
    }

    override fun onInterrupt() = Unit

    override fun onDestroy() {
        if (instance === this) {
            instance = null
        }
        super.onDestroy()
    }

    fun readSocAndOdometer(): Map<String, Any?> {
        val root = rootInActiveWindow
            ?: return mapOf("success" to false, "message" to "No active window to inspect.")

        val texts = flattenNodeText(root)
        val soc = findSoc(texts)
        var odometer = findOdometer(texts)

        if (odometer == null) {
            clickNodeByText(root, "vehicle status") ||
                tapFallback("deepal_vehicle_status_button", null)
            odometer = waitForOdometer()
        }

        return if (soc != null && odometer != null) {
            mapOf("success" to true, "currentSoc" to soc, "odometerKm" to odometer)
        } else {
            mapOf(
                "success" to false,
                "message" to "Could not reliably read SOC or odometer from the current Deepal screen."
            )
        }
    }

    fun fillFuelio(odometerKm: Int, energyKwh: Double, pricePerKwh: Double): Boolean {
        val root = rootInActiveWindow ?: return false

        val odometerValue = odometerKm.toString()
        val energyValue = String.format(Locale.US, "%.2f", energyKwh)
        val priceValue = String.format(Locale.US, "%.2f", pricePerKwh)

        val odometerSet = setField(root, listOf("odometer"), odometerValue) ||
            tapFallback("fuelio_odometer_field", odometerValue)
        val energySet = setField(root, listOf("energy", "kwh"), energyValue) ||
            tapFallback("fuelio_energy_field", energyValue)
        val priceSet = setField(root, listOf("price", "cost per"), priceValue) ||
            tapFallback("fuelio_price_field", priceValue)

        clickNodeByText(root, "slow charge")
        return odometerSet && energySet && priceSet
    }

    fun saveFuelioEntry(): Boolean {
        val root = rootInActiveWindow ?: return false
        val confirmClicked =
            clickNodeByText(root, "confirm") || tapFallback("fuelio_confirm_button", null)
        val saveClicked = clickNodeByText(root, "save") || tapFallback("fuelio_save_button", null)
        return confirmClicked || saveClicked
    }

    private fun flattenNodeText(node: AccessibilityNodeInfo): List<String> {
        val results = mutableListOf<String>()

        fun walk(current: AccessibilityNodeInfo?) {
            if (current == null) {
                return
            }
            current.text?.toString()?.trim()?.takeIf { it.isNotEmpty() }?.let(results::add)
            current.contentDescription?.toString()?.trim()?.takeIf { it.isNotEmpty() }?.let(results::add)
            for (index in 0 until current.childCount) {
                walk(current.getChild(index))
            }
        }

        walk(node)
        return results
    }

    private fun findSoc(texts: List<String>): Int? {
        return texts.firstNotNullOfOrNull { text ->
            val matcher = socPattern.matcher(text)
            if (matcher.find()) matcher.group(1)?.toIntOrNull() else null
        }
    }

    private fun findOdometer(texts: List<String>): Int? {
        return texts.firstNotNullOfOrNull { text ->
            val matcher = odometerPattern.matcher(text)
            if (matcher.find()) matcher.group(1)?.replace(",", "")?.toIntOrNull() else null
        }
    }

    private fun waitForOdometer(timeoutMs: Long = 3000L): Int? {
        val start = SystemClock.uptimeMillis()
        while (SystemClock.uptimeMillis() - start < timeoutMs) {
            val currentTexts = rootInActiveWindow?.let(::flattenNodeText).orEmpty()
            val odometer = findOdometer(currentTexts)
            if (odometer != null) {
                return odometer
            }
            SystemClock.sleep(250)
        }
        return null
    }

    private fun setField(
        root: AccessibilityNodeInfo,
        labels: List<String>,
        value: String,
    ): Boolean {
        val nodes = mutableListOf<AccessibilityNodeInfo>()

        fun walk(node: AccessibilityNodeInfo?) {
            if (node == null) {
                return
            }
            val text = (node.text?.toString() ?: node.hintText?.toString() ?: "").lowercase()
            val contentDescription = (node.contentDescription?.toString() ?: "").lowercase()
            if (labels.any { text.contains(it) || contentDescription.contains(it) }) {
                nodes.add(node)
            }
            for (index in 0 until node.childCount) {
                walk(node.getChild(index))
            }
        }

        walk(root)
        for (node in nodes) {
            val target = if (node.isEditable) node else node.findFocus(AccessibilityNodeInfo.FOCUS_INPUT)
            if (target != null) {
                val args = Bundle().apply {
                    putCharSequence(
                        AccessibilityNodeInfo.ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE,
                        value
                    )
                }
                if (target.performAction(AccessibilityNodeInfo.ACTION_SET_TEXT, args)) {
                    return true
                }
            }
        }
        return false
    }

    private fun clickNodeByText(root: AccessibilityNodeInfo, query: String): Boolean {
        val normalized = query.lowercase()

        fun walk(node: AccessibilityNodeInfo?): AccessibilityNodeInfo? {
            if (node == null) {
                return null
            }
            val text = node.text?.toString()?.lowercase() ?: ""
            val description = node.contentDescription?.toString()?.lowercase() ?: ""
            if (text.contains(normalized) || description.contains(normalized)) {
                return node
            }
            for (index in 0 until node.childCount) {
                val childResult = walk(node.getChild(index))
                if (childResult != null) {
                    return childResult
                }
            }
            return null
        }

        val node = walk(root) ?: return false
        return node.performAction(AccessibilityNodeInfo.ACTION_CLICK) ||
            node.parent?.performAction(AccessibilityNodeInfo.ACTION_CLICK) == true
    }

    private fun tapFallback(mappingKey: String, textToPaste: String?): Boolean {
        val prefs = getSharedPreferences("ev_charge_assistant_native", Context.MODE_PRIVATE)
        val x = prefs.getFloat("${mappingKey}_x", -1f)
        val y = prefs.getFloat("${mappingKey}_y", -1f)
        if (x < 0 || y < 0) {
            return false
        }
        performTap(x, y)
        if (textToPaste != null) {
            handler.postDelayed({ pasteText(textToPaste) }, 350)
        }
        return true
    }

    private fun performTap(x: Float, y: Float) {
        val path = Path().apply {
            moveTo(x, y)
        }
        val gesture = GestureDescription.Builder()
            .addStroke(GestureDescription.StrokeDescription(path, 0, 80))
            .build()
        dispatchGesture(gesture, null, null)
    }

    private fun pasteText(text: String) {
        rootInActiveWindow?.findFocus(AccessibilityNodeInfo.FOCUS_INPUT)?.let { node ->
            val args = Bundle().apply {
                putCharSequence(
                    AccessibilityNodeInfo.ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE,
                    text
                )
            }
            node.performAction(AccessibilityNodeInfo.ACTION_SET_TEXT, args)
        }
    }
}
