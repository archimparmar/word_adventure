import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/theme.dart';

// --- Persistent Flag --------------------------------------------------------
const String kTutorialDoneKey = 'tutorial_gameplay_completed';

Future<bool> isTutorialDone() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(kTutorialDoneKey) ?? false;
}

Future<void> markTutorialDone() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(kTutorialDoneKey, true);
}

// --- Tutorial Step Data ------------------------------------------------------
enum TutorialTarget { wheel, board, hint, shuffle }

class TutorialStep {
  final String title;
  final String body;
  final TutorialTarget target;
  final String nextLabel;

  const TutorialStep({
    required this.title,
    required this.body,
    required this.target,
    this.nextLabel = 'NEXT',
  });
}

const List<TutorialStep> tutorialSteps = [
  TutorialStep(
    title: '🔤  Letter Wheel',
    body: 'Drag across the letters to build a word.\nRelease to submit your guess!',
    target: TutorialTarget.wheel,
  ),
  TutorialStep(
    title: '🧩  Word Board',
    body: 'Found words fill the board here.\nDiscover all required words to complete the level!',
    target: TutorialTarget.board,
  ),
  TutorialStep(
    title: '💡  Hint',
    body: 'Stuck? Tap Hint to reveal a letter.\nHints are limited — use them wisely!',
    target: TutorialTarget.hint,
  ),
  TutorialStep(
    title: '🔀  Shuffle',
    body: 'Rearrange the letters for a fresh perspective.\nSometimes a new view sparks an idea!',
    target: TutorialTarget.shuffle,
    nextLabel: 'GOT IT!',
  ),
];


// --- Layout Params -----------------------------------------------------------
class GameLayoutParams {
  final double screenWidth;
  final double screenHeight;
  final double boardTop;
  final double boardHeight;
  final double wheelCenterY;
  final double wheelDiameter;
  final double circleSize;
  final double hintX;
  final double shuffleX;
  final double controlsY;

  const GameLayoutParams({
    required this.screenWidth,
    required this.screenHeight,
    required this.boardTop,
    required this.boardHeight,
    required this.wheelCenterY,
    required this.wheelDiameter,
    required this.circleSize,
    required this.hintX,
    required this.shuffleX,
    required this.controlsY,
  });

  factory GameLayoutParams.compute(double screenWidth, double availableH) {
    final bool isSmall = screenWidth < 350 || availableH < 620;
    final double hudHeight = isSmall ? 46.0 : 54.0;
    final double bottomBarHeight = isSmall ? 52.0 : 60.0;
    const double subBoardBarHeight = 30.0;
    final double topBoardMargin = isSmall ? 10.0 : 16.0;
    const double gapHeight = 6.0;
    const double totalGaps = gapHeight * 4;
    const double safetyCushion = 8.0;

    final double remainingContentH = math.max(
      100.0,
      availableH -
          (hudHeight +
              topBoardMargin +
              bottomBarHeight +
              subBoardBarHeight +
              totalGaps +
              safetyCushion),
    );

    final double boardMaxH = remainingContentH * 0.54;
    final double wheelMaxH =
        math.min(remainingContentH * 0.46, screenWidth * 0.72);

    final double boardTop = hudHeight + topBoardMargin;
    final double boardHeight = boardMaxH;

    // Wheel vertical center (SafeArea child starts at 0)
    final double wheelAreaTop = boardTop +
        boardHeight +
        (gapHeight + 2) +
        subBoardBarHeight +
        (gapHeight + 2);
    final double wheelDiameter = math.min(wheelMaxH, screenWidth * 0.88);
    final double wheelCenterY = wheelAreaTop + wheelDiameter / 2;

    // Bottom controls
    final double controlsTop = wheelAreaTop + wheelMaxH + gapHeight;
    final double circleSize = math.max(48.0, isSmall ? 46.0 : 52.0);
    final double controlsY = controlsTop + circleSize / 2;

    const double hPad = 28.0;
    final double hintX = hPad + circleSize / 2;
    final double shuffleX = screenWidth - hPad - circleSize / 2;

    return GameLayoutParams(
      screenWidth: screenWidth,
      screenHeight: availableH,
      boardTop: boardTop,
      boardHeight: boardHeight,
      wheelCenterY: wheelCenterY,
      wheelDiameter: wheelDiameter,
      circleSize: circleSize,
      hintX: hintX,
      shuffleX: shuffleX,
      controlsY: controlsY,
    );
  }
}

