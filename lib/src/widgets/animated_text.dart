import 'package:flutter/material.dart';
import 'package:flutter_streaming_text_markdown/flutter_streaming_text_markdown.dart';

import '../providers/theme_provider.dart';
import '../utils/font_helper.dart';

class AnimatedTextMessage extends StatefulWidget {
  const AnimatedTextMessage({
    super.key,
    required this.text,
    this.style,
    this.animate = false,
    required this.isUser,
    this.isStreaming = false,
    this.textBuilder,
  });
  final String text;
  final TextStyle? style;
  final bool animate;
  final bool isUser;
  final bool isStreaming;
  final Widget Function(String text, TextStyle? style)? textBuilder;

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
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    if (widget.animate) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(final AnimatedTextMessage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != oldWidget.text && widget.animate) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final customTheme = Theme.of(context).extension<CustomThemeExtension>() ??
        ThemeProvider.lightTheme.extension<CustomThemeExtension>()!;

    final textStyle = FontHelper.getAppropriateFont(
      text: widget.text,
      baseStyle: widget.style ??
          TextStyle(
            color: customTheme.messageTextColor,
            fontSize: 15,
            height: 1.4,
          ),
    );

    final isRtlText = FontHelper.isRTL(widget.text);
    final textAlign = isRtlText ? TextAlign.right : TextAlign.left;
    final textDirection = isRtlText ? TextDirection.rtl : TextDirection.ltr;

    Widget buildText(final String text, final TextStyle? style) {
      if (widget.textBuilder != null) {
        return widget.textBuilder!(text, style);
      }
      return Text(
        text,
        style: style,
        textAlign: textAlign,
        textDirection: textDirection,
      );
    }

    // Instead of using Directionality, use Container with alignment to respect text direction
    // while not affecting surrounding elements
    return Container(
      alignment: FontHelper.getAlignment(widget.text),
      width: double.infinity,
      child: widget.isStreaming
          ? StreamingText(
              text: widget.text,
              style: textStyle,
              typingSpeed: const Duration(milliseconds: 30),
              wordByWord: true,
              fadeInEnabled: true,
              fadeInDuration: const Duration(milliseconds: 200),
              textAlign: textAlign,
              textDirection: textDirection,
            )
          : FadeTransition(
              opacity: _fadeAnimation,
              child: buildText(widget.text, textStyle),
            ),
    );
  }
}

