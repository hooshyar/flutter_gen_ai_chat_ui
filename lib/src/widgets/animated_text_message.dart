import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_streaming_text_markdown/flutter_streaming_text_markdown.dart';

import '../utils/color_extensions.dart';

/// A widget that animates text appearing character by character
class AnimatedTextMessage extends StatefulWidget {
  const AnimatedTextMessage({
    super.key,
    required this.text,
    required this.style,
    required this.animate,
    required this.isUser,
    this.isStreaming = false,
    this.isMarkdown = false,
    this.textBuilder,
  });

  final String text;
  final TextStyle style;
  final bool animate;
  final bool isUser;
  final bool isStreaming;
  final bool isMarkdown;
  final Widget Function(String text, TextStyle style)? textBuilder;

  @override
  State<AnimatedTextMessage> createState() => _AnimatedTextMessageState();
}

class _AnimatedTextMessageState extends State<AnimatedTextMessage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    if (widget.animate) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Handle markdown streaming text
    if (widget.isMarkdown && widget.isStreaming) {
      return StreamingText(
        text: widget.text,
        style: widget.style,
        typingSpeed: const Duration(milliseconds: 30),
      );
    }

    // Handle regular streaming text
    if (widget.isStreaming) {
      return StreamingText(
        text: widget.text,
        style: widget.style,
        typingSpeed: const Duration(milliseconds: 30),
      );
    }

    // Handle regular text with fade animation
    return FadeTransition(
      opacity: _fadeAnimation,
      child: widget.textBuilder?.call(widget.text, widget.style) ??
          (widget.isMarkdown
              ? MarkdownBody(
                  data: widget.text,
                  styleSheet: MarkdownStyleSheet(
                    p: widget.style,
                    code: widget.style.copyWith(
                      fontFamily: 'monospace',
                      backgroundColor: Colors.grey.withOpacityCompat(0.2),
                    ),
                  ),
                )
              : Text(widget.text, style: widget.style)),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
