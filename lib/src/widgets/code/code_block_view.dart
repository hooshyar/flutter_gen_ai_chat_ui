import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;

import '../../theme/code_block_theme.dart';
import 'code_highlighter.dart';

/// A self-contained code block: optional header (language label + copy
/// button) above horizontally-scrollable, syntax-highlighted code.
///
/// The widget always renders its content left-to-right so code stays LTR
/// inside RTL chats.
///
/// Set [decorate] to false when the surrounding markdown renderer already
/// paints the block background (e.g. flutter_markdown_plus wraps `pre`
/// output in `MarkdownStyleSheet.codeblockDecoration`); otherwise a single
/// rounded container is drawn with [CodeBlockTheme.backgroundColor] and a
/// 1px [CodeBlockTheme.borderColor] border.
class CodeBlockView extends StatefulWidget {
  const CodeBlockView({
    super.key,
    required this.code,
    this.language,
    this.theme,
    this.enableSyntaxHighlighting = true,
    this.showCopyButton = true,
    this.baseStyle,
    this.padding,
    this.decorate = true,
  });

  /// Raw source code — no markdown fences or language tag.
  final String code;

  /// Language tag used for highlighting and shown lowercase in the header.
  final String? language;

  /// Visual theme. Defaults to [CodeBlockTheme.of] with ambient brightness.
  final CodeBlockTheme? theme;

  /// When false the code renders as a single unhighlighted span.
  final bool enableSyntaxHighlighting;

  /// Whether the header's copy affordance is shown.
  final bool showCopyButton;

  /// Optional override merged over `theme.baseStyle` (font family, size,
  /// colour, …). Its `backgroundColor` is ignored — backgrounds belong to
  /// the container.
  final TextStyle? baseStyle;

  /// Inner padding around the code. Defaults to `EdgeInsets.all(12)`.
  final EdgeInsets? padding;

  /// Whether to paint the rounded background/border container.
  final bool decorate;

  @override
  State<CodeBlockView> createState() => _CodeBlockViewState();
}

class _CodeBlockViewState extends State<CodeBlockView> {
  static const Duration _copiedFeedbackDuration = Duration(milliseconds: 1500);

  final ScrollController _scrollController = ScrollController();
  final CodeHighlighter _highlighter = const CodeHighlighter();

  bool _copied = false;
  Timer? _copiedTimer;

  @override
  void dispose() {
    _copiedTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _copy() async {
    final text = widget.code.replaceAll(RegExp(r'[\r\n]+$'), '');
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    setState(() => _copied = true);
    _copiedTimer?.cancel();
    _copiedTimer = Timer(_copiedFeedbackDuration, () {
      if (mounted) {
        setState(() => _copied = false);
      }
    });
  }

  /// Merges [CodeBlockView.baseStyle] over [theme]'s `baseStyle`, dropping
  /// any `backgroundColor`. `copyWith` cannot null out a field, so the
  /// merged style is rebuilt field-by-field (the `fontFamily` getter already
  /// returns the `packages/<pkg>/` prefixed value, so nothing is lost).
  TextStyle _effectiveBaseStyle(CodeBlockTheme theme) {
    final override = widget.baseStyle;
    if (override == null) return theme.baseStyle;
    final merged = theme.baseStyle.merge(override);
    if (merged.backgroundColor == null) return merged;
    return TextStyle(
      inherit: merged.inherit,
      color: merged.color,
      fontSize: merged.fontSize,
      fontWeight: merged.fontWeight,
      fontStyle: merged.fontStyle,
      letterSpacing: merged.letterSpacing,
      wordSpacing: merged.wordSpacing,
      textBaseline: merged.textBaseline,
      height: merged.height,
      leadingDistribution: merged.leadingDistribution,
      locale: merged.locale,
      foreground: merged.foreground,
      background: merged.background,
      shadows: merged.shadows,
      fontFeatures: merged.fontFeatures,
      fontVariations: merged.fontVariations,
      decoration: merged.decoration,
      decorationColor: merged.decorationColor,
      decorationStyle: merged.decorationStyle,
      decorationThickness: merged.decorationThickness,
      debugLabel: merged.debugLabel,
      fontFamily: merged.fontFamily,
      fontFamilyFallback: merged.fontFamilyFallback,
      overflow: merged.overflow,
    );
  }

  CodeBlockTheme _effectiveTheme(CodeBlockTheme theme) {
    final baseStyle = _effectiveBaseStyle(theme);
    if (identical(baseStyle, theme.baseStyle)) return theme;
    return CodeBlockTheme(
      backgroundColor: theme.backgroundColor,
      borderColor: theme.borderColor,
      headerTextColor: theme.headerTextColor,
      baseStyle: baseStyle,
      commentColor: theme.commentColor,
      stringColor: theme.stringColor,
      numberColor: theme.numberColor,
      keywordColor: theme.keywordColor,
      typeColor: theme.typeColor,
      functionColor: theme.functionColor,
      annotationColor: theme.annotationColor,
      punctuationColor: theme.punctuationColor,
      copyTooltip: theme.copyTooltip,
      copiedTooltip: theme.copiedTooltip,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = _effectiveTheme(
      widget.theme ?? CodeBlockTheme.of(Theme.of(context).brightness),
    );
    final language = widget.language?.trim() ?? '';

    Widget child = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (language.isNotEmpty || widget.showCopyButton)
          _Header(
            language: language,
            theme: theme,
            copied: _copied,
            showCopyButton: widget.showCopyButton,
            onCopy: _copy,
          ),
        Scrollbar(
          controller: _scrollController,
          child: SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            padding: widget.padding ?? const EdgeInsets.all(12),
            child: Text.rich(
              _highlighter.highlight(
                widget.code,
                language: widget.language,
                theme: theme,
                enabled: widget.enableSyntaxHighlighting,
              ),
              softWrap: false,
            ),
          ),
        ),
      ],
    );

