import 'package:material_ui/material_ui.dart';

ThemeData readingTheme(
  Brightness brightness, {
  String? readingFamily,
  double readingScale = 1,
  double readingHeight = 1.6,
}) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xff32685d),
    brightness: brightness,
    primary: dark ? const Color(0xff9bd4c1) : const Color(0xff285f53),
    surface: dark ? const Color(0xff182321) : const Color(0xfffffcf5),
    secondary: dark ? const Color(0xffe1bf87) : const Color(0xff846034),
  );
  final base = ThemeData(useMaterial3: true, colorScheme: scheme);
  return base.copyWith(
    extensions: [
      ReadingTypography(
        family: readingFamily,
        scale: readingScale,
        lineHeight: readingHeight,
      ),
    ],
    scaffoldBackgroundColor: dark
        ? const Color(0xff101a18)
        : const Color(0xfff5f1e8),
    textTheme: base.textTheme
        .apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface)
        .copyWith(
          headlineLarge: base.textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -1.2,
          ),
          headlineMedium: base.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -.6,
          ),
          bodyLarge: base.textTheme.bodyLarge?.copyWith(height: 1.65),
          bodyMedium: base.textTheme.bodyMedium?.copyWith(height: 1.5),
        ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: base.textTheme.titleLarge?.copyWith(
        color: scheme.onSurface,
        fontWeight: FontWeight.w700,
        letterSpacing: -.5,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: .45)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: .5),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: scheme.primary, width: 1.5),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surface,
      elevation: 0,
      height: 72,
      indicatorColor: scheme.primaryContainer,
    ),
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant.withValues(alpha: .5),
      space: 28,
    ),
    chipTheme: ChipThemeData(
      side: BorderSide.none,
      backgroundColor: scheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
    ),
  );
}

class ReadingTypography extends ThemeExtension<ReadingTypography> {
  const ReadingTypography({this.family, this.scale = 1, this.lineHeight = 1.6});
  final String? family;
  final double scale, lineHeight;
  @override
  ReadingTypography copyWith({
    String? family,
    double? scale,
    double? lineHeight,
  }) => ReadingTypography(
    family: family ?? this.family,
    scale: scale ?? this.scale,
    lineHeight: lineHeight ?? this.lineHeight,
  );
  @override
  ReadingTypography lerp(covariant ReadingTypography? other, double t) =>
      other == null
      ? this
      : ReadingTypography(
          family: t < .5 ? family : other.family,
          scale: scale + (other.scale - scale) * t,
          lineHeight: lineHeight + (other.lineHeight - lineHeight) * t,
        );
}

TextStyle readingStyle(BuildContext context, [TextStyle? base]) {
  final typography =
      Theme.of(context).extension<ReadingTypography>() ??
      const ReadingTypography();
  final style =
      base ??
      Theme.of(context).textTheme.bodyLarge ??
      const TextStyle(fontSize: 16);
  return style.copyWith(
    fontFamily: typography.family,
    fontFamilyFallback: const ['YomiNotoSansJP'],
    locale: const Locale('ja'),
    fontSize: (style.fontSize ?? 16) * typography.scale,
    height: typography.lineHeight,
  );
}
