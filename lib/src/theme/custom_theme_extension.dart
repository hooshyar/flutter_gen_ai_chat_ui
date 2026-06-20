import 'package:flutter/material.dart';

/// Immutable theme extension that stores chat UI color tokens and layout properties.
@immutable
class CustomThemeExtension extends ThemeExtension<CustomThemeExtension> {
  final Color? chatBackground;
  final Color? messageBubbleColor;
  final Color? userBubbleColor;
  final Color? messageTextColor;
  final Color? inputBackgroundColor;
  final Color? inputBorderColor;
  final Color? inputTextColor;
  final Color? hintTextColor;
  final Color? backToBottomButtonColor;
  final Color? sendButtonColor;
  final Color? sendButtonIconColor;

  const CustomThemeExtension({
    this.chatBackground,
    this.messageBubbleColor,
    this.userBubbleColor,
    this.messageTextColor,
    this.inputBackgroundColor,
    this.inputBorderColor,
    this.inputTextColor,
    this.hintTextColor,
    this.backToBottomButtonColor,
    this.sendButtonColor,
    this.sendButtonIconColor,
  });

  @override
  CustomThemeExtension copyWith({
    Color? chatBackground,
    Color? messageBubbleColor,
    Color? userBubbleColor,
    Color? messageTextColor,
    Color? inputBackgroundColor,
    Color? inputBorderColor,
    Color? inputTextColor,
    Color? hintTextColor,
    Color? backToBottomButtonColor,
    Color? sendButtonColor,
    Color? sendButtonIconColor,
  }) {
    return CustomThemeExtension(
      chatBackground: chatBackground ?? this.chatBackground,
      messageBubbleColor: messageBubbleColor ?? this.messageBubbleColor,
      userBubbleColor: userBubbleColor ?? this.userBubbleColor,
      messageTextColor: messageTextColor ?? this.messageTextColor,
      inputBackgroundColor: inputBackgroundColor ?? this.inputBackgroundColor,
      inputBorderColor: inputBorderColor ?? this.inputBorderColor,
      inputTextColor: inputTextColor ?? this.inputTextColor,
      hintTextColor: hintTextColor ?? this.hintTextColor,
      backToBottomButtonColor:
          backToBottomButtonColor ?? this.backToBottomButtonColor,
      sendButtonColor: sendButtonColor ?? this.sendButtonColor,
      sendButtonIconColor: sendButtonIconColor ?? this.sendButtonIconColor,
    );
  }

  @override
  CustomThemeExtension lerp(
      ThemeExtension<CustomThemeExtension>? other, double t) {
    if (other is! CustomThemeExtension) return this;
    return CustomThemeExtension(
      chatBackground: Color.lerp(chatBackground, other.chatBackground, t),
      messageBubbleColor:
          Color.lerp(messageBubbleColor, other.messageBubbleColor, t),
      userBubbleColor: Color.lerp(userBubbleColor, other.userBubbleColor, t),
      messageTextColor: Color.lerp(messageTextColor, other.messageTextColor, t),
      inputBackgroundColor:
          Color.lerp(inputBackgroundColor, other.inputBackgroundColor, t),
      inputBorderColor: Color.lerp(inputBorderColor, other.inputBorderColor, t),
      inputTextColor: Color.lerp(inputTextColor, other.inputTextColor, t),
      hintTextColor: Color.lerp(hintTextColor, other.hintTextColor, t),
      backToBottomButtonColor:
          Color.lerp(backToBottomButtonColor, other.backToBottomButtonColor, t),
      sendButtonColor: Color.lerp(sendButtonColor, other.sendButtonColor, t),
      sendButtonIconColor:
          Color.lerp(sendButtonIconColor, other.sendButtonIconColor, t),
    );
  }

  // ---- Minimal presets building upon ColorScheme to avoid bloat ----

