import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../utils/color_extensions.dart';

/// A highly customizable loading widget that displays a shimmer effect with animated text.
class LoadingWidget extends StatefulWidget {
  /// Creates a loading widget with extensive customization options.
  const LoadingWidget({
    super.key,
    this.texts = const ['Loading...'],
    this.interval = const Duration(seconds: 2),
    this.textStyle,
    this.shimmerBaseColor,
    this.shimmerHighlightColor,
    this.margin,
    this.padding,
    this.containerDecoration,
    this.backgroundColor,
    this.borderRadius,
    this.border,
    this.boxShadow,
    this.elevation,
    this.gradientColors,
    this.gradientStops,
    this.gradientType = GradientType.linear,
    this.gradientAngle = 0,
    this.isGlassmorphic = false,
    this.blurStrength = 10,
    this.glassmorphicOpacity = 0.1,
    this.alignment,
    this.width,
    this.minWidth,
    this.maxWidth,
    this.height,
    this.minHeight,
    this.maxHeight,
  });

  /// The list of texts to cycle through.
  final List<String> texts;

  /// The interval between text changes.
  final Duration interval;

  /// The text style for the loading text.
  final TextStyle? textStyle;

  /// The base color for the shimmer effect.
  final Color? shimmerBaseColor;

  /// The highlight color for the shimmer effect.
  final Color? shimmerHighlightColor;

  /// Margin around the loading widget.
  final EdgeInsetsGeometry? margin;

  /// Padding inside the loading widget container.
  final EdgeInsetsGeometry? padding;

  /// Custom decoration for the container, overrides other decoration properties if provided.
  final BoxDecoration? containerDecoration;

  /// Background color of the container (ignored if containerDecoration is provided).
  final Color? backgroundColor;

  /// Border radius of the container (ignored if containerDecoration is provided).
  final BorderRadius? borderRadius;

  /// Border of the container (ignored if containerDecoration is provided).
  final BoxBorder? border;

  /// Box shadow of the container (ignored if containerDecoration is provided).
  final List<BoxShadow>? boxShadow;

  /// Material elevation of the container (if > 0, adds a shadow).
  final double? elevation;

  /// Gradient colors for the background (ignored if containerDecoration is provided).
  final List<Color>? gradientColors;

  /// Gradient stops for the gradient colors (should match gradientColors.length).
  final List<double>? gradientStops;

  /// Type of gradient to apply (linear, radial, or sweep).
  final GradientType gradientType;

  /// Angle for linear gradient in degrees (0-360).
  final double gradientAngle;

  /// Whether to apply a glassmorphic effect.
  final bool isGlassmorphic;

  /// Blur strength for glassmorphic effect.
  final double blurStrength;

  /// Opacity for the glassmorphic effect (0.0-1.0).
  final double glassmorphicOpacity;

  /// Alignment of the text within the container.
  /// If null, aligns based on the text direction (start alignment).
  final Alignment? alignment;

  /// Explicit width of the container.
  final double? width;

  /// Minimum width constraint.
  final double? minWidth;

  /// Maximum width constraint.
  final double? maxWidth;

  /// Explicit height of the container.
  final double? height;

  /// Minimum height constraint.
  final double? minHeight;

  /// Maximum height constraint.
  final double? maxHeight;

  @override
  State<LoadingWidget> createState() => _LoadingWidgetState();
}

/// Type of gradient to apply to the loading indicator background.
enum GradientType {
  /// Linear gradient that transitions from one color to another along a line.
  linear,

  /// Radial gradient that transitions from one color to another in a circular pattern.
  radial,

  /// Sweep gradient that transitions from one color to another in a sweeping pattern.
  sweep
}

