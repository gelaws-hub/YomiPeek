# YomiPeek — Full Application Development Specification

## 1. Your Role

You are a senior Flutter engineer, Android platform engineer, and software architect responsible for developing a production-quality, open-source Japanese dictionary application called **YomiPeek**.

Your task is to design and implement the application, not merely generate a proposal or architecture document.

You have access to the local development environment, repository, terminal, and installed development tools.

**Work autonomously.** Inspect the environment, make reasonable technical decisions, implement features, run tests, fix problems, and document your work.

Do not stop after scaffolding or generating placeholder screens. Produce working functionality.

Implement the project incrementally, prioritizing a complete, stable core experience before advanced functionality.

If a feature cannot be completed because of missing external credentials, platform limitations, or unavailable tools, implement everything possible locally, provide an actionable configuration guide, and clearly identify the remaining dependency.

---

# 2. Product Vision

**Application:** YomiPeek

**Tagline:** Japanese at a glance.

**Product concept:**

YomiPeek is a free, open-source, offline-first Japanese dictionary and immersion-learning application built with Flutter.

Its primary purpose is to let users look up Japanese vocabulary quickly, including while reading content in other Android applications.

YomiPeek combines several capabilities:

- Japanese dictionary functionality similar to Mazii.
- User-imported dictionary support similar to Yomitan.
- Floating dictionary lookups over other Android applications.
- Vocabulary collection and sentence mining.
- Spaced repetition and flashcards.
- Optional Google Drive backup and synchronization.
- Japanese reading and learning tools.

The application must be usable without creating an account, accessing a server, or paying for a service.

All core dictionary lookups must work offline.

## Fundamental principles

1. **Bring Your Own Dictionary (BYOD):** Users provide their own dictionary files.
2. **Offline-first:** Local storage is the authoritative source during normal operation.
3. **Free and open-source:** No subscriptions, advertisements, or paid features.
4. **No developer-hosted backend:** Google Drive is used for optional user-data synchronization.
5. **User ownership:** User data must be exportable and recoverable.
6. **Privacy:** Do not collect telemetry or transmit lookup activity.
7. **Modularity:** Dictionary, learning, synchronization, and platform integration must remain decoupled.
8. **Performance:** Searches and popups should feel instantaneous on typical Android devices.
9. **Reliability:** Data integrity and graceful error handling are essential.
10. **Maintainability:** Prefer clean, testable architecture rather than unnecessary abstraction.

---

# 3. Technology Stack

Use the following stack unless investigation reveals a compelling reason to change it.

| Component | Technology |
|---|---|
| Application framework | Flutter, stable channel |
| Language | Dart |
| Android-specific integration | Kotlin |
| UI | Material 3 |
| State management | Riverpod |
| Database | SQLite |
| Database access | Drift |
| Search indexing | SQLite indexes and FTS5 |
| Dictionary format | Yomitan-compatible ZIP archives |
| File import | Android Storage Access Framework / Flutter file picker |
| Archive parsing | Dart archive library |
| Authentication | Google OAuth |
| Cloud storage | Google Drive REST API |
| Background synchronization | Android WorkManager |
| HTTP client | A maintained Dart HTTP client |
| OCR | On-device recognition engine |
| Unit testing | flutter_test |
| Integration testing | integration_test |

Prefer mature, actively maintained dependencies.

Research the current official documentation before choosing dependency versions or Android APIs.

Use the latest compatible stable versions, but avoid unnecessary pre-release dependencies.

Do not introduce Firebase, Supabase, a custom server, or a paid cloud service.

## Development environment

The developer uses Linux, VS Code, Flutter, and the Android SDK/Android Emulator installed through Android Studio.

Ensure the project builds and runs from the Linux terminal.

Useful commands include:

```bash
flutter doctor
flutter pub get
flutter analyze
flutter test
flutter run
flutter build apk
```

Check that Android compilation works, not merely that Dart analysis passes.

---

# 4. Architecture

Use a feature-first architecture with clear separation between presentation, domain logic, and infrastructure.

