package org.yomipeek.yomipeek

import android.app.Activity
import android.os.Bundle
import android.content.Intent
import android.provider.Settings

/** Only receives text explicitly selected and sent by a compatible host app. */
class TextSelectionHandler: Activity() {
    private var delivered = false
    override fun onCreate(state: Bundle?) { super.onCreate(state) }
    override fun onPostResume() {
        super.onPostResume()
        if (delivered) return
        delivered = true
        val text = try { boundedText(intent.getCharSequenceExtra(Intent.EXTRA_PROCESS_TEXT)) } catch (_: Exception) { "" }
        if (Settings.canDrawOverlays(this)) {
            try {
                OverlayService.start(this, OverlayService.LOOKUP, text)
                finish(); return
            } catch (_: Exception) { /* Fall back to the full app; selection remains usable. */ }
        }
        startActivity(Intent(this, MainActivity::class.java).putExtra("lookup_text", text).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP))
        finish()
    }
}
