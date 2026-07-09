import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// An input field that can display a faint inline "ghost" suggestion after the
/// user's current text, and accept it with Tab (optional).
///
/// This widget is UI-only and backend-agnostic. Provide [ghostText] externally.
class InlineAutocompleteTextField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final InputDecoration? decoration;
  final TextStyle? style;
  final String? ghostText;
  final VoidCallback? onAcceptGhost;
  final bool acceptOnTab;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;

  /// For testing and special cases: force displaying the ghost overlay regardless of caret.
  final bool forceShowGhost;

  const InlineAutocompleteTextField({
    super.key,
    required this.controller,
    this.focusNode,
    this.decoration,
    this.style,
    this.ghostText,
    this.onAcceptGhost,
    this.acceptOnTab = true,
    this.textInputAction,
    this.onSubmitted,
    this.onChanged,
    this.forceShowGhost = false,
  });

  @override
  State<InlineAutocompleteTextField> createState() =>
      _InlineAutocompleteTextFieldState();
}

class _InlineAutocompleteTextFieldState
    extends State<InlineAutocompleteTextField> {
  late FocusNode _focusNode;
  bool _ownsFocusNode = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _ownsFocusNode = widget.focusNode == null;
  }

  @override
  void dispose() {
    if (_ownsFocusNode) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  bool get _showGhost {
    final ghost = widget.ghostText ?? '';
    if (ghost.isEmpty) return false;
    if (widget.forceShowGhost) return true;
    final selection = widget.controller.selection;
    // Only show when caret is at the end
    return selection.isCollapsed &&
        selection.extentOffset == widget.controller.text.length;
  }

  void _acceptGhost() {
    final ghost = widget.ghostText ?? '';
    if (ghost.isEmpty) return;
    final current = widget.controller.text;
    widget.controller.text = '$current$ghost';
    widget.controller.selection =
        TextSelection.collapsed(offset: widget.controller.text.length);
    widget.onAcceptGhost?.call();
    widget.onChanged?.call(widget.controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final baseStyle = widget.style ?? Theme.of(context).textTheme.bodyLarge;
    final decoration =
        widget.decoration ?? const InputDecoration(hintText: 'Type a message');

    // Keyboard handling for Tab acceptance via Shortcuts/Actions to avoid
    // focus node conflicts with the inner TextField.
    return Shortcuts(
      shortcuts: {
        if (widget.acceptOnTab)
          LogicalKeySet(LogicalKeyboardKey.tab): const _AcceptGhostIntent(),
      },
      child: Actions(
        actions: {
          _AcceptGhostIntent: CallbackAction<_AcceptGhostIntent>(
            onInvoke: (intent) {
              if (_showGhost) {
                _acceptGhost();
              }
              return null;
            },
          ),
        },
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            // The actual editable field
            TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              decoration: decoration,
              style: baseStyle,
              textInputAction: widget.textInputAction,
              onSubmitted: widget.onSubmitted,
              onChanged: widget.onChanged,
            ),
            // Ghost suggestion overlay (Positioned must be direct child of Stack)
            if (_showGhost)
              _GhostOverlay(
                text: widget.controller.text,
                ghostText: widget.ghostText!,
                style: baseStyle,
                decoration: decoration,
              ),
          ],
        ),
      ),
    );
  }
}

class _AcceptGhostIntent extends Intent {
  const _AcceptGhostIntent();
}

class _GhostOverlay extends StatelessWidget {
  final String text;
  final String ghostText;
  final TextStyle? style;
  final InputDecoration decoration;

  const _GhostOverlay({
    required this.text,
    required this.ghostText,
    required this.style,
    required this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    // We estimate the position by measuring the current text width using TextPainter
    final effectiveStyle = style ?? Theme.of(context).textTheme.bodyLarge;

    final painter = TextPainter(
      text: TextSpan(text: text, style: effectiveStyle),
      textDirection: Directionality.of(context),
      maxLines: 1,
    )..layout();

    final contentPadding = decoration.contentPadding;
    final leftPad = contentPadding is EdgeInsets ? contentPadding.left : 12.0;
    final topPad = contentPadding is EdgeInsets ? contentPadding.top : 8.0;

    // Read the measured width before disposing the painter — this build runs on
    // every keystroke while a ghost suggestion is visible.
    final painterWidth = painter.width;
    painter.dispose();

    final ghostColor =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35);

    return Positioned(
      left: leftPad + painterWidth,
      top: topPad,
      child: Text(
        ghostText,
        style:
            (effectiveStyle ?? const TextStyle()).copyWith(color: ghostColor),
      ),
    );
  }
}
