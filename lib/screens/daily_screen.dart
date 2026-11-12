import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../utils/theme.dart';
import '../utils/game_assets.dart';
import '../widgets/game_button.dart';
import '../widgets/responsive_screen.dart';
import 'game_screen.dart';
import '../providers/game_provider.dart';
import '../services/level_service.dart';

class DailyScreen extends StatelessWidget {
  const DailyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, user, child) {
        return ResponsiveScreen(
          backgroundAsset: GameAssets.worldBackground(8),
          hasBottomNav: true,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = MediaQuery.of(context).size.width;
              final h = constraints.maxHeight;

              // Responsive scale helpers
              final isSmall = w < 340;
              final isMid = w < 390;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ── 1. COMPACT HEADER ──────────────────────────────────
                  _DailyHeader(user: user, isSmall: isSmall),

                  SizedBox(height: isSmall ? 4 : 6),

                  // ── 2. HERO CALENDAR + REWARD ──────────────────────────
                  Flexible(
                    flex: 45,
                    child: _DailyHero(user: user, w: w, h: h, isSmall: isSmall, isMid: isMid),
                  ),

                  SizedBox(height: isSmall ? 4 : 8),

                  // ── 3. 7-DAY STREAK TRACKER ────────────────────────────
                  Flexible(
                    flex: 26,
                    child: _StreakTrack(user: user, isSmall: isSmall),
                  ),

                  SizedBox(height: isSmall ? 6 : 10),

                  // ── 4. CTA ─────────────────────────────────────────────
                  _DailyCTA(user: user, context: context, w: w, isSmall: isSmall),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HEADER
// ─────────────────────────────────────────────────────────────────────────────

class _DailyHeader extends StatelessWidget {
  final UserProvider user;
  final bool isSmall;

  const _DailyHeader({required this.user, required this.isSmall});

  @override
  Widget build(BuildContext context) {
    final titleSize = isSmall ? 17.0 : 19.0;
    final streak = user.userData.streak;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Title
        Text(
          'DAILY ADVENTURE',
          style: AppTheme.worldTitle.copyWith(
            fontSize: titleSize,
            letterSpacing: 2.5,
          ),
        ),

        // Streak pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppTheme.deepIndigo.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.gold.withValues(alpha: 0.40),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                GameAssets.dailyStreakFire,
                width: isSmall ? 16 : 18,
                height: isSmall ? 16 : 18,
                fit: BoxFit.contain,
                errorBuilder: (c, e, s) => const SizedBox(width: 18, height: 18),
              ),
              const SizedBox(width: 5),
              Text(
                streak == 0
                    ? 'NO STREAK'
                    : '$streak ${streak == 1 ? "DAY" : "DAYS"}',
                style: AppTheme.smallSecondary.copyWith(
                  color: AppTheme.gold,
                  fontWeight: FontWeight.w900,
                  fontSize: isSmall ? 10 : 11,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HERO: CALENDAR + DATE + REWARD
// ─────────────────────────────────────────────────────────────────────────────

class _DailyHero extends StatelessWidget {
  final UserProvider user;
  final double w;
  final double h;
  final bool isSmall;
  final bool isMid;

  const _DailyHero({
    required this.user,
    required this.w,
    required this.h,
    required this.isSmall,
    required this.isMid,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final day = now.day.toString();
    final months = [
      'JANUARY', 'FEBRUARY', 'MARCH', 'APRIL', 'MAY', 'JUNE',
      'JULY', 'AUGUST', 'SEPTEMBER', 'OCTOBER', 'NOVEMBER', 'DECEMBER'
    ];
    final monthName = months[now.month - 1];

    // Responsive calendar size
    final calSize = isSmall ? 142.0 : (isMid ? 162.0 : 180.0);

    // Responsive date font
    final dateFontSize = isSmall ? 36.0 : (isMid ? 40.0 : 44.0);
    final subtitleSize = isSmall ? 10.0 : 11.0;

    final isCompleted = user.userData.completedDailyToday;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Calendar with date overlay
        SizedBox(
          width: calSize,
          height: calSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Calendar artwork
              Positioned.fill(
                child: Image.asset(
                  GameAssets.dailyCalendar,
                  fit: BoxFit.contain,
                  errorBuilder: (c, e, s) => const SizedBox(),
                ),
              ),
              // Date number — positioned in lower portion of calendar
              Positioned(
                bottom: calSize * 0.12,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      day,
                      style: AppTheme.reward.copyWith(
                        color: AppTheme.deepIndigo,
                        fontSize: dateFontSize,
                        fontWeight: FontWeight.w900,
                        shadows: [],
                        height: 1.0,
                      ),
                    ),
                    Text(
                      monthName,
                      style: AppTheme.smallSecondary.copyWith(
                        color: AppTheme.deepIndigo,
                        fontSize: subtitleSize,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        shadows: [],
                      ),
                    ),
                  ],
                ),
              ),

              // Completed badge
              if (isCompleted)
                Positioned(
                  top: calSize * 0.04,
                  right: calSize * 0.04,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.success,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Text(
                      '✓ DONE',
                      style: AppTheme.smallSecondary.copyWith(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        SizedBox(height: isSmall ? 8 : 10),

        // Reward row
        _RewardRow(isSmall: isSmall, isCompleted: isCompleted),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REWARD ROW
// ─────────────────────────────────────────────────────────────────────────────

class _RewardRow extends StatelessWidget {
  final bool isSmall;
  final bool isCompleted;

  const _RewardRow({required this.isSmall, required this.isCompleted});

  @override
  Widget build(BuildContext context) {
    final iconSize = isSmall ? 22.0 : 26.0;
    final amountSize = isSmall ? 13.0 : 14.0;
    final labelSize = isSmall ? 9.0 : 10.0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 14 : 18,
        vertical: isSmall ? 7 : 8,
      ),
      decoration: BoxDecoration(
        color: AppTheme.deepIndigo.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(
          color: isCompleted
              ? AppTheme.success.withValues(alpha: 0.45)
              : AppTheme.gold.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _RewardItem(
            asset: GameAssets.coin,
            amount: '+100',
            label: 'COINS',
            iconSize: iconSize,
            amountSize: amountSize,
            labelSize: labelSize,
            isCompleted: isCompleted,
          ),
          Container(
            height: isSmall ? 28 : 32,
            width: 1,
            margin: const EdgeInsets.symmetric(horizontal: 14),
            color: Colors.white.withValues(alpha: 0.12),
          ),
          _RewardItem(
            asset: GameAssets.xpGem,
            amount: '+150',
            label: 'XP',
            iconSize: iconSize,
            amountSize: amountSize,
            labelSize: labelSize,
            isCompleted: isCompleted,
          ),
        ],
      ),
    );
  }
}

class _RewardItem extends StatelessWidget {
  final String asset;
  final String amount;
  final String label;
  final double iconSize;
  final double amountSize;
  final double labelSize;
  final bool isCompleted;

  const _RewardItem({
    required this.asset,
    required this.amount,
    required this.label,
    required this.iconSize,
    required this.amountSize,
    required this.labelSize,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          asset,
          width: iconSize,
          height: iconSize,
          fit: BoxFit.contain,
          color: isCompleted ? null : null, // no tint — show artwork as-is
          errorBuilder: (c, e, s) => const SizedBox(),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              amount,
              style: AppTheme.reward.copyWith(
                fontSize: amountSize,
                color: isCompleted
                    ? Colors.white.withValues(alpha: 0.55)
                    : AppTheme.gold,
                shadows: [],
              ),
            ),
            Text(
              label,
              style: AppTheme.smallSecondary.copyWith(
                fontSize: labelSize,
                color: Colors.white.withValues(alpha: 0.55),
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 7-DAY STREAK TRACKER
// ─────────────────────────────────────────────────────────────────────────────

class _StreakTrack extends StatelessWidget {
  final UserProvider user;
  final bool isSmall;

  const _StreakTrack({required this.user, required this.isSmall});

  @override
  Widget build(BuildContext context) {
    final streak = user.userData.streak;
    final completedToday = user.userData.completedDailyToday;

    // Circle diameter responsive
    final circleDiam = isSmall ? 30.0 : 36.0;
    final iconSize = isSmall ? 16.0 : 18.0;
    final dayFontSize = isSmall ? 8.5 : 9.5;
    final titleFontSize = isSmall ? 10.0 : 11.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 10 : 14,
        vertical: isSmall ? 10 : 12,
      ),
      decoration: BoxDecoration(
        color: AppTheme.deepIndigo.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: AppTheme.gold.withValues(alpha: 0.30),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '7 DAY STREAK',
            style: AppTheme.smallSecondary.copyWith(
              color: AppTheme.gold,
              fontSize: titleFontSize,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
            ),
          ),
          SizedBox(height: isSmall ? 8 : 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final dayNum = index + 1;
              // A day is "completed" if it falls within the current streak
              // Today's slot is either current-complete or current-pending
              final isCompletedDay = dayNum <= streak;
              // "Today" slot: the day after the last completed one, unless today is already done
              final todaySlot = completedToday ? streak : streak + 1;
              final isToday = dayNum == todaySlot && dayNum <= 7;
              final isLocked = !isCompletedDay && !isToday;

              return Expanded(
                child: _StreakDayCell(
                  dayNum: dayNum,
                  isCompleted: isCompletedDay,
                  isToday: isToday,
                  isLocked: isLocked,
                  circleDiam: circleDiam,
                  iconSize: iconSize,
                  dayFontSize: dayFontSize,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _StreakDayCell extends StatelessWidget {
  final int dayNum;
  final bool isCompleted;
  final bool isToday;
  final bool isLocked;
  final double circleDiam;
  final double iconSize;
  final double dayFontSize;

  const _StreakDayCell({
    required this.dayNum,
    required this.isCompleted,
    required this.isToday,
    required this.isLocked,
    required this.circleDiam,
    required this.iconSize,
    required this.dayFontSize,
  });

  @override
  Widget build(BuildContext context) {
    // Colors
    final Color circleBg = isCompleted
        ? AppTheme.gold
        : isToday
            ? AppTheme.royalBlue
            : AppTheme.deepIndigo.withValues(alpha: 0.6);

    final Color borderColor = isCompleted
        ? AppTheme.warmGold
        : isToday
            ? AppTheme.sky.withValues(alpha: 0.8)
            : Colors.white.withValues(alpha: 0.12);

    // Asset to render inside circle
    String? iconAsset;
    if (isCompleted) {
      iconAsset = GameAssets.starReward;
    } else if (isToday) {
      iconAsset = GameAssets.dailyStreakFire;
    } else {
      iconAsset = GameAssets.lockIcon;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Circle
        Container(
          width: circleDiam,
          height: circleDiam,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: circleBg,
            border: Border.all(color: borderColor, width: isCompleted || isToday ? 2.0 : 1.5),
            boxShadow: isCompleted
                ? [BoxShadow(color: AppTheme.gold.withValues(alpha: 0.45), blurRadius: 8)]
                : isToday
                    ? [BoxShadow(color: AppTheme.sky.withValues(alpha: 0.30), blurRadius: 6)]
                    : null,
          ),
          child: Center(
            child: Image.asset(
              iconAsset,
              width: iconSize,
              height: iconSize,
              fit: BoxFit.contain,
              errorBuilder: (c, e, s) => const SizedBox(),
            ),
          ),
        ),
        const SizedBox(height: 4),
        // Day label
        Text(
          '$dayNum',
          style: AppTheme.smallSecondary.copyWith(
            fontSize: dayFontSize,
            color: isCompleted
                ? AppTheme.gold
                : isToday
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.30),
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CTA
// ─────────────────────────────────────────────────────────────────────────────

class _DailyCTA extends StatelessWidget {
  final UserProvider user;
  final BuildContext context;
  final double w;
  final bool isSmall;

  const _DailyCTA({
    required this.user,
    required this.context,
    required this.w,
    required this.isSmall,
  });

  @override
  Widget build(BuildContext outerContext) {
    final isCompleted = user.userData.completedDailyToday;
    final btnW = math.min(w - 40, isSmall ? 210.0 : 240.0);
    final btnH = isSmall ? 50.0 : 54.0;
    final fontSize = isSmall ? 16.0 : 18.0;

    if (isCompleted) {
      return Container(
        width: btnW,
        height: btnH,
        decoration: BoxDecoration(
          color: AppTheme.deepIndigo.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(
            color: AppTheme.success.withValues(alpha: 0.50),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              GameAssets.starReward,
              width: isSmall ? 18 : 20,
              height: isSmall ? 18 : 20,
              errorBuilder: (c, e, s) => const SizedBox(),
            ),
            const SizedBox(width: 8),
            Text(
              'COMPLETED FOR TODAY',
              style: AppTheme.smallSecondary.copyWith(
                color: AppTheme.success,
                fontSize: isSmall ? 11 : 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      );
    }

    return GameButton(
      width: btnW,
      height: btnH,
      baseColor: AppTheme.coral,
      shadowColor: const Color(0xFFC0392B),
      onPressed: () {
        final dailyLevel = LevelService.getDailyLevel(DateTime.now());
        Navigator.push(
          outerContext,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                ChangeNotifierProvider(
              create: (_) => GameProvider(dailyLevel.id),
              child: const GameScreen(),
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                FadeTransition(opacity: animation, child: child),
          ),
        );
      },
      child: Text(
        'PLAY TODAY',
        style: AppTheme.body.copyWith(
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
