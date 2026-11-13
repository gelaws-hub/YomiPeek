import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'core/database/database.dart';
import 'features/dictionary/data/repository.dart';
import 'app/app.dart';
import 'features/floating_lookup/overlay_bridge.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final directory = await getApplicationSupportDirectory();
    final db = DictionaryDb.file(File('${directory.path}/dictionaries.sqlite'));
    final user = UserDb.file(File('${directory.path}/user.sqlite'));
    // Open early so storage errors have a recoverable, visible startup state.
    await db.customSelect('SELECT 1').get();
    await user.customSelect('SELECT 1').get();
    runApp(
      ProviderScope(
        overrides: [
          repositoryProvider.overrideWithValue(DictionaryRepository(db, user)),
        ],
        child: const YomiPeekApp(),
      ),
    );
  } catch (_) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.storage, size: 48),
                  const Text(
                    'YomiPeek could not open local storage. Your files have not been reset.',
                  ),
                  IconButton.filled(
                    tooltip: 'Retry',
                    onPressed: main,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

@pragma('vm:entry-point')
Future<void> overlayMain() => startOverlayBridge();
