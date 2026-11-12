import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../utils/theme.dart';
import '../utils/game_assets.dart';
import '../services/audio_service.dart';

class HintPackage {
  final int hints;
  final int coins;
  const HintPackage(this.hints, this.coins);
}

class HintPurchaseDialog extends StatefulWidget {
  const HintPurchaseDialog({super.key});

  static const List<HintPackage> packages = [
    HintPackage(1, 20),
    HintPackage(3, 60),
    HintPackage(5, 100),
    HintPackage(10, 200),
    HintPackage(15, 300),
    HintPackage(20, 400),
  ];

  @override
  State<HintPurchaseDialog> createState() => _HintPurchaseDialogState();
}

class _HintPurchaseDialogState extends State<HintPurchaseDialog> {
  String? _errorMessage;

  void _buyPackage(UserProvider userProvider, HintPackage pkg) {
    setState(() => _errorMessage = null);

    if (userProvider.userData.coins < pkg.coins) {
      setState(() {
        _errorMessage = 'INSUFFICIENT COINS! Need ${pkg.coins} 🪙';
      });
      return;
    }

    // Spend coins and add hints using existing atomic economy methods
    final success = userProvider.spendCoins(pkg.coins);
    if (success) {
      userProvider.addHints(pkg.hints);
      AudioService().playPurchaseSuccess();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Purchased +${pkg.hints} Hints!'),
          backgroundColor: AppTheme.success,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360),
        padding: const EdgeInsets.all(18),
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
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Image.asset(GameAssets.hintBulb, width: 26, height: 26),
                    const SizedBox(width: 8),
                    Text(
                      'GET MORE HINTS',
                      style: AppTheme.worldTitle.copyWith(
                        fontSize: 17,
                        letterSpacing: 1.5,
                        color: AppTheme.gold,
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
                    child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Live User Balance Row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF203626).withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF5B7A42).withValues(alpha: 0.40)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Image.asset(GameAssets.coin, width: 18, height: 18),
                      const SizedBox(width: 6),
                      Text(
                        '${userProvider.userData.coins} Coins',
                        style: const TextStyle(
                          color: AppTheme.gold,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '20 Coins / Hint',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: const TextStyle(
                  color: AppTheme.coral,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],

            const SizedBox(height: 12),

            // 6 Hint Package Options List
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: HintPurchaseDialog.packages.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final pkg = HintPurchaseDialog.packages[index];
                  final canAfford = userProvider.userData.coins >= pkg.coins;

                  return GestureDetector(
                    onTap: () => _buyPackage(userProvider, pkg),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: canAfford
                            ? const Color(0xFF203626).withValues(alpha: 0.85)
                            : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: canAfford
                              ? const Color(0xFF5B7A42).withValues(alpha: 0.60)
                              : Colors.white10,
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Left: Hint Quantity
                          Row(
                            children: [
                              Image.asset(GameAssets.hintBulb, width: 22, height: 22),
                              const SizedBox(width: 10),
                              Text(
                                '${pkg.hints} ${pkg.hints == 1 ? "HINT" : "HINTS"}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),

                          // Right: Price Button Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: canAfford ? AppTheme.success : Colors.grey.shade800,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  '${pkg.coins}',
                                  style: TextStyle(
                                    color: canAfford ? Colors.white : Colors.white38,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Image.asset(GameAssets.coin, width: 14, height: 14),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 14),

            // CANCEL Button
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'CANCEL',
                  style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
