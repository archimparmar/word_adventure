import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../services/audio_service.dart';
import '../providers/game_provider.dart';
import '../providers/user_provider.dart';
import '../utils/theme.dart';
import '../utils/game_animations.dart';
import '../screens/game_screen.dart';

class LetterWheel extends StatefulWidget {
  const LetterWheel({super.key});

  @override
  State<LetterWheel> createState() => _LetterWheelState();
}

class _LetterWheelState extends State<LetterWheel> {
  bool _isDragging = false;
  Offset? _currentDragPos;

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, provider, child) {
        if (provider.wheelLetters.isEmpty) return const SizedBox();

        final letters = provider.wheelLetters;
        final int letterCount = letters.length;

        return LayoutBuilder(
          builder: (context, constraints) {
            final double screenWidth = MediaQuery.of(context).size.width;

            // 1. Strict wheel size bounded by parent constraints
            final double wheelSize = math.min(constraints.maxWidth, constraints.maxHeight);
            if (wheelSize <= 0) return const SizedBox();

            // 2. Viewport target button size
            double maxTargetButtonSize;
            if (screenWidth < 340) {
              maxTargetButtonSize = 38.0;
            } else if (screenWidth < 385) {
              maxTargetButtonSize = 42.0;
            } else {
              maxTargetButtonSize = 46.0;
            }

            // 3. True Chord Distance Geometry Math
            const double outerSafetyMargin = 8.0;
            const double minGap = 4.0;
            double angularSin = math.sin(math.pi / letterCount);

            // Solve chord equation:
            double maxGeomDiameter = ((wheelSize - (2 * outerSafetyMargin)) * angularSin - minGap) / (1 + angularSin);
            
            // GEOMETRY SAFETY > MINIMUM BUTTON SIZE
            double buttonDiameter = math.min(maxTargetButtonSize, maxGeomDiameter);
            if (buttonDiameter >= 24.0) {
              buttonDiameter = buttonDiameter.clamp(24.0, maxTargetButtonSize);
            }
            buttonDiameter = math.max(12.0, buttonDiameter); // Ensure positive rendering size

            double placementRadius = math.max(
              10.0,
              (wheelSize / 2.0) - (buttonDiameter / 2.0) - outerSafetyMargin,
            );

            Offset center = Offset(constraints.maxWidth / 2.0, constraints.maxHeight / 2.0);

            List<Offset> letterPositions = [];
            for (int i = 0; i < letterCount; i++) {
              double angle = (2 * math.pi * i) / letterCount - math.pi / 2;
              double x = center.dx + placementRadius * math.cos(angle);
              double y = center.dy + placementRadius * math.sin(angle);
              letterPositions.add(Offset(x, y));
            }

            // Proportional stroke width
            double strokeWidth = (buttonDiameter * 0.22).clamp(6.0, 10.0);

            return GestureDetector(
              onPanStart: (details) => _handlePan(details.localPosition, letterPositions, provider, buttonDiameter),
              onPanUpdate: (details) => _handlePan(details.localPosition, letterPositions, provider, buttonDiameter),
              onPanEnd: (details) {
                setState(() {
                  _isDragging = false;
                  _currentDragPos = null;
                });

                provider.submitWord((word, result) {
                  if (result == SubmissionResult.validRequired ||
                      result == SubmissionResult.validBonus ||
                      result == SubmissionResult.validHard) {
                    final userProvider = Provider.of<UserProvider>(context, listen: false);
                    
                    userProvider.recordWordFound(
                      result == SubmissionResult.validBonus,
                      isHard: result == SubmissionResult.validHard,
                      word: word,
                    );

                    if (provider.isLevelComplete) {
                      userProvider.completeLevel(provider.currentLevel, perfect: provider.isPerfect());
                      AudioService().playWordComplete();
                    } else {
                      AudioService().playWordComplete();
                    }
                  } else {
                    AudioService().playWordInvalid();
                  }

                  // Find GameScreen State to display transient feedback
                  final gameScreenState = context.findAncestorStateOfType<GameScreenState>();
                  if (gameScreenState != null) {
                    gameScreenState.handleSubmissionResult(word, result);
                  }
                });
              },
              child: Container(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                color: Colors.transparent,
                child: Stack(
                  children: [
                    // Translucent Base Plate Disk
                    Center(
                      child: Container(
                        width: wheelSize,
                        height: wheelSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF0D162B).withValues(alpha: 0.42),
                          border: Border.all(
                            color: const Color(0xFFFFD21C).withValues(alpha: 0.35),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.30),
                              blurRadius: 14,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Drag Gesture Path
                    if (_isDragging && provider.selectedIndices.isNotEmpty)
                      CustomPaint(
                        size: Size(constraints.maxWidth, constraints.maxHeight),
                        painter: PathPainter(
                          positions: provider.selectedIndices.map((i) => letterPositions[i]).toList(),
                          currentPos: _currentDragPos ?? letterPositions[provider.selectedIndices.last],
                          strokeWidth: strokeWidth,
                        ),
                      ),

                    // Letter Buttons (3D Blue Adventure Nodes)
                    ...List.generate(letterCount, (index) {
                      bool isSelected = provider.selectedIndices.contains(index);
                      return Positioned(
                        left: letterPositions[index].dx - (buttonDiameter / 2),
                        top: letterPositions[index].dy - (buttonDiameter / 2),
                        child: AnimatedScale(
                          scale: isSelected ? 1.15 : 1.0,
                          duration: GameAnimations.micro,
                          curve: Curves.easeOutBack,
                          child: Container(
                            width: buttonDiameter,
                            height: buttonDiameter,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: isSelected
                                  ? const LinearGradient(
                                      colors: [Color(0xFFFFD21C), Color(0xFFF59E0B)],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    )
                                  : const LinearGradient(
                                      colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                              boxShadow: [
                                BoxShadow(
                                  color: isSelected
                                      ? const Color(0xFFFFD21C).withValues(alpha: 0.5)
                                      : Colors.black.withValues(alpha: 0.45),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.35),
                                  offset: const Offset(0, -2),
                                  blurRadius: 2,
                                ),
                              ],
                              border: Border.all(
                                color: isSelected ? Colors.white : const Color(0xFF93C5FD),
                                width: 2.2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                letters[index],
                                style: TextStyle(
                                  fontFamily: AppTheme.worldTitle.fontFamily,
                                  fontSize: buttonDiameter * 0.50,
                                  color: isSelected ? const Color(0xFF0F1932) : Colors.white,
                                  fontWeight: FontWeight.w900,
                                  height: 1.0,
                                  shadows: isSelected
                                      ? null
                                      : const [
                                          Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(0, 1.5)),
                                        ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _handlePan(Offset pos, List<Offset> letterPositions, GameProvider provider, double buttonDiameter) {
    setState(() {
      _isDragging = true;
      _currentDragPos = pos;
    });

    double hitRadius = math.max(20.0, buttonDiameter * 0.60);

    // Find closest and second-closest letter position
    int closestIndex = -1;
    double minDistance = double.infinity;
    double secondMinDistance = double.infinity;

    for (int i = 0; i < letterPositions.length; i++) {
      double dist = (pos - letterPositions[i]).distance;
      if (dist < minDistance) {
        secondMinDistance = minDistance;
        minDistance = dist;
        closestIndex = i;
      } else if (dist < secondMinDistance) {
        secondMinDistance = dist;
      }
    }

    if (closestIndex != -1 && minDistance <= hitRadius) {
      // Ambiguity check: must be closer to closestIndex than secondMinDistance - 4px
      if (minDistance <= secondMinDistance - 4.0 || secondMinDistance == double.infinity) {
        final selectedIndices = provider.selectedIndices;

        // Check for backtracking: if touched index is immediately preceding selected index
        if (selectedIndices.length >= 2 && closestIndex == selectedIndices[selectedIndices.length - 2]) {
          provider.deselectLastIndex();
        } else if (!selectedIndices.contains(closestIndex)) {
          AudioService().playLetterSelect();
          provider.selectIndex(closestIndex);
        }
      }
    }
  }
}

class PathPainter extends CustomPainter {
  final List<Offset> positions;
  final Offset currentPos;
  final double strokeWidth;

  PathPainter({
    required this.positions,
    required this.currentPos,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (positions.isEmpty) return;

    final paint = Paint()
      ..color = AppTheme.gold.withValues(alpha: 0.85)
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(positions[0].dx, positions[0].dy);

    for (int i = 1; i < positions.length; i++) {
      path.lineTo(positions[i].dx, positions[i].dy);
    }

    path.lineTo(currentPos.dx, currentPos.dy);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