A suggested structure:

```text
lib/
  main.dart
  app/
    app.dart
    router/
    theme/
    dependency_injection/

  core/
    database/
    models/
    errors/
    logging/
    storage/
    permissions/
    utilities/
    platform/

  features/
    dictionary/
      domain/
      data/
      presentation/
      import/
      search/

    kanji/
    pitch_accent/
    vocabulary/
    flashcards/
    reader/
    floating_lookup/
    sync/
    backup/
    settings/

android/
  app/
    src/main/kotlin/
      .../
        TextSelectionHandler.kt
        OverlayService.kt
        PlatformChannelHandler.kt

test/
integration_test/
docs/
```

Adjust this structure when justified, but preserve modular boundaries.

## Architectural expectations

- Business logic must not depend directly on Flutter widgets.
- Dictionary parsing must be independently testable.
- Search must be usable by the main app and floating lookup interface.
- Sync must not depend on the UI lifecycle.
- Database migrations must preserve user-created data.
- Native Android functionality should be exposed through small, documented interfaces.
- Importing dictionaries must not modify user-generated vocabulary or review history.
- Errors should use typed results or consistent exception handling.
- Avoid hidden global mutable state.
- Avoid unnecessary third-party frameworks.

---

# 5. Bring Your Own Dictionary

**This is a mandatory design constraint.**

YomiPeek must not bundle, automatically download, redistribute, or host third-party dictionary databases.

The user must manually supply Yomitan-compatible dictionary files.

The application should initially display an empty dictionary state with an import action.

Do not embed JMdict, Jitendex, KANJIDIC, or any other real dictionary dataset in the distributed application.

A tiny, original, synthetic test fixture may be included in the test suite to validate import behavior.

## Supported format

Implement a compatible reader for documented Yomitan dictionary archives.

Investigate and support the relevant format versions and structures, including where applicable:

```text
index.json
term_bank_*.json
term_meta_bank_*.json
kanji_bank_*.json
kanji_meta_bank_*.json
tag_bank_*.json
structured content
dictionary media assets
```

Do not assume every dictionary archive contains all of these files.

Support vocabulary, kanji, frequency, pronunciation, and pitch-accent information when present.

Preserve dictionary-specific metadata and attribution.

Avoid hardcoding knowledge of any particular dictionary provider.

## Dictionary importer

Implement:

1. Select ZIP files using the system file picker.
2. Validate the archive.
3. Read dictionary metadata.
4. Identify supported archive structures and schema versions.
5. Parse entries incrementally where possible.
6. Transform them into a normalized internal representation.
7. Insert entries into SQLite efficiently.
8. Build search indexes.
9. Report import progress.
10. Handle cancellation safely.
11. Recover from errors without leaving partially imported dictionaries active.
12. Confirm successful import.

Do not load massive dictionary archives entirely into memory if incremental processing can be used.

Protect against malformed archives, path traversal, ZIP bombs, excessive decompression, unsupported content, and unsafe markup.

Use transactions or staged imports so interrupted imports can be rolled back.

## Dictionary management

Implement a dedicated management page supporting:

- Import dictionary.
- Import multiple dictionaries.
- View installed dictionaries.
- Show title, revision, entry count, and supported capabilities.
- Enable or disable individual dictionaries.
- Set dictionary priority.
- Update a dictionary by importing a newer ZIP.
- Detect duplicate imports.
- Delete dictionary and indexed data.
- Show import errors.
- Display license and attribution metadata.
- Show approximate storage consumption.

Dictionary-specific styling or structured content must be rendered safely.

Never execute JavaScript supplied by imported dictionaries.

---

# 6. Dictionary Search Engine

Implement an offline search engine optimized for Japanese vocabulary.

## Search capabilities

Support:

- Japanese kanji lookup.
- Hiragana lookup.
- Katakana lookup.
- English definition search.
- Exact matching.
- Prefix matching.
- Search suggestions.
- Search history.
- Multiple dictionary results.
- Dictionary priority ordering.
- Duplicate-result grouping where appropriate.
- Variant readings.
- Part-of-speech information.
- Frequency information where available.
- JLPT tags where supplied.
- Pitch-accent information where supplied.

