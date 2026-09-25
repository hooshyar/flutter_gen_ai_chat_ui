import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/code_block_theme.dart';
import 'code/code_block_view.dart';

/// Rich message content widget with advanced features
class RichMessageContent extends StatelessWidget {
  final String text;
  final TextStyle? textStyle;
  final EdgeInsets padding;
  final bool enableTextSelection;
  final bool showCopyButton;
  final VoidCallback? onTextCopy;

  const RichMessageContent({
    super.key,
    required this.text,
    this.textStyle,
    this.padding = const EdgeInsets.all(12),
    this.enableTextSelection = true,
    this.showCopyButton = true,
    this.onTextCopy,
  });

  @override
  Widget build(BuildContext context) {
    if (enableTextSelection) {
      return SelectableText.rich(
        _buildTextSpan(context),
        style: textStyle ?? Theme.of(context).textTheme.bodyMedium,
        contextMenuBuilder: showCopyButton ? _buildContextMenu : null,
      );
    }

    return RichText(text: _buildTextSpan(context));
  }

  TextSpan _buildTextSpan(BuildContext context) {
    // Enhanced text processing with multiple features
    return TextSpan(
      text: text,
      style: textStyle ?? Theme.of(context).textTheme.bodyMedium,
    );
  }

  Widget _buildContextMenu(
    BuildContext context,
    EditableTextState editableTextState,
  ) {
    return AdaptiveTextSelectionToolbar.buttonItems(
      anchors: editableTextState.contextMenuAnchors,
      buttonItems: [
        // Copy button
        ContextMenuButtonItem(
          onPressed: () {
            _copyToClipboard();
            ContextMenuController.removeAny();
          },
          type: ContextMenuButtonType.copy,
        ),
      ],
    );
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: text));
    onTextCopy?.call();
  }
}

/// Advanced markdown-style content renderer
class MarkdownContent extends StatelessWidget {
  final String markdown;
  final TextStyle? textStyle;
  final EdgeInsets padding;
  final bool enableSyntaxHighlighting;
  final Map<String, TextStyle> codeTheme;

  const MarkdownContent({
    super.key,
    required this.markdown,
    this.textStyle,
    this.padding = const EdgeInsets.all(12),
    this.enableSyntaxHighlighting = true,
    this.codeTheme = const {},
  });

  @override
  Widget build(BuildContext context) {
    return Container(padding: padding, child: _buildMarkdownContent(context));
  }

  Widget _buildMarkdownContent(BuildContext context) {
    final baseStyle = textStyle ?? Theme.of(context).textTheme.bodyMedium!;
    final spans = <InlineSpan>[];

    // Simple markdown parsing for common patterns
    final lines = markdown.split('\n');

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];

