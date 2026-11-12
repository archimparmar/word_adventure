import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../utils/game_assets.dart';
import '../utils/theme.dart';
import '../widgets/responsive_screen.dart';

class LoadingScreen extends StatefulWidget {
  final Widget Function() targetBuilder;
  final String title;

  const LoadingScreen({
    super.key,
    required this.targetBuilder,
    this.title = 'LOADING ADVENTURE...',
  });

  static Future<void> open(
    BuildContext context, {
    required Widget Function() targetBuilder,
    String title = 'LOADING ADVENTURE...',
  }) {
    return Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => LoadingScreen(
          targetBuilder: targetBuilder,
          title: title,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnim;
  late Animation<double> _progressAnim;

  final List<_LoadingParticle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _progressAnim = Tween<double>(begin: 0.15, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    // Initialize 20 floating particles
    for (int i = 0; i < 20; i++) {
      _particles.add(
        _LoadingParticle(
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          size: _random.nextDouble() * 3.5 + 2.0,
          speed: _random.nextDouble() * 0.002 + 0.0008,
          opacity: _random.nextDouble() * 0.5 + 0.3,
          color: i % 2 == 0 ? const Color(0xFFFFD21C) : const Color(0xFF38BDF8),
        ),
      );
    }

    _loadAndNavigate();
  }

  Future<void> _loadAndNavigate() async {
    // Short smooth preparation window to ensure target widget & assets load cleanly
    await Future.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;

    final targetWidget = widget.targetBuilder();

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => targetWidget,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C1838), // Non-black fallback background
      body: ResponsiveScreen(
        backgroundAsset: GameAssets.globalBackground,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final isSmall = w < 350;
            final logoWidth = isSmall ? 190.0 : 240.0;
            final progressWidth = isSmall ? 180.0 : 220.0;

            return Stack(
              children: [
                // Floating Sparkle Particles Painter
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    for (var p in _particles) {
                      p.y -= p.speed;
                      if (p.y < 0) {
                        p.y = 1.0;
                        p.x = _random.nextDouble();
                      }
                    }
                    return CustomPaint(
                      size: Size(constraints.maxWidth, constraints.maxHeight),
                      painter: _LoadingParticlePainter(_particles),
                    );
                  },
                ),

                // Centered Column: Logo, Loading Bar, Title Text
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Centered Glowing Logo
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnim.value,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFFD21C).withValues(alpha: 0.30),
                                    blurRadius: 32,
                                    spreadRadius: 6,
                                  ),
                                  BoxShadow(
                                    color: const Color(0xFF38BDF8).withValues(alpha: 0.20),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Image.asset(
                                GameAssets.homeLogo,
                                width: logoWidth,
                                fit: BoxFit.contain,
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 24),

                      // Polished Loading Progress Indicator Bar
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          return Container(
                            width: progressWidth,
                            height: 10,
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D1734).withValues(alpha: 0.90),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFFFD21C).withValues(alpha: 0.70),
                                width: 1.5,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black45,
                                  blurRadius: 8,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: FractionallySizedBox(
                                widthFactor: _progressAnim.value,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF38BDF8), Color(0xFFFFD21C)],
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0xFFFFD21C),
                                        blurRadius: 6,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 14),

                      // Loading Title Text
                      Text(
                        widget.title,
                        style: AppTheme.worldTitle.copyWith(
                          fontSize: isSmall ? 12.0 : 14.0,
                          letterSpacing: 1.8,
                          color: const Color(0xFFFFD21C),
                          fontWeight: FontWeight.w900,
                          shadows: const [
                            Shadow(color: Colors.black87, blurRadius: 6, offset: Offset(0, 2)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LoadingParticle {
  double x;
  double y;
  double size;
  double speed;
  double opacity;
  Color color;

  _LoadingParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.color,
  });
}

class _LoadingParticlePainter extends CustomPainter {
  final List<_LoadingParticle> particles;
  _LoadingParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (var p in particles) {
      final paint = Paint()
        ..color = p.color.withValues(alpha: p.opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(p.x * size.width, p.y * size.height),
        p.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
