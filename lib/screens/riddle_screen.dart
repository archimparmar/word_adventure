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
import '../services/audio_service.dart';

import '../widgets/game_control_buttons.dart';

class RiddleScreen extends StatefulWidget {
  final int levelId;
  const RiddleScreen({super.key, required this.levelId});

  @override
  State<RiddleScreen> createState() => _RiddleScreenState();
}

class _RiddleScreenState extends State<RiddleScreen> {
  late RiddlePuzzle puzzle;
  List<String?> userSlots = [];
  List<String> availableLetters = [];
  List<bool> letterUsed = [];
  String? feedbackMessage;
  bool isHintRevealed = false;

  @override
  void initState() {
    super.initState();
    _loadPuzzle();
  }

  void _loadPuzzle() {
    final puzzles = MiniGameData.riddles;
    int index = (widget.levelId - 1).clamp(0, math.max(0, puzzles.length - 1));
    puzzle = index < puzzles.length
        ? puzzles[index]
        : RiddlePuzzle(
            id: widget.levelId,
            clue: "I have one eye but cannot see, and I spin across the sea. What am I?",
            answer: "HURRICANE",
            category: "General",
            difficulty: "Easy",
            hint: "I am a powerful tropical storm.",
            explanation: "A hurricane has a calm center called the eye.",
          );

    final cleanAnswer = puzzle.answer.toUpperCase();
    final letterChars = cleanAnswer.replaceAll(RegExp(r'\s+'), '').split('');

    userSlots = List<String?>.filled(letterChars.length, null);

    List<String> pool = List.from(letterChars);
    const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    final random = math.Random(widget.levelId * 37);

    int targetBankSize = math.max(10, letterChars.length + 3);
    while (pool.length < targetBankSize) {
      String extraChar = alphabet[random.nextInt(alphabet.length)];
      pool.add(extraChar);
    }

    pool.shuffle(random);
    availableLetters = pool;
    letterUsed = List<bool>.filled(availableLetters.length, false);
    feedbackMessage = null;
    isHintRevealed = false;
  }

  void _onLetterSelect(int index) {
    if (letterUsed[index]) return;

    int emptyIndex = userSlots.indexOf(null);
    if (emptyIndex != -1) {
      AudioService().playLetterSelect();
      setState(() {
        userSlots[emptyIndex] = availableLetters[index];
        letterUsed[index] = true;
        feedbackMessage = null;
      });

      if (!userSlots.contains(null)) {
        _checkAnswer();
      }
    }
  }

  void _onSlotTap(int slotIndex) {
    if (userSlots[slotIndex] == null) return;

    String letter = userSlots[slotIndex]!;
    int letterIndex = availableLetters.asMap().entries.firstWhere(
      (e) => e.value == letter && letterUsed[e.key],
      orElse: () => const MapEntry(-1, ''),
    ).key;

    if (letterIndex != -1) {
      setState(() {
        userSlots[slotIndex] = null;
        letterUsed[letterIndex] = false;
        feedbackMessage = null;
      });
    }
  }

  void _onClear() {
    final letterChars = puzzle.answer.toUpperCase().replaceAll(RegExp(r'\s+'), '').split('');
    setState(() {
      userSlots = List<String?>.filled(letterChars.length, null);
      letterUsed = List<bool>.filled(availableLetters.length, false);
      feedbackMessage = null;
    });
  }

  void _onHint(UserProvider user) {
    if (isHintRevealed) {
      setState(() {
        feedbackMessage = "Hint: ${puzzle.hint}";
      });
      return;
    }

    if (user.userData.hints > 0) {
      user.useHint(1);
      AudioService().playHintUsed();
    } else if (user.userData.coins >= 15) {
      user.spendCoins(15);
      AudioService().playHintUsed();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Need 15 coins or 1 hint!')),
      );
      return;
    }

