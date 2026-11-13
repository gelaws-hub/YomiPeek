import 'package:drift/native.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yomipeek/app/app.dart';
import 'package:yomipeek/core/database/database.dart';
import 'package:yomipeek/features/appearance/fonts.dart';
import 'package:yomipeek/features/appearance/font_settings_page.dart';
import 'package:yomipeek/features/dictionary/data/repository.dart';

void main() {
  testWidgets(
    'changing reading size does not move the slider beneath the finger',
    (tester) async {
      final db = DictionaryDb(NativeDatabase.memory());
      final user = UserDb(NativeDatabase.memory());
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            repositoryProvider.overrideWithValue(
              DictionaryRepository(db, user),
            ),
          ],
          child: const MaterialApp(home: FontSettingsPage()),
        ),
      );
      await tester.pumpAndSettle();
      final slider = find.byKey(const Key('reading-scale'));
      await tester.ensureVisible(slider);
      await tester.pumpAndSettle();
      final before = tester.getRect(slider);
      // Start at the current 100% thumb, then increase the preview font size.
      final start = Offset(
        before.left + 24 + (before.width - 48) * (.15 / .55),
        before.center.dy,
      );
      final gesture = await tester.startGesture(start);
      await gesture.moveBy(const Offset(160, 0));
      await tester.pump();
      expect(tester.getRect(slider).center.dy, closeTo(before.center.dy, .1));
      final scope = ProviderScope.containerOf(
        tester.element(find.byType(FontSettingsPage)),
      );
      await tester.runAsync(() async {
        await gesture.up();
        final deadline = DateTime.now().add(const Duration(seconds: 2));
        while (scope.read(japaneseFontsProvider).scale <= 1 &&
            DateTime.now().isBefore(deadline)) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
      });
      await tester.pumpAndSettle();
      expect(tester.getRect(slider).center.dy, closeTo(before.center.dy, .1));
      final container = ProviderScope.containerOf(
        tester.element(find.byType(FontSettingsPage)),
      );
      expect(container.read(japaneseFontsProvider).scale, greaterThan(1));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await db.close();
        await user.close();
      });
    },
  );
}
