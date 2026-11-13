import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../app/app.dart';
import '../../core/database/database.dart';
import '../../core/platform/android_gateway.dart';

const fontPresets = <String, (String, String?)>{
  'system': ('System default', null),
  'gothic': ('Gothic · Noto Sans JP', 'YomiNotoSansJP'),
  'mincho': ('Mincho · Noto Serif JP', 'YomiNotoSerifJP'),
  'rounded': ('Rounded · Zen Maru Gothic', 'YomiRoundedJP'),
};
const maxFontBytes = 32 * 1024 * 1024;

class FontImportFailure implements Exception {
  const FontImportFailure(this.message);
  final String message;
}

/// Validate bounded SFNT table ranges before passing a user font to platform parsers.
/// Only individual TrueType/OpenType fonts are supported, not archives or web fonts.
void validateFontBytes(Uint8List bytes) {
  if (bytes.length < 12 || bytes.length > maxFontBytes) {
    throw const FontImportFailure(
      'Choose a TTF or OTF font smaller than 32 MiB.',
    );
  }
  final data = ByteData.sublistView(bytes);
  final signature = data.getUint32(0);
  if (signature != 0x00010000 && signature != 0x4f54544f) {
    throw const FontImportFailure(
      'This is not a supported TTF or OTF font. Collections and web fonts are not supported.',
    );
  }
  final count = data.getUint16(4);
  if (count == 0 || count > 512 || 12 + count * 16 > bytes.length) {
    throw const FontImportFailure('The font table directory is invalid.');
  }
  final tags = <String>{};
  for (var i = 0; i < count; i++) {
    final start = 12 + i * 16;
    final tag = String.fromCharCodes(bytes.sublist(start, start + 4));
    final offset = data.getUint32(start + 8);
    final length = data.getUint32(start + 12);
    if (!tags.add(tag) ||
        offset < 12 + count * 16 ||
        offset > bytes.length ||
        length > bytes.length - offset) {
      throw const FontImportFailure(
        'The font contains invalid or truncated tables.',
      );
    }
  }
  if (!tags.containsAll(['cmap', 'head', 'maxp'])) {
    throw const FontImportFailure(
      'The font is missing required character or metric tables.',
    );
  }
}

class ImportedFont {
  const ImportedFont({
    required this.id,
    required this.name,
    required this.file,
  });
  final String id, name, file;
  String get family => 'YomiCustom$id';
  Map<String, String> toJson() => {'id': id, 'name': name, 'file': file};
}

class JapaneseFontSettings {
  const JapaneseFontSettings({
    this.selected = 'system',
    this.imported = const [],
    this.scale = 1,
    this.lineHeight = 1.6,
  });
  final String selected;
  final List<ImportedFont> imported;
  final double scale, lineHeight;
  ImportedFont? get custom =>
      imported.where((f) => f.id == selected).firstOrNull;
  String? get family => fontPresets[selected]?.$2 ?? custom?.family;
  JapaneseFontSettings copyWith({
    String? selected,
    List<ImportedFont>? imported,
    double? scale,
    double? lineHeight,
  }) => JapaneseFontSettings(
    selected: selected ?? this.selected,
    imported: imported ?? this.imported,
    scale: scale ?? this.scale,
    lineHeight: lineHeight ?? this.lineHeight,
  );
  Map<String, dynamic> toJson() => {
    'selected': selected,
    'imported': imported.map((f) => f.toJson()).toList(),
    'scale': scale,
    'lineHeight': lineHeight,
  };
  Map<String, dynamic> get native => {
    'key': selected,
    'file': custom?.file ?? '',
    'scale': scale,
    'lineHeight': lineHeight,
  };
  factory JapaneseFontSettings.fromJson(Map<String, dynamic> json) {
    final imported = <ImportedFont>[];
    for (final item in (json['imported'] as List? ?? []).take(10)) {
      if (item is! Map) continue;
      final id = item['id'], name = item['name'], file = item['file'];
      if (id is String &&
          RegExp(r'^custom-[a-z0-9]+$').hasMatch(id) &&
          name is String &&
          file is String &&
          RegExp(r'^font-[a-z0-9]+\.(ttf|otf)$').hasMatch(file)) {
        imported.add(ImportedFont(id: id, name: name, file: file));
      }
    }
    final selected = json['selected'];
    return JapaneseFontSettings(
      selected:
          selected is String &&
              (fontPresets.containsKey(selected) ||
                  imported.any((f) => f.id == selected))
          ? selected
          : 'system',
      imported: imported,
      scale: json['scale'] is num
          ? (json['scale'] as num).toDouble().clamp(.85, 1.4)
          : 1,
      lineHeight: json['lineHeight'] is num
          ? (json['lineHeight'] as num).toDouble().clamp(1.2, 2.2)
          : 1.6,
    );
  }
}

