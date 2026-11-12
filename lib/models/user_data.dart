import 'dart:convert';

class UserData {
  final int currentLevel;
  final int coins;
  final int gems;
  final int hints;
  final int playerLevel;
  final int xp;
  final int streak;
  final int bestStreak;
  final DateTime? lastPlayed;
  final DateTime? lastDailyPuzzleDate;
  
  final int hintsUsed;
  final int wordsFound;
  final int bonusWordsFound;
  final int hardWordsFound;
  final int perfectLevels;
  final int riddlesCompleted;
  final int crosswordsCompleted;
  final bool completedDailyToday;
  
  final List<String> discoveredVocabulary;
  final List<String> unlockedThemes;
  final List<String> unlockedAchievements;
  final Map<String, int> miniGameLevels;
  final List<String> unlockedMiniGames;

  UserData({
    required this.currentLevel,
    required this.coins,
    required this.gems,
    required this.hints,
    required this.playerLevel,
    required this.xp,
    required this.streak,
    required this.bestStreak,
    this.lastPlayed,
    this.lastDailyPuzzleDate,
    required this.hintsUsed,
    required this.wordsFound,
    required this.bonusWordsFound,
    required this.hardWordsFound,
    required this.perfectLevels,
    required this.riddlesCompleted,
    required this.crosswordsCompleted,
    required this.completedDailyToday,
    required this.discoveredVocabulary,
    required this.unlockedThemes,
    required this.unlockedAchievements,
    required this.miniGameLevels,
    required this.unlockedMiniGames,
  });

  factory UserData.initial() {
    return UserData(
      currentLevel: 1,
      coins: 500,
      gems: 50,
      hints: 3,
      playerLevel: 1,
      xp: 0,
      streak: 0,
      bestStreak: 0,
      lastPlayed: null,
      lastDailyPuzzleDate: null,
      hintsUsed: 0,
      wordsFound: 0,
      bonusWordsFound: 0,
      hardWordsFound: 0,
      perfectLevels: 0,
      riddlesCompleted: 0,
      crosswordsCompleted: 0,
      completedDailyToday: false,
      discoveredVocabulary: [],
      unlockedThemes: ['Spring'],
      unlockedAchievements: [],
      miniGameLevels: {
        'word_wheel': 1,
        'mini_crossword': 1,
        'word_riddle': 1,
        'word_search': 1,
      },
      unlockedMiniGames: ['word_wheel'],
    );
  }

