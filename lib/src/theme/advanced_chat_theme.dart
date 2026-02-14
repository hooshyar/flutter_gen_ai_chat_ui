import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'chat_animation_presets.dart';
import 'chat_spacing.dart';
import 'chat_typography.dart';
import 'platform_theme_variants.dart';

/// Advanced chat theme system with 50+ sophisticated properties
/// supporting gradients, typography scales, animations, and platform variations
/// Comprehensive chat theme with 50+ properties including gradients, animations, and platform variants.
@immutable
class AdvancedChatTheme extends ThemeExtension<AdvancedChatTheme> {
  /// Background gradient system
  final List<Color> backgroundGradient;
  final AlignmentGeometry backgroundGradientBegin;
  final AlignmentGeometry backgroundGradientEnd;
  final List<double>? backgroundGradientStops;

  /// Message bubble gradients
  final List<Color> messageBubbleGradient;
  final List<Color> userBubbleGradient;
  final List<Color> aiResponseGradient;
  final List<Color> systemMessageGradient;

  /// Gradient alignment for bubbles
  final AlignmentGeometry messageBubbleGradientBegin;
  final AlignmentGeometry messageBubbleGradientEnd;
  final AlignmentGeometry userBubbleGradientBegin;
  final AlignmentGeometry userBubbleGradientEnd;

  /// Typography system
  final ChatTypography typography;

  /// Spacing system
  final ChatSpacing spacing;

  /// Animation presets
  final ChatAnimationPresets animations;

  /// Platform-specific variations
  final PlatformThemeVariants platform;

  /// Advanced shadow system
  final List<BoxShadow> messageBubbleShadows;
  final List<BoxShadow> userBubbleShadows;
  final List<BoxShadow> inputFieldShadows;
  final List<BoxShadow> floatingActionShadows;

  /// Border radius system
  final BorderRadiusGeometry messageBubbleBorderRadius;
  final BorderRadiusGeometry userBubbleBorderRadius;
  final BorderRadiusGeometry inputFieldBorderRadius;
  final BorderRadiusGeometry attachmentBorderRadius;

  /// Interactive state colors
  final Color pressedStateColor;
  final Color hoveredStateColor;
  final Color focusedStateColor;
  final Color disabledStateColor;

  /// Status indicator colors
  final Color sendingStatusColor;
  final Color sentStatusColor;
  final Color deliveredStatusColor;
  final Color readStatusColor;
  final Color errorStatusColor;

  /// Input field advanced theming
  final List<Color> inputFieldGradient;
  final Color inputFieldBorderColor;
  final Color inputFieldFocusedBorderColor;
  final Color inputFieldErrorBorderColor;
  final double inputFieldBorderWidth;
  final double inputFieldFocusedBorderWidth;

  /// Loading and streaming states
  final Color streamingIndicatorColor;
  final Color typingIndicatorColor;
  final List<Color> loadingShimmerGradient;
  final Color skeletonColor;
  final Color skeletonHighlightColor;

  /// Accessibility colors
  final Color highContrastBorderColor;
  final Color highContrastBackgroundColor;
  final Color selectionColor;
  final Color selectionHandleColor;

  /// Timestamp and metadata
  final Color timestampColor;
  final Color messageMetadataColor;
  final Color messageCounterColor;

  /// Action button colors
  final Color primaryActionColor;
  final Color secondaryActionColor;
  final Color destructiveActionColor;
  final Color favoriteActionColor;

  const AdvancedChatTheme({
    // Background gradient system
    this.backgroundGradient = const [Color(0xFFFFFFFF), Color(0xFFF8F9FA)],
    this.backgroundGradientBegin = Alignment.topCenter,
    this.backgroundGradientEnd = Alignment.bottomCenter,
    this.backgroundGradientStops,

    // Message bubble gradients
    this.messageBubbleGradient = const [Color(0xFFF0F0F0), Color(0xFFE8E8E8)],
    this.userBubbleGradient = const [Color(0xFF007AFF), Color(0xFF0051D5)],
    this.aiResponseGradient = const [Color(0xFFFFFFFF), Color(0xFFF5F5F5)],
    this.systemMessageGradient = const [Color(0xFFFFEB3B), Color(0xFFFFC107)],

    // Gradient alignments
    this.messageBubbleGradientBegin = Alignment.topLeft,
    this.messageBubbleGradientEnd = Alignment.bottomRight,
    this.userBubbleGradientBegin = Alignment.topLeft,
    this.userBubbleGradientEnd = Alignment.bottomRight,

    // Typography system
    required this.typography,

    // Spacing system
    required this.spacing,

    // Animation presets
    required this.animations,

    // Platform variations
    required this.platform,

    // Shadow system
    this.messageBubbleShadows = const [
      BoxShadow(
        color: Color(0x1A000000),
        offset: Offset(0, 1),
        blurRadius: 3,
        spreadRadius: 0,
      ),
    ],
    this.userBubbleShadows = const [
      BoxShadow(
        color: Color(0x1A000000),
        offset: Offset(0, 1),
        blurRadius: 3,
        spreadRadius: 0,
      ),
    ],
    this.inputFieldShadows = const [
      BoxShadow(
        color: Color(0x0D000000),
        offset: Offset(0, 1),
        blurRadius: 2,
        spreadRadius: 0,
      ),
    ],
    this.floatingActionShadows = const [
      BoxShadow(
        color: Color(0x26000000),
        offset: Offset(0, 2),
        blurRadius: 8,
        spreadRadius: 0,
      ),
    ],

    // Border radius system
    this.messageBubbleBorderRadius =
        const BorderRadius.all(Radius.circular(18)),
    this.userBubbleBorderRadius = const BorderRadius.all(Radius.circular(18)),
    this.inputFieldBorderRadius = const BorderRadius.all(Radius.circular(24)),
    this.attachmentBorderRadius = const BorderRadius.all(Radius.circular(12)),

    // Interactive states
    this.pressedStateColor = const Color(0x1A000000),
    this.hoveredStateColor = const Color(0x0D000000),
    this.focusedStateColor = const Color(0x1A007AFF),
    this.disabledStateColor = const Color(0x61000000),

    // Status indicators
    this.sendingStatusColor = const Color(0xFF9E9E9E),
    this.sentStatusColor = const Color(0xFF4CAF50),
    this.deliveredStatusColor = const Color(0xFF2196F3),
    this.readStatusColor = const Color(0xFF007AFF),
    this.errorStatusColor = const Color(0xFFF44336),

    // Input field theming
    this.inputFieldGradient = const [Color(0xFFFFFFFF), Color(0xFFFAFAFA)],
    this.inputFieldBorderColor = const Color(0xFFE0E0E0),
    this.inputFieldFocusedBorderColor = const Color(0xFF007AFF),
    this.inputFieldErrorBorderColor = const Color(0xFFF44336),
    this.inputFieldBorderWidth = 1.0,
    this.inputFieldFocusedBorderWidth = 2.0,

    // Loading states
    this.streamingIndicatorColor = const Color(0xFF007AFF),
    this.typingIndicatorColor = const Color(0xFF9E9E9E),
    this.loadingShimmerGradient = const [
      Color(0xFFE0E0E0),
      Color(0xFFF5F5F5),
      Color(0xFFE0E0E0),
    ],
    this.skeletonColor = const Color(0xFFE0E0E0),
    this.skeletonHighlightColor = const Color(0xFFF5F5F5),

    // Accessibility
    this.highContrastBorderColor = const Color(0xFF000000),
    this.highContrastBackgroundColor = const Color(0xFFFFFFFF),
    this.selectionColor = const Color(0x4D007AFF),
    this.selectionHandleColor = const Color(0xFF007AFF),

    // Metadata
    this.timestampColor = const Color(0xFF757575),
    this.messageMetadataColor = const Color(0xFF9E9E9E),
    this.messageCounterColor = const Color(0xFFF44336),

    // Action buttons
    this.primaryActionColor = const Color(0xFF007AFF),
    this.secondaryActionColor = const Color(0xFF9E9E9E),
    this.destructiveActionColor = const Color(0xFFF44336),
    this.favoriteActionColor = const Color(0xFFFFEB3B),
  });

