import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_math_fork/flutter_math.dart';

/// A markdown renderer that supports inline and block LaTeX/math expressions.
///
/// Supports:
/// - Block math: `$$...$$`
/// - Inline math: `$...$`
///
/// Non-math content is rendered via [MarkdownBody].
class MathMarkdown extends StatelessWidget {
  const MathMarkdown({
    super.key,
    required this.data,
    this.styleSheet,
    this.selectable = false,
    this.onTapLink,
    this.textStyle,
  });

  final String data;
  final MarkdownStyleSheet? styleSheet;
  final bool selectable;
  final MarkdownTapLinkCallback? onTapLink;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final segments = _parseSegments(data);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: segments.map((seg) => _buildSegment(context, seg)).toList(),
    );
  }

  Widget _buildSegment(BuildContext context, _MathSegment seg) {
    if (seg.isBlock) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Math.tex(
            seg.content,
            textStyle: textStyle ?? DefaultTextStyle.of(context).style,
            onErrorFallback: (e) => SelectableText(
              seg.content,
              style: (textStyle ?? DefaultTextStyle.of(context).style).copyWith(
                color: Colors.red[700],
                fontFamily: 'monospace',
              ),
            ),
          ),
        ),
      );
    }

    if (seg.isInline) {
      return Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: _parseInlineMath(context, seg.content),
      );
    }

    // Plain markdown
    return MarkdownBody(
      data: seg.content,
      selectable: selectable,
      shrinkWrap: true,
      styleSheet: styleSheet,
      onTapLink: onTapLink,
    );
  }

  /// Parse a run of text that may contain inline `$...$` math.
  List<Widget> _parseInlineMath(BuildContext context, String text) {
    final widgets = <Widget>[];
    final pattern = RegExp(r'\$([^$]+?)\$');
    var last = 0;

    for (final match in pattern.allMatches(text)) {
      if (match.start > last) {
        final before = text.substring(last, match.start);
        if (before.isNotEmpty) {
          widgets.add(Text(before,
              style: textStyle ?? DefaultTextStyle.of(context).style));
        }
      }
      widgets.add(
        Math.tex(
          match.group(1)!,
          textStyle: textStyle ?? DefaultTextStyle.of(context).style,
          onErrorFallback: (e) => Text(
            match.group(0)!,
            style: (textStyle ?? DefaultTextStyle.of(context).style).copyWith(
              color: Colors.red[700],
            ),
          ),
        ),
      );
      last = match.end;
    }

    if (last < text.length) {
      final after = text.substring(last);
      if (after.isNotEmpty) {
        widgets.add(Text(after,
            style: textStyle ?? DefaultTextStyle.of(context).style));
      }
    }
    return widgets;
  }

  /// Split [data] into plain-markdown, block-math ($$...$$), and inline-math segments.
  List<_MathSegment> _parseSegments(String data) {
    final segments = <_MathSegment>[];
    // Match block math first ($$...$$), then inline ($...$)
    final blockPattern = RegExp(r'\$\$([\s\S]+?)\$\$');
    var cursor = 0;

    for (final match in blockPattern.allMatches(data)) {
      if (match.start > cursor) {
        final between = data.substring(cursor, match.start);
        _addTextSegments(segments, between);
      }
      segments.add(_MathSegment.block(match.group(1)!.trim()));
      cursor = match.end;
    }

    if (cursor < data.length) {
      _addTextSegments(segments, data.substring(cursor));
    }

    return segments;
  }

  void _addTextSegments(List<_MathSegment> segments, String text) {
    if (text.isEmpty) return;
    // Check if this chunk has any inline math
    if (RegExp(r'\$[^$]+?\$').hasMatch(text)) {
      segments.add(_MathSegment.inlineRun(text));
    } else {
      segments.add(_MathSegment.markdown(text));
    }
  }
}

class _MathSegment {
  final String content;
  final _SegmentKind kind;

  const _MathSegment._(this.content, this.kind);
  factory _MathSegment.block(String content) =>
      _MathSegment._(content, _SegmentKind.block);
  factory _MathSegment.inlineRun(String content) =>
      _MathSegment._(content, _SegmentKind.inline);
  factory _MathSegment.markdown(String content) =>
      _MathSegment._(content, _SegmentKind.markdown);

  bool get isBlock => kind == _SegmentKind.block;
  bool get isInline => kind == _SegmentKind.inline;
}

enum _SegmentKind { block, inline, markdown }
