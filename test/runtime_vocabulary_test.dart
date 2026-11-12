// Drives the real runtime code paths (asset bundle -> LevelService /
// MiniGameData -> GameProvider) and checks that what the app actually serves
// is the corrected, globally unique vocabulary.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:word_puzzle/data/mini_game_data.dart';
import 'package:word_puzzle/providers/game_provider.dart';
import 'package:word_puzzle/services/level_service.dart';

import '../tool/vocabulary_audit.dart';

List<dynamic> _json(String name) =>
    (jsonDecode(File('assets/$name').readAsStringSync()) as Map<String, dynamic>)['levels'] as List<dynamic>;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Same calls as main.dart
    await LevelService.loadDataset();
    await MiniGameData.loadDatasets();
  });

  test('Main Game: runtime levels match the dataset and never repeat a word', () {
    final data = _json('word_wheel_300_levels.json');
    final Map<String, int> seen = {};
    for (int id = 1; id <= 300; id++) {
      final level = LevelService.getLevel(id);
      final expected = (data[id - 1]['words_to_make'] as List<dynamic>).cast<String>();
      expect(level.id, equals(id));
      expect(level.requiredWords, equals(expected), reason: 'Level $id words');
      expect(level.letters, equals(data[id - 1]['main_word']), reason: 'Level $id letters');
      for (final w in level.requiredWords) {
        expect(seen.containsKey(w), isFalse, reason: '"$w" in level $id was already used in level ${seen[w]}');
        seen[w] = id;
      }
    }
    expect(seen.length, equals(2694));
  });

  test('Main Game: sampled levels can be played to completion through GameProvider', () {
    for (final id in [1, 5, 6, 10, 57, 120, 150, 151, 222, 298, 299, 300]) {
      final provider = GameProvider(id);
      final level = provider.currentLevel;
      for (final word in level.requiredWords) {
        // spell the word by picking wheel tiles, exactly like the UI does
        final picked = <int>[];
        for (final ch in word.split('')) {
          final idx = List.generate(provider.wheelLetters.length, (i) => i)
              .firstWhere((i) => provider.wheelLetters[i] == ch && !picked.contains(i), orElse: () => -1);
          expect(idx, isNot(-1), reason: 'Level $id: wheel cannot spell "$word"');
          picked.add(idx);
          provider.selectIndex(idx);
        }
        SubmissionResult? got;
        provider.submitWord((w, result) => got = result);
        expect(got, equals(SubmissionResult.validRequired), reason: 'Level $id: "$word"');
      }
      expect(provider.isLevelComplete, isTrue, reason: 'Level $id should complete');
    }
  });

  test('Main Game: hardcoded fallback list serves only that level\'s own unique words', () {
    final data = _json('word_wheel_300_levels.json');
    expect(LevelService.levels.length, equals(300));
    for (int i = 0; i < 300; i++) {
      final fallback = LevelService.levels[i];
      final expected = (data[i]['words_to_make'] as List<dynamic>).cast<String>().toSet();
      expect(fallback.id, equals(i + 1));
      expect({...fallback.requiredWords, ...fallback.bonusWords}, equals(expected), reason: 'Fallback level ${i + 1}');
    }
    final all = data.expand((l) => (l['words_to_make'] as List<dynamic>).cast<String>()).toSet();
    expect(LevelService.allVocabulary.toSet(), equals(all));
  });

  test('Crossword: runtime puzzles match the dataset, every answer unique and placed correctly', () {
    final data = _json('crossword_50_levels.json');
    final puzzles = MiniGameData.crosswords;
    expect(puzzles.length, equals(50));
    final Set<String> seen = {};
    for (int i = 0; i < puzzles.length; i++) {
      final p = puzzles[i];
      final expected = (data[i]['words'] as List<dynamic>).map((w) => w['answer'] as String).toList();
      expect(p.words.map((w) => w.answer).toList(), equals(expected), reason: 'Crossword ${i + 1}');
      for (final w in p.words) {
        expect(seen.add(w.answer), isTrue, reason: 'Crossword answer "${w.answer}" repeats (level ${p.id})');
        expect(w.clue.trim(), isNotEmpty);
        for (int k = 0; k < w.answer.length; k++) {
          final r = w.row + (w.direction == 'down' ? k : 0);
          final c = w.col + (w.direction == 'across' ? k : 0);
          expect(p.solution[r][c], equals(w.answer[k]), reason: 'Crossword ${p.id} "${w.answer}" cell [$r,$c]');
          final g = p.grid[r][c];
          expect(g == '_' || g == w.answer[k], isTrue, reason: 'Crossword ${p.id} prefilled cell [$r,$c]');
        }
      }
    }
    expect(seen.length, equals(250));
  });

  test('Riddles: runtime puzzles match the dataset and every answer is unique', () {
    final data = _json('word_riddle_50_levels.json');
    final puzzles = MiniGameData.riddles;
    expect(puzzles.length, equals(50));
    final Set<String> seen = {};
    for (int i = 0; i < puzzles.length; i++) {
      expect(puzzles[i].answer, equals(data[i]['answer']));
      expect(puzzles[i].clue, equals(data[i]['clue']));
      expect(seen.add(normalizeWord(puzzles[i].answer)), isTrue, reason: 'Riddle answer "${puzzles[i].answer}" repeats');
    }
  });

  test('Word Search: runtime boards contain every unique target at its coordinates', () {
    final puzzles = MiniGameData.wordSearches;
    expect(puzzles.length, equals(50));
    final Set<String> seen = {};
    for (final p in puzzles) {
      expect(p.board.length, equals(p.size));
      for (final w in p.words) {
        expect(seen.add(w.word), isTrue, reason: 'Word search target "${w.word}" repeats (level ${p.id})');
        final d = wordSearchDirections[w.direction]!;
        final sb = StringBuffer();
        for (int k = 0; k < w.word.length; k++) {
          sb.write(p.board[w.startRow + d[0] * k][w.startCol + d[1] * k]);
        }
        expect(sb.toString(), equals(w.word), reason: 'Word search ${p.id} "${w.word}"');
        expect(w.startRow + d[0] * (w.word.length - 1), equals(w.endRow));
        expect(w.startCol + d[1] * (w.word.length - 1), equals(w.endCol));
      }
    }
    expect(seen.length, equals(250));
  });

  test('All four games together serve zero repeated words at runtime', () {
    final Map<String, String> seen = {};
    void use(String word, String where) {
      final key = normalizeWord(word);
      expect(seen.containsKey(key), isFalse, reason: '"$word" in $where already used in ${seen[key]}');
      seen[key] = where;
    }

    for (int id = 1; id <= 300; id++) {
      for (final w in LevelService.getLevel(id).requiredWords) {
        use(w, 'Main $id');
      }
    }
    for (final p in MiniGameData.crosswords) {
      for (final w in p.words) {
        use(w.answer, 'Crossword ${p.id}');
      }
    }
    for (final p in MiniGameData.riddles) {
      use(p.answer, 'Riddle ${p.id}');
    }
    for (final p in MiniGameData.wordSearches) {
      for (final w in p.words) {
        use(w.word, 'Word Search ${p.id}');
      }
    }
    expect(seen.length, equals(3244));
  });
}
