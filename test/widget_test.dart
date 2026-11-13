import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:yomipeek/app/app.dart';
import 'package:yomipeek/core/database/database.dart';
import 'package:yomipeek/features/dictionary/data/repository.dart';

void main() {
  testWidgets('empty state and working navigation', (tester) async {
    final db = DictionaryDb(NativeDatabase.memory());
    final user = UserDb(NativeDatabase.memory());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          repositoryProvider.overrideWithValue(DictionaryRepository(db, user)),
        ],
        child: const YomiPeekApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byTooltip('Import Dictionary ZIP'), findsOneWidget);
    await tester.tap(
      find.byWidgetPredicate(
        (widget) =>
            widget is NavigationDestination && widget.label == 'Vocabulary',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Your vocabulary starts here'), findsOneWidget);
    await tester.tap(
      find.byWidgetPredicate(
        (widget) =>
            widget is NavigationDestination && widget.label == 'Settings',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Appearance'), findsOneWidget);
    await tester.tap(find.text('Dictionaries'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Import ZIP files'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await db.close();
      await user.close();
    });
  });
}
