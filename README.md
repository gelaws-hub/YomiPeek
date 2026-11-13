# YomiPeek

Japanese at a glance. An Android, offline-first dictionary built with Flutter.

## Implemented (phases 0–2)

- Material 3 light/dark/system themes and Dictionary, Explore, Vocabulary and Settings navigation with warm reading surfaces and a consistent icon-first design.
- User-selected Yomitan format-3 term and kanji ZIPs, multi-file import, atomic replacement by title, duplicate revision detection, progress and cancellation.
- SQLite/Drift persistence in separate dictionary and user files. Japanese exact/prefix lookup, kana/width normalization, definition FTS5, common rule-validated conjugations.
- Dictionary enable/disable, priority, deletion, original metadata inspection and approximate source storage size.
- Browsable word details with structured definitions, examples, references, original entry fields, tag explanations and supplied frequency/pitch/kanji metadata; copy, bookmarks and 50 recent searches.
- Android text-selection action with full-app fallback, tap-to-choose word assistance for selections, optional draggable floating lookup and persistent shortcut, quick save, explicit Paste and installed offline Japanese TTS.

No dictionaries are bundled or automatically downloaded by the app. Obtain a compatible archive you are authorized to use. Search and saved vocabulary work without an account or network.

## Development

Install Flutter stable and Android tooling; see [AGENTS.md](AGENTS.md) for this workstation.

```sh
flutter pub get
dart run build_runner build
dart format .
flutter analyze
flutter test
adb devices
flutter run -d emulator-5554 --no-enable-impeller
flutter build apk --debug
flutter test integration_test/offline_dictionary_test.dart -d emulator-5554 --no-uninstall
```

Open Dictionaries using the books icon or Settings, then **Import ZIP files**. Pick one or more archives in the Android file picker. Reimport a different revision with the same title to replace an existing dictionary atomically. Submitted searches enter history; typing provides results after a short debounce. Higher dictionary priorities appear first within each match rank. Results are capped at 100; narrow the query to see others.

Debug APK: `build/app/outputs/flutter-apk/app-debug.apk`. GitHub Actions builds signed release APKs; see [releasing](RELEASING.md). Android 8.0/API 26 or later is the supported target; desktop/web are not configured.

## Scope

Format-3 vocabulary and kanji dictionaries are the current compatibility target; vendor-specific media layouts remain limited. See [limitations](docs/known-limitations.md) and [format](docs/dictionary-format.md). Automated fixtures are original synthetic entries; live validation also uses externally imported official JMdict/examples and KANJIDIC archives.

Drive backup (phase 3), multi-device sync (phase 4), study (phase 5), and a full document reader (phase 6) are planned. No Google OAuth setup is needed for phases 0–2; [Drive setup](docs/google-drive-setup.md) records the future boundary.

Application code is MIT licensed; imported dictionaries retain their own licenses. See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) and [PRIVACY.md](PRIVACY.md).

For text-selection, overlay permissions, lifecycle and clipboard behavior, see [Android integration](docs/android-integration.md). Settings → Floating lookup provides the optional setup; no account or overlay permission is needed for the full-app dictionary.

The validated build uses Flutter’s supported Skia fallback after an Impeller/OpenGLES raster crash on the API 37 emulator. The manifest applies the fallback to installed APKs; see [testing notes](docs/testing.md) before re-enabling Impeller or upgrading Flutter.

The integration-test command includes `--no-uninstall` because this Flutter SDK otherwise uninstalls the application during test cleanup. Relaunch the normal app after integration tests.


The Explore tab turns pasted Japanese into a dictionary browsing session. Follow suggested words, open a result for structured senses and examples, tap an example to discover its other words, and use Back to return through your exploration. Character chips open imported kanji readings and meanings. All browsing stays offline.

The popup follows Settings → Appearance, including explicit light/dark overrides. Its shortcut is a single draggable search button; hold it to dismiss (or use notification Stop / Settings). It stays out of the way inside YomiPeek. The panel has separate expand and circular close controls and short entrance/exit transitions. See [browser validation](docs/testing.md) for screenshots and measured performance.
