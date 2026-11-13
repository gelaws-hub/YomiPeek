import '../data/repository.dart';
import 'japanese.dart';

/// Bounded longest dictionary match starting at a user-chosen character.
/// This is a lookup aid, not a morphological Japanese sentence tokenizer.
Future<String> wordAt(
  String text,
  int offset,
  DictionaryRepository repository,
) async {
  if (offset < 0 || offset >= text.length) return '';
  // Native TextView and Dart both use UTF-16 offsets. Avoid splitting a surrogate.
  if (offset > 0 &&
      text.codeUnitAt(offset) >= 0xdc00 &&
      text.codeUnitAt(offset) <= 0xdfff) {
    offset--;
  }
  while (offset < text.length && RegExp(r'\s').hasMatch(text[offset])) {
    offset++;
  }
  if (offset >= text.length) return '';
  final latin = RegExp(r'[a-zA-Z0-9]');
  if (latin.hasMatch(text[offset])) {
    while (offset > 0 && latin.hasMatch(text[offset - 1])) {
      offset--;
    }
  }
  final characters = text
      .substring(offset)
      .runes
      .take(16)
      .map(String.fromCharCode)
      .takeWhile((c) => !RegExp(r'[\s、。！？「」『』（）,.!?;:]').hasMatch(c))
      .toList();
  for (var length = characters.length; length > 0; length--) {
    final candidate = characters.take(length).join();
    final roots = deinflect(candidate).map((v) => v.word).toSet();
    final matches = await repository.search(candidate);
    if (matches.any(
      (r) =>
          roots.contains(r.term.normalized) ||
          roots.contains(r.term.normalizedReading),
    )) {
      return candidate;
    }
  }
  return characters.isEmpty ? '' : characters.first;
}
