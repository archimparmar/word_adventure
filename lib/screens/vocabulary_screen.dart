import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../services/level_service.dart';
import '../utils/theme.dart';
import '../utils/game_assets.dart';
import '../widgets/game_button.dart';
import '../widgets/responsive_screen.dart';

class VocabularyScreen extends StatefulWidget {
  const VocabularyScreen({super.key});

  @override
  State<VocabularyScreen> createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends State<VocabularyScreen> {
  // Track expanded state of letter groups in local UI state
  final Set<String> _expandedLetters = {};
  bool _hasInitializedExpansion = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        final List<String> discovered = userProvider
            .userData.discoveredVocabulary
            .toSet()
            .toList()
          ..sort();
        final List<String> totalVocabulary = LevelService.allVocabulary;
        final int totalCount =
            totalVocabulary.isEmpty ? 100 : totalVocabulary.length;
        final double percent = (discovered.length / totalCount).clamp(0.0, 1.0);

        // Group discovered words by first letter
        Map<String, List<String>> grouped = {};
        for (String word in discovered) {
          if (word.isEmpty) continue;
          String firstLetter = word[0].toUpperCase();
          grouped.putIfAbsent(firstLetter, () => []).add(word);
        }

        final sortedLetters = grouped.keys.toList()..sort();

        // Initialize expansion state: expand first letter group by default
        if (!_hasInitializedExpansion && sortedLetters.isNotEmpty) {
          _expandedLetters.add(sortedLetters.first);
          _hasInitializedExpansion = true;
        }

        return ResponsiveScreen(
          backgroundAsset: GameAssets.vocabularyBackground,
          hasBottomNav: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final h = constraints.maxHeight;

              final isSmall = w < 340 || h < 500;

              return Column(
                children: [
                  // ── 1. FIXED COMPACT HEADER ────────────────────────────
                  _buildHeader(context, isSmall),

                  SizedBox(height: isSmall ? 6 : 10),

                  // ── 2. FIXED COMPACT DISCOVERY SUMMARY ─────────────────
                  _buildSummaryCard(
                    discovered.length,
                    totalCount,
                    percent,
                    isSmall,
                  ),

                  SizedBox(height: isSmall ? 8 : 12),

                  // ── 3. EXPANDED SCROLLABLE WORD COLLECTION ─────────────
                  Expanded(
                    child: discovered.isEmpty
                        ? _buildEmptyState(isSmall)
                        : _buildScrollableCollection(
                            sortedLetters,
                            grouped,
                            isSmall,
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

  // ── HEADER ─────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, bool isSmall) {
    final titleSize = isSmall ? 17.0 : 19.0;
    final btnSize = isSmall ? 40.0 : 44.0;
    final iconSize = isSmall ? 20.0 : 22.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Back Button (Min 44px touch target)
        GameButton(
          width: btnSize,
          height: btnSize,
          isRounded: true,
          baseColor: AppTheme.deepIndigo.withValues(alpha: 0.8),
          shadowColor: Colors.black45,
          onPressed: () => Navigator.pop(context),
          child: Image.asset(
            GameAssets.backButton,
            width: iconSize,
            height: iconSize,
            color: Colors.white,
            errorBuilder: (c, e, s) =>
                const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          ),
        ),

        // Screen Title
        Text(
          'MY VOCABULARY',
          style: AppTheme.worldTitle.copyWith(
            fontSize: titleSize,
            letterSpacing: 2.2,
          ),
        ),

        // Header Accent: Map Scroll Graphic
        Image.asset(
          GameAssets.mapScroll,
          width: isSmall ? 32 : 38,
          height: isSmall ? 32 : 38,
          fit: BoxFit.contain,
          errorBuilder: (c, e, s) => const SizedBox(width: 38),
        ),
      ],
    );
  }

  // ── DISCOVERY SUMMARY CARD ──────────────────────────────────────────
  Widget _buildSummaryCard(
    int discoveredCount,
    int totalCount,
    double percent,
    bool isSmall,
  ) {
    return Container(
      padding: EdgeInsets.all(isSmall ? 10 : 14),
      decoration: BoxDecoration(
        color: AppTheme.deepIndigo.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(
          color: AppTheme.gold.withValues(alpha: 0.40),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Count Badge with Star Graphic
              Row(
                children: [
                  Image.asset(
                    GameAssets.starReward,
                    width: isSmall ? 18 : 22,
                    height: isSmall ? 18 : 22,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$discoveredCount / $totalCount WORDS',
                    style: TextStyle(
                      fontFamily: AppTheme.body.fontFamily,
                      color: AppTheme.gold,
                      fontWeight: FontWeight.w900,
                      fontSize: isSmall ? 12 : 13.5,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),

              // Percentage Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.gold.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.gold.withValues(alpha: 0.50),
                    width: 1.0,
                  ),
                ),
                child: Text(
                  '${(percent * 100).toStringAsFixed(1)}%',
                  style: AppTheme.smallSecondary.copyWith(
                    color: AppTheme.gold,
                    fontWeight: FontWeight.w900,
                    fontSize: isSmall ? 10.5 : 11.5,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isSmall ? 8 : 10),

          // Mastery Progress Bar
          Container(
            height: isSmall ? 8 : 10,
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: AppTheme.gold.withValues(alpha: 0.3),
                width: 1.0,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: LinearProgressIndicator(
                value: percent,
                backgroundColor: Colors.transparent,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppTheme.success),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── SCROLLABLE COLLECTION REGION ────────────────────────────────────
  Widget _buildScrollableCollection(
    List<String> sortedLetters,
    Map<String, List<String>> grouped,
    bool isSmall,
  ) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(bottom: isSmall ? 16 : 24),
      itemCount: sortedLetters.length,
      itemBuilder: (context, index) {
        String letter = sortedLetters[index];
        List<String> words = grouped[letter]!..sort();
        bool isExpanded = _expandedLetters.contains(letter);

        return _buildLetterGroup(letter, words, isExpanded, isSmall);
      },
    );
  }

  // ── LETTER GROUP ITEM ────────────────────────────────────────────────
  Widget _buildLetterGroup(
    String letter,
    List<String> words,
    bool isExpanded,
    bool isSmall,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.deepIndigo.withValues(alpha: 0.80),
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Expandable Letter Header
          InkWell(
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedLetters.remove(letter);
                } else {
                  _expandedLetters.add(letter);
                }
              });
            },
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isSmall ? 10 : 14,
                vertical: isSmall ? 8 : 10,
              ),
              child: Row(
                children: [
                  // Letter Icon Pill
                  Container(
                    width: isSmall ? 32 : 36,
                    height: isSmall ? 32 : 36,
                    decoration: BoxDecoration(
                      color: AppTheme.gold,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      letter,
                      style: AppTheme.worldTitle.copyWith(
                        color: AppTheme.deepIndigo,
                        fontSize: isSmall ? 14 : 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Words Count Label
                  Text(
                    '${words.length} ${words.length == 1 ? 'WORD' : 'WORDS'}',
                    style: AppTheme.worldTitle.copyWith(
                      color: AppTheme.gold,
                      fontSize: isSmall ? 12 : 13.5,
                      letterSpacing: 1.0,
                    ),
                  ),

                  const Spacer(),

                  // Expand/Collapse Chevron Indicator
                  AnimatedRotation(
                    turns: isExpanded ? 0.25 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.chevron_right_rounded,
                      color: AppTheme.gold,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expanded Discovered Words Chips
          if (isExpanded)
            Padding(
              padding: EdgeInsets.only(
                left: isSmall ? 10 : 14,
                right: isSmall ? 10 : 14,
                bottom: isSmall ? 10 : 12,
                top: 4,
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: words.map((word) {
                  return Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmall ? 10 : 12,
                      vertical: isSmall ? 6 : 7,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.success,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF1B9954),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 3,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      word,
                      style: AppTheme.worldTitle.copyWith(
                        color: Colors.white,
                        letterSpacing: 1.2,
                        fontSize: isSmall ? 11.5 : 13.0,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  // ── EMPTY STATE ─────────────────────────────────────────────────────
  Widget _buildEmptyState(bool isSmall) {
    return Center(
      child: Container(
        margin: EdgeInsets.all(isSmall ? 16 : 24),
        padding: EdgeInsets.all(isSmall ? 20 : 28),
        decoration: BoxDecoration(
          color: AppTheme.deepIndigo.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          border: Border.all(
            color: AppTheme.gold.withValues(alpha: 0.35),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              GameAssets.profileIcon,
              width: isSmall ? 56 : 68,
              height: isSmall ? 56 : 68,
              fit: BoxFit.contain,
              errorBuilder: (c, e, s) =>
                  const Icon(Icons.explore_rounded, color: AppTheme.gold, size: 56),
            ),
            SizedBox(height: isSmall ? 12 : 16),
            Text(
              'NO WORDS DISCOVERED YET',
              textAlign: TextAlign.center,
              style: AppTheme.worldTitle.copyWith(
                color: AppTheme.gold,
                fontSize: isSmall ? 14 : 16,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Play puzzle levels to discover words and build your adventure vocabulary collection!',
              textAlign: TextAlign.center,
              style: AppTheme.body.copyWith(
                color: Colors.white70,
                fontSize: isSmall ? 11.5 : 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