Do not assume that an installed dictionary contains English definitions.

## Japanese normalization

Handle appropriate normalization of:

- Unicode text.
- Full-width and half-width characters.
- Hiragana and katakana.
- Common orthographic variants where appropriate.

Normalization must not destroy distinctions needed for precise Japanese lookup.

## Deinflection

Implement a Japanese deinflection engine so users can find dictionary forms from common conjugations.

Examples:

```text
食べました → 食べる
食べた → 食べる
行かなかった → 行く
読んでいる → 読む
高かった → 高い
```

Support common verb classes, irregular verbs, adjectives, and auxiliary constructions.

A deinflection result should retain information about the transformation.

Use rule-based transformations with validation against dictionary entries.

Prevent combinatorial explosions, invalid loops, and excessive processing.

Add comprehensive unit tests.

## Search performance

Use:

- Indexed columns for Japanese exact/prefix lookup.
- FTS5 for appropriate text searches.
- Batched queries.
- Debounced search input.
- Cancellable requests where practical.
- Pagination or lazy result rendering.
- Background isolates for CPU-intensive parsing.

Target responsive search behavior on ordinary mid-range Android hardware.

Benchmark representative dictionary sizes and document the results. Avoid claiming a latency target has been met without measurement.

---

# 7. Dictionary Result UI

Create a polished, mobile-first dictionary interface.

## Main dictionary screen

Include:

- Search bar.
- Search suggestions.
- Recent searches.
- Dictionary result list.
- Saved vocabulary shortcut.
- Dictionary manager shortcut.
- Settings access.

## Word result

Show available information, including:

- Kanji expression.
- Kana reading.
- Furigana.
- Part of speech.
- Definitions.
- Dictionary source.
- Frequency.
- JLPT tags.
- Pitch accent.
- Example sentences.
- Conjugation information.
- Audio playback, if available.

Actions:

- Bookmark.
- Save to vocabulary.
- Play pronunciation.
- Copy expression.
- Copy reading.
- Copy definition.
- View kanji details.
- Create flashcard.
- View source sentence.

If optional data is unavailable, omit the corresponding UI gracefully.

## Kanji details

Support:

- Character.
- Onyomi.
- Kunyomi.
- Meanings.
- Radicals.
- Stroke count.
- Related vocabulary.
- Available frequency metadata.

These details depend on the imported dictionaries.

---

# 8. Android System-Wide Dictionary Lookup

This is a major differentiating feature of YomiPeek.

Implement native Android integration using Kotlin when necessary.

## A. Android text-selection integration

Use Android's supported text-processing intent mechanisms, including `ACTION_PROCESS_TEXT`, where applicable.

Desired workflow:

1. The user selects Japanese text in a compatible application.
2. Android displays its text-selection menu.
3. The user selects YomiPeek.
4. YomiPeek receives the selected text.
5. The dictionary displays the relevant lookup.

Handle:

- Single words.
- Multiple words.
- Complete sentences.
- Empty text.
- Unsupported text.
- Large selections.

When multiple words are selected, provide a convenient way to choose a word.

Do not promise control over whether Android places YomiPeek directly in the visible selection toolbar or inside the overflow menu. That decision belongs to the host application and Android.

## B. Floating dictionary window

Implement a floating dictionary UI over other applications where supported.

Possible interface:

```text
┌──────────────────────────────┐
│ YomiPeek                  X  │
├──────────────────────────────┤
│ 食べる       たべる          │
│                              │
│ Verb — Ichidan               │
│                              │
│ 1. To eat                    │
│ 2. To consume                │
│                              │
│ [Audio] [Save] [Expand]      │
└──────────────────────────────┘
```

Requirements:

