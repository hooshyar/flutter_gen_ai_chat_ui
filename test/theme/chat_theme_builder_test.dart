import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen_ai_chat_ui/src/theme/chat_theme_builder.dart';
import 'package:flutter_gen_ai_chat_ui/src/theme/advanced_chat_theme.dart';

void main() {
  group('ChatThemeBuilder', () {
    test('should create theme from brand colors', () {
      final theme = ChatThemeBuilder.fromBrand(
        primaryColor: Colors.blue,
        secondaryColor: Colors.green,
      ).build();

      expect(theme, isA<AdvancedChatTheme>());
      expect(theme.primaryActionColor, Colors.blue);
      expect(theme.secondaryActionColor, Colors.green);
      expect(theme.userBubbleGradient, contains(Colors.blue));
    });

    test('should create minimal theme', () {
      final lightTheme =
          ChatThemeBuilder.minimal(brightness: Brightness.light).build();

      final darkTheme =
          ChatThemeBuilder.minimal(brightness: Brightness.dark).build();

      expect(lightTheme, isA<AdvancedChatTheme>());
      expect(darkTheme, isA<AdvancedChatTheme>());
      expect(
        lightTheme.backgroundGradient.first.value,
        isNot(equals(darkTheme.backgroundGradient.first.value)),
      );
    });

    test('should create glassmorphic theme', () {
      final theme = ChatThemeBuilder.glassmorphic().build();

      expect(theme, isA<AdvancedChatTheme>());
      // Glassmorphic themes should have semi-transparent colors
      expect(theme.messageBubbleGradient.first.alpha, lessThan(255));
    });

    test('should create accessible theme', () {
      final theme = ChatThemeBuilder.accessible().build();

      expect(theme, isA<AdvancedChatTheme>());
      expect(theme.inputFieldBorderWidth, greaterThan(1.0));
      expect(theme.inputFieldFocusedBorderWidth, greaterThan(2.0));
    });

    test('should support fluent API with method chaining', () {
      final theme = ChatThemeBuilder.fromBrand(
        primaryColor: Colors.red,
        secondaryColor: Colors.orange,
      )
          .withBackgroundGradient([Colors.white, Colors.grey.shade100])
          .withMessageBubbleGradient([
            Colors.grey.shade200,
            Colors.grey.shade100,
          ])
          .withBorderRadius(
            messageBubbleBorderRadius: const BorderRadius.all(
              Radius.circular(20),
            ),
          )
          .build();

      expect(theme, isA<AdvancedChatTheme>());
      expect(theme.primaryActionColor, Colors.red);
      expect(theme.backgroundGradient, contains(Colors.white));
      expect(
        theme.messageBubbleBorderRadius,
        const BorderRadius.all(Radius.circular(20)),
      );
    });

    test('should create ChatGPT-style preset', () {
      final theme = ChatThemeBuilder.chatGptStyle();

      expect(theme, isA<AdvancedChatTheme>());
      expect(theme.primaryActionColor, const Color(0xFF10A37F));
    });

    test('should create Claude-style preset', () {
      final theme = ChatThemeBuilder.claudeStyle();

      expect(theme, isA<AdvancedChatTheme>());
      expect(theme.primaryActionColor, const Color(0xFFCC785C));
    });

    test('should create Gemini-style preset', () {
      final theme = ChatThemeBuilder.geminiStyle();

      expect(theme, isA<AdvancedChatTheme>());
      expect(theme.primaryActionColor, const Color(0xFF4285F4));
    });

    test('should preserve existing properties when using copyWith', () {
      final originalTheme = ChatThemeBuilder.fromBrand(
        primaryColor: Colors.blue,
        secondaryColor: Colors.green,
      ).build();

      final modifiedTheme = originalTheme.copyWith(
        primaryActionColor: Colors.red,
      );

      expect(modifiedTheme.primaryActionColor, Colors.red);
      expect(
        modifiedTheme.secondaryActionColor,
        originalTheme.secondaryActionColor,
      );
      expect(modifiedTheme.typography, originalTheme.typography);
    });
  });
}
