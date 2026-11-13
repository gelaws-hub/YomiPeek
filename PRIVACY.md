# Privacy policy draft

YomiPeek phases 0–2 store imported dictionaries, saved words, submitted search history (up to 50 queries), appearance and floating-shortcut preferences locally. No telemetry, account, remote lookup, advertising, background clipboard monitoring, or cloud upload is implemented. Text selection is received only after a user invokes YomiPeek in a compatible app's system menu. Clipboard reads happen only after Paste; Copy actions write only when requested.

The Android system picker grants access to selected dictionary files. Optional display-over-other-apps permission enables the floating dictionary and shortcut. Foreground-service permissions keep these user-requested visible windows alive; notification permission is requested when enabling the shortcut on Android 13+. Permission denial leaves the full-app dictionary available. No Accessibility Service, broad storage, microphone, location or screen capture permissions are used. See docs/android-integration.md for the complete behavior.

Pronunciation delegates to an installed offline Japanese Android text-to-speech voice. YomiPeek does not automatically download audio or voices. Imported dictionary content never executes JavaScript or supplied styles.

Clear search history in Settings; remove saved words from Vocabulary and dictionaries from Dictionaries. The development/profile Flutter manifests request Internet for debugging; the release main manifest does not request Internet. Android's system backup is disabled to avoid unintentionally uploading third-party dictionary imports. Uninstalling removes local app data. Portable backup and Drive export are planned and unavailable in this build.

Users are responsible for obtaining dictionaries they may lawfully use. Supplied licenses/attribution can be inspected in Dictionaries → information. Application licensing does not grant rights to imported dictionary content.