  static CustomThemeExtension modern(ColorScheme scheme) =>
      CustomThemeExtension(
        chatBackground: scheme.surface,
        messageBubbleColor: scheme.surfaceContainerLow,
        userBubbleColor: scheme.primaryContainer,
        messageTextColor: scheme.onSurface,
        inputBackgroundColor: scheme.surfaceContainerHighest,
        inputBorderColor: scheme.outlineVariant,
        inputTextColor: scheme.onSurface,
        hintTextColor: scheme.onSurfaceVariant,
        backToBottomButtonColor: scheme.secondary,
        sendButtonColor: scheme.primary,
        sendButtonIconColor: scheme.onPrimary,
      );

  static CustomThemeExtension minimal(ColorScheme scheme) =>
      CustomThemeExtension(
        chatBackground: scheme.surface,
        messageBubbleColor: scheme.surface,
        userBubbleColor: scheme.surface,
        messageTextColor: scheme.onSurface,
        inputBackgroundColor: scheme.surface,
        inputBorderColor: scheme.outlineVariant,
        inputTextColor: scheme.onSurface,
        hintTextColor: scheme.onSurfaceVariant,
        backToBottomButtonColor: scheme.secondary,
        sendButtonColor: scheme.primary,
        sendButtonIconColor: scheme.onPrimary,
      );

  // ---- Brand presets ----
  //
  // One-liner themes that approximate popular AI chat UIs. Apply via:
  //   MaterialApp(theme: ThemeData(extensions: [CustomThemeExtension.chatgpt()]))
  // Colors are deliberately fixed (not derived from ColorScheme) so the look
  // matches the brand regardless of the host app's seed color.

  /// ChatGPT-style theme (neutral greys, green accent).
  static CustomThemeExtension chatgpt({bool dark = false}) => dark
      ? const CustomThemeExtension(
          chatBackground: Color(0xFF212121),
          messageBubbleColor: Color(0xFF2F2F2F),
          userBubbleColor: Color(0xFF303030),
          messageTextColor: Color(0xFFECECEC),
          inputBackgroundColor: Color(0xFF2F2F2F),
          inputBorderColor: Color(0xFF4D4D4F),
          inputTextColor: Color(0xFFECECEC),
          hintTextColor: Color(0xFF8E8EA0),
          backToBottomButtonColor: Color(0xFF19C37D),
          sendButtonColor: Color(0xFF19C37D),
          sendButtonIconColor: Color(0xFFFFFFFF),
        )
      : const CustomThemeExtension(
          chatBackground: Color(0xFFFFFFFF),
          messageBubbleColor: Color(0xFFF7F7F8),
          userBubbleColor: Color(0xFFECECEC),
          messageTextColor: Color(0xFF0D0D0D),
          inputBackgroundColor: Color(0xFFFFFFFF),
          inputBorderColor: Color(0xFFD9D9E3),
          inputTextColor: Color(0xFF0D0D0D),
          hintTextColor: Color(0xFF8E8EA0),
          backToBottomButtonColor: Color(0xFF10A37F),
          sendButtonColor: Color(0xFF10A37F),
          sendButtonIconColor: Color(0xFFFFFFFF),
        );

  /// Claude-style theme (warm cream surfaces, coral accent).
  static CustomThemeExtension claude({bool dark = false}) => dark
      ? const CustomThemeExtension(
          chatBackground: Color(0xFF262624),
          messageBubbleColor: Color(0xFF2D2C2A),
          userBubbleColor: Color(0xFF393834),
          messageTextColor: Color(0xFFF5F4EE),
          inputBackgroundColor: Color(0xFF2D2C2A),
          inputBorderColor: Color(0xFF4A4843),
          inputTextColor: Color(0xFFF5F4EE),
          hintTextColor: Color(0xFFA8A39A),
          backToBottomButtonColor: Color(0xFFD97757),
          sendButtonColor: Color(0xFFD97757),
          sendButtonIconColor: Color(0xFFFFFFFF),
        )
      : const CustomThemeExtension(
          chatBackground: Color(0xFFFFFFFF),
          messageBubbleColor: Color(0xFFF9F9F7),
          userBubbleColor: Color(0xFFF0EEE6),
          messageTextColor: Color(0xFF1F1E1D),
          inputBackgroundColor: Color(0xFFFFFFFF),
          inputBorderColor: Color(0xFFE3E1D9),
          inputTextColor: Color(0xFF1F1E1D),
          hintTextColor: Color(0xFF8C887F),
          backToBottomButtonColor: Color(0xFFD97757),
          sendButtonColor: Color(0xFFD97757),
          sendButtonIconColor: Color(0xFFFFFFFF),
        );

