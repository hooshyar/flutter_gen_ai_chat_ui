import 'package:flutter/material.dart';

/// Configuration for the welcome message section of the chat
class WelcomeMessageConfig {
  const WelcomeMessageConfig({
    this.title,
    this.titleStyle,
    this.containerDecoration,
    this.containerPadding = const EdgeInsets.all(24),
    this.containerMargin = const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 12,
    ),
    this.questionsSectionTitle = 'Here are some questions you can ask:',
    this.questionsSectionTitleStyle,
    this.questionsSectionDecoration,
    this.questionsSectionPadding = const EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 8,
    ),
    this.questionSpacing = 12.0,
    this.animation = const Duration(milliseconds: 500),
    this.builder,
    this.centerVertically = false,
  });

  /// The title text of the welcome message
  final String? title;

  /// Style for the title text
  final TextStyle? titleStyle;

  /// Decoration for the main container
  final BoxDecoration? containerDecoration;

  /// Padding for the main container
  final EdgeInsets containerPadding;

  /// Margin for the main container
  final EdgeInsets containerMargin;

  /// Title for the questions section
  final String questionsSectionTitle;

  /// Style for the questions section title
  final TextStyle? questionsSectionTitleStyle;

  /// Decoration for the questions section container
  final BoxDecoration? questionsSectionDecoration;

  /// Padding for the questions section
  final EdgeInsets questionsSectionPadding;

  /// Spacing between questions
  final double questionSpacing;

  /// Duration for the welcome message animation
  final Duration animation;

  /// Custom builder function to create a welcome message widget
  final Widget Function()? builder;

  /// Whether to center the welcome message vertically while the conversation
  /// is empty.
  ///
  /// By default (false) the welcome message sits at the bottom of the chat
  /// area, just above the input. Set to true to center it in the available
  /// space instead — a more balanced empty state on tall screens. Once the
  /// first message is sent, normal message layout resumes regardless.
  final bool centerVertically;

  /// Creates a copy of this config with the given fields replaced with new values
  WelcomeMessageConfig copyWith({
    String? title,
    TextStyle? titleStyle,
    BoxDecoration? containerDecoration,
    EdgeInsets? containerPadding,
    EdgeInsets? containerMargin,
    String? questionsSectionTitle,
    TextStyle? questionsSectionTitleStyle,
    BoxDecoration? questionsSectionDecoration,
    EdgeInsets? questionsSectionPadding,
    double? questionSpacing,
    Duration? animation,
    Widget Function()? builder,
    bool? centerVertically,
  }) {
    return WelcomeMessageConfig(
      title: title ?? this.title,
      titleStyle: titleStyle ?? this.titleStyle,
      containerDecoration: containerDecoration ?? this.containerDecoration,
      containerPadding: containerPadding ?? this.containerPadding,
      containerMargin: containerMargin ?? this.containerMargin,
      questionsSectionTitle:
          questionsSectionTitle ?? this.questionsSectionTitle,
      questionsSectionTitleStyle:
          questionsSectionTitleStyle ?? this.questionsSectionTitleStyle,
      questionsSectionDecoration:
          questionsSectionDecoration ?? this.questionsSectionDecoration,
      questionsSectionPadding:
          questionsSectionPadding ?? this.questionsSectionPadding,
      questionSpacing: questionSpacing ?? this.questionSpacing,
      animation: animation ?? this.animation,
      builder: builder ?? this.builder,
      centerVertically: centerVertically ?? this.centerVertically,
    );
  }
}
