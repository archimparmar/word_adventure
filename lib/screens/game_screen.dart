import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'dart:async';
import '../providers/game_provider.dart';
import '../providers/user_provider.dart';
import '../utils/theme.dart';
import '../utils/game_assets.dart';
import '../widgets/puzzle_board.dart';
import '../widgets/letter_wheel.dart';
import '../widgets/vocabulary_modal.dart';
import '../widgets/hint_purchase_dialog.dart';
import 'completion_screen.dart';
import '../services/audio_service.dart';
import '../services/ad_service.dart';
import '../widgets/game_tutorial.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => GameScreenState();
}

class GameScreenState extends State<GameScreen> {
  String? _transientFeedbackMessage;
  Color? _transientFeedbackColor;
  Timer? _feedbackTimer;
  bool _isNavigatingToCompletion = false;

  @override
  void initState() {
    super.initState();
    // Music is managed at app-level (main.dart) — no action needed here
  }

  @override
  void dispose() {
    _feedbackTimer?.cancel();
    // Do NOT stop music here — Home screen owns the music lifecycle
    super.dispose();
  }

  void handleSubmissionResult(String word, SubmissionResult result) {
    _feedbackTimer?.cancel();

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final gameProvider = Provider.of<GameProvider>(context, listen: false);

    String msg;
    Color col;

    switch (result) {
      case SubmissionResult.validRequired:
        userProvider.recordWordFound(false);
        msg = 'GREAT!';
        col = const Color(0xFF1B9954);
        break;
      case SubmissionResult.validBonus:
        if (!gameProvider.currentLevel.requiredWords.contains(word) &&
            gameProvider.currentLevel.hardWord != word &&
            !gameProvider.currentLevel.bonusWords.contains(word)) {
          userProvider.recordExtraBonusWord(word);
        } else {
          userProvider.recordWordFound(true);
        }
        msg = 'BONUS WORD! +5 🪙';
        col = AppTheme.success;
        break;
      case SubmissionResult.validHard:
        userProvider.recordWordFound(true, isHard: true);
        msg = '✨ HARD WORD! +25 🪙';
        col = AppTheme.coral;
        break;
      case SubmissionResult.alreadyFound:
        msg = 'ALREADY FOUND';
        col = const Color(0xFFF59E0B);
        break;
      case SubmissionResult.invalid:
        msg = 'TRY AGAIN';
        col = const Color(0xFFEF4444);
        break;
    }

    setState(() {
      _transientFeedbackMessage = msg;
      _transientFeedbackColor = col;
    });

    _feedbackTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _transientFeedbackMessage = null;
          _transientFeedbackColor = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, provider, child) {
        if (provider.isLevelComplete && !_isNavigatingToCompletion) {
          _isNavigatingToCompletion = true;
          final level = provider.currentLevel;
          final perfect = provider.isPerfect();
          final navigator = Navigator.of(context);
          Future.delayed(const Duration(milliseconds: 700), () {
            if (!mounted) return;
            navigator.pushReplacement(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => CompletionScreen(
                  level: level,
                  perfect: perfect,
                  isDaily: level.id < 0,
                  bonusCount: provider.foundBonusWords.length,
                ),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: animation,
                    child: child,
                  );
                },
                transitionDuration: const Duration(milliseconds: 600),
              ),
            );
          });
        }

        final currentTheme = provider.currentLevel.id < 0
            ? WorldTheme.worlds[0]
            : WorldTheme.getTheme(provider.currentLevel.id);

        return Scaffold(
          extendBody: true,
          bottomNavigationBar: const AdBannerBar(),
          body: Stack(
            children: [
              // Dynamic World Environment Background
              Positioned.fill(
                child: Image.asset(
                  currentTheme.backgroundPath,
                  fit: BoxFit.cover,
                ),
              ),
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final screenWidth = MediaQuery.of(context).size.width;
                    final availableH = constraints.maxHeight;
                    final isSmall = screenWidth < 350 || availableH < 620;

                    // Responsive Proportional Heights
                    final double hudHeight = isSmall ? 46.0 : 54.0;
                    final double bottomBarHeight = isSmall ? 52.0 : 60.0;
                    final double iconSize = isSmall ? 38.0 : 46.0;
                    final double feedbackFontSize = isSmall ? 16.0 : 20.0;
                    const double subBoardBarHeight = 30.0;
                    final double topBoardMargin = isSmall ? 10.0 : 16.0;
                    const double gapHeight = 6.0;
                    const double totalGaps = gapHeight * 4;
                    const double safetyCushion = 8.0;

                    // Exact remaining height budget for Board and Wheel
                    final double remainingContentH = math.max(
                      100.0,
                      availableH - (hudHeight + topBoardMargin + bottomBarHeight + subBoardBarHeight + totalGaps + safetyCushion),
                    );

                    final double boardMaxH = remainingContentH * 0.54;
                    final double wheelMaxH = math.min(remainingContentH * 0.46, screenWidth * 0.72);
                    final double vocabBtnSize = isSmall ? 44.0 : 50.0;

                    // Compute layout params for tutorial spotlight positions
                    final tutorialParams = GameLayoutParams.compute(
                      screenWidth,
                      availableH,
                    );

                    return GameTutorialOverlay(
                      params: tutorialParams,
                      child: Stack(
                        children: [
                        // Main Vertical Content Column
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            // 1. TOP HUD (Back Button Left, Centered Light Brown Level Plaque, Coins Right)
                            SizedBox(
                              height: hudHeight,
                              child: _buildTopHUD(context, provider, currentTheme, iconSize),
                            ),

                            // Board position shifted slightly lower down
                            SizedBox(height: topBoardMargin),

                            // 2. EXISTING WORD BOARD (Upper-Middle Main Focus)
                            SizedBox(
                              height: boardMaxH,
                              width: screenWidth,
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: PuzzleBoard(),
                              ),
                            ),
                            const SizedBox(height: gapHeight + 2),

                            // 3. WORD FEEDBACK TEXT (Shown when dragging/submitted; empty when idle)
                            SizedBox(
                              height: subBoardBarHeight,
                              child: _buildWordFeedback(provider, feedbackFontSize),
                            ),
                            const SizedBox(height: gapHeight + 2),

                            // 4. LETTER WHEEL
                            SizedBox(
                              height: wheelMaxH,
                              width: screenWidth,
                              child: const LetterWheel(),
                            ),
                            const SizedBox(height: gapHeight),

                            // 5. BOTTOM CONTROLS (Thick Orange-Gold Circular Hint & Shuffle)
                            SizedBox(
                              height: bottomBarHeight,
                              child: _buildBottomControls(context, provider, iconSize),
                            ),
                          ],
                        ),

                        // Floating Vocab Button (Right side, slightly lower down, bigger size)
                        Positioned(
                          right: isSmall ? 10.0 : 16.0,
                          top: hudHeight + topBoardMargin + boardMaxH + 4.0,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (_) => const VocabularyModal(),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                  ),
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.45),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Image.asset(
                                GameAssets.vocabIcon,
                                width: vocabBtnSize,
                                height: vocabBtnSize,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ), // end child Stack
                    ); // end GameTutorialOverlay
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── 1. TOP HUD (Centered Light Brown Plaque & Coins Only) ──────────────────
  Widget _buildTopHUD(BuildContext context, GameProvider provider, WorldTheme theme, double buttonSize) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: EdgeInsets.only(
        left: screenWidth < 340 ? 10.0 : 16.0,
        right: screenWidth < 340 ? 10.0 : 16.0,
        top: 2,
        bottom: 2,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Back Button (Left)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (_isNavigatingToCompletion) return;
              provider.clearSelection();
              Navigator.pop(context);
            },
            child: Image.asset(
              GameAssets.backButton,
              width: buttonSize,
              height: buttonSize,
              fit: BoxFit.contain,
            ),
          ),

          // Centered Level Text (Vertically & Horizontally Aligned)
          Text(
            provider.currentLevel.id < 0 ? 'DAILY' : 'LEVEL ${provider.currentLevel.id}',
            style: AppTheme.worldTitle.copyWith(
              fontSize: screenWidth < 340 ? 15.0 : 18.0,
              letterSpacing: 1.6,
              color: const Color(0xFFFFD21C),
              fontWeight: FontWeight.w900,
              shadows: const [
                Shadow(color: Colors.black, blurRadius: 12, offset: Offset(0, 3)),
                Shadow(color: Colors.black, blurRadius: 6, offset: Offset(0, 2)),
                Shadow(color: Colors.black87, blurRadius: 2, offset: Offset(0, 1)),
              ],
            ),
          ),

          // Coins Inventory Badge Only (Right side)
          Consumer<UserProvider>(
            builder: (context, user, child) {
              return Container(
                height: 34,
                padding: EdgeInsets.symmetric(horizontal: screenWidth < 340 ? 8 : 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1830).withValues(alpha: 0.90),
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.80),
                    width: 1.5,
                  ),
                  boxShadow: const [
                    BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 2)),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(GameAssets.coin, width: 18, height: 18, fit: BoxFit.contain),
                    const SizedBox(width: 5),
                    Text(
                      '${user.userData.coins}',
                      style: TextStyle(
                        fontFamily: AppTheme.worldTitle.fontFamily,
                        color: const Color(0xFFFFD21C),
                        fontWeight: FontWeight.w900,
                        fontSize: screenWidth < 340 ? 13.0 : 14.0,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── 3. WORD FEEDBACK TEXT (Only shows when dragging/submitting; empty when idle)
  Widget _buildWordFeedback(GameProvider provider, double fontSize) {
    String? textToDisplay;
    Color textColor = Colors.white;

    if (_transientFeedbackMessage != null) {
      textToDisplay = _transientFeedbackMessage!;
      textColor = _transientFeedbackColor ?? Colors.white;
    } else if (provider.currentWord.isNotEmpty) {
      textToDisplay = provider.currentWord;
      textColor = Colors.white;
    } else if (provider.isLevelComplete) {
      textToDisplay = 'LEVEL COMPLETE!';
      textColor = const Color(0xFFF59E0B);
    } else {
      textToDisplay = null; // Removed "MAKE A WORD" text when idle
    }

    if (textToDisplay == null) {
      return const SizedBox();
    }

    return Center(
      child: Text(
        textToDisplay,
        style: AppTheme.worldTitle.copyWith(
          fontSize: fontSize + 2.0,
          letterSpacing: 3.2,
          fontWeight: FontWeight.w900,
          color: textColor,
          shadows: const [
            Shadow(color: Colors.black, blurRadius: 8, offset: Offset(0, 3)),
            Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(0, 1)),
          ],
        ),
      ),
    );
  }

  // ── 5. BOTTOM CONTROLS (Thick Orange-Gold Circle Hint & Shuffle) ───────────
  Widget _buildBottomControls(BuildContext context, GameProvider provider, double buttonSize) {
    final double circleSize = math.max(48.0, buttonSize + 6.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Hint Circular Button
          _buildHintButton(context, provider, circleSize),

          // Right: Shuffle Circular Button
          _buildCircularButton(
            child: Image.asset(
              GameAssets.shuffleIcon,
              width: circleSize * 0.62,
              height: circleSize * 0.62,
              fit: BoxFit.contain,
            ),
            circleSize: circleSize,
            onTap: () {
              AudioService().playShuffle();
              provider.shuffle();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCircularButton({
    required Widget child,
    required double circleSize,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: circleSize,
        height: circleSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF0D1830).withValues(alpha: 0.92),
          border: Border.all(
            color: const Color(0xFFF59E0B), // Orange-gold border shade
            width: 2.8, // Thicker border
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
              blurRadius: 10,
              spreadRadius: 1,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }

  Widget _buildHintButton(BuildContext context, GameProvider provider, double circleSize) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        int hintsAvailable = userProvider.userData.hints;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            _buildCircularButton(
              child: Image.asset(
                GameAssets.hintBulb,
                width: circleSize * 0.62, // Larger icon inside circle
                height: circleSize * 0.62,
                fit: BoxFit.contain,
              ),
              circleSize: circleSize,
              onTap: () => _onHintTap(context, userProvider, provider),
            ),
            if (hintsAvailable > 0)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: AppTheme.coral,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                    boxShadow: const [
                      BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Text(
                    '$hintsAvailable',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _onHintTap(BuildContext context, UserProvider userProvider, GameProvider provider) {
    int hintsAvailable = userProvider.userData.hints;

    if (hintsAvailable > 0) {
      int remainingCells = _getRemainingUnrevealedCells(provider);
      if (remainingCells <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All required word letters are already revealed!'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      if (userProvider.useHint(1)) {
        AudioService().playHintUsed();
        provider.useHint();
      }
    } else {
      showDialog(
        context: context,
        builder: (_) => const HintPurchaseDialog(),
      );
    }
  }

  int _getRemainingUnrevealedCells(GameProvider provider) {
    int count = 0;
    for (String word in provider.currentLevel.requiredWords) {
      if (!provider.foundWords.contains(word)) {
        for (int i = 0; i < word.length; i++) {
          String cellKey = '${word}_$i';
          if (!provider.hintedCells.contains(cellKey)) {
            count++;
          }
        }
      }
    }
    return count;
  }
}