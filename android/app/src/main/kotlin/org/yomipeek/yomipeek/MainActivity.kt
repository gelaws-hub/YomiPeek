package org.yomipeek.yomipeek

import android.content.Intent
import android.content.IntentFilter
import android.content.BroadcastReceiver
import android.content.Context
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private var integration: PlatformChannelHandler? = null
    private var pendingSelection: String? = null
    private var dartReady = false
    private var registered = false
    private val changes = object: BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) { integration?.channel?.invokeMethod("changed", null) }
    }
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        pendingSelection = intent?.getStringExtra("lookup_text")?.let { boundedText(it) }
        val filter = IntentFilter("org.yomipeek.USER_DATA_CHANGED")
        if (Build.VERSION.SDK_INT >= 33) registerReceiver(changes, filter, RECEIVER_NOT_EXPORTED) else registerReceiver(changes, filter)
        registered = true
        integration = PlatformChannelHandler(this, MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "org.yomipeek/platform"))
    }
    fun takeSelection(): String? { dartReady = true; val value = pendingSelection; pendingSelection = null; return value }
    private fun deliverSelection(text: String) {
        val bounded = boundedText(text); pendingSelection = bounded
        if (!dartReady) return
        integration?.channel?.invokeMethod("selection", bounded, object: MethodChannel.Result {
            override fun success(result: Any?) { if (pendingSelection == bounded) pendingSelection = null }
            override fun error(code: String, message: String?, details: Any?) {}
            override fun notImplemented() {}
        })
    }
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val text = intent.getStringExtra("lookup_text") ?: if (intent.action == Intent.ACTION_PROCESS_TEXT) boundedText(intent.getCharSequenceExtra(Intent.EXTRA_PROCESS_TEXT)) else return
        deliverSelection(text)
    }
    override fun onPostResume() {
        super.onPostResume()
        OverlayService.setHostVisible(true)
        android.util.Log.d("YomiPeek", "Activity resumed; overlay permission=${Settings.canDrawOverlays(this)}")
        integration?.channel?.invokeMethod("changed", null)
        if (OverlayService.shortcutEnabled(this) && Settings.canDrawOverlays(this)) {
            try { OverlayService.start(this, OverlayService.SHORTCUT) } catch (_: Exception) { OverlayService.setShortcut(this, false); android.widget.Toast.makeText(this, "Floating lookup could not resume. Enable it again in settings.", android.widget.Toast.LENGTH_LONG).show() }
        }
    }
    override fun onPause() {
        OverlayService.setHostVisible(false)
        super.onPause()
    }
    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        if (registered) { unregisterReceiver(changes); registered = false }
        integration?.close(); integration = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
