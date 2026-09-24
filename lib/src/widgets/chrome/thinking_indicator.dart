import 'package:flutter/material.dart';

import '../../theme/chat_tokens.dart';
import '../../utils/color_extensions.dart';

/// Pre-first-token "AI is composing" state (`DESIGN.md` §8.7).
///
/// The package default for a `ChatMessage.loading` placeholder that has no
/// text yet: the word "Thinking" with a highlight band sweeping across it
/// over [ChatMotion.thinkingSweep], linear, repeating. Collapses to static
/// text plus three static 4px dots when
/// `MediaQuery.disableAnimationsOf(context)` is true. No grey pill, no
/// bouncing dots — that variant is reserved for [ChatTypingDots].
class ThinkingIndicator extends StatefulWidget {
  /// Creates the pre-first-token thinking row.
  const ThinkingIndicator({super.key});

  @override
  State<ThinkingIndicator> createState() => _ThinkingIndicatorState();
}

class _ThinkingIndicatorState extends State<ThinkingIndicator>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncController();
  }

  void _syncController() {
    final reduced = ChatMotion.reduced(context);
    if (reduced) {
      _controller?.dispose();
      _controller = null;
      return;
    }
    _controller ??= AnimationController(
      vsync: this,
      duration: ChatMotion.thinkingSweep,
    )..repeat();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ChatTokens.of(context);
    final labelStyle = TextStyle(
      fontSize: 14,
      height: 20 / 14,
      fontWeight: FontWeight.w500,
      color: tokens.textSecondary,
    );

    final controller = _controller;
    if (controller == null) {
      return Semantics(
        label: 'Thinking',
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Thinking', style: labelStyle),
            const SizedBox(width: 8),
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(width: 4),
              _StaticDot(color: tokens.textTertiary, size: 4),
            ],
          ],
        ),
      );
    }

    return Semantics(
      label: 'Thinking',
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          final t = controller.value;
          // Sweep a highlight band start-to-end across the label, looping.
          final dx = -1.0 + 3.0 * t;
          return ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) => LinearGradient(
              colors: [
                tokens.textSecondary,
                tokens.textPrimary,
                tokens.textSecondary,
              ],
              stops: const [0.0, 0.5, 1.0],
              begin: Alignment(dx - 1, 0),
              end: Alignment(dx + 1, 0),
            ).createShader(bounds),
            child: Text('Thinking', style: labelStyle),
          );
        },
      ),
    );
  }
}

/// Bouncing three-dot indicator for multi-user typing (`DESIGN.md` §8.7).
///
/// Package default: `textTertiary`, 6px, no background pill. [color] and
/// [size] stay overridable (documented knobs threaded from
/// `LoadingConfig.typingIndicatorColor`/`.typingIndicatorSize`).
class ChatTypingDots extends StatefulWidget {
  /// Creates the multi-user typing dots row.
  const ChatTypingDots({super.key, this.color, this.size});

  /// Dot color. Defaults to `ChatTokens.textTertiary`.
  final Color? color;

  /// Dot diameter. Defaults to 6.
  final double? size;

  @override
  State<ChatTypingDots> createState() => _ChatTypingDotsState();
}

class _ChatTypingDotsState extends State<ChatTypingDots>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = ChatMotion.reduced(context);
    if (reduced) {
      _controller?.dispose();
      _controller = null;
      return;
    }
    _controller ??= AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ChatTokens.of(context);
    final dotSize = widget.size ?? 6.0;
    final dimColor = (widget.color ?? tokens.textTertiary).withOpacityCompat(
      0.45,
    );
    final brightColor = widget.color ?? tokens.textTertiary;
    final controller = _controller;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          if (controller == null)
            _StaticDot(color: brightColor, size: dotSize)
          else
            AnimatedBuilder(
              animation: controller,
              builder: (context, child) {
                final interval = CurvedAnimation(
                  parent: controller,
                  curve: Interval(i * 0.2, 1.0, curve: Curves.easeInOut),
                );
                return Container(
                  width: dotSize,
                  height: dotSize,
                  decoration: BoxDecoration(
                    color: Color.lerp(
                      dimColor,
                      brightColor,
                      interval.value,
                    ),
                    shape: BoxShape.circle,
                  ),
                );
              },
            ),
        ],
      ],
    );
  }
}

/// Skeleton placeholder bars for a `ChatMessage.loading` message that
/// already has caption text (`DESIGN.md` §8.7).
///
/// Three bars, 10px tall, radius 5, widths 100% / 72% / 46%, filled with
/// `surfaceSunken` and a [ChatMotion.thinkingSweep] shimmer (static under
/// reduced motion). [caption] renders above them when non-null/non-empty.
class ChatLoadingBars extends StatefulWidget {
  /// Creates the loading skeleton bars, with an optional caption above them.
  const ChatLoadingBars({super.key, this.caption});

  /// Optional caption shown above the bars, e.g. "Searching for lawyers...".
  final String? caption;

  @override
  State<ChatLoadingBars> createState() => _ChatLoadingBarsState();
}

class _ChatLoadingBarsState extends State<ChatLoadingBars>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  static const _widthFactors = [1.0, 0.72, 0.46];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = ChatMotion.reduced(context);
    if (reduced) {
      _controller?.dispose();
      _controller = null;
      return;
    }
    _controller ??= AnimationController(
      vsync: this,
      duration: ChatMotion.thinkingSweep,
    )..repeat();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ChatTokens.of(context);
    final caption = widget.caption;
    final controller = _controller;

    Widget bar(double widthFactor) {
      final fill = Container(
        height: 10,
        decoration: BoxDecoration(
          color: tokens.surfaceSunken,
          borderRadius: BorderRadius.circular(5),
        ),
      );
      if (controller == null) {
        return FractionallySizedBox(
          widthFactor: widthFactor,
          alignment: AlignmentDirectional.centerStart,
          child: fill,
        );
      }
      return FractionallySizedBox(
        widthFactor: widthFactor,
        alignment: AlignmentDirectional.centerStart,
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            final t = controller.value;
            final dx = -1.0 + 3.0 * t;
            return ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) => LinearGradient(
                colors: [
                  tokens.surfaceSunken,
                  tokens.border,
                  tokens.surfaceSunken,
                ],
                stops: const [0.0, 0.5, 1.0],
                begin: Alignment(dx - 1, 0),
                end: Alignment(dx + 1, 0),
              ).createShader(bounds),
              child: fill,
            );
          },
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (caption != null && caption.isNotEmpty) ...[
          Text(
            caption,
            style: TextStyle(
              fontSize: 12,
              height: 16 / 12,
              letterSpacing: 0.1,
              color: tokens.textTertiary,
            ),
          ),
          const SizedBox(height: 8),
        ],
        for (var i = 0; i < _widthFactors.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          bar(_widthFactors[i]),
        ],
      ],
    );
  }
}

/// Pagination "loading more" spinner (`DESIGN.md` §8.7): 16px,
/// `strokeWidth: 2`, `textTertiary`, no text.
class ChatPaginationSpinner extends StatelessWidget {
  /// Creates the pagination loading spinner.
  const ChatPaginationSpinner({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = ChatTokens.of(context);
    return Center(
      child: SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(tokens.textTertiary),
        ),
      ),
    );
  }
}

class _StaticDot extends StatelessWidget {
  const _StaticDot({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
