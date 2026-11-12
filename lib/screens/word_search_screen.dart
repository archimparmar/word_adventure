import 'dart:math' as math;
import 'dart:math' show Point;
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

class WordSearchScreen extends StatefulWidget {
  final int levelId;
  const WordSearchScreen({super.key, required this.levelId});

  @override
  State<WordSearchScreen> createState() => _WordSearchScreenState();
}

class _WordSearchScreenState extends State<WordSearchScreen> {
  late WordSearchPuzzle puzzle;
  late int gridSize;
  List<List<String>> gridMatrix = [];

  List<String> foundWords = [];
  Set<String> permanentFoundCells = {};
  Map<String, int> cellToWordIndex = {};

  int? dragStartX, dragStartY;
  int? dragCurrentX, dragCurrentY;
  List<Point<int>> currentSelectionPath = [];

  static const List<Color> _foundWordPalette = [
    Color(0xFF06B6D4), // Vibrant Cyan
    Color(0xFFEC4899), // Hot Pink / Rose
    Color(0xFFF59E0B), // Warm Gold / Amber
    Color(0xFF10B981), // Emerald Green
    Color(0xFFA855F7), // Bright Purple / Violet
    Color(0xFF3B82F6), // Royal Blue
    Color(0xFFF97316), // Vivid Orange
    Color(0xFF8B5CF6), // Deep Indigo
  ];

  @override
  void initState() {
    super.initState();
    _loadPuzzle();
  }

  void _loadPuzzle() {
    final puzzles = MiniGameData.wordSearches;
    int index = (widget.levelId - 1).clamp(0, math.max(0, puzzles.length - 1));
    puzzle = index < puzzles.length
        ? puzzles[index]
        : WordSearchPuzzle(
            id: widget.levelId,
            size: 6,
            difficulty: "easy",
            board: [
              "UBYARN",
              "PIBNNK",
              "DAORYY",
              "RENCOS",
              "QUSZLU",
              "ICWKAO"
            ],
            words: [
              WordSearchWord(word: "YARN", startRow: 0, startCol: 2, endRow: 0, endCol: 5, direction: "right")
            ],
          );

    gridSize = puzzle.size;
    foundWords.clear();
    permanentFoundCells.clear();
    cellToWordIndex.clear();

    gridMatrix = List.generate(gridSize, (r) {
      String rowStr = r < puzzle.board.length ? puzzle.board[r] : '';
      return List.generate(gridSize, (c) {
        if (c < rowStr.length) {
          return rowStr[c].toUpperCase();
        }
        return 'X';
      });
    });
  }

  void _onHint(UserProvider user) {
    final remainingWords = puzzle.words.where((w) => !foundWords.contains(w.word.toUpperCase())).toList();
    if (remainingWords.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All words are already found!')),
      );
      return;
    }

