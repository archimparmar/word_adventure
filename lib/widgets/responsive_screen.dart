import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;

class ResponsiveScreen extends StatelessWidget {
  final Widget child;
  final String? backgroundAsset;
  final bool hasBottomNav;
  final double overlayOpacity;
  final bool blurBackground;
  final double blurSigma;
  final Widget? bottomBar;

  const ResponsiveScreen({
    super.key,
    required this.child,
    this.backgroundAsset,
    this.hasBottomNav = false,
    this.overlayOpacity = 0.28,
    this.blurBackground = false,
    this.blurSigma = 2.5,
    this.bottomBar,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      bottomNavigationBar: bottomBar,
      body: Stack(
        children: [
          if (backgroundAsset != null) ...[
            Positioned.fill(
              child: Image.asset(
                backgroundAsset!,
                fit: BoxFit.cover,
              ),
            ),
            if (blurBackground)
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
                  child: Container(
                    color: const Color(0xFF0B0E1E).withValues(alpha: math.max(0.35, overlayOpacity)),
                  ),
                ),
              )
            else if (overlayOpacity > 0)
              Positioned.fill(
                child: Container(
                  color: const Color(0xFF0B0E1E).withValues(alpha: overlayOpacity),
                ),
              ),
          ],
          SafeArea(
            bottom: !hasBottomNav,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600), // Max tablet width
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 16.0,
                    right: 16.0,
                    top: 12.0,
                    bottom: hasBottomNav ? 90.0 : 12.0, // Space for navigation dock
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
