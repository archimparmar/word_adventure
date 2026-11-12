import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../utils/theme.dart';
import '../utils/game_assets.dart';
import '../widgets/game_button.dart';
import '../widgets/responsive_screen.dart';
import '../services/audio_service.dart';
import '../services/ad_service.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, user, child) {
        return ResponsiveScreen(
          backgroundAsset: GameAssets.shopBackground,
          hasBottomNav: false,
          blurBackground: true,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final h = constraints.maxHeight;
              final isSmall = w < 340 || h < 550;

              return Column(
                children: [
                  // 1. TOP HUD & TREASURE STORE BANNER
                  _buildTopHeader(context, user, isSmall),

                  SizedBox(height: isSmall ? 12 : 18),

                  // 2. SCROLLABLE SHOP PRODUCTS
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // HINT BOOSTERS (BUY WITH COINS)
                          _buildSectionHeader(
                            'HINT BOOSTERS',
                            GameAssets.hintBulb,
                            Icons.lightbulb_rounded,
                            const Color(0xFFFFD21C),
                            isSmall,
                          ),
                          SizedBox(height: isSmall ? 8 : 10),
                          _buildHintPackagesRow(context, user, isSmall),

                          SizedBox(height: isSmall ? 16 : 24),

                          // COIN PACKAGES (FREE AD COINS + GEMS TO COINS)
                          _buildSectionHeader(
                            'COIN PACKAGES',
                            GameAssets.coin,
                            Icons.monetization_on_rounded,
                            const Color(0xFFFFD21C),
                            isSmall,
                          ),
                          SizedBox(height: isSmall ? 8 : 10),
                          _buildCoinPackagesRow(context, user, isSmall),

                          SizedBox(height: isSmall ? 16 : 24),

                          // DIAMOND PACKAGES (EARN VIA REWARDED ADS — NO DOLLAR PURCHASES)
                          _buildSectionHeader(
                            'DIAMOND PACKAGES',
                            GameAssets.xpGem,
                            Icons.diamond_rounded,
                            const Color(0xFF00E5FF),
                            isSmall,
                          ),
                          SizedBox(height: isSmall ? 8 : 10),
                          _buildGemPackagesRow(context, user, isSmall),
                          SizedBox(height: isSmall ? 16 : 24),

                          // Ad Banner at bottom of Shop
                          const Center(child: AdBannerWidget()),
                          const SizedBox(height: 16),
                        ],
                      ),
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

  // ── 1. TOP HEADER & PROMINENT TREASURE STORE BANNER ────────────────────────
  Widget _buildTopHeader(BuildContext context, UserProvider user, bool isSmall) {
    final double pillHeight = isSmall ? 34.0 : 40.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Top Row: Back button (Left) & Coins/Gems Unified HUD (Right)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.pop(context),
              child: Image.asset(
                GameAssets.backButton,
                width: isSmall ? 38 : 44,
                height: isSmall ? 38 : 44,
                fit: BoxFit.contain,
              ),
            ),

            // Reused Unified Coins & Gems HUD Plaque from Home
            Container(
              height: pillHeight,
              padding: EdgeInsets.symmetric(
                horizontal: isSmall ? 10 : 14,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1830).withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(pillHeight / 2),
                border: Border.all(
                  color: const Color(0xFFFFD21C),
                  width: 1.6,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD21C).withValues(alpha: 0.2),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Coins counter
                  Image.asset(GameAssets.coin, width: isSmall ? 17 : 20, height: isSmall ? 17 : 20),
                  const SizedBox(width: 5),
                  Text(
                    '${user.userData.coins}',
                    style: TextStyle(
                      fontFamily: AppTheme.worldTitle.fontFamily,
                      fontWeight: FontWeight.w900,
                      fontSize: isSmall ? 12.5 : 14.0,
                      color: const Color(0xFFFFD21C),
                      shadows: const [
                        Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(0, 1)),
                      ],
                    ),
                  ),

                  // Divider
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 1.2,
                    height: pillHeight * 0.5,
                    color: const Color(0xFFFFD21C).withValues(alpha: 0.35),
                  ),

                  // Gems/Diamonds counter
                  Image.asset(
                    GameAssets.xpGem,
                    width: isSmall ? 16 : 18,
                    height: isSmall ? 16 : 18,
                    errorBuilder: (c, e, s) => Icon(Icons.diamond_rounded, color: const Color(0xFF29B6F6), size: isSmall ? 15 : 17),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${user.userData.gems}',
                    style: TextStyle(
                      fontFamily: AppTheme.worldTitle.fontFamily,
                      fontWeight: FontWeight.w900,
                      fontSize: isSmall ? 12.5 : 14.0,
                      color: const Color(0xFF29B6F6),
                      shadows: const [
                        Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(0, 1)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),


        SizedBox(height: isSmall ? 8 : 12),

        // TREASURE STORE WOODEN TITLE BANNER
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: isSmall ? 8 : 12,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF3B200C).withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFFFD21C),
              width: 2.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD21C).withValues(alpha: 0.25),
                blurRadius: 12,
                spreadRadius: 1,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Text(
            'TREASURE STORE',
            textAlign: TextAlign.center,
            style: AppTheme.worldTitle.copyWith(
              fontSize: isSmall ? 18.0 : 22.0,
              letterSpacing: isSmall ? 2.0 : 3.0,
              color: const Color(0xFFFFD21C),
              shadows: const [
                Shadow(color: Colors.black87, blurRadius: 8, offset: Offset(0, 2)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── 2. SECTION HEADER ──────────────────────────────────────────────────────
  Widget _buildSectionHeader(
    String title,
    String iconAsset,
    IconData fallbackIcon,
    Color borderGlow,
    bool isSmall,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.all(isSmall ? 5 : 7),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF1E3324),
            border: Border.all(color: borderGlow, width: 2.0),
            boxShadow: [
              BoxShadow(color: borderGlow.withValues(alpha: 0.45), blurRadius: 8),
            ],
          ),
          child: Image.asset(
            iconAsset,
            width: isSmall ? 20 : 26,
            height: isSmall ? 20 : 26,
            fit: BoxFit.contain,
            errorBuilder: (c, e, s) => Icon(fallbackIcon, color: borderGlow, size: isSmall ? 20 : 26),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isSmall ? 14 : 18,
            vertical: isSmall ? 6 : 8,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF2E1C0C).withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF8B5A2B), width: 1.8),
            boxShadow: const [
              BoxShadow(color: Colors.black54, blurRadius: 6, offset: Offset(0, 3)),
            ],
          ),
          child: Text(
            title,
            style: AppTheme.worldTitle.copyWith(
              color: const Color(0xFFF2C14E),
              fontSize: isSmall ? 12.0 : 14.0,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  // ── HINT PACKAGES ROW ──────────────────────────────────────────────────────
  Widget _buildHintPackagesRow(BuildContext context, UserProvider user, bool isSmall) {
    return Row(
      children: [
        Expanded(child: _buildHintCard(context, user, 5, 100, isSmall)),
        const SizedBox(width: 8),
        Expanded(child: _buildHintCard(context, user, 10, 200, isSmall)),
        const SizedBox(width: 8),
        Expanded(child: _buildHintCard(context, user, 20, 400, isSmall)),
      ],
    );
  }

  Widget _buildHintCard(BuildContext context, UserProvider user, int hints, int coinPrice, bool isSmall) {
    return Container(
      height: isSmall ? 145 : 175,
      padding: EdgeInsets.fromLTRB(6, isSmall ? 6 : 8, 6, isSmall ? 14 : 18),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1911).withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF5B7A42).withValues(alpha: 0.85), width: 1.8),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 2),
              Image.asset(
                GameAssets.hintBulb,
                width: isSmall ? 40 : 54,
                height: isSmall ? 40 : 54,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 6),
              Text(
                '$hints HINTS',
                style: AppTheme.worldTitle.copyWith(
                  color: Colors.white,
                  fontSize: isSmall ? 11.5 : 14.0,
                  fontWeight: FontWeight.w900,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          GameButton(
            width: double.infinity,
            height: isSmall ? 32 : 38,
            baseColor: AppTheme.success,
            shadowColor: const Color(0xFF1B9954),
            onPressed: () => _buyHint(context, user, hints, coinPrice),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$coinPrice',
                  style: TextStyle(
                    fontFamily: AppTheme.body.fontFamily,
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: isSmall ? 12.0 : 14.0,
                  ),
                ),
                const SizedBox(width: 4),

                Image.asset(GameAssets.coin, width: isSmall ? 14 : 16, height: isSmall ? 14 : 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── COIN PACKAGES ROW (WITH REWARDED AD COIN OFFER) ────────────────────────
  Widget _buildCoinPackagesRow(BuildContext context, UserProvider user, bool isSmall) {
    return Row(
      children: [
        // Card 1: FREE COINS via Rewarded Ad (+100 COINS)
        Expanded(child: _buildAdCoinCard(context, user, isSmall)),
        const SizedBox(width: 8),
        // Card 2: 500 Coins for 50 Gems (+500 COINS)
        Expanded(child: _buildCoinCard(context, user, 500, 50, isSmall)),
        const SizedBox(width: 8),
        // Card 3: 1000 Coins for 100 Gems (+1000 COINS)
        Expanded(child: _buildCoinCard(context, user, 1000, 100, isSmall)),
      ],
    );
  }

  Widget _buildAdCoinCard(BuildContext context, UserProvider user, bool isSmall) {
    final bool canWatch = user.canWatchCoinAd;
    final int remaining = user.remainingCoinAdsToday;
    final int cooldownSec = user.secondsUntilNextCoinAd;

    String btnText = 'WATCH AD';
    if (remaining <= 0) {
      btnText = 'LIMIT';
    } else if (cooldownSec > 0) {
      btnText = '${cooldownSec}s';
    }

    return Container(
      height: isSmall ? 145 : 175,
      padding: EdgeInsets.fromLTRB(6, isSmall ? 6 : 8, 6, isSmall ? 14 : 18),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1911).withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFD21C).withValues(alpha: 0.85), width: 1.8),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 2),
              Image.asset(
                GameAssets.coin,
                width: isSmall ? 38 : 52,
                height: isSmall ? 38 : 52,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 4),
              Text(
                '+100 COINS',
                style: TextStyle(
                  fontFamily: AppTheme.worldTitle.fontFamily,
                  color: AppTheme.gold,
                  fontWeight: FontWeight.w900,
                  fontSize: isSmall ? 10.5 : 12.5,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                '($remaining/5 Left)',
                style: TextStyle(
                  fontFamily: AppTheme.body.fontFamily,
                  color: Colors.white70,
                  fontSize: isSmall ? 8.5 : 10.0,
                ),
              ),
            ],
          ),

          GameButton(
            width: double.infinity,
            height: isSmall ? 32 : 38,
            baseColor: canWatch ? const Color(0xFFD48806) : Colors.grey.shade700,
            shadowColor: canWatch ? const Color(0xFF8C5300) : Colors.grey.shade900,
            onPressed: canWatch
                ? () {
                    AdService().showRewardedAd(
                      context: context,
                      onRewardGranted: () {
                        user.recordCoinAdWatched();
                        AudioService().playCoinReward();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Reward Earned! +100 Coins added! 🪙'),
                            backgroundColor: AppTheme.success,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    );
                  }
                : () {
                    String msg = 'Daily ad limit reached!';
                    if (cooldownSec > 0) {
                      msg = 'Please wait  seconds before watching another ad.';
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(msg),
                        backgroundColor: AppTheme.coral,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.play_circle_fill, color: Colors.white, size: 13),
                const SizedBox(width: 3),
                Text(
                  btnText,
                  style: TextStyle(
                    fontFamily: AppTheme.body.fontFamily,
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: isSmall ? 10.0 : 11.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoinCard(BuildContext context, UserProvider user, int coins, int gemPrice, bool isSmall) {
    return Container(
      height: isSmall ? 145 : 175,
      padding: EdgeInsets.fromLTRB(6, isSmall ? 6 : 8, 6, isSmall ? 14 : 18),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1911).withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF5B7A42).withValues(alpha: 0.85), width: 1.8),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 2),
              Image.asset(
                GameAssets.coin,
                width: isSmall ? 38 : 52,
                height: isSmall ? 38 : 52,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 6),
              Text(
                '+$coins COINS',
                style: TextStyle(
                  fontFamily: AppTheme.worldTitle.fontFamily,
                  color: AppTheme.gold,
                  fontWeight: FontWeight.w900,
                  fontSize: isSmall ? 10.5 : 12.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          GameButton(
            width: double.infinity,
            height: isSmall ? 32 : 38,
            baseColor: const Color(0xFF1B362A),
            shadowColor: const Color(0xFF10221A),
            onPressed: () => _buyCoinsWithGems(context, user, coins, gemPrice),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  GameAssets.xpGem,
                  width: isSmall ? 14 : 16,
                  height: isSmall ? 14 : 16,
                  errorBuilder: (c, e, s) => const Icon(Icons.diamond, color: Color(0xFF00E5FF), size: 14),
                ),
                const SizedBox(width: 4),
                Text(
                  '$gemPrice',
                  style: TextStyle(
                    fontFamily: AppTheme.body.fontFamily,
                    color: const Color(0xFF00E5FF),
                    fontWeight: FontWeight.w900,
                    fontSize: isSmall ? 12.0 : 14.0,
                  ),
                ),
              ],
            ),
          ),

        ],
      ),
    );
  }

  // ── GEM / DIAMOND PACKAGES ROW (NO DOLLAR PURCHASES — REWARDED ADS) ───────
  Widget _buildGemPackagesRow(BuildContext context, UserProvider user, bool isSmall) {
    return Row(
      children: [
        Expanded(child: _buildGemAdCard(context, user, 100, isSmall)),
        const SizedBox(width: 8),
        Expanded(child: _buildGemAdCard(context, user, 500, isSmall)),
        const SizedBox(width: 8),
        Expanded(child: _buildGemAdCard(context, user, 1200, isSmall)),
      ],
    );
  }

  Widget _buildGemAdCard(BuildContext context, UserProvider user, int gems, bool isSmall) {
    return Container(
      height: isSmall ? 145 : 175,
      padding: EdgeInsets.fromLTRB(6, isSmall ? 6 : 8, 6, isSmall ? 14 : 18),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1911).withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.75), width: 1.8),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 2),
              Image.asset(
                GameAssets.xpGem,
                width: isSmall ? 38 : 52,
                height: isSmall ? 38 : 52,
                fit: BoxFit.contain,
                errorBuilder: (c, e, s) => Icon(Icons.diamond, color: const Color(0xFF00E5FF), size: isSmall ? 38 : 52),
              ),
              const SizedBox(height: 6),
              Text(
                '+$gems DIAMONDS',
                style: TextStyle(
                  fontFamily: AppTheme.worldTitle.fontFamily,
                  color: const Color(0xFF00E5FF),
                  fontWeight: FontWeight.w900,
                  fontSize: isSmall ? 10.0 : 12.0,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          GameButton(
            width: double.infinity,
            height: isSmall ? 32 : 38,
            baseColor: const Color(0xFF0097A7),
            shadowColor: const Color(0xFF006064),
            onPressed: () {
              AdService().showRewardedAd(
                context: context,
                onRewardGranted: () {
                  user.addGems(gems);
                  AudioService().playPurchaseSuccess();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Ad Watched! Granted +$gems Diamonds! 💎'),
                      backgroundColor: const Color(0xFF0097A7),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              );
            },

            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.play_circle_fill, color: Colors.white, size: 13),
                const SizedBox(width: 3),
                Text(
                  'WATCH AD',
                  style: TextStyle(
                    fontFamily: AppTheme.body.fontFamily,
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: isSmall ? 10.0 : 11.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── TRANSACTION HANDLERS ───────────────────────────────────────────────────
  void _buyHint(BuildContext context, UserProvider user, int count, int price) {
    if (user.spendCoins(price)) {
      user.addHints(count);
      AudioService().playPurchaseSuccess();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bought $count Hints!'),
          backgroundColor: AppTheme.success,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not enough Coins!'),
          backgroundColor: AppTheme.coral,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _buyCoinsWithGems(BuildContext context, UserProvider user, int coinAmount, int gemCost) {
    if (user.spendGems(gemCost)) {
      user.addCoins(coinAmount);
      AudioService().playPurchaseSuccess();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exchanged $gemCost Gems for $coinAmount Coins!'),
          backgroundColor: AppTheme.success,
          duration: const Duration(seconds: 2),
        ),
      );

    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not enough Gems!'),
          backgroundColor: AppTheme.coral,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}
