import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:yomipeek/features/appearance/fonts.dart';

void main() {
  test('bundled Japanese fonts have supported, bounded SFNT tables', () async {
    for (final name in ['noto-sans-jp', 'noto-serif-jp', 'zen-maru-gothic']) {
      validateFontBytes(
        await File('assets/fonts/$name/font.ttf').readAsBytes(),
      );
      expect(
        await File('assets/fonts/$name/OFL.txt').length(),
        greaterThan(1000),
      );
    }
  });
  test(
    'font validation rejects renamed text, collections and truncated tables',
    () async {
      expect(
        () =>
            validateFontBytes(Uint8List.fromList('not a font file'.codeUnits)),
        throwsA(isA<FontImportFailure>()),
      );
      final bytes = await File('assets/fonts/zen-maru-gothic/font.ttf')
          .readAsBytes();
      final invalid = Uint8List.fromList(bytes);
      ByteData.sublistView(invalid).setUint32(20, bytes.length + 1);
      expect(
        () => validateFontBytes(invalid),
        throwsA(isA<FontImportFailure>()),
      );
      expect(
        () => validateFontBytes(bytes.sublist(0, 24)),
        throwsA(isA<FontImportFailure>()),
      );
      ByteData.sublistView(invalid).setUint32(0, 0x74746366);
      expect(
        () => validateFontBytes(invalid),
        throwsA(isA<FontImportFailure>()),
      );
    },
  );
  test('typography preferences round trip with bounded controls and private filenames', () {
    final settings = JapaneseFontSettings.fromJson({
      'selected': 'custom-abc',
      'scale': 3,
      'lineHeight': .5,
      'imported': [
        {'id': 'custom-abc', 'name': 'My Mincho.ttf', 'file': 'font-abc.ttf'},
      ],
    });
    expect(settings.scale, 1.4);
    expect(settings.lineHeight, 1.2);
    expect(settings.family, 'YomiCustomcustom-abc');
    final restored = JapaneseFontSettings.fromJson(settings.toJson());
    expect(restored.native, settings.native);
    final invalid = JapaneseFontSettings.fromJson({
      'selected': 'custom-abc',
      'imported': [
        {'id': 'custom-abc', 'name': 'unsafe', 'file': '../font-abc.ttf'},
      ],
    });
    expect(invalid.imported, isEmpty);
    expect(invalid.selected, 'system');
  });
}
