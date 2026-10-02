import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;

import '../../theme/chat_tokens.dart';
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

  /// Inner padding around the code. Defaults to
  /// `EdgeInsets.symmetric(vertical: 14, horizontal: 16)`.
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

  /// Whether there is more code to scroll to at the right edge.
  bool _canScrollRight = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateCanScrollRight);
  }

  @override
  void dispose() {
    _copiedTimer?.cancel();
    _scrollController.removeListener(_updateCanScrollRight);
    _scrollController.dispose();
    super.dispose();
  }

  /// `widget.code` with exactly one trailing newline removed.
  ///
  /// Markdown fences hand us `element.textContent`, which always ends with
  /// a `\n` from the closing fence line — rendering it as-is adds a whole
  /// blank trailing line (most visible as dead space below one-line
  /// blocks). Only a single trailing `\r\n`/`\n` is stripped (not
  /// `trimRight()`, which would also eat intentional trailing blank lines
  /// a caller passed on purpose) and the same trimmed string is what gets
  /// copied, so copy output matches what's on screen.
  String get _displayCode {
    final code = widget.code;
    if (code.endsWith('\r\n')) return code.substring(0, code.length - 2);
    if (code.endsWith('\n')) return code.substring(0, code.length - 1);
    return code;
  }

  void _updateCanScrollRight() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final canScrollRight = position.pixels < position.maxScrollExtent - 1;
    if (canScrollRight != _canScrollRight) {
      setState(() => _canScrollRight = canScrollRight);
    }
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _displayCode));
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
    final hasHeader = language.isNotEmpty || widget.showCopyButton;

    // The scroll extent is only known after this frame lays out; schedule a
    // check so the edge fade appears/disappears as soon as it's accurate
    // (e.g. when `code` changes length between builds).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateCanScrollRight();
    });

    Widget codeArea = Scrollbar(
      controller: _scrollController,
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: widget.padding ??
            const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        child: Text.rich(
          _highlighter.highlight(
            _displayCode,
            language: widget.language,
            theme: theme,
            enabled: widget.enableSyntaxHighlighting,
          ),
          softWrap: false,
        ),
      ),
    );

    if (_canScrollRight) {
      codeArea = ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          stops: [0, 0.94, 1],
          colors: [Colors.white, Colors.white, Colors.transparent],
        ).createShader(bounds),
        blendMode: BlendMode.dstIn,
        child: codeArea,
      );
    }

    Widget child = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasHeader) ...[
          _Header(
            language: language,
            theme: theme,
            copied: _copied,
            showCopyButton: widget.showCopyButton,
            onCopy: _copy,
          ),
          Container(height: 1, color: theme.borderColor),
        ],
        codeArea,
      ],
    );

    if (widget.decorate) {
      child = Container(
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: theme.backgroundColor,
          border: Border.all(color: theme.borderColor, width: 1),
          borderRadius: BorderRadius.circular(ChatRadius.md),
        ),
        child: child,
      );
    }

    return Directionality(textDirection: TextDirection.ltr, child: child);
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
    return SizedBox(
      height: 44,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(start: 12, end: 0),
        child: Row(
          children: [
            if (language.isNotEmpty)
              Expanded(
                child: Text(
                  language.toLowerCase(),
                  style: theme.baseStyle.copyWith(
                    color: theme.headerTextColor,
                    fontSize: 12,
                    letterSpacing: 0.2,
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
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                  color: theme.headerTextColor,
                  icon: AnimatedSwitcher(
                    duration: ChatMotion.of(context, ChatMotion.fast),
                    child: Icon(
                      copied ? Icons.check_rounded : Icons.copy_rounded,
                      key: ValueKey(copied),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A [MarkdownElementBuilder] for `pre` elements that renders fenced code
/// blocks as [CodeBlockView].
///
/// Register it as `builders: {'pre': CodeBlockMarkdownBuilder(...)}` on
/// `MarkdownBody`/`MarkdownWidget`. flutter_markdown_plus always wraps the
/// returned widget in a `Container(decoration: styleSheet.codeblockDecoration)`
/// with no public hook to add space *outside* that container (its
/// `codeblockPadding`/`paddingBuilders` only apply inside it, or — for
/// `paddingBuilders` — only to the `hr` tag in this version).
///
/// [ownsDecoration] controls how that's reconciled with `DESIGN.md` §4's
/// code-block vertical rhythm:
/// - `true` (the package's own default path — see `chatMarkdownStyle`,
///   which sets `codeblockDecoration` to a fully transparent
///   `BoxDecoration()` for exactly this): this builder paints the
///   background/border/radius itself via `CodeBlockView(decorate: true)`
///   *inside* a bottom [Padding], so the added space stays empty instead
///   of inheriting the code block's chrome — see the field's doc comment
///   for why a symmetric top margin isn't added the same way.
/// - `false` (a caller supplied their own
///   `MessageOptions.markdownStyleSheet` with a real `codeblockDecoration`
///   — `code_block_rendering_test.dart`'s "user markdownStyleSheet
///   codeblockDecoration still wraps the block"): this builder must not
///   also paint a decoration, or the block would show doubled-up
///   chrome — same as this class's behavior before the spacing fix.
class CodeBlockMarkdownBuilder extends MarkdownElementBuilder {
  CodeBlockMarkdownBuilder({
    this.theme,
    this.enableSyntaxHighlighting = true,
    this.showCopyButton = true,
    this.baseStyle,
    this.ownsDecoration = true,
    this.padding,
  });

  /// Visual theme forwarded to [CodeBlockView.theme].
  final CodeBlockTheme? theme;

  /// Forwarded to [CodeBlockView.enableSyntaxHighlighting].
  final bool enableSyntaxHighlighting;

  /// Forwarded to [CodeBlockView.showCopyButton].
  final bool showCopyButton;

  /// Forwarded to [CodeBlockView.baseStyle].
  final TextStyle? baseStyle;

  /// See the class doc comment. Set to `false` when the ambient
  /// `MarkdownStyleSheet.codeblockDecoration` is a caller-supplied,
  /// non-transparent value that already paints the block's chrome.
  final bool ownsDecoration;

  /// Forwarded to [CodeBlockView.padding].
  ///
  /// flutter_markdown_plus's own `MarkdownStyleSheet.codeblockPadding` is
  /// only consumed on its own `pre` rendering path — registering a custom
  /// `pre` builder (this class) bypasses that path entirely, so a caller's
  /// `codeblockPadding` would otherwise be silently dropped even though
  /// they set it on the very stylesheet passed to `MessageOptions`. Set
  /// this from that value (when non-null) so it still takes effect.
  final EdgeInsets? padding;

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
    final view = CodeBlockView(
      code: element.textContent,
      language: language,
      theme: theme,
      enableSyntaxHighlighting: enableSyntaxHighlighting,
      showCopyButton: showCopyButton,
      baseStyle: baseStyle,
      decorate: ownsDecoration,
      padding: padding,
    );
    if (!ownsDecoration) return view;
    // Bottom-only: the ambient block spacing plus this already lines up
    // the gap *above* a code block (e.g. a heading's own bottom padding
    // plus block spacing) with `DESIGN.md` §4's ~12-16px paragraph rhythm,
    // so adding a symmetric top margin here would double up on top of
    // that instead of matching it — see the class doc comment.
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: ChatSpace.s8),
      child: view,
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
