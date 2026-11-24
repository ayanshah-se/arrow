package com.example.arrows

import android.content.Context
import android.media.AudioAttributes
import android.os.Build
import android.os.Bundle
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.view.HapticFeedbackConstants
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "arrows/haptics"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.decorView.isHapticFeedbackEnabled = true
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                if (call.method == "vibrate") {
                    val duration = (call.argument<Int>("duration") ?: 80).toLong()
                    val strong = call.argument<Boolean>("strong") ?: true
                    pulse(duration, strong)
                    result.success(true)
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun pulse(duration: Long, strong: Boolean) {
        val flags = HapticFeedbackConstants.FLAG_IGNORE_VIEW_SETTING or 2
        val viewConstant =
            if (strong) {
                if (Build.VERSION.SDK_INT >= 30) {
                    HapticFeedbackConstants.REJECT
                } else {
                    HapticFeedbackConstants.LONG_PRESS
                }
            } else {
                if (Build.VERSION.SDK_INT >= 27) {
                    HapticFeedbackConstants.KEYBOARD_TAP
                } else {
                    HapticFeedbackConstants.VIRTUAL_KEY
                }
            }
        window.decorView.performHapticFeedback(viewConstant, flags)

        val vibrator = systemVibrator() ?: return
        if (!vibrator.hasVibrator()) return

        val attrs =
            AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_GAME)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val amplitude =
                if (strong && vibrator.hasAmplitudeControl()) 255
                else VibrationEffect.DEFAULT_AMPLITUDE
            val effect = VibrationEffect.createOneShot(duration.coerceAtLeast(20), amplitude)
            if (Build.VERSION.SDK_INT >= 33) {
                val touchAttrs =
                    android.os.VibrationAttributes.Builder()
                        .setUsage(android.os.VibrationAttributes.USAGE_TOUCH)
                        .build()
                vibrator.vibrate(effect, touchAttrs)
            } else {
                vibrator.vibrate(effect, attrs)
            }
        } else {
            @Suppress("DEPRECATION")
            vibrator.vibrate(duration)
        }
    }

    private fun systemVibrator(): Vibrator? {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val manager = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
            manager.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
        }
    }
}