// --- Spotlight Data ----------------------------------------------------------
class SpotlightRect {
  final Rect rect;
  final bool isCircle;
  const SpotlightRect({required this.rect, required this.isCircle});
}

SpotlightRect computeSpotlight(TutorialTarget target, GameLayoutParams p) {
  switch (target) {
    case TutorialTarget.wheel:
      return SpotlightRect(
        rect: Rect.fromCenter(
          center: Offset(p.screenWidth / 2, p.wheelCenterY),
          width: p.wheelDiameter + 28,
          height: p.wheelDiameter + 28,
        ),
        isCircle: true,
      );
    case TutorialTarget.board:
      return SpotlightRect(
        rect: Rect.fromLTWH(
          20,
          p.boardTop,
          p.screenWidth - 40,
          p.boardHeight,
        ),
        isCircle: false,
      );
    case TutorialTarget.hint:
      return SpotlightRect(
        rect: Rect.fromCenter(
          center: Offset(p.hintX, p.controlsY),
          width: p.circleSize + 28,
          height: p.circleSize + 28,
        ),
        isCircle: true,
      );
    case TutorialTarget.shuffle:
      return SpotlightRect(
        rect: Rect.fromCenter(
          center: Offset(p.shuffleX, p.controlsY),
          width: p.circleSize + 28,
          height: p.circleSize + 28,
        ),
        isCircle: true,
      );
  }
}

// --- Main Tutorial Overlay Widget --------------------------------------------
class GameTutorialOverlay extends StatefulWidget {
  final Widget child;
  final GameLayoutParams params;

  const GameTutorialOverlay({
    super.key,
    required this.child,
    required this.params,
  });

  @override
  State<GameTutorialOverlay> createState() => _GameTutorialOverlayState();
}

