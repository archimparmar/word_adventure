import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/level.dart';
import '../providers/user_provider.dart';
import '../utils/theme.dart';
import '../utils/game_assets.dart';
import '../widgets/game_button.dart';
import 'game_screen.dart';
import '../providers/game_provider.dart';
import '../services/audio_service.dart';
import '../services/ad_service.dart';
import '../services/notification_service.dart';

class CompletionScreen extends StatefulWidget {
  final Level level;
  final bool perfect;
  final bool isDaily;
  final int bonusCount;

  const CompletionScreen({
    super.key,
    required this.level,
    this.perfect = false,
    this.isDaily = false,
    this.bonusCount = 0,
  });

  @override
  State<CompletionScreen> createState() => _CompletionScreenState();
}

class _CompletionScreenState extends State<CompletionScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const ElasticOutCurve(0.85)),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.4, curve: Curves.easeIn)),
    );
    _controller.forward();
    if (widget.isDaily) {
      AudioService().playDailyChallengeComplete();
    } else {
      AudioService().playLevelComplete();
    }

    // Show Interstitial Ad on level completion (subject to rate limit cooldown)
    AdService().showInterstitialAd();

    // Request Notification permission after completing level 1 (appropriate time)
    if (widget.level.id == 1 && !widget.isDaily) {
      NotificationService().requestPermissions();
    }
  }


  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onNextLevel(BuildContext context, UserProvider userProvider) {
    if (widget.isDaily) {
      Navigator.pop(context);
      return;
    }

    int nextLevelId = userProvider.userData.currentLevel;
    if (widget.level.id >= 300) {
      nextLevelId = 300;
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => ChangeNotifierProvider(
          create: (_) => GameProvider(nextLevelId),
          child: const GameScreen(),
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _onReplay(BuildContext context) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => ChangeNotifierProvider(
          create: (_) => GameProvider(widget.level.id),
          child: const GameScreen(),
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _onHome(BuildContext context) {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final isLastLevel = !widget.isDaily && widget.level.id >= 300;
    final screenWidth = MediaQuery.of(context).size.width;
    final starSize = (screenWidth * 0.13).clamp(36.0, 52.0);

    return Scaffold(
      body: Stack(
        children: [
          // Background Artwork
          Positioned.fill(
            child: Image.asset(
              GameAssets.completionBackground,
              fit: BoxFit.cover,
            ),
          ),

          // Subtle Dark Backdrop Overlay
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.35),
            ),
          ),

          SafeArea(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: child,
                  ),
                );
              },
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Subheader Level Title
                      Text(
                        widget.isDaily
                            ? 'DAILY ADVENTURE'
                            : (isLastLevel ? 'GRAND FINALE!' : 'LEVEL ${widget.level.id}'),
                        style: AppTheme.worldTitle.copyWith(
                          fontSize: (screenWidth * 0.05).clamp(16.0, 20.0),
                          letterSpacing: 3,
                          color: const Color(0xFFF2C14E),
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Main Completion Banner Title
                      Text(
                        isLastLevel ? '300 LEVELS SOLVED!' : 'LEVEL COMPLETE!',
                        textAlign: TextAlign.center,
                        style: AppTheme.reward.copyWith(
                          fontSize: isLastLevel
                              ? (screenWidth * 0.07).clamp(24.0, 32.0)
                              : (screenWidth * 0.085).clamp(28.0, 38.0),
                          letterSpacing: 2,
                          color: AppTheme.gold,
                          shadows: [
                            const Shadow(
                              color: Colors.black54,
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Three Stars Component - Exactly 3 stars, properly spaced and responsive
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Image.asset(
                              GameAssets.starReward,
                              width: starSize,
                              height: starSize,
                              fit: BoxFit.contain,
                            ),
                          );
                        }),
                      ),

                      const SizedBox(height: 10),

                      // Sub-celebration message
                      Text(
                        widget.perfect ? 'PERFECT SOLVE!' : 'GREAT JOB!',
                        style: AppTheme.body.copyWith(
                          fontSize: (screenWidth * 0.045).clamp(14.0, 18.0),
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFFF2C14E),
                          letterSpacing: 2,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Compact Reward & Stats Panel
                      Container(
                        constraints: const BoxConstraints(maxWidth: 340),
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                        decoration: BoxDecoration(
                          color: const Color(0xF7142217), // Deep warm forest green
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFD9A62E), // Warm gold border
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.45),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Required Words Summary
                            _buildStatRow(
                              'REQUIRED WORDS',
                              '${widget.level.requiredWords.length} / ${widget.level.requiredWords.length}',
                            ),

                            // Optional Bonus Words Summary
                            if (widget.bonusCount > 0) ...[
                              const SizedBox(height: 4),
                              _buildStatRow(
                                'BONUS WORDS FOUND',
                                '+${widget.bonusCount}',
                                isHighlight: true,
                              ),
                            ],

                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Divider(color: Color(0x33D9A62E), thickness: 1),
                            ),

                            // Currency Rewards Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildRewardBox(
                                  GameAssets.coin,
                                  '+${widget.level.reward + (widget.perfect ? 10 : 0)}',
                                  'COINS',
                                ),
                                _buildRewardBox(GameAssets.xpGem, '+100', 'XP'),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Actions Hierarchy (NEXT LEVEL / REPLAY / HOME)
                      Column(
                        children: [
                          if (!isLastLevel) ...[
                            // Primary CTA: NEXT LEVEL
                            GameButton(
                              width: (screenWidth * 0.6).clamp(180.0, 220.0),
                              height: 50,
                              baseColor: AppTheme.success,
                              shadowColor: const Color(0xFF1B9954),
                              onPressed: () => _onNextLevel(context, userProvider),
                              child: Text(
                                widget.isDaily ? 'BACK TO DAILY' : 'NEXT LEVEL',
                                style: AppTheme.body.copyWith(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Secondary CTA: REPLAY
                          GameButton(
                            width: (screenWidth * 0.6).clamp(180.0, 220.0),
                            height: 46,
                            baseColor: const Color(0xFF263A22),
                            shadowColor: const Color(0xFF18251B),
                            onPressed: () => _onReplay(context),
                            child: Text(
                              'REPLAY',
                              style: AppTheme.body.copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFFF2C14E),
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Tertiary Link: HOME
                          TextButton(
                            onPressed: () => _onHome(context),
                            child: Text(
                              'HOME',
                              style: TextStyle(
                                fontFamily: AppTheme.body.fontFamily,
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTheme.smallSecondary.copyWith(
            fontSize: 13,
            color: Colors.white70,
            letterSpacing: 0.5,
          ),
        ),
        Text(
          value,
          style: AppTheme.body.copyWith(
            color: isHighlight ? const Color(0xFFF2C14E) : Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _buildRewardBox(String imagePath, String amount, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(imagePath, width: 26, height: 26, errorBuilder: (c, e, s) => const SizedBox()),
        const SizedBox(width: 8),
        Text(
          amount,
          style: AppTheme.reward.copyWith(
            fontSize: 20,
            color: const Color(0xFFF2C14E),
          ),
        ),
      ],
    );
  }
}