    if (user.userData.hints > 0) {
      user.useHint(1);
      AudioService().playHintUsed();
    } else if (user.userData.coins >= 20) {
      user.spendCoins(20);
      AudioService().playHintUsed();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Need 20 coins or 1 hint!')),
      );
      return;
    }

    final target = remainingWords.first;
    int wordIdx = puzzle.words.indexOf(target);
    if (wordIdx == -1) {
      wordIdx = puzzle.words.indexWhere((w) => w.word.toUpperCase() == target.word.toUpperCase());
    }

    setState(() {
      foundWords.add(target.word.toUpperCase());
      int dx = 0;
      int dy = 0;
      if (target.direction == 'right') {
        dx = 1;
      } else if (target.direction == 'down') {
        dy = 1;
      } else if (target.direction == 'diag') {
        dx = 1;
        dy = 1;
      }

      for (int i = 0; i < target.word.length; i++) {
        int r = target.startRow + (i * dy);
        int c = target.startCol + (i * dx);
        permanentFoundCells.add("${r}_$c");
        cellToWordIndex["${r}_$c"] = wordIdx;
      }
    });

    _checkCompletion();
  }

  void _onPanStart(Offset localPos, double outerSideLength) {
    final cell = _getGridCellFromLocalPos(localPos, outerSideLength);
    if (cell != null) {
      AudioService().playLetterSelect();
      setState(() {
        dragStartX = cell.x;
        dragStartY = cell.y;
        dragCurrentX = cell.x;
        dragCurrentY = cell.y;
        currentSelectionPath = [cell];
      });
    }
  }

  void _onPanUpdate(Offset localPos, double outerSideLength) {
    if (dragStartX == null || dragStartY == null) return;
    final cell = _getGridCellFromLocalPos(localPos, outerSideLength);
    if (cell != null && (cell.x != dragCurrentX || cell.y != dragCurrentY)) {
      dragCurrentX = cell.x;
      dragCurrentY = cell.y;
      _calculateSelectionPath();
    }
  }

  void _calculateSelectionPath() {
    if (dragStartX == null || dragStartY == null || dragCurrentX == null || dragCurrentY == null) return;

    int dx = dragCurrentX! - dragStartX!;
    int dy = dragCurrentY! - dragStartY!;

    if (dx == 0 && dy == 0) {
      currentSelectionPath = [Point(dragStartX!, dragStartY!)];
      setState(() {});
      return;
    }

    int steps = math.max(dx.abs(), dy.abs());
    int stepX = dx == 0 ? 0 : (dx > 0 ? 1 : -1);
    int stepY = dy == 0 ? 0 : (dy > 0 ? 1 : -1);

    if (dx == 0 || dy == 0 || dx.abs() == dy.abs()) {
      List<Point<int>> path = [];
      for (int i = 0; i <= steps; i++) {
        int cx = dragStartX! + i * stepX;
        int cy = dragStartY! + i * stepY;
        if (cx >= 0 && cx < gridSize && cy >= 0 && cy < gridSize) {
          path.add(Point(cx, cy));
        }
      }
      currentSelectionPath = path;
      setState(() {});
    }
  }

  void _onPanEnd() {
    if (currentSelectionPath.isEmpty) return;

    String selectedStr = currentSelectionPath.map((p) => gridMatrix[p.y][p.x]).join('');
    String revStr = selectedStr.split('').reversed.join('');

    WordSearchWord? matchedWord;
    for (var w in puzzle.words) {
      String upperW = w.word.toUpperCase();
      if (upperW == selectedStr || upperW == revStr) {
        matchedWord = w;
        break;
      }
    }

    if (matchedWord != null) {
      String wUpper = matchedWord.word.toUpperCase();
      if (!foundWords.contains(wUpper)) {
        int wordIdx = puzzle.words.indexOf(matchedWord);
        if (wordIdx == -1) {
          wordIdx = puzzle.words.indexWhere((w) => w.word.toUpperCase() == wUpper);
        }

        setState(() {
          foundWords.add(wUpper);
          for (var p in currentSelectionPath) {
            permanentFoundCells.add("${p.y}_${p.x}");
            cellToWordIndex["${p.y}_${p.x}"] = wordIdx;
          }
        });
        AudioService().playWordCorrect();
        _checkCompletion();
      }
    }

    setState(() {
      dragStartX = null;
      dragStartY = null;
      dragCurrentX = null;
      dragCurrentY = null;
      currentSelectionPath = [];
    });
  }

  Point<int>? _getGridCellFromLocalPos(Offset pos, double outerSideLength) {
    double borderPaddingOverhead = 16.0;
    double availableGridSpace = math.max(0.0, outerSideLength - borderPaddingOverhead);
    double cellSize = (availableGridSpace / gridSize).floorToDouble();

    double gridOffsetX = (outerSideLength - (cellSize * gridSize)) / 2.0;
    double gridOffsetY = (outerSideLength - (cellSize * gridSize)) / 2.0;

    double relX = pos.dx - gridOffsetX;
    double relY = pos.dy - gridOffsetY;

    if (relX < 0 || relX >= (cellSize * gridSize) || relY < 0 || relY >= (cellSize * gridSize)) {
      return null;
    }

    int c = (relX / cellSize).floor().clamp(0, gridSize - 1);
    int r = (relY / cellSize).floor().clamp(0, gridSize - 1);
    return Point(c, r);
  }

  void _checkCompletion() {
    if (foundWords.length >= puzzle.words.length) {
      _handleCompletion();
    }
  }

  void _handleCompletion() {
    AudioService().playMiniGameComplete();
    final user = Provider.of<UserProvider>(context, listen: false);
    user.recordMiniGameCompleted('word_search', puzzle.reward);
    user.progressMiniGame('word_search', completedLevel: widget.levelId);

    final maxLevel = math.max(1, MiniGameData.wordSearches.length);
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
          hasNext ? '✨ PUZZLE SOLVED!' : '🎉 ALL WORD SEARCHES COMPLETE!',
          style: AppTheme.worldTitle.copyWith(color: AppTheme.gold, fontSize: 18),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'All hidden words discovered!',
              style: TextStyle(color: Colors.white, fontSize: 14),
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
                          builder: (_) => WordSearchScreen(levelId: nextLevel),
                        ),
                      );
                    },
                    child: Text(
                      'NEXT PUZZLE',
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

              return Stack(
                children: [
                  Column(
                    children: [
                      // 1. TOP HEADER (Unified Header Row)
                      UnifiedHeaderRow(
                        levelId: widget.levelId,
                        isSmall: isSmall,
                      ),

                      SizedBox(height: isSmall ? 12 : 16), // Moved WORDS TO FIND card slightly DOWN

                      // 2. TARGET WORDS LIST (Redesigned card with distinct found word colors)
                      _buildTargetWordsList(isSmall),

                      const SizedBox(height: 8),

                      // 3. FLEXIBLE REMAINING AREA FOR SQUARE GRID (Guaranteed 0 overflow)
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, gridConstraints) {
                            final availW = gridConstraints.maxWidth;
                            final availH = gridConstraints.maxHeight;

                            final maxAllowedW = math.max(100.0, availW - 32.0);
                            final maxAllowedH = math.max(100.0, availH - 24.0);

                            // Exact square outer side length matching available constraints
                            final double outerBoardSize = math.min(maxAllowedW, maxAllowedH).clamp(100.0, 340.0);

                            return Center(
                              child: SizedBox(
                                width: outerBoardSize,
                                height: outerBoardSize,
                                child: GestureDetector(
                                  onPanStart: (d) => _onPanStart(d.localPosition, outerBoardSize),
                                  onPanUpdate: (d) => _onPanUpdate(d.localPosition, outerBoardSize),
                                  onPanEnd: (d) => _onPanEnd(),
                                  child: _buildGrid(outerBoardSize, isSmall),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 56), // Room for bottom Hint control
                    ],
                  ),

                  // 4. LOWER CORNER HINT CONTROL - Matching Main Gameplay
                  Positioned(
                    left: 28,
                    bottom: 4,
                    child: UnifiedHintButton(
                      isSmall: isSmall,
                      onTap: () => _onHint(user),
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

  Widget _buildTargetWordsList(bool isSmall) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: isSmall ? 8 : 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F1B3E), Color(0xFF162A56)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF59E0B), width: 1.8),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          Text(
            'WORDS TO FIND',
            style: TextStyle(
              fontFamily: AppTheme.worldTitle.fontFamily,
              color: const Color(0xFFFFD21C),
              fontWeight: FontWeight.w900,
              fontSize: isSmall ? 13.0 : 15.0,
              letterSpacing: 1.4,
              shadows: const [
                Shadow(color: Colors.black, blurRadius: 4, offset: Offset(0, 1.5)),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: isSmall ? 8 : 12,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: List.generate(puzzle.words.length, (index) {
              final w = puzzle.words[index];
              final wordStr = w.word.toUpperCase();
              bool isFound = foundWords.contains(wordStr);
              Color wordColor = _foundWordPalette[index % _foundWordPalette.length];

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isFound
                      ? wordColor.withValues(alpha: 0.22)
                      : const Color(0xFF1E3A8A).withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isFound ? wordColor : const Color(0xFFFFD21C),
                    width: isFound ? 1.8 : 1.2,
                  ),
                ),
                child: Text(
                  wordStr,
                  style: TextStyle(
                    fontFamily: AppTheme.worldTitle.fontFamily,
                    fontSize: isSmall ? 12.0 : 13.5,
                    fontWeight: FontWeight.w900,
                    color: isFound ? wordColor : Colors.white,
                    decoration: isFound ? TextDecoration.lineThrough : null,
                    decorationColor: wordColor,
                    decorationThickness: 2.5,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(double outerSideLength, bool isSmall) {
    final double borderPaddingOverhead = 16.0;
    final double availableGridSpace = math.max(0.0, outerSideLength - borderPaddingOverhead);
    final double cellSize = (availableGridSpace / gridSize).floorToDouble();

    return Container(
      width: outerSideLength,
      height: outerSideLength,
      padding: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D1738), Color(0xFF091026)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF59E0B), width: 2.5),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 12, offset: Offset(0, 6)),
          BoxShadow(color: Color(0xFFF59E0B), blurRadius: 4, spreadRadius: -2),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(gridSize, (r) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(gridSize, (c) {
                bool isSelectedInDrag = currentSelectionPath.any((p) => p.x == c && p.y == r);
                bool isPermanentFound = permanentFoundCells.contains("${r}_$c");

                Color cellBg;
                Color borderColor;
                Color textColor;
                double borderWidth;

                if (isSelectedInDrag) {
                  cellBg = const Color(0xFFFFD21C); // Solid bright gold during drag selection
                  borderColor = Colors.white;
                  textColor = const Color(0xFF0D1738);
                  borderWidth = 2.0;
                } else if (isPermanentFound) {
                  int? wordIdx = cellToWordIndex["${r}_$c"];
                  Color wordColor = (wordIdx != null && wordIdx >= 0)
                      ? _foundWordPalette[wordIdx % _foundWordPalette.length]
                      : const Color(0xFF06B6D4);

                  cellBg = wordColor.withValues(alpha: 0.85); // Distinct persistent color per word
                  borderColor = Colors.white.withValues(alpha: 0.90);
                  textColor = Colors.white;
                  borderWidth = 1.6;
                } else {
                  cellBg = const Color(0xFF0F1C3F).withValues(alpha: 0.90);
                  borderColor = const Color(0xFF1E2D5A);
                  textColor = Colors.white;
                  borderWidth = 1.0;
                }

                return Container(
                  width: cellSize - 2.0,
                  height: cellSize - 2.0,
                  margin: const EdgeInsets.all(1.0),
                  decoration: BoxDecoration(
                    color: cellBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: borderColor,
                      width: borderWidth,
                    ),
                    boxShadow: isSelectedInDrag
                        ? const [
                            BoxShadow(color: Color(0xFFFFD21C), blurRadius: 6, spreadRadius: 1),
                          ]
                        : (isPermanentFound
                            ? [
                                BoxShadow(
                                  color: cellBg.withValues(alpha: 0.6),
                                  blurRadius: 4,
                                  spreadRadius: -1,
                                ),
                              ]
                            : null),
                  ),
                  child: Center(
                    child: Text(
                      gridMatrix[r][c],
                      style: TextStyle(
                        fontFamily: AppTheme.worldTitle.fontFamily,
                        fontSize: cellSize * 0.50,
                        fontWeight: FontWeight.w900,
                        color: textColor,
                      ),
                    ),
                  ),
                );
              }),
            );
          }),
        ),
      ),
    );
  }
}
