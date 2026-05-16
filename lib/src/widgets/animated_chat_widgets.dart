import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

/// Collection of animated widgets for chat interfaces
class AnimatedChatWidgets {
  AnimatedChatWidgets._();

  /// Creates a bounce-in animation for message bubbles
  static Widget bounceInBubble({
    required Widget child,
    required AnimationController controller,
    Duration delay = Duration.zero,
  }) {
    final animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(
          delay.inMilliseconds / controller.duration!.inMilliseconds,
          1.0,
          curve: Curves.elasticOut,
        ),
      ),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.scale(
          scale: animation.value,
          child: child,
        );
      },
      child: child,
    );
  }

  /// Creates a slide-in animation from the side
  static Widget slideInBubble({
    required Widget child,
    required AnimationController controller,
    required bool isUser,
    Duration delay = Duration.zero,
  }) {
    final slideAnimation = Tween<Offset>(
      begin: Offset(isUser ? 1.0 : -1.0, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(
          delay.inMilliseconds / controller.duration!.inMilliseconds,
          1.0,
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    final fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(
          delay.inMilliseconds / controller.duration!.inMilliseconds,
          1.0,
          curve: Curves.easeOut,
        ),
      ),
    );

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: fadeAnimation,
          child: SlideTransition(
            position: slideAnimation,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// Animated bubble with custom decorations and effects
class AnimatedBubble extends StatefulWidget {
  final Widget child;
  final BoxDecoration decoration;
  final EdgeInsets padding;
  final bool isUser;
  final BubbleAnimation animationType;
  final Duration animationDuration;
  final Duration delay;

  const AnimatedBubble({
    super.key,
    required this.child,
    required this.decoration,
    this.padding = const EdgeInsets.all(12),
    this.isUser = false,
    this.animationType = BubbleAnimation.slideIn,
    this.animationDuration = const Duration(milliseconds: 600),
    this.delay = Duration.zero,
  });

  @override
  State<AnimatedBubble> createState() => _AnimatedBubbleState();
}

class _AnimatedBubbleState extends State<AnimatedBubble>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _hoverController;

  /// Tracked start-delay timer (iter 3). Cancelled on dispose so widget tests
  /// that unmount an AnimatedBubble before its initial delay elapses don't
  /// fail with "Timer still pending after dispose".
  Timer? _startDelayTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    // Start animation with delay
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      _startDelayTimer = Timer(widget.delay, () {
        _startDelayTimer = null;
        if (mounted) {
          _controller.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _startDelayTimer?.cancel();
    _startDelayTimer = null;
    _controller.dispose();
    _hoverController.dispose();
    super.dispose();
  }

  void _onHover(bool hover) {
    if (hover) {
      _hoverController.forward();
    } else {
      _hoverController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget animatedChild;

    switch (widget.animationType) {
      case BubbleAnimation.bounceIn:
        animatedChild = AnimatedChatWidgets.bounceInBubble(
          controller: _controller,
          delay: widget.delay,
          child: _buildBubble(),
        );
        break;
      case BubbleAnimation.slideIn:
        animatedChild = AnimatedChatWidgets.slideInBubble(
          controller: _controller,
          isUser: widget.isUser,
          delay: widget.delay,
          child: _buildBubble(),
        );
        break;
      case BubbleAnimation.fadeIn:
        final fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: _controller,
          curve: Curves.easeOut,
        ));

        animatedChild = AnimatedBuilder(
          animation: fadeAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: fadeAnimation.value,
              child: child,
            );
          },
          child: _buildBubble(),
        );
        break;
    }

    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      child: animatedChild,
    );
  }

  Widget _buildBubble() {
    return AnimatedBuilder(
      animation: _hoverController,
      builder: (context, child) {
        final hoverValue = _hoverController.value;
        final scale = 1.0 + (hoverValue * 0.05); // Subtle scale on hover

        return Transform.scale(
          scale: scale,
          child: Container(
            padding: widget.padding,
            decoration: widget.decoration.copyWith(
              boxShadow: widget.decoration.boxShadow?.map((shadow) {
                return shadow.copyWith(
                  blurRadius: shadow.blurRadius + (hoverValue * 5),
                  spreadRadius: shadow.spreadRadius + (hoverValue * 2),
                );
              }).toList(),
            ),
            child: widget.child,
          ),
        );
      },
    );
  }
}

