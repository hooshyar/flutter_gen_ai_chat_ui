import 'dart:ui';

import 'package:flutter/material.dart';

/// Platform-specific theme variations to ensure native look and feel
@immutable
class PlatformThemeVariants {
  /// iOS-specific theming
  final IOSThemeVariant ios;

  /// Android-specific theming
  final AndroidThemeVariant android;

  /// Web-specific theming
  final WebThemeVariant web;

  /// Desktop-specific theming (Windows, macOS, Linux)
  final DesktopThemeVariant desktop;

  const PlatformThemeVariants({
    this.ios = const IOSThemeVariant(),
    this.android = const AndroidThemeVariant(),
    this.web = const WebThemeVariant(),
    this.desktop = const DesktopThemeVariant(),
  });

  /// Create a copy with different values
  PlatformThemeVariants copyWith({
    IOSThemeVariant? ios,
    AndroidThemeVariant? android,
    WebThemeVariant? web,
    DesktopThemeVariant? desktop,
  }) {
    return PlatformThemeVariants(
      ios: ios ?? this.ios,
      android: android ?? this.android,
      web: web ?? this.web,
      desktop: desktop ?? this.desktop,
    );
  }

  /// Lerp between two platform theme variants
  PlatformThemeVariants lerp(PlatformThemeVariants other, double t) {
    return PlatformThemeVariants(
      ios: ios.lerp(other.ios, t),
      android: android.lerp(other.android, t),
      web: web.lerp(other.web, t),
      desktop: desktop.lerp(other.desktop, t),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PlatformThemeVariants &&
            ios == other.ios &&
            android == other.android &&
            web == other.web &&
            desktop == other.desktop);
  }

  @override
  int get hashCode {
    return Object.hash(ios, android, web, desktop);
  }
}

/// iOS-specific theme variant following Human Interface Guidelines
/// iOS-specific theme overrides following Human Interface Guidelines.
@immutable
class IOSThemeVariant {
  /// Use SF Symbols when available
  final bool useSFSymbols;

  /// iOS haptic feedback settings
  final bool enableHapticFeedback;

  /// iOS scroll behavior
  final ScrollPhysics scrollPhysics;

  /// iOS blur effect strength
  final double blurEffectStrength;

  /// iOS corner radius style
  final double cornerRadiusScale;

  /// iOS shadows (lighter on iOS)
  final double shadowOpacity;

  /// iOS color intensity
  final double colorSaturation;

  const IOSThemeVariant({
    this.useSFSymbols = true,
    this.enableHapticFeedback = true,
    this.scrollPhysics = const BouncingScrollPhysics(),
    this.blurEffectStrength = 1.0,
    this.cornerRadiusScale = 1.0,
    this.shadowOpacity = 0.1,
    this.colorSaturation = 1.0,
  });

  IOSThemeVariant copyWith({
    bool? useSFSymbols,
    bool? enableHapticFeedback,
    ScrollPhysics? scrollPhysics,
    double? blurEffectStrength,
    double? cornerRadiusScale,
    double? shadowOpacity,
    double? colorSaturation,
  }) {
    return IOSThemeVariant(
      useSFSymbols: useSFSymbols ?? this.useSFSymbols,
      enableHapticFeedback: enableHapticFeedback ?? this.enableHapticFeedback,
      scrollPhysics: scrollPhysics ?? this.scrollPhysics,
      blurEffectStrength: blurEffectStrength ?? this.blurEffectStrength,
      cornerRadiusScale: cornerRadiusScale ?? this.cornerRadiusScale,
      shadowOpacity: shadowOpacity ?? this.shadowOpacity,
      colorSaturation: colorSaturation ?? this.colorSaturation,
    );
  }

  IOSThemeVariant lerp(IOSThemeVariant other, double t) {
    return IOSThemeVariant(
      useSFSymbols: t < 0.5 ? useSFSymbols : other.useSFSymbols,
      enableHapticFeedback:
          t < 0.5 ? enableHapticFeedback : other.enableHapticFeedback,
      scrollPhysics: t < 0.5 ? scrollPhysics : other.scrollPhysics,
      blurEffectStrength:
          lerpDouble(blurEffectStrength, other.blurEffectStrength, t) ??
              blurEffectStrength,
      cornerRadiusScale:
          lerpDouble(cornerRadiusScale, other.cornerRadiusScale, t) ??
              cornerRadiusScale,
      shadowOpacity:
          lerpDouble(shadowOpacity, other.shadowOpacity, t) ?? shadowOpacity,
      colorSaturation: lerpDouble(colorSaturation, other.colorSaturation, t) ??
          colorSaturation,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is IOSThemeVariant &&
            useSFSymbols == other.useSFSymbols &&
            enableHapticFeedback == other.enableHapticFeedback &&
            blurEffectStrength == other.blurEffectStrength &&
            cornerRadiusScale == other.cornerRadiusScale &&
            shadowOpacity == other.shadowOpacity &&
            colorSaturation == other.colorSaturation);
  }

