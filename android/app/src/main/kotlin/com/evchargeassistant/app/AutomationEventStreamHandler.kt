package com.evchargeassistant.app

import io.flutter.plugin.common.EventChannel

object AutomationEventStreamHandler : EventChannel.StreamHandler {
    private var sink: EventChannel.EventSink? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        sink = events
    }

    override fun onCancel(arguments: Any?) {
        sink = null
    }

    fun emit(event: Map<String, Any?>) {
        sink?.success(event)
    }
}