/// Gradient border bubble with animated effects
class GradientBorderBubble extends StatefulWidget {
  final Widget child;
  final List<Color> gradientColors;
  final Color backgroundColor;
  final double borderWidth;
  final BorderRadius borderRadius;
  final EdgeInsets padding;
  final bool animate;

  const GradientBorderBubble({
    super.key,
    required this.child,
    required this.gradientColors,
    this.backgroundColor = Colors.white,
    this.borderWidth = 2.0,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.padding = const EdgeInsets.all(16),
    this.animate = true,
  });

  @override
  State<GradientBorderBubble> createState() => _GradientBorderBubbleState();
}

class _GradientBorderBubbleState extends State<GradientBorderBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    if (widget.animate) {
      _rotationController.repeat();
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _rotationController,
      builder: (context, child) {
        return CustomPaint(
          painter: GradientBorderPainter(
            gradientColors: widget.gradientColors,
            borderWidth: widget.borderWidth,
            borderRadius: widget.borderRadius,
            rotationAngle:
                widget.animate ? _rotationController.value * 2 * math.pi : 0,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: widget.backgroundColor,
              borderRadius: widget.borderRadius,
            ),
            padding: widget.padding,
            child: widget.child,
          ),
        );
      },
    );
  }
}

/// Custom painter for gradient borders
class GradientBorderPainter extends CustomPainter {
  final List<Color> gradientColors;
  final double borderWidth;
  final BorderRadius borderRadius;
  final double rotationAngle;

  GradientBorderPainter({
    required this.gradientColors,
    required this.borderWidth,
    required this.borderRadius,
    this.rotationAngle = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndCorners(
      rect,
      topLeft: borderRadius.topLeft,
      topRight: borderRadius.topRight,
      bottomLeft: borderRadius.bottomLeft,
      bottomRight: borderRadius.bottomRight,
    );

    // Create gradient with rotation
    final gradient = SweepGradient(
      colors: gradientColors,
      startAngle: rotationAngle,
      endAngle: rotationAngle + 2 * math.pi,
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..strokeWidth = borderWidth
      ..style = PaintingStyle.stroke;

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(GradientBorderPainter oldDelegate) {
    return oldDelegate.rotationAngle != rotationAngle ||
        oldDelegate.gradientColors != gradientColors ||
        oldDelegate.borderWidth != borderWidth ||
        oldDelegate.borderRadius != borderRadius;
  }
}

/// Glassmorphic bubble with backdrop blur effect
class GlassmorphicBubble extends StatelessWidget {
  final Widget child;
  final Color color;
  final double opacity;
  final double blurAmount;
  final Border? border;
  final BorderRadius borderRadius;
  final EdgeInsets padding;

  const GlassmorphicBubble({
    super.key,
    required this.child,
    this.color = Colors.white,
    this.opacity = 0.2,
    this.blurAmount = 10.0,
    this.border,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
        child: Container(
          decoration: BoxDecoration(
            color: color.withValues(alpha: opacity),
            borderRadius: borderRadius,
            border: border,
          ),
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

/// Neon glow effect bubble
class NeonGlowBubble extends StatefulWidget {
  final Widget child;
  final Color glowColor;
  final Color backgroundColor;
  final double glowIntensity;
  final BorderRadius borderRadius;
  final EdgeInsets padding;
  final bool animate;

  const NeonGlowBubble({
    super.key,
    required this.child,
    this.glowColor = const Color(0xFF00D9FF),
    this.backgroundColor = const Color(0xFF1E1E2E),
    this.glowIntensity = 10.0,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.padding = const EdgeInsets.all(16),
    this.animate = false,
  });

  @override
  State<NeonGlowBubble> createState() => _NeonGlowBubbleState();
}

class _NeonGlowBubbleState extends State<NeonGlowBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    if (widget.animate) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final glowIntensity = widget.animate
            ? widget.glowIntensity + (_pulseController.value * 5)
            : widget.glowIntensity;

        return Container(
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: widget.borderRadius,
            border: Border.all(color: widget.glowColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: widget.glowColor.withValues(alpha: 0.5),
                blurRadius: glowIntensity,
                spreadRadius: glowIntensity / 4,
              ),
              BoxShadow(
                color: widget.glowColor.withValues(alpha: 0.3),
                blurRadius: glowIntensity * 2,
                spreadRadius: glowIntensity / 2,
              ),
            ],
          ),
          padding: widget.padding,
          child: widget.child,
        );
      },
    );
  }
}

/// Animation types for bubbles
enum BubbleAnimation {
  bounceIn,
  slideIn,
  fadeIn,
}
