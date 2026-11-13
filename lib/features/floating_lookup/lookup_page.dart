import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app.dart';
import '../dictionary/data/repository.dart';
import '../dictionary/search/selection.dart';

class LookupPage extends ConsumerStatefulWidget {
  const LookupPage({required this.text, super.key});
  final String text;
  @override
  ConsumerState<LookupPage> createState() => _LookupPageState();
}

class _LookupPageState extends ConsumerState<LookupPage> {
  late final controller = TextEditingController(
    text: widget.text.length <= 64 ? widget.text : '',
  );
  List<WordResult> results = [];
  bool busy = false;
  String? error;
  int generation = 0;
  Timer? timer;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.text.length <= 64) {
        search(controller.text, remember: true);
      } else {
        choose(0);
      }
    });
  }

  Future<void> choose(int offset) async {
    final request = ++generation;
    setState(() => busy = true);
    try {
      final word = await wordAt(
        widget.text,
        offset,
        ref.read(repositoryProvider),
      );
      if (mounted && request == generation) {
        controller.text = word;
        search(word, remember: true);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          busy = false;
          error = 'Could not look up this selection.';
        });
      }
    }
  }

  void search(String query, {bool remember = false}) {
    timer?.cancel();
    final request = ++generation;
    setState(() {
      busy = query.trim().isNotEmpty;
      error = null;
    });
    timer = Timer(Duration(milliseconds: remember ? 0 : 250), () async {
      try {
        final repo = ref.read(repositoryProvider);
        final found = await repo.search(query);
        if (remember) await repo.remember(query);
        if (mounted && request == generation) {
          setState(() {
            results = found;
            busy = false;
          });
        }
      } catch (_) {
        if (mounted && request == generation) {
          setState(() {
            busy = false;
            error = 'Could not read local dictionaries.';
          });
        }
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Selected text')),
    body: CustomScrollView(
      key: const Key('selection-scroll'),
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              if (widget.text.isNotEmpty)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 160),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Wrap(children: characterButtons()),
                    ),
                  ),
                ),
              if (widget.text.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Tap the first character of a word, or edit the search below. Selections are limited to 2,000 characters.',
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: controller,
                  maxLength: 512,
                  onChanged: search,
                  onSubmitted: (q) => search(q, remember: true),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    labelText: 'Lookup',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      tooltip: 'Paste text',
                      icon: const Icon(Icons.content_paste),
                      onPressed: () async {
                        final data = await Clipboard.getData(
                          Clipboard.kTextPlain,
                        );
                        if (!mounted) return;
                        controller.text = (data?.text ?? '').runes
                            .take(512)
                            .map(String.fromCharCode)
                            .join();
                        search(controller.text, remember: true);
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (busy)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()),
          )
        else if (error != null)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Text(error!)),
          )
        else if (results.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No results. Import or enable a dictionary, or choose a shorter word.',
                ),
              ),
            ),
          )
        else
          SliverList.builder(
            itemCount: results.length,
            itemBuilder: (context, index) => WordCard(result: results[index]),
          ),
      ],
    ),
  );
  List<Widget> characterButtons() {
    final widgets = <Widget>[];
    var offset = 0;
    for (final rune in widget.text.runes) {
      final start = offset;
      final character = String.fromCharCode(rune);
      offset += character.length;
      widgets.add(
        InkWell(
          onTap: () => choose(start),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              character,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ),
      );
    }
    return widgets;
  }
}
