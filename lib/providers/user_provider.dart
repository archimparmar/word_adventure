import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_data.dart';
import '../models/level.dart';
import '../models/mini_game.dart';
import '../services/audio_service.dart';

class UserProvider with ChangeNotifier {
  // Development override for Arcade minigames
  static const bool developmentUnlockAllMiniGames = true;

  UserData _userData = UserData.initial();
  bool _isInitialized = false;

  UserData get userData => _userData;
  bool get isInitialized => _isInitialized;
  
  double get xpProgress {
    int requiredXp = (100 * (_userData.playerLevel * _userData.playerLevel) * 0.5 + 100).toInt();
    return (_userData.xp / requiredXp).clamp(0.0, 1.0);
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final dataString = prefs.getString('user_data');
    if (dataString != null) {
      try {
        _userData = UserData.fromJson(dataString);
        _checkStreak();
      } catch (e) {
        _userData = UserData.initial();
      }
    }
    _isInitialized = true;
    notifyListeners();
  }

  void _checkStreak() {
    if (_userData.lastPlayed == null) return;
    
    final now = DateTime.now();
    final difference = now.difference(_userData.lastPlayed!).inDays;
    
    bool isDifferentDay = now.year != _userData.lastPlayed!.year || 
                          now.month != _userData.lastPlayed!.month || 
                          now.day != _userData.lastPlayed!.day;
                          
    if (isDifferentDay) {
      _userData = _userData.copyWith(completedDailyToday: false);
    }
    
    if (difference == 1) {
      // Streak continues
    } else if (difference > 1) {
      _userData = _userData.copyWith(streak: 0); // Lost streak
    }
    _saveData();
  }
  
  void claimDailyReward() {
    final now = DateTime.now();
    if (_userData.lastPlayed != null && now.difference(_userData.lastPlayed!).inDays == 0) {
      return; // Already played today
    }
    
    int newStreak = _userData.streak + 1;
    int newBestStreak = newStreak > _userData.bestStreak ? newStreak : _userData.bestStreak;
    int reward = 50 + (newStreak * 10);
    if (reward > 250) reward = 250;
    
    _userData = _userData.copyWith(
      streak: newStreak,
      bestStreak: newBestStreak,
      lastPlayed: now,
      coins: _userData.coins + reward,
    );
    
    _saveData();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', _userData.toJson());
    notifyListeners();
  }

  void addCoins(int amount) {
    if (amount > 0) {
      AudioService().playCoinReward();
    }
    _userData = _userData.copyWith(coins: _userData.coins + amount);
    _saveData();
  }

  bool spendCoins(int amount) {
    if (_userData.coins >= amount) {
      _userData = _userData.copyWith(coins: _userData.coins - amount);
      _saveData();
      return true;
    }
    return false;
  }

  void addGems(int amount) {
    if (amount > 0) {
      AudioService().playCoinReward();
    }
    _userData = _userData.copyWith(gems: _userData.gems + amount);
    _saveData();
  }

  bool spendGems(int amount) {
    if (_userData.gems >= amount) {
      _userData = _userData.copyWith(gems: _userData.gems - amount);
      _saveData();
      return true;
    }
    return false;
  }

  void addXp(int amount) {
    int newXp = _userData.xp + amount;
    int requiredXp = (100 * (_userData.playerLevel * _userData.playerLevel) * 0.5 + 100).toInt();
    int newPlayerLevel = _userData.playerLevel;
    int coinsToAdd = 0;
    
    while (newXp >= requiredXp) {
      newXp -= requiredXp;
      newPlayerLevel++;
      requiredXp = (100 * (newPlayerLevel * newPlayerLevel) * 0.5 + 100).toInt();
      coinsToAdd += 100; // Reward for level up
    }
    
    _userData = _userData.copyWith(
      xp: newXp, 
      playerLevel: newPlayerLevel,
      coins: _userData.coins + coinsToAdd
    );
    _saveData();
  }

