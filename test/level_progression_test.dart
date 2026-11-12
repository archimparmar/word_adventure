import 'package:flutter_test/flutter_test.dart';
import 'package:word_puzzle/services/level_service.dart';
import 'package:word_puzzle/providers/game_provider.dart';

void main() {
  test('Verify required word counts for all 300 levels', () {
    for (int i = 1; i <= 300; i++) {
      final level = LevelService.getLevel(i);

      expect(
        level.requiredWords.isNotEmpty,
        isTrue,
        reason: 'Level $i requiredWords must not be empty',
      );

      expect(
        level.letters.isNotEmpty,
        isTrue,
        reason: 'Level $i letters must not be empty',
      );
    }
  });

  test('Verify letter wheel shuffle and duplicate letter retention for levels', () {
    final List<int> sampleLevels = [1, 6, 9, 28, 31, 80, 150, 221, 300];

    for (final levelId in sampleLevels) {
      final level = LevelService.getLevel(levelId);
      final word = level.letters.toUpperCase();
      final provider = GameProvider(levelId);

      // Check initial shuffle
      expect(
        provider.wheelLetters.length,
        equals(word.length),
        reason: 'Wheel letter length for $word on level $levelId',
      );

      final List<String> originalSorted = word.split('')..sort();
      final List<String> wheelSorted = List.from(provider.wheelLetters)..sort();
      expect(
        wheelSorted,
        equals(originalSorted),
        reason: 'Initial wheel letters multiset for $word on level $levelId',
      );

      // Check shuffle method
      provider.shuffle();
      expect(provider.wheelLetters.length, equals(word.length));
      final List<String> wheelSortedAfter = List.from(provider.wheelLetters)..sort();
      expect(
        wheelSortedAfter,
        equals(originalSorted),
        reason: 'Shuffled wheel letters multiset for $word on level $levelId',
      );
    }
  });
}
