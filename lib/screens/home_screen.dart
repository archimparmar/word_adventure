import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/game_provider.dart';
import '../utils/theme.dart';
import '../utils/game_assets.dart';
import '../widgets/game_button.dart';
import '../widgets/responsive_screen.dart';
import 'game_screen.dart';
import 'profile_screen.dart';
import 'shop_screen.dart';
import 'mini_crossword_screen.dart';
import 'riddle_screen.dart';
import 'word_search_screen.dart';
import 'loading_screen.dart';
import '../services/level_service.dart';
import '../services/ad_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  bool _isArcadeExpanded = false;
  late AnimationController _animController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _expandAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggleArcade() {
    setState(() {
      _isArcadeExpanded = !_isArcadeExpanded;
      if (_isArcadeExpanded) {
        _animController.forward();
      } else {
        _animController.reverse();
      }
    });
  }

  void _closeArcade() {
    if (_isArcadeExpanded) {
      setState(() {
        _isArcadeExpanded = false;
        _animController.reverse();
      });
    }
  }

  void _openMiniGame(Widget Function() targetBuilder, String title) {
    _closeArcade();
    LoadingScreen.open(
      context,
      targetBuilder: targetBuilder,
      title: title,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, user, child) {
        final currentLevel = user.userData.currentLevel;
        final currentTheme = WorldTheme.getTheme(currentLevel);

        return ResponsiveScreen(
          backgroundAsset: GameAssets.globalBackground,
          hasBottomNav: false,
          bottomBar: const AdBannerBar(),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = MediaQuery.of(context).size.width;
              final screenHeight = constraints.maxHeight;

              final isSmall = screenWidth < 350 || screenHeight < 620;

              double avatarSize = isSmall ? 48.0 : 58.0;
              double pillHeight = isSmall ? 38.0 : 42.0;
              double logoWidth = isSmall ? 155.0 : 205.0;
              double landmarkHeight = isSmall ? 75.0 : 105.0;
              double playWidth = isSmall ? 195.0 : 235.0;
              double playHeight = isSmall ? 48.0 : 54.0;
              double dailyWidth = isSmall ? 175.0 : 205.0;
              double dailyHeight = isSmall ? 38.0 : 42.0;
              double sideBtnSize = isSmall ? 56.0 : 66.0;
              double miniGameIconSize = isSmall ? 52.0 : 62.0;

              return Stack(
                children: [
                  // Main Content Area (Header, Center Content)
                  Positioned.fill(
                    child: Column(
                      children: [
                        // 1. TOP HUD (Profile Avatar & Coins/Gems HUD)
                        _buildTopHUD(context, user, avatarSize, pillHeight, isSmall),

                        // 2. CENTER CONTENT (Logo, Landmark, World Plaque, Play CTA, Daily CTA)
                        Expanded(
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  SizedBox(height: isSmall ? 2 : 6),

                                  // Word Adventure Logo Banner
                                  Container(
                                    decoration: BoxDecoration(
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.35),
                                          blurRadius: 16,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: Image.asset(
                                      GameAssets.homeLogo,
                                      width: logoWidth,
                                      fit: BoxFit.contain,
                                    ),
                                  ),

                                  SizedBox(height: isSmall ? 6 : 10),

                                  // Current World Landmark Image
                                  Image.asset(
                                    currentTheme.landmarkPath,
                                    height: landmarkHeight,
                                    fit: BoxFit.contain,
                                    errorBuilder: (c, e, s) => SizedBox(height: landmarkHeight),
                                  ),

                                  SizedBox(height: isSmall ? 8 : 12),

                                  // Redesigned World & Level Adventure Plaque
                                  _buildWorldInfoCard(currentTheme, currentLevel, isSmall),

                                  SizedBox(height: isSmall ? 12 : 16),

                                  // Primary PLAY / CONTINUE CTA
                                  _buildPlayCTA(context, currentLevel, playWidth, playHeight, isSmall),

                                  SizedBox(height: isSmall ? 8 : 10),

                                  // Secondary DAILY ADVENTURE CTA
                                  _buildDailyCTA(context, dailyWidth, dailyHeight, isSmall),

                                  SizedBox(height: isSmall ? 6 : 12),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 3. FLOATING RIGHT SIDE BUTTON: SHOP
                  Positioned(
                    right: isSmall ? 0 : 4,
                    bottom: isSmall ? 0 : 4,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        _closeArcade();
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ShopScreen()),
                        );
                      },
                      child: SizedBox(
                        width: sideBtnSize,
                        height: sideBtnSize,
                        child: Center(
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFFD21C).withValues(alpha: 0.25),
                                  blurRadius: 12,
                                  spreadRadius: 1,
                                ),
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Image.asset(
                              GameAssets.shopIcon,
                              width: sideBtnSize * 0.88,
                              height: sideBtnSize * 0.88,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 4. FLOATING LEFT SIDE BUTTON: EXPANDABLE ARCADE MENU
                  Positioned(
                    left: isSmall ? 0 : 4,
                    bottom: isSmall ? 0 : 4,
                    child: SizedBox(
                      width: sideBtnSize + (isSmall ? 76.0 : 90.0),
                      height: sideBtnSize + (isSmall ? 76.0 : 90.0),
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.bottomLeft,
                        children: [
                          // Arc Mini-Game 1: directly UP (Mini Crossword)
                          Positioned(
                            bottom: isSmall ? 76.0 : 90.0,
                            left: (sideBtnSize - (miniGameIconSize * 0.85)) / 2,
                            child: IgnorePointer(
                              ignoring: !_isArcadeExpanded,
                              child: FadeTransition(
                                opacity: _expandAnimation,
                                child: ScaleTransition(
                                  scale: _expandAnimation,
                                  alignment: Alignment.bottomLeft,
                                  child: _buildMiniGameIcon(
                                    iconAsset: GameAssets.crosswordIcon,
                                    size: miniGameIconSize,
                                    onTap: () {
                                      final lvl = user.userData.miniGameLevels['mini_crossword'] ?? 1;
                                      _openMiniGame(() => MiniCrosswordScreen(levelId: lvl), 'LOADING MINI CROSSWORD...');
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Arc Mini-Game 2: UP + RIGHT diagonally (Word Riddles)
                          Positioned(
                            bottom: isSmall ? 54.0 : 64.0,
                            left: isSmall ? 54.0 : 64.0,
                            child: IgnorePointer(
                              ignoring: !_isArcadeExpanded,
                              child: FadeTransition(
                                opacity: _expandAnimation,
                                child: ScaleTransition(
                                  scale: _expandAnimation,
                                  alignment: Alignment.bottomLeft,
                                  child: _buildMiniGameIcon(
                                    iconAsset: GameAssets.riddleIcon,
                                    size: miniGameIconSize,
                                    onTap: () {
                                      final lvl = user.userData.miniGameLevels['word_riddle'] ?? 1;
                                      _openMiniGame(() => RiddleScreen(levelId: lvl), 'LOADING WORD RIDDLE...');
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Arc Mini-Game 3: directly RIGHT (Word Search)
                          Positioned(
                            bottom: (sideBtnSize - (miniGameIconSize * 0.85)) / 2,
                            left: isSmall ? 76.0 : 90.0,
                            child: IgnorePointer(
                              ignoring: !_isArcadeExpanded,
                              child: FadeTransition(
                                opacity: _expandAnimation,
                                child: ScaleTransition(
                                  scale: _expandAnimation,
                                  alignment: Alignment.bottomLeft,
                                  child: _buildMiniGameIcon(
                                    iconAsset: GameAssets.wordSearchIcon,
                                    size: miniGameIconSize,
                                    onTap: () {
                                      final lvl = user.userData.miniGameLevels['word_search'] ?? 1;
                                      _openMiniGame(() => WordSearchScreen(levelId: lvl), 'LOADING WORD SEARCH...');
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Arcade Toggle / X Close Button
                          Positioned(
                            bottom: 0,
                            left: 0,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: _toggleArcade,
                              child: SizedBox(
                                width: sideBtnSize,
                                height: sideBtnSize,
                                child: Center(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFFFD21C).withValues(alpha: 0.25),
                                          blurRadius: 12,
                                          spreadRadius: 1,
                                        ),
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.4),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: _isArcadeExpanded
                                        ? Container(
                                            width: sideBtnSize * 0.86,
                                            height: sideBtnSize * 0.86,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: const Color(0xFF0F1932).withValues(alpha: 0.95),
                                              border: Border.all(
                                                color: const Color(0xFFFFD21C),
                                                width: 2.0,
                                              ),
                                            ),
                                            child: const Icon(
                                              Icons.close_rounded,
                                              color: Color(0xFFFFD21C),
                                              size: 26,
                                            ),
                                          )
                                        : Image.asset(
                                            GameAssets.arcadeIcon,
                                            width: sideBtnSize * 0.88,
                                            height: sideBtnSize * 0.88,
                                            fit: BoxFit.contain,
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildMiniGameIcon({
    required String iconAsset,
    required double size,
    required VoidCallback onTap,
  }) {
    final scaledSize = size * 0.85;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: size,
        height: scaledSize,
        child: Center(
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Image.asset(
              iconAsset,
              width: scaledSize,
              height: scaledSize,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }

  // ── 1. TOP HUD (Profile Avatar & Coins/Gems HUD) ──────────────────────────
  Widget _buildTopHUD(BuildContext context, UserProvider user, double avatarSize, double pillHeight, bool isSmall) {
    return Padding(
      padding: const EdgeInsets.only(top: 2.0, left: 4.0, right: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Profile Avatar Frame Button
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              _closeArcade();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
            child: Image.asset(
              GameAssets.defaultAvatar,
              width: avatarSize,
              height: avatarSize,
              fit: BoxFit.contain,
            ),
          ),

          // Coins & Gems Unified HUD Plaque
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              _closeArcade();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ShopScreen()),
              );
            },
            child: Container(
              height: pillHeight,
              padding: EdgeInsets.symmetric(
                horizontal: isSmall ? 10 : 14,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1830).withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(pillHeight / 2),
                border: Border.all(
                  color: const Color(0xFFFFD21C),
                  width: 1.6,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD21C).withValues(alpha: 0.2),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Coins counter
                  Image.asset(GameAssets.coin, width: isSmall ? 17 : 20, height: isSmall ? 17 : 20),
                  const SizedBox(width: 5),
                  Text(
                    '${user.userData.coins}',
                    style: TextStyle(
                      fontFamily: AppTheme.worldTitle.fontFamily,
                      fontWeight: FontWeight.w900,
                      fontSize: isSmall ? 12.5 : 14.0,
                      color: const Color(0xFFFFD21C),
                      shadows: const [
                        Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(0, 1)),
                      ],
                    ),
                  ),

                  // Divider
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 1.2,
                    height: pillHeight * 0.5,
                    color: const Color(0xFFFFD21C).withValues(alpha: 0.35),
                  ),

                  // Gems counter
                  Image.asset(
                    GameAssets.xpGem,
                    width: isSmall ? 16 : 18,
                    height: isSmall ? 16 : 18,
                    errorBuilder: (c, e, s) => Icon(Icons.diamond_rounded, color: const Color(0xFF29B6F6), size: isSmall ? 15 : 17),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${user.userData.gems}',
                    style: TextStyle(
                      fontFamily: AppTheme.worldTitle.fontFamily,
                      fontWeight: FontWeight.w900,
                      fontSize: isSmall ? 12.5 : 14.0,
                      color: const Color(0xFF29B6F6),
                      shadows: const [
                        Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(0, 1)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 2. WORLD & LEVEL ADVENTURE PLAQUE ─────────────────────────────────────
  Widget _buildWorldInfoCard(WorldTheme theme, int currentLevel, bool isSmall) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 20 : 28,
        vertical: isSmall ? 10 : 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1A30).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFFD21C),
          width: 1.8,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD21C).withValues(alpha: 0.20),
            blurRadius: 14,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // World Title (Primary text)
          Text(
            theme.name.toUpperCase(),
            style: AppTheme.worldTitle.copyWith(
              fontSize: isSmall ? 15.5 : 18.5,
              letterSpacing: 2.0,
              color: const Color(0xFFFFD21C),
              shadows: const [
                Shadow(color: Colors.black, blurRadius: 8, offset: Offset(0, 2)),
              ],
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 5),

          // Level Badge (Secondary text)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isSmall ? 12 : 16,
              vertical: isSmall ? 2 : 4,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF162544),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF29B6F6).withValues(alpha: 0.6),
                width: 1.2,
              ),
            ),
            child: Text(
              'LEVEL $currentLevel',
              style: TextStyle(
                fontFamily: AppTheme.body.fontFamily,
                fontWeight: FontWeight.w900,
                fontSize: isSmall ? 11.5 : 13.0,
                letterSpacing: 1.4,
                color: const Color(0xFF29B6F6),
                shadows: const [
                  Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(0, 1)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 3. PRIMARY PLAY / CONTINUE CTA ───────────────────────────────────────
  Widget _buildPlayCTA(BuildContext context, int currentLevel, double width, double height, bool isSmall) {
    return GameButton(
      width: width,
      height: height,
      baseColor: const Color(0xFF27AE60),
      shadowColor: const Color(0xFF196F3D),
      onPressed: () {
        _closeArcade();
        LoadingScreen.open(
          context,
          targetBuilder: () => ChangeNotifierProvider(
            create: (_) => GameProvider(currentLevel),
            child: const GameScreen(),
          ),
          title: 'LOADING GAMEPLAY...',
        );
      },
      child: Text(
        currentLevel == 1 ? 'PLAY' : 'CONTINUE',
        style: TextStyle(
          fontFamily: AppTheme.body.fontFamily,
          fontWeight: FontWeight.w900,
          fontSize: isSmall ? 16.0 : 19.0,
          color: Colors.white,
          letterSpacing: 2.0,
          shadows: const [
            Shadow(color: Colors.black87, blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
      ),
    );
  }

  // ── 4. SECONDARY DAILY ADVENTURE CTA ──────────────────────────────────────
  Widget _buildDailyCTA(BuildContext context, double width, double height, bool isSmall) {
    return GameButton(
      width: width,
      height: height,
      baseColor: const Color(0xFF0F1C36),
      shadowColor: const Color(0xFF070E1E),
      onPressed: () {
        _closeArcade();
        final dailyLevel = LevelService.getDailyLevel(DateTime.now());
        LoadingScreen.open(
          context,
          targetBuilder: () => ChangeNotifierProvider(
            create: (_) => GameProvider(dailyLevel.id),
            child: const GameScreen(),
          ),
          title: 'LOADING DAILY ADVENTURE...',
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            GameAssets.dailyStreakFire,
            width: isSmall ? 15 : 18,
            height: isSmall ? 15 : 18,
            errorBuilder: (c, e, s) => Icon(Icons.local_fire_department, color: Colors.orange, size: isSmall ? 15 : 18),
          ),
          const SizedBox(width: 6),
          Text(
            'DAILY ADVENTURE',
            style: TextStyle(
              fontFamily: AppTheme.body.fontFamily,
              fontWeight: FontWeight.w900,
              fontSize: isSmall ? 11.0 : 12.5,
              color: const Color(0xFFFFD21C),
              letterSpacing: 1.2,
              shadows: const [
                Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(0, 1)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
