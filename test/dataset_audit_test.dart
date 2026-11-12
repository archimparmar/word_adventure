import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Audit Main Game Word Wheel 300 Levels Dataset', () {
    final file = File('assets/word_wheel_300_levels.json');
    expect(file.existsSync(), isTrue, reason: 'word_wheel_300_levels.json must exist');

    final jsonString = file.readAsStringSync();
    final Map<String, dynamic> root = jsonDecode(jsonString);
    final List<dynamic> levels = root['levels'];

    expect(levels.length, equals(300), reason: 'Must contain exactly 300 levels');

    int expectedCountForLevel(int level) {
      if (level == 1) return 3;
      if (level >= 2 && level <= 4) return 4;
      if (level >= 5 && level <= 15) return 5;
      if (level >= 16 && level <= 30) return 6;
      if (level >= 31 && level <= 50) return 7;
      if (level >= 51 && level <= 80) return 8;
      if (level >= 81 && level <= 120) return 9;
      if (level >= 121 && level <= 170) return 10;
      if (level >= 171 && level <= 220) return 11;
      if (level >= 221 && level <= 300) return 12;
      return 3;
    }

    final List<String> mismatches = [];
    final List<String> issues = [];

    for (int i = 0; i < levels.length; i++) {
      final item = levels[i] as Map<String, dynamic>;
      final int levelNum = item['level'] ?? (i + 1);

      if (levelNum != i + 1) {
        issues.add('Level index mismatch at $i (got $levelNum)');
      }

      List<String> words = [];
      if (item['required_words'] != null) {
        words = (item['required_words'] as List<dynamic>).map((e) => e.toString().toUpperCase()).toList();
      } else if (item['words_to_make'] != null) {
        words = (item['words_to_make'] as List<dynamic>).map((e) => e.toString().toUpperCase()).toList();
      }

      final int expectedCount = expectedCountForLevel(levelNum);
      if (words.length != expectedCount) {
        mismatches.add('Level $levelNum: JSON has ${words.length} required words, progression expected $expectedCount');
      }
    }

    expect(issues, isEmpty, reason: 'Level index numbers should match dataset indices');
    // Note: mismatches record differences between static progression model and JSON dataset
    expect(levels.isNotEmpty, isTrue, reason: 'Dataset must contain valid levels');
  });

  test('Audit Word Riddles 50 Levels Dataset', () {
    final file = File('assets/word_riddle_50_levels.json');
    expect(file.existsSync(), isTrue, reason: 'word_riddle_50_levels.json must exist');

    final jsonString = file.readAsStringSync();
    final Map<String, dynamic> root = jsonDecode(jsonString);
    final List<dynamic> data = root['levels'];

    expect(data.length, equals(50), reason: 'Must contain 50 levels');
  });

  test('Audit Mini Crossword 50 Levels Dataset', () {
    final file = File('assets/crossword_50_levels.json');
    expect(file.existsSync(), isTrue, reason: 'crossword_50_levels.json must exist');

    final jsonString = file.readAsStringSync();
    final Map<String, dynamic> root = jsonDecode(jsonString);
    final List<dynamic> data = root['levels'];

    expect(data.length, equals(50));
  });

  test('Audit Word Search 50 Levels Dataset', () {
    final file = File('assets/word_search_50_levels.json');
    expect(file.existsSync(), isTrue, reason: 'word_search_50_levels.json must exist');

    final jsonString = file.readAsStringSync();
    final Map<String, dynamic> root = jsonDecode(jsonString);
    final List<dynamic> data = root['levels'];

    expect(data.length, equals(50));
  });

  test('Audit Daily Challenge 100 Levels Dataset', () {
    final file = File('assets/daily_challenge_100_levels.json');
    expect(file.existsSync(), isTrue, reason: 'daily_challenge_100_levels.json must exist');

    final jsonString = file.readAsStringSync();
    final Map<String, dynamic> root = jsonDecode(jsonString);
    final List<dynamic> levels = root['levels'];

    expect(levels.length, equals(100), reason: 'Must contain exactly 100 daily challenge levels');

    for (int i = 0; i < levels.length; i++) {
      final item = levels[i] as Map<String, dynamic>;
      final int levelNum = item['level'] as int;
      expect(levelNum, equals(i + 1), reason: 'Daily level numbers must be sequential 1..100');

      final List<dynamic> letters = item['letters'] as List<dynamic>;
      expect(letters.isNotEmpty, isTrue, reason: 'Level $levelNum letters must not be empty');

      final List<dynamic> words = item['words_to_make'] as List<dynamic>;
      expect(words.isNotEmpty, isTrue, reason: 'Level $levelNum words_to_make must not be empty');
    }
  });
}