    setState(() {
      isHintRevealed = true;
      feedbackMessage = "Hint: ${puzzle.hint}";
    });
  }

  void _checkAnswer() {
    final targetLetterChars = puzzle.answer.toUpperCase().replaceAll(RegExp(r'\s+'), '');
    final entered = userSlots.join('');

    if (entered == targetLetterChars) {
      _handleCompletion();
    } else {
      setState(() {
        feedbackMessage = "Not quite! Try again.";
      });
    }
  }

  void _handleCompletion() {
    AudioService().playMiniGameComplete();
    final user = Provider.of<UserProvider>(context, listen: false);
    user.recordMiniGameCompleted('riddle', puzzle.reward);
    user.progressMiniGame('word_riddle', completedLevel: widget.levelId);

    final maxLevel = math.max(1, MiniGameData.riddles.length);
    final nextLevel = widget.levelId + 1;
    final bool hasNext = nextLevel <= maxLevel;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.deepIndigo,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.gold, width: 2),
        ),
        title: Text(
          hasNext ? '✨ RIDDLE SOLVED!' : '🎉 ALL RIDDLES COMPLETE!',
          style: AppTheme.worldTitle.copyWith(color: AppTheme.gold, fontSize: 18),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              puzzle.explanation,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Reward: +${puzzle.reward} coins',
              style: AppTheme.smallSecondary.copyWith(color: AppTheme.success, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          Column(
            children: [
              if (hasNext) ...[
                Center(
                  child: GameButton(
                    width: 170,
                    height: 42,
                    baseColor: AppTheme.success,
                    shadowColor: const Color(0xFF1B9954),
                    onPressed: () {
                      Navigator.pop(dialogCtx);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RiddleScreen(levelId: nextLevel),
                        ),
                      );
                    },
                    child: Text(
                      'NEXT RIDDLE',
                      style: AppTheme.body.copyWith(fontWeight: FontWeight.w900, fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Center(

                child: GameButton(
                  width: 170,
                  height: 38,
                  baseColor: const Color(0xFF3B82F6),
                  shadowColor: const Color(0xFF1D4ED8),
                  onPressed: () {
                    Navigator.pop(dialogCtx);
                    Navigator.pop(context);
                  },
                  child: Text(
                    'HOME',
                    style: AppTheme.body.copyWith(fontWeight: FontWeight.w900, fontSize: 12),
                  ),
                ),
              ),
            ],
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
        blurBackground: true,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final h = constraints.maxHeight;
              final isSmall = w < 340 || h < 550;

              final scrollHeight = (h * 0.35).clamp(150.0, 230.0);

              return Stack(
                children: [
                  Column(
                    children: [
                      // 1. TOP HEADER (Unified Header Row)
                      UnifiedHeaderRow(
                        levelId: widget.levelId,
                        isSmall: isSmall,
                      ),

                      SizedBox(height: isSmall ? 12 : 18), // Moved description/clue card slightly DOWN

                      // 2. RIDDLE SCROLL FRAME
                      _buildScrollFrame(w, scrollHeight, isSmall),

                      SizedBox(height: isSmall ? 18 : 24), // Clear gap between clue card & answer slots

                      // 3. ANSWER SLOTS
                      _buildAnswerSlots(w, isSmall),

                      if (feedbackMessage != null) ...[
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            feedbackMessage!,
                            textAlign: TextAlign.center,
                            style: AppTheme.smallSecondary.copyWith(
                              color: isHintRevealed ? AppTheme.gold : AppTheme.coral,
                              fontSize: isSmall ? 11 : 13.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],

                      SizedBox(height: isSmall ? 16 : 24), // Moved bottom letter list slightly DOWN

                      // 4. LETTER SELECTION BANK
                      Expanded(
                        child: Center(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: _buildLetterBank(w, isSmall),
                          ),
                        ),
                      ),
                      const SizedBox(height: 56), // Room for bottom corner controls
                    ],
                  ),

                  // 5. LOWER CORNER CIRCULAR CONTROLS: HINT (Left) & REPLAY (Right) - Matching Main Gameplay
                  Positioned(
                    left: 28,
                    bottom: 4,
                    child: UnifiedHintButton(
                      isSmall: isSmall,
                      onTap: () => _onHint(user),
                    ),
                  ),

                  Positioned(
                    right: 28,
                    bottom: 4,
                    child: UnifiedReplayButton(
                      isSmall: isSmall,
                      onTap: _onClear,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildScrollFrame(double screenWidth, double height, bool isSmall) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.deepIndigo.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.gold, width: 2.0),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Opacity(
                opacity: 0.25,
                child: Image.asset(
                  GameAssets.riddleScroll,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => const SizedBox(),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isSmall ? 14.0 : 20.0,
              vertical: isSmall ? 8.0 : 12.0,
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.gold.withValues(alpha: 0.20),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.gold.withValues(alpha: 0.50)),
                  ),
                  child: Text(
                    '${puzzle.category.toUpperCase()} • ${puzzle.difficulty.toUpperCase()}',
                    style: AppTheme.smallSecondary.copyWith(
                      color: AppTheme.gold,
                      fontWeight: FontWeight.w900,
                      fontSize: isSmall ? 9.5 : 11,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Text(
                        puzzle.clue,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: AppTheme.worldTitle.fontFamily,
                          fontSize: isSmall ? 19 : 22, // Increased font size for maximum readability
                          fontWeight: FontWeight.w900,
                          height: 1.35,
                          color: Colors.white,
                          shadows: const [
                            Shadow(color: Colors.black, blurRadius: 8, offset: Offset(0, 2)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerSlots(double screenWidth, bool isSmall) {
    final words = puzzle.answer.toUpperCase().split(RegExp(r'\s+'));
    int totalLetters = 0;
    for (var w in words) {
      totalLetters += w.length;
    }

    final double maxSlotSize = isSmall ? 32.0 : 38.0;
    final double availableW = screenWidth - 32;
    double slotSize = (availableW - (totalLetters * 4)) / math.max(1, totalLetters);
    slotSize = slotSize.clamp(20.0, maxSlotSize);

    int slotIndex = 0;

    return Wrap(
      spacing: isSmall ? 10 : 14,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: words.map((wordStr) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(wordStr.length, (charIdx) {
            final currentSlotIdx = slotIndex++;
            String? letter = userSlots[currentSlotIdx];

            return GestureDetector(
              onTap: () => _onSlotTap(currentSlotIdx),
              child: Container(
                width: slotSize,
                height: slotSize * 1.15,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: letter != null ? AppTheme.gold : const Color(0xFF10152F).withValues(alpha: 0.80),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: letter != null ? AppTheme.warmGold : const Color(0xFFFFD21C).withValues(alpha: 0.40),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    letter ?? '',
                    style: AppTheme.worldTitle.copyWith(
                      color: letter != null ? AppTheme.deepIndigo : Colors.white,
                      fontSize: slotSize * 0.58,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      }).toList(),
    );
  }

  Widget _buildLetterBank(double screenWidth, bool isSmall) {
    final tileSize = isSmall ? 34.0 : 40.0;

    return Wrap(
      spacing: isSmall ? 5 : 8,
      runSpacing: isSmall ? 5 : 8,
      alignment: WrapAlignment.center,
      children: List.generate(availableLetters.length, (i) {
        bool isUsed = letterUsed[i];
        String letter = availableLetters[i];

        return GestureDetector(
          onTap: () => _onLetterSelect(i),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 150),
            opacity: isUsed ? 0.25 : 1.0,
            child: Container(
              width: tileSize,
              height: tileSize,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white30, width: 1.5),
              ),
              child: Center(
                child: Text(
                  letter,
                  style: AppTheme.worldTitle.copyWith(
                    color: Colors.white,
                    fontSize: isSmall ? 15 : 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
