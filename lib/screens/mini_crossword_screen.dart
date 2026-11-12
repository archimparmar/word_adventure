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

class MiniCrosswordScreen extends StatefulWidget {
  final int levelId;
  const MiniCrosswordScreen({super.key, required this.levelId});

  @override
  State<MiniCrosswordScreen> createState() => _MiniCrosswordScreenState();
}

class _MiniCrosswordScreenState extends State<MiniCrosswordScreen> {
  late CrosswordPuzzle puzzle;
  late int rows;
  late int cols;

  // Map of "r_c" -> user entered letter
  final Map<String, String> userGrid = {};
  // Map of "r_c" -> prefilled starting letter
  final Map<String, String> prefilledGrid = {};

  // Unique set of letters required for this puzzle level keyboard
  List<String> levelLetters = [];

  // Active selection state
  int activeRow = 0;
  int activeCol = 0;
  String activeDirection = 'across'; // 'across' or 'down'
  CrosswordWord? activeWord;

  @override
  void initState() {
    super.initState();
    _loadPuzzle();
  }

  void _loadPuzzle() {
    final puzzles = MiniGameData.crosswords;
    int index = (widget.levelId - 1).clamp(0, math.max(0, puzzles.length - 1));
    puzzle = index < puzzles.length
        ? puzzles[index]
        : CrosswordPuzzle(
            id: widget.levelId,
            rows: 3,
            cols: 5,
            grid: ["#####", "QUILT", "#####"],
            solution: ["#####", "QUILT", "#####"],
            words: [
              CrosswordWord(number: 1, answer: "QUILT", clue: "A warm bed cover made of stitched fabric squares.", row: 1, col: 0, direction: "across"),
            ],
          );

    rows = puzzle.rows;
    cols = puzzle.cols;
    userGrid.clear();
    prefilledGrid.clear();

    // Populate prefilled cells & userGrid initial values
    for (int r = 0; r < rows; r++) {
      String rowStr = r < puzzle.grid.length ? puzzle.grid[r] : '';
      for (int c = 0; c < cols; c++) {
        if (c < rowStr.length) {
          String char = rowStr[c].toUpperCase();
          if (char != '#' && char != '.' && char != '_') {
            prefilledGrid["${r}_$c"] = char;
            userGrid["${r}_$c"] = char;
          }
        }
      }
    }

    // Extract unique letters required for keyboard
    final Set<String> requiredSet = {};
    for (var w in puzzle.words) {
      for (var char in w.answer.toUpperCase().split('')) {
        if (RegExp(r'[A-Z]').hasMatch(char)) {
          requiredSet.add(char);
        }
      }
    }
    List<String> sortedList = requiredSet.toList()..sort();
    if (sortedList.isEmpty) {
      sortedList = ['A', 'B', 'C', 'D', 'E'];
    }
    levelLetters = sortedList;

    _selectInitialCell();
  }

  void _selectInitialCell() {
    if (puzzle.words.isNotEmpty) {
      activeWord = puzzle.words.first;
      activeRow = activeWord!.row;
      activeCol = activeWord!.col;
      activeDirection = activeWord!.direction;
    }
  }

  bool _isBlocked(int r, int c) {
    if (r < 0 || r >= puzzle.grid.length) return true;
    String rowStr = puzzle.grid[r];
    if (c < 0 || c >= rowStr.length) return true;
    String char = rowStr[c];
    return char == '#' || char == '.';
  }

  void _onKeyPress(String letter) {
    if (_isBlocked(activeRow, activeCol)) return;

    String key = "${activeRow}_$activeCol";

    if (!prefilledGrid.containsKey(key)) {
      setState(() {
        userGrid[key] = letter.toUpperCase();
      });
    }

    AudioService().playLetterSelect();
    _advanceCursor();
    _checkCompletion();
  }

