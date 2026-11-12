import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../utils/theme.dart';
import '../utils/game_assets.dart';
import '../services/audio_service.dart';

class CircularGameButton extends StatelessWidget {
  final Widget child;
  final double circleSize;
  final VoidCallback onTap;

  const CircularGameButton({
    super.key,
    required this.child,
    required this.circleSize,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        AudioService().playButtonTap();
        onTap();
      },
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
}

class UnifiedBackButton extends StatelessWidget {
  final bool isSmall;
  final VoidCallback? onTap;

  const UnifiedBackButton({
    super.key,
    required this.isSmall,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final double buttonSize = isSmall ? 46.0 : 52.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        AudioService().playButtonTap();
        (onTap ?? () => Navigator.pop(context))();
      },
      child: Image.asset(
        GameAssets.backButton,
        width: buttonSize,
        height: buttonSize,
        fit: BoxFit.contain,
      ),
    );
  }
}

class UnifiedHeaderRow extends StatelessWidget {
  final int levelId;
  final bool isSmall;
  final VoidCallback? onBackTap;
  final String? customTitle;

  const UnifiedHeaderRow({
    super.key,
    required this.levelId,
    required this.isSmall,
    this.onBackTap,
    this.customTitle,
  });

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Back Button
          UnifiedBackButton(
            isSmall: isSmall,
            onTap: onBackTap,
          ),

          // Center Level Text
          Text(
            customTitle ?? (levelId < 0 ? 'DAILY' : 'LEVEL $levelId'),
            style: AppTheme.worldTitle.copyWith(
              fontSize: isSmall ? 15.0 : 18.0,
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

          // Coins HUD Badge
          Container(
            height: 34,
            padding: EdgeInsets.symmetric(horizontal: isSmall ? 8 : 12),
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
                    fontSize: isSmall ? 13.0 : 14.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class UnifiedHintButton extends StatelessWidget {
  final bool isSmall;
  final VoidCallback onTap;

  const UnifiedHintButton({
    super.key,
    required this.isSmall,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final double buttonSize = isSmall ? 38.0 : 46.0;
    final double circleSize = math.max(48.0, buttonSize + 6.0);

    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        int hintsAvailable = userProvider.userData.hints;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            CircularGameButton(
              circleSize: circleSize,
              onTap: onTap,
              child: Image.asset(
                GameAssets.hintBulb,
                width: circleSize * 0.62,
                height: circleSize * 0.62,
                fit: BoxFit.contain,
              ),
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
}

class UnifiedClearButton extends StatelessWidget {
  final bool isSmall;
  final VoidCallback onTap;

  const UnifiedClearButton({
    super.key,
    required this.isSmall,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final double buttonSize = isSmall ? 38.0 : 46.0;
    final double circleSize = math.max(48.0, buttonSize + 6.0);

    return CircularGameButton(
      circleSize: circleSize,
      onTap: onTap,
      child: Icon(
        Icons.backspace_rounded,
        color: Colors.white,
        size: circleSize * 0.52,
      ),
    );
  }
}

class UnifiedReplayButton extends StatelessWidget {
  final bool isSmall;
  final VoidCallback onTap;

  const UnifiedReplayButton({
    super.key,
    required this.isSmall,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final double buttonSize = isSmall ? 38.0 : 46.0;
    final double circleSize = math.max(48.0, buttonSize + 6.0);

    return CircularGameButton(
      circleSize: circleSize,
      onTap: onTap,
      child: Icon(
        Icons.replay_rounded,
        color: Colors.white,
        size: circleSize * 0.54,
      ),
    );
  }
}
