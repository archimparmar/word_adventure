import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../utils/theme.dart';
import '../utils/game_assets.dart';
import 'dart:math' as math;

class PuzzleBoard extends StatelessWidget {
  const PuzzleBoard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, provider, child) {
        final level = provider.currentLevel;
        final String boardAsset = GameAssets.getBoardPathByDifficulty(level.difficulty);

        return Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(boardAsset),
              fit: BoxFit.fill,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double screenWidth = MediaQuery.of(context).size.width;

              // 1. Dynamic board edge margin (tiles never touch decorative board edges)
              final double boardMargin = screenWidth < 340 ? 12.0 : (screenWidth < 390 ? 16.0 : 20.0);
              const double tileGap = 2.5; // Gap between letters in a word

              List<String> words = List.from(level.requiredWords);
              if (words.isEmpty) return const SizedBox();

              final double availableW = math.max(0, constraints.maxWidth - (boardMargin * 2));
              final double availableH = math.max(0, constraints.maxHeight - (boardMargin * 2));

              // 2. Rule-Based Deterministic Layout Engine
              List<List<String>> rowGroups = _getBalancedRowGroups(words, availableW);
              int numRows = rowGroups.length;

              // Dynamic vertical row gaps based on total rows
              final double rowGap = numRows >= 7
                  ? 4.5
                  : (numRows >= 5 ? 6.5 : (numRows == 4 ? 9.0 : 12.0));

              // 3. Progressive Target Tile Size Scaling based on Word Count
              double maxTargetTileSize;
              if (words.length <= 6) {
                maxTargetTileSize = screenWidth < 340 ? 25.0 : (screenWidth < 385 ? 28.0 : 32.0);
              } else if (words.length <= 10) {
                maxTargetTileSize = screenWidth < 340 ? 22.0 : (screenWidth < 385 ? 25.0 : 28.0);
              } else {
                maxTargetTileSize = screenWidth < 340 ? 19.0 : (screenWidth < 385 ? 22.0 : 24.0);
              }

              // 4. Calculate optimal tile size to fit all rows inside available width and height
              double chosenTileSize = maxTargetTileSize;

              for (List<String> group in rowGroups) {
                int totalLetters = group.fold(0, (sum, w) => sum + w.length);
                int wordCount = group.length;
                double minColGap = wordCount > 1 ? 14.0 : 0.0;
                double fixedGaps = ((totalLetters - wordCount) * tileGap) + ((wordCount - 1) * minColGap);
                double maxTileForGroup = (availableW - fixedGaps) / math.max(1, totalLetters);
                chosenTileSize = math.min(chosenTileSize, maxTileForGroup);
              }

              // Check vertical fit constraints
              double totalRequiredH = (numRows * chosenTileSize) + ((numRows - 1) * rowGap);
              if (totalRequiredH > availableH) {
                chosenTileSize = (availableH - ((numRows - 1) * rowGap)) / numRows;
              }

              // Never drop below 15.0px so letters remain clearly readable
              chosenTileSize = chosenTileSize.clamp(15.0, maxTargetTileSize);

              // 5. Build row widgets
              List<Widget> rowWidgets = rowGroups.map((group) {
                if (group.length == 1) {
                  // Single word row -> Centered
                  return _buildWordRow(group[0], provider, chosenTileSize, tileGap);
                } else {
                  // Multi-word row -> Balanced Spacing
                  int totalLetters = group.fold(0, (sum, w) => sum + w.length);
                  double totalLettersWidth = totalLetters * chosenTileSize + ((totalLetters - group.length) * tileGap);
                  double totalGapSpace = availableW - totalLettersWidth;
                  double colGap = math.max(14.0, totalGapSpace / (group.length + 1));

                  List<Widget> wordWidgets = group
                      .map((word) => _buildWordRow(word, provider, chosenTileSize, tileGap))
                      .toList();

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: wordWidgets
                        .expand((w) => [w, SizedBox(width: colGap)])
                        .toList()
                      ..removeLast(),
                  );
                }
              }).toList();

              return Center(
                child: Padding(
                  padding: EdgeInsets.all(boardMargin),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: rowWidgets
                        .expand((rw) => [rw, SizedBox(height: rowGap)])
                        .toList()
                      ..removeLast(),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ── RULE-BASED RESPONSIVE TILE LAYOUT ENGINE ──────────────────────────────
  List<List<String>> _getBalancedRowGroups(List<String> words, double availableWidth) {
    int count = words.length;
    if (count == 0) return [];

    // RULE 1: 4 WORDS -> 4 vertical centered rows
    if (count == 4) {
      return words.map((w) => [w]).toList();
    }

    // RULE 2: 5 WORDS -> 5 vertical centered rows
    if (count == 5) {
      return words.map((w) => [w]).toList();
    }

    // RULE 3: 6 WORDS -> Structured 2 / 2 / 1 / 1 arrangement
    if (count == 6) {
      List<int> lengths = words.map((w) => w.length).toList();
      if (lengths[0] <= 5 && lengths[1] <= 5 && lengths[2] <= 5 && lengths[3] <= 5) {
        return [
          [words[0], words[1]],
          [words[2], words[3]],
          [words[4]],
          [words[5]],
        ];
      }
    }

    // RULE 4: DENSE LAYOUT ENGINE FOR 7-10 WORDS AND 11+ WORDS
    // Strict constraint: For 7-10 words, MAXIMUM 2 WORDS PER ROW!
    final int maxWordsInRow = count >= 11 ? 3 : 2;

    List<List<String>> rows = [];
    List<String> currentRow = [];

    for (int i = 0; i < words.length; i++) {
      String w = words[i];

      // Long words (7+ letters) ALWAYS occupy their own full centered row
      if (w.length >= 7) {
        if (currentRow.isNotEmpty) {
          rows.add(List.from(currentRow));
          currentRow.clear();
        }
        rows.add([w]);
        continue;
      }

      if (currentRow.isEmpty) {
        currentRow.add(w);
      } else {
        int currentLetters = currentRow.fold(0, (sum, item) => sum + item.length);
        
        bool canAdd = false;
        if (currentRow.length < maxWordsInRow) {
          if (maxWordsInRow == 2) {
            canAdd = (currentLetters + w.length <= 10);
          } else {
            // For 11+ words, 3 words per row allowed only if total letters <= 10 and each word <= 4 letters
            canAdd = (currentRow.length < 2 && currentLetters + w.length <= 10) ||
                     (currentRow.length == 2 && currentLetters + w.length <= 10 && w.length <= 4);
          }
        }

        if (canAdd) {
          currentRow.add(w);
        } else {
          rows.add(List.from(currentRow));
          currentRow.clear();
          currentRow.add(w);
        }
      }
    }

    if (currentRow.isNotEmpty) {
      rows.add(List.from(currentRow));
    }

    // Compress rows if needed while respecting maxWordsInRow strictly
    if (rows.length > 7) {
      List<List<String>> compressedRows = [];
      for (int i = 0; i < rows.length; i++) {
        if (compressedRows.isEmpty) {
          compressedRows.add(rows[i]);
        } else {
          var lastRow = compressedRows.last;
          int lastLetters = lastRow.fold(0, (sum, item) => sum + item.length);
          int thisLetters = rows[i].fold(0, (sum, item) => sum + item.length);

          if (lastRow.length + rows[i].length <= maxWordsInRow && lastLetters + thisLetters <= 10) {
            lastRow.addAll(rows[i]);
          } else {
            compressedRows.add(rows[i]);
          }
        }
      }
      rows = compressedRows;
    }

    return rows;
  }

  Widget _buildWordRow(String word, GameProvider provider, double tileSize, double tileGap) {
    bool isRevealed = provider.foundWords.contains(word);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(word.length, (i) {
        bool isHint = provider.hintedCells.contains('${word}_$i');
        bool active = isRevealed || isHint;

        String displayLetter = active ? word[i] : '';
        String tileImage = active ? GameAssets.tileNormal : GameAssets.tileEmpty;

        return Container(
          width: tileSize,
          height: tileSize,
          margin: i < word.length - 1 ? EdgeInsets.only(right: tileGap) : EdgeInsets.zero,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(tileImage),
              fit: BoxFit.contain,
            ),
            boxShadow: active
                ? const [BoxShadow(color: Colors.black26, blurRadius: 3, offset: Offset(0, 2))]
                : null,
          ),
          child: Center(
            child: Text(
              displayLetter,
              style: TextStyle(
                fontFamily: AppTheme.body.fontFamily,
                fontSize: tileSize * 0.68,
                color: AppTheme.deepIndigo,
                fontWeight: FontWeight.w900,
                height: 1.0,
              ),
            ),
          ),
        );
      }),
    );
  }
}
