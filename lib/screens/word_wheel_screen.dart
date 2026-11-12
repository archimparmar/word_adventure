import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../models/puzzle_models.dart';
import '../data/mini_game_data.dart';
import '../utils/theme.dart';
import '../utils/game_assets.dart';
import '../widgets/game_button.dart';
import '../widgets/responsive_screen.dart';

class WordWheelScreen extends StatefulWidget {
  final int levelId;
  const WordWheelScreen({super.key, required this.levelId});

  @override
  State<WordWheelScreen> createState() => _WordWheelScreenState();
}

class _WordWheelScreenState extends State<WordWheelScreen> {
  late WordWheelPuzzle puzzle;
  List<String> outerLetters = [];
  String currentInput = '';
  List<String> foundWords = [];
  String? feedbackMessage;

  @override
  void initState() {
    super.initState();
    _loadPuzzle();
  }

  void _loadPuzzle() {
    final puzzles = MiniGameData.wordWheels;
    int index = (widget.levelId - 1).clamp(0, puzzles.length - 1);
    puzzle = puzzles[index];
    outerLetters = puzzle.outerLetters.split('');
  }

  void _onLetterTap(String letter) {
    setState(() {
      currentInput += letter;
      feedbackMessage = null;
    });
  }

  void _onDelete() {
    if (currentInput.isNotEmpty) {
      setState(() {
        currentInput = currentInput.substring(0, currentInput.length - 1);
        feedbackMessage = null;
      });
    }
  }

  // REAL SHUFFLE: Shuffles outer positions while strictly preserving canonical letter set & duplicates
  void _onShuffle() {
    setState(() {
      outerLetters.shuffle();
      currentInput = '';
      feedbackMessage = null;
    });
  }