  UserData copyWith({
    int? currentLevel,
    int? coins,
    int? gems,
    int? hints,
    int? playerLevel,
    int? xp,
    int? streak,
    int? bestStreak,
    DateTime? lastPlayed,
    DateTime? lastDailyPuzzleDate,
    int? hintsUsed,
    int? wordsFound,
    int? bonusWordsFound,
    int? hardWordsFound,
    int? perfectLevels,
    int? riddlesCompleted,
    int? crosswordsCompleted,
    bool? completedDailyToday,
    List<String>? discoveredVocabulary,
    List<String>? unlockedThemes,
    List<String>? unlockedAchievements,
    Map<String, int>? miniGameLevels,
    List<String>? unlockedMiniGames,
  }) {
    return UserData(
      currentLevel: currentLevel ?? this.currentLevel,
      coins: coins ?? this.coins,
      gems: gems ?? this.gems,
      hints: hints ?? this.hints,
      playerLevel: playerLevel ?? this.playerLevel,
      xp: xp ?? this.xp,
      streak: streak ?? this.streak,
      bestStreak: bestStreak ?? this.bestStreak,
      lastPlayed: lastPlayed ?? this.lastPlayed,
      lastDailyPuzzleDate: lastDailyPuzzleDate ?? this.lastDailyPuzzleDate,
      completedDailyToday: completedDailyToday ?? this.completedDailyToday,
      hintsUsed: hintsUsed ?? this.hintsUsed,
      wordsFound: wordsFound ?? this.wordsFound,
      bonusWordsFound: bonusWordsFound ?? this.bonusWordsFound,
      hardWordsFound: hardWordsFound ?? this.hardWordsFound,
      perfectLevels: perfectLevels ?? this.perfectLevels,
      riddlesCompleted: riddlesCompleted ?? this.riddlesCompleted,
      crosswordsCompleted: crosswordsCompleted ?? this.crosswordsCompleted,
      discoveredVocabulary: discoveredVocabulary ?? this.discoveredVocabulary,
      unlockedThemes: unlockedThemes ?? this.unlockedThemes,
      unlockedAchievements: unlockedAchievements ?? this.unlockedAchievements,
      miniGameLevels: miniGameLevels ?? this.miniGameLevels,
      unlockedMiniGames: unlockedMiniGames ?? this.unlockedMiniGames,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'currentLevel': currentLevel,
      'coins': coins,
      'gems': gems,
      'hints': hints,
      'playerLevel': playerLevel,
      'xp': xp,
      'streak': streak,
      'bestStreak': bestStreak,
      'lastPlayed': lastPlayed?.toIso8601String(),
      'lastDailyPuzzleDate': lastDailyPuzzleDate?.toIso8601String(),
      'completedDailyToday': completedDailyToday,
      'hintsUsed': hintsUsed,
      'wordsFound': wordsFound,
      'bonusWordsFound': bonusWordsFound,
      'hardWordsFound': hardWordsFound,
      'perfectLevels': perfectLevels,
      'riddlesCompleted': riddlesCompleted,
      'crosswordsCompleted': crosswordsCompleted,
      'discoveredVocabulary': discoveredVocabulary,
      'unlockedThemes': unlockedThemes,
      'unlockedAchievements': unlockedAchievements,
      'miniGameLevels': miniGameLevels,
      'unlockedMiniGames': unlockedMiniGames,
    };
  }

  factory UserData.fromMap(Map<String, dynamic> map) {
    return UserData(
      currentLevel: map['currentLevel'] ?? 1,
      coins: map['coins'] ?? 500,
      gems: map['gems'] ?? 50,
      hints: map['hints'] ?? 3,
      playerLevel: map['playerLevel'] ?? 1,
      xp: map['xp'] ?? 0,
      streak: map['streak'] ?? 0,
      bestStreak: map['bestStreak'] ?? 0,
      lastPlayed: map['lastPlayed'] != null ? DateTime.tryParse(map['lastPlayed']) : null,
      lastDailyPuzzleDate: map['lastDailyPuzzleDate'] != null ? DateTime.tryParse(map['lastDailyPuzzleDate']) : null,
      completedDailyToday: map['completedDailyToday'] ?? false,
      hintsUsed: map['hintsUsed'] ?? 0,
      wordsFound: map['wordsFound'] ?? 0,
      bonusWordsFound: map['bonusWordsFound'] ?? 0,
      hardWordsFound: map['hardWordsFound'] ?? 0,
      perfectLevels: map['perfectLevels'] ?? 0,
      riddlesCompleted: map['riddlesCompleted'] ?? 0,
      crosswordsCompleted: map['crosswordsCompleted'] ?? 0,
      discoveredVocabulary: List<String>.from(map['discoveredVocabulary'] ?? []),
      unlockedThemes: List<String>.from(map['unlockedThemes'] ?? ['Spring']),
      unlockedAchievements: List<String>.from(map['unlockedAchievements'] ?? []),
      miniGameLevels: map['miniGameLevels'] != null ? Map<String, int>.from(map['miniGameLevels']) : {
        'word_wheel': 1,
        'mini_crossword': 1,
        'word_riddle': 1,
        'word_search': 1,
      },
      unlockedMiniGames: List<String>.from(map['unlockedMiniGames'] ?? ['word_wheel']),
    );
  }

  String toJson() => json.encode(toMap());

  factory UserData.fromJson(String source) => UserData.fromMap(json.decode(source));
}
