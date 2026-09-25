import 'package:flutter/material.dart';

/// Configuration for individual example questions in the chat
class ExampleQuestionConfig {
  const ExampleQuestionConfig({
    this.containerDecoration,
    this.containerPadding = const EdgeInsets.symmetric(
      vertical: 14,
      horizontal: 16,
    ),
    this.textStyle,
    this.iconData = Icons.chat_bubble_outline_rounded,
    this.iconSize = 20.0,
    this.iconColor,
    this.trailingIconData = Icons.arrow_forward_rounded,
    this.trailingIconSize = 20.0,
    this.trailingIconColor,
    this.spacing = 12.0,
    this.onTap,
  });

  /// Decoration for the question container
  final BoxDecoration? containerDecoration;

  /// Padding for the question container
  final EdgeInsets containerPadding;

  /// Style for the question text
  final TextStyle? textStyle;

  /// Icon data for the leading icon
  final IconData iconData;

  /// Size of the leading icon
  final double iconSize;

  /// Color of the leading icon
  final Color? iconColor;

  /// Icon data for the trailing icon
  /// Made nullable to avoid analyzer warnings
  final IconData? trailingIconData;

  /// Size of the trailing icon
  final double trailingIconSize;

  /// Color of the trailing icon
  final Color? trailingIconColor;

  /// Spacing between elements
  final double spacing;

  /// Custom onTap callback for the question
  final void Function(String question)? onTap;

  /// Creates a copy of this config with the given fields replaced with new values
  ExampleQuestionConfig copyWith({
    BoxDecoration? containerDecoration,
    EdgeInsets? containerPadding,
    TextStyle? textStyle,
    IconData? iconData,
    double? iconSize,
    Color? iconColor,
    IconData? trailingIconData,
    double? trailingIconSize,
    Color? trailingIconColor,
    double? spacing,
    void Function(String question)? onTap,
  }) {
    return ExampleQuestionConfig(
      containerDecoration: containerDecoration ?? this.containerDecoration,
      containerPadding: containerPadding ?? this.containerPadding,
      textStyle: textStyle ?? this.textStyle,
      iconData: iconData ?? this.iconData,
      iconSize: iconSize ?? this.iconSize,
      iconColor: iconColor ?? this.iconColor,
      trailingIconData: trailingIconData ?? this.trailingIconData,
      trailingIconSize: trailingIconSize ?? this.trailingIconSize,
      trailingIconColor: trailingIconColor ?? this.trailingIconColor,
      spacing: spacing ?? this.spacing,
      onTap: onTap ?? this.onTap,
    );
  }
}

/// Model class for example questions
class ExampleQuestion {
  const ExampleQuestion({required this.question, this.config});

  /// The question text
  final String question;

  /// Optional configuration specific to this question
  final ExampleQuestionConfig? config;
}
