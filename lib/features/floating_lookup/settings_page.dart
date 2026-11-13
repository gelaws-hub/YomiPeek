import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/platform/android_gateway.dart';

class FloatingSettingsPage extends ConsumerStatefulWidget {
  const FloatingSettingsPage({super.key});
  @override
  ConsumerState<FloatingSettingsPage> createState() =>
      _FloatingSettingsPageState();
}

class _FloatingSettingsPageState extends ConsumerState<FloatingSettingsPage>
    with WidgetsBindingObserver {
  late Future<FloatingState> current;
  bool working = false;
  StreamSubscription<void>? changes;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    current = ref.read(androidProvider).state();
    changes = ref.read(androidProvider).changes.listen((_) {
      if (mounted) refresh();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    changes?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) refresh();
  }

  void refresh() {
    setState(() {
      current = ref.read(androidProvider).state();
    });
  }

  Future<void> action(Future<void> Function() run) async {
    if (working) return;
    setState(() => working = true);
    try {
      await run();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is PlatformException
                  ? error.message ?? 'Android could not complete this action.'
                  : 'Android could not complete this action.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => working = false);
        refresh();
      }
    }
  }

  Future<void> permission() async {
    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Allow floating dictionary?'),
        content: const Text(
          'YomiPeek can display a small movable dictionary above other apps. This is optional. Selected text can still open in the full app without this permission.\n\nEnable “Allow display over other apps” for YomiPeek on the next Android screen.',
        ),
        actions: [
          IconButton(
            tooltip: 'Cancel',
            onPressed: () => Navigator.pop(context, false),
            icon: const Icon(Icons.close),
          ),
          IconButton.filled(
            tooltip: 'Open Android settings',
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.open_in_new),
          ),
        ],
      ),
    );
    if (proceed == true && mounted) {
      await action(() => ref.read(androidProvider).permission());
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Floating lookup')),
    body: FutureBuilder<FloatingState>(
      future: current,
      builder: (context, snapshot) {
        final state = snapshot.data ?? const FloatingState();
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Japanese wherever you read',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            const Text(
              'Select text in a compatible app and choose YomiPeek. Android and the host app decide whether the action appears in the toolbar or its overflow menu.',
            ),
            const SizedBox(height: 16),
            const Text(
              'Without overlay permission, selections open in YomiPeek. With permission, they open in a movable floating window. Long selections support tapping the first character of a word.',
            ),
            const SizedBox(height: 24),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Display over other apps'),
              subtitle: Text(
                !state.available
                    ? 'Android integration is unavailable on this platform.'
                    : state.permission
                    ? 'Allowed by Android'
                    : 'Not allowed · full-app lookup still works',
              ),
              trailing: IconButton.outlined(
                tooltip: state.permission
                    ? 'Manage overlay permission'
                    : 'Allow display over other apps',
                onPressed: working || !state.available ? null : permission,
                icon: Icon(
                  state.permission ? Icons.tune : Icons.layers_outlined,
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton.filled(
                onPressed: working || !state.permission
                    ? null
                    : () => action(() => ref.read(androidProvider).open('')),
                icon: const Icon(Icons.open_in_new),
                tooltip: 'Open floating dictionary',
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Floating shortcut'),
              subtitle: const Text(
                'Keeps a small movable lookup button above other apps. Close it with × or Stop in the ongoing notification. Android may ask to show notifications; denial does not block lookup.',
              ),
              value: state.shortcut,
              onChanged: working || !state.permission
                  ? null
                  : (v) => action(() => ref.read(androidProvider).shortcut(v)),
            ),
            const Divider(),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Clipboard privacy'),
              subtitle: Text(
                'Paste reads plain text only after you tap Paste. YomiPeek never monitors the clipboard in the background.',
              ),
            ),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Pronunciation'),
              subtitle: Text(
                'Speak uses an installed offline Japanese Android voice. If no voice is ready, YomiPeek explains how to install one; it does not download audio automatically.',
              ),
            ),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Android limits'),
              subtitle: Text(
                'Secure screens may hide overlays. Shortcut state is remembered, but Android may stop the service; reopening YomiPeek restores an enabled shortcut. There is no boot auto-start or Accessibility Service.',
              ),
            ),
          ],
        );
      },
    ),
  );
}
