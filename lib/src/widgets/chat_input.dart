import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/file_upload_options.dart';
import '../models/input_options.dart';

/// A custom chat input widget that supports extensive customization options.
class ChatInput extends StatefulWidget {
  const ChatInput({
    super.key,
    required this.controller,
    required this.onSend,
    required this.options,
    this.focusNode,
    this.fileUploadOptions,
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

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  bool _isEmpty = true;

  @override
  void initState() {
    super.initState();
    _isEmpty = widget.controller.text.trim().isEmpty;
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(ChatInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTextChanged);
      widget.controller.addListener(_onTextChanged);
      _isEmpty = widget.controller.text.trim().isEmpty;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final empty = widget.controller.text.trim().isEmpty;
    if (empty != _isEmpty) {
      setState(() => _isEmpty = empty);
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

    final isEnter = event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter;
    if (!isEnter) return KeyEventResult.ignored;

    if (!widget.options.sendOnEnter) return KeyEventResult.ignored;

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
    final focusNode = widget.focusNode;
    final fileUploadOptions = widget.fileUploadOptions;
    // Always use the app's text direction from context for consistency
    final appDirection = Directionality.of(context);

    // Basic content of the input area - the TextField and send button
    Widget textField = TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: options.autofocus,
      style: options.textStyle,
      // Always use the app's text direction for the TextField
      textDirection: appDirection,
      decoration: options.decoration,
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
        // Implement sendOnEnter functionality
        if (options.sendOnEnter && controller.text.trim().isNotEmpty) {
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
      textField = SizedBox(
        height: options.inputHeight!,
        child: textField,
      );
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

    // Create input content with text field and send button
    final inputRow = Row(
      // Change to center alignment for better vertical alignment
      crossAxisAlignment: CrossAxisAlignment.center,
      // Use app direction consistently
      textDirection: appDirection,
      children: [
        // Add file upload button if enabled
        if (fileUploadOptions?.enabled == true) _buildFileUploadButton(context),

        // Leading builder (mic, attach, etc.) inside the input row
        if (options.inputLeadingBuilder != null)
          options.inputLeadingBuilder!(context),

        Flexible(
          child: textField,
        ),
        // Adjust send button to match text field height
        Container(
          // Match the height to align with text field
          height: options.inputHeight ??
              (options.decoration?.contentPadding?.vertical ?? 14) +
                  24, // Base height approximation
          // Center the button vertically
          alignment: Alignment.center,
          child: options.effectiveSendWidget(onSend, isEmpty: _isEmpty),
        ),
      ],
    );

    // Combine: attachment preview (above) + text row + toolbar (below)
    Widget inputContent;
    final hasToolbar = options.inputToolbarBuilder != null;
    final hasPreview = options.attachmentPreviewBuilder != null;

    if (hasToolbar || hasPreview) {
      inputContent = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasPreview) options.attachmentPreviewBuilder!(context),
          inputRow,
          if (hasToolbar) options.inputToolbarBuilder!(context),
        ],
      );
    } else {
      inputContent = inputRow;
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

    // Default rendering without container customization
    Widget result = Container(
      // Use app direction consistently for margin resolution
      padding: options.margin?.resolve(appDirection) ?? EdgeInsets.zero,
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
            focusNode?.requestFocus();
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
          focusNode?.requestFocus();
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