class _LoadingWidgetState extends State<LoadingWidget> {
  late Timer _timer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(widget.interval, (final timer) {
      setState(() {
        _currentIndex = (_currentIndex + 1) % widget.texts.length;
      });
    });
  }

  /// Builds a gradient based on the specified parameters.
  Gradient? _buildGradient() {
    if (widget.gradientColors == null || widget.gradientColors!.isEmpty) {
      return null;
    }

    final colors = widget.gradientColors!;
    final stops = widget.gradientStops;

    // Convert angle to radians and calculate start/end points
    final angleInRadians = widget.gradientAngle * (math.pi / 180);
    final cosAngle = math.cos(angleInRadians);
    final sinAngle = math.sin(angleInRadians);
    final start = Alignment(cosAngle * -1, sinAngle * -1);
    final end = Alignment(cosAngle, sinAngle);

    switch (widget.gradientType) {
      case GradientType.linear:
        return LinearGradient(
          colors: colors,
          stops: stops,
          begin: start,
          end: end,
        );
      case GradientType.radial:
        return RadialGradient(
          colors: colors,
          stops: stops,
          center: Alignment.center,
          radius: 1.0,
        );
      case GradientType.sweep:
        return SweepGradient(
          colors: colors,
          stops: stops,
          center: Alignment.center,
          startAngle: 0.0,
          endAngle: math.pi * 2,
        );
    }
  }

  /// Builds the box decoration based on widget properties.
  BoxDecoration _buildDecoration(BuildContext context) {
    // Use provided decoration if available
    if (widget.containerDecoration != null) {
      return widget.containerDecoration!;
    }

    // Determine background
    var backgroundColor = widget.backgroundColor;

    // By default, use transparent backgrounds
    backgroundColor ??= Colors.transparent;

    // Build decoration
    return BoxDecoration(
      color: widget.isGlassmorphic ? Colors.transparent : backgroundColor,
      borderRadius: widget.borderRadius,
      border: widget.border,
      boxShadow: widget.boxShadow,
      gradient: _buildGradient(),
    );
  }

  @override
  Widget build(final BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = widget.shimmerBaseColor ??
        (isDark
            ? Theme.of(context).colorScheme.surface.withOpacityCompat(0.5)
            : const Color(0xFFF7F8F8));
    final highlightColor = widget.shimmerHighlightColor ??
        (isDark ? Theme.of(context).colorScheme.surface : Colors.white);

    // Create constraints for sizing
    final constraints = BoxConstraints(
      minWidth: widget.minWidth ?? 0,
      maxWidth: widget.maxWidth ?? double.infinity,
      minHeight: widget.minHeight ?? 0,
      maxHeight: widget.maxHeight ?? double.infinity,
    );

    // Check if we need to apply container styling (if any custom properties are set)
    final useContainerStyling = widget.backgroundColor != null ||
        widget.borderRadius != null ||
        widget.border != null ||
        widget.boxShadow != null ||
        widget.elevation != null ||
        widget.gradientColors != null ||
        widget.isGlassmorphic ||
        widget.containerDecoration != null;

    // Get the text direction from context for proper alignment
    final textDirection = Directionality.of(context);

    // Determine alignment based on text direction if not explicitly provided
    final effectiveAlignment = widget.alignment ??
        (textDirection == TextDirection.rtl
            ? Alignment.centerRight
            : Alignment.centerLeft);

    // Create the shimmer text content
    final textContent = Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
          return Stack(
            alignment: effectiveAlignment,
            children: <Widget>[
              ...previousChildren,
              if (currentChild != null) currentChild,
            ],
          );
        },
        child: Text(
          widget.texts[_currentIndex],
          key: ValueKey<String>(widget.texts[_currentIndex]),
          style: widget.textStyle ??
              TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.1,
              ),
          textAlign: textDirection == TextDirection.rtl
              ? TextAlign.right
              : TextAlign.left,
        ),
      ),
    );

    // If no custom styling is requested, just return the shimmer text with minimal padding
    if (!useContainerStyling) {
      return Container(
        padding: widget.padding ??
            const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        alignment: effectiveAlignment,
        child: textContent,
      );
    }

    // Otherwise build the full customizable container
    Widget content = Container(
      width: widget.width,
      height: widget.height,
      constraints: constraints,
      margin: widget.margin ??
          const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Material(
        color: Colors.transparent,
        elevation: widget.elevation ?? 0,
        borderRadius: widget.borderRadius,
        child: Container(
          decoration: _buildDecoration(context),
          padding: widget.padding ??
              const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          alignment: effectiveAlignment,
          child: textContent,
        ),
      ),
    );

    // Apply glassmorphic effect if enabled
    if (widget.isGlassmorphic) {
      content = ClipRRect(
        borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: widget.blurStrength,
            sigmaY: widget.blurStrength,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacityCompat(widget.glassmorphicOpacity)
                  : Colors.black.withOpacityCompat(widget.glassmorphicOpacity),
              borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
              border: widget.border ??
                  Border.all(
                    color: isDark
                        ? Colors.white.withOpacityCompat(0.2)
                        : Colors.white.withOpacityCompat(0.3),
                    width: 1.5,
                  ),
            ),
            child: content,
          ),
        ),
      );
    }

    return content;
  }
}
