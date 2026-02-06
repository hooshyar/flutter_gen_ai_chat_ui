import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/chat/citation.dart';

/// Theme configuration for citation chips
class CitationChipTheme {
  /// Background color for the chip
  final Color? backgroundColor;

  /// Text color for the chip
  final Color? textColor;

  /// Icon color for the chip
  final Color? iconColor;

  /// Border color (if using outlined style)
  final Color? borderColor;

  /// Border radius for the chip
  final double borderRadius;

  /// Padding inside the chip
  final EdgeInsets padding;

  /// Text style for the citation text
  final TextStyle? textStyle;

  /// Icon to display (default: gavel for legal)
  final IconData? icon;

  /// Whether to show the icon
  final bool showIcon;

  /// Whether to use outlined style (vs filled)
  final bool outlined;

  const CitationChipTheme({
    this.backgroundColor,
    this.textColor,
    this.iconColor,
    this.borderColor,
    this.borderRadius = 8.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    this.textStyle,
    this.icon,
    this.showIcon = true,
    this.outlined = false,
  });

  /// Default theme using primary color
  static CitationChipTheme defaultTheme(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    return CitationChipTheme(
      backgroundColor: primaryColor.withOpacity(0.1),
      textColor: primaryColor,
      iconColor: primaryColor,
      borderColor: primaryColor.withOpacity(0.3),
    );
  }

  /// Elegant theme with subtle styling
  static CitationChipTheme elegant(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return CitationChipTheme(
      backgroundColor: isDark
          ? Colors.white.withOpacity(0.08)
          : Colors.black.withOpacity(0.04),
      textColor: isDark ? Colors.white70 : Colors.black87,
      iconColor: isDark ? Colors.white54 : Colors.black54,
      borderRadius: 12,
      outlined: true,
      borderColor: isDark
          ? Colors.white.withOpacity(0.15)
          : Colors.black.withOpacity(0.1),
    );
  }

  /// Legal theme with gavel icon
  static CitationChipTheme legal(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    return CitationChipTheme(
      backgroundColor: primaryColor.withOpacity(0.12),
      textColor: primaryColor,
      iconColor: primaryColor,
      icon: Icons.gavel,
      borderRadius: 10,
    );
  }

  /// Minimal theme with no icon
  static CitationChipTheme minimal(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return CitationChipTheme(
      backgroundColor: isDark
          ? Colors.white.withOpacity(0.05)
          : Colors.grey.withOpacity(0.1),
      textColor: isDark ? Colors.white70 : Colors.grey[700],
      showIcon: false,
      borderRadius: 6,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }
}

/// A chip widget for displaying citations/source references
class CitationChip extends StatelessWidget {
  /// The citation to display
  final ChatCitation citation;

  /// Optional theme for the chip
  final CitationChipTheme? theme;

  /// Callback when the chip is tapped
  final VoidCallback? onTap;

  /// Callback when the chip is long pressed (for copy)
  final VoidCallback? onLongPress;

  /// Language code for localized display
  final String language;

  /// Whether to show in compact mode
  final bool compact;

  /// Whether to enable copy on long press
  final bool enableCopy;

  /// Custom tooltip message
  final String? tooltip;

