import 'package:flutter/material.dart';

import '../../theme/chat_tokens.dart';

/// The package's default composer send/stop control (`DESIGN.md` §8.5).
///
/// A single 48x48 hit area around a 36px disc that morphs between three
/// states as the composer's text and generation status change:
///
/// - **Enabled** (text present, not generating): filled [ChatTokens.ink]
///   disc with an [icon] (defaults to `Icons.arrow_upward_rounded`) in
///   [ChatTokens.onInk].
/// - **Empty** (no text, not generating): the same disc at a low fixed
///   alpha, an untappable [icon] in [ChatTokens.textTertiary], and a
///   `"Send message, disabled"` semantics label.
/// - **Generating** ([isGenerating] true with [onCancel] provided): the
///   disc shows a small rounded square instead of [icon] and tapping calls
///   [onCancel]; the tooltip becomes `"Stop generating"`.
///
/// Used by `ChatInput` only when the consumer has not supplied
/// `sendButtonBuilder`, `sendOrMicBuilder`, or `cancelButtonBuilder` — any of
/// those replace this widget entirely. An explicit `InputOptions.sendButtonIcon`
/// / `InputOptions.sendButtonColor` still applies on top of this default (see
/// [icon] / [enabledFillColor]).
class SendStopButton extends StatefulWidget {
  /// Creates the default send/stop composer control.
  const SendStopButton({
    super.key,
    required this.isEmpty,
    required this.onSend,
    this.isGenerating = false,
    this.onCancel,
    this.icon,
    this.enabledFillColor,
    this.tooltip,
  });

  /// Whether the composer's text field is currently empty (trimmed).
  final bool isEmpty;

  /// Invoked when the control is tapped in the enabled (non-generating,
  /// non-empty) state.
  final VoidCallback onSend;

  /// Whether a response is currently being generated.
  final bool isGenerating;

  /// Invoked when the control is tapped while [isGenerating] is true. When
  /// null, [isGenerating] is treated as false (matches `ChatInput`'s
  /// existing stop-button gating).
  final VoidCallback? onCancel;

  /// Icon used for the send state (enabled and empty). Defaults to
  /// `Icons.arrow_upward_rounded`. Never used for the generating state,
  /// which always renders the fixed stop square.
  final IconData? icon;

  /// Explicit fill color for the enabled (non-empty, non-generating) state,
  /// overriding the default `ChatTokens.ink`. The empty and generating fills
  /// are always token-derived so the disabled/busy states stay legible.
  final Color? enabledFillColor;

  /// Explicit tooltip for the enabled send state. Defaults to
  /// `"Send message"`. The generating state's tooltip is always
  /// `"Stop generating"`.
  final String? tooltip;

  @override
  State<SendStopButton> createState() => _SendStopButtonState();
}

class _SendStopButtonState extends State<SendStopButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ChatTokens.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final icon = widget.icon ?? Icons.arrow_upward_rounded;

    final generating = widget.isGenerating && widget.onCancel != null;
    final disabled = !generating && widget.isEmpty;

    late final Color fill;
    late final Widget glyph;
    late final String semanticsLabel;
    late final String tooltipMessage;
    late final VoidCallback? onTap;

    if (generating) {
      fill = tokens.ink;
      glyph = Container(
        key: const ValueKey('send-stop-button-stop'),
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: tokens.onInk,
          borderRadius: BorderRadius.circular(3),
        ),
      );
      semanticsLabel = 'Stop generating';
      tooltipMessage = 'Stop generating';
      onTap = widget.onCancel;
    } else if (disabled) {
      fill = tokens.ink.withValues(alpha: isDark ? 0.16 : 0.12);
      glyph = Icon(
        icon,
        key: const ValueKey('send-stop-button-disabled'),
        size: 20,
        color: tokens.textTertiary,
      );
      semanticsLabel = 'Send message, disabled';
      // Still tooltipped (`DESIGN.md` §8.13: every icon-only control has a
      // tooltip and a semantics label, disabled or not).
      tooltipMessage = widget.tooltip ?? 'Send message';
      onTap = null;
    } else {
      fill = widget.enabledFillColor ?? tokens.ink;
      glyph = Icon(
        icon,
        key: const ValueKey('send-stop-button-enabled'),
        size: 20,
        color: tokens.onInk,
      );
      semanticsLabel = 'Send message';
      tooltipMessage = widget.tooltip ?? 'Send message';
      onTap = widget.onSend;
    }

    Widget disc = AnimatedContainer(
      duration: ChatMotion.of(context, ChatMotion.fast),
      curve: ChatMotion.enter,
      width: 36,
      height: 36,
      alignment: Alignment.center,
      // A 36px-diameter circle expressed as `borderRadius` rather than
      // `BoxShape.circle` — visually identical, but avoids colliding with
      // other widgets' `decoration.shape == BoxShape.circle` predicates
      // (e.g. the typing-indicator dots' own test helper) when scanning the
      // whole tree for "the circular Container".
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(18),
      ),
      child: AnimatedSwitcher(
        duration: ChatMotion.of(context, ChatMotion.sendMorph),
        switchInCurve: ChatMotion.enter,
        switchOutCurve: ChatMotion.exit,
        child: glyph,
      ),
    );

    disc = AnimatedScale(
      scale: _pressed ? 0.96 : 1.0,
      duration: ChatMotion.of(context, ChatMotion.press),
      curve: ChatMotion.enter,
      child: disc,
    );

    final control = Semantics(
      button: true,
      enabled: onTap != null,
      label: semanticsLabel,
      child: SizedBox(
        width: 48,
        height: 48,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: onTap == null ? null : (_) => _setPressed(true),
          onTapUp: onTap == null ? null : (_) => _setPressed(false),
          onTapCancel: onTap == null ? null : () => _setPressed(false),
          onTap: onTap,
          child: Center(child: disc),
        ),
      ),
    );

    return Tooltip(message: tooltipMessage, child: control);
  }
}
