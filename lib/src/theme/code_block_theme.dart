import 'package:flutter/material.dart';

/// Immutable theme for fenced code blocks and their syntax highlighting.
///
/// Colors follow GitHub's light/dark palettes so both variants stay
/// WCAG-readable on their respective backgrounds. Use [CodeBlockTheme.of]
/// to resolve a theme from ambient [Brightness].
class CodeBlockTheme {
  /// Font family bundled with this package (`fonts/JetBrainsMono-Regular.ttf`).
  static const String monoFontFamily = 'JetBrainsMono';

  /// Platform monospace fallbacks used when the bundled font is unavailable.
  static const List<String> monoFontFallback = [
    'Menlo',
    'Consolas',
    'Courier New',
    'monospace',
  ];

  const CodeBlockTheme({
    required this.backgroundColor,
    required this.borderColor,
    required this.headerTextColor,
    required this.baseStyle,
    required this.commentColor,
    required this.stringColor,
    required this.numberColor,
    required this.keywordColor,
    required this.typeColor,
    required this.functionColor,
    required this.annotationColor,
    required this.punctuationColor,
    this.copyTooltip = 'Copy code',
    this.copiedTooltip = 'Copied',
  });

  /// GitHub-light-derived palette per `DESIGN.md` §3 (two contrast fixes:
  /// `commentColor` and `annotationColor`).
  factory CodeBlockTheme.light() => const CodeBlockTheme(
        backgroundColor: Color(0xFFF6F6F4),
        borderColor: Color(0xFFE4E4E2),
        headerTextColor: Color(0xFF6B6B73),
        baseStyle: _baseLight,
        commentColor: Color(0xFF656D76),
        stringColor: Color(0xFF0A3069),
        numberColor: Color(0xFF0550AE),
        keywordColor: Color(0xFFCF222E),
        typeColor: Color(0xFF953800),
        functionColor: Color(0xFF8250DF),
        annotationColor: Color(0xFF8A5C00),
        punctuationColor: Color(0xFF57606A),
      );

  /// GitHub-dark-derived palette per `DESIGN.md` §3.
  factory CodeBlockTheme.dark() => const CodeBlockTheme(
        backgroundColor: Color(0xFF161618),
        borderColor: Color(0xFF2A2A2F),
        headerTextColor: Color(0xFF8C8C94),
        baseStyle: _baseDark,
        commentColor: Color(0xFF8B949E),
        stringColor: Color(0xFFA5D6FF),
        numberColor: Color(0xFF79C0FF),
        keywordColor: Color(0xFFFF7B72),
        typeColor: Color(0xFFFFA657),
        functionColor: Color(0xFFD2A8FF),
        annotationColor: Color(0xFF7EE787),
        punctuationColor: Color(0xFF8B949E),
      );

  /// Resolves a theme from ambient brightness.
  static CodeBlockTheme of(Brightness brightness) =>
      brightness == Brightness.dark
          ? CodeBlockTheme.dark()
          : CodeBlockTheme.light();

  static const TextStyle _baseLight = TextStyle(
    fontFamily: monoFontFamily,
    package: 'flutter_gen_ai_chat_ui',
    fontFamilyFallback: monoFontFallback,
    fontSize: 13.5,
    height: 1.48,
    color: Color(0xFF24292F),
  );

  static const TextStyle _baseDark = TextStyle(
    fontFamily: monoFontFamily,
    package: 'flutter_gen_ai_chat_ui',
    fontFamilyFallback: monoFontFallback,
    fontSize: 13.5,
    height: 1.48,
    color: Color(0xFFE6EDF3),
  );

  final Color backgroundColor;
  final Color borderColor;
  final Color headerTextColor;

  /// Base monospace text style applied to unhighlighted code and inherited
  /// by every token span. Never carries a `backgroundColor`.
  final TextStyle baseStyle;

  final Color commentColor;
  final Color stringColor;
  final Color numberColor;
  final Color keywordColor;
  final Color typeColor;
  final Color functionColor;
  final Color annotationColor;
  final Color punctuationColor;

  /// Tooltip shown on the copy affordance.
  final String copyTooltip;

  /// Tooltip shown briefly after a successful copy.
  final String copiedTooltip;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CodeBlockTheme &&
          other.backgroundColor == backgroundColor &&
          other.borderColor == borderColor &&
          other.headerTextColor == headerTextColor &&
          other.baseStyle == baseStyle &&
          other.commentColor == commentColor &&
          other.stringColor == stringColor &&
          other.numberColor == numberColor &&
          other.keywordColor == keywordColor &&
          other.typeColor == typeColor &&
          other.functionColor == functionColor &&
          other.annotationColor == annotationColor &&
          other.punctuationColor == punctuationColor &&
          other.copyTooltip == copyTooltip &&
          other.copiedTooltip == copiedTooltip;

  @override
  int get hashCode => Object.hash(
        backgroundColor,
        borderColor,
        headerTextColor,
        baseStyle,
        commentColor,
        stringColor,
        numberColor,
        keywordColor,
        typeColor,
        functionColor,
        annotationColor,
        punctuationColor,
        copyTooltip,
        copiedTooltip,
      );
}
