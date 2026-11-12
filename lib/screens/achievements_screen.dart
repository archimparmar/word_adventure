import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../models/user_data.dart';
import '../utils/theme.dart';
import '../utils/game_assets.dart';
import '../widgets/responsive_screen.dart';
import '../services/audio_service.dart';

class Achievement {
  final String title;
  final String description;
  final int currentProgress;
  final int requiredProgress;
  final String iconAsset;

  Achievement({
    required this.title,
    required this.description,
    required this.currentProgress,
    required this.requiredProgress,
    required this.iconAsset,
  });

  bool get isUnlocked => currentProgress >= requiredProgress;
  double get progressRatio => (currentProgress / requiredProgress).clamp(0.0, 1.0);
}

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  List<Achievement> _getAchievements(UserData data) {
    return [
      Achievement(
        title: "Novice Explorer",
        description: "Reach Player Level 5",
        currentProgress: data.playerLevel,
        requiredProgress: 5,
        iconAsset: GameAssets.xpGem,
      ),
      Achievement(
        title: "Wordsmith",
        description: "Find 100 words",
        currentProgress: data.wordsFound,
        requiredProgress: 100,
        iconAsset: GameAssets.starReward,
      ),
      Achievement(
        title: "Dedicated",
        description: "Achieve a 7-day streak",
        currentProgress: data.bestStreak,
        requiredProgress: 7,
        iconAsset: GameAssets.dailyStreakFire,
      ),
      Achievement(
        title: "Perfectionist",
        description: "Complete 10 levels perfectly",
        currentProgress: data.perfectLevels,
        requiredProgress: 10,
        iconAsset: GameAssets.openedChest,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, user, child) {
        final achievements = _getAchievements(user.userData);
        if (achievements.any((a) => a.isUnlocked)) {
          AudioService().playAchievementUnlock();
        }

        return ResponsiveScreen(
          backgroundAsset: GameAssets.profileBackground,
          blurBackground: true,
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount: achievements.length,
                  itemBuilder: (context, index) {
                    final achievement = achievements[index];
                    return _buildAchievementCard(achievement);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Proper Back Button (Min 44x44 target, standard game asset without white tint)
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
        Text(
          'ACHIEVEMENTS',
          style: AppTheme.worldTitle.copyWith(fontSize: 18, letterSpacing: 1.5),
        ),
        const SizedBox(width: 44), // Balances the row
      ],
    );
  }

  Widget _buildAchievementCard(Achievement achievement) {
    final bool unlocked = achievement.isUnlocked;
    final bool inProgress = !unlocked && achievement.currentProgress > 0;

    Color cardBg;
    Color borderColor;
    Color badgeColor;
    String badgeText;
    Color progressColor;
    Color textColor;

    if (unlocked) {
      cardBg = AppTheme.deepIndigo.withValues(alpha: 0.92);
      borderColor = AppTheme.gold;
      badgeColor = AppTheme.success;
      badgeText = 'UNLOCKED ✓';
      progressColor = AppTheme.success;
      textColor = AppTheme.gold;
    } else if (inProgress) {
      cardBg = AppTheme.deepIndigo.withValues(alpha: 0.82);
      borderColor = AppTheme.sky.withValues(alpha: 0.70);
      badgeColor = AppTheme.sky;
      badgeText = 'IN PROGRESS';
      progressColor = AppTheme.sky;
      textColor = Colors.white;
    } else {
      cardBg = const Color(0xFF10152F).withValues(alpha: 0.55);
      borderColor = Colors.white.withValues(alpha: 0.12);
      badgeColor = Colors.black45;
      badgeText = 'LOCKED';
      progressColor = Colors.white24;
      textColor = Colors.white60;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: unlocked ? 1.8 : 1.0,
        ),
        boxShadow: unlocked
            ? [
                BoxShadow(
                  color: AppTheme.gold.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          // Icon Container
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: unlocked
                  ? AppTheme.gold.withValues(alpha: 0.25)
                  : inProgress
                      ? AppTheme.sky.withValues(alpha: 0.20)
                      : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: unlocked ? AppTheme.warmGold : inProgress ? AppTheme.sky : Colors.white12,
              ),
            ),
            padding: const EdgeInsets.all(8),
            child: Image.asset(
              achievement.iconAsset,
              fit: BoxFit.contain,
              errorBuilder: (c, e, s) => Icon(
                Icons.emoji_events_rounded,
                color: unlocked ? AppTheme.gold : inProgress ? AppTheme.sky : Colors.white38,
                size: 26,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Details & Progress
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        achievement.title.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.worldTitle.copyWith(
                          color: textColor,
                          fontSize: 13.5,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        badgeText,
                        style: AppTheme.smallSecondary.copyWith(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  achievement.description,
                  style: AppTheme.smallSecondary.copyWith(
                    color: unlocked || inProgress ? Colors.white.withValues(alpha: 0.85) : Colors.white38,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 8),

                // Progress Bar & Ratio Text
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: achievement.progressRatio,
                            backgroundColor: Colors.transparent,
                            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${achievement.currentProgress}/${achievement.requiredProgress}',
                      style: AppTheme.smallSecondary.copyWith(
                        color: unlocked ? AppTheme.gold : inProgress ? AppTheme.sky : Colors.white54,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
