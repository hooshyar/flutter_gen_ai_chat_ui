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
