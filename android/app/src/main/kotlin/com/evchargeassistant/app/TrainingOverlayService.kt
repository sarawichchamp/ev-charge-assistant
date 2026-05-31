package com.evchargeassistant.app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.PixelFormat
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.FrameLayout
import android.widget.ImageButton
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast

class TrainingOverlayService : Service() {
    private var windowManager: WindowManager? = null
    private var overlayView: View? = null
    private var bubbleView: View? = null
    private val handler = Handler(Looper.getMainLooper())

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startForeground(1002, buildNotification())
        val mappingKey = intent?.getStringExtra("mappingKey").orEmpty()
        showBubble(mappingKey)
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        handler.removeCallbacksAndMessages(null)
        overlayView?.let { view -> windowManager?.removeView(view) }
        bubbleView?.let { view -> windowManager?.removeView(view) }
        overlayView = null
        bubbleView = null
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

    private fun showBubble(mappingKey: String) {
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        bubbleView?.let { existing ->
            runCatching { windowManager?.removeView(existing) }
        }

        val bubble = ImageButton(this).apply {
            setImageResource(android.R.drawable.ic_menu_mylocation)
            setBackgroundColor(0xDD00BCD4.toInt())
            contentDescription = "Capture target position"
            setOnClickListener {
                runCatching { windowManager?.removeView(this) }
                bubbleView = null
                showOverlay(mappingKey)
            }
        }

        val params = WindowManager.LayoutParams(
            160,
            160,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            } else {
                WindowManager.LayoutParams.TYPE_PHONE
            },
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.END
            x = 24
            y = 260
        }

        bubbleView = bubble
        windowManager?.addView(bubble, params)
        Toast.makeText(
            this,
            "Bubble ready. Open the target app, then tap the bubble.",
            Toast.LENGTH_LONG
        ).show()
    }

    private fun showOverlay(mappingKey: String) {
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        val overlay = FrameLayout(this).apply {
            setBackgroundColor(0x2200BCD4)
        }
        val panel = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(32, 64, 32, 32)
            setBackgroundColor(0xDD111111.toInt())
        }
        val prompt = TextView(this).apply {
            text = "Tap target for: $mappingKey"
            textSize = 18f
            setTextColor(0xFFFFFFFF.toInt())
        }
        val hint = TextView(this).apply {
            text = "Wait for the correct screen, then tap the exact target position once."
            textSize = 14f
            setTextColor(0xFFE0E0E0.toInt())
            setPadding(0, 16, 0, 16)
        }
        val cancelButton = Button(this).apply {
            text = "Cancel"
            setOnClickListener {
                stopSelf()
            }
        }
        panel.addView(prompt)
        panel.addView(hint)
        panel.addView(cancelButton)
        overlay.addView(panel)

        overlay.setOnTouchListener { _, event ->
            if (event.action == MotionEvent.ACTION_DOWN) {
                if (event.rawY < 240) {
                    return@setOnTouchListener false
                }
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
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
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
