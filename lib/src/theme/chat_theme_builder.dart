import 'package:flutter/material.dart';

import 'advanced_chat_theme.dart';
import 'chat_animation_presets.dart';
import 'chat_spacing.dart';
import 'chat_typography.dart';
import 'platform_theme_variants.dart';

/// Powerful theme builder for creating custom chat themes
class ChatThemeBuilder {
  late AdvancedChatTheme _theme;

  ChatThemeBuilder._internal(AdvancedChatTheme theme) : _theme = theme;

  /// Create a theme builder from brand colors
  factory ChatThemeBuilder.fromBrand({
    required Color primaryColor,
    required Color secondaryColor,
    Color? backgroundColor,
    Brightness brightness = Brightness.light,
  }) {
    final isDark = brightness == Brightness.dark;
    final baseBackground = backgroundColor ??
        (isDark ? const Color(0xFF121212) : const Color(0xFFFFFFFF));

    // Generate complementary colors
    final primary = primaryColor;
    final secondary = secondaryColor;
    final surface = isDark
        ? Color.lerp(baseBackground, primary, 0.05)!
        : Color.lerp(baseBackground, primary, 0.02)!;

    final userBubbleGradient = [primary, Color.lerp(primary, secondary, 0.3)!];

    final messageBubbleGradient = [surface, Color.lerp(surface, primary, 0.1)!];

    final backgroundGradient = [
      baseBackground,
      Color.lerp(baseBackground, primary, 0.02)!,
    ];

    return ChatThemeBuilder._internal(
      AdvancedChatTheme(
        // Background gradients
        backgroundGradient: backgroundGradient,
        backgroundGradientBegin: Alignment.topCenter,
        backgroundGradientEnd: Alignment.bottomCenter,

        // Message gradients
        messageBubbleGradient: messageBubbleGradient,
        userBubbleGradient: userBubbleGradient,
        aiResponseGradient: messageBubbleGradient,

        // Core systems with defaults
        typography: const ChatTypography(),
        spacing: const ChatSpacing(),
        animations: const ChatAnimationPresets(),
        platform: const PlatformThemeVariants(),

        // Colors derived from brand
        primaryActionColor: primary,
        secondaryActionColor: secondary,
        inputFieldFocusedBorderColor: primary,
        streamingIndicatorColor: primary,
        readStatusColor: primary,
      ),
    );
  }

  /// Create a theme builder from an image (extracts dominant colors)
  factory ChatThemeBuilder.fromImage() {
    // Note: In a real implementation, you'd extract colors from the image
    // For now, we'll create a sophisticated default theme
    return ChatThemeBuilder._internal(
      const AdvancedChatTheme(
        backgroundGradient: [Color(0xFFF8F9FA), Color(0xFFE9ECEF)],
        userBubbleGradient: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
        messageBubbleGradient: [Color(0xFFFFFFFF), Color(0xFFF1F3F4)],
        typography: ChatTypography(),
        spacing: ChatSpacing(),
        animations: ChatAnimationPresets(),
        platform: PlatformThemeVariants(),
      ),
    );
  }

  /// Create a minimal theme with clean aesthetics
  factory ChatThemeBuilder.minimal({Brightness brightness = Brightness.light}) {
    final isDark = brightness == Brightness.dark;

    if (isDark) {
      return ChatThemeBuilder._internal(
        const AdvancedChatTheme(
          backgroundGradient: [Color(0xFF000000), Color(0xFF111111)],
          messageBubbleGradient: [Color(0xFF1A1A1A), Color(0xFF2D2D2D)],
          userBubbleGradient: [Color(0xFF333333), Color(0xFF404040)],
          aiResponseGradient: [Color(0xFF1A1A1A), Color(0xFF262626)],
          typography: ChatTypography(),
          spacing: ChatSpacing(),
          animations: ChatAnimationPresets(),
          platform: PlatformThemeVariants(),
          // Minimal shadows
          messageBubbleShadows: [],
          userBubbleShadows: [],
          inputFieldShadows: [],
          floatingActionShadows: [],
        ),
      );
    } else {
      return ChatThemeBuilder._internal(
        const AdvancedChatTheme(
          backgroundGradient: [Color(0xFFFFFFFF), Color(0xFFFAFAFA)],
          messageBubbleGradient: [Color(0xFFF8F9FA), Color(0xFFFFFFFF)],
          userBubbleGradient: [Color(0xFFE3F2FD), Color(0xFFF3E5F5)],
          aiResponseGradient: [Color(0xFFFFFFFF), Color(0xFFF5F5F5)],
          typography: ChatTypography(),
          spacing: ChatSpacing(),
          animations: ChatAnimationPresets(),
          platform: PlatformThemeVariants(),
          // Minimal shadows
          messageBubbleShadows: [
            BoxShadow(
              color: Color(0x08000000),
              offset: Offset(0, 1),
              blurRadius: 2,
            ),
          ],
          userBubbleShadows: [
            BoxShadow(
              color: Color(0x08000000),
              offset: Offset(0, 1),
              blurRadius: 2,
            ),
          ],
          inputFieldShadows: [],
          floatingActionShadows: [],
        ),
      );
    }
  }

