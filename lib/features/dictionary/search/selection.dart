import '../data/repository.dart';

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
  final candidates = [
    for (var length = characters.length; length > 0; length--)
      characters.take(length).join(),
  ];
  final valid = await repository.validCandidates(candidates);
  for (final candidate in candidates) {
    if (valid.contains(candidate)) return candidate;
  }
  return characters.isEmpty ? '' : characters.first;
}

class SentenceToken {
  const SentenceToken(this.text, this.offset, this.known);
  final String text;
  final int offset;
  final bool known;
}

/// Dictionary-assisted longest match; not a morphological grammar parser.
Future<List<SentenceToken>> sentenceTokens(
  String text,
  DictionaryRepository repo, {
  bool Function()? cancelled,
}) async {
  final tokens = <SentenceToken>[];
  var offset = 0;
  // Bounded preview; the complete text remains visible and individually tappable.
  final limit = text.length.clamp(0, 320);
  while (offset < limit && !(cancelled?.call() ?? false)) {
    final char = String.fromCharCode(text.runeAt(offset));
    if (RegExp(r'[\s、。！？「」（）,!?;:]').hasMatch(char)) {
      tokens.add(SentenceToken(char, offset, false));
      offset += char.length;
      continue;
    }
    final latin = RegExp(r'^[a-zA-Z0-9]+').firstMatch(text.substring(offset));
    if (latin != null) {
      final value = latin.group(0)!;
      tokens.add(
        SentenceToken(
          value,
          offset,
          (await repo.validCandidates([value])).isNotEmpty,
        ),
      );
      offset += value.length;
      continue;
    }
    final candidate = await wordAt(text, offset, repo);
    final value = candidate.isEmpty ? char : candidate;
    final valid = await repo.validCandidates([value]);
    tokens.add(SentenceToken(value, offset, valid.isNotEmpty));
    offset += value.length;
  }
  return tokens;
}

extension on String {
  int runeAt(int offset) => substring(offset).runes.first;
}