  @override
  AdvancedChatTheme copyWith({
    // Background gradient
    List<Color>? backgroundGradient,
    AlignmentGeometry? backgroundGradientBegin,
    AlignmentGeometry? backgroundGradientEnd,
    List<double>? backgroundGradientStops,

    // Message gradients
    List<Color>? messageBubbleGradient,
    List<Color>? userBubbleGradient,
    List<Color>? aiResponseGradient,
    List<Color>? systemMessageGradient,

    // Gradient alignments
    AlignmentGeometry? messageBubbleGradientBegin,
    AlignmentGeometry? messageBubbleGradientEnd,
    AlignmentGeometry? userBubbleGradientBegin,
    AlignmentGeometry? userBubbleGradientEnd,

    // Core systems
    ChatTypography? typography,
    ChatSpacing? spacing,
    ChatAnimationPresets? animations,
    PlatformThemeVariants? platform,

    // Shadows
    List<BoxShadow>? messageBubbleShadows,
    List<BoxShadow>? userBubbleShadows,
    List<BoxShadow>? inputFieldShadows,
    List<BoxShadow>? floatingActionShadows,

    // Border radius
    BorderRadiusGeometry? messageBubbleBorderRadius,
    BorderRadiusGeometry? userBubbleBorderRadius,
    BorderRadiusGeometry? inputFieldBorderRadius,
    BorderRadiusGeometry? attachmentBorderRadius,

    // Interactive states
    Color? pressedStateColor,
    Color? hoveredStateColor,
    Color? focusedStateColor,
    Color? disabledStateColor,

    // Status indicators
    Color? sendingStatusColor,
    Color? sentStatusColor,
    Color? deliveredStatusColor,
    Color? readStatusColor,
    Color? errorStatusColor,

    // Input field
    List<Color>? inputFieldGradient,
    Color? inputFieldBorderColor,
    Color? inputFieldFocusedBorderColor,
    Color? inputFieldErrorBorderColor,
    double? inputFieldBorderWidth,
    double? inputFieldFocusedBorderWidth,

    // Loading states
    Color? streamingIndicatorColor,
    Color? typingIndicatorColor,
    List<Color>? loadingShimmerGradient,
    Color? skeletonColor,
    Color? skeletonHighlightColor,

    // Accessibility
    Color? highContrastBorderColor,
    Color? highContrastBackgroundColor,
    Color? selectionColor,
    Color? selectionHandleColor,

    // Metadata
    Color? timestampColor,
    Color? messageMetadataColor,
    Color? messageCounterColor,

    // Actions
    Color? primaryActionColor,
    Color? secondaryActionColor,
    Color? destructiveActionColor,
    Color? favoriteActionColor,
  }) {
    return AdvancedChatTheme(
      // Background gradient
      backgroundGradient: backgroundGradient ?? this.backgroundGradient,
      backgroundGradientBegin:
          backgroundGradientBegin ?? this.backgroundGradientBegin,
      backgroundGradientEnd:
          backgroundGradientEnd ?? this.backgroundGradientEnd,
      backgroundGradientStops:
          backgroundGradientStops ?? this.backgroundGradientStops,

      // Message gradients
      messageBubbleGradient:
          messageBubbleGradient ?? this.messageBubbleGradient,
      userBubbleGradient: userBubbleGradient ?? this.userBubbleGradient,
      aiResponseGradient: aiResponseGradient ?? this.aiResponseGradient,
      systemMessageGradient:
          systemMessageGradient ?? this.systemMessageGradient,

      // Gradient alignments
      messageBubbleGradientBegin:
          messageBubbleGradientBegin ?? this.messageBubbleGradientBegin,
      messageBubbleGradientEnd:
          messageBubbleGradientEnd ?? this.messageBubbleGradientEnd,
      userBubbleGradientBegin:
          userBubbleGradientBegin ?? this.userBubbleGradientBegin,
      userBubbleGradientEnd:
          userBubbleGradientEnd ?? this.userBubbleGradientEnd,

      // Core systems
      typography: typography ?? this.typography,
      spacing: spacing ?? this.spacing,
      animations: animations ?? this.animations,
      platform: platform ?? this.platform,

      // Shadows
      messageBubbleShadows: messageBubbleShadows ?? this.messageBubbleShadows,
      userBubbleShadows: userBubbleShadows ?? this.userBubbleShadows,
      inputFieldShadows: inputFieldShadows ?? this.inputFieldShadows,
      floatingActionShadows:
          floatingActionShadows ?? this.floatingActionShadows,

      // Border radius
      messageBubbleBorderRadius:
          messageBubbleBorderRadius ?? this.messageBubbleBorderRadius,
      userBubbleBorderRadius:
          userBubbleBorderRadius ?? this.userBubbleBorderRadius,
      inputFieldBorderRadius:
          inputFieldBorderRadius ?? this.inputFieldBorderRadius,
      attachmentBorderRadius:
          attachmentBorderRadius ?? this.attachmentBorderRadius,

      // Interactive states
      pressedStateColor: pressedStateColor ?? this.pressedStateColor,
      hoveredStateColor: hoveredStateColor ?? this.hoveredStateColor,
      focusedStateColor: focusedStateColor ?? this.focusedStateColor,
      disabledStateColor: disabledStateColor ?? this.disabledStateColor,

      // Status indicators
      sendingStatusColor: sendingStatusColor ?? this.sendingStatusColor,
      sentStatusColor: sentStatusColor ?? this.sentStatusColor,
      deliveredStatusColor: deliveredStatusColor ?? this.deliveredStatusColor,
      readStatusColor: readStatusColor ?? this.readStatusColor,
      errorStatusColor: errorStatusColor ?? this.errorStatusColor,

      // Input field
      inputFieldGradient: inputFieldGradient ?? this.inputFieldGradient,
      inputFieldBorderColor:
          inputFieldBorderColor ?? this.inputFieldBorderColor,
      inputFieldFocusedBorderColor:
          inputFieldFocusedBorderColor ?? this.inputFieldFocusedBorderColor,
      inputFieldErrorBorderColor:
          inputFieldErrorBorderColor ?? this.inputFieldErrorBorderColor,
      inputFieldBorderWidth:
          inputFieldBorderWidth ?? this.inputFieldBorderWidth,
      inputFieldFocusedBorderWidth:
          inputFieldFocusedBorderWidth ?? this.inputFieldFocusedBorderWidth,

      // Loading states
      streamingIndicatorColor:
          streamingIndicatorColor ?? this.streamingIndicatorColor,
      typingIndicatorColor: typingIndicatorColor ?? this.typingIndicatorColor,
      loadingShimmerGradient:
          loadingShimmerGradient ?? this.loadingShimmerGradient,
      skeletonColor: skeletonColor ?? this.skeletonColor,
      skeletonHighlightColor:
          skeletonHighlightColor ?? this.skeletonHighlightColor,

      // Accessibility
      highContrastBorderColor:
          highContrastBorderColor ?? this.highContrastBorderColor,
      highContrastBackgroundColor:
          highContrastBackgroundColor ?? this.highContrastBackgroundColor,
      selectionColor: selectionColor ?? this.selectionColor,
      selectionHandleColor: selectionHandleColor ?? this.selectionHandleColor,

      // Metadata
      timestampColor: timestampColor ?? this.timestampColor,
      messageMetadataColor: messageMetadataColor ?? this.messageMetadataColor,
      messageCounterColor: messageCounterColor ?? this.messageCounterColor,

      // Actions
      primaryActionColor: primaryActionColor ?? this.primaryActionColor,
      secondaryActionColor: secondaryActionColor ?? this.secondaryActionColor,
      destructiveActionColor:
          destructiveActionColor ?? this.destructiveActionColor,
      favoriteActionColor: favoriteActionColor ?? this.favoriteActionColor,
    );
  }