  /// Create a glassmorphic theme with blur effects
  factory ChatThemeBuilder.glassmorphic({
    Brightness brightness = Brightness.light,
  }) {
    final isDark = brightness == Brightness.dark;

    if (isDark) {
      return ChatThemeBuilder._internal(
        const AdvancedChatTheme(
          backgroundGradient: [Color(0xFF0A0A0A), Color(0xFF1A1A1A)],
          messageBubbleGradient: [Color(0x40FFFFFF), Color(0x20FFFFFF)],
          userBubbleGradient: [Color(0x60007AFF), Color(0x40007AFF)],
          aiResponseGradient: [Color(0x30FFFFFF), Color(0x15FFFFFF)],
          typography: ChatTypography(),
          spacing: ChatSpacing(),
          animations: ChatAnimationPresets(),
          platform: PlatformThemeVariants(),
          // Glassmorphic shadows
          messageBubbleShadows: [
            BoxShadow(
              color: Color(0x20000000),
              offset: Offset(0, 8),
              blurRadius: 32,
              spreadRadius: 0,
            ),
          ],
          userBubbleShadows: [
            BoxShadow(
              color: Color(0x30007AFF),
              offset: Offset(0, 8),
              blurRadius: 32,
              spreadRadius: 0,
            ),
          ],
          inputFieldShadows: [
            BoxShadow(
              color: Color(0x15FFFFFF),
              offset: Offset(0, 4),
              blurRadius: 16,
              spreadRadius: 0,
            ),
          ],
        ),
      );
    } else {
      return ChatThemeBuilder._internal(
        const AdvancedChatTheme(
          backgroundGradient: [Color(0xFFF0F8FF), Color(0xFFE6F3FF)],
          messageBubbleGradient: [Color(0x80FFFFFF), Color(0x60FFFFFF)],
          userBubbleGradient: [Color(0x80007AFF), Color(0x60007AFF)],
          aiResponseGradient: [Color(0x90FFFFFF), Color(0x70FFFFFF)],
          typography: ChatTypography(),
          spacing: ChatSpacing(),
          animations: ChatAnimationPresets(),
          platform: PlatformThemeVariants(),
          // Glassmorphic shadows
          messageBubbleShadows: [
            BoxShadow(
              color: Color(0x10000000),
              offset: Offset(0, 8),
              blurRadius: 32,
              spreadRadius: 0,
            ),
          ],
          userBubbleShadows: [
            BoxShadow(
              color: Color(0x20007AFF),
              offset: Offset(0, 8),
              blurRadius: 32,
              spreadRadius: 0,
            ),
          ],
          inputFieldShadows: [
            BoxShadow(
              color: Color(0x08000000),
              offset: Offset(0, 4),
              blurRadius: 16,
              spreadRadius: 0,
            ),
          ],
        ),
      );
    }
  }

  /// Create a theme optimized for accessibility
  factory ChatThemeBuilder.accessible({
    Brightness brightness = Brightness.light,
  }) {
    return ChatThemeBuilder._internal(
      AdvancedChatTheme(
        backgroundGradient: brightness == Brightness.dark
            ? const [Color(0xFF000000), Color(0xFF000000)]
            : const [Color(0xFFFFFFFF), Color(0xFFFFFFFF)],
        messageBubbleGradient: brightness == Brightness.dark
            ? const [Color(0xFF2D2D2D), Color(0xFF2D2D2D)]
            : const [Color(0xFFF5F5F5), Color(0xFFF5F5F5)],
        userBubbleGradient: brightness == Brightness.dark
            ? const [Color(0xFF0066CC), Color(0xFF0066CC)]
            : const [Color(0xFF0066CC), Color(0xFF0066CC)],
        aiResponseGradient: brightness == Brightness.dark
            ? const [Color(0xFF1A1A1A), Color(0xFF1A1A1A)]
            : const [Color(0xFFFFFFFF), Color(0xFFFFFFFF)],
        typography: ChatTypography.accessible,
        spacing: ChatSpacing.comfortable,
        animations: ChatAnimationPresets.reduced,
        platform: const PlatformThemeVariants(),
        // High contrast borders
        highContrastBorderColor: brightness == Brightness.dark
            ? const Color(0xFFFFFFFF)
            : const Color(0xFF000000),
        inputFieldBorderWidth: 2.0,
        inputFieldFocusedBorderWidth: 3.0,
      ),
    );
  }

