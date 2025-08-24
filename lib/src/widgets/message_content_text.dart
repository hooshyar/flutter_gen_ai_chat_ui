import 'package:flutter/material.dart';
import 'package:flutter_streaming_text_markdown/flutter_streaming_text_markdown.dart';

import '../utils/font_helper.dart';

/// A specialized widget for displaying message text with proper directionality.
///
/// This widget handles text direction based on content rather than environment,
/// ensuring that RTL text is displayed correctly without affecting the surrounding UI.
class MessageContentText extends StatelessWidget {
  /// The text content to display
  final String text;

  /// The style to apply to the text
  final TextStyle? style;

  /// Whether the text should be displayed with streaming animation
  final bool isStreaming;

  /// Optional builder for custom text rendering
  final Widget Function(String text, TextStyle? style)? textBuilder;

  /// Creates a message content text widget
  const MessageContentText({
    super.key,
    required this.text,
    this.style,
    this.isStreaming = false,
    this.textBuilder,
  });

  @override
  Widget build(BuildContext context) {
    // Detect text direction based on content
    final isRtlText = FontHelper.isRTL(text);
    final textAlign = isRtlText ? TextAlign.right : TextAlign.left;
    final textDirection = isRtlText ? TextDirection.rtl : TextDirection.ltr;

    // Build the appropriate text widget
    Widget textWidget;
    if (textBuilder != null) {
      textWidget = textBuilder!(text, style);
    } else if (isStreaming) {
      // Use StreamingText for streaming content
      textWidget = StreamingText(
        text: text,
        style: style,
        typingSpeed: const Duration(milliseconds: 30),
        markdownEnabled: false,
        wordByWord: true,
        fadeInEnabled: true,
        fadeInDuration: const Duration(milliseconds: 200),
        textAlign: textAlign,
        textDirection: textDirection,
      );
    } else {
      textWidget = Text(
        text,
        style: style,
        textAlign: textAlign,
        textDirection: textDirection,
      );
    }

    // Wrap in a container that handles alignment without affecting parent layout
    return Container(
      alignment: isRtlText ? Alignment.centerRight : Alignment.centerLeft,
      width: double.infinity,
      child: textWidget,
    );
  }
}