  void _onHint(UserProvider user) {
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

    // Reveal one empty or incorrect cell in the active word
    if (activeWord != null) {
      for (int i = 0; i < activeWord!.answer.length; i++) {
        int r = activeDirection == 'across' ? activeWord!.row : activeWord!.row + i;
        int c = activeDirection == 'across' ? activeWord!.col + i : activeWord!.col;
        String key = "${r}_$c";
        String expected = activeWord!.answer[i].toUpperCase();

        if (userGrid[key] != expected) {
          setState(() {
            userGrid[key] = expected;
          });
          _checkCompletion();
          return;
        }
      }
    }
  }

  void _advanceCursor() {
    if (activeWord == null) return;

    if (activeDirection == 'across') {
      int nextC = activeCol + 1;
      if (nextC < activeWord!.col + activeWord!.answer.length && !_isBlocked(activeRow, nextC)) {
        activeCol = nextC;
      }
    } else {
      int nextR = activeRow + 1;
      if (nextR < activeWord!.row + activeWord!.answer.length && !_isBlocked(nextR, activeCol)) {
        activeRow = nextR;
      }
    }
    setState(() {});
  }

  void _checkCompletion() {
    bool complete = true;

    for (int r = 0; r < rows; r++) {
      String solRow = (r < puzzle.solution.length) ? puzzle.solution[r] : '';
      for (int c = 0; c < cols; c++) {
        if (!_isBlocked(r, c)) {
          String expected = (c < solRow.length && solRow[c] != '_' && solRow[c] != '#')
              ? solRow[c].toUpperCase()
              : _getExpectedCellLetter(r, c);
          String userChar = userGrid["${r}_$c"] ?? '';
          if (userChar != expected) {
            complete = false;
            break;
          }
        }
      }
      if (!complete) break;
    }

    if (complete) {
      _handleCompletion();
    }
  }

  String _getExpectedCellLetter(int r, int c) {
    for (var w in puzzle.words) {
      if (w.direction == 'across' && r == w.row && c >= w.col && c < w.col + w.answer.length) {
        return w.answer[c - w.col].toUpperCase();
      }
      if (w.direction == 'down' && c == w.col && r >= w.row && r < w.row + w.answer.length) {
        return w.answer[r - w.row].toUpperCase();
      }
    }
    return '';
  }

