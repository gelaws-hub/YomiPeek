package org.yomipeek.yomipeek

import android.app.*
import android.content.*
import android.content.ClipboardManager
import android.content.res.Configuration
import android.content.pm.ServiceInfo
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.graphics.drawable.RippleDrawable
import android.content.res.ColorStateList
import android.os.*
import android.provider.Settings
import android.text.*
import android.text.method.LinkMovementMethod
import android.text.style.ClickableSpan
import android.view.*
import android.view.inputmethod.InputMethodManager
import android.widget.*
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import kotlin.math.abs

/** User-started, bounded native overlay. The service owns its headless search engine. */
class OverlayService: Service() {
    companion object {
        const val LOOKUP = "org.yomipeek.LOOKUP"
        const val SHORTCUT = "org.yomipeek.SHORTCUT"
        const val STOP = "org.yomipeek.STOP"
        private const val CHANNEL = "floating_lookup"
        fun shortcutEnabled(context: Context) = context.getSharedPreferences("floating", MODE_PRIVATE).getBoolean("shortcut", false)
        fun setShortcut(context: Context, enabled: Boolean) { context.getSharedPreferences("floating", MODE_PRIVATE).edit().putBoolean("shortcut", enabled).apply() }
        fun start(context: Context, action: String, text: String = "") {
            context.startForegroundService(Intent(context, OverlayService::class.java).setAction(action).putExtra("text", boundedText(text)))
        }
    }
    private lateinit var windows: WindowManager
    private val handler = Handler(Looper.getMainLooper())
    private var panel: LinearLayout? = null
    private var bubble: LinearLayout? = null
    private var panelParams: WindowManager.LayoutParams? = null
    private var query: EditText? = null
    private var content: LinearLayout? = null
    private var status: TextView? = null
    private var engine: FlutterEngine? = null
    private var bridge: MethodChannel? = null
    private var ready = false
    private var generation = 0
    private var pendingSearch: Runnable? = null
    private var speech: JapaneseSpeech? = null
    private var sourceText = ""
    private var destroyed = false

