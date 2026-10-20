package net.circulation.ci.circulation

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.IBinder
import android.provider.Settings
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.FrameLayout
import android.widget.ImageView
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import kotlin.math.abs

/**
 * Service Android affichant une bulle flottante par-dessus les autres
 * applications. La bulle permet d'ouvrir rapidement l'écran de signalement
 * d'infraction.
 */
class FloatingBubbleService : Service() {

    companion object {
        const val ACTION_START = "net.circulation.ci.circulation.START_BUBBLE"
        const val ACTION_STOP = "net.circulation.ci.circulation.STOP_BUBBLE"
        const val EXTRA_ROUTE = "floating_bubble_route"
        const val ROUTE_INFRACTION = "/client/infraction/type"

        private const val CHANNEL_ID = "floating_bubble"
        private const val NOTIFICATION_ID = 4101

        @Volatile
        var isRunning: Boolean = false
            private set

        fun start(context: Context) {
            val intent = Intent(context, FloatingBubbleService::class.java).apply {
                action = ACTION_START
            }
            ContextCompat.startForegroundService(context, intent)
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, FloatingBubbleService::class.java))
        }
    }

    private var windowManager: WindowManager? = null
    private var bubbleView: FrameLayout? = null
    private var layoutParams: WindowManager.LayoutParams? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        isRunning = true
        createNotificationChannel()
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Circulation")
            .setContentText("Bulle de signalement active")
            .setSmallIcon(R.drawable.ic_stat_bubble)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
        val notificationIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            notificationIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        notification.contentIntent = pendingIntent
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startForeground(
                NOTIFICATION_ID,
                notification,
                android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE,
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            stopSelf()
            return START_NOT_STICKY
        }
        if (!Settings.canDrawOverlays(this)) {
            stopSelf()
            return START_NOT_STICKY
        }
        showBubble()
        return START_STICKY
    }

    override fun onDestroy() {
        hideBubble()
        isRunning = false
        super.onDestroy()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Bulle flottante",
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = "Maintient la bulle de signalement active"
            setShowBadge(false)
        }
        manager.createNotificationChannel(channel)
    }

    private fun showBubble() {
        if (bubbleView != null) return
        val manager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        windowManager = manager

        val density = resources.displayMetrics.density
        val size = (60 * density).toInt()

        val bubble = FrameLayout(this)
        val background = GradientDrawable().apply {
            shape = GradientDrawable.OVAL
            setColor(Color.parseColor("#1565C0"))
            setStroke((3 * density).toInt(), Color.WHITE)
        }
        bubble.background = background

        val icon = ImageView(this)
        icon.setImageDrawable(packageManager.getApplicationIcon(packageName))
        val padding = (14 * density).toInt()
        icon.setPadding(padding, padding, padding, padding)
        bubble.addView(
            icon,
            FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT,
            ),
        )

        val type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_PHONE
        }

        val params = WindowManager.LayoutParams(
            size,
            size,
            type,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT,
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = resources.displayMetrics.widthPixels - size - (16 * density).toInt()
            y = (resources.displayMetrics.heightPixels * 0.35f).toInt()
        }
        layoutParams = params

        bubble.setOnTouchListener(object : View.OnTouchListener {
            private var initialX = 0
            private var initialY = 0
            private var touchX = 0f
            private var touchY = 0f
            private var moved = false

            override fun onTouch(view: View, event: MotionEvent): Boolean {
                when (event.action) {
                    MotionEvent.ACTION_DOWN -> {
                        initialX = params.x
                        initialY = params.y
                        touchX = event.rawX
                        touchY = event.rawY
                        moved = false
                        return true
                    }

                    MotionEvent.ACTION_MOVE -> {
                        val dx = event.rawX - touchX
                        val dy = event.rawY - touchY
                        if (abs(dx) > 12 || abs(dy) > 12) moved = true
                        params.x = initialX + dx.toInt()
                        params.y = initialY + dy.toInt()
                        windowManager?.updateViewLayout(bubble, params)
                        return true
                    }

                    MotionEvent.ACTION_UP -> {
                        if (!moved) {
                            openInfractionCapture()
                        } else {
                            snapToEdge()
                        }
                        return true
                    }
                }
                return false
            }
        })

        manager.addView(bubble, params)
        bubbleView = bubble
    }

    private fun snapToEdge() {
        val params = layoutParams ?: return
        val bubble = bubbleView ?: return
        val screenWidth = resources.displayMetrics.widthPixels
        val margin = (12 * resources.displayMetrics.density).toInt()
        params.x = if (params.x + params.width / 2 < screenWidth / 2) {
            margin
        } else {
            screenWidth - params.width - margin
        }
        windowManager?.updateViewLayout(bubble, params)
    }

    private fun openInfractionCapture() {
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_CLEAR_TOP or
                Intent.FLAG_ACTIVITY_SINGLE_TOP
            putExtra(EXTRA_ROUTE, ROUTE_INFRACTION)
        }
        startActivity(intent)
    }

    private fun hideBubble() {
        bubbleView?.let { view ->
            try {
                windowManager?.removeView(view)
            } catch (_: Exception) {
            }
        }
        bubbleView = null
        layoutParams = null
        windowManager = null
    }
}