- Request overlay permission explicitly.
- Explain why permission is needed.
- Never request it unnecessarily.
- Show and dismiss the window predictably.
- Support dragging or repositioning where appropriate.
- Avoid blocking the entire screen.
- Support scrolling and long definitions.
- Support quick bookmarking.
- Support audio playback.
- Allow opening the full dictionary.
- Clean up resources when dismissed.

Use Android WindowManager or a well-maintained Flutter overlay solution, whichever is more reliable.

Verify Android version compatibility and lifecycle behavior.

## C. Floating lookup button

Provide an optional persistent floating shortcut.

It may:

- Open the dictionary overlay.
- Allow manual text entry.
- Read clipboard content after an explicit user action when permitted.
- Open a saved/recent lookup.
- Close or hide itself.

Persist the enabled/disabled setting.

Do not continuously poll the clipboard in violation of modern Android restrictions.

## D. Clipboard behavior

Android restricts background clipboard access.

Therefore:

- Do not promise automatic detection after every Copy action.
- Do not circumvent OS privacy restrictions.
- Prefer user-initiated clipboard access.
- Clearly explain limitations to users.
- Do not use Accessibility Service to covertly read other applications.

Automatic text-selection detection using Accessibility APIs is an optional research item, not part of the core implementation.

---

# 9. Vocabulary Management

Provide a persistent personal vocabulary library independent of imported dictionaries.

Each saved entry should support:

- Stable unique identifier.
- Expression.
- Reading.
- Selected meaning.
- Dictionary source reference.
- User notes.
- Tags.
- Collections.
- Source sentence.
- Date added.
- Last modified timestamp.
- Known/learning/unknown status.
- Relevant flashcard references.

Important: Saved user vocabulary must remain intact even when the original dictionary is deleted.

Store enough of the saved information to make previously saved entries useful without the original dictionary.

Implement:

- Save word.
- Remove saved word.
- Edit notes.
- Add or remove tags.
- Create collections.
- Move words between collections.
- Search saved vocabulary.
- Filter and sort.
- Export vocabulary.
- Duplicate detection.

---

# 10. Flashcards and Spaced Repetition

Build a separate learning module.

## Flashcard types

Support:

- Japanese expression → meaning.
- Reading → meaning.
- Meaning → Japanese expression.
- Sentence card.
- Optional custom cards.

## Spaced repetition

Prefer a well-documented FSRS implementation if a compatible, maintained implementation is available.

If the scheduling algorithm requires more investigation, implement a clearly isolated scheduler interface and a tested initial scheduler. Do not falsely label a simplified scheduler as FSRS.

Support:

- New cards.
- Due cards.
- Review cards.
- Again / Hard / Good / Easy grading.
- Review timestamps.
- Daily review limits.
- New-card limits.
- Card suspension.
- Review history.
- Basic retention statistics.

Persist review events independently from current scheduling state so review history can be synchronized and reconstructed.

## Sentence mining

Allow users to save:

- Target word.
- Full original sentence.
- Reading.
- Meaning.
- Source title or URL when provided.
- Creation timestamp.

Provide optional AnkiDroid integration or export where technically feasible.

CSV export should be supported.

APKG export is optional and should be implemented only with a validated format/library.

---

# 11. Google Drive Backup and Synchronization

**This is a mandatory product feature.**

YomiPeek must support optional Google Drive backup and state synchronization without a developer-hosted server.

Do not use Firebase or a proprietary backend.

## Authentication

Use Google's supported OAuth authorization flow.

Users must be able to:

- Connect a Google account.
- Disconnect their account.
- See connection status.
- Trigger sync.
- Disable automatic sync.
- Use the app without signing in.

Use minimal scopes.

Prefer the Google Drive `appDataFolder` using its supported application-data scope for automatic synchronization.

Verify the current Google Drive API, OAuth, Android SDK, and consent-screen requirements before implementing.

Do not embed client secrets, refresh tokens, service-account credentials, or private keys in the source code.

Document Google Cloud project configuration, OAuth client setup, package identity, and signing certificate requirements.

If a Google Cloud project is not configured locally, keep the application operational and expose a clear setup state rather than crashing.