class _GameTutorialOverlayState extends State<GameTutorialOverlay>
    with TickerProviderStateMixin {
  bool _loaded = false;
  bool _showTutorial = false;
  int _step = 0;

  late AnimationController _pulseCtrl;
  late AnimationController _fadeCtrl;
  late Animation<double> _pulseAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _pulseAnim = Tween<double>(begin: 1.0, end: 1.09)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut));

    _checkAndShow();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkAndShow() async {
    final done = await isTutorialDone();
    if (!mounted) return;
    setState(() {
      _loaded = true;
      _showTutorial = !done;
    });
    if (!done) _fadeCtrl.forward();
  }

  Future<void> _advance() async {
    if (!_showTutorial) return;
    if (_step < tutorialSteps.length - 1) {
      await _fadeCtrl.reverse();
      if (!mounted) return;
      setState(() => _step++);
      _fadeCtrl.forward();
    } else {
      await _fadeCtrl.reverse();
      await markTutorialDone();
      if (!mounted) return;
      setState(() => _showTutorial = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || !_showTutorial) return widget.child;

    final step = tutorialSteps[_step];
    final spotlight = computeSpotlight(step.target, widget.params);

    return Stack(
      children: [
        widget.child,
        FadeTransition(
          opacity: _fadeAnim,
          child: AnimatedBuilder(
            animation: _pulseAnim,
            builder: (context, _) {
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _advance,
                child: Stack(
                  children: [
                    // Dim overlay with spotlight cutout
                    CustomPaint(
                      size: Size(widget.params.screenWidth, widget.params.screenHeight),
                      painter: _SpotlightPainter(
                        spotlight: spotlight,
                        pulse: _pulseAnim.value,
                      ),
                    ),
                    // Animated ring
                    _buildRing(spotlight),
                    // Info card
                    _buildCard(context, step, spotlight),
                    // Step dots
                    _buildDots(),
                    // Tap hint text
                    Positioned(
                      bottom: 14,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Text(
                          'TAP ANYWHERE TO CONTINUE',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.38),
                            fontSize: 10,
                            fontFamily: AppTheme.worldTitle.fontFamily,
                            letterSpacing: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRing(SpotlightRect spotlight) {
    final r = spotlight.rect;
    final pulse = _pulseAnim.value;

    if (spotlight.isCircle) {
      final radius = (r.width / 2) * pulse;
      return Positioned(
        left: r.center.dx - radius,
        top: r.center.dy - radius,
        child: Container(
          width: radius * 2,
          height: radius * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFFFD21C).withValues(alpha: 0.9),
              width: 2.8,
            ),
          ),
        ),
      );
    } else {
      final expanded = Rect.fromCenter(
        center: r.center,
        width: r.width * pulse,
        height: r.height + (pulse - 1.0) * 10,
      );
      return Positioned(
        left: expanded.left,
        top: expanded.top,
        child: Container(
          width: expanded.width,
          height: expanded.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFFFD21C).withValues(alpha: 0.9),
              width: 2.5,
            ),
          ),
        ),
      );
    }
  }

  Widget _buildCard(BuildContext context, TutorialStep step, SpotlightRect spotlight) {
    final r = spotlight.rect;
    final screenH = widget.params.screenHeight;

    // Place card so it does not overlap the spotlight
    final bool placeAbove = r.center.dy > screenH * 0.52;
    final double cardTop = placeAbove
        ? math.max(60.0, r.top - 200)
        : math.min(screenH - 220, r.bottom + 20);

    return Positioned(
      top: cardTop,
      left: 18,
      right: 18,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {}, // prevent tap-through
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1830).withValues(alpha: 0.90),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFFFD21C).withValues(alpha: 0.60),
                  width: 1.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD21C).withValues(alpha: 0.14),
                    blurRadius: 28,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.65),
                    blurRadius: 18,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: AppTheme.worldTitle.copyWith(
                      fontSize: 20,
                      color: const Color(0xFFFFD21C),
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      shadows: const [
                        Shadow(color: Colors.black, blurRadius: 8, offset: Offset(0, 2)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    step.body,
                    style: TextStyle(
                      fontFamily: AppTheme.worldTitle.fontFamily,
                      fontSize: 14.5,
                      color: Colors.white.withValues(alpha: 0.92),
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: _advance,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFD21C), Color(0xFFF59E0B)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFD21C).withValues(alpha: 0.45),
                              blurRadius: 14,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Text(
                          step.nextLabel,
                          style: TextStyle(
                            fontFamily: AppTheme.worldTitle.fontFamily,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF0D1830),
                            letterSpacing: 1.6,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDots() {
    return Positioned(
      top: 18,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(tutorialSteps.length, (i) {
          final active = i == _step;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: active ? 20 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: active
                  ? const Color(0xFFFFD21C)
                  : Colors.white.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      ),
    );
  }
}

// --- CustomPainter for Spotlight ---------------------------------------------
class _SpotlightPainter extends CustomPainter {
  final SpotlightRect spotlight;
  final double pulse;

  _SpotlightPainter({required this.spotlight, required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xCC000000);
    final fullRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final r = spotlight.rect;

    final expanded = Rect.fromCenter(
      center: r.center,
      width: r.width * pulse,
      height: r.height * pulse,
    );

    final path = spotlight.isCircle
        ? (Path()
          ..addRect(fullRect)
          ..addOval(expanded)
          ..fillType = PathFillType.evenOdd)
        : (Path()
          ..addRect(fullRect)
          ..addRRect(RRect.fromRectAndRadius(expanded, const Radius.circular(14)))
          ..fillType = PathFillType.evenOdd);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) =>
      old.pulse != pulse || old.spotlight.rect != spotlight.rect;
}
