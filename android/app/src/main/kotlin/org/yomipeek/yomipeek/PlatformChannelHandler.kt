package org.yomipeek.yomipeek

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.speech.tts.TextToSpeech
import io.flutter.plugin.common.MethodChannel
import java.util.Locale

internal fun boundedText(value: CharSequence?, limit: Int = 2000): String {
    val text = value?.toString().orEmpty()
    return text.substring(0, text.offsetByCodePoints(0, minOf(text.codePointCount(0, text.length), limit)))
}
internal class JapaneseSpeech(private val activityContext: android.content.Context) {
    private var available = false
    private var engine: TextToSpeech? = null
    init {
        engine = TextToSpeech(activityContext) { status ->
            if (status == TextToSpeech.SUCCESS) {
                val result = engine?.setLanguage(Locale.JAPANESE)
                available = result != null && result >= TextToSpeech.LANG_AVAILABLE
                // Never select a network-only voice for this offline application.
                val voice = engine?.voices?.firstOrNull { it.locale.language == "ja" && !it.isNetworkConnectionRequired }
                if (voice != null) engine?.voice = voice else available = false
            }
        }
    }
    fun speak(text: String): Boolean {
        if (!available) return false
        return engine?.speak(boundedText(text, 512), TextToSpeech.QUEUE_FLUSH, null, "yomipeek") == TextToSpeech.SUCCESS
    }
    fun close() { engine?.stop(); engine?.shutdown(); engine = null }
}
internal class PlatformChannelHandler(private val activity: MainActivity, val channel: MethodChannel) {
    private val speech = JapaneseSpeech(activity)
    init {
        channel.setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "initialSelection" -> result.success(activity.takeSelection())
                    "setTheme" -> {
                        val mode = (call.arguments as? String).takeIf { it in listOf("system", "light", "dark") } ?: "system"
                        activity.getSharedPreferences("floating", android.content.Context.MODE_PRIVATE).edit().putString("theme", mode).apply()
                        result.success(null)
                    }
                    "floatingState" -> {
                        val allowed = Settings.canDrawOverlays(activity)
                        android.util.Log.d("YomiPeek", "Overlay permission queried: $allowed")
                        result.success(mapOf("permission" to allowed, "shortcut" to OverlayService.shortcutEnabled(activity), "theme" to activity.getSharedPreferences("floating", android.content.Context.MODE_PRIVATE).getString("theme", "system")))
                    }
                    "overlayPermission" -> {
                        activity.startActivity(Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, Uri.parse("package:${activity.packageName}")))
                        result.success(null)
                    }
                    "openFloating" -> {
                        if (!Settings.canDrawOverlays(activity)) result.error("permission", "Allow display over other apps in Android settings first.", null)
                        else { OverlayService.start(activity, OverlayService.LOOKUP, boundedText(call.arguments as? String)); result.success(null) }
                    }
                    "shortcut" -> {
                        val enabled = call.arguments == true
                        if (enabled && !Settings.canDrawOverlays(activity)) result.error("permission", "Overlay permission has not been granted.", null)
                        else {
                            OverlayService.setShortcut(activity, enabled)
                            if (enabled) {
                                if (Build.VERSION.SDK_INT >= 33 && activity.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
                                    activity.requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 52)
                                }
                                OverlayService.start(activity, OverlayService.SHORTCUT)
                            } else activity.stopService(Intent(activity, OverlayService::class.java))
                            result.success(null)
                        }
                    }
                    "speak" -> if (speech.speak(call.arguments as? String ?: "")) result.success(null) else result.error("voice", "No offline Japanese voice is ready. Install one in Android text-to-speech settings, then retry.", null)
                    else -> result.notImplemented()
                }
            } catch (error: Exception) { result.error("android", "Android could not complete this action. Check permissions and retry.", null) }
        }
    }
    fun close() { channel.setMethodCallHandler(null); speech.close() }
}
