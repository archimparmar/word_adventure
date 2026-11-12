class Level {
  final int id;
  final String theme;
  final String letters;
  final List<String> requiredWords;
  final List<String> bonusWords;
  final String? hardWord;
  final int difficulty;
  final int reward;
  final int layoutPattern;

  Level({
    required this.id,
    required this.theme,
    required this.letters,
    required this.requiredWords,
    required this.bonusWords,
    this.hardWord,
    required this.difficulty,
    required this.reward,
    required this.layoutPattern,
  });
}
