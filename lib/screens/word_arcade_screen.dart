import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../data/mini_game_data.dart';
import '../utils/theme.dart';
import '../utils/game_assets.dart';
import '../widgets/game_button.dart';
import '../widgets/responsive_screen.dart';
import 'mini_crossword_screen.dart';
import 'riddle_screen.dart';
import 'word_search_screen.dart';
import 'loading_screen.dart';

class WordArcadeScreen extends StatefulWidget {
  const WordArcadeScreen({super.key});

  @override
  State<WordArcadeScreen> createState() => _WordArcadeScreenState();
}

class _WordArcadeScreenState extends State<WordArcadeScreen> {
  @override
  void initState() {
    super.initState();
    if (!MiniGameData.isLoaded) {
      MiniGameData.loadDatasets().then((_) {
        if (mounted) setState(() {});
      });
    }
  }

  static const List<_ArcadeGameConfig> _games = [
    _ArcadeGameConfig(
      id: 'mini_crossword',
      name: 'MINI CROSSWORD',
      description: 'Solve the crossword',
      iconAsset: GameAssets.crosswordIcon,
      accentColor: Color(0xFF25D978),
      shadowColor: Color(0xFF1B9954),
    ),
    _ArcadeGameConfig(
      id: 'word_riddle',
      name: 'WORD RIDDLES',
      description: 'Solve the riddle',
      iconAsset: GameAssets.riddleIcon,
      accentColor: Color(0xFFE040FB),
      shadowColor: Color(0xFF9C27B0),
    ),
    _ArcadeGameConfig(
      id: 'word_search',
      name: 'WORD SEARCH',
      description: 'Find hidden words',
      iconAsset: GameAssets.wordSearchIcon,
      accentColor: Color(0xFF00E5FF),
      shadowColor: Color(0xFF0097A7),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, user, child) {
        return ResponsiveScreen(
          backgroundAsset: GameAssets.arcadeBackground,
          hasBottomNav: true,
          blurBackground: true,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final h = constraints.maxHeight;
              final isSmall = w < 340 || h < 550;

              return Column(
                children: [
                  // ── 1. HEADER BAR ────────────────────────────────────
                  SizedBox(
                    height: isSmall ? 38.0 : 46.0,
                    child: _buildHeader(user, isSmall),
                  ),

                  // ── 2. 3-ROW BALANCED GAME MENU LIST ─────────────────
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: _games.map((cfg) {
                          return _buildGameRow(context, user, cfg, w, isSmall);
                        }).toList(),
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

  Widget _buildHeader(UserProvider user, bool isSmall) {
    final titleSize = isSmall ? 15.0 : 19.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            'WORD ARCADE',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.worldTitle.copyWith(
              fontSize: titleSize,
              letterSpacing: isSmall ? 1.5 : 2.5,
              color: const Color(0xFFF2C14E),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Live Coin Badge
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isSmall ? 8 : 12,
            vertical: isSmall ? 4 : 6,
          ),
          decoration: BoxDecoration(
            color: const Color(0xF7142217),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFD9A62E),
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                GameAssets.coin,
                width: isSmall ? 16 : 18,
                height: isSmall ? 16 : 18,
                fit: BoxFit.contain,
                errorBuilder: (c, e, s) =>
                    const Icon(Icons.monetization_on, color: AppTheme.gold, size: 16),
              ),
              const SizedBox(width: 6),
              Text(
                '${user.userData.coins}',
                style: TextStyle(
                  fontFamily: AppTheme.body.fontFamily,
                  color: AppTheme.gold,
                  fontWeight: FontWeight.w900,
                  fontSize: isSmall ? 12 : 13.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── 3-ROW COMPACT HORIZONTAL GAME ROW ────────────────────────────────
  Widget _buildGameRow(
    BuildContext context,
    UserProvider user,
    _ArcadeGameConfig cfg,
    double screenWidth,
    bool isSmall,
  ) {
    final int level = user.userData.miniGameLevels[cfg.id] ?? 1;

    final iconSize = isSmall ? 46.0 : 54.0;
    final titleFontSize = isSmall ? 12.5 : 14.5;
    final badgeFontSize = isSmall ? 9.5 : 10.5;
    final btnWidth = isSmall ? 72.0 : 84.0;
    final btnHeight = isSmall ? 36.0 : 40.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _navigate(context, user, cfg.id, level),
      child: Container(
        height: isSmall ? 72.0 : 84.0,
        padding: EdgeInsets.symmetric(
          horizontal: isSmall ? 10.0 : 14.0,
        ),
        decoration: BoxDecoration(
          color: const Color(0xF7142217),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFD9A62E).withValues(alpha: 0.65),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. Prominent Large Game Icon Anchor (Left)
            Image.asset(
              cfg.iconAsset,
              width: iconSize,
              height: iconSize,
              fit: BoxFit.contain,
              errorBuilder: (c, e, s) => Icon(
                Icons.extension,
                size: iconSize,
                color: const Color(0xFFD9A62E),
              ),
            ),

            SizedBox(width: isSmall ? 10 : 14),

            // 2. Center: FULL Game Name (never truncated) + LEVEL X directly underneath
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      cfg.name,
                      style: AppTheme.sectionHeading.copyWith(
                        color: Colors.white,
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Level Badge Pill
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmall ? 6 : 8,
                      vertical: isSmall ? 2 : 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF263A22),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: const Color(0xFF5B7A42),
                        width: 1.0,
                      ),
                    ),
                    child: Text(
                      'LEVEL $level',
                      style: AppTheme.smallSecondary.copyWith(
                        color: const Color(0xFFF2C14E),
                        fontWeight: FontWeight.w900,
                        fontSize: badgeFontSize,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // 3. Prominent PLAY Button (Right)
            SizedBox(
              width: btnWidth,
              height: btnHeight,
              child: GameButton(
                width: btnWidth,
                height: btnHeight,
                baseColor: cfg.accentColor,
                shadowColor: cfg.shadowColor,
                onPressed: () => _navigate(context, user, cfg.id, level),
                child: Text(
                  'PLAY',
                  style: AppTheme.smallSecondary.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: isSmall ? 11.5 : 13.0,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigate(
      BuildContext context, UserProvider user, String id, int level) {
    switch (id) {
      case 'mini_crossword':
        LoadingScreen.open(
          context,
          targetBuilder: () => MiniCrosswordScreen(levelId: level),
          title: 'LOADING MINI CROSSWORD...',
        );
        break;
      case 'word_riddle':
        LoadingScreen.open(
          context,
          targetBuilder: () => RiddleScreen(levelId: level),
          title: 'LOADING WORD RIDDLE...',
        );
        break;
      case 'word_search':
        LoadingScreen.open(
          context,
          targetBuilder: () => WordSearchScreen(levelId: level),
          title: 'LOADING WORD SEARCH...',
        );
        break;
    }
  }
}

class _ArcadeGameConfig {
  final String id;
  final String name;
  final String description;
  final String iconAsset;
  final Color accentColor;
  final Color shadowColor;

  const _ArcadeGameConfig({
    required this.id,
    required this.name,
    required this.description,
    required this.iconAsset,
    required this.accentColor,
    required this.shadowColor,
  });
}
