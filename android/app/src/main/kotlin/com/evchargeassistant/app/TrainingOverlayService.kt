package com.evchargeassistant.app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.PixelFormat
import android.os.Build
import android.os.IBinder
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.FrameLayout
import android.widget.TextView
import android.widget.Toast

class TrainingOverlayService : Service() {
    private var windowManager: WindowManager? = null
    private var overlayView: View? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startForeground(1002, buildNotification())
        showOverlay(intent?.getStringExtra("mappingKey").orEmpty())
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        overlayView?.let { view -> windowManager?.removeView(view) }
        overlayView = null
        super.onDestroy()
    }

    private fun buildNotification(): Notification {
        val channelId = "ev_charge_training"
        val manager = getSystemService(NotificationManager::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "EV Charge Training",
                NotificationManager.IMPORTANCE_LOW
            )
            manager.createNotificationChannel(channel)
        }
        return Notification.Builder(this, channelId)
            .setContentTitle("Training Mode")
            .setContentText("Tap the correct position to save a mapping.")
            .setSmallIcon(android.R.drawable.ic_menu_edit)
            .build()
    }

    private fun showOverlay(mappingKey: String) {
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        val overlay = FrameLayout(this).apply {
            setBackgroundColor(0x3300BCD4)
        }
        val prompt = TextView(this).apply {
            text = "Tap target for: $mappingKey"
            textSize = 18f
            setPadding(32, 64, 32, 32)
        }
        overlay.addView(prompt)

        overlay.setOnTouchListener { _, event ->
            if (event.action == MotionEvent.ACTION_DOWN) {
                saveMapping(mappingKey, event.rawX, event.rawY)
                stopSelf()
                true
            } else {
                false
            }
        }

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            } else {
                WindowManager.LayoutParams.TYPE_PHONE
            },
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
        }

        overlayView = overlay
        windowManager?.addView(overlay, params)
    }

    private fun saveMapping(mappingKey: String, rawX: Float, rawY: Float) {
        getSharedPreferences("ev_charge_assistant_native", Context.MODE_PRIVATE)
            .edit()
            .putFloat("${mappingKey}_x", rawX)
            .putFloat("${mappingKey}_y", rawY)
            .apply()
        AutomationEventStreamHandler.emit(
            mapOf(
                "type" to "mappingSaved",
                "mappingKey" to mappingKey,
                "x" to rawX.toDouble(),
                "y" to rawY.toDouble(),
            )
        )
        Toast.makeText(this, "Saved $mappingKey at ($rawX, $rawY)", Toast.LENGTH_SHORT).show()
    }
}
