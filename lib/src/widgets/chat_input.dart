import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/file_upload_options.dart';
import '../models/input_options.dart';
import '../theme/chat_tokens.dart';
import '../theme/custom_theme_extension.dart';
import 'input/send_stop_button.dart';

/// A custom chat input widget that supports extensive customization options.
class ChatInput extends StatefulWidget {
  const ChatInput({
    super.key,
    required this.controller,
    required this.onSend,
    required this.options,
    this.focusNode,
    this.fileUploadOptions,
    this.isGenerating = false,
    this.onCancelGenerating,
  });

  /// The text editing controller.
  final TextEditingController controller;

  /// Callback when the send button is pressed.
  final VoidCallback onSend;

  /// The input options for customization.
  final InputOptions options;

  /// Optional focus node for the text field.
  final FocusNode? focusNode;

  /// Optional file upload options.
  final FileUploadOptions? fileUploadOptions;

  /// Whether a response is currently being generated.
  ///
  /// When true and [onCancelGenerating] is provided, the send button is
  /// replaced by a stop button.
  final bool isGenerating;

  /// Callback invoked when the user taps the stop button to cancel generation.
  final VoidCallback? onCancelGenerating;

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  bool _isEmpty = true;

  // Owned locally so the default composer chrome (`DESIGN.md` §8.4) can
  // listen for focus changes and redraw its border/ring. When the consumer
  // supplies its own `focusNode`, this simply wraps it (no new node created);
  // when they don't, TextField would otherwise create an internal node we
  // can't observe, so we create and own one instead — same effective
  // behavior, just observable.
  late FocusNode _focusNode;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _isEmpty = widget.controller.text.trim().isEmpty;
    widget.controller.addListener(_onTextChanged);
    _focusNode = widget.focusNode ?? FocusNode();
    _focused = _focusNode.hasFocus;
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(ChatInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTextChanged);
      widget.controller.addListener(_onTextChanged);
      _isEmpty = widget.controller.text.trim().isEmpty;
    }
    if (oldWidget.focusNode != widget.focusNode) {
      _focusNode.removeListener(_onFocusChanged);
      if (oldWidget.focusNode == null) {
        _focusNode.dispose();
      }
      _focusNode = widget.focusNode ?? FocusNode();
      _focused = _focusNode.hasFocus;
      _focusNode.addListener(_onFocusChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onTextChanged() {
    final empty = widget.controller.text.trim().isEmpty;
    if (empty != _isEmpty) {
      setState(() => _isEmpty = empty);
    }
  }

  void _onFocusChanged() {
    if (_focused != _focusNode.hasFocus) {
      setState(() => _focused = _focusNode.hasFocus);
    }
  }

  // Intercepts hardware Enter so `sendOnEnter: true` works on desktop, web,
  // and any platform with an attached physical keyboard. The TextField's
  // `onSubmitted` only fires on soft-keyboard submit with non-newline
  // textInputAction, which leaves hardware Enter unhandled in multi-line
  // mode. Wrapping the TextField in a Focus(onKeyEvent:) preempts
  // EditableText's internal newline shortcut.
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    // Ignore key-up and key-repeat. Acting on repeat would fire `onSend`
    // continuously while the user holds Enter.
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    // Esc cancels an in-flight generation (`DESIGN.md` §8.4 "Keyboard").
    if (event.logicalKey == LogicalKeyboardKey.escape &&
        widget.isGenerating &&
        widget.onCancelGenerating != null) {
      widget.onCancelGenerating!();
      return KeyEventResult.handled;
    }

    final isEnter = event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter;
    if (!isEnter) return KeyEventResult.ignored;

    if (!widget.options.sendOnEnter) return KeyEventResult.ignored;

    // While a response is generating and a cancel handler is wired, the send
    // button is replaced by a stop button — don't let Enter send a new
    // message in that state.
    if (widget.isGenerating && widget.onCancelGenerating != null) {
      return KeyEventResult.ignored;
    }

    // Shift+Enter falls through so EditableText inserts a newline.
    if (HardwareKeyboard.instance.isShiftPressed) {
      return KeyEventResult.ignored;
    }

    // CJK / IME composing: Enter commits composition; don't send.
    if (widget.controller.value.composing.isValid) {
      return KeyEventResult.ignored;
    }

    final text = widget.controller.text;
    if (text.trim().isEmpty) return KeyEventResult.ignored;

    widget.onSend();
    // Mirror the soft-keyboard submit path so consumers get a consistent
    // onSubmitted signal regardless of input source.
    widget.options.onSubmitted?.call(text);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final options = widget.options;
    final onSend = widget.onSend;
    final controller = widget.controller;
    final fileUploadOptions = widget.fileUploadOptions;
    // Always use the app's text direction from context for consistency
    final appDirection = Directionality.of(context);

    // A `CustomThemeExtension` (e.g. a brand preset) supplies input-field
    // and send-button colors as a fallback layer below any explicit
    // `InputOptions` value. Null (nobody has opted into a custom theme)
    // leaves both `effectiveDecoration`/`effectiveTextStyle` exactly as
    // `options.decoration`/`options.textStyle` were before — no behavior
    // change for existing consumers.
    final themeExt = Theme.of(context).extension<CustomThemeExtension>();
    final tokens = ChatTokens.of(context);

    // Default composer decoration (`DESIGN.md` §8.4). Only reached when the
    // consumer hasn't supplied their own `containerDecoration` (see the
    // early-return below) — that case keeps rendering exactly as before,
    // untouched by any of this.
    final composerFill = themeExt?.inputBackgroundColor ?? tokens.surfaceSunken;
    final composerBorderColor = _focused
        ? tokens.borderStrong
        : (themeExt?.inputBorderColor ?? tokens.border);

    final effectiveDecoration = options.decoration ??
        InputDecoration(
          hintText: 'Message...',
          hintStyle: TextStyle(
            color: themeExt?.hintTextColor ?? tokens.textSecondary,
          ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsetsDirectional.fromSTEB(16, 12, 8, 12),
        );
    final effectiveTextStyle = options.textStyle ??
        (themeExt?.inputTextColor != null
            ? TextStyle(color: themeExt!.inputTextColor)
            : null);

    // Basic content of the input area - the TextField and send button
    Widget textField = TextField(
      controller: controller,
      focusNode: _focusNode,
      autofocus: options.autofocus,
      autocorrect: options.autocorrect,
      style: effectiveTextStyle,
      // Always use the app's text direction for the TextField
      textDirection: appDirection,
      decoration: effectiveDecoration,
      textCapitalization: options.textCapitalization,
      maxLines: options.maxLines,
      minLines: options.minLines,
      textInputAction: options.textInputAction,
      keyboardType: options.keyboardType,
      cursorColor: options.cursorColor,
      cursorHeight: options.cursorHeight,
      cursorWidth: options.cursorWidth ?? 2.0,
      cursorRadius: options.cursorRadius,
      showCursor: options.showCursor,
      enableSuggestions: options.enableSuggestions,
      enableIMEPersonalizedLearning: options.enableIMEPersonalizedLearning,
      enableInteractiveSelection: options.enableInteractiveSelection,
      readOnly: options.readOnly,
      smartDashesType: options.smartDashesType,
      smartQuotesType: options.smartQuotesType,
      selectionControls: options.selectionControls,
      onTap: options.onTap,
      onEditingComplete: options.onEditingComplete,
      onSubmitted: (text) {
        // Implement sendOnEnter functionality. Suppressed while generating so a
        // soft-keyboard submit doesn't queue a new message behind the stop UI.
        final generating =
            widget.isGenerating && widget.onCancelGenerating != null;
        if (options.sendOnEnter &&
            !generating &&
            controller.text.trim().isNotEmpty) {
          onSend();
        }
        // Forward to the original onSubmitted if provided
        if (options.onSubmitted != null) {
          options.onSubmitted!(text);
        }
      },
      onChanged: options.onChanged,
      inputFormatters: options.inputFormatters,
      mouseCursor: options.mouseCursor,
      contextMenuBuilder: options.contextMenuBuilder,
      undoController: options.undoController,
      spellCheckConfiguration: options.spellCheckConfiguration,
      magnifierConfiguration: options.magnifierConfiguration,
      onTapOutside: (event) {
        // Let the parent GestureDetector handle focus
      },
    );

    // Apply custom height to text field if specified
    if (options.inputHeight != null) {
      textField = SizedBox(height: options.inputHeight!, child: textField);
    }

    // Hardware Enter handling for desktop, web, and devices with attached
    // physical keyboards. canRequestFocus:false keeps focus on the TextField;
    // skipTraversal:true keeps tab order unchanged.
    textField = Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: _handleKeyEvent,
      child: textField,
    );

    // The send/stop control. `SendStopButton` (`DESIGN.md` §8.5) is used only
    // when none of sendButtonBuilder / sendOrMicBuilder / cancelButtonBuilder
    // are supplied — any of those keeps the legacy builder-driven behavior
    // exactly as before, including its own 48px tap-target floor.
    final usesCustomSendControls = options.sendButtonBuilder != null ||
        options.sendOrMicBuilder != null ||
        options.cancelButtonBuilder != null;

    final sendControlContainer = usesCustomSendControls
        ? Container(
            // Match the height to align with text field. Floored at 48 (the
            // Material/WCAG minimum tap target) when falling back to the
            // approximated height — a fixed Container height here overrides
            // the send IconButton's own 48x48 minimum constraint, so without
            // this floor a compact contentPadding could shrink the button's
            // real tap target below the accessibility minimum even though it
            // still LOOKS the same size (the icon itself doesn't change).
            // An explicit `inputHeight` is a deliberate consumer choice and
            // is left as-is.
            height: options.inputHeight ??
                ((options.decoration?.contentPadding?.vertical ?? 14) + 24)
                    .clamp(48.0, double.infinity),
            alignment: Alignment.center,
            child: (widget.isGenerating && widget.onCancelGenerating != null)
                ? options.effectiveStopButtonBuilder(widget.onCancelGenerating!)
                : options.effectiveSendWidget(
                    onSend,
                    isEmpty: _isEmpty,
                    themeSendButtonColor: themeExt?.sendButtonColor,
                  ),
          )
        : SendStopButton(
            isEmpty: _isEmpty,
            onSend: onSend,
            isGenerating: widget.isGenerating,
            onCancel: widget.onCancelGenerating,
            icon: options.sendButtonIcon,
            enabledFillColor:
                options.sendButtonColor ?? themeExt?.sendButtonColor,
            tooltip: options.sendButtonTooltip,
          );

    // Leading content (attach / toolbar builder / mic) moves send + itself
    // into a dedicated bottom row below the text field (`DESIGN.md` §8.4).
    // With no leading content, the field and send control share one row.
    final hasLeading = (fileUploadOptions?.enabled == true) ||
        (options.inputLeadingBuilder != null);
    final hasToolbar = options.inputToolbarBuilder != null;
    final hasPreview = options.attachmentPreviewBuilder != null;
    final hasBottomRow = hasLeading || hasToolbar;

    Widget inputContent;
    if (hasBottomRow) {
      final fieldRow = Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        textDirection: appDirection,
        children: [Flexible(child: textField)],
      );
      final bottomRow = Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        textDirection: appDirection,
        children: [
          if (fileUploadOptions?.enabled == true)
            _buildFileUploadButton(context),
          if (options.inputLeadingBuilder != null)
            options.inputLeadingBuilder!(context),
          if (hasToolbar)
            Expanded(child: options.inputToolbarBuilder!(context))
          else
            const Spacer(),
          sendControlContainer,
        ],
      );
      inputContent = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasPreview) options.attachmentPreviewBuilder!(context),
          fieldRow,
          bottomRow,
        ],
      );
    } else {
      final inputRow = Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        textDirection: appDirection,
        children: [
          Flexible(child: textField),
          sendControlContainer,
        ],
      );
      inputContent = hasPreview
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [options.attachmentPreviewBuilder!(context), inputRow],
            )
          : inputRow;
    }

    // Calculate appropriate background color based on settings
    final useScaffoldBg = options.useScaffoldBackground ?? false;
    final effectiveBackgroundColor = useScaffoldBg
        ? Theme.of(context).scaffoldBackgroundColor
        : options.containerBackgroundColor;

    // Prepare constraints for the input container
    final constraints = options.inputContainerConstraints ??
        BoxConstraints(
          minHeight: options.inputContainerHeight ?? 0,
          maxHeight: options.inputContainerHeight ?? double.infinity,
        );

    // Render with container decoration if specified
    if (options.containerDecoration != null) {
      // For glassmorphic effect (with backdrop filter)
      if (options.clipBehavior &&
          options.containerDecoration?.borderRadius != null) {
        final borderRadius =
            options.containerDecoration?.borderRadius as BorderRadius?;

        return ClipRRect(
          borderRadius: borderRadius ?? BorderRadius.zero,
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: options.blurStrength != null
                  ? options.blurStrength! * 10
                  : 8.0,
              sigmaY: options.blurStrength != null
                  ? options.blurStrength! * 10
                  : 8.0,
            ),
            child: Container(
              constraints: constraints,
              width: _getContainerWidth(options, context),
              padding: options.containerPadding,
              decoration: options.containerDecoration?.copyWith(
                color: effectiveBackgroundColor,
              ),
              child: Padding(
                // Use app direction consistently for margin resolution
                padding:
                    options.margin?.resolve(appDirection) ?? EdgeInsets.zero,
                child: inputContent,
              ),
            ),
          ),
        );
      }

      // Regular container decoration without backdrop filter
      return Container(
        constraints: constraints,
        width: _getContainerWidth(options, context),
        padding: options.containerPadding,
        decoration: options.containerDecoration,
        child: Padding(
          // Use app direction consistently for margin resolution
          padding: options.margin?.resolve(appDirection) ?? EdgeInsets.zero,
          child: inputContent,
        ),
      );
    }

    // Default rendering without container customization: the composer's own
    // rounded, bordered chrome (`DESIGN.md` §8.4), animated between resting
    // and focused states.
    Widget result = AnimatedContainer(
      duration: ChatMotion.of(context, ChatMotion.fast),
      curve: ChatMotion.enter,
      // Use app direction consistently for margin resolution
      padding: options.margin?.resolve(appDirection) ??
          const EdgeInsetsDirectional.fromSTEB(
            16,
            12,
            8,
            8,
          ).resolve(appDirection),
      decoration: BoxDecoration(
        color: composerFill,
        border: Border.all(color: composerBorderColor),
        borderRadius: BorderRadius.circular(ChatRadius.composer),
        boxShadow: _focused
            ? [
                BoxShadow(
                  color: tokens.accent.withValues(alpha: 0.18),
                  spreadRadius: 3,
                ),
              ]
            : null,
      ),
      child: inputContent,
    );

    // Apply constraints if needed when no container decoration is used
    if (options.inputContainerHeight != null ||
        options.inputContainerConstraints != null) {
      result = Container(
        constraints: constraints,
        width: _getContainerWidth(options, context),
        child: result,
      );
    }

    // Skip Material if useOuterMaterial is false
    if (!options.useOuterMaterial) {
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          if (!options.unfocusOnTapOutside) {
            _focusNode.requestFocus();
          }
        },
        child: result,
      );
    }

    // Optional Material styling
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        if (!options.unfocusOnTapOutside) {
          _focusNode.requestFocus();
        }
      },
      child: Material(
        color: options.materialColor ?? Colors.transparent,
        elevation: options.materialElevation ?? 0.0,
        shape: options.materialShape,
        shadowColor: Colors.transparent,
        child: Padding(
          padding: options.materialPadding != null
              ? options.materialPadding!
              : EdgeInsets.zero,
          child: result,
        ),
      ),
    );
  }

  // Helper method to get container width based on options
  double? _getContainerWidth(InputOptions options, BuildContext context) {
    if (options.inputContainerWidth == InputContainerWidth.fullWidth) {
      return double.infinity;
    } else if (options.inputContainerWidth == InputContainerWidth.custom &&
        options.inputContainerConstraints != null) {
      return options.inputContainerConstraints!.maxWidth;
    }
    return null;
  }

  // Build the file upload button
  Widget _buildFileUploadButton(BuildContext context) {
    final options = widget.fileUploadOptions!;

    // Use custom builder if provided
    if (options.customUploadButtonBuilder != null) {
      return options.customUploadButtonBuilder!(context, () {
        _handleFileSelection(context);
      });
    }

    // Default upload button
    return Container(
      margin: const EdgeInsets.only(left: 4.0, right: 4.0),
      child: IconButton(
        icon: Icon(
          options.uploadIcon,
          color:
              options.uploadIconColor ?? Theme.of(context).colorScheme.primary,
          size: options.uploadIconSize,
        ),
        tooltip: options.uploadTooltip,
        onPressed: () => _handleFileSelection(context),
      ),
    );
  }

  // Handle file selection
  void _handleFileSelection(BuildContext context) {
    // This function will be a placeholder - the actual file selection
    // will be implemented by the developer using the package
    if (widget.fileUploadOptions?.onFilesSelected != null) {
      // Call the developer's file selection handler
      widget.fileUploadOptions!.onFilesSelected!([]);
    } else {
      // Show a placeholder message if no handler is provided
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('File upload handler not implemented.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}
