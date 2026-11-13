# Architecture

`lib/app` owns Material navigation, Riverpod dependencies/theme state and presentation. `features/dictionary/import` validates ZIPs and normalizes terms without depending on widgets. `search/japanese.dart` contains pure Unicode normalization and bounded rule transformations. `data/repository.dart` exposes offline search and bookmark/history writes. `core/database` owns Drift schemas and versioning.

Two SQLite files live in Android's application-support directory: `dictionaries.sqlite` contains rebuildable imports and indexes; `user.sqlite` owns independent snapshots, history and preferences. Saved words deliberately have no foreign key to dictionary terms. Deleting/replacing a dictionary cannot cascade into user storage.

NativeDatabase opens SQLite on background isolates. ZIP directory inspection and each term bank's decoding run in separate worker isolates. The importer processes one bank at a time and writes batches of 500 inside a single transaction. Cancellation is cooperative between decoding and insertion batches. Closing/termination rolls back SQLite's uncommitted transaction. UI updates show indeterminate progress and imported entry counts.

Queries rank exact, dictionary-validated deinflection, then prefix/definition results; priority applies within rank. SQLite indexes normalized expression/reading. An external-content FTS5 index has insert/delete triggers within the same transaction. No editable term rows exist. Input is bound as SQL variables; FTS input is limited to escaped alphanumeric tokens. Search generation IDs prevent obsolete requests from overwriting newer results.

Schema version 1 is the initial migration. Future upgrades must supply explicit data-preserving migrations and tests; never delete a database as an upgrade fallback. There are no sync or learning implementations yet.

Phase 2 adds a small Android method-channel gateway, a transparent PROCESS_TEXT dispatcher, and a user-started native overlay service. A service-owned headless Dart engine shares DictionaryRepository and the bounded selection helper, rather than duplicating search in Kotlin. Native UI sends plain data requests and receives escaped-free plain strings. The main and service connections use SQLite WAL and a 5-second busy timeout. Package-local invalidation events refresh main-engine user streams after service writes. Floating-shortcut enablement lives in Android SharedPreferences; future portable backup must explicitly include this preference. See docs/android-integration.md for contracts and lifecycle.
