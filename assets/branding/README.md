# YomiPeek — Kana Lens

Final artwork based on candidate 02: a cream magnifying glass enclosing あ, with three gold discovery rays on forest green. The candidate was generated with the built-in image tool; final artwork was rebuilt as outlined vector geometry for crisp scaling. No font installation is required to use the SVGs.

- `yomipeek-icon.svg`: scalable rounded tile.
- `yomipeek-mark.svg`: transparent foreground mark.
- `yomipeek-icon-1024.png`: large rounded icon with transparent corners.
- `yomipeek-play-store-512.png`: opaque square store artwork; no baked-in corner mask.

Colors: forest `#285F53`, cream `#FFFCF5`, gold `#B89256`. The outlined Japanese glyph uses Noto Sans CJK JP Bold, available under the SIL Open Font License.

Android uses matching vector foregrounds, a solid background, adaptive launcher resources for API 26+, a monochrome foreground for API 33+, and legacy PNGs in all five density folders. Keep the foreground inset so launcher masks do not clip it. The manifest uses `@mipmap/ic_launcher`.
