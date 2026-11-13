import 'package:unorm_dart/unorm_dart.dart' as unicode;

String normalize(String input) => String.fromCharCodes(
  unicode
      .nfkc(input.trim())
      .toLowerCase()
      .runes
      .map((c) => c >= 0x30a1 && c <= 0x30f6 ? c - 0x60 : c),
);

class Inflection {
  const Inflection(this.word, this.steps, [this.rule = '']);
  final String word;
  final List<String> steps;
  final String rule;
}

// Rule labels are validated against the imported term's Yomitan rule classes.
List<Inflection> deinflect(String input) {
  final results = <Inflection>[Inflection(normalize(input), [])];
  final seen = <String>{results.first.word};
  final rules = <(String, String, String, String)>[
    ('ました', 'る', 'polite past', 'v1'),
    ('ます', 'る', 'polite', 'v1'),
    ('ません', 'る', 'polite negative', 'v1'),
    ('ませんでした', 'ません', 'polite negative past', ''),
    ('なかった', 'ない', 'negative past', ''),
    ('ない', 'る', 'negative', 'v1'),
    ('た', 'る', 'past', 'v1'),
    ('て', 'る', 'te-form', 'v1'),
    ('ている', 'て', 'progressive', ''),
    ('でいる', 'で', 'progressive', ''),
    ('かった', 'い', 'past adjective', 'adj-i'),
    ('くない', 'い', 'negative adjective', 'adj-i'),
    ('した', 'する', 'past', 'vs'),
    ('しました', 'する', 'polite past', 'vs'),
    ('しない', 'する', 'negative', 'vs'),
    ('します', 'する', 'polite', 'vs'),
    ('しません', 'する', 'polite negative', 'vs'),
    ('して', 'する', 'te-form', 'vs'),
    ('きます', 'くる', 'polite', 'vk'),
    ('きました', 'くる', 'polite past', 'vk'),
    ('きません', 'くる', 'polite negative', 'vk'),
    ('きて', 'くる', 'te-form', 'vk'),
    ('来ます', '来る', 'polite', 'vk'),
    ('来ました', '来る', 'polite past', 'vk'),
    ('来ません', '来る', 'polite negative', 'vk'),
    ('来て', '来る', 'te-form', 'vk'),
    ('きた', 'くる', 'past', 'vk'),
    ('こない', 'くる', 'negative', 'vk'),
    ('来た', '来る', 'past', 'vk'),
    ('来ない', '来る', 'negative', 'vk'),
    ('いった', 'いく', 'past', 'v5'),
    ('行った', '行く', 'past', 'v5'),
    for (final ending in ['った', 'って'])
      for (final base in ['う', 'つ', 'る'])
        (ending, base, 'past / te-form', 'v5'),
    for (final ending in ['んだ', 'んで'])
      for (final base in ['む', 'ぶ', 'ぬ'])
        (ending, base, 'past / te-form', 'v5'),
    ('いた', 'く', 'past', 'v5'),
    ('いて', 'く', 'te-form', 'v5'),
    ('いだ', 'ぐ', 'past', 'v5'),
    ('いで', 'ぐ', 'te-form', 'v5'),
    ('した', 'す', 'past', 'v5'),
    ('して', 'す', 'te-form', 'v5'),
    ('いって', 'いく', 'te-form', 'v5'),
    ('行って', '行く', 'te-form', 'v5'),
    for (final pair in [
      ('わ', 'う'),
      ('か', 'く'),
      ('が', 'ぐ'),
      ('さ', 'す'),
      ('た', 'つ'),
      ('な', 'ぬ'),
      ('ば', 'ぶ'),
      ('ま', 'む'),
      ('ら', 'る'),
    ])
      ('${pair.$1}ない', pair.$2, 'negative', 'v5'),
    for (final pair in [
      ('い', 'う'),
      ('き', 'く'),
      ('ぎ', 'ぐ'),
      ('し', 'す'),
      ('ち', 'つ'),
      ('に', 'ぬ'),
      ('び', 'ぶ'),
      ('み', 'む'),
      ('り', 'る'),
    ])
      for (final suffix in ['ます', 'ました', 'ません'])
        ('${pair.$1}$suffix', pair.$2, 'polite', 'v5'),
  ];
  for (var i = 0; i < results.length && results.length < 128; i++) {
    final current = results[i];
    if (current.steps.length >= 4) continue;
    for (final r in rules) {
      if (!current.word.endsWith(r.$1) ||
          (current.word.length < r.$1.length ||
              (current.word.length == r.$1.length &&
                  r.$4 != 'vs' &&
                  r.$4 != 'vk'))) {
        continue;
      }
      final word =
          current.word.substring(0, current.word.length - r.$1.length) + r.$2;
      if (seen.add('$word:${r.$4}') && results.length < 128) {
        results.add(Inflection(word, [...current.steps, r.$3], r.$4));
      }
    }
  }
  return results;
}
