package net.circulation.ci.circulation

import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        private const val BUBBLE_CHANNEL =
            "net.circulation.ci.circulation/floating_bubble"
        private const val BUBBLE_EVENTS_CHANNEL =
            "net.circulation.ci.circulation/floating_bubble_events"
        private const val VIDEO_TRIM_CHANNEL =
            "net.circulation.ci.circulation/video_trim"
    }

    private var bubbleEventSink: EventChannel.EventSink? = null
    private var pendingRoute: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        MethodChannel(messenger, BUBBLE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "show" -> {
                    if (!Settings.canDrawOverlays(this)) {
                        result.success(false)
                    } else {
                        FloatingBubbleService.start(this)
                        result.success(true)
                    }
                }

                "hide" -> {
                    FloatingBubbleService.stop(this)
                    result.success(true)
                }

                "toggle" -> {
                    if (FloatingBubbleService.isRunning) {
                        FloatingBubbleService.stop(this)
                        result.success(false)
                    } else if (!Settings.canDrawOverlays(this)) {
                        result.success(false)
                    } else {
                        FloatingBubbleService.start(this)
                        result.success(true)
                    }
                }

                "isActive" -> result.success(FloatingBubbleService.isRunning)

                else -> result.notImplemented()
            }
        }

        MethodChannel(messenger, VIDEO_TRIM_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method != "trim") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            val inputPath = call.argument<String>("inputPath")
            val outputPath = call.argument<String>("outputPath")
            val startMs = call.argument<Number>("startMs")?.toLong()
            val endMs = call.argument<Number>("endMs")?.toLong()

            if (inputPath == null || outputPath == null || startMs == null || endMs == null) {
                result.error("invalid_args", "Paramètres de découpe invalides", null)
                return@setMethodCallHandler
            }

            Thread {
                val success = VideoTrimmer.trim(inputPath, outputPath, startMs, endMs)
                runOnUiThread {
                    if (success) {
                        result.success(outputPath)
                    } else {
                        result.error("trim_failed", "Découpage impossible", null)
                    }
                }
            }.start()
        }

        EventChannel(messenger, BUBBLE_EVENTS_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    bubbleEventSink = events
                    pendingRoute?.let { route ->
                        pendingRoute = null
                        events?.success(route)
                    }
                }

                override fun onCancel(arguments: Any?) {
                    bubbleEventSink = null
                }
            },
        )

        handleRouteIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleRouteIntent(intent)
    }

    private fun handleRouteIntent(intent: Intent?) {
        val route = intent?.getStringExtra(FloatingBubbleService.EXTRA_ROUTE) ?: return
        intent.removeExtra(FloatingBubbleService.EXTRA_ROUTE)
        val sink = bubbleEventSink
        if (sink != null) {
            sink.success(route)
        } else {
            pendingRoute = route
        }
    }
}
