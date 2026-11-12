import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/game_provider.dart';
import '../services/level_service.dart';
import '../utils/theme.dart';
import '../utils/game_assets.dart';
import '../widgets/game_button.dart';
import '../screens/game_screen.dart';

class DailyChallengeModal extends StatelessWidget {
  const DailyChallengeModal({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, user, child) {
        final isCompleted = user.userData.completedDailyToday;
        final streak = user.userData.streak;
        final now = DateTime.now();

        final dayNum = LevelService.getDailyDayNumber(now);
        final dateStr = "DAY $dayNum • ${now.day} ${_getMonthName(now.month)} ${now.year}";

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF16251A).withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFFD9A62E).withValues(alpha: 0.65),
                width: 2.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DAILY ADVENTURE',
                          style: AppTheme.worldTitle.copyWith(
                            fontSize: 18,
                            letterSpacing: 2,
                            color: AppTheme.gold,
                          ),
                        ),
                        Text(
                          'DAY $dayNum OF 100',
                          style: AppTheme.smallSecondary.copyWith(
                            fontSize: 11,
                            color: const Color(0xFFF2C14E),
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                        child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Calendar & Streak Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF203626).withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF5B7A42).withValues(alpha: 0.40)),
                  ),
                  child: Row(
                    children: [
                      // Day Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.gold,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'DAY',
                              style: AppTheme.smallSecondary.copyWith(
                                color: AppTheme.deepIndigo,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              '$dayNum',
                              style: AppTheme.worldTitle.copyWith(
                                color: AppTheme.deepIndigo,
                                fontSize: 20,
                                height: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dateStr,
                              style: AppTheme.body.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Image.asset(
                                  GameAssets.dailyStreakFire,
                                  width: 18,
                                  height: 18,
                                  errorBuilder: (c, e, s) => const Icon(Icons.local_fire_department, color: Colors.orange, size: 18),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$streak DAY STREAK',
                                  style: AppTheme.smallSecondary.copyWith(
                                    color: AppTheme.gold,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Reward Details
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Row(
                        children: [
                          Image.asset(GameAssets.coin, width: 20, height: 20),
                          const SizedBox(width: 6),
                          Text('+100 COINS', style: AppTheme.body.copyWith(color: AppTheme.gold, fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                      Row(
                        children: [
                          Image.asset(GameAssets.xpGem, width: 20, height: 20, errorBuilder: (c,e,s) => const SizedBox()),
                          const SizedBox(width: 6),
                          Text('+150 XP', style: AppTheme.body.copyWith(color: AppTheme.sky, fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // PLAY CTA
                if (isCompleted)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.success.withValues(alpha: 0.60)),
                    ),
                    child: Text(
                      'COMPLETED FOR TODAY ✓',
                      textAlign: TextAlign.center,
                      style: AppTheme.smallSecondary.copyWith(
                        color: AppTheme.success,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  )
                else
                  GameButton(
                    width: double.infinity,
                    height: 48,
                    baseColor: AppTheme.coral,
                    shadowColor: const Color(0xFFC0392B),
                    onPressed: () {
                      Navigator.pop(context); // Close modal
                      final dailyLevel = LevelService.getDailyLevel(DateTime.now());
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChangeNotifierProvider(
                            create: (_) => GameProvider(dailyLevel.id),
                            child: const GameScreen(),
                          ),
                        ),
                      );
                    },
                    child: Text(
                      "PLAY TODAY'S CHALLENGE",
                      style: AppTheme.body.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 13.5,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getMonthName(int month) {
    const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    return months[(month - 1).clamp(0, 11)];
  }
}