  void recordWordFound(bool isBonus, {bool isHard = false, String? word}) {
    int newWords = _userData.wordsFound + (isBonus ? 0 : 1);
    int newBonus = _userData.bonusWordsFound + (isBonus ? 1 : 0);
    int newHard = _userData.hardWordsFound + (isHard ? 1 : 0);
    
    _userData = _userData.copyWith(
      wordsFound: newWords,
      bonusWordsFound: newBonus,
      hardWordsFound: newHard,
    );
    addXp((isBonus ? 5 : 10) + (isHard ? 25 : 0));
  }

  void recordExtraBonusWord(String word) {
    String upper = word.trim().toUpperCase();
    if (upper.isEmpty) return;

    int newBonus = _userData.bonusWordsFound + 1;
    List<String> newVocab = List.from(_userData.discoveredVocabulary);
    if (!newVocab.contains(upper)) {
      newVocab.add(upper);
    }
    
    _userData = _userData.copyWith(
      bonusWordsFound: newBonus,
      discoveredVocabulary: newVocab,
      coins: _userData.coins + 5,
    );
    addXp(5);
    _saveData();
  }

  bool useHint(int count) {
    if (_userData.hints >= count) {
      _userData = _userData.copyWith(
        hints: _userData.hints - count,
        hintsUsed: _userData.hintsUsed + count
      );
      _saveData();
      return true;
    }
    return false;
  }

  void addHints(int count) {
    _userData = _userData.copyWith(hints: _userData.hints + count);
    _saveData();
  }

  void recordHintUsed() {
    // Deprecated. Use useHint instead.
    _userData = _userData.copyWith(hintsUsed: _userData.hintsUsed + 1);
    _saveData();
  }

  void completeLevel(Level level, {bool perfect = false}) {
    if (level.id < 0) {
      // Daily level completion
      final now = DateTime.now();
      if (_userData.lastDailyPuzzleDate != null && 
          _userData.lastDailyPuzzleDate!.year == now.year &&
          _userData.lastDailyPuzzleDate!.month == now.month &&
          _userData.lastDailyPuzzleDate!.day == now.day) {
        return; // Already completed today
      }
      
      int newStreak = _userData.streak + 1;
      int newBestStreak = newStreak > _userData.bestStreak ? newStreak : _userData.bestStreak;

      _userData = _userData.copyWith(
        completedDailyToday: true,
        lastDailyPuzzleDate: now,
        streak: newStreak,
        bestStreak: newBestStreak,
      );
      
      _processLevelRewards(level.reward, perfect);
      return;
    }

    if (level.id != _userData.currentLevel) return; // Prevent duplicate rewards for already completed levels
    
    int nextLevel = (_userData.currentLevel < 300) ? _userData.currentLevel + 1 : 300;
    int newPerfect = _userData.perfectLevels + (perfect ? 1 : 0);
    
    _userData = _userData.copyWith(
      currentLevel: nextLevel,
      perfectLevels: newPerfect,
    );
    
    _processLevelRewards(level.reward, perfect);
  }
  
  void _processLevelRewards(int baseReward, bool perfect) {
    int xpGain = baseReward * 2 + (perfect ? 50 : 0);
    int coinGain = baseReward + (perfect ? 10 : 0);
    
    int newXp = _userData.xp + xpGain;
    int requiredXp = (100 * (_userData.playerLevel * _userData.playerLevel) * 0.5 + 100).toInt();
    int newPlayerLevel = _userData.playerLevel;
    
    while (newXp >= requiredXp) {
      newXp -= requiredXp;
      newPlayerLevel++;
      requiredXp = (100 * (newPlayerLevel * newPlayerLevel) * 0.5 + 100).toInt();
      coinGain += 100; // Level up reward
    }
    
    _userData = _userData.copyWith(
      xp: newXp,
      playerLevel: newPlayerLevel,
      coins: _userData.coins + coinGain,
    );
    _saveData();
  }
  