    if (widget.decorate) {
      child = Container(
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: theme.backgroundColor,
          border: Border.all(color: theme.borderColor, width: 1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: child,
      );
    }

    return Directionality(
      textDirection: TextDirection.ltr,
      child: child,
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.language,
    required this.theme,
    required this.copied,
    required this.showCopyButton,
    required this.onCopy,
  });

  final String language;
  final CodeBlockTheme theme;
  final bool copied;
  final bool showCopyButton;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final tooltip = copied ? theme.copiedTooltip : theme.copyTooltip;
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 4),
      child: Row(
        children: [
          if (language.isNotEmpty)
            Expanded(
              child: Text(
                language.toLowerCase(),
                style: TextStyle(
                  color: theme.headerTextColor,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
            )
          else
            const Spacer(),
          if (showCopyButton)
            Semantics(
              button: true,
              label: tooltip,
              child: IconButton(
                tooltip: tooltip,
                onPressed: onCopy,
                iconSize: 16,
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
                color: theme.headerTextColor,
                icon: Icon(
                  copied ? Icons.check_rounded : Icons.copy_rounded,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A [MarkdownElementBuilder] for `pre` elements that renders fenced code
/// blocks as [CodeBlockView].
///
/// Register it as `builders: {'pre': CodeBlockMarkdownBuilder(...)}` on
/// `MarkdownBody`/`MarkdownWidget`. flutter_markdown_plus still wraps the
/// returned widget in `MarkdownStyleSheet.codeblockDecoration`, so the view
/// is built with `decorate: false` to avoid a double background.
class CodeBlockMarkdownBuilder extends MarkdownElementBuilder {
  CodeBlockMarkdownBuilder({
    this.theme,
    this.enableSyntaxHighlighting = true,
    this.showCopyButton = true,
    this.baseStyle,
  });

  /// Visual theme forwarded to [CodeBlockView.theme].
  final CodeBlockTheme? theme;

  /// Forwarded to [CodeBlockView.enableSyntaxHighlighting].
  final bool enableSyntaxHighlighting;

  /// Forwarded to [CodeBlockView.showCopyButton].
  final bool showCopyButton;

  /// Forwarded to [CodeBlockView.baseStyle].
  final TextStyle? baseStyle;

  String? _language;

  @override
  bool isBlockElement() => true;

  @override
  void visitElementBefore(md.Element element) {
    _language = _extractLanguage(element);
  }

  @override
  Widget? visitText(md.Text text, TextStyle? preferredStyle) =>
      const SizedBox.shrink();

  @override
  Widget visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final language = _language;
    _language = null;
    return CodeBlockView(
      code: element.textContent,
      language: language,
      theme: theme,
      enableSyntaxHighlighting: enableSyntaxHighlighting,
      showCopyButton: showCopyButton,
      baseStyle: baseStyle,
      decorate: false,
    );
  }

  /// Reads the language from a fenced block's `code` child, whose `class`
  /// attribute carries `language-xxx`.
  static String? _extractLanguage(md.Element element) {
    for (final child in element.children ?? const <md.Node>[]) {
      if (child is md.Element && child.tag == 'code') {
        final className = child.attributes['class'];
        if (className == null || className.isEmpty) return null;
        const prefix = 'language-';
        return className.startsWith(prefix)
            ? className.substring(prefix.length)
            : className;
      }
    }
    return null;
  }
}