  @override
  int get hashCode {
    return Object.hash(
      useSFSymbols,
      enableHapticFeedback,
      blurEffectStrength,
      cornerRadiusScale,
      shadowOpacity,
      colorSaturation,
    );
  }
}

/// Android-specific theme variant following Material Design Guidelines
/// Android-specific theme overrides following Material Design guidelines.
@immutable
class AndroidThemeVariant {
  /// Use Material Design 3 components
  final bool useMaterial3;

  /// Android ripple effects
  final bool enableRippleEffects;

  /// Android scroll behavior
  final ScrollPhysics scrollPhysics;

  /// Material elevation intensity
  final double elevationScale;

  /// Material corner radius style
  final double cornerRadiusScale;

  /// Material shadows (stronger on Android)
  final double shadowOpacity;

  /// Material color intensity
  final double colorSaturation;

  const AndroidThemeVariant({
    this.useMaterial3 = true,
    this.enableRippleEffects = true,
    this.scrollPhysics = const ClampingScrollPhysics(),
    this.elevationScale = 1.0,
    this.cornerRadiusScale = 1.0,
    this.shadowOpacity = 0.2,
    this.colorSaturation = 1.0,
  });

  AndroidThemeVariant copyWith({
    bool? useMaterial3,
    bool? enableRippleEffects,
    ScrollPhysics? scrollPhysics,
    double? elevationScale,
    double? cornerRadiusScale,
    double? shadowOpacity,
    double? colorSaturation,
  }) {
    return AndroidThemeVariant(
      useMaterial3: useMaterial3 ?? this.useMaterial3,
      enableRippleEffects: enableRippleEffects ?? this.enableRippleEffects,
      scrollPhysics: scrollPhysics ?? this.scrollPhysics,
      elevationScale: elevationScale ?? this.elevationScale,
      cornerRadiusScale: cornerRadiusScale ?? this.cornerRadiusScale,
      shadowOpacity: shadowOpacity ?? this.shadowOpacity,
      colorSaturation: colorSaturation ?? this.colorSaturation,
    );
  }

  AndroidThemeVariant lerp(AndroidThemeVariant other, double t) {
    return AndroidThemeVariant(
      useMaterial3: t < 0.5 ? useMaterial3 : other.useMaterial3,
      enableRippleEffects:
          t < 0.5 ? enableRippleEffects : other.enableRippleEffects,
      scrollPhysics: t < 0.5 ? scrollPhysics : other.scrollPhysics,
      elevationScale:
          lerpDouble(elevationScale, other.elevationScale, t) ?? elevationScale,
      cornerRadiusScale:
          lerpDouble(cornerRadiusScale, other.cornerRadiusScale, t) ??
              cornerRadiusScale,
      shadowOpacity:
          lerpDouble(shadowOpacity, other.shadowOpacity, t) ?? shadowOpacity,
      colorSaturation: lerpDouble(colorSaturation, other.colorSaturation, t) ??
          colorSaturation,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is AndroidThemeVariant &&
            useMaterial3 == other.useMaterial3 &&
            enableRippleEffects == other.enableRippleEffects &&
            elevationScale == other.elevationScale &&
            cornerRadiusScale == other.cornerRadiusScale &&
            shadowOpacity == other.shadowOpacity &&
            colorSaturation == other.colorSaturation);
  }

  @override
  int get hashCode {
    return Object.hash(
      useMaterial3,
      enableRippleEffects,
      elevationScale,
      cornerRadiusScale,
      shadowOpacity,
      colorSaturation,
    );
  }
}

/// Web-specific theme variant for browser environments
/// Web-specific theme overrides optimized for browser rendering and responsiveness.
@immutable
class WebThemeVariant {
  /// Web scroll behavior
  final ScrollPhysics scrollPhysics;

  /// Hover effects for mouse interaction
  final bool enableHoverEffects;

  /// Web-specific cursor behavior
  final bool enableCursorEffects;

  /// Web accessibility features
  final bool enhancedAccessibility;

  /// Web performance optimizations
  final bool enableWebOptimizations;

  /// Web blur effects (can be expensive)
  final double blurEffectStrength;

  const WebThemeVariant({
    this.scrollPhysics = const ClampingScrollPhysics(),
    this.enableHoverEffects = true,
    this.enableCursorEffects = true,
    this.enhancedAccessibility = true,
    this.enableWebOptimizations = true,
    this.blurEffectStrength = 0.8,
  });

