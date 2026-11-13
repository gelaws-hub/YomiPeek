import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app.dart';
import 'fonts.dart';

class FontSettingsPage extends ConsumerStatefulWidget {
  const FontSettingsPage({super.key});
  @override
  ConsumerState<FontSettingsPage> createState() => _FontSettingsPageState();
}

class _FontSettingsPageState extends ConsumerState<FontSettingsPage> {
  bool busy = false;
  double? scale, height;
  Future<void> perform(Future<void> Function() action) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is FontImportFailure
                  ? e.message
                  : 'Could not apply this font. Check the file and try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          busy = false;
          scale = null;
          height = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(japaneseFontsProvider);
    final notifier = ref.read(japaneseFontsProvider.notifier);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Japanese typography'),
        actions: [
          IconButton(
            tooltip: 'Import font',
            icon: const Icon(Icons.file_upload_outlined),
            onPressed: busy
                ? null
                : () => perform(() async {
                    final picked = await FilePicker.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['ttf', 'otf'],
                    );
                    final file = picked.isEmpty ? null : picked.single;
                    if (file?.path != null) {
                      await notifier.importFont(file!.path!, file.name);
                    }
                  }),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const Text(
            'Make Japanese feel like your own.',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          const Text(
            'Choose a reading face for words, examples and characters. The floating dictionary uses the same settings.',
          ),
          const SizedBox(height: 20),
          Card(
            margin: EdgeInsets.zero,
            child: SizedBox(
              height: 220,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'READING PREVIEW',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        '日本語を、じっくり読む。',
                        key: const Key('font-preview'),
                        locale: const Locale('ja'),
                        style: TextStyle(
                          fontFamily: settings.family,
                          fontFamilyFallback: const ['YomiNotoSansJP'],
                          fontSize: 26 * (scale ?? settings.scale),
                          height: height ?? settings.lineHeight,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '食べる　たべる\n本の中で、新しい言葉に出会う。',
                        locale: const Locale('ja'),
                        style: TextStyle(
                          fontFamily: settings.family,
                          fontFamilyFallback: const ['YomiNotoSansJP'],
                          fontSize: 17 * (scale ?? settings.scale),
                          height: height ?? settings.lineHeight,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            key: ValueKey(settings.selected),
            initialValue: settings.selected,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Reading font'),
            items: [
              for (final entry in fontPresets.entries)
                DropdownMenuItem(value: entry.key, child: Text(entry.value.$1)),
              for (final font in settings.imported)
                DropdownMenuItem(
                  value: font.id,
                  child: Text(
                    font.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: busy
                ? null
                : (key) {
                    if (key != null) {
                      perform(
                        () => notifier.save(settings.copyWith(selected: key)),
                      );
                    }
                  },
          ),
          const SizedBox(height: 20),
          Text(
            'Reading size · ${((scale ?? settings.scale) * 100).round()}%',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Slider(
            key: const Key('reading-scale'),
            value: scale ?? settings.scale,
            min: .85,
            max: 1.4,
            divisions: 11,
            label: '${((scale ?? settings.scale) * 100).round()}%',
            onChanged: busy ? null : (v) => setState(() => scale = v),
            onChangeEnd: (v) => perform(() async {
              await notifier.save(settings.copyWith(scale: v));
              if (mounted) setState(() => scale = null);
            }),
          ),
          Text(
            'Line spacing · ${(height ?? settings.lineHeight).toStringAsFixed(1)}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Slider(
            key: const Key('reading-height'),
            value: height ?? settings.lineHeight,
            min: 1.2,
            max: 2.2,
            divisions: 10,
            label: (height ?? settings.lineHeight).toStringAsFixed(1),
            onChanged: busy ? null : (v) => setState(() => height = v),
            onChangeEnd: (v) => perform(() async {
              await notifier.save(settings.copyWith(lineHeight: v));
              if (mounted) setState(() => height = null);
            }),
          ),
          if (busy) const LinearProgressIndicator(),
          const Divider(),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Your fonts',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                tooltip: 'Reset typography',
                icon: const Icon(Icons.restart_alt),
                onPressed: busy
                    ? null
                    : () => perform(
                        () => notifier.save(
                          settings.copyWith(
                            selected: 'system',
                            scale: 1,
                            lineHeight: 1.6,
                          ),
                        ),
                      ),
              ),
            ],
          ),
          if (settings.imported.isEmpty)
            const Text(
              'Import a .ttf or .otf font using the upload icon. Fonts are copied to private app storage and stay available offline.',
            ),
          for (final font in settings.imported)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(font.name),
              subtitle: Text(
                settings.selected == font.id
                    ? 'Selected · stored on this device'
                    : 'Stored on this device',
              ),
              trailing: IconButton(
                tooltip: 'Remove ${font.name}',
                icon: const Icon(Icons.delete_outline),
                onPressed: busy
                    ? null
                    : () async {
                        if (await confirm(context, 'Remove ${font.name}?')) {
                          await perform(() => notifier.remove(font));
                        }
                      },
              ),
            ),
          const SizedBox(height: 16),
          const Text(
            'TTF and OTF only · up to 32 MiB each · 10 imported fonts. Missing characters fall back to Japanese Gothic. Use a font that includes the Japanese characters you read.',
          ),
        ],
      ),
    );
  }
}
