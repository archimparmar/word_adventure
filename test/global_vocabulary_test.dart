import 'package:flutter_test/flutter_test.dart';

import '../tool/vocabulary_audit.dart';

void main() {
  final result = runVocabularyAudit();

  test('No gameplay word repeats anywhere across the four games', () {
    // ignore: avoid_print
    print(result.report());
    expect(result.duplicates, isEmpty, reason: 'Every gameplay word must be globally unique');
    expect(result.relatedForms, isEmpty, reason: 'Inflected forms of a used word count as the same word');
    expect(result.entries.length, equals(result.uniqueWords));
  });

  test('Level counts are unchanged', () {
    expect(result.levelCounts['main'], equals(300));
    expect(result.levelCounts['crossword'], equals(50));
    expect(result.levelCounts['riddle'], equals(50));
    expect(result.levelCounts['wordsearch'], equals(50));
  });

  test('Main Game vocabulary is valid', () {
    expect(result.mainErrors, isEmpty);
  });

  test('Crossword grids, intersections and clues are valid', () {
    expect(result.crosswordErrors, isEmpty);
  });

  test('Riddle data is valid', () {
    expect(result.riddleErrors, isEmpty);
  });

  test('Word Search boards and placements are valid', () {
    expect(result.wordSearchErrors, isEmpty);
  });

  test('Hardcoded runtime fallbacks match the corrected datasets', () {
    expect(result.fallbackErrors, isEmpty);
  });

  test('Normalization treats case, spacing and punctuation as the same word', () {
    expect(normalizeWord('Apple'), equals('APPLE'));
    expect(normalizeWord(' apple '), equals('APPLE'));
    expect(normalizeWord('LETTER M'), equals('LETTERM'));
    expect(normalizeWord('ice-cream'), equals(normalizeWord('ICE CREAM')));
  });
}
