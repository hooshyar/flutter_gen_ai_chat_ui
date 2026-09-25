import 'package:flutter/material.dart';

/// Configuration for the welcome message section of the chat
class WelcomeMessageConfig {
  const WelcomeMessageConfig({
    this.title,
    this.titleStyle,
    this.subtitle,
    this.subtitleStyle,
    this.containerDecoration,
    this.containerPadding = const EdgeInsets.all(24),
    this.containerMargin = const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 12,
    ),
    this.questionsSectionTitle = '',
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

  /// Optional subtitle shown below the title (`DESIGN.md` §8.6): `body`,
  /// `textSecondary`, max 2 lines by default. Null by default — the
  /// package default empty state shows only a greeting unless a subtitle
  /// is explicitly supplied.
  final String? subtitle;

  /// Style for [subtitle]. Falls back to the package's `body`/
  /// `textSecondary` default when null.
  final TextStyle? subtitleStyle;

  /// Decoration for the main container
  final BoxDecoration? containerDecoration;

  /// Padding for the main container
  final EdgeInsets containerPadding;

  /// Margin for the main container
  final EdgeInsets containerMargin;

  /// Optional heading shown above the suggestion tiles. Empty (`''`) by
  /// default — the package default empty state (`DESIGN.md` §8.6) has no
  /// "Here are some questions you can ask:" label; set this explicitly to
  /// opt back in. An empty string is always treated the same as "no
  /// heading", so `copyWith()` can't accidentally clear it back to the
  /// non-null-but-unset default with a bare `''`.
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
    String? subtitle,
    TextStyle? subtitleStyle,
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
      subtitle: subtitle ?? this.subtitle,
      subtitleStyle: subtitleStyle ?? this.subtitleStyle,
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
