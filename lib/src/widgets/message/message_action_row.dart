import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/chat_tokens.dart';

/// The action row rendered below a completed AI message: an optional copy
/// control, then the timestamp at the trailing end (`DESIGN.md` §8.8).
///
/// Hidden entirely while [isStreaming] is true. On hover-capable platforms
/// it fades in on hover/keyboard focus; it is always shown on touch
/// platforms and when [alwaysVisible] is set (the package uses this for the
/// latest AI message, so the primary action is never hidden behind a hover
/// state the user hasn't discovered yet).
class MessageActionRow extends StatefulWidget {
  const MessageActionRow({
    super.key,
    required this.text,
    required this.timestampText,
    this.onCopy,
    this.alwaysVisible = false,
    this.isStreaming = false,
    this.showCopyButton = true,
    this.copyButtonLabel,
    this.showTimestamp = true,
    this.timestampStyle,
  });

  /// The raw message text copied to the clipboard.
  final String text;

  /// Pre-formatted timestamp shown at the end of the row.
  final String timestampText;

  /// Called with [text] after a successful copy. The row never shows a
  /// [SnackBar] itself — feedback is the icon swapping to a checkmark.
  final void Function(String)? onCopy;

  /// Keeps the row at full opacity regardless of hover/focus/touch state.
  final bool alwaysVisible;

  /// Hides the row entirely while true.
  final bool isStreaming;

  /// Whether the copy control renders at all.
  final bool showCopyButton;

  /// Tooltip/semantics label for the copy control. Defaults to `'Copy'`.
  final String? copyButtonLabel;

  /// Whether the timestamp [Text] renders at all (`MessageOptions.showTime`).
  /// The copy control is unaffected — only the trailing timestamp is hidden.
  final bool showTimestamp;

  /// Style for the timestamp text. Falls back to the row's caption/
  /// `textTertiary` default when null (`MessageOptions.aiTimeTextStyle` ??
  /// `timeTextStyle`, resolved by the caller).
  final TextStyle? timestampStyle;

  @override
  State<MessageActionRow> createState() => _MessageActionRowState();
}

class _MessageActionRowState extends State<MessageActionRow> {
  bool _hovered = false;
  bool _focused = false;
  bool _justCopied = false;

  bool get _isTouchPlatform =>
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.android;

  void _handleCopy() {
    Clipboard.setData(ClipboardData(text: widget.text));
    widget.onCopy?.call(widget.text);
    setState(() => _justCopied = true);
    Future<void>.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _justCopied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isStreaming) {
      return const SizedBox.shrink();
    }

    final tokens = ChatTokens.of(context);
    final visible =
        widget.alwaysVisible || _isTouchPlatform || _hovered || _focused;

    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showCopyButton)
          Tooltip(
            message: widget.copyButtonLabel ?? 'Copy',
            // The hit area stays >=48 logical px (a11y minimum tap target),
            // but it is anchored so the glyph's START edge sits at the row's
            // start edge instead of being centred in the box: centring an
            // IconButton's default hit area put the glyph well right of the
            // message text's start edge (`DESIGN.md` §8.8 — the copy icon
            // must line up with the text above it). `alignment:
            // centerStart` with zero padding pins the icon to the box's
            // start edge; the hit area then simply extends further to the
            // end (right, in LTR) without moving the glyph. Directional
            // values keep this correct in RTL.
            child: SizedBox(
              width: 48,
              height: 48,
              child: IconButton(
                padding: EdgeInsets.zero,
                alignment: AlignmentDirectional.centerStart,
                onPressed: _handleCopy,
                icon: Icon(
                  _justCopied
                      ? Icons.check_rounded
                      : Icons.content_copy_rounded,
                  size: 16,
                  color: tokens.textTertiary,
                ),
              ),
            ),
          ),
        if (widget.showTimestamp) ...[
          const SizedBox(width: ChatSpace.s8),
          Text(
            widget.timestampText,
            style: widget.timestampStyle ??
                TextStyle(
                  fontSize: 12,
                  height: 16 / 12,
                  letterSpacing: 0.1,
                  color: tokens.textTertiary,
                ),
          ),
        ],
      ],
    );

    return FocusableActionDetector(
      onShowHoverHighlight: (hovering) => setState(() => _hovered = hovering),
      onShowFocusHighlight: (focused) => setState(() => _focused = focused),
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: ChatMotion.of(context, ChatMotion.fast),
        child: row,
      ),
    );
  }
}