  /// Gemini-style theme (cool blues, soft surfaces).
  static CustomThemeExtension gemini({bool dark = false}) => dark
      ? const CustomThemeExtension(
          chatBackground: Color(0xFF1B1C1D),
          messageBubbleColor: Color(0xFF1E1F20),
          userBubbleColor: Color(0xFF2D2F31),
          messageTextColor: Color(0xFFE3E3E3),
          inputBackgroundColor: Color(0xFF1E1F20),
          inputBorderColor: Color(0xFF444746),
          inputTextColor: Color(0xFFE3E3E3),
          hintTextColor: Color(0xFF9AA0A6),
          backToBottomButtonColor: Color(0xFF8AB4F8),
          sendButtonColor: Color(0xFF8AB4F8),
          sendButtonIconColor: Color(0xFF1B1C1D),
        )
      : const CustomThemeExtension(
          chatBackground: Color(0xFFFFFFFF),
          messageBubbleColor: Color(0xFFF0F4F9),
          userBubbleColor: Color(0xFFD3E3FD),
          messageTextColor: Color(0xFF1F1F1F),
          inputBackgroundColor: Color(0xFFF0F4F9),
          inputBorderColor: Color(0xFFC4C7C5),
          inputTextColor: Color(0xFF1F1F1F),
          hintTextColor: Color(0xFF5F6368),
          backToBottomButtonColor: Color(0xFF1A73E8),
          sendButtonColor: Color(0xFF1A73E8),
          sendButtonIconColor: Color(0xFFFFFFFF),
        );

  // Merge helper to attach extension to an existing ThemeData
  static ThemeData withCustomTheme(ThemeData base, CustomThemeExtension ext) {
    // ThemeData.extensions is a Map<Type, ThemeExtension>. Overwriting a key
    // replaces the extension for that type. To allow multiple variants, apps
    // should consolidate into a single extension via copyWith.
    final map = Map<Type, ThemeExtension<dynamic>>.from(base.extensions);
    final current = map[CustomThemeExtension] as CustomThemeExtension?;
    map[CustomThemeExtension] = current == null
        ? ext
        : current.copyWith(
            chatBackground: ext.chatBackground ?? current.chatBackground,
            messageBubbleColor:
                ext.messageBubbleColor ?? current.messageBubbleColor,
            userBubbleColor: ext.userBubbleColor ?? current.userBubbleColor,
            messageTextColor: ext.messageTextColor ?? current.messageTextColor,
            inputBackgroundColor:
                ext.inputBackgroundColor ?? current.inputBackgroundColor,
            inputBorderColor: ext.inputBorderColor ?? current.inputBorderColor,
            inputTextColor: ext.inputTextColor ?? current.inputTextColor,
            hintTextColor: ext.hintTextColor ?? current.hintTextColor,
            backToBottomButtonColor:
                ext.backToBottomButtonColor ?? current.backToBottomButtonColor,
            sendButtonColor: ext.sendButtonColor ?? current.sendButtonColor,
            sendButtonIconColor:
                ext.sendButtonIconColor ?? current.sendButtonIconColor,
          );
    return base.copyWith(extensions: map.values.toList());
  }
}