## Two different backup modes

### Mode A: Automatic app-data synchronization

Store synchronization state in the application's Google Drive data folder.

This must be optional and invisible to ordinary dictionary usage.

Synchronize:

- Saved vocabulary.
- Tags and collections.
- Notes.
- Flashcards.
- Review history.
- Reading progress.
- User preferences.
- Search history, if enabled.
- Installed dictionary metadata and priority.

Do not automatically upload dictionary ZIP files, imported dictionary databases, or third-party content.

### Mode B: Portable backup/export

Allow users to export their own application state to a portable versioned file.

Support:

- Manual backup.
- Manual restore.
- Local file export.
- Local file import.
- Documented schema version.
- Data validation.
- Optional encryption.
- Backup file integrity checks.

For visible Drive backups, use a Google-supported file creation or user-authorized file-selection workflow with appropriately limited permissions.

Do not assume appDataFolder files are visible in the user's regular Drive interface.

## Synchronization architecture

Use a local-first design.

SQLite is the local source of truth while offline.

Synchronization should occur when:

- The user manually requests it.
- The application starts, if enabled and connected.
- The application returns to foreground, subject to throttling.
- A permitted background synchronization job runs.
- Connectivity returns, when practical.

Android background execution is best-effort. Do not promise exact synchronization intervals.

## Multi-device support

Support this scenario:

```text
Device A:
  Save word A
  Review flashcard B
  Go offline

Device B:
  Save word C
  Review flashcard D
  Go offline

Both devices reconnect.

Expected outcome:
  Word A preserved
  Word C preserved
  Both review histories preserved
  Consistent resulting study state
```

Implement:

- Stable record IDs.
- Device identifiers.
- Modification metadata.
- Synchronization cursors or revisions.
- Tombstones for deletions.
- Idempotent operations.
- Conflict handling.
- Retry logic.
- Safe transaction boundaries.
- Atomic local application of downloaded changes.

Do not naively overwrite the entire database with whichever device synchronizes last.

Because Google Drive is file storage rather than a transactional database, explicitly design for concurrent writes.

Use file revision/ETag checks or an append-only operation-log strategy with unique per-device records, then merge deterministically.

For review events, preserve immutable event records and derive scheduling state in an order-consistent way.

If reliable conflict-free synchronization is not yet implemented, expose the feature as **backup/restore only**, rather than misleadingly claiming multi-device sync.

## Sync user interface

Display:

- Connected Google account.
- Last successful synchronization.
- Current synchronization state.
- Pending local changes.
- Errors.
- Retry action.
- Manual backup.
- Manual restore.
- Automatic sync toggle.
- Data categories to sync.
- Disconnect action.

Never delete local data merely because the cloud account has been disconnected.

Do not upload third-party dictionary archives by default.

---

# 12. Reading and Immersion Features

After the core dictionary, Android lookup, and Google Drive backup features are working, implement a reading module.

## Text reader

Support:

- Pasted Japanese text.
- Imported plain-text files.
- Paragraph display.
- Tap-to-lookup.
- Saved reading position.
- Save word from selected text.
- Save entire sentence.

Use a tested Japanese text segmentation strategy.

## Web reader

Provide an in-app reading experience for Japanese webpages.

Where technically practical and safe:

- Load webpages.
- Let users select Japanese text.
- Open YomiPeek lookup.
- Save vocabulary and sentences.

Respect website security and browser constraints.

## Future reader capabilities

Prepare extension points for:

- EPUB reading.
- PDF reading.
- Manga/image OCR.
- On-device Japanese OCR.
- Subtitle import.
- Video subtitle lookup.
- Reading statistics.
- Known-word highlighting.

Do not let these advanced features delay the initial usable application.

---

# 13. UI/UX Requirements

The application should look like a polished consumer Android application.

Use Material 3 and a consistent design system.

## Visual direction

- Minimalist.
- Modern.
- Clean typography.
- Comfortable Japanese text rendering.
- Smooth transitions.
- Uncluttered navigation.
- Rounded surfaces.
- Accessible contrast.
- Thoughtful empty states.