  void recordMiniGameCompleted(String type, int reward) {
    if (type == 'riddle') {
      _userData = _userData.copyWith(riddlesCompleted: _userData.riddlesCompleted + 1);
    } else if (type == 'crossword') {
      _userData = _userData.copyWith(crosswordsCompleted: _userData.crosswordsCompleted + 1);
    }
    _processLevelRewards(reward, false); // Mini-games don't have perfect bonus logic yet, but use the same engine
  }

  bool isGameUnlocked(MiniGame game) {
    if (developmentUnlockAllMiniGames) return true;
    
    if (game.unlockType == UnlockType.level) {
      return _userData.currentLevel >= game.unlockValue;
    } else if (game.unlockType == UnlockType.coins) {
      return _userData.unlockedMiniGames.contains(game.id);
    }
    return false;
  }

  bool unlockGame(MiniGame game) {
    if (game.unlockType != UnlockType.coins) return false;
    if (_userData.coins < game.unlockValue) return false;
    
    _userData = _userData.copyWith(
      coins: _userData.coins - game.unlockValue,
      unlockedMiniGames: [..._userData.unlockedMiniGames, game.id],
    );
    _saveData();
    return true;
  }

  void progressMiniGame(String gameId, {int? completedLevel}) {
    final key = (gameId == 'riddle') ? 'word_riddle' : gameId;
    int currentSaved = _userData.miniGameLevels[key] ?? _userData.miniGameLevels[gameId] ?? 1;
    int nextLevel = (completedLevel != null) ? (completedLevel + 1) : (currentSaved + 1);

    if (nextLevel > 50) nextLevel = 50;

    if (nextLevel > currentSaved || !_userData.miniGameLevels.containsKey(key)) {
      Map<String, int> levels = Map.from(_userData.miniGameLevels);
      levels[key] = nextLevel;
      if (key == 'word_riddle' || gameId == 'riddle') {
        levels['word_riddle'] = nextLevel;
        levels['riddle'] = nextLevel;
      }
      _userData = _userData.copyWith(miniGameLevels: levels);
      _saveData();
    }
  }


  // ── COIN ADS & DAILY REWARD COOLDOWN ──────────────────────────────────────
  int _coinAdsWatchedToday = 0;
  DateTime? _lastCoinAdTime;
  static const int maxCoinAdsPerDay = 5;
  static const Duration coinAdCooldown = Duration(seconds: 30);

  int get remainingCoinAdsToday {
    _refreshCoinAdLimits();
    return (maxCoinAdsPerDay - _coinAdsWatchedToday).clamp(0, maxCoinAdsPerDay);
  }

  bool get canWatchCoinAd {
    _refreshCoinAdLimits();
    if (_coinAdsWatchedToday >= maxCoinAdsPerDay) return false;
    if (_lastCoinAdTime != null &&
        DateTime.now().difference(_lastCoinAdTime!) < coinAdCooldown) {
      return false;
    }
    return true;
  }

  int get secondsUntilNextCoinAd {
    if (_lastCoinAdTime == null) return 0;
    final diff = DateTime.now().difference(_lastCoinAdTime!);
    if (diff >= coinAdCooldown) return 0;
    return coinAdCooldown.inSeconds - diff.inSeconds;
  }

  void recordCoinAdWatched() {
    _refreshCoinAdLimits();
    _coinAdsWatchedToday++;
    _lastCoinAdTime = DateTime.now();
    _saveCoinAdState();
    addCoins(100);
  }

  Future<void> _refreshCoinAdLimits() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDateStr = prefs.getString('last_coin_ad_date');
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    if (lastDateStr != todayStr) {
      _coinAdsWatchedToday = 0;
      await prefs.setString('last_coin_ad_date', todayStr);
      await prefs.setInt('coin_ads_watched_today', 0);
    } else {
      _coinAdsWatchedToday = prefs.getInt('coin_ads_watched_today') ?? 0;
    }
  }

  Future<void> _saveCoinAdState() async {
    final prefs = await SharedPreferences.getInstance();
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    await prefs.setString('last_coin_ad_date', todayStr);
    await prefs.setInt('coin_ads_watched_today', _coinAdsWatchedToday);
  }
}