  @override
  AdvancedChatTheme lerp(ThemeExtension<AdvancedChatTheme>? other, double t) {
    if (other is! AdvancedChatTheme) return this;

    return AdvancedChatTheme(
      // Background gradient
      backgroundGradient:
          _lerpColorList(backgroundGradient, other.backgroundGradient, t),
      backgroundGradientBegin: AlignmentGeometry.lerp(
              backgroundGradientBegin, other.backgroundGradientBegin, t) ??
          backgroundGradientBegin,
      backgroundGradientEnd: AlignmentGeometry.lerp(
              backgroundGradientEnd, other.backgroundGradientEnd, t) ??
          backgroundGradientEnd,
      backgroundGradientStops: _lerpDoubleList(
          backgroundGradientStops, other.backgroundGradientStops, t),

      // Message gradients
      messageBubbleGradient:
          _lerpColorList(messageBubbleGradient, other.messageBubbleGradient, t),
      userBubbleGradient:
          _lerpColorList(userBubbleGradient, other.userBubbleGradient, t),
      aiResponseGradient:
          _lerpColorList(aiResponseGradient, other.aiResponseGradient, t),
      systemMessageGradient:
          _lerpColorList(systemMessageGradient, other.systemMessageGradient, t),

      // Gradient alignments
      messageBubbleGradientBegin: AlignmentGeometry.lerp(
              messageBubbleGradientBegin,
              other.messageBubbleGradientBegin,
              t) ??
          messageBubbleGradientBegin,
      messageBubbleGradientEnd: AlignmentGeometry.lerp(
              messageBubbleGradientEnd, other.messageBubbleGradientEnd, t) ??
          messageBubbleGradientEnd,
      userBubbleGradientBegin: AlignmentGeometry.lerp(
              userBubbleGradientBegin, other.userBubbleGradientBegin, t) ??
          userBubbleGradientBegin,
      userBubbleGradientEnd: AlignmentGeometry.lerp(
              userBubbleGradientEnd, other.userBubbleGradientEnd, t) ??
          userBubbleGradientEnd,

      // Core systems
      typography: typography.lerp(other.typography, t),
      spacing: spacing.lerp(other.spacing, t),
      animations: animations.lerp(other.animations, t),
      platform: platform.lerp(other.platform, t),

      // Shadows
      messageBubbleShadows: BoxShadow.lerpList(
              messageBubbleShadows, other.messageBubbleShadows, t) ??
          messageBubbleShadows,
      userBubbleShadows:
          BoxShadow.lerpList(userBubbleShadows, other.userBubbleShadows, t) ??
              userBubbleShadows,
      inputFieldShadows:
          BoxShadow.lerpList(inputFieldShadows, other.inputFieldShadows, t) ??
              inputFieldShadows,
      floatingActionShadows: BoxShadow.lerpList(
              floatingActionShadows, other.floatingActionShadows, t) ??
          floatingActionShadows,

      // Border radius
      messageBubbleBorderRadius: BorderRadiusGeometry.lerp(
              messageBubbleBorderRadius, other.messageBubbleBorderRadius, t) ??
          messageBubbleBorderRadius,
      userBubbleBorderRadius: BorderRadiusGeometry.lerp(
              userBubbleBorderRadius, other.userBubbleBorderRadius, t) ??
          userBubbleBorderRadius,
      inputFieldBorderRadius: BorderRadiusGeometry.lerp(
              inputFieldBorderRadius, other.inputFieldBorderRadius, t) ??
          inputFieldBorderRadius,
      attachmentBorderRadius: BorderRadiusGeometry.lerp(
              attachmentBorderRadius, other.attachmentBorderRadius, t) ??
          attachmentBorderRadius,

      // Interactive states
      pressedStateColor:
          Color.lerp(pressedStateColor, other.pressedStateColor, t) ??
              pressedStateColor,
      hoveredStateColor:
          Color.lerp(hoveredStateColor, other.hoveredStateColor, t) ??
              hoveredStateColor,
      focusedStateColor:
          Color.lerp(focusedStateColor, other.focusedStateColor, t) ??
              focusedStateColor,
      disabledStateColor:
          Color.lerp(disabledStateColor, other.disabledStateColor, t) ??
              disabledStateColor,

      // Status indicators
      sendingStatusColor:
          Color.lerp(sendingStatusColor, other.sendingStatusColor, t) ??
              sendingStatusColor,
      sentStatusColor: Color.lerp(sentStatusColor, other.sentStatusColor, t) ??
          sentStatusColor,
      deliveredStatusColor:
          Color.lerp(deliveredStatusColor, other.deliveredStatusColor, t) ??
              deliveredStatusColor,
      readStatusColor: Color.lerp(readStatusColor, other.readStatusColor, t) ??
          readStatusColor,
      errorStatusColor:
          Color.lerp(errorStatusColor, other.errorStatusColor, t) ??
              errorStatusColor,

      // Input field
      inputFieldGradient:
          _lerpColorList(inputFieldGradient, other.inputFieldGradient, t),
      inputFieldBorderColor:
          Color.lerp(inputFieldBorderColor, other.inputFieldBorderColor, t) ??
              inputFieldBorderColor,
      inputFieldFocusedBorderColor: Color.lerp(inputFieldFocusedBorderColor,
              other.inputFieldFocusedBorderColor, t) ??
          inputFieldFocusedBorderColor,
      inputFieldErrorBorderColor: Color.lerp(inputFieldErrorBorderColor,
              other.inputFieldErrorBorderColor, t) ??
          inputFieldErrorBorderColor,
      inputFieldBorderWidth:
          lerpDouble(inputFieldBorderWidth, other.inputFieldBorderWidth, t) ??
              inputFieldBorderWidth,
      inputFieldFocusedBorderWidth: lerpDouble(inputFieldFocusedBorderWidth,
              other.inputFieldFocusedBorderWidth, t) ??
          inputFieldFocusedBorderWidth,

      // Loading states
      streamingIndicatorColor: Color.lerp(
              streamingIndicatorColor, other.streamingIndicatorColor, t) ??
          streamingIndicatorColor,
      typingIndicatorColor:
          Color.lerp(typingIndicatorColor, other.typingIndicatorColor, t) ??
              typingIndicatorColor,
      loadingShimmerGradient: _lerpColorList(
          loadingShimmerGradient, other.loadingShimmerGradient, t),
      skeletonColor:
          Color.lerp(skeletonColor, other.skeletonColor, t) ?? skeletonColor,
      skeletonHighlightColor:
          Color.lerp(skeletonHighlightColor, other.skeletonHighlightColor, t) ??
              skeletonHighlightColor,

      // Accessibility
      highContrastBorderColor: Color.lerp(
              highContrastBorderColor, other.highContrastBorderColor, t) ??
          highContrastBorderColor,
      highContrastBackgroundColor: Color.lerp(highContrastBackgroundColor,
              other.highContrastBackgroundColor, t) ??
          highContrastBackgroundColor,
      selectionColor:
          Color.lerp(selectionColor, other.selectionColor, t) ?? selectionColor,
      selectionHandleColor:
          Color.lerp(selectionHandleColor, other.selectionHandleColor, t) ??
              selectionHandleColor,

      // Metadata
      timestampColor:
          Color.lerp(timestampColor, other.timestampColor, t) ?? timestampColor,
      messageMetadataColor:
          Color.lerp(messageMetadataColor, other.messageMetadataColor, t) ??
              messageMetadataColor,
      messageCounterColor:
          Color.lerp(messageCounterColor, other.messageCounterColor, t) ??
              messageCounterColor,

      // Actions
      primaryActionColor:
          Color.lerp(primaryActionColor, other.primaryActionColor, t) ??
              primaryActionColor,
      secondaryActionColor:
          Color.lerp(secondaryActionColor, other.secondaryActionColor, t) ??
              secondaryActionColor,
      destructiveActionColor:
          Color.lerp(destructiveActionColor, other.destructiveActionColor, t) ??
              destructiveActionColor,
      favoriteActionColor:
          Color.lerp(favoriteActionColor, other.favoriteActionColor, t) ??
              favoriteActionColor,
    );
  }