Do not copy Mazii, Yomitan, or Manatan branding, logos, proprietary assets, or exact UI layouts.

## Branding

Application name: YomiPeek

Tagline: Japanese at a glance.

Use a temporary original app icon based on Japanese reading or a magnifying-glass motif.

## Navigation

Suggested primary destinations:

1. Dictionary
2. Vocabulary
3. Study
4. Reader
5. Settings

Dictionary management should be accessible from the Dictionary screen and Settings.

## First launch

A new user should see:

```text
Welcome to YomiPeek

Your Japanese dictionary,
your way.

No dictionaries installed.

[ Import Dictionary ZIP ]

Import a Yomitan-compatible
dictionary to get started.

No account required.
Works offline.
```

Do not force Google sign-in.

## Settings

Organize into:

- General.
- Appearance.
- Dictionaries.
- Floating lookup.
- Learning.
- Google Drive sync.
- Backup and restore.
- Privacy.
- About.

Support light and dark modes.

Use responsive layouts so the application remains usable on different Android screen sizes.

---

# 14. Data Modeling

Create proper relational tables and migrations.

Suggested logical entities:

```text
Dictionary
DictionaryEntry
DictionaryDefinition
DictionaryTag
DictionaryMetadata
DictionaryMedia
KanjiEntry
Pronunciation
FrequencyRecord

SavedVocabulary
VocabularyTag
VocabularyCollection
VocabularyCollectionItem
Sentence
SearchHistory

Flashcard
ReviewEvent
StudySettings

ReadingDocument
ReadingProgress

AppPreference
SyncOperation
SyncState
SyncTombstone
```

This is a conceptual schema, not a requirement to create every entity as a separate table.

Normalize where useful, but optimize high-volume dictionary lookups.

## Separate dictionary and user data

Prefer two independently managed storage domains:

**Dictionary storage**
- Imported dictionary records.
- Rebuildable indexes.
- Metadata.
- Dictionary media.

**User-data storage**
- Saved vocabulary.
- Notes.
- Review records.
- Reading history.
- Settings.
- Sync metadata.

This separation should make it possible to remove or rebuild dictionaries without risking user-created information.

Design schema migrations from the beginning.

---

# 15. Security, Privacy, and Licensing

Follow these constraints:

- No bundled third-party dictionaries.
- No automatic unauthorized dictionary downloading.
- No scraping protected dictionary services.
- No bypassing copy protection.
- No embedded Google credentials or secrets.
- No unnecessary Android permissions.
- No plaintext logging of OAuth tokens.
- No hidden telemetry.
- No unprompted clipboard collection.
- No transmission of user search queries to remote services.
- No uploading user data without explicit opt-in.
- No executing dictionary-supplied scripts.

Make imported dictionary content safe to parse and render.

Display user-facing attribution and license metadata supplied with dictionaries where possible.

Document that users are responsible for obtaining compatible dictionary files they are authorized to use.

Do not assume that user-supplied dictionaries are always freely redistributable.

Include a privacy policy draft and a description of all Android permissions requested.

---

# 16. Reliability and Performance

The application must handle:

- No dictionaries installed.
- Multiple dictionaries installed.
- Large dictionaries.
- Malformed archives.
- Interrupted imports.
- Duplicate imports.
- Database corruption detection.
- Offline operation.
- Failed Google authentication.
- Cloud synchronization errors.
- Conflicting device modifications.
- Missing audio.
- Missing pitch-accent data.
- Missing kanji metadata.
- Android process termination.
- Screen rotation and application lifecycle changes.
- Overlay permission denial.

Do not crash simply because optional data or services are unavailable.

## Performance goals

Aim for:

- Responsive typing and search results.
- Smooth scrolling through long results.
- No noticeable UI freezes during dictionary imports.
- Bounded memory usage.
- Efficient database queries.
- Incremental parsing.
- Minimal background battery usage.

Measure representative operations rather than making unsupported performance claims.