  const CitationChip({
    super.key,
    required this.citation,
    this.theme,
    this.onTap,
    this.onLongPress,
    this.language = 'en',
    this.compact = false,
    this.enableCopy = true,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveTheme = theme ?? CitationChipTheme.defaultTheme(context);

    Widget chip = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: enableCopy
            ? () {
                _copyToClipboard(context);
                onLongPress?.call();
              }
            : onLongPress,
        borderRadius: BorderRadius.circular(effectiveTheme.borderRadius),
        child: Container(
          padding: compact
              ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
              : effectiveTheme.padding,
          decoration: BoxDecoration(
            color: effectiveTheme.outlined
                ? Colors.transparent
                : effectiveTheme.backgroundColor,
            borderRadius: BorderRadius.circular(effectiveTheme.borderRadius),
            border: effectiveTheme.outlined
                ? Border.all(
                    color: effectiveTheme.borderColor ??
                        effectiveTheme.textColor?.withOpacity(0.3) ??
                        Colors.grey,
                    width: 1,
                  )
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (effectiveTheme.showIcon) ...[
                Icon(
                  effectiveTheme.icon ?? Icons.article_outlined,
                  size: compact ? 12 : 14,
                  color: effectiveTheme.iconColor ?? effectiveTheme.textColor,
                ),
                SizedBox(width: compact ? 4 : 6),
              ],
              Flexible(
                child: Text(
                  _getDisplayText(),
                  style: effectiveTheme.textStyle ??
                      TextStyle(
                        fontSize: compact ? 11 : 12,
                        fontWeight: FontWeight.w500,
                        color: effectiveTheme.textColor,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onTap != null) ...[
                SizedBox(width: compact ? 2 : 4),
                Icon(
                  Icons.chevron_right,
                  size: compact ? 12 : 14,
                  color: (effectiveTheme.iconColor ?? effectiveTheme.textColor)
                      ?.withOpacity(0.6),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (tooltip != null || citation.hasContent) {
      chip = Tooltip(
        message: tooltip ?? _getTooltipText(),
        preferBelow: true,
        child: chip,
      );
    }

    return chip;
  }

  String _getDisplayText() {
    // Use localized citation if available, otherwise short citation
    final localizedCitation = citation.getCitationInLanguage(language);
    if (localizedCitation.isNotEmpty && localizedCitation != citation.fullCitation) {
      return localizedCitation;
    }
    return citation.shortCitation.isNotEmpty
        ? citation.shortCitation
        : citation.fullCitation;
  }

  String _getTooltipText() {
    final parts = <String>[];

    final title = citation.getTitleInLanguage(language);
    if (title != null && title.isNotEmpty) {
      parts.add(title);
    }

    if (citation.year != null) {
      parts.add('(${citation.year})');
    }

    final content = citation.getContentInLanguage(language);
    if (content != null && content.isNotEmpty) {
      // Truncate content for tooltip
      final truncated = content.length > 100
          ? '${content.substring(0, 100)}...'
          : content;
      parts.add(truncated);
    }

    return parts.join('\n');
  }

  void _copyToClipboard(BuildContext context) {
    final textToCopy = citation.fullCitation.isNotEmpty
        ? citation.fullCitation
        : citation.shortCitation;

    Clipboard.setData(ClipboardData(text: textToCopy));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_getCopyMessage()),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _getCopyMessage() {
    switch (language) {
      case 'ar':
        return 'تم نسخ الاستشهاد';
      case 'ku':
        return 'سەرچاوە کۆپی کرا';
      default:
        return 'Citation copied';
    }
  }
}

/// A section widget displaying a list of citations
class CitationsSection extends StatelessWidget {
  /// The citations data to display
  final ChatCitationsData citationsData;

  /// Optional theme for the chips
  final CitationChipTheme? chipTheme;

  /// Callback when a citation is tapped
  final void Function(ChatCitation)? onCitationTap;

  /// Maximum number of citations to show (others collapsed)
  final int? maxVisible;

  /// Whether to show in compact mode
  final bool compact;

  /// Custom section label
  final String? sectionLabel;

  /// Style for the section label
  final TextStyle? labelStyle;

  /// Spacing between chips
  final double chipSpacing;

  /// Run spacing for wrapped chips
  final double runSpacing;

  const CitationsSection({
    super.key,
    required this.citationsData,
    this.chipTheme,
    this.onCitationTap,
    this.maxVisible,
    this.compact = false,
    this.sectionLabel,
    this.labelStyle,
    this.chipSpacing = 8,
    this.runSpacing = 8,
  });

  @override
  Widget build(BuildContext context) {
    if (!citationsData.hasCitations) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final citations = maxVisible != null
        ? citationsData.citations.take(maxVisible!).toList()
        : citationsData.citations;
    final hasMore = maxVisible != null &&
        citationsData.citations.length > maxVisible!;

    return Container(
      padding: EdgeInsets.only(top: compact ? 6 : 8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.06),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Section label
          Padding(
            padding: EdgeInsets.only(bottom: compact ? 4 : 6),
            child: Text(
              sectionLabel ??
                  citationsData.sectionLabel ??
                  citationsData.getDefaultSectionLabel(),
              style: labelStyle ??
                  TextStyle(
                    fontSize: compact ? 10 : 11,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? Colors.white.withOpacity(0.6)
                        : Colors.black.withOpacity(0.5),
                    letterSpacing: 0.3,
                  ),
            ),
          ),
          // Citation chips
          Wrap(
            spacing: chipSpacing,
            runSpacing: runSpacing,
            children: [
              ...citations.map((citation) => CitationChip(
                    citation: citation,
                    theme: chipTheme,
                    language: citationsData.language,
                    compact: compact,
                    onTap: onCitationTap != null
                        ? () => onCitationTap!(citation)
                        : null,
                  )),
              if (hasMore)
                _buildMoreChip(
                  context,
                  citationsData.citations.length - maxVisible!,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMoreChip(BuildContext context, int count) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '+$count',
        style: TextStyle(
          fontSize: compact ? 10 : 11,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white54 : Colors.grey[600],
        ),
      ),
    );
  }
}

/// An expanded view for showing citation content
class CitationExpandedView extends StatelessWidget {
  /// The citation to display
  final ChatCitation citation;

  /// Language code for localized display
  final String language;

  /// Callback to close the view
  final VoidCallback? onClose;

  /// Optional theme for styling
  final CitationChipTheme? theme;

  const CitationExpandedView({
    super.key,
    required this.citation,
    this.language = 'en',
    this.onClose,
    this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : primaryColor.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : primaryColor.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with close button
          Row(
            children: [
              Icon(
                Icons.gavel,
                size: 18,
                color: primaryColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  citation.getCitationInLanguage(language),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              if (onClose != null)
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: onClose,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
            ],
          ),
          // Source title if available
          if (citation.getTitleInLanguage(language) != null) ...[
            const SizedBox(height: 8),
            Text(
              citation.getTitleInLanguage(language)!,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
          // Content if available
          if (citation.getContentInLanguage(language) != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withOpacity(0.2)
                    : Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                citation.getContentInLanguage(language)!,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: isDark ? Colors.white.withOpacity(0.85) : Colors.black87,
                ),
              ),
            ),
          ],
          // Actions
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: citation.fullCitation));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(_getCopyMessage()),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: Icon(
                  Icons.copy,
                  size: 16,
                  color: primaryColor,
                ),
                label: Text(
                  _getCopyLabel(),
                  style: TextStyle(
                    fontSize: 12,
                    color: primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getCopyLabel() {
    switch (language) {
      case 'ar':
        return 'نسخ';
      case 'ku':
        return 'کۆپی';
      default:
        return 'Copy';
    }
  }

  String _getCopyMessage() {
    switch (language) {
      case 'ar':
        return 'تم نسخ الاستشهاد';
      case 'ku':
        return 'سەرچاوە کۆپی کرا';
      default:
        return 'Citation copied';
    }
  }
}
