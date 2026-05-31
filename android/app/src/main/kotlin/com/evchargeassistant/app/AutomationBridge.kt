package com.evchargeassistant.app

import android.accessibilityservice.AccessibilityServiceInfo
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.view.accessibility.AccessibilityManager
import androidx.core.content.ContextCompat

class AutomationBridge(private val context: Context) {
    private val prefs: SharedPreferences =
        context.getSharedPreferences("ev_charge_assistant_native", Context.MODE_PRIVATE)

    fun ensurePermissions(): Boolean {
        if (!Settings.canDrawOverlays(context)) {
            val intent = Intent(
                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                Uri.parse("package:${context.packageName}")
            ).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(intent)
            return false
        }

        if (!isAccessibilityEnabled()) {
            val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(intent)
            return false
        }

        startForegroundService()
        return true
    }

    fun launchDeepal() {
        launchByCandidates(
            listOf(
                "com.deepal.app",
                "com.changan.deepal",
                "com.deepal",
            ),
            "deepal"
        )
    }

    fun launchFuelio() {
        launchByCandidates(listOf("com.kajda.fuelio"), "fuelio")
    }

    fun readSocAndOdometer(): Map<String, Any?> {
        val service = EvAccessibilityService.instance
        if (service == null) {
            return mapOf(
                "success" to false,
                "message" to "Accessibility service is not active."
            )
        }
        return service.readSocAndOdometer()
    }

    fun fillFuelio(arguments: Map<*, *>?): Boolean {
        val service = EvAccessibilityService.instance ?: return false
        return service.fillFuelio(
            odometerKm = (arguments?.get("odometerKm") as? Number)?.toInt() ?: return false,
            energyKwh = (arguments["energyKwh"] as? Number)?.toDouble() ?: return false,
            pricePerKwh = (arguments["pricePerKwh"] as? Number)?.toDouble() ?: return false,
        )
    }

    fun saveFuelioEntry(): Boolean {
        val service = EvAccessibilityService.instance ?: return false
        return service.saveFuelioEntry()
    }

    fun openTrainingOverlay(mappingKey: String) {
        if (!Settings.canDrawOverlays(context)) {
            ensurePermissions()
            return
        }
        launchTrainingTarget(mappingKey)
        Handler(Looper.getMainLooper()).postDelayed({
            val intent = Intent(context, TrainingOverlayService::class.java).apply {
                putExtra("mappingKey", mappingKey)
            }
            ContextCompat.startForegroundService(context, intent)
        }, 1800)
    }

    fun saveMappingPoint(mappingKey: String, label: String, x: Double, y: Double) {
        prefs.edit()
            .putFloat("${mappingKey}_x", x.toFloat())
            .putFloat("${mappingKey}_y", y.toFloat())
            .putString("${mappingKey}_label", label)
            .apply()
    }

    fun saveAutomationMode(mode: String) {
        prefs.edit().putString("automation_mode", mode).apply()
    }

    private fun isAccessibilityEnabled(): Boolean {
        val accessibilityManager =
            context.getSystemService(Context.ACCESSIBILITY_SERVICE) as AccessibilityManager
        val services = accessibilityManager.getEnabledAccessibilityServiceList(
            AccessibilityServiceInfo.FEEDBACK_GENERIC
        )
        return services.any {
            val serviceInfo = it.resolveInfo.serviceInfo
            ComponentName(serviceInfo.packageName, serviceInfo.name).flattenToString() ==
                ComponentName(context, EvAccessibilityService::class.java).flattenToString()
        }
    }

    private fun startForegroundService() {
        val intent = Intent(context, AutomationForegroundService::class.java)
        ContextCompat.startForegroundService(context, intent)
    }

    private fun launchByCandidates(packages: List<String>, fallbackLabel: String) {
        val pm = context.packageManager
        for (candidate in packages) {
            val launchIntent = pm.getLaunchIntentForPackage(candidate)
            if (launchIntent != null) {
                launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                context.startActivity(launchIntent)
                return
            }
        }

        val fallback = pm.getInstalledApplications(PackageManager.GET_META_DATA).firstOrNull {
            pm.getApplicationLabel(it).toString().contains(fallbackLabel, ignoreCase = true)
        }
        val launchIntent = fallback?.packageName?.let(pm::getLaunchIntentForPackage)
        launchIntent?.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        if (launchIntent != null) {
            context.startActivity(launchIntent)
        }
    }

    private fun launchTrainingTarget(mappingKey: String) {
        when {
            mappingKey.startsWith("deepal_") -> launchDeepal()
            mappingKey.startsWith("fuelio_") -> launchFuelio()
        }
    }
}