---

# 17. Testing Requirements

Include meaningful automated tests.

## Unit tests

Test:

- Dictionary metadata parsing.
- Term parsing.
- Kanji parsing.
- Pitch-accent parsing.
- Frequency parsing.
- Japanese normalization.
- Deinflection.
- Search ranking.
- Vocabulary persistence.
- Backup serialization.
- Synchronization merging.
- Review scheduling.
- Database migrations.

## Integration tests

Test:

- Import dictionary ZIP.
- Search imported entries.
- Enable/disable dictionaries.
- Remove a dictionary.
- Save vocabulary.
- Restart app and verify persistence.
- Export user state.
- Restore user state.
- Synchronize with a mocked Drive API.
- Handle sync conflicts.
- Handle malformed imports.

## Android-specific verification

Validate:

- `ACTION_PROCESS_TEXT` integration.
- Permission handling.
- Overlay creation.
- Overlay lifecycle.
- Background/foreground transitions.
- Android version compatibility.

If Android instrumentation testing is unavailable in the current environment, document exactly what requires manual verification on an emulator or physical device.

Avoid relying exclusively on mocked tests for functionality that requires Android OS integration.

---

# 18. Development Phases

Implement in this order.

## Phase 0 — Environment and project foundation

- Inspect the repository.
- Detect the installed Flutter SDK.
- Check Android tooling.
- Initialize the project if necessary.
- Configure linting and code formatting.
- Set up Riverpod and Drift.
- Configure app routing.
- Implement the theme.
- Set up testing.
- Create initial documentation.
- Verify that the empty app runs.

**Acceptance:** Application compiles, launches, and has working navigation.

## Phase 1 — Functional offline dictionary

- Implement Yomitan ZIP importer.
- Implement dictionary schema.
- Implement SQLite persistence.
- Implement indexing.
- Implement Japanese lookup.
- Implement English definition search.
- Implement deinflection.
- Implement dictionary manager.
- Implement word result UI.
- Implement bookmarks.
- Implement search history.
- Add unit and integration tests.

**Acceptance:** A user can import a compatible dictionary, search vocabulary offline, save words, and use the app after restarting it.

## Phase 2 — Android text selection and floating lookup

- Implement Android native integration.
- Handle selected text.
- Implement dictionary lookup entry point.
- Implement overlay permission flow.
- Create floating dictionary UI.
- Implement quick save and dismiss actions.
- Implement optional floating shortcut.
- Test relevant lifecycle behavior.

**Acceptance:** On a supported Android browser/application, the user can select text, invoke YomiPeek through the available system action, and see a dictionary result.

## Phase 3 — Google Drive backup and restore

- Implement OAuth connection.
- Implement Drive API adapter.
- Implement hidden application-data backup.
- Implement backup serialization.
- Implement restore.
- Implement portable local export/import.
- Implement sync status UI.
- Handle failures and retries.
- Add tests with a mocked Drive implementation.

**Acceptance:** A user can back up and restore their personal YomiPeek state without affecting installed dictionary data.

## Phase 4 — Multi-device synchronization

- Implement change tracking.
- Implement conflict-safe merging.
- Implement tombstones.
- Implement immutable review-event synchronization.
- Implement retries and idempotency.
- Add deterministic multi-device simulation tests.
- Add optional background scheduling.

**Acceptance:** Independent changes made offline on two devices are preserved after both synchronize, including deletions and flashcard review events.

## Phase 5 — Learning features

- Implement vocabulary collections.
- Implement tags and personal notes.
- Implement flashcards.
- Implement a tested SRS scheduler.
- Implement review history.
- Implement study statistics.
- Implement sentence mining.
- Add CSV export.

**Acceptance:** Users can build and review vocabulary decks offline, and their study data survives restarts and backups.

## Phase 6 — Reading and immersion

- Implement text reader.
- Implement tap-to-lookup.
- Implement reading progress.
- Implement sentence capture.
- Investigate and implement an in-app web reader.
- Document future OCR and media capabilities.

