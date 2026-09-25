import 'dart:ui';

import 'package:flutter/material.dart';

import '../utils/color_extensions.dart';

/// A container with a glassmorphic effect (blurred transparent background).
class GlassmorphicContainer extends StatelessWidget {
  /// Creates a glassmorphic container with a frosted glass effect.
  const GlassmorphicContainer({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.blur = 10.0,
    this.colors = const [Colors.white, Colors.white],
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
    this.opacity = 0.2,
    this.border = true,
    this.borderColor = Colors.white,
    this.borderWidth = 1.5,
    this.shadow = true,
    this.shadowColor = Colors.black,
    this.shadowBlur = 15,
    this.shadowSpread = 5,
    this.height,
    this.width,
    this.margin,
    this.padding,
    this.backgroundColor = Colors.transparent,
  });

  /// Child widget to be rendered inside the container.
  final Widget child;

  /// The border radius of the container.
  final BorderRadius borderRadius;

  /// The blur intensity for the backdrop filter.
  final double blur;

  /// The gradient colors used in the background.
  final List<Color> colors;

  /// The gradient start position.
  final AlignmentGeometry begin;

  /// The gradient end position.
  final AlignmentGeometry end;

  /// Opacity level for the colors and effects.
  final double opacity;

  /// Whether to show a border around the container.
  final bool border;

  /// Color of the border (if [border] is true).
  final Color borderColor;

  /// Width of the border (if [border] is true).
  final double borderWidth;

  /// Whether to show a shadow under the container.
  final bool shadow;

  /// Color of the shadow (if [shadow] is true).
  final Color shadowColor;

  /// Blur radius of the shadow (if [shadow] is true).
  final double shadowBlur;

  /// Spread radius of the shadow (if [shadow] is true).
  final double shadowSpread;

  /// Fixed height of the container.
  final double? height;

  /// Fixed width of the container.
  final double? width;

  /// Margin around the container.
  final EdgeInsetsGeometry? margin;

  /// Padding inside the container.
  final EdgeInsetsGeometry? padding;

  /// Background color of the container (on top of the blur effect).
  /// Use a transparent color for maximum blur visibility or
  /// add a semi-transparent color for a tinted glass effect.
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      margin: margin,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: begin,
          end: end,
          colors:
              colors.map((color) => color.withOpacityCompat(opacity)).toList(),
        ),
        borderRadius: borderRadius,
        border: border
            ? Border.all(
                color: borderColor.withOpacityCompat(opacity),
                width: borderWidth,
              )
            : null,
        boxShadow: shadow
            ? [
                BoxShadow(
                  color: shadowColor.withOpacityCompat(opacity),
                  blurRadius: shadowBlur,
                  spreadRadius: shadowSpread,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: borderRadius,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