final japaneseFontsProvider =
    NotifierProvider<JapaneseFonts, JapaneseFontSettings>(JapaneseFonts.new);

class JapaneseFonts extends Notifier<JapaneseFontSettings> {
  static final _loaded = <String>{};
  int revision = 0;
  @override
  JapaneseFontSettings build() {
    restore();
    return const JapaneseFontSettings();
  }

  Future<Directory> get directory async =>
      Directory('${(await getApplicationSupportDirectory()).path}/fonts')
          .create(recursive: true);
  Future<void> restore() async {
    final request = revision;
    final repo = ref.read(repositoryProvider);
    final value = await (repo.user.select(
      repo.user.preferences,
    )..where((p) => p.key.equals('typography'))).getSingleOrNull();
    if (!ref.mounted || request != revision) return;
    var settings = const JapaneseFontSettings();
    try {
      if (value != null) {
        settings = JapaneseFontSettings.fromJson(
          jsonDecode(value.value) as Map<String, dynamic>,
        );
      }
      if (settings.custom != null) await load(settings.custom!);
      if (!ref.mounted || request != revision) return;
      await ref.read(androidProvider).setTypography(settings.native);
    } catch (_) {
      settings = settings.copyWith(selected: 'system');
      if (ref.mounted && request == revision) {
        await ref.read(androidProvider).setTypography(settings.native);
      }
    }
    if (ref.mounted && request == revision) state = settings;
  }

  Future<void> load(ImportedFont font) async {
    if (_loaded.contains(font.id)) return;
    final file = File('${(await directory).path}/${font.file}');
    if (!await file.exists()) {
      throw const FontImportFailure(
        'This font file is missing. Import it again.',
      );
    }
    final bytes = await file.readAsBytes();
    validateFontBytes(bytes);
    await ref.read(androidProvider).validateFont(font.file);
    final loader = FontLoader(font.family)
      ..addFont(Future.value(ByteData.sublistView(bytes)));
    await loader.load();
    _loaded.add(font.id);
  }

  Future<void> save(JapaneseFontSettings settings) async {
    ++revision;
    if (settings.custom != null) await load(settings.custom!);
    final previous = state;
    final repo = ref.read(repositoryProvider);
    await repo.user
        .into(repo.user.preferences)
        .insertOnConflictUpdate(
          PreferencesCompanion.insert(
            key: 'typography',
            value: jsonEncode(settings.toJson()),
          ),
        );
    try {
      await ref.read(androidProvider).setTypography(settings.native);
    } catch (_) {
      await repo.user
          .into(repo.user.preferences)
          .insertOnConflictUpdate(
            PreferencesCompanion.insert(
              key: 'typography',
              value: jsonEncode(previous.toJson()),
            ),
          );
      rethrow;
    }
    if (ref.mounted) state = settings;
  }

  Future<void> importFont(String path, String name) async {
    if (state.imported.length >= 10) {
      throw const FontImportFailure(
        'You can keep up to 10 imported fonts. Remove one before adding another.',
      );
    }
    final extension = name.split('.').last.toLowerCase();
    if (!['ttf', 'otf'].contains(extension)) {
      throw const FontImportFailure('Choose an individual .ttf or .otf font.');
    }
    final source = File(path);
    if (await source.length() > maxFontBytes) {
      throw const FontImportFailure('The font exceeds the 32 MiB limit.');
    }
    final bytes = await source.readAsBytes();
    validateFontBytes(bytes);
    final id = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final font = ImportedFont(
      id: 'custom-$id',
      name: name
          .replaceAll(RegExp(r'[\x00-\x1f]'), '')
          .runes
          .take(100)
          .map(String.fromCharCode)
          .join(),
      file: 'font-$id.$extension',
    );
    final target = File('${(await directory).path}/${font.file}');
    await target.writeAsBytes(bytes, flush: true);
    try {
      await load(font);
      await save(
        state.copyWith(selected: font.id, imported: [...state.imported, font]),
      );
    } catch (_) {
      await target.delete();
      rethrow;
    }
  }

  Future<void> remove(ImportedFont font) async {
    await save(
      state.copyWith(
        selected: state.selected == font.id ? 'system' : state.selected,
        imported: state.imported.where((f) => f.id != font.id).toList(),
      ),
    );
    final file = File('${(await directory).path}/${font.file}');
    if (await file.exists()) await file.delete();
  }
}
