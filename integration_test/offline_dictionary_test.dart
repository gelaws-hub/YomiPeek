import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:yomipeek/app/app.dart';
import 'package:yomipeek/core/database/database.dart';
import 'package:yomipeek/features/dictionary/data/repository.dart';
import 'package:yomipeek/features/dictionary/import/importer.dart';

import '../test/fixture.dart';

import 'package:yomipeek/core/platform/android_gateway.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Android import, lookup, bookmark, reopen, disable and removal', (
    tester,
  ) async {
    final root = await getTemporaryDirectory();
    final directory = await Directory(
      '${root.path}/integration-${DateTime.now().millisecondsSinceEpoch}',
    ).create();
    final dictionaryFile = File('${directory.path}/dictionary.sqlite');
    final userFile = File('${directory.path}/user.sqlite');
    var db = DictionaryDb.file(dictionaryFile);
    var user = UserDb.file(userFile);
    var repo = DictionaryRepository(db, user);
    final zip = await fixture(directory);
    await importDictionary(zip.path, db);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [repositoryProvider.overrideWithValue(repo)],
        child: const YomiPeekApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('search')), '食べました');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle(const Duration(milliseconds: 400));
    expect(find.text('食べる'), findsOneWidget);
    expect(find.text('Matched via polite past'), findsOneWidget);
    await tester.tap(find.byTooltip('Save word'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byWidgetPredicate(
        (widget) =>
            widget is NavigationDestination && widget.label == 'Vocabulary',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('synthetic meal action'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await db.close();
    await user.close();
    db = DictionaryDb.file(dictionaryFile);
    user = UserDb.file(userFile);
    repo = DictionaryRepository(db, user);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [repositoryProvider.overrideWithValue(repo)],
        child: const YomiPeekApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('食べました'), findsOneWidget);
    await tester.tap(
      find.byWidgetPredicate(
        (widget) =>
            widget is NavigationDestination && widget.label == 'Vocabulary',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('synthetic meal action'), findsOneWidget);
    await tester.tap(find.byTooltip('Manage dictionaries'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(await repo.search('meal'), isEmpty);
    await tester.tap(find.byTooltip('Delete dictionary'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Remove'));
    await tester.pumpAndSettle();
    expect(find.text('No dictionaries installed.'), findsOneWidget);
    expect(await user.select(user.savedWords).get(), hasLength(1));
    final bad = await fixture(directory, revision: 'bad', malformed: true);
    await expectLater(
      importDictionary(bad.path, db),
      throwsA(isA<ImportFailure>()),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await db.close();
    await user.close();
    await directory.delete(recursive: true);
  });
  testWidgets(
    'native permission status and floating settings need no permission grant',
    (tester) async {
      final db = DictionaryDb.file(
        File(
          '${(await getTemporaryDirectory()).path}/native-status-dictionary.sqlite',
        ),
      );
      final user = UserDb.file(
        File(
          '${(await getTemporaryDirectory()).path}/native-status-user.sqlite',
        ),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            repositoryProvider.overrideWithValue(
              DictionaryRepository(db, user),
            ),
          ],
          child: const YomiPeekApp(),
        ),
      );
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(HomePage)),
      );
      final state = await container.read(androidProvider).state();
      expect(state.available, true);
      await tester.tap(
        find.byWidgetPredicate(
          (widget) =>
              widget is NavigationDestination && widget.label == 'Settings',
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Floating lookup'));
      await tester.pumpAndSettle();
      expect(find.text('Display over other apps'), findsOneWidget);
      expect(find.text('Clipboard privacy'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await db.close();
      await user.close();
    },
  );
}
