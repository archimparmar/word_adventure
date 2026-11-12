class GameAssets {
  static const String basePath = 'assets/images';

  // Navigation & Icons
  static const String homeIcon = '$basePath/icons/home.webp';
  static const String dailyIcon = '$basePath/daily/calendar.webp';
  static const String arcadeIcon = '$basePath/icons/arcade.webp';
  static const String shopIcon = '$basePath/icons/shop.webp';
  static const String profileIcon = '$basePath/icons/compass.webp';
  static const String backButton = '$basePath/icons/back.webp';
  static const String hintBulb = '$basePath/icons/hint.webp';
  static const String shuffleIcon = '$basePath/icons/shuffle.webp';
  static const String settingsButton = '$basePath/icons/settings.webp';
  static const String lockIcon = '$basePath/icons/lock.webp';
  static const String mapScroll = '$basePath/icons/map_scroll.webp';
  static const String vocabIcon = '$basePath/icons/vocab icon.webp';
  static const String crosswordIcon = '$basePath/icons/cross word puzzle icon.webp';
  static const String riddleIcon = '$basePath/icons/word riddle icon.webp';
  static const String wordSearchIcon = '$basePath/icons/word search icon.webp';

  // Branding
  static const String appIcon = '$basePath/branding/word_adventure_app_icon.webp';
  static const String homeLogo = '$basePath/branding/word_adventure_logo.webp';

  // Backgrounds & Boards
  static const String woodenBoard = '$basePath/boards/board_wood.webp';
  static const String crystalBoard = '$basePath/boards/board_crystal.webp';
  static const String goldBoard = '$basePath/boards/board_gold.webp';
  static const String stoneBoard = '$basePath/boards/board_stone.webp';
  static const String completionBackground = '$basePath/completion/background.webp';
  static const String arcadeBackground = '$basePath/arcade/hub_background.webp';
  static const String shopBackground = '$basePath/shop/background.webp';
  static const String profileBackground = '$basePath/profile/background.webp';
  static const String vocabularyBackground = '$basePath/vocabulary/background.webp';

  static String getBoardPathByDifficulty(dynamic difficulty) {
    if (difficulty == null) return woodenBoard;
    final str = difficulty.toString().trim();
    if (str == '1' || str == 'Easy' || str == 'Easy-Medium') {
      return woodenBoard;
    } else if (str == '2' || str == 'Medium' || str == 'Medium-Hard') {
      return crystalBoard;
    } else if (str == '3' || str == 'Hard') {
      return goldBoard;
    }
    return woodenBoard;
  }

  // Mini-Game Heroes
  static const String heroWordWheel = '$basePath/arcade/hero_word_wheel.webp';
  static const String heroCrossword = '$basePath/arcade/hero_crossword.webp';
  static const String heroRiddles = '$basePath/arcade/hero_riddles.webp';
  static const String heroWordSearch = '$basePath/arcade/hero_word_search.webp';

  // Avatars & Rewards
  static const String defaultAvatar = '$basePath/avatars/explorer.webp';
  static const String coin = '$basePath/rewards/coin.webp';
  static const String xpGem = '$basePath/rewards/xp_gem.webp';
  static const String starReward = '$basePath/rewards/star.webp';
  
  static const String dailyCalendar = '$basePath/daily/calendar.webp';
  static const String dailyStreakFire = '$basePath/daily/streak_fire.webp';
  
  static const String closedChest = '$basePath/rewards/chest_closed.webp';
  static const String openedChest = '$basePath/rewards/chest_opened.webp';
  static const String tileNormal = '$basePath/tiles/tile_normal.webp';
  static const String tileEmpty = '$basePath/tiles/tile_empty.webp';
  
  // Riddles & Objects
  static const String riddleScroll = '$basePath/arcade/riddle_scroll.webp';

  // Worlds
  static const String globalBackground = '$basePath/worlds/global_background.webp';

  static String worldBackground(int worldNumber) {
    if (worldNumber < 1) worldNumber = 1;
    if (worldNumber > 7) worldNumber = 7;
    return '$basePath/worlds/world_$worldNumber.webp';
  }
}
