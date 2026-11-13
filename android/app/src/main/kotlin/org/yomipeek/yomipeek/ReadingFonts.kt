package org.yomipeek.yomipeek

import android.content.Context
import android.graphics.Typeface
import org.json.JSONObject
import java.io.File

internal data class ReadingFont(val key: String = "system", val file: String = "", val scale: Float = 1f, val lineHeight: Float = 1.6f)
internal object ReadingFonts {
    private val presets = mapOf("gothic" to "noto-sans-jp", "mincho" to "noto-serif-jp", "rounded" to "zen-maru-gothic")
    private val faces = mutableMapOf<String, Typeface>()
    fun file(context: Context, name: String): File {
        require(Regex("^font-[a-z0-9]+\\.(ttf|otf)$").matches(name))
        val root = File(context.filesDir, "fonts").canonicalFile
        val candidate = File(root, name).canonicalFile
        require(candidate.parentFile == root && candidate.isFile && candidate.length() in 12..(32L * 1024 * 1024))
        return candidate
    }
    fun validate(context: Context, name: String) { requireNotNull(Typeface.Builder(file(context, name)).setWeight(400).build()) { "The font could not be decoded." } }
    fun save(context: Context, args: Map<*, *>) {
        val key = args["key"] as? String ?: "system"
        val name = args["file"] as? String ?: ""
        require(key == "system" || presets.containsKey(key) || Regex("^custom-[a-z0-9]+$").matches(key))
        if (key.startsWith("custom-")) validate(context, name)
        val scale = ((args["scale"] as? Number)?.toDouble() ?: 1.0).coerceIn(.85, 1.4)
        val height = ((args["lineHeight"] as? Number)?.toDouble() ?: 1.6).coerceIn(1.2, 2.2)
        require(scale.isFinite() && height.isFinite())
        val json = JSONObject().put("key", key).put("file", name).put("scale", scale).put("lineHeight", height)
        context.getSharedPreferences("floating", Context.MODE_PRIVATE).edit().putString("typography", json.toString()).apply()
    }
    fun read(context: Context): ReadingFont = try {
        val json = JSONObject(context.getSharedPreferences("floating", Context.MODE_PRIVATE).getString("typography", "{}") ?: "{}")
        ReadingFont(json.optString("key", "system"), json.optString("file", ""), json.optDouble("scale", 1.0).coerceIn(.85, 1.4).toFloat(), json.optDouble("lineHeight", 1.6).coerceIn(1.2, 2.2).toFloat())
    } catch (_: Exception) { ReadingFont() }
    fun face(context: Context, settings: ReadingFont): Typeface? = try {
        when {
            settings.key == "system" -> null
            presets.containsKey(settings.key) -> faces.getOrPut(settings.key) { Typeface.Builder(context.assets, "flutter_assets/assets/fonts/${presets[settings.key]}/font.ttf").setWeight(400).build() }
            else -> faces.getOrPut(settings.file) { Typeface.Builder(file(context, settings.file)).setWeight(400).build() }
        }
    } catch (_: Exception) { null }
}
