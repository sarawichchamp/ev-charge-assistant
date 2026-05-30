package com.evchargeassistant.app

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val methodChannelName = "ev_charge_assistant/methods"
    private val eventChannelName = "ev_charge_assistant/events"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, eventChannelName)
            .setStreamHandler(AutomationEventStreamHandler)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, methodChannelName)
            .setMethodCallHandler { call, result ->
                val bridge = AutomationBridge(this)
                when (call.method) {
                    "ensurePermissions" -> result.success(bridge.ensurePermissions())
                    "launchDeepal" -> {
                        bridge.launchDeepal()
                        result.success(true)
                    }

                    "launchFuelio" -> {
                        bridge.launchFuelio()
                        result.success(true)
                    }

                    "readSocAndOdometer" -> result.success(bridge.readSocAndOdometer())
                    "fillFuelio" -> result.success(bridge.fillFuelio(call.arguments as? Map<*, *>))
                    "saveFuelioEntry" -> result.success(bridge.saveFuelioEntry())
                    "openTrainingOverlay" -> {
                        bridge.openTrainingOverlay(call.argument("mappingKey") ?: "")
                        result.success(true)
                    }

                    "saveMappingPoint" -> {
                        bridge.saveMappingPoint(
                            call.argument("mappingKey") ?: "",
                            call.argument("label") ?: "",
                            call.argument<Double>("x") ?: 0.0,
                            call.argument<Double>("y") ?: 0.0,
                        )
                        result.success(true)
                    }

                    "saveAutomationMode" -> {
                        bridge.saveAutomationMode(call.argument("mode") ?: "textRecognition")
                        result.success(true)
                    }

                    "openDeepalForSchedule" -> {
                        bridge.launchDeepal()
                        result.success(true)
                    }

                    else -> result.notImplemented()
                }
            }
    }
}
