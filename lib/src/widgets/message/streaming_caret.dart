import 'package:flutter/material.dart';

import '../../theme/chat_tokens.dart';

/// The live caret shown after a streaming AI message's revealed content
/// (`DESIGN.md` §7, §8.9): an 8x8 [ChatTokens.textPrimary] dot pulsing
/// between 35% and 100% opacity over [ChatMotion.caretPulse].
///
/// Removed by the caller once the stream ends. Under reduced motion
/// ([ChatMotion.reduced]) no [AnimationController]/ticker is created at all
/// and the dot renders at a fixed full opacity.
class StreamingCaret extends StatefulWidget {
  const StreamingCaret({super.key});

  @override
  State<StreamingCaret> createState() => _StreamingCaretState();
}

class _StreamingCaretState extends State<StreamingCaret>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    if (!ChatMotion.reduced(context)) {
      _controller = AnimationController(
        vsync: this,
        duration: ChatMotion.caretPulse,
      )..repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ChatTokens.of(context);
    final dot = Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: tokens.textPrimary,
        shape: BoxShape.circle,
      ),
    );

    final controller = _controller;
    if (controller == null) {
      // Reduced motion: static, fully opaque dot, no ticker.
      return dot;
    }

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Opacity(opacity: 0.35 + 0.65 * controller.value, child: child);
      },
      child: dot,
    );
  }
}