    private val permissionChanges = AppOpsManager.OnOpChangedListener { _, packageChanged ->
        if (packageChanged == packageName) handler.post { if (!Settings.canDrawOverlays(this)) { setShortcut(this, false); stopSelf() } }
    }
    override fun onBind(intent: Intent?) = null
    private fun dp(value: Int) = (value * resources.displayMetrics.density).toInt()
    override fun onCreate() {
        super.onCreate()
        windows = getSystemService(WINDOW_SERVICE) as WindowManager
        (getSystemService(APP_OPS_SERVICE) as AppOpsManager).startWatchingMode(AppOpsManager.OPSTR_SYSTEM_ALERT_WINDOW, packageName, permissionChanges)
        speech = JapaneseSpeech(this)
        val notifications = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        notifications.createNotificationChannel(NotificationChannel(CHANNEL, "Floating dictionary", NotificationManager.IMPORTANCE_LOW))
    }
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == STOP) { setShortcut(this, false); stopSelf(); return START_NOT_STICKY }
        if (!Settings.canDrawOverlays(this)) { setShortcut(this, false); stopSelf(); return START_NOT_STICKY }
        try {
            val stop = PendingIntent.getService(this, 1, Intent(this, OverlayService::class.java).setAction(STOP), PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            val open = PendingIntent.getActivity(this, 2, Intent(this, MainActivity::class.java), PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            val notification = Notification.Builder(this, CHANNEL).setSmallIcon(R.drawable.yomipeek_notification).setContentTitle("YomiPeek floating lookup")
                .setContentText("Tap the shortcut to look up a word. Stop to close all floating windows.")
                .setContentIntent(open).setOngoing(true).addAction(Notification.Action.Builder(null, "Stop", stop).build()).build()
            if (Build.VERSION.SDK_INT >= 34) startForeground(41, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE) else startForeground(41, notification)
            if (shortcutEnabled(this)) showBubble()
            if (intent?.action == LOOKUP) showPanel(boundedText(intent.getStringExtra("text")))
        } catch (error: Exception) {
            android.util.Log.e("YomiPeek", "Floating service failed to open", error)
            Toast.makeText(this, "Floating lookup could not open. Check overlay permission in Android settings.", Toast.LENGTH_LONG).show()
            setShortcut(this, false); stopSelf()
        }
        return START_NOT_STICKY
    }
    private fun background(color: Int, radius: Int = 20) = GradientDrawable().apply { setColor(color); cornerRadius = dp(radius).toFloat() }
    private val dark get() = (resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK) == Configuration.UI_MODE_NIGHT_YES
    private val inkColor get() = if (dark) Color.rgb(230, 240, 233) else Color.rgb(25, 40, 35)
    private val green get() = if (dark) Color.rgb(140, 205, 183) else Color.rgb(56, 103, 92)
    private val panelColor get() = if (dark) Color.rgb(23, 31, 28) else Color.rgb(247, 250, 247)
    private val cardColor get() = if (dark) Color.rgb(36, 46, 41) else Color.WHITE
    private fun label(value: String, size: Float = 16f) = TextView(this).apply { text = value; textSize = size; setTextColor(inkColor); setPadding(dp(4), dp(4), dp(4), dp(4)) }
    private fun iconButton(icon: Int, description: String, onAccent: Boolean = false, action: () -> Unit) = ImageButton(this).apply {
        setImageResource(icon)
        contentDescription = description
        tooltipText = description
        minimumWidth = dp(48); minimumHeight = dp(48)
        setPadding(dp(12), dp(12), dp(12), dp(12))
        scaleType = ImageView.ScaleType.CENTER
        val tint = if (onAccent) { if (dark) Color.rgb(23, 31, 28) else Color.WHITE } else green
        imageTintList = ColorStateList.valueOf(tint)
        val surface = if (onAccent) green else if (dark) Color.rgb(45, 64, 55) else Color.rgb(225, 239, 232)
        background = RippleDrawable(ColorStateList.valueOf(Color.argb(38, Color.red(tint), Color.green(tint), Color.blue(tint))), background(surface, if (onAccent) 24 else 12), null)
        elevation = 0f; stateListAnimator = null
        setOnClickListener { action() }
    }
    private fun params(width: Int, height: Int) = WindowManager.LayoutParams(width, height, WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
        WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL, PixelFormat.TRANSLUCENT).apply {
            gravity = Gravity.TOP or Gravity.START; x = dp(16); y = dp(96)
            softInputMode = WindowManager.LayoutParams.SOFT_INPUT_ADJUST_RESIZE
        }
    private fun showBubble() {
        if (bubble != null) return
        val row = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL; background = background(green, 24); elevation = dp(8).toFloat() }
        val open = iconButton(R.drawable.ic_lookup_search, "Open YomiPeek floating lookup", true) { showPanel("") }.apply { contentDescription = "Open YomiPeek floating lookup" }
        val close = iconButton(R.drawable.ic_lookup_close, "Stop YomiPeek floating shortcut", true) { setShortcut(this, false); stopSelf() }.apply { contentDescription = "Stop YomiPeek floating shortcut" }
        row.addView(open, LinearLayout.LayoutParams(dp(52), dp(52))); row.addView(close, LinearLayout.LayoutParams(dp(48), dp(52)))
        val layout = params(dp(100), dp(52)).apply { x = maxOf(0, resources.displayMetrics.widthPixels - dp(116)); y = resources.displayMetrics.heightPixels / 2 }
        drag(open, row, layout, true)
        windows.addView(row, layout); bubble = row
    }
    private fun showPanel(text: String) {
        if (destroyed) return
        sourceText = text
        if (panel != null) {
            query?.setText(if (text.length <= 64) text else "")
            renderSource()
            if (text.length > 64) chooseWord(0) else scheduleSearch()
            return
        }
        val root = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL; background = background(panelColor); elevation = dp(16).toFloat(); setPadding(dp(10), dp(8), dp(10), dp(8)) }
        val width = minOf(resources.displayMetrics.widthPixels - dp(24), dp(390))
        val height = minOf((resources.displayMetrics.heightPixels * 0.68).toInt(), dp(560))
        val layout = params(width, height)
        panelParams = layout
        val header = LinearLayout(this).apply { gravity = Gravity.CENTER_VERTICAL }
        val title = label("YomiPeek", 14f).apply { setTypeface(null, Typeface.BOLD); contentDescription = "Drag floating dictionary"; setCompoundDrawablesRelativeWithIntrinsicBounds(R.drawable.ic_lookup_drag, 0, 0, 0); compoundDrawablePadding = dp(8); compoundDrawableTintList = ColorStateList.valueOf(green) }
        drag(title, root, layout, false)
        header.addView(title, LinearLayout.LayoutParams(0, dp(48), 1f))
        header.addView(iconButton(R.drawable.ic_lookup_expand, "Open lookup in full YomiPeek app") {
            val selected = query?.text?.toString().orEmpty()
            startActivity(Intent(this, MainActivity::class.java).putExtra("lookup_text", selected).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP))
            closePanel()
        }.apply { contentDescription = "Open lookup in full YomiPeek app" }, LinearLayout.LayoutParams(dp(48), dp(48)))
        header.addView(iconButton(R.drawable.ic_lookup_close, "Close floating dictionary") { closePanel() }.apply { contentDescription = "Close floating dictionary" }, LinearLayout.LayoutParams(dp(48), dp(48)))
        root.addView(header)
        val inputRow = LinearLayout(this)
        val edit = EditText(this).apply {
            hint = "Japanese or definition"; setSingleLine(true); textSize = 16f; setTextColor(inkColor); setHintTextColor(if (dark) Color.LTGRAY else Color.DKGRAY)
            filters = arrayOf(InputFilter.LengthFilter(512)); imeOptions = android.view.inputmethod.EditorInfo.IME_ACTION_SEARCH
            setOnTouchListener { _, event -> if (event.action == MotionEvent.ACTION_DOWN) focusPanel(true); false }
            setOnEditorActionListener { _, action, _ -> if (action == android.view.inputmethod.EditorInfo.IME_ACTION_SEARCH) { search(); bridge?.invokeMethod("remember", this.text.toString()); unfocusPanel(); true } else false }
            addTextChangedListener(object: TextWatcher { override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) {} ; override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) { scheduleSearch() }; override fun afterTextChanged(s: Editable?) {} })
        }
        query = edit
        inputRow.addView(edit, LinearLayout.LayoutParams(0, dp(56), 1f))
        inputRow.addView(iconButton(R.drawable.ic_lookup_paste, "Paste text") {
            focusPanel(false)
            handler.postDelayed({
                if (panel == null) return@postDelayed
                val clip = (getSystemService(CLIPBOARD_SERVICE) as ClipboardManager).primaryClip
                val value = if (clip != null && clip.itemCount > 0) boundedText(clip.getItemAt(0).text, 512) else ""
                edit.setText(value); unfocusPanel()
                if (value.isEmpty()) Toast.makeText(this, "No plain text is available to paste.", Toast.LENGTH_SHORT).show()
            }, 120)
        }, LinearLayout.LayoutParams(dp(48), dp(56)))
        root.addView(inputRow)
        status = label("Opening offline dictionary…", 13f); root.addView(status)
        val scroll = ScrollView(this)
        content = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL }
        scroll.addView(content); root.addView(scroll, LinearLayout.LayoutParams(-1, 0, 1f))
        windows.addView(root, layout); panel = root
        edit.setText(if (text.length <= 64) text else "")
        renderSource(); ensureEngine()
        if (text.length > 64 && ready) chooseWord(0) else scheduleSearch()
    }
    private fun ensureEngine() {
        if (engine != null) return
        val created = FlutterEngine(this)
        engine = created
        val channel = MethodChannel(created.dartExecutor.binaryMessenger, "org.yomipeek/overlay")
        bridge = channel
        channel.setMethodCallHandler { call, result ->
            if (call.method == "ready") {
                ready = true; result.success(null)
                if (panel != null && sourceText.length > 64) chooseWord(0) else search()
            } else result.notImplemented()
        }
        val loader = FlutterInjector.instance().flutterLoader()
        created.dartExecutor.executeDartEntrypoint(DartExecutor.DartEntrypoint(loader.findAppBundlePath(), "overlayMain"))
        handler.postDelayed({ if (!destroyed && !ready) status?.text = "Dictionary startup is taking longer than expected. Close and reopen to retry." }, 15000)
    }
    private fun scheduleSearch() {
        generation++
        pendingSearch?.let { handler.removeCallbacks(it) }
        val task = Runnable { search() }; pendingSearch = task; handler.postDelayed(task, 250)
    }
    private fun search() {
        if (!ready || panel == null || destroyed) return
        val text = query?.text?.toString().orEmpty().trim()
        val request = ++generation
        if (text.isEmpty()) { status?.text = "Enter a word, paste explicitly, or tap a character in selected text."; content?.removeAllViews(); renderSource(); return }
        status?.text = "Searching offline…"
        bridge?.invokeMethod("search", text, object: MethodChannel.Result {
            override fun success(result: Any?) {
                if (destroyed || panel == null || request != generation) return
                content?.removeAllViews(); renderSource()
                val words = (result as? List<*>)?.mapNotNull { it as? Map<*, *> }.orEmpty()
                status?.text = if (words.isEmpty()) "No results. Import/enable a dictionary or try a shorter word." else "${words.size} results · up to 30 shown"
                words.forEach { renderWord(it) }
            }
            override fun error(code: String, message: String?, details: Any?) { if (request == generation) status?.text = "Could not read local dictionaries. Open the full app to retry." }
            override fun notImplemented() { error("bridge", null, null) }
        })
    }
    private fun renderSource() {
        val target = content ?: return
        if (sourceText.isEmpty()) return
        // Rebuild once per result list; callers clear content before invoking this.
        if (target.findViewWithTag<TextView>("source") != null) return
        val text = SpannableString(sourceText)
        var offset = 0
        while (offset < sourceText.length) {
            val start = offset
            offset += Character.charCount(sourceText.codePointAt(offset))
            text.setSpan(object: ClickableSpan() { override fun onClick(widget: View) { chooseWord(start) }; override fun updateDrawState(ds: TextPaint) { ds.color = green; ds.isUnderlineText = false } }, start, offset, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
        }
        target.addView(label("Selected text · tap a word's first character", 12f))
        target.addView(label("", 18f).apply { tag = "source"; this.text = text; movementMethod = LinkMovementMethod.getInstance() })
    }
    private fun chooseWord(offset: Int) {
        if (!ready) return
        pendingSearch?.let { handler.removeCallbacks(it) }; pendingSearch = null
        val request = ++generation
        status?.text = "Finding a dictionary match…"
        bridge?.invokeMethod("wordAt", mapOf("text" to sourceText, "offset" to offset), object: MethodChannel.Result {
            override fun success(result: Any?) { if (!destroyed && panel != null && request == generation) query?.setText(result as? String ?: "") }
            override fun error(code: String, message: String?, details: Any?) { if (request == generation) status?.text = "No word could be selected. Edit the lookup field instead." }
            override fun notImplemented() { error("bridge", null, null) }
        })
    }
    private fun renderWord(word: Map<*, *>) {
        val card = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL; setPadding(dp(10), dp(10), dp(10), dp(14)); background = background(cardColor, 12) }
        fun value(key: String) = word[key] as? String ?: ""
        card.addView(label(value("expression"), 25f).apply { setTypeface(null, Typeface.BOLD) })
        if (value("reading").isNotEmpty()) card.addView(label(value("reading"), 17f))
        if (value("tags").isNotEmpty()) card.addView(label(value("tags"), 12f))
        if (value("inflection").isNotEmpty()) card.addView(label("Matched via ${value("inflection")}", 12f))
        card.addView(label(value("definitions"), 16f).apply { setTextIsSelectable(true) })
        card.addView(label(value("source"), 12f))
        val actions = LinearLayout(this)
        val save = iconButton(R.drawable.ic_lookup_save, "Save word") {}
        save.setOnClickListener {
            save.isEnabled = false
            bridge?.invokeMethod("save", word, object: MethodChannel.Result {
                override fun success(result: Any?) { save.setImageResource(R.drawable.ic_lookup_saved); save.contentDescription = "Word saved"; save.tooltipText = "Word saved"; sendBroadcast(Intent("org.yomipeek.USER_DATA_CHANGED").setPackage(packageName)) }
                override fun error(code: String, message: String?, details: Any?) { save.isEnabled = true; Toast.makeText(this@OverlayService, "Word could not be saved. Retry in the full app.", Toast.LENGTH_LONG).show() }
                override fun notImplemented() { error("bridge", null, null) }
            })
        }
        actions.addView(save, LinearLayout.LayoutParams(dp(48), dp(48)))
        actions.addView(iconButton(R.drawable.ic_lookup_speak, "Speak Japanese") { if (speech?.speak(value("reading").ifEmpty { value("expression") }) != true) Toast.makeText(this, "Install an offline Japanese text-to-speech voice to use pronunciation.", Toast.LENGTH_LONG).show() }, LinearLayout.LayoutParams(dp(48), dp(48)).apply { marginStart = dp(8) })
        card.addView(actions)
        content?.addView(card, LinearLayout.LayoutParams(-1, -2).apply { topMargin = dp(8) })
    }
    private fun focusPanel(keyboard: Boolean) {
        val root = panel ?: return
        val layout = panelParams ?: return
        layout.flags = layout.flags and WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE.inv()
        windows.updateViewLayout(root, layout)
        if (keyboard) { query?.requestFocus(); (getSystemService(INPUT_METHOD_SERVICE) as InputMethodManager).showSoftInput(query, InputMethodManager.SHOW_IMPLICIT) }
        else { root.isFocusableInTouchMode = true; root.requestFocus() }
    }
    private fun unfocusPanel() {
        val root = panel ?: return
        (getSystemService(INPUT_METHOD_SERVICE) as InputMethodManager).hideSoftInputFromWindow(root.windowToken, 0)
        val layout = panelParams ?: return
        layout.flags = layout.flags or WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE
        windows.updateViewLayout(root, layout)
    }
    private fun drag(handle: View, window: View, layout: WindowManager.LayoutParams, click: Boolean) {
        var startX = 0f; var startY = 0f; var x = 0; var y = 0; var moved = false
        handle.setOnTouchListener { view, event ->
            when (event.action) {
                MotionEvent.ACTION_DOWN -> { startX = event.rawX; startY = event.rawY; x = layout.x; y = layout.y; moved = false; true }
                MotionEvent.ACTION_MOVE -> {
                    if (abs(event.rawX - startX) > dp(6) || abs(event.rawY - startY) > dp(6)) moved = true
                    if (moved) { layout.x = (x + event.rawX.toInt() - startX.toInt()).coerceIn(0, maxOf(0, resources.displayMetrics.widthPixels - window.width)); layout.y = (y + event.rawY.toInt() - startY.toInt()).coerceIn(0, maxOf(0, resources.displayMetrics.heightPixels - window.height - dp(32))); try { windows.updateViewLayout(window, layout) } catch (_: IllegalArgumentException) { /* View was dismissed during the gesture. */ } }
                    true
                }
                MotionEvent.ACTION_UP -> { if (!moved && click) view.performClick(); true }
                else -> false
            }
        }
    }
    private fun closePanel() {
        generation++
        panel?.let { unfocusPanel(); try { windows.removeView(it) } catch (_: IllegalArgumentException) {} }
        panel = null; query = null; content = null; status = null; panelParams = null
        if (!shortcutEnabled(this)) stopSelf()
    }
    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)
        panel?.let { window -> panelParams?.let { layout ->
            layout.width = minOf(resources.displayMetrics.widthPixels - dp(24), dp(390))
            layout.height = minOf((resources.displayMetrics.heightPixels * 0.68).toInt(), dp(560))
            layout.x = layout.x.coerceIn(0, maxOf(0, resources.displayMetrics.widthPixels - layout.width))
            layout.y = layout.y.coerceIn(0, maxOf(0, resources.displayMetrics.heightPixels - layout.height - dp(32)))
            windows.updateViewLayout(window, layout)
        } }
        bubble?.let { window -> val layout = window.layoutParams as WindowManager.LayoutParams
            layout.x = layout.x.coerceIn(0, maxOf(0, resources.displayMetrics.widthPixels - window.width))
            layout.y = layout.y.coerceIn(0, maxOf(0, resources.displayMetrics.heightPixels - window.height - dp(32)))
            windows.updateViewLayout(window, layout)
        }
    }
    override fun onDestroy() {
        (getSystemService(APP_OPS_SERVICE) as AppOpsManager).stopWatchingMode(permissionChanges)
        destroyed = true; generation++; handler.removeCallbacksAndMessages(null)
        panel?.let { try { windows.removeView(it) } catch (_: IllegalArgumentException) {} }; panel = null
        bubble?.let { try { windows.removeView(it) } catch (_: IllegalArgumentException) {} }; bubble = null
        speech?.close(); speech = null
        val current = engine; engine = null
        if (current != null) {
            var released = false
            fun release() { if (!released) { released = true; current.destroy() } }
            bridge?.invokeMethod("dispose", null, object: MethodChannel.Result { override fun success(result: Any?) = release(); override fun error(code: String, message: String?, details: Any?) = release(); override fun notImplemented() = release() })
            handler.postDelayed({ release() }, 1500)
        }
        sendBroadcast(Intent("org.yomipeek.USER_DATA_CHANGED").setPackage(packageName))
        bridge = null; stopForeground(STOP_FOREGROUND_REMOVE)
        super.onDestroy()
    }
}