      if (line.startsWith('```')) {
        // Code block — the opening fence may carry a language tag.
        final language = line.substring(3).trim();
        final codeLines = <String>[];
        i++; // Skip the opening ```

        while (i < lines.length && !lines[i].startsWith('```')) {
          codeLines.add(lines[i]);
          i++;
        }

        spans.add(
          WidgetSpan(
            child: _buildCodeBlock(
              codeLines.join('\n'),
              language.isEmpty ? null : language,
              context,
            ),
          ),
        );
      } else if (line.startsWith('# ')) {
        // Header
        spans.add(
          TextSpan(
            text: '${line.substring(2)}\n',
            style: baseStyle.copyWith(
              fontSize: (baseStyle.fontSize ?? 14) * 1.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      } else if (line.startsWith('## ')) {
        // Sub-header
        spans.add(
          TextSpan(
            text: '${line.substring(3)}\n',
            style: baseStyle.copyWith(
              fontSize: (baseStyle.fontSize ?? 14) * 1.3,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      } else if (line.startsWith('- ') || line.startsWith('* ')) {
        // List item
        spans.add(TextSpan(text: '• ${line.substring(2)}\n', style: baseStyle));
      } else {
        // Regular text with inline formatting
        spans.add(_parseInlineMarkdown('$line\n', baseStyle));
      }
    }

    return RichText(text: TextSpan(children: spans));
  }

  TextSpan _parseInlineMarkdown(String text, TextStyle baseStyle) {
    final spans = <InlineSpan>[];
    final buffer = StringBuffer();
    var inBold = false;
    var inItalic = false;
    var inCode = false;

    for (var i = 0; i < text.length; i++) {
      final char = text[i];
      final nextChar = i + 1 < text.length ? text[i + 1] : '';

      if (char == '*' && nextChar == '*' && !inCode) {
        // Bold
        if (buffer.isNotEmpty) {
          spans.add(
            TextSpan(
              text: buffer.toString(),
              style: _getCurrentStyle(baseStyle, inBold, inItalic, inCode),
            ),
          );
          buffer.clear();
        }
        inBold = !inBold;
        i++; // Skip next *
      } else if (char == '*' && !inCode) {
        // Italic
        if (buffer.isNotEmpty) {
          spans.add(
            TextSpan(
              text: buffer.toString(),
              style: _getCurrentStyle(baseStyle, inBold, inItalic, inCode),
            ),
          );
          buffer.clear();
        }
        inItalic = !inItalic;
      } else if (char == '`') {
        // Inline code
        if (buffer.isNotEmpty) {
          spans.add(
            TextSpan(
              text: buffer.toString(),
              style: _getCurrentStyle(baseStyle, inBold, inItalic, inCode),
            ),
          );
          buffer.clear();
        }
        inCode = !inCode;
      } else {
        buffer.write(char);
      }
    }

    if (buffer.isNotEmpty) {
      spans.add(
        TextSpan(
          text: buffer.toString(),
          style: _getCurrentStyle(baseStyle, inBold, inItalic, inCode),
        ),
      );
    }

    return TextSpan(children: spans);
  }

  TextStyle _getCurrentStyle(
    TextStyle base,
    bool bold,
    bool italic,
    bool code,
  ) {
    var style = base;

    if (bold) {
      style = style.copyWith(fontWeight: FontWeight.bold);
    }
    if (italic) {
      style = style.copyWith(fontStyle: FontStyle.italic);
    }
    if (code) {
      style = style.copyWith(
        fontFamily: 'monospace',
        backgroundColor: Colors.grey.withValues(alpha: 0.1),
      );
    }

    return style;
  }

  Widget _buildCodeBlock(String code, String? language, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        width: double.infinity,
        child: CodeBlockView(
          code: code,
          language: language,
          theme: _resolveCodeTheme(context),
          enableSyntaxHighlighting: enableSyntaxHighlighting,
        ),
      ),
    );
  }

  /// Maps the legacy [codeTheme] token map onto a [CodeBlockTheme]. Keys are
  /// token-kind names (`comment`, `string`, `number`, `keyword`, `type`,
  /// `function`, `annotation`); each entry's `color` overrides that token's
  /// color on top of the ambient light/dark palette. Unknown keys and
  /// colorless styles are ignored.
  CodeBlockTheme _resolveCodeTheme(BuildContext context) {
    final base = CodeBlockTheme.of(Theme.of(context).brightness);
    if (codeTheme.isEmpty) return base;

    Color? colorOf(String key) => codeTheme[key]?.color;

    return CodeBlockTheme(
      backgroundColor: base.backgroundColor,
      borderColor: base.borderColor,
      headerTextColor: base.headerTextColor,
      baseStyle: base.baseStyle,
      commentColor: colorOf('comment') ?? base.commentColor,
      stringColor: colorOf('string') ?? base.stringColor,
      numberColor: colorOf('number') ?? base.numberColor,
      keywordColor: colorOf('keyword') ?? base.keywordColor,
      typeColor: colorOf('type') ?? base.typeColor,
      functionColor: colorOf('function') ?? base.functionColor,
      annotationColor: colorOf('annotation') ?? base.annotationColor,
      punctuationColor: base.punctuationColor,
      copyTooltip: base.copyTooltip,
      copiedTooltip: base.copiedTooltip,
    );
  }
}

/// Interactive content with action buttons
class InteractiveContent extends StatelessWidget {
  final String content;
  final List<ContentAction> actions;
  final TextStyle? textStyle;
  final EdgeInsets padding;

  const InteractiveContent({
    super.key,
    required this.content,
    this.actions = const [],
    this.textStyle,
    this.padding = const EdgeInsets.all(12),
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: padding,
          child: SelectableText(
            content,
            style: textStyle ?? Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        if (actions.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: actions
                .map((action) => _buildActionButton(action, context))
                .toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButton(ContentAction action, BuildContext context) {
    return FilledButton.tonal(
      onPressed: action.onPressed,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: const Size(0, 32),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (action.icon != null) ...[
            Icon(action.icon, size: 16),
            const SizedBox(width: 4),
          ],
          Text(action.label, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}

/// Content action definition
class ContentAction {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;

  const ContentAction({
    required this.label,
    required this.onPressed,
    this.icon,
  });
}

/// Collapsible content section
class CollapsibleContent extends StatefulWidget {
  final String title;
  final String content;
  final bool initiallyExpanded;
  final TextStyle? titleStyle;
  final TextStyle? contentStyle;
  final EdgeInsets padding;

  const CollapsibleContent({
    super.key,
    required this.title,
    required this.content,
    this.initiallyExpanded = false,
    this.titleStyle,
    this.contentStyle,
    this.padding = const EdgeInsets.all(12),
  });

  @override
  State<CollapsibleContent> createState() => _CollapsibleContentState();
}

class _CollapsibleContentState extends State<CollapsibleContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    if (_isExpanded) {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: widget.padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: _toggleExpansion,
            child: Row(
              children: [
                AnimatedRotation(
                  turns: _isExpanded ? 0.25 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: const Icon(Icons.chevron_right, size: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.title,
                    style: widget.titleStyle ??
                        Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: Padding(
              padding: const EdgeInsets.only(left: 28, top: 8),
              child: SelectableText(
                widget.content,
                style: widget.contentStyle ??
                    Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
