import 'dart:io';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:yomipeek/app/app.dart';
import 'package:yomipeek/core/database/database.dart';
import 'package:yomipeek/features/dictionary/data/repository.dart';
import 'package:yomipeek/features/dictionary/import/importer.dart';

import 'fixture.dart';

import 'package:yomipeek/features/floating_lookup/settings_page.dart';
import 'package:yomipeek/features/floating_lookup/lookup_page.dart';

void main() {
  testWidgets(
    'incoming sentence opens lookup and a character tap finds the conjugated word',
    (tester) async {
      final db = DictionaryDb(NativeDatabase.memory());
      final user = UserDb(NativeDatabase.memory());
      late Directory temp;
      await tester.runAsync(() async {
        temp = await Directory.systemTemp.createTemp('yomipeek-selection');
        await importDictionary((await fixture(temp)).path, db);
      });
      const channel = MethodChannel('org.yomipeek/platform');
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (call) async =>
            call.method == 'initialSelection' ? '食べました。読んでいる。' : null,
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
      await tester.pumpAndSettle(const Duration(milliseconds: 300));
      expect(find.text('Explore text'), findsOneWidget);
      await tester.tap(find.text('読'));
      await tester.pumpAndSettle(const Duration(milliseconds: 300));
      expect(find.text('読む'), findsOneWidget);
      expect(find.textContaining('Matched via progressive'), findsOneWidget);
      await tester.tap(find.byTooltip('Save word'));
      await tester.pumpAndSettle();
      expect(await user.select(user.savedWords).get(), hasLength(1));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await db.close();
        await user.close();
        await temp.delete(recursive: true);
      });
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      );
    },
  );
  testWidgets(
    'permission status refreshes after returning from Android settings',
    (tester) async {
      var allowed = false;
      const channel = MethodChannel('org.yomipeek/platform');
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        if (call.method == 'floatingState') {
          return {'permission': allowed, 'shortcut': false};
        }
        return null;
      });
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: FloatingSettingsPage())),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Not allowed · full-app lookup still works'),
        findsOneWidget,
      );
      allowed = true;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.text('Allowed by Android'), findsOneWidget);
      await tester.tap(find.byTooltip('Open floating dictionary'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      );
    },
  );
  testWidgets(
    'long selections keep results reachable in enlarged landscape layout',
    (tester) async {
      tester.view.physicalSize = const Size(850, 350);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final db = DictionaryDb(NativeDatabase.memory());
      final user = UserDb(NativeDatabase.memory());
      late Directory temp;
      await tester.runAsync(() async {
        temp = await Directory.systemTemp.createTemp('yomipeek-landscape');
        await importDictionary((await fixture(temp)).path, db);
      });
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            repositoryProvider.overrideWithValue(
              DictionaryRepository(db, user),
            ),
          ],
          child: MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(1.3)),
              child: child!,
            ),
            home: LookupPage(text: '大' * 2000),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 300));
      await tester.ensureVisible(find.byType(TextField));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '食べました');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle(const Duration(milliseconds: 300));
      await tester.scrollUntilVisible(
        find.text('synthetic meal action'),
        120,
        scrollable: find
            .descendant(
              of: find.byKey(const Key('selection-scroll')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .getRect(find.text('synthetic meal action'))
            .overlaps(const Rect.fromLTWH(0, 0, 850, 350)),
        true,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await db.close();
        await user.close();
        await temp.delete(recursive: true);
      });
    },
  );
}
