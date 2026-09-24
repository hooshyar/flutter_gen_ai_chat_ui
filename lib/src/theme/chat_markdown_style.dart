import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import 'chat_tokens.dart';
import 'code_block_theme.dart';

/// Builds the [MarkdownStyleSheet] used for message markdown, per
/// `DESIGN.md` §4.
///
/// [base] supplies the paragraph text color/font (already resolved by the
/// caller from the message options' text style, a theme extension or
/// [ChatTokens]); this only layers size, line height, weight, tracking and
/// block spacing on top of it. [cbt] supplies the fenced-code-block palette
/// used for [MarkdownStyleSheet.codeblockDecoration].
///
/// A caller-supplied `MessageOptions.markdownStyleSheet` always wins over
/// the sheet this returns — this is only ever the fallback default.
MarkdownStyleSheet chatMarkdownStyle(
  BuildContext context,
  TextStyle base,
  CodeBlockTheme cbt,
) {
  final tokens = ChatTokens.of(context);
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final trackingBoost = isDark ? 0.1 : 0.0;

  TextStyle scale(
    double fontSize,
    double heightMultiplier,
    FontWeight weight, {
    double letterSpacing = 0,
    Color? color,
  }) {
    return base.copyWith(
      fontSize: fontSize,
      height: heightMultiplier,
      fontWeight: weight,
      letterSpacing: letterSpacing,
      color: color ?? base.color,
    );
  }

  final headingPadding = const EdgeInsets.only(top: 20, bottom: 8);

  return MarkdownStyleSheet(
    p: scale(16, 1.56, FontWeight.w400, letterSpacing: trackingBoost),
    pPadding: const EdgeInsets.only(bottom: 12),
    h1: scale(20, 1.4, FontWeight.w600, letterSpacing: -0.2),
    h1Padding: headingPadding,
    h2: scale(17.5, 1.49, FontWeight.w600, letterSpacing: -0.1),
    h2Padding: headingPadding,
    h3: scale(16, 1.5, FontWeight.w600),
    h3Padding: headingPadding,
    h4: scale(16, 1.5, FontWeight.w600),
    h4Padding: headingPadding,
    h5: scale(16, 1.5, FontWeight.w600),
    h5Padding: headingPadding,
    h6: scale(16, 1.5, FontWeight.w600),
    h6Padding: headingPadding,
    strong: scale(16, 1.56, FontWeight.w600, letterSpacing: trackingBoost),
    a: TextStyle(color: tokens.accent, decoration: TextDecoration.none),
    listIndent: 20,
    listBullet: scale(16, 1.56, FontWeight.w400, color: tokens.textSecondary),
    // Flutter Markdown's `blockquotePadding` is a plain (non-directional)
    // EdgeInsets, so the left inset below is a best-effort match for LTR;
    // the rule itself is directional (BorderDirectional) so it still mirrors
    // correctly under RTL.
    blockquotePadding: const EdgeInsets.only(left: 12),
    blockquoteDecoration: BoxDecoration(
      border: BorderDirectional(
        start: BorderSide(width: 3, color: tokens.border),
      ),
    ),
    blockquote: scale(16, 1.56, FontWeight.w400, color: tokens.textSecondary),
    tableHead: scale(16, 1.56, FontWeight.w600),
    tableBody: scale(16, 1.56, FontWeight.w400),
    tableHeadCellsDecoration: BoxDecoration(color: tokens.surfaceSunken),
    tableCellsPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
    tableBorder: TableBorder(
      top: BorderSide(width: 1, color: tokens.border),
      bottom: BorderSide(width: 1, color: tokens.border),
      horizontalInside: BorderSide(width: 1, color: tokens.border),
      left: BorderSide.none,
      right: BorderSide.none,
      verticalInside: BorderSide.none,
    ),
    // Inline `code` — a subtle tinted chip in the bundled mono font. Flutter
    // cannot round an inline TextSpan background, so radius is skipped.
    code: TextStyle(
      fontFamily: CodeBlockTheme.monoFontFamily,
      package: 'flutter_gen_ai_chat_ui',
      fontFamilyFallback: CodeBlockTheme.monoFontFallback,
      fontSize: (base.fontSize ?? 16) * 0.9,
      color: base.color,
      backgroundColor: tokens.inlineCodeBg,
    ),
    // Fenced code blocks: the visual chrome (background, border, radius)
    // comes entirely from CodeBlockView / CodeBlockMarkdownBuilder now, so
    // the stylesheet must not add its own padding on top of theirs.
    codeblockPadding: EdgeInsets.zero,
    codeblockDecoration: BoxDecoration(
      color: cbt.backgroundColor,
      border: Border.all(color: cbt.borderColor),
      borderRadius: const BorderRadius.all(Radius.circular(ChatRadius.md)),
    ),
  );
}
