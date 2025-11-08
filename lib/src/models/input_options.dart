import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/color_extensions.dart';

/// Controls how the input container's width should be sized
enum InputContainerWidth {
  /// Use the maximum available width
  fullWidth,

  /// Use the width of the content plus padding
  wrapContent,

  /// Use a specific width provided in inputContainerConstraints
  custom
}

/// Input options for customizing the chat input field.
/// Designed to be more aligned with Dila's approach.
class InputOptions {
  // Core text field properties
  final TextEditingController? textController;
  final TextStyle? textStyle;
  final InputDecoration? decoration;
  final int? maxLines;
  final int? minLines;
  final bool sendOnEnter;
  final bool readOnly;
  final bool autocorrect;

  // Container and layout properties
  final EdgeInsets? margin;
  final BoxDecoration? containerDecoration;
  final Color? containerBackgroundColor;
  final EdgeInsets? padding;
  final EdgeInsets? containerPadding;
  final double? inputHeight;
  final double? inputContainerHeight;
  final BoxConstraints? inputContainerConstraints;
  final InputContainerWidth? inputContainerWidth;
  final bool useOuterContainer;

  /// Whether to use a Material widget for the outer container.
  /// If false, no Material widget will be used at all, removing all elevation,
  /// color and shadow effects completely.
  final bool useOuterMaterial;

  final double? materialElevation;
  final Color? materialColor;
  final ShapeBorder? materialShape;
  final EdgeInsets? materialPadding;
  final bool? useScaffoldBackground;
  final TextDirection? inputTextDirection;

  // Position properties (when used in Stack/Positioned)
  final double? positionedLeft;
  final double? positionedRight;
  final double? positionedBottom;
  final double? positionedTop;

  // Special effects
  final double? blurStrength;
  final bool clipBehavior;

  // Send button customization
  final Widget Function(VoidCallback onSend)? sendButtonBuilder;
  final Color? sendButtonColor;
  final IconData? sendButtonIcon;
  final double? sendButtonIconSize;
  final EdgeInsets? sendButtonPadding;

  // Text input behavior
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final TextInputAction? textInputAction;
  final TextDirection? textDirection;
  final List<TextInputFormatter>? inputFormatters;
  final bool enableSuggestions;
  final bool enableIMEPersonalizedLearning;

  // Cursor customization
  final Color? cursorColor;
  final double? cursorHeight;
  final double? cursorWidth;
  final Radius? cursorRadius;
  final bool? showCursor;

  // Callbacks
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final GestureTapCallback? onTap;

  /// Whether to unfocus the text field when tapping outside it
  final bool unfocusOnTapOutside;

  // Advanced customization
  final MouseCursor? mouseCursor;
  final EditableTextContextMenuBuilder? contextMenuBuilder;
  final UndoHistoryController? undoController;
  final SpellCheckConfiguration? spellCheckConfiguration;
  final TextMagnifierConfiguration? magnifierConfiguration;
  final SmartDashesType? smartDashesType;
  final SmartQuotesType? smartQuotesType;
  final TextSelectionControls? selectionControls;
  final bool enableInteractiveSelection;

  const InputOptions({
    this.textController,
    this.textStyle,
    this.decoration,
    this.maxLines = 5,
    this.minLines = 1,
    this.sendOnEnter = true,
    this.readOnly = false,
    this.autocorrect = true,
    this.margin,
    this.containerDecoration,
    this.containerBackgroundColor = Colors.transparent,
    this.padding,
    this.containerPadding,
    this.inputHeight,
    this.inputContainerHeight,
    this.inputContainerConstraints,
    this.inputContainerWidth,
    this.useOuterContainer = true,
    this.useOuterMaterial = false,
    this.materialElevation = 0,
    this.materialColor,
    this.materialShape,
    this.materialPadding = const EdgeInsets.all(8.0),
    this.useScaffoldBackground = false,
    this.inputTextDirection,
    this.positionedLeft,
    this.positionedRight,
    this.positionedBottom,
    this.positionedTop,
    this.blurStrength,
    this.clipBehavior = false,
    this.sendButtonBuilder,
    this.sendButtonColor,
    this.sendButtonIcon = Icons.send,
    this.sendButtonIconSize = 24.0,
    this.sendButtonPadding = const EdgeInsets.all(4.0),
    this.keyboardType = TextInputType.multiline,
    this.textCapitalization = TextCapitalization.sentences,
    this.textInputAction = TextInputAction.newline,
    this.textDirection,
    this.inputFormatters,
    this.enableSuggestions = true,
    this.enableIMEPersonalizedLearning = true,
    this.cursorColor,
    this.cursorHeight,
    this.cursorWidth,
    this.cursorRadius,
    this.showCursor,
    this.onEditingComplete,
    this.onSubmitted,
    this.onChanged,
    this.onTap,
    this.unfocusOnTapOutside = false,
    this.mouseCursor,
    this.contextMenuBuilder,
    this.undoController,
    this.spellCheckConfiguration,
    this.magnifierConfiguration,
    this.smartDashesType,
    this.smartQuotesType,
    this.selectionControls,
    this.enableInteractiveSelection = true,
  });