  WebThemeVariant copyWith({
    ScrollPhysics? scrollPhysics,
    bool? enableHoverEffects,
    bool? enableCursorEffects,
    bool? enhancedAccessibility,
    bool? enableWebOptimizations,
    double? blurEffectStrength,
  }) {
    return WebThemeVariant(
      scrollPhysics: scrollPhysics ?? this.scrollPhysics,
      enableHoverEffects: enableHoverEffects ?? this.enableHoverEffects,
      enableCursorEffects: enableCursorEffects ?? this.enableCursorEffects,
      enhancedAccessibility:
          enhancedAccessibility ?? this.enhancedAccessibility,
      enableWebOptimizations:
          enableWebOptimizations ?? this.enableWebOptimizations,
      blurEffectStrength: blurEffectStrength ?? this.blurEffectStrength,
    );
  }

  WebThemeVariant lerp(WebThemeVariant other, double t) {
    return WebThemeVariant(
      scrollPhysics: t < 0.5 ? scrollPhysics : other.scrollPhysics,
      enableHoverEffects:
          t < 0.5 ? enableHoverEffects : other.enableHoverEffects,
      enableCursorEffects:
          t < 0.5 ? enableCursorEffects : other.enableCursorEffects,
      enhancedAccessibility:
          t < 0.5 ? enhancedAccessibility : other.enhancedAccessibility,
      enableWebOptimizations:
          t < 0.5 ? enableWebOptimizations : other.enableWebOptimizations,
      blurEffectStrength:
          lerpDouble(blurEffectStrength, other.blurEffectStrength, t) ??
              blurEffectStrength,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is WebThemeVariant &&
            enableHoverEffects == other.enableHoverEffects &&
            enableCursorEffects == other.enableCursorEffects &&
            enhancedAccessibility == other.enhancedAccessibility &&
            enableWebOptimizations == other.enableWebOptimizations &&
            blurEffectStrength == other.blurEffectStrength);
  }

  @override
  int get hashCode {
    return Object.hash(
      enableHoverEffects,
      enableCursorEffects,
      enhancedAccessibility,
      enableWebOptimizations,
      blurEffectStrength,
    );
  }
}

/// Desktop-specific theme variant for Windows, macOS, Linux
/// Desktop-specific theme overrides for macOS, Windows, and Linux.
@immutable
class DesktopThemeVariant {
  /// Desktop scroll behavior
  final ScrollPhysics scrollPhysics;

  /// Desktop hover effects
  final bool enableHoverEffects;

  /// Desktop keyboard shortcuts
  final bool enableKeyboardShortcuts;

  /// Desktop context menus
  final bool enableContextMenus;

  /// Desktop window integration
  final bool enableWindowIntegration;

  /// Desktop spacing (more generous)
  final double spacingScale;

  const DesktopThemeVariant({
    this.scrollPhysics = const ClampingScrollPhysics(),
    this.enableHoverEffects = true,
    this.enableKeyboardShortcuts = true,
    this.enableContextMenus = true,
    this.enableWindowIntegration = true,
    this.spacingScale = 1.2,
  });

  DesktopThemeVariant copyWith({
    ScrollPhysics? scrollPhysics,
    bool? enableHoverEffects,
    bool? enableKeyboardShortcuts,
    bool? enableContextMenus,
    bool? enableWindowIntegration,
    double? spacingScale,
  }) {
    return DesktopThemeVariant(
      scrollPhysics: scrollPhysics ?? this.scrollPhysics,
      enableHoverEffects: enableHoverEffects ?? this.enableHoverEffects,
      enableKeyboardShortcuts:
          enableKeyboardShortcuts ?? this.enableKeyboardShortcuts,
      enableContextMenus: enableContextMenus ?? this.enableContextMenus,
      enableWindowIntegration:
          enableWindowIntegration ?? this.enableWindowIntegration,
      spacingScale: spacingScale ?? this.spacingScale,
    );
  }

  DesktopThemeVariant lerp(DesktopThemeVariant other, double t) {
    return DesktopThemeVariant(
      scrollPhysics: t < 0.5 ? scrollPhysics : other.scrollPhysics,
      enableHoverEffects:
          t < 0.5 ? enableHoverEffects : other.enableHoverEffects,
      enableKeyboardShortcuts:
          t < 0.5 ? enableKeyboardShortcuts : other.enableKeyboardShortcuts,
      enableContextMenus:
          t < 0.5 ? enableContextMenus : other.enableContextMenus,
      enableWindowIntegration:
          t < 0.5 ? enableWindowIntegration : other.enableWindowIntegration,
      spacingScale:
          lerpDouble(spacingScale, other.spacingScale, t) ?? spacingScale,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is DesktopThemeVariant &&
            enableHoverEffects == other.enableHoverEffects &&
            enableKeyboardShortcuts == other.enableKeyboardShortcuts &&
            enableContextMenus == other.enableContextMenus &&
            enableWindowIntegration == other.enableWindowIntegration &&
            spacingScale == other.spacingScale);
  }

  @override
  int get hashCode {
    return Object.hash(
      enableHoverEffects,
      enableKeyboardShortcuts,
      enableContextMenus,
      enableWindowIntegration,
      spacingScale,
    );
  }
}