**Acceptance:** A user can import or paste Japanese text, tap words for definitions, and save vocabulary from the reading context.

---

# 19. Important Scope Management

The final product vision is broad. Do not sacrifice correctness or data safety to claim all features are complete.

Complete each phase before moving to the next.

Keep the project buildable after every phase.

If execution time, environment access, or context limits prevent completion of the full roadmap, finish the current phase to a working state and document the remaining tasks.

Do not fill missing functionality with fake implementations.

Specifically:

- Never present a mock Drive login as real authentication.
- Never present backup overwrite as conflict-safe synchronization.
- Never claim all Yomitan dictionaries work unless compatibility has been tested.
- Never claim Android automatically detects every text selection.
- Never bundle real dictionary files to make demonstrations easier.
- Never silently discard user data during upgrades or sync.

Use appropriate abstractions for incomplete modules, but keep disabled features visibly disabled rather than exposing nonfunctional controls.

---

# 20. Repository Deliverables

Create and maintain:

```text
README.md
ARCHITECTURE.md
DEVELOPMENT.md
ROADMAP.md
PRIVACY.md
LICENSE
docs/
  dictionary-format.md
  dictionary-import.md
  database-schema.md
  android-integration.md
  google-drive-setup.md
  sync-protocol.md
  backup-format.md
  testing.md
  known-limitations.md
```

The README should explain:

- What YomiPeek is.
- Supported platforms.
- Key features.
- How to install Flutter dependencies.
- How to run the app.
- How to build an APK.
- How to import a dictionary.
- How to configure Google Drive OAuth.
- How to run tests.
- What works offline.
- Which features are implemented.
- Which features are planned.

Use an appropriate open-source application license, with clear third-party dependency notices. Do not assume that licensing the application grants rights to third-party dictionary content.

---

# 21. Execution Instructions

Begin by inspecting the current working directory and checking whether a Flutter application already exists.

**Do not overwrite existing work without first inspecting it.**

Then:

1. Audit the existing repository and environment.
2. Produce a concise implementation plan.
3. Set up or repair the project structure.
4. Implement the application phase by phase.
5. Run formatting, static analysis, and relevant tests after meaningful changes.
6. Fix compilation and test failures.
7. Keep architecture and documentation updated.
8. Build a debug APK when Android tooling is available.
9. Verify the implemented user flows.
10. Provide a truthful final implementation report.

Use this quality gate after each major phase:

```bash
dart format .
flutter analyze
flutter test
flutter build apk --debug
```

If a command fails, investigate and fix the cause. Do not suppress errors merely to make the checks pass.

Use meaningful commits if Git is configured and repository conventions allow it. Do not make destructive Git operations.

### Final report format

At the end, report:

**Implemented**
- Working features.

**Verified**
- Tests run and results.
- Build output.
- Android functionality tested.

**Configuration required**
- Any Google OAuth setup.
- Android device permissions.
- Other external prerequisites.

**Known limitations**
- Unsupported dictionary features.
- Platform-specific restrictions.
- Untested scenarios.

**Next tasks**
- Remaining roadmap items in priority order.

Do not state that a feature is complete unless its implementation and relevant validation are present.

---

# 22. Final Product Expectations

A successful initial YomiPeek release allows a user to:

1. Install the application on Android.
2. Import their own Yomitan-compatible ZIP dictionary.
3. Search Japanese words entirely offline.
4. View readings, definitions, and available dictionary metadata.
5. Look up conjugated words.
6. Save useful vocabulary.
7. Invoke dictionary lookup through supported Android text-selection actions.
8. Display results in a floating window when permissions and OS behavior allow.
9. Back up personal application state to Google Drive.
10. Restore personal state after reinstalling.
11. Use the application without signing in.
12. Export personal data without Google Drive.

Later releases expand this into a complete immersion-learning experience with spaced repetition, reading, OCR, and advanced synchronization.

**Start implementing YomiPeek now. Prioritize working software, maintainable architecture, data integrity, and a polished user experience.**