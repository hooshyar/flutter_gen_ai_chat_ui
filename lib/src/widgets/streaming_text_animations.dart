import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Different animation styles for streaming text
enum StreamingAnimationType {
  /// Classic typewriter effect - characters appear one by one
  typewriter,

  /// Words fade in with opacity animation
  fadeIn,

  /// Words slide in from the right with subtle bounce
  slideIn,

  /// Words bounce in with spring physics
  bounce,

  /// Words appear with a subtle glow effect
  glow,

  /// Words scale up from nothing
  scale,

  /// Words appear with a wave effect
  wave,

  /// Words appear with a shimmer effect
  shimmer,
}

/// Configuration for streaming text animations
class StreamingAnimationConfig {
  /// The type of animation to use
  final StreamingAnimationType type;

  /// Duration for each character/word animation
  final Duration duration;

  /// Delay between character/word animations
  final Duration delay;

  /// Animation curve for the effect
  final Curve curve;

  /// Whether to animate by character or by word
  final bool animateByWord;

  /// Custom colors for glow/shimmer effects
  final Color? accentColor;

  /// Whether to include haptic feedback
  final bool enableHapticFeedback;

  const StreamingAnimationConfig({
    this.type = StreamingAnimationType.typewriter,
    this.duration = const Duration(milliseconds: 200),
    this.delay = const Duration(milliseconds: 50),
    this.curve = Curves.easeInOut,
    this.animateByWord = true,
    this.accentColor,
    this.enableHapticFeedback = false,
  });

  /// Typewriter preset - classic character-by-character
  static const typewriter = StreamingAnimationConfig(
    type: StreamingAnimationType.typewriter,
    duration: Duration(milliseconds: 100),
    delay: Duration(milliseconds: 30),
    animateByWord: false,
  );

  /// Smooth fade-in preset
  static const fadeIn = StreamingAnimationConfig(
    type: StreamingAnimationType.fadeIn,
    duration: Duration(milliseconds: 300),
    delay: Duration(milliseconds: 80),
    curve: Curves.easeInOut,
  );

  /// Slide-in with bounce preset
  static const slideIn = StreamingAnimationConfig(
    type: StreamingAnimationType.slideIn,
    duration: Duration(milliseconds: 400),
    delay: Duration(milliseconds: 100),
    curve: Curves.easeOutBack,
  );

  /// Bouncy entrance preset
  static const bounce = StreamingAnimationConfig(
    type: StreamingAnimationType.bounce,
    duration: Duration(milliseconds: 500),
    delay: Duration(milliseconds: 120),
    curve: Curves.bounceOut,
  );

  /// Glowing text preset
  static const glow = StreamingAnimationConfig(
    type: StreamingAnimationType.glow,
    duration: Duration(milliseconds: 600),
    delay: Duration(milliseconds: 100),
    curve: Curves.easeInOut,
    accentColor: Color(0xFF6366F1),
  );

  /// Scale-up preset
  static const scale = StreamingAnimationConfig(
    type: StreamingAnimationType.scale,
    duration: Duration(milliseconds: 300),
    delay: Duration(milliseconds: 60),
    curve: Curves.elasticOut,
  );

  /// Wave effect preset
  static const wave = StreamingAnimationConfig(
    type: StreamingAnimationType.wave,
    duration: Duration(milliseconds: 400),
    delay: Duration(milliseconds: 80),
    curve: Curves.easeInOutSine,
  );

  /// Shimmer effect preset
  static const shimmer = StreamingAnimationConfig(
    type: StreamingAnimationType.shimmer,
    duration: Duration(milliseconds: 800),
    delay: Duration(milliseconds: 100),
    curve: Curves.linear,
    accentColor: Color(0xFFFFFFFF),
  );
}

/// Widget that handles streaming text with different animation styles
class StreamingTextWidget extends StatefulWidget {
  /// The complete text to display
  final String text;

  /// Text style for the content
  final TextStyle? style;

  /// Animation configuration
  final StreamingAnimationConfig config;

  /// Whether the text should be streaming (animated)
  final bool isStreaming;

  /// Callback when streaming completes
  final VoidCallback? onStreamingComplete;

  /// Text alignment
  final TextAlign? textAlign;

  /// Maximum lines
  final int? maxLines;

  /// Text overflow behavior
  final TextOverflow? overflow;

  const StreamingTextWidget({
    super.key,
    required this.text,
    this.style,
    this.config = StreamingAnimationConfig.typewriter,
    this.isStreaming = true,
    this.onStreamingComplete,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  State<StreamingTextWidget> createState() => _StreamingTextWidgetState();
}

class _StreamingTextWidgetState extends State<StreamingTextWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late List<String> _textParts;
  int _currentIndex = 0;

  /// Active recursive-step timer for [_animateNextPart]. Tracked so [dispose]
  /// can cancel it — otherwise widget tests that dispose this widget while
  /// the streaming animation is mid-flight fail with "Timer still pending
  /// after dispose" (iter 3 audit).
  Timer? _stepTimer;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _parseText();
    if (widget.isStreaming) {
      _startAnimation();
    } else {
      _currentIndex = _textParts.length;
    }
  }

  @override
  void didUpdateWidget(StreamingTextWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text ||
        oldWidget.isStreaming != widget.isStreaming) {
      _parseText();
      if (widget.isStreaming && !oldWidget.isStreaming) {
        _startAnimation();
      } else if (!widget.isStreaming) {
        _currentIndex = _textParts.length;
        setState(() {});
      }
    }
  }

  void _setupAnimation() {
    _controller = AnimationController(
      duration: widget.config.duration,
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: widget.config.curve,
    );
  }

  void _parseText() {
    if (widget.config.animateByWord) {
      _textParts = widget.text.split(' ');
    } else {
      _textParts = widget.text.split('');
    }
    _currentIndex = widget.isStreaming ? 0 : _textParts.length;
  }

  void _startAnimation() {
    _currentIndex = 0;
    _animateNextPart();
  }

  void _animateNextPart() {
    if (_currentIndex >= _textParts.length) {
      widget.onStreamingComplete?.call();
      return;
    }

    setState(() => _currentIndex++);

    if (widget.config.enableHapticFeedback) {
      HapticFeedback.selectionClick();
    }

    _controller
      ..reset()
      ..forward();

    // Tracked Timer (iter 3) — replaces an untracked Future.delayed so we can
    // cancel pending steps on dispose.
    _stepTimer?.cancel();
    _stepTimer = Timer(widget.config.delay, () {
      _stepTimer = null;
      if (mounted && widget.isStreaming) {
        _animateNextPart();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return _buildTextWithAnimation();
      },
    );
  }

  Widget _buildTextWithAnimation() {
    final displayedText = _getDisplayedText();
    final lastPartIndex = _currentIndex - 1;

    switch (widget.config.type) {
      case StreamingAnimationType.typewriter:
        return Text(
          displayedText,
          style: widget.style,
          textAlign: widget.textAlign,
          maxLines: widget.maxLines,
          overflow: widget.overflow,
        );

      case StreamingAnimationType.fadeIn:
        return _buildFadeInText(displayedText, lastPartIndex);

      case StreamingAnimationType.slideIn:
        return _buildSlideInText(displayedText, lastPartIndex);

      case StreamingAnimationType.bounce:
        return _buildBounceText(displayedText, lastPartIndex);

      case StreamingAnimationType.glow:
        return _buildGlowText(displayedText, lastPartIndex);

      case StreamingAnimationType.scale:
        return _buildScaleText(displayedText, lastPartIndex);

      case StreamingAnimationType.wave:
        return _buildWaveText(displayedText, lastPartIndex);

      case StreamingAnimationType.shimmer:
        return _buildShimmerText(displayedText, lastPartIndex);
    }
  }

  String _getDisplayedText() {
    if (widget.config.animateByWord) {
      return _textParts.take(_currentIndex).join(' ');
    } else {
      return _textParts.take(_currentIndex).join('');
    }
  }

  Widget _buildFadeInText(String displayedText, int lastPartIndex) {
    if (lastPartIndex < 0) {
      return const SizedBox.shrink();
    }

    return Wrap(
      children: _textParts.asMap().entries.map((entry) {
        final index = entry.key;
        final part = entry.value;

        if (index >= _currentIndex) {
          return const SizedBox.shrink();
        }

        final opacity = index == lastPartIndex ? _animation.value : 1.0;

        return AnimatedOpacity(
          opacity: opacity,
          duration: widget.config.duration,
          child: Text(
            widget.config.animateByWord ? '$part ' : part,
            style: widget.style,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSlideInText(String displayedText, int lastPartIndex) {
    return Wrap(
      children: _textParts.asMap().entries.map((entry) {
        final index = entry.key;
        final part = entry.value;

        if (index >= _currentIndex) {
          return const SizedBox.shrink();
        }

        final offset = index == lastPartIndex
            ? Offset((1 - _animation.value) * 20, 0)
            : Offset.zero;

        return Transform.translate(
          offset: offset,
          child: Text(
            widget.config.animateByWord ? '$part ' : part,
            style: widget.style,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBounceText(String displayedText, int lastPartIndex) {
    return Wrap(
      children: _textParts.asMap().entries.map((entry) {
        final index = entry.key;
        final part = entry.value;

        if (index >= _currentIndex) {
          return const SizedBox.shrink();
        }

        final scale = index == lastPartIndex ? _animation.value : 1.0;

        return Transform.scale(
          scale: scale,
          child: Text(
            widget.config.animateByWord ? '$part ' : part,
            style: widget.style,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGlowText(String displayedText, int lastPartIndex) {
    final accentColor = widget.config.accentColor ?? Colors.blue;

    return Wrap(
      children: _textParts.asMap().entries.map((entry) {
        final index = entry.key;
        final part = entry.value;

        if (index >= _currentIndex) {
          return const SizedBox.shrink();
        }

        final glowIntensity = index == lastPartIndex ? _animation.value : 0.0;

        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: glowIntensity * 0.5),
                blurRadius: 10 * glowIntensity,
                spreadRadius: 2 * glowIntensity,
              ),
            ],
          ),
          child: Text(
            widget.config.animateByWord ? '$part ' : part,
            style: widget.style?.copyWith(
              color: Color.lerp(
                widget.style?.color ?? Colors.black,
                accentColor,
                glowIntensity * 0.3,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildScaleText(String displayedText, int lastPartIndex) {
    return Wrap(
      children: _textParts.asMap().entries.map((entry) {
        final index = entry.key;
        final part = entry.value;

        if (index >= _currentIndex) {
          return const SizedBox.shrink();
        }

        final scale =
            index == lastPartIndex ? 0.5 + (_animation.value * 0.5) : 1.0;

        return Transform.scale(
          scale: scale,
          child: Text(
            widget.config.animateByWord ? '$part ' : part,
            style: widget.style,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWaveText(String displayedText, int lastPartIndex) {
    return Wrap(
      children: _textParts.asMap().entries.map((entry) {
        final index = entry.key;
        final part = entry.value;

        if (index >= _currentIndex) {
          return const SizedBox.shrink();
        }

        final waveOffset =
            index == lastPartIndex ? sin(_animation.value * 2 * pi) * 3 : 0.0;

        return Transform.translate(
          offset: Offset(0, waveOffset),
          child: Text(
            widget.config.animateByWord ? '$part ' : part,
            style: widget.style,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildShimmerText(String displayedText, int lastPartIndex) {
    final accentColor = widget.config.accentColor ?? Colors.white;

    return Wrap(
      children: _textParts.asMap().entries.map((entry) {
        final index = entry.key;
        final part = entry.value;

        if (index >= _currentIndex) {
          return const SizedBox.shrink();
        }

        final shimmerValue = index == lastPartIndex ? _animation.value : 0.0;

        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                widget.style?.color ?? Colors.black,
                accentColor,
                widget.style?.color ?? Colors.black,
              ],
              stops: [
                (shimmerValue - 0.3).clamp(0.0, 1.0),
                shimmerValue,
                (shimmerValue + 0.3).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          child: Text(
            widget.config.animateByWord ? '$part ' : part,
            style: widget.style?.copyWith(
              color: Colors.white,
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    _stepTimer = null;
    _controller.dispose();
    super.dispose();
  }
}

// Helper function for wave animation
double sin(double value) => math.sin(value);
double get pi => math.pi;
