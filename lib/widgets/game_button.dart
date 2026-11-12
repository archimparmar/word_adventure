import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../utils/game_animations.dart';
import '../services/audio_service.dart';

class GameButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;
  final double? width;
  final double height;
  final Color baseColor;
  final Color shadowColor;
  final bool isRounded;
  
  const GameButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.width,
    this.height = 56.0,
    this.baseColor = AppTheme.success,
    this.shadowColor = const Color(0xFF1B9954), // darker green
    this.isRounded = false,
  });

  @override
  GameButtonState createState() => GameButtonState();
}

class GameButtonState extends State<GameButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: GameAnimations.micro,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    _controller.forward();
  }

  void _onPointerUp(PointerUpEvent event) {
    _controller.reverse();
    AudioService().playButtonTap();
    widget.onPressed();
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                color: widget.baseColor,
                shape: widget.isRounded ? BoxShape.circle : BoxShape.rectangle,
                borderRadius: widget.isRounded ? null : BorderRadius.circular(AppTheme.radiusLarge),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: widget.shadowColor,
                    offset: Offset(0, 6 * _scaleAnimation.value),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    offset: Offset(0, 8 * _scaleAnimation.value),
                    blurRadius: 8 * _scaleAnimation.value,
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.3),
                    offset: const Offset(0, -2),
                    blurRadius: 2,
                  ),
                ],
              ),
              child: Center(child: widget.child),
            ),
          );
        },
      ),
    );
  }
}