  // HINT MECHANIC: Spends 30 coins to reveal 1 unfound word
  void _onHint(UserProvider user) {
    final unfound = puzzle.validWords.where((w) => !foundWords.contains(w)).toList();
    if (unfound.isEmpty) return;

    if (user.userData.coins < 30) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Need 30 coins for a hint!')),
      );
      return;
    }

    user.spendCoins(30);
    final revealed = unfound.first;
    setState(() {
      foundWords.add(revealed);
      feedbackMessage = "Revealed '$revealed'!";
      currentInput = '';
      if (foundWords.length == puzzle.validWords.length) {
        _handleCompletion();
      }
    });
  }

  void _onSubmit() {
    if (currentInput.length < 3) {
      setState(() {
        feedbackMessage = "Too short!";
        currentInput = '';
      });
      return;
    }
    if (!currentInput.contains(puzzle.centerLetter)) {
      setState(() {
        feedbackMessage = "Missing center letter '${puzzle.centerLetter}'!";
        currentInput = '';
      });
      return;
    }
    if (foundWords.contains(currentInput)) {
      setState(() {
        feedbackMessage = "Already found!";
        currentInput = '';
      });
      return;
    }
    if (puzzle.validWords.contains(currentInput)) {
      setState(() {
        foundWords.add(currentInput);
        feedbackMessage = "Nice!";
        currentInput = '';

        if (foundWords.length == puzzle.validWords.length) {
          _handleCompletion();
        }
      });
    } else {
      setState(() {
        feedbackMessage = "Not in word list!";
        currentInput = '';
      });
    }
  }

  void _handleCompletion() {
    final user = Provider.of<UserProvider>(context, listen: false);
    user.recordMiniGameCompleted('word_wheel', puzzle.reward);
    user.progressMiniGame('word_wheel');

    final updatedLevel = user.userData.miniGameLevels['word_wheel'] ?? (widget.levelId + 1);
    final maxLevel = MiniGameData.wordWheels.length;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.deepIndigo,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.gold, width: 2),
        ),
        title: Text(
          updatedLevel <= maxLevel ? '✨ GENIUS!' : '🎉 ALL WHEELS COMPLETE!',
          style: AppTheme.worldTitle.copyWith(color: AppTheme.gold, fontSize: 20),
          textAlign: TextAlign.center,
        ),
        content: Text(
          updatedLevel <= maxLevel
              ? 'You found all words!\nReward: +${puzzle.reward} coins\nXP: +${puzzle.reward * 2}'
              : 'Congratulations! You completed all Word Wheel puzzles.\nReward: +${puzzle.reward} coins',
          style: AppTheme.body.copyWith(color: Colors.white, height: 1.5),
          textAlign: TextAlign.center,
        ),
        actions: [
          if (updatedLevel <= maxLevel)
            Center(
              child: GameButton(
                width: 150,
                height: 44,
                baseColor: AppTheme.success,
                shadowColor: const Color(0xFF1B9954),
                onPressed: () {
                  Navigator.pop(context); // Close completion dialog
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => WordWheelScreen(levelId: updatedLevel),
                    ),
                  );
                },
                child: Text(
                  'NEXT LEVEL',
                  style: AppTheme.body.copyWith(fontWeight: FontWeight.w900, fontSize: 12),
                ),
              ),
            )
          else
            Center(
              child: GameButton(
                width: 160,
                height: 44,
                baseColor: AppTheme.success,
                shadowColor: const Color(0xFF1B9954),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: Text(
                  'BACK TO ARCADE',
                  style: AppTheme.body.copyWith(fontWeight: FontWeight.w900, fontSize: 11),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context);

    return PopScope(
      canPop: true,
      child: ResponsiveScreen(
        backgroundAsset: GameAssets.arcadeBackground,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;
            final isSmall = w < 340 || h < 500;

            final wheelDiameter = math.min(w * 0.62, h * 0.32);

            return Column(
              children: [
                // ── 1. COMPACT APP BAR ─────────────────────────────────
                _buildAppBar(context, user, isSmall),

                const SizedBox(height: 6),

                // ── 2. FOUND WORDS PROGRESS HEADER ──────────────────────
                Text(
                  '${foundWords.length} / ${puzzle.validWords.length} WORDS',
                  style: AppTheme.worldTitle.copyWith(
                    color: AppTheme.gold,
                    fontSize: isSmall ? 15 : 18,
                  ),
                ),
                const SizedBox(height: 4),

                // Progress Bar
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: isSmall ? 20 : 40),
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppTheme.deepIndigo.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppTheme.gold.withValues(alpha: 0.5)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: puzzle.validWords.isEmpty
                            ? 0
                            : foundWords.length / puzzle.validWords.length,
                        backgroundColor: Colors.transparent,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.success),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: isSmall ? 4 : 8),

                // ── 3. FOUND WORDS DISPLAY LIST ─────────────────────────
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(isSmall ? 8 : 12),
                    decoration: BoxDecoration(
                      color: AppTheme.deepIndigo.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                    ),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Wrap(
                        spacing: isSmall ? 6 : 8,
                        runSpacing: isSmall ? 6 : 8,
                        alignment: WrapAlignment.center,
                        children: puzzle.validWords.map((word) {
                          bool isFound = foundWords.contains(word);
                          return Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isSmall ? 8 : 12,
                              vertical: isSmall ? 4 : 6,
                            ),
                            decoration: BoxDecoration(
                              color: isFound ? AppTheme.gold : Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                              border: Border.all(
                                color: isFound ? AppTheme.warmGold : Colors.white12,
                              ),
                            ),
                            child: Text(
                              isFound ? word : ('-' * word.length),
                              style: AppTheme.worldTitle.copyWith(
                                color: isFound ? AppTheme.deepIndigo : Colors.white38,
                                fontSize: isSmall ? 12 : 14,
                                letterSpacing: 2,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: isSmall ? 4 : 8),

                // ── 4. CURRENT INPUT & FEEDBACK ────────────────────────
                Container(
                  height: isSmall ? 32 : 40,
                  alignment: Alignment.center,
                  child: Text(
                    currentInput,
                    style: AppTheme.worldTitle.copyWith(
                      fontSize: isSmall ? 24 : 30,
                      letterSpacing: 4,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (feedbackMessage != null)
                  Text(
                    feedbackMessage!,
                    style: AppTheme.smallSecondary.copyWith(
                      color: AppTheme.coral,
                      fontSize: isSmall ? 11 : 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                SizedBox(height: isSmall ? 6 : 10),

                // ── 5. INTERACTIVE WHEEL & CONTROLS ─────────────────────
                SizedBox(
                  height: wheelDiameter + 10,
                  width: double.infinity,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      _buildLetterWheel(wheelDiameter),

                      // Left: SHUFFLE Button
                      Positioned(
                        left: isSmall ? 10 : 20,
                        child: _buildCircleControl(
                          iconAsset: GameAssets.shuffleIcon,
                          label: 'SHUFFLE',
                          onTap: _onShuffle,
                          isSmall: isSmall,
                        ),
                      ),

                      // Right: HINT Button
                      Positioned(
                        right: isSmall ? 10 : 20,
                        child: _buildCircleControl(
                          iconAsset: GameAssets.hintBulb,
                          label: 'HINT (30🪙)',
                          onTap: () => _onHint(user),
                          isSmall: isSmall,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: isSmall ? 6 : 10),

                // ── 6. SUBMIT & DELETE ACTIONS ──────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GameButton(
                      width: isSmall ? 85 : 100,
                      height: isSmall ? 38 : 44,
                      baseColor: AppTheme.coral,
                      shadowColor: const Color(0xFFC0392B),
                      onPressed: _onDelete,
                      child: Text(
                        'DELETE',
                        style: AppTheme.smallSecondary.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: isSmall ? 10 : 11.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    GameButton(
                      width: isSmall ? 110 : 130,
                      height: isSmall ? 38 : 44,
                      baseColor: AppTheme.success,
                      shadowColor: const Color(0xFF1B9954),
                      onPressed: _onSubmit,
                      child: Text(
                        'SUBMIT',
                        style: AppTheme.smallSecondary.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: isSmall ? 11 : 12.5,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, UserProvider user, bool isSmall) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Proper Back Button (Min 44x44 target, standard game asset)
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.pop(context),
          child: Image.asset(
            GameAssets.backButton,
            width: 44,
            height: 44,
            fit: BoxFit.contain,
          ),
        ),
        Flexible(
          child: Text(
            'WORD WHEEL • LVL ${widget.levelId}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.worldTitle.copyWith(
              fontSize: isSmall ? 14 : 17,
              letterSpacing: 1.5,
            ),
          ),
        ),
        // Coin Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF10152F).withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFFD21C).withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(GameAssets.coin, width: 16, height: 16),
              const SizedBox(width: 4),
              Text(
                '${user.userData.coins}',
                style: TextStyle(
                  fontFamily: AppTheme.body.fontFamily,
                  color: AppTheme.gold,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCircleControl({
    required String iconAsset,
    required String label,
    required VoidCallback onTap,
    required bool isSmall,
  }) {
    final diam = isSmall ? 46.0 : 52.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: diam,
            height: diam,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF10152F).withValues(alpha: 0.85),
              border: Border.all(
                color: const Color(0xFFFFD21C).withValues(alpha: 0.50),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Center(
              child: Image.asset(
                iconAsset,
                width: diam * 0.50,
                height: diam * 0.50,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: AppTheme.smallSecondary.copyWith(
              color: Colors.white70,
              fontSize: isSmall ? 8.5 : 9.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLetterWheel(double diameter) {
    final radius = diameter / 2;
    final centerLetter = puzzle.centerLetter;
    final count = outerLetters.length;

    return SizedBox(
      width: diameter,
      height: diameter,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Outer Ring
          Container(
            width: diameter,
            height: diameter,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.deepIndigo.withValues(alpha: 0.85),
              border: Border.all(color: AppTheme.gold.withValues(alpha: 0.40), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 10,
                ),
              ],
            ),
          ),

          // Center Key Letter
          GestureDetector(
            onTap: () => _onLetterTap(centerLetter),
            child: Container(
              width: radius * 0.65,
              height: radius * 0.65,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.gold,
                border: Border.all(color: AppTheme.warmGold, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.gold.withValues(alpha: 0.5),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  centerLetter,
                  style: AppTheme.worldTitle.copyWith(
                    color: AppTheme.deepIndigo,
                    fontSize: radius * 0.32,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),

          // Outer Surrounding Letters
          ...List.generate(count, (i) {
            final angle = (2 * math.pi / count) * i - (math.pi / 2);
            final dist = radius * 0.62;
            final x = dist * math.cos(angle);
            final y = dist * math.sin(angle);
            final letter = outerLetters[i];

            return Transform.translate(
              offset: Offset(x, y),
              child: GestureDetector(
                onTap: () => _onLetterTap(letter),
                child: Container(
                  width: radius * 0.45,
                  height: radius * 0.45,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.15),
                    border: Border.all(color: Colors.white30, width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      letter,
                      style: AppTheme.worldTitle.copyWith(
                        color: Colors.white,
                        fontSize: radius * 0.22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
