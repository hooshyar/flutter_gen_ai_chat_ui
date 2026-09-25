import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen_ai_chat_ui/src/theme/advanced_chat_theme.dart';
import 'package:flutter_gen_ai_chat_ui/src/theme/chat_typography.dart';
import 'package:flutter_gen_ai_chat_ui/src/theme/chat_spacing.dart';
import 'package:flutter_gen_ai_chat_ui/src/theme/chat_animation_presets.dart';
import 'package:flutter_gen_ai_chat_ui/src/theme/platform_theme_variants.dart';

void main() {
  group('AdvancedChatTheme', () {
    test('should create theme with default values', () {
      const theme = AdvancedChatTheme(
        typography: ChatTypography(),
        spacing: ChatSpacing(),
        animations: ChatAnimationPresets(),
        platform: PlatformThemeVariants(),
      );

      expect(theme.backgroundGradient, isNotEmpty);
      expect(theme.messageBubbleGradient, isNotEmpty);
      expect(theme.userBubbleGradient, isNotEmpty);
      expect(theme.typography, isA<ChatTypography>());
      expect(theme.spacing, isA<ChatSpacing>());
      expect(theme.animations, isA<ChatAnimationPresets>());
      expect(theme.platform, isA<PlatformThemeVariants>());
    });

    test('should support copyWith functionality', () {
      const originalTheme = AdvancedChatTheme(
        typography: ChatTypography(),
        spacing: ChatSpacing(),
        animations: ChatAnimationPresets(),
        platform: PlatformThemeVariants(),
        primaryActionColor: Colors.blue,
      );

      final copiedTheme = originalTheme.copyWith(
        primaryActionColor: Colors.red,
      );

      expect(copiedTheme.primaryActionColor, Colors.red);
      expect(copiedTheme.typography, originalTheme.typography);
      expect(copiedTheme.spacing, originalTheme.spacing);
    });

    test('should support lerp functionality', () {
      const theme1 = AdvancedChatTheme(
        typography: ChatTypography(),
        spacing: ChatSpacing(),
        animations: ChatAnimationPresets(),
        platform: PlatformThemeVariants(),
        primaryActionColor: Colors.blue,
      );

      const theme2 = AdvancedChatTheme(
        typography: ChatTypography(),
        spacing: ChatSpacing(),
        animations: ChatAnimationPresets(),
        platform: PlatformThemeVariants(),
        primaryActionColor: Colors.red,
      );

      final lerpedTheme = theme1.lerp(theme2, 0.5);

      expect(lerpedTheme, isA<AdvancedChatTheme>());
      expect(lerpedTheme.primaryActionColor, isNot(equals(Colors.blue)));
      expect(lerpedTheme.primaryActionColor, isNot(equals(Colors.red)));
    });

    test('should have 50+ configurable properties', () {
      const theme = AdvancedChatTheme(
        typography: ChatTypography(),
        spacing: ChatSpacing(),
        animations: ChatAnimationPresets(),
        platform: PlatformThemeVariants(),
      );

      // Count major theme properties
      final properties = [
        // Background gradient system (4 properties)
        theme.backgroundGradient,
        theme.backgroundGradientBegin,
        theme.backgroundGradientEnd,
        theme.backgroundGradientStops,

        // Message gradients (4 properties)
        theme.messageBubbleGradient,
        theme.userBubbleGradient,
        theme.aiResponseGradient,
        theme.systemMessageGradient,

        // Gradient alignments (4 properties)
        theme.messageBubbleGradientBegin,
        theme.messageBubbleGradientEnd,
        theme.userBubbleGradientBegin,
        theme.userBubbleGradientEnd,

        // Core systems (4 properties)
        theme.typography,
        theme.spacing,
        theme.animations,
        theme.platform,

        // Shadows (4 properties)
        theme.messageBubbleShadows,
        theme.userBubbleShadows,
        theme.inputFieldShadows,
        theme.floatingActionShadows,

        // Border radius (4 properties)
        theme.messageBubbleBorderRadius,
        theme.userBubbleBorderRadius,
        theme.inputFieldBorderRadius,
        theme.attachmentBorderRadius,

        // Interactive states (4 properties)
        theme.pressedStateColor,
        theme.hoveredStateColor,
        theme.focusedStateColor,
        theme.disabledStateColor,

        // Status indicators (5 properties)
        theme.sendingStatusColor,
        theme.sentStatusColor,
        theme.deliveredStatusColor,
        theme.readStatusColor,
        theme.errorStatusColor,

        // Input field theming (6 properties)
        theme.inputFieldGradient,
        theme.inputFieldBorderColor,
        theme.inputFieldFocusedBorderColor,
        theme.inputFieldErrorBorderColor,
        theme.inputFieldBorderWidth,
        theme.inputFieldFocusedBorderWidth,

        // Loading states (5 properties)
        theme.streamingIndicatorColor,
        theme.typingIndicatorColor,
        theme.loadingShimmerGradient,
        theme.skeletonColor,
        theme.skeletonHighlightColor,

        // Accessibility (4 properties)
        theme.highContrastBorderColor,
        theme.highContrastBackgroundColor,
        theme.selectionColor,
        theme.selectionHandleColor,

        // Metadata (3 properties)
        theme.timestampColor,
        theme.messageMetadataColor,
        theme.messageCounterColor,

        // Action buttons (4 properties)
        theme.primaryActionColor,
        theme.secondaryActionColor,
        theme.destructiveActionColor,
        theme.favoriteActionColor,
      ];

      // Should have 50+ major configurable properties
      expect(properties.length, greaterThanOrEqualTo(50));
    });
  });

  group('ChatTypography', () {
    test('should have comprehensive text styles', () {
      const typography = ChatTypography();

      // Verify all text styles are defined
      expect(typography.displayLarge, isA<TextStyle>());
      expect(typography.messageBody, isA<TextStyle>());
      expect(typography.userMessageBody, isA<TextStyle>());
      expect(typography.aiResponseBody, isA<TextStyle>());
      expect(typography.timestamp, isA<TextStyle>());
      expect(typography.inputText, isA<TextStyle>());
      expect(typography.codeBlock, isA<TextStyle>());
      expect(typography.inlineCode, isA<TextStyle>());
    });

    test('should support scaling', () {
      const typography = ChatTypography();
      final scaledTypography = typography.scale(1.5);

      expect(
        scaledTypography.messageBody.fontSize!,
        greaterThan(typography.messageBody.fontSize!),
      );
    });
  });

  group('ChatSpacing', () {
    test('should have consistent spacing system', () {
      const spacing = ChatSpacing();

      expect(spacing.xs, lessThan(spacing.sm));
      expect(spacing.sm, lessThan(spacing.md));
      expect(spacing.md, lessThan(spacing.lg));
      expect(spacing.lg, lessThan(spacing.xl));
      expect(spacing.xl, lessThan(spacing.xxl));
      expect(spacing.xxl, lessThan(spacing.xxxl));
    });

    test('should support scaling', () {
      const spacing = ChatSpacing();
      final scaledSpacing = spacing.scale(2.0);

      expect(scaledSpacing.md, equals(spacing.md * 2.0));
      expect(scaledSpacing.lg, equals(spacing.lg * 2.0));
    });
  });

  group('ChatAnimationPresets', () {
    test('should have reasonable animation durations', () {
      const animations = ChatAnimationPresets();

      expect(animations.microInteraction.inMilliseconds, lessThan(300));
      expect(animations.quickTransition.inMilliseconds, lessThan(400));
      expect(animations.messageSlideIn.inMilliseconds, lessThan(500));
    });

    test('should support scaling', () {
      const animations = ChatAnimationPresets();
      final scaledAnimations = animations.scale(0.5);

      expect(
        scaledAnimations.microInteraction.inMilliseconds,
        lessThan(animations.microInteraction.inMilliseconds),
      );
    });
  });

  group('PlatformThemeVariants', () {
    test('should have platform-specific configurations', () {
      const variants = PlatformThemeVariants();

      expect(variants.ios, isA<IOSThemeVariant>());
      expect(variants.android, isA<AndroidThemeVariant>());
      expect(variants.web, isA<WebThemeVariant>());
      expect(variants.desktop, isA<DesktopThemeVariant>());
    });

    test('should have different scroll physics per platform', () {
      const variants = PlatformThemeVariants();

      expect(variants.ios.scrollPhysics, isA<BouncingScrollPhysics>());
      expect(variants.android.scrollPhysics, isA<ClampingScrollPhysics>());
    });
  });
}
