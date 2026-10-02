import 'package:flutter/material.dart';

import '../utils/color_extensions.dart';

/// A utility class to create glassmorphic decoration effects.
class GlassmorphicDecoration {
  /// Creates a glassmorphic box decoration with a backdrop filter effect.
  ///
  /// This creates a frosted glass effect that is commonly used in modern UI designs.
  ///
  /// [borderRadius] specifies the roundness of the container corners.
  /// [blur] controls the intensity of the blur effect (higher values create more blur).
  /// [colors] are the gradient colors used in the background.
  /// [begin] and [end] define the gradient direction.
  /// [opacity] controls the transparency of the colors.
  /// [border] determines if a subtle border should be added.
  /// [borderColor] defines the color of the border if enabled.
  /// [borderWidth] defines the width of the border if enabled.
  /// [shadow] determines if a shadow should be added.
  /// [shadowColor] defines the color of the shadow if enabled.
  /// [shadowBlur] controls the blur radius of the shadow.
  /// [shadowSpread] controls how far the shadow spreads.
  /// [backgroundColor] defines the color/opacity on top of the blur effect.
  static BoxDecoration create({
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(16)),
    double blur = 10.0,
    List<Color> colors = const [Colors.white, Colors.white],
    AlignmentGeometry begin = Alignment.topLeft,
    AlignmentGeometry end = Alignment.bottomRight,
    double opacity = 0.2,
    bool border = true,
    Color borderColor = Colors.white,
    double borderWidth = 1.5,
    bool shadow = true,
    Color shadowColor = Colors.black,
    double shadowBlur = 15,
    double shadowSpread = 5,
    Color backgroundColor = Colors.transparent,
  }) {
    return BoxDecoration(
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
    );
  }
}