  /// Set custom typography
  ChatThemeBuilder withTypography(ChatTypography typography) {
    _theme = _theme.copyWith(typography: typography);
    return this;
  }

  /// Set custom spacing
  ChatThemeBuilder withSpacing(ChatSpacing spacing) {
    _theme = _theme.copyWith(spacing: spacing);
    return this;
  }

  /// Set custom animations
  ChatThemeBuilder withAnimations(ChatAnimationPresets animations) {
    _theme = _theme.copyWith(animations: animations);
    return this;
  }

  /// Set custom platform variants
  ChatThemeBuilder withPlatform(PlatformThemeVariants platform) {
    _theme = _theme.copyWith(platform: platform);
    return this;
  }

  /// Set custom background gradient
  ChatThemeBuilder withBackgroundGradient(
    List<Color> colors, {
    AlignmentGeometry begin = Alignment.topCenter,
    AlignmentGeometry end = Alignment.bottomCenter,
    List<double>? stops,
  }) {
    _theme = _theme.copyWith(
      backgroundGradient: colors,
      backgroundGradientBegin: begin,
      backgroundGradientEnd: end,
      backgroundGradientStops: stops,
    );
    return this;
  }

  /// Set custom message bubble gradients
  ChatThemeBuilder withMessageBubbleGradient(List<Color> colors) {
    _theme = _theme.copyWith(messageBubbleGradient: colors);
    return this;
  }

  /// Set custom user bubble gradients
  ChatThemeBuilder withUserBubbleGradient(List<Color> colors) {
    _theme = _theme.copyWith(userBubbleGradient: colors);
    return this;
  }

  /// Set custom shadows
  ChatThemeBuilder withShadows({
    List<BoxShadow>? messageBubbleShadows,
    List<BoxShadow>? userBubbleShadows,
    List<BoxShadow>? inputFieldShadows,
  }) {
    _theme = _theme.copyWith(
      messageBubbleShadows: messageBubbleShadows,
      userBubbleShadows: userBubbleShadows,
      inputFieldShadows: inputFieldShadows,
    );
    return this;
  }

  /// Set custom border radius
  ChatThemeBuilder withBorderRadius({
    BorderRadiusGeometry? messageBubbleBorderRadius,
    BorderRadiusGeometry? userBubbleBorderRadius,
    BorderRadiusGeometry? inputFieldBorderRadius,
  }) {
    _theme = _theme.copyWith(
      messageBubbleBorderRadius: messageBubbleBorderRadius,
      userBubbleBorderRadius: userBubbleBorderRadius,
      inputFieldBorderRadius: inputFieldBorderRadius,
    );
    return this;
  }

  /// Build the final theme
  AdvancedChatTheme build() {
    return _theme;
  }

  /// Quick preset builders for common use cases
  static AdvancedChatTheme chatGptStyle() {
    return ChatThemeBuilder.fromBrand(
      primaryColor: const Color(0xFF10A37F),
      secondaryColor: const Color(0xFF19C37D),
      backgroundColor: const Color(0xFFFFFFFF),
    )
        .withAnimations(ChatAnimationPresets.chatGptStyle)
        .withBorderRadius(
          messageBubbleBorderRadius: const BorderRadius.all(
            Radius.circular(12),
          ),
          userBubbleBorderRadius: const BorderRadius.all(Radius.circular(12)),
          inputFieldBorderRadius: const BorderRadius.all(Radius.circular(8)),
        )
        .build();
  }

  static AdvancedChatTheme claudeStyle() {
    return ChatThemeBuilder.fromBrand(
      primaryColor: const Color(0xFFCC785C),
      secondaryColor: const Color(0xFFF4A177),
      backgroundColor: const Color(0xFFFFFCF9),
    )
        .withAnimations(ChatAnimationPresets.claudeStyle)
        .withBorderRadius(
          messageBubbleBorderRadius: const BorderRadius.all(
            Radius.circular(16),
          ),
          userBubbleBorderRadius: const BorderRadius.all(Radius.circular(16)),
          inputFieldBorderRadius: const BorderRadius.all(Radius.circular(12)),
        )
        .build();
  }

  static AdvancedChatTheme geminiStyle() {
    return ChatThemeBuilder.fromBrand(
      primaryColor: const Color(0xFF4285F4),
      secondaryColor: const Color(0xFF34A853),
      backgroundColor: const Color(0xFFFFFFFF),
    )
        .withBorderRadius(
          messageBubbleBorderRadius: const BorderRadius.all(
            Radius.circular(18),
          ),
          userBubbleBorderRadius: const BorderRadius.all(Radius.circular(18)),
          inputFieldBorderRadius: const BorderRadius.all(Radius.circular(24)),
        )
        .build();
  }
}