  void _handleCompletion() {
    AudioService().playMiniGameComplete();
    final user = Provider.of<UserProvider>(context, listen: false);
    user.recordMiniGameCompleted('mini_crossword', puzzle.reward);
    user.progressMiniGame('mini_crossword', completedLevel: widget.levelId);

    final maxLevel = math.max(1, MiniGameData.crosswords.length);
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
          hasNext ? '✨ CROSSWORD SOLVED!' : '🎉 ALL CROSSWORDS COMPLETE!',
          style: AppTheme.worldTitle.copyWith(color: AppTheme.gold, fontSize: 18),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Excellent crossword completion!',
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
                          builder: (_) => MiniCrosswordScreen(levelId: nextLevel),
                        ),
                      );
                    },
                    child: Text(
                      'NEXT CROSSWORD',
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

  void _onSpatialCellTap(int r, int c) {
    if (_isBlocked(r, c)) return;

    final cellWords = puzzle.words.where((w) {
      if (w.direction == 'across') {
        return r == w.row && c >= w.col && c < w.col + w.answer.length;
      } else {
        return c == w.col && r >= w.row && r < w.row + w.answer.length;
      }
    }).toList();

    if (cellWords.isEmpty) return;

    if (r == activeRow && c == activeCol) {
      // Toggle direction at intersections
      if (cellWords.length > 1) {
        activeDirection = (activeDirection == 'across') ? 'down' : 'across';
      }
    } else {
      activeRow = r;
      activeCol = c;
    }

    final match = cellWords.firstWhere(
      (w) => w.direction == activeDirection,
      orElse: () => cellWords.first,
    );

    activeDirection = match.direction;
    activeWord = match;

    setState(() {});
  }

  void _onReplay() {
    setState(() {
      userGrid.clear();
      for (var entry in prefilledGrid.entries) {
        userGrid[entry.key] = entry.value;
      }
      _selectInitialCell();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context);

    return PopScope(
      canPop: true,
      child: ResponsiveScreen(
        backgroundAsset: GameAssets.arcadeBackground,
        blurBackground: true,
        blurSigma: 2.5,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final h = constraints.maxHeight;
              final isSmall = w < 340 || h < 600;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                child: Column(
                  children: [
                    // 1. TOP HEADER (Unified Header Row)
                    UnifiedHeaderRow(
                      levelId: widget.levelId,
                      isSmall: isSmall,
                    ),

                    SizedBox(height: isSmall ? 10 : 14), // Moved Hint description card slightly DOWN

                    // 2. CLUE PANEL (Dark navy interior, gold decorative border frame)
                    _buildCluePanel(isSmall),

                    SizedBox(height: isSmall ? 3 : 5),

                    // 3. CROSSWORD GRID (Expanded, enlarged spatial crossword cells)
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: _buildSpatialCrosswordGrid(w, h, isSmall),
                        ),
                      ),
                    ),

                    const SizedBox(height: 2),

                    // 4. LETTER KEYBOARD (Moved slightly UP)
                    _buildLetterKeyboard(w, isSmall),

                    SizedBox(height: isSmall ? 12 : 18),

                    // 5. BOTTOM CONTROLS (Unified Hint on Left, Unified Replay on Right - Moved slightly DOWN)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          UnifiedHintButton(
                            isSmall: isSmall,
                            onTap: () => _onHint(user),
                          ),
                          UnifiedReplayButton(
                            isSmall: isSmall,
                            onTap: _onReplay,
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: isSmall ? 2 : 4),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // 2. CLUE PANEL WIDGET
  Widget _buildCluePanel(bool isSmall) {
    String directionHeader;
    String clueText;

    if (activeWord != null) {
      directionHeader = "${activeWord!.direction.toUpperCase()} ${activeWord!.number}:";
      clueText = activeWord!.clue;
    } else {
      directionHeader = "SELECT A WORD:";
      clueText = "Tap any cell on the grid to view clue.";
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: isSmall ? 8 : 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1738).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF59E0B), width: 2.2),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 4)),
          BoxShadow(color: Color(0xFFF59E0B), blurRadius: 4, spreadRadius: -2),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Heading (e.g. DOWN 1:) in large gold heading
          Text(
            directionHeader,
            style: TextStyle(
              fontFamily: AppTheme.worldTitle.fontFamily,
              color: const Color(0xFFFFD21C),
              fontSize: isSmall ? 13 : 15,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
              shadows: const [
                Shadow(color: Colors.black, blurRadius: 3, offset: Offset(0, 1.5)),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // Clue text below in large readable white text
          Text(
            clueText,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppTheme.body.fontFamily,
              color: Colors.white,
              fontSize: isSmall ? 12 : 14,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }

  // 3. ENLARGED SPATIAL CROSSWORD GRID WIDGET
  Widget _buildSpatialCrosswordGrid(double availableW, double availableH, bool isSmall) {
    // Dynamic cell size calculation for maximum size without overflow
    final double horizontalMaxCell = (availableW - 32) / math.max(1, cols);
    final double verticalMaxCell = (availableH * 0.42) / math.max(1, rows);
    final double cellSize = math.min(horizontalMaxCell, verticalMaxCell).clamp(38.0, 68.0);

    // Set of valid cell keys ("r_c") belonging to actual words
    final Set<String> wordCellKeys = {};
    for (var w in puzzle.words) {
      for (int i = 0; i < w.answer.length; i++) {
        int r = (w.direction == 'across') ? w.row : w.row + i;
        int c = (w.direction == 'across') ? w.col + i : w.col;
        wordCellKeys.add("${r}_$c");
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(rows, (r) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(cols, (c) {
            String key = "${r}_$c";

            // REQUIREMENT: Render ONLY cells that belong to an actual word!
            // Non-word cells remain completely transparent with NO background tile.
            if (!wordCellKeys.contains(key) && _isBlocked(r, c)) {
              return SizedBox(
                width: cellSize,
                height: cellSize,
              );
            }

            bool isSelectedCell = (r == activeRow && c == activeCol);
            bool isHighlightedWordCell = false;
            if (activeWord != null) {
              if (activeWord!.direction == 'across') {
                isHighlightedWordCell = (r == activeWord!.row && c >= activeWord!.col && c < activeWord!.col + activeWord!.answer.length);
              } else {
                isHighlightedWordCell = (c == activeWord!.col && r >= activeWord!.row && r < activeWord!.row + activeWord!.answer.length);
              }
            }

            String userChar = userGrid[key] ?? '';
            bool isPrefilled = prefilledGrid.containsKey(key);

            // Reference styling matching rules:
            // - Active/selected cursor cell: Vibrant gold fill + white glow outline + dark navy letter text
            // - Active word cells: Rich dark yellow/amber fill + gold border
            // - Other empty/filled crossword cells: Dark navy fill + crisp gold border
            Color tileBg;
            Color borderColor;
            double borderWidth;

            if (isSelectedCell) {
              tileBg = const Color(0xFFFFD21C); // Bright solid gold
              borderColor = Colors.white;
              borderWidth = 2.5;
            } else if (isHighlightedWordCell) {
              tileBg = const Color(0xFF92400E).withValues(alpha: 0.90); // Dark amber highlight
              borderColor = const Color(0xFFFFD21C);
              borderWidth = 2.0;
            } else {
              tileBg = const Color(0xFF0C1838).withValues(alpha: 0.92); // Dark navy cell
              borderColor = const Color(0xFFD97706);
              borderWidth = 1.8;
            }

            // Letter Text Color:
            // Selected cell -> Dark navy
            // Prefilled letter -> Vibrant Cyan/Blue
            // User entered letter -> Bright White
            Color textColor;
            if (isSelectedCell) {
              textColor = const Color(0xFF0C1838);
            } else if (isPrefilled) {
              textColor = const Color(0xFF38BDF8); // Cyan highlight
            } else {
              textColor = Colors.white;
            }

            return GestureDetector(
              onTap: () => _onSpatialCellTap(r, c),
              child: Container(
                width: cellSize,
                height: cellSize,
                margin: const EdgeInsets.all(2.0),
                decoration: BoxDecoration(
                  color: tileBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: borderColor,
                    width: borderWidth,
                  ),
                  boxShadow: isSelectedCell
                      ? const [
                          BoxShadow(color: Color(0xFFFFD21C), blurRadius: 8, spreadRadius: 1),
                          BoxShadow(color: Colors.white, blurRadius: 4),
                        ]
                      : const [
                          BoxShadow(color: Colors.black45, blurRadius: 3, offset: Offset(0, 2)),
                        ],
                ),
                child: Center(
                  child: Text(
                    userChar,
                    style: TextStyle(
                      fontFamily: AppTheme.worldTitle.fontFamily,
                      fontSize: cellSize * 0.52,
                      fontWeight: FontWeight.w900,
                      color: textColor,
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      }),
    );
  }

  // 4. LETTER KEYBOARD WIDGET
  Widget _buildLetterKeyboard(double availableW, bool isSmall) {
    // Dynamic circular key size calculated to evenly space in 1 centered horizontal row
    final int count = levelLetters.length;
    final double maxKeySize = isSmall ? 40.0 : 46.0;
    final double calculatedKeySize = ((availableW - 32 - (count * 6)) / math.max(1, count)).clamp(32.0, maxKeySize);

    return Wrap(
      spacing: 6,
      alignment: WrapAlignment.center,
      children: levelLetters.map((letter) {
        return GestureDetector(
          onTap: () => _onKeyPress(letter),
          child: Container(
            width: calculatedKeySize,
            height: calculatedKeySize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF1D4ED8), Color(0xFF1E3A8A)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              border: Border.all(color: const Color(0xFFFFD21C), width: 2.0),
              boxShadow: const [
                BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2)),
              ],
            ),
            child: Center(
              child: Text(
                letter,
                style: TextStyle(
                  fontFamily: AppTheme.worldTitle.fontFamily,
                  fontSize: calculatedKeySize * 0.48,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  shadows: const [
                    Shadow(color: Colors.black54, blurRadius: 2, offset: Offset(0, 1)),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
