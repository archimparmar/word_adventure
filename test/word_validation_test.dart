// Main Game word submission: REQUIRED vs BONUS vs INVALID vs ALREADY FOUND.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:word_puzzle/providers/game_provider.dart';
import 'package:word_puzzle/services/dictionary_service.dart';
import 'package:word_puzzle/services/level_service.dart';

SubmissionResult? _submit(GameProvider p, String word) {
  final picked = <int>[];
  for (final ch in word.split('')) {
    final idx = List.generate(p.wheelLetters.length, (i) => i)
        .firstWhere((i) => p.wheelLetters[i] == ch && !picked.contains(i), orElse: () => -1);
    if (idx < 0) {
      p.clearSelection();
      return null; // cannot be spelled with the wheel
    }
    picked.add(idx);
    p.selectIndex(idx);
  }
  SubmissionResult? result;
  p.submitWord((w, r) => result = r);
  return result;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await LevelService.loadDataset();
    await DictionaryService.loadDictionary();
  });

  test('Dictionary loads and knows common words but not junk', () {
    expect(DictionaryService.isLoaded, isTrue);
    for (final w in ['ACT', 'TONE', 'ATE', 'TAP', 'PALE', 'NOTES', 'STONE', 'WALKED', 'RUNNING', 'HAPPY']) {
      expect(DictionaryService.isValidWord(w), isTrue, reason: w);
    }
    for (final w in ['ZXQ', 'USA', 'INC', 'FAQ', 'PDF', 'HTML', 'JOHN', 'TOM', 'EBAY', 'LANET', 'PLA', 'AE']) {
      expect(DictionaryService.isValidWord(w), isFalse, reason: w);
    }
  });

  test('Every curated Main Game word is in the dictionary', () {
    final levels = (jsonDecode(File('assets/word_wheel_300_levels.json').readAsStringSync())['levels'] as List<dynamic>);
    for (final l in levels) {
      for (final w in l['words_to_make'] as List<dynamic>) {
        expect(DictionaryService.isValidWord(w as String), isTrue, reason: 'Level ${l['level']} $w');
      }
    }
  });

  test('Level 1: required / bonus / invalid / already found', () {
    final p = GameProvider(1); // PLANET: required PLANET, TEN, LATE
    expect(p.currentLevel.requiredWords, equals(['PLANET', 'TEN', 'LATE']));

    expect(_submit(p, 'TEN'), SubmissionResult.validRequired);
    expect(_submit(p, 'TEN'), SubmissionResult.alreadyFound);

    // valid extra English words -> BONUS, never required
    for (final w in ['ATE', 'TAP', 'PALE', 'NEAT', 'PLAN', 'PLANE', 'PLATE']) {
      expect(_submit(p, w), SubmissionResult.validBonus, reason: w);
    }
    expect(_submit(p, 'PLAN'), SubmissionResult.alreadyFound);

    // non-words built from the same letters -> INVALID
    for (final w in ['LANET', 'PLA', 'TNE', 'ANPL', 'ETALP']) {
      expect(_submit(p, w), SubmissionResult.invalid, reason: w);
    }

    // bonus words did not touch the required list or completion
    expect(p.currentLevel.requiredWords, equals(['PLANET', 'TEN', 'LATE']));
    expect(p.foundWords, equals(['TEN']));
    expect(p.foundBonusWords, containsAll(['ATE', 'TAP', 'PALE', 'NEAT', 'PLAN', 'PLANE', 'PLATE']));
    expect(p.isLevelComplete, isFalse);

    expect(_submit(p, 'LATE'), SubmissionResult.validRequired);
    expect(p.isLevelComplete, isFalse);
    expect(_submit(p, 'PLANET'), SubmissionResult.validRequired);
    expect(p.isLevelComplete, isTrue);
  });

  test('Sampled levels: required words complete the level, extras are bonus only', () {
    final extras = {
      6: ['ODE', 'ELM', 'MOLDY'],
      10: ['SEW', 'EARS', 'SNARE'],
      57: ['GUT', 'TUB', 'DUET'],
      150: ['ROD', 'DICE', 'CORD'],
      300: ['LIE', 'TIN', 'HINT'],
    };
    extras.forEach((id, words) {
      final p = GameProvider(id);
      final required = List<String>.from(p.currentLevel.requiredWords);
      for (final w in words) {
        expect(required.contains(w), isFalse, reason: 'Level $id: $w must not be a required word');
        expect(_submit(p, w), SubmissionResult.validBonus, reason: 'Level $id: $w');
      }
      expect(p.foundWords, isEmpty, reason: 'Level $id: bonus words must not count as required');
      expect(p.isLevelComplete, isFalse);
      for (final w in required) {
        expect(_submit(p, w), SubmissionResult.validRequired, reason: 'Level $id: $w');
      }
      expect(p.isLevelComplete, isTrue, reason: 'Level $id completes with required words only');
      expect(p.currentLevel.requiredWords, equals(required));
    });
  });

  test('A real word that cannot be spelled from the level letters is never accepted', () {
    expect(DictionaryService.isValidWord('HOUSE'), isTrue);
    expect(DictionaryService.canFormWordFromLetters('HOUSE', 'PLANET'), isFalse);
    expect(DictionaryService.canFormWordFromLetters('PLANT', 'PLANET'), isTrue);
    expect(DictionaryService.canFormWordFromLetters('PLANTT', 'PLANET'), isFalse);
  });
}