  /// Helper method to lerp color lists
  List<Color> _lerpColorList(List<Color> a, List<Color> b, double t) {
    if (a.length != b.length) return t < 0.5 ? a : b;

    return List.generate(
      a.length,
      (index) => Color.lerp(a[index], b[index], t) ?? a[index],
    );
  }

  /// Helper method to lerp double lists
  List<double>? _lerpDoubleList(List<double>? a, List<double>? b, double t) {
    if (a == null && b == null) return null;
    if (a == null) return t < 0.5 ? null : b;
    if (b == null) return t < 0.5 ? a : null;
    if (a.length != b.length) return t < 0.5 ? a : b;

    return List.generate(
      a.length,
      (index) => lerpDouble(a[index], b[index], t) ?? a[index],
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is AdvancedChatTheme &&
            listEquals(backgroundGradient, other.backgroundGradient) &&
            backgroundGradientBegin == other.backgroundGradientBegin &&
            backgroundGradientEnd == other.backgroundGradientEnd &&
            listEquals(
                backgroundGradientStops, other.backgroundGradientStops) &&
            listEquals(messageBubbleGradient, other.messageBubbleGradient) &&
            listEquals(userBubbleGradient, other.userBubbleGradient) &&
            listEquals(aiResponseGradient, other.aiResponseGradient) &&
            listEquals(systemMessageGradient, other.systemMessageGradient) &&
            typography == other.typography &&
            spacing == other.spacing &&
            animations == other.animations &&
            platform == other.platform);
  }

  @override
  int get hashCode {
    return Object.hashAll([
      Object.hashAll(backgroundGradient),
      backgroundGradientBegin,
      backgroundGradientEnd,
      Object.hashAll(backgroundGradientStops ?? []),
      Object.hashAll(messageBubbleGradient),
      Object.hashAll(userBubbleGradient),
      Object.hashAll(aiResponseGradient),
      Object.hashAll(systemMessageGradient),
      typography,
      spacing,
      animations,
      platform,
    ]);
  }
}