  /// Creates a minimal input field with no outer container.
  factory InputOptions.minimal({
    String? hintText,
    Color? textColor,
    Color? hintColor,
    Color? backgroundColor,
    double? borderRadius,
    TextEditingController? textController,
    bool sendOnEnter = true,
  }) {
    return InputOptions(
      textController: textController,
      useOuterContainer: false,
      sendOnEnter: sendOnEnter,
      textStyle: textColor != null ? TextStyle(color: textColor) : null,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: hintColor != null ? TextStyle(color: hintColor) : null,
        filled: backgroundColor != null,
        fillColor: backgroundColor,
        border: borderRadius != null
            ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(borderRadius),
                borderSide: BorderSide.none,
              )
            : null,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 10.0,
        ),
      ),
    );
  }

  /// Creates a glassmorphic input field with a frosted glass effect.
  factory InputOptions.glassmorphic({
    List<Color>? colors,
    double borderRadius = 24.0,
    double blurStrength = 10.0,
    String? hintText,
    Color? textColor,
    Color? hintColor,
    bool useOuterContainer = true,
    TextEditingController? textController,
    bool sendOnEnter = true,
  }) {
    final effectiveColors = colors ??
        [
          Colors.white.withOpacityCompat(0.3),
          Colors.white.withOpacityCompat(0.2),
        ];

    return InputOptions(
      textController: textController,
      useOuterContainer: useOuterContainer,
      sendOnEnter: sendOnEnter,
      blurStrength: blurStrength,
      textStyle: textColor != null ? TextStyle(color: textColor) : null,
      containerBackgroundColor: Colors.transparent,
      containerDecoration: BoxDecoration(
        gradient: LinearGradient(
          colors: effectiveColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: Colors.white.withOpacityCompat(0.2),
          width: 1.5,
        ),
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: hintColor != null ? TextStyle(color: hintColor) : null,
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 10.0,
        ),
      ),
    );
  }

  /// Creates a custom input field with complete control.
  factory InputOptions.custom({
    InputDecoration? decoration,
    TextStyle? textStyle,
    Widget Function(VoidCallback onSend)? sendButtonBuilder,
    bool useOuterContainer = true,
    TextEditingController? textController,
    bool sendOnEnter = true,
  }) {
    return InputOptions(
      textController: textController,
      decoration: decoration,
      textStyle: textStyle,
      sendButtonBuilder: sendButtonBuilder,
      useOuterContainer: useOuterContainer,
      sendOnEnter: sendOnEnter,
    );
  }

  /// Creates a copy with the given fields replaced with new values.
  InputOptions copyWith({
    TextEditingController? textController,
    TextStyle? textStyle,
    InputDecoration? decoration,
    int? maxLines,
    int? minLines,
    bool? sendOnEnter,
    bool? readOnly,
    bool? autocorrect,
    EdgeInsets? margin,
    BoxDecoration? containerDecoration,
    Color? containerBackgroundColor,
    EdgeInsets? padding,
    EdgeInsets? containerPadding,
    double? inputHeight,
    double? inputContainerHeight,
    BoxConstraints? inputContainerConstraints,
    InputContainerWidth? inputContainerWidth,
    bool? useOuterContainer,
    bool? useOuterMaterial,
    double? materialElevation,
    Color? materialColor,
    ShapeBorder? materialShape,
    EdgeInsets? materialPadding,
    bool? useScaffoldBackground,
    TextDirection? textDirection,
    double? positionedLeft,
    double? positionedRight,
    double? positionedBottom,
    double? positionedTop,
    double? blurStrength,
    bool? clipBehavior,
    Widget Function(VoidCallback onSend)? sendButtonBuilder,
    Color? sendButtonColor,
    IconData? sendButtonIcon,
    double? sendButtonIconSize,
    EdgeInsets? sendButtonPadding,
    TextInputType? keyboardType,
    TextCapitalization? textCapitalization,
    TextInputAction? textInputAction,
    List<TextInputFormatter>? inputFormatters,
    bool? enableSuggestions,
    bool? enableIMEPersonalizedLearning,
    Color? cursorColor,
    double? cursorHeight,
    double? cursorWidth,
    Radius? cursorRadius,
    bool? showCursor,
    VoidCallback? onEditingComplete,
    ValueChanged<String>? onSubmitted,
    ValueChanged<String>? onChanged,
    GestureTapCallback? onTap,
    bool? unfocusOnTapOutside,
    MouseCursor? mouseCursor,
    EditableTextContextMenuBuilder? contextMenuBuilder,
    UndoHistoryController? undoController,
    SpellCheckConfiguration? spellCheckConfiguration,
    TextMagnifierConfiguration? magnifierConfiguration,
    SmartDashesType? smartDashesType,
    SmartQuotesType? smartQuotesType,
    TextSelectionControls? selectionControls,
    bool? enableInteractiveSelection,
  }) {
    return InputOptions(
      textController: textController ?? this.textController,
      textStyle: textStyle ?? this.textStyle,
      decoration: decoration ?? this.decoration,
      maxLines: maxLines ?? this.maxLines,
      minLines: minLines ?? this.minLines,
      sendOnEnter: sendOnEnter ?? this.sendOnEnter,
      readOnly: readOnly ?? this.readOnly,
      autocorrect: autocorrect ?? this.autocorrect,
      margin: margin ?? this.margin,
      containerDecoration: containerDecoration ?? this.containerDecoration,
      containerBackgroundColor:
          containerBackgroundColor ?? this.containerBackgroundColor,
      padding: padding ?? this.padding,
      containerPadding: containerPadding ?? this.containerPadding,
      inputHeight: inputHeight ?? this.inputHeight,
      inputContainerHeight: inputContainerHeight ?? this.inputContainerHeight,
      inputContainerConstraints:
          inputContainerConstraints ?? this.inputContainerConstraints,
      inputContainerWidth: inputContainerWidth ?? this.inputContainerWidth,
      useOuterContainer: useOuterContainer ?? this.useOuterContainer,
      useOuterMaterial: useOuterMaterial ?? this.useOuterMaterial,
      materialElevation: materialElevation ?? this.materialElevation,
      materialColor: materialColor ?? this.materialColor,
      materialShape: materialShape ?? this.materialShape,
      materialPadding: materialPadding ?? this.materialPadding,
      useScaffoldBackground:
          useScaffoldBackground ?? this.useScaffoldBackground,
      inputTextDirection: textDirection ?? inputTextDirection,
      positionedLeft: positionedLeft ?? this.positionedLeft,
      positionedRight: positionedRight ?? this.positionedRight,
      positionedBottom: positionedBottom ?? this.positionedBottom,
      positionedTop: positionedTop ?? this.positionedTop,
      blurStrength: blurStrength ?? this.blurStrength,
      clipBehavior: clipBehavior ?? this.clipBehavior,
      sendButtonBuilder: sendButtonBuilder ?? this.sendButtonBuilder,
      sendButtonColor: sendButtonColor ?? this.sendButtonColor,
      sendButtonIcon: sendButtonIcon ?? this.sendButtonIcon,
      sendButtonIconSize: sendButtonIconSize ?? this.sendButtonIconSize,
      sendButtonPadding: sendButtonPadding ?? this.sendButtonPadding,
      keyboardType: keyboardType ?? this.keyboardType,
      textCapitalization: textCapitalization ?? this.textCapitalization,
      textInputAction: textInputAction ?? this.textInputAction,
      textDirection: textDirection ?? this.textDirection,
      inputFormatters: inputFormatters ?? this.inputFormatters,
      enableSuggestions: enableSuggestions ?? this.enableSuggestions,
      enableIMEPersonalizedLearning:
          enableIMEPersonalizedLearning ?? this.enableIMEPersonalizedLearning,
      cursorColor: cursorColor ?? this.cursorColor,
      cursorHeight: cursorHeight ?? this.cursorHeight,
      cursorWidth: cursorWidth ?? this.cursorWidth,
      cursorRadius: cursorRadius ?? this.cursorRadius,
      showCursor: showCursor ?? this.showCursor,
      onEditingComplete: onEditingComplete ?? this.onEditingComplete,
      onSubmitted: onSubmitted ?? this.onSubmitted,
      onChanged: onChanged ?? this.onChanged,
      onTap: onTap ?? this.onTap,
      unfocusOnTapOutside: unfocusOnTapOutside ?? this.unfocusOnTapOutside,
      mouseCursor: mouseCursor ?? this.mouseCursor,
      contextMenuBuilder: contextMenuBuilder ?? this.contextMenuBuilder,
      undoController: undoController ?? this.undoController,
      spellCheckConfiguration:
          spellCheckConfiguration ?? this.spellCheckConfiguration,
      magnifierConfiguration:
          magnifierConfiguration ?? this.magnifierConfiguration,
      smartDashesType: smartDashesType ?? this.smartDashesType,
      smartQuotesType: smartQuotesType ?? this.smartQuotesType,
      selectionControls: selectionControls ?? this.selectionControls,
      enableInteractiveSelection:
          enableInteractiveSelection ?? this.enableInteractiveSelection,
    );
  }

  /// Helper method to build an effective send button based on configuration
  Widget effectiveSendButtonBuilder(VoidCallback onSend) {
    // If a custom builder is provided, use it
    if (sendButtonBuilder != null) {
      return sendButtonBuilder!(onSend);
    }

    // Build the default send button with better alignment
    return IconButton(
      icon: Icon(
        sendButtonIcon,
        size: sendButtonIconSize,
        color: sendButtonColor,
      ),
      padding: sendButtonPadding,
      onPressed: onSend,
    );
  }
}
