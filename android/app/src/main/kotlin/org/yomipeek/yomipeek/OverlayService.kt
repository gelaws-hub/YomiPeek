package org.yomipeek.yomipeek

import android.app.*
import android.animation.ValueAnimator
import java.util.Locale
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
import android.view.animation.DecelerateInterpolator
import android.view.animation.AccelerateInterpolator
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
        private var active: OverlayService? = null
        private var hostVisible = false
        fun setHostVisible(visible: Boolean) { hostVisible = visible; active?.updateShortcutVisibility() }
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
    private var expanded = false
    private var resizing: ValueAnimator? = null
    private var readingFont = ReadingFont()
    private var readingFace: Typeface? = null
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
    private var closing = false
    private val browsingHistory = java.util.ArrayDeque<Pair<String, String>>()
    private var backButton: ImageButton? = null
    private val appearanceChanges = SharedPreferences.OnSharedPreferenceChangeListener { _, key ->
        if (key == "theme" || key == "typography") handler.post { rebuildAppearance() }
    }
    private fun rebuildAppearance() {
        val wasClosing = closing
        val wasExpanded = expanded
        readingFont = ReadingFonts.read(this); readingFace = ReadingFonts.face(this, readingFont)
        resizing?.cancel(); resizing = null
        val selected = sourceText
        val value = query?.text?.toString()
        val position = panelParams?.let { Pair(it.x, it.y) }
        panel?.let { it.animate().cancel(); try { windows.removeView(it) } catch (_: IllegalArgumentException) {} }
        panel = null; closing = false
        bubble?.let { try { windows.removeView(it) } catch (_: IllegalArgumentException) {} }; bubble = null
        if (shortcutEnabled(this)) showBubble()
        if (wasClosing) {
            query = null; content = null; status = null; panelParams = null; browsingHistory.clear()
            if (!shortcutEnabled(this)) stopSelf()
            return
        }
        if (value != null) {
            showPanel(selected); query?.setText(value); resizePanel(wasExpanded, false)
            panelParams?.let { layout -> position?.let { layout.x = it.first; layout.y = it.second; panel?.let { windows.updateViewLayout(it, layout) } } }
        }
    }

    private val permissionChanges = AppOpsManager.OnOpChangedListener { _, packageChanged ->
        if (packageChanged == packageName) handler.post { if (!Settings.canDrawOverlays(this)) { setShortcut(this, false); stopSelf() } }
    }
    override fun onBind(intent: Intent?) = null
    private fun dp(value: Int) = (value * resources.displayMetrics.density).toInt()
    override fun onCreate() {
        super.onCreate()
        active = this
        windows = getSystemService(WINDOW_SERVICE) as WindowManager
        (getSystemService(APP_OPS_SERVICE) as AppOpsManager).startWatchingMode(AppOpsManager.OPSTR_SYSTEM_ALERT_WINDOW, packageName, permissionChanges)
        getSharedPreferences("floating", MODE_PRIVATE).registerOnSharedPreferenceChangeListener(appearanceChanges)
        readingFont = ReadingFonts.read(this); readingFace = ReadingFonts.face(this, readingFont)
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
            val notification = Notification.Builder(this, CHANNEL).setSmallIcon(R.drawable.yomipeek_icon_monochrome).setContentTitle("YomiPeek floating lookup")
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
    private val dark get() = when (getSharedPreferences("floating", MODE_PRIVATE).getString("theme", "system")) {
        "dark" -> true
        "light" -> false
        else -> (resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK) == Configuration.UI_MODE_NIGHT_YES
    }
    private val inkColor get() = if (dark) Color.rgb(226, 237, 230) else Color.rgb(31, 43, 37)
    private val green get() = if (dark) Color.rgb(155, 212, 193) else Color.rgb(40, 95, 83)
    private val panelColor get() = if (dark) Color.rgb(16, 26, 24) else Color.rgb(245, 241, 232)
    private val cardColor get() = if (dark) Color.rgb(24, 35, 33) else Color.rgb(255, 252, 245)
    private fun label(value: String, size: Float = 16f) = TextView(this).apply { text = value; textSize = size; setTextColor(inkColor); setPadding(dp(4), dp(5), dp(4), dp(5)); setLineSpacing(dp(2).toFloat(), 1.1f) }
    private fun readingLabel(value: String, size: Float = 16f) = label(value, size * readingFont.scale).apply {
        typeface = readingFace
        textLocale = Locale.JAPANESE
        includeFontPadding = false
        val metrics = paint.fontMetricsInt
        setLineSpacing(textSize * readingFont.lineHeight - (metrics.descent - metrics.ascent), 1f)
    }
    private fun panelWidth(large: Boolean) = minOf(resources.displayMetrics.widthPixels - dp(24), dp(if (large) 390 else 320))
    private fun panelHeight(large: Boolean) = minOf((resources.displayMetrics.heightPixels * .68).toInt(), if (large) dp(560) else dp(196) + (maxOf(0f, resources.configuration.fontScale - 1f) * dp(64)).toInt())
    private fun resizePanel(large: Boolean, animate: Boolean = true) {
        val root = panel ?: return
        val layout = panelParams ?: return
        if (closing || destroyed) return
        expanded = large
        resizing?.cancel(); resizing = null
        val width = panelWidth(large); val height = panelHeight(large)
        val x = layout.x.coerceIn(0, maxOf(0, resources.displayMetrics.widthPixels - width))
        val y = layout.y.coerceIn(0, maxOf(0, resources.displayMetrics.heightPixels - height - dp(32)))
        if (layout.width == width && layout.height == height && layout.x == x && layout.y == y) return
        val startWidth = layout.width; val startHeight = layout.height; val startX = layout.x; val startY = layout.y
        fun update(progress: Float) {
            if (panel !== root || closing || destroyed) return
            layout.width = (startWidth + (width - startWidth) * progress).toInt()
            layout.height = (startHeight + (height - startHeight) * progress).toInt()
            layout.x = (startX + (x - startX) * progress).toInt(); layout.y = (startY + (y - startY) * progress).toInt()
            try { windows.updateViewLayout(root, layout) } catch (_: IllegalArgumentException) {}
        }
        if (!animate || !ValueAnimator.areAnimatorsEnabled()) { update(1f); return }
        resizing = ValueAnimator.ofFloat(0f, 1f).apply { duration = 240; interpolator = DecelerateInterpolator(); addUpdateListener { update(it.animatedValue as Float) }; start() }
    }
    private fun iconButton(icon: Int, description: String, onAccent: Boolean = false, action: () -> Unit) = ImageButton(this).apply {
        setImageResource(icon)
        contentDescription = description
        tooltipText = description
        minimumWidth = dp(48); minimumHeight = dp(48)
        setPadding(dp(12), dp(12), dp(12), dp(12))
        scaleType = ImageView.ScaleType.CENTER
        val tint = if (onAccent) { if (dark) Color.rgb(23, 31, 28) else Color.WHITE } else green
        imageTintList = ColorStateList.valueOf(tint)
        val surface = if (description == "Close floating dictionary") { if (dark) Color.rgb(38, 49, 45) else Color.rgb(231, 226, 216) } else if (onAccent) green else if (dark) Color.rgb(45, 64, 55) else Color.rgb(225, 239, 232)
        background = RippleDrawable(ColorStateList.valueOf(Color.argb(38, Color.red(tint), Color.green(tint), Color.blue(tint))), background(surface, if (onAccent || description == "Close floating dictionary") 24 else 14), null)
        elevation = 0f; stateListAnimator = null
        setOnClickListener { action() }
    }
    private fun params(width: Int, height: Int) = WindowManager.LayoutParams(width, height, WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
        WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL, PixelFormat.TRANSLUCENT).apply {
            gravity = Gravity.TOP or Gravity.START; x = dp(16); y = dp(96)
            softInputMode = WindowManager.LayoutParams.SOFT_INPUT_ADJUST_RESIZE
        }
    private fun updateShortcutVisibility() {
        if (hostVisible) {
            bubble?.let { it.animate().cancel(); try { windows.removeView(it) } catch (_: IllegalArgumentException) {} }; bubble = null
        } else if (shortcutEnabled(this) && !destroyed) showBubble()
    }
    private fun showBubble() {
        if (bubble != null || hostVisible) return
        val row = LinearLayout(this).apply { background = null; elevation = 0f; setPadding(0, 0, 0, 0) }
        val open = iconButton(R.drawable.yomipeek_mark, "Open YomiPeek floating lookup", true) { showPanel("") }.apply { imageTintList = null; setPadding(0, 0, 0, 0); scaleType = ImageView.ScaleType.FIT_CENTER; background = background(Color.rgb(40, 95, 83), 24) }
        open.tooltipText = "Tap to search · hold to dismiss shortcut"
        open.setOnLongClickListener { setShortcut(this, false); stopSelf(); true }
        row.addView(open, LinearLayout.LayoutParams(dp(48), dp(48)))
        val layout = params(dp(56), dp(56)).apply { x = maxOf(0, resources.displayMetrics.widthPixels - dp(72)); y = resources.displayMetrics.heightPixels / 2 }
        drag(open, row, layout, true)
        windows.addView(row, layout); bubble = row
        row.alpha = 0f; row.scaleX = .85f; row.scaleY = .85f
        row.animate().alpha(1f).scaleX(1f).scaleY(1f).setDuration(180).start()
    }
    private fun showPanel(text: String) {
        if (destroyed) return
        if (closing) {
            panel?.let { it.animate().cancel(); try { windows.removeView(it) } catch (_: IllegalArgumentException) {} }
            panel = null; closing = false
        }
        sourceText = text
        if (panel != null) {
            content?.removeAllViews(); resizePanel(false)
            query?.setText(if (text.length <= 64) text else "")
            renderSource()
            if (text.length > 64) chooseWord(0) else scheduleSearch()
            return
        }
        val root = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL; background = background(panelColor); elevation = dp(16).toFloat(); setPadding(dp(10), dp(8), dp(10), dp(8)) }
        expanded = false
        val width = panelWidth(false)
        val height = panelHeight(false)
        val layout = params(width, height)
        panelParams = layout
        val header = LinearLayout(this).apply { gravity = Gravity.CENTER_VERTICAL }
        header.addView(ImageView(this).apply { setImageResource(R.drawable.yomipeek_mark); scaleType = ImageView.ScaleType.FIT_CENTER; background = background(Color.rgb(40, 95, 83), 14); setPadding(dp(2), dp(2), dp(2), dp(2)) }, LinearLayout.LayoutParams(dp(28), dp(28)).apply { marginEnd = dp(6) })
        backButton = iconButton(R.drawable.ic_lookup_back, "Back to previous word") {
            if (!browsingHistory.isEmpty()) { val previous = browsingHistory.removeLast(); sourceText = previous.second; query?.setText(previous.first); backButton?.visibility = if (browsingHistory.isEmpty()) View.GONE else View.VISIBLE }
        }
        header.addView(backButton, LinearLayout.LayoutParams(dp(48), dp(48)))
        backButton?.visibility = if (browsingHistory.isEmpty()) View.GONE else View.VISIBLE
        val title = label("YomiPeek", 14f).apply { setTypeface(null, Typeface.BOLD); contentDescription = "Drag floating dictionary"; setCompoundDrawablesRelativeWithIntrinsicBounds(R.drawable.ic_lookup_drag, 0, 0, 0); compoundDrawablePadding = dp(8); compoundDrawableTintList = ColorStateList.valueOf(green) }
        drag(title, root, layout, false)
        header.addView(title, LinearLayout.LayoutParams(0, dp(48), 1f))
        header.addView(iconButton(R.drawable.ic_lookup_expand, "Open lookup in full YomiPeek app") {
            val selected = query?.text?.toString().orEmpty()
            startActivity(Intent(this, MainActivity::class.java).putExtra("lookup_text", if (selected.isNotEmpty() && sourceText.contains(selected) && sourceText.any { it in "。！？" }) sourceText else selected).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP))
            closePanel()
        }.apply { contentDescription = "Open lookup in full YomiPeek app" }, LinearLayout.LayoutParams(dp(48), dp(48)))
        header.addView(iconButton(R.drawable.ic_lookup_close, "Close floating dictionary") { closePanel() }.apply { contentDescription = "Close floating dictionary" }, LinearLayout.LayoutParams(dp(48), dp(48)))
        root.addView(header)
        val inputRow = LinearLayout(this).apply { setPadding(0, dp(8), 0, dp(6)) }
        val edit = EditText(this).apply {
            hint = "Look up a word…"; background = background(cardColor, 14); setPadding(dp(12), 0, dp(8), 0); setSingleLine(true); textSize = 16f * readingFont.scale; typeface = readingFace; textLocale = Locale.JAPANESE; setTextColor(inkColor); setHintTextColor(if (dark) Color.LTGRAY else Color.DKGRAY)
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
        root.alpha = 0f; root.translationY = dp(18).toFloat(); root.scaleX = .97f; root.scaleY = .97f
        root.animate().alpha(1f).translationY(0f).scaleX(1f).scaleY(1f).setDuration(220).setInterpolator(DecelerateInterpolator()).start()
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
        if (text.isEmpty()) { resizePanel(false); status?.text = "Enter a word, paste explicitly, or tap a character in selected text."; content?.removeAllViews(); renderSource(); return }
        status?.text = "Searching offline…"
        bridge?.invokeMethod("search", text, object: MethodChannel.Result {
            override fun success(result: Any?) {
                if (destroyed || panel == null || request != generation) return
                content?.removeAllViews(); renderSource()
                val words = (result as? List<*>)?.mapNotNull { it as? Map<*, *> }.orEmpty()
                status?.text = if (words.isEmpty()) "No results. Import/enable a dictionary or try a shorter word." else "${words.size} results · up to 30 shown"
                words.forEach { renderWord(it) }
                resizePanel(words.isNotEmpty())
            }
            override fun error(code: String, message: String?, details: Any?) { if (request == generation) { content?.removeAllViews(); resizePanel(false); status?.text = "Could not read local dictionaries. Open the full app to retry." } }
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
        target.addView(readingLabel("", 18f).apply { tag = "source"; this.text = text; movementMethod = LinkMovementMethod.getInstance() })
    }
    private fun chooseWord(offset: Int, sentence: String = sourceText) {
        if (!ready) return
        pendingSearch?.let { handler.removeCallbacks(it) }; pendingSearch = null
        val request = ++generation
        status?.text = "Finding a dictionary match…"
        bridge?.invokeMethod("wordAt", mapOf("text" to sentence, "offset" to offset), object: MethodChannel.Result {
            override fun success(result: Any?) { if (!destroyed && panel != null && request == generation) navigateWord(result as? String ?: "", sentence) }
            override fun error(code: String, message: String?, details: Any?) { if (request == generation) status?.text = "No word could be selected. Edit the lookup field instead." }
            override fun notImplemented() { error("bridge", null, null) }
        })
    }
    private fun navigateWord(value: String, sentence: String = value) {
        val previous = query?.text?.toString().orEmpty()
        if (previous.isNotEmpty() && previous != value) {
            if (browsingHistory.size >= 40) browsingHistory.removeFirst()
            browsingHistory.addLast(Pair(previous, sourceText))
        }
        backButton?.visibility = if (browsingHistory.isEmpty()) View.GONE else View.VISIBLE
        sourceText = sentence
        query?.setText(value)
    }
    private fun browsableLabel(value: String): TextView {
        val text = SpannableString(value)
        var offset = 0
        while (offset < value.length) {
            val start = offset
            val point = value.codePointAt(offset)
            offset += Character.charCount(point)
            if (point in 0x3040..0x30ff || point in 0x3400..0x9fff) {
                text.setSpan(object: ClickableSpan() {
                    override fun onClick(widget: View) { chooseWord(start, value) }
                    override fun updateDrawState(ds: TextPaint) { ds.color = green; ds.isUnderlineText = true }
                }, start, offset, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
            }
        }
        return readingLabel("", 16f).apply { this.text = text; movementMethod = LinkMovementMethod.getInstance() }
    }
    private fun renderWord(word: Map<*, *>) {
        val card = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL; setPadding(dp(10), dp(10), dp(10), dp(14)); background = background(cardColor, 12) }
        fun value(key: String) = word[key] as? String ?: ""
        card.addView(readingLabel(value("expression"), 25f).apply { setTypeface(readingFace, Typeface.BOLD) })
        if (value("reading").isNotEmpty()) card.addView(readingLabel(value("reading"), 17f))
        if (value("tags").isNotEmpty()) card.addView(label(value("tags"), 12f))
        if (value("inflection").isNotEmpty()) card.addView(label("Matched via ${value("inflection")}", 12f))
        card.addView(browsableLabel(value("definitions")))
        if (value("parameters").isNotEmpty()) card.addView(label(value("parameters"), 11f))
        (word["references"] as? List<*>)?.filterIsInstance<String>()?.distinct()?.forEach { reference ->
            card.addView(label("↗ $reference", 15f).apply { setTextColor(green); contentDescription = "Explore $reference"; isClickable = true; setOnClickListener { navigateWord(reference) } })
        }
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
        var pressedAt = 0L
        handle.setOnTouchListener { view, event ->
            when (event.action) {
                MotionEvent.ACTION_DOWN -> { pressedAt = SystemClock.uptimeMillis(); startX = event.rawX; startY = event.rawY; x = layout.x; y = layout.y; moved = false; true }
                MotionEvent.ACTION_MOVE -> {
                    if (abs(event.rawX - startX) > dp(6) || abs(event.rawY - startY) > dp(6)) moved = true
                    if (moved) { layout.x = (x + event.rawX.toInt() - startX.toInt()).coerceIn(0, maxOf(0, resources.displayMetrics.widthPixels - window.width)); layout.y = (y + event.rawY.toInt() - startY.toInt()).coerceIn(0, maxOf(0, resources.displayMetrics.heightPixels - window.height - dp(32))); try { windows.updateViewLayout(window, layout) } catch (_: IllegalArgumentException) { /* View was dismissed during the gesture. */ } }
                    true
                }
                MotionEvent.ACTION_UP -> { if (!moved && click) { if (SystemClock.uptimeMillis() - pressedAt >= ViewConfiguration.getLongPressTimeout()) view.performLongClick() else view.performClick() }; true }
                else -> false
            }
        }
    }
    private fun closePanel() {
        if (closing) return
        val root = panel ?: return
        closing = true; generation++; resizing?.cancel(); resizing = null
        unfocusPanel()
        root.animate().cancel()
        root.animate().alpha(0f).translationY(dp(12).toFloat()).scaleX(.98f).scaleY(.98f).setDuration(140).setInterpolator(AccelerateInterpolator()).withEndAction {
            if (panel === root) {
                try { windows.removeView(root) } catch (_: IllegalArgumentException) {}
                panel = null; query = null; content = null; status = null; panelParams = null; closing = false
                browsingHistory.clear()
                if (!shortcutEnabled(this)) stopSelf()
            }
        }.start()
    }
    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)
        rebuildAppearance()
        panel?.let { window -> panelParams?.let { layout ->
            layout.width = panelWidth(expanded)
            layout.height = panelHeight(expanded)
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
        getSharedPreferences("floating", MODE_PRIVATE).unregisterOnSharedPreferenceChangeListener(appearanceChanges)
        if (active === this) active = null
        destroyed = true; resizing?.cancel(); resizing = null; generation++; handler.removeCallbacksAndMessages(null)
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
