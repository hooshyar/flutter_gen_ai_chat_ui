import 'package:flutter/material.dart';

/// Professional typography system for chat UI with 12+ carefully crafted text styles
@immutable
class ChatTypography {
  /// Display text styles
  final TextStyle displayLarge;
  final TextStyle displayMedium;
  final TextStyle displaySmall;

  /// Headline text styles
  final TextStyle headlineLarge;
  final TextStyle headlineMedium;
  final TextStyle headlineSmall;

  /// Title text styles
  final TextStyle titleLarge;
  final TextStyle titleMedium;
  final TextStyle titleSmall;

  /// Body text styles
  final TextStyle bodyLarge;
  final TextStyle bodyMedium;
  final TextStyle bodySmall;

  /// Label text styles
  final TextStyle labelLarge;
  final TextStyle labelMedium;
  final TextStyle labelSmall;

  /// Chat-specific text styles
  final TextStyle messageBody;
  final TextStyle userMessageBody;
  final TextStyle aiResponseBody;
  final TextStyle systemMessageBody;
  final TextStyle timestamp;
  final TextStyle messageMetadata;
  final TextStyle inputPlaceholder;
  final TextStyle inputText;
  final TextStyle buttonText;
  final TextStyle errorText;
  final TextStyle codeBlock;
  final TextStyle inlineCode;

  const ChatTypography({
    // Display styles
    this.displayLarge = const TextStyle(
      fontSize: 57,
      fontWeight: FontWeight.w400,
      height: 1.12,
      letterSpacing: -0.25,
    ),
    this.displayMedium = const TextStyle(
      fontSize: 45,
      fontWeight: FontWeight.w400,
      height: 1.16,
      letterSpacing: 0,
    ),
    this.displaySmall = const TextStyle(
      fontSize: 36,
      fontWeight: FontWeight.w400,
      height: 1.22,
      letterSpacing: 0,
    ),

    // Headline styles
    this.headlineLarge = const TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w400,
      height: 1.25,
      letterSpacing: 0,
    ),
    this.headlineMedium = const TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w400,
      height: 1.29,
      letterSpacing: 0,
    ),
    this.headlineSmall = const TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w400,
      height: 1.33,
      letterSpacing: 0,
    ),

    // Title styles
    this.titleLarge = const TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w400,
      height: 1.27,
      letterSpacing: 0,
    ),
    this.titleMedium = const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      height: 1.50,
      letterSpacing: 0.15,
    ),
    this.titleSmall = const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 1.43,
      letterSpacing: 0.1,
    ),

    // Body styles
    this.bodyLarge = const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.50,
      letterSpacing: 0.5,
    ),
    this.bodyMedium = const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.43,
      letterSpacing: 0.25,
    ),
    this.bodySmall = const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.33,
      letterSpacing: 0.4,
    ),

    // Label styles
    this.labelLarge = const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 1.43,
      letterSpacing: 0.1,
    ),
    this.labelMedium = const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 1.33,
      letterSpacing: 0.5,
    ),
    this.labelSmall = const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      height: 1.45,
      letterSpacing: 0.5,
    ),

    // Chat-specific styles
    this.messageBody = const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.5,
      letterSpacing: 0,
    ),
    this.userMessageBody = const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.5,
      letterSpacing: 0,
    ),
    this.aiResponseBody = const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.5,
      letterSpacing: 0,
    ),
    this.systemMessageBody = const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 1.43,
      letterSpacing: 0.1,
    ),
    this.timestamp = const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.33,
      letterSpacing: 0.4,
    ),
    this.messageMetadata = const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w400,
      height: 1.45,
      letterSpacing: 0.5,
    ),
    this.inputPlaceholder = const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.5,
      letterSpacing: 0,
    ),
    this.inputText = const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.5,
      letterSpacing: 0,
    ),
    this.buttonText = const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 1.43,
      letterSpacing: 0.1,
    ),
    this.errorText = const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.33,
      letterSpacing: 0.4,
    ),
    this.codeBlock = const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.43,
      letterSpacing: 0,
      fontFamily: 'monospace',
    ),
    this.inlineCode = const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.43,
      letterSpacing: 0,
      fontFamily: 'monospace',
    ),
  });

  /// Create typography for different screen sizes
  ChatTypography copyWith({
    TextStyle? displayLarge,
    TextStyle? displayMedium,
    TextStyle? displaySmall,
    TextStyle? headlineLarge,
    TextStyle? headlineMedium,
    TextStyle? headlineSmall,
    TextStyle? titleLarge,
    TextStyle? titleMedium,
    TextStyle? titleSmall,
    TextStyle? bodyLarge,
    TextStyle? bodyMedium,
    TextStyle? bodySmall,
    TextStyle? labelLarge,
    TextStyle? labelMedium,
    TextStyle? labelSmall,
    TextStyle? messageBody,
    TextStyle? userMessageBody,
    TextStyle? aiResponseBody,
    TextStyle? systemMessageBody,
    TextStyle? timestamp,
    TextStyle? messageMetadata,
    TextStyle? inputPlaceholder,
    TextStyle? inputText,
    TextStyle? buttonText,
    TextStyle? errorText,
    TextStyle? codeBlock,
    TextStyle? inlineCode,
  }) {
    return ChatTypography(
      displayLarge: displayLarge ?? this.displayLarge,
      displayMedium: displayMedium ?? this.displayMedium,
      displaySmall: displaySmall ?? this.displaySmall,
      headlineLarge: headlineLarge ?? this.headlineLarge,
      headlineMedium: headlineMedium ?? this.headlineMedium,
      headlineSmall: headlineSmall ?? this.headlineSmall,
      titleLarge: titleLarge ?? this.titleLarge,
      titleMedium: titleMedium ?? this.titleMedium,
      titleSmall: titleSmall ?? this.titleSmall,
      bodyLarge: bodyLarge ?? this.bodyLarge,
      bodyMedium: bodyMedium ?? this.bodyMedium,
      bodySmall: bodySmall ?? this.bodySmall,
      labelLarge: labelLarge ?? this.labelLarge,
      labelMedium: labelMedium ?? this.labelMedium,
      labelSmall: labelSmall ?? this.labelSmall,
      messageBody: messageBody ?? this.messageBody,
      userMessageBody: userMessageBody ?? this.userMessageBody,
      aiResponseBody: aiResponseBody ?? this.aiResponseBody,
      systemMessageBody: systemMessageBody ?? this.systemMessageBody,
      timestamp: timestamp ?? this.timestamp,
      messageMetadata: messageMetadata ?? this.messageMetadata,
      inputPlaceholder: inputPlaceholder ?? this.inputPlaceholder,
      inputText: inputText ?? this.inputText,
      buttonText: buttonText ?? this.buttonText,
      errorText: errorText ?? this.errorText,
      codeBlock: codeBlock ?? this.codeBlock,
      inlineCode: inlineCode ?? this.inlineCode,
    );
  }

  /// Create typography scaled for different screen sizes
  ChatTypography scale(double scaleFactor) {
    return ChatTypography(
      displayLarge: _scaleTextStyle(displayLarge, scaleFactor),
      displayMedium: _scaleTextStyle(displayMedium, scaleFactor),
      displaySmall: _scaleTextStyle(displaySmall, scaleFactor),
      headlineLarge: _scaleTextStyle(headlineLarge, scaleFactor),
      headlineMedium: _scaleTextStyle(headlineMedium, scaleFactor),
      headlineSmall: _scaleTextStyle(headlineSmall, scaleFactor),
      titleLarge: _scaleTextStyle(titleLarge, scaleFactor),
      titleMedium: _scaleTextStyle(titleMedium, scaleFactor),
      titleSmall: _scaleTextStyle(titleSmall, scaleFactor),
      bodyLarge: _scaleTextStyle(bodyLarge, scaleFactor),
      bodyMedium: _scaleTextStyle(bodyMedium, scaleFactor),
      bodySmall: _scaleTextStyle(bodySmall, scaleFactor),
      labelLarge: _scaleTextStyle(labelLarge, scaleFactor),
      labelMedium: _scaleTextStyle(labelMedium, scaleFactor),
      labelSmall: _scaleTextStyle(labelSmall, scaleFactor),
      messageBody: _scaleTextStyle(messageBody, scaleFactor),
      userMessageBody: _scaleTextStyle(userMessageBody, scaleFactor),
      aiResponseBody: _scaleTextStyle(aiResponseBody, scaleFactor),
      systemMessageBody: _scaleTextStyle(systemMessageBody, scaleFactor),
      timestamp: _scaleTextStyle(timestamp, scaleFactor),
      messageMetadata: _scaleTextStyle(messageMetadata, scaleFactor),
      inputPlaceholder: _scaleTextStyle(inputPlaceholder, scaleFactor),
      inputText: _scaleTextStyle(inputText, scaleFactor),
      buttonText: _scaleTextStyle(buttonText, scaleFactor),
      errorText: _scaleTextStyle(errorText, scaleFactor),
      codeBlock: _scaleTextStyle(codeBlock, scaleFactor),
      inlineCode: _scaleTextStyle(inlineCode, scaleFactor),
    );
  }

  TextStyle _scaleTextStyle(TextStyle style, double scaleFactor) {
    return style.copyWith(fontSize: (style.fontSize ?? 14) * scaleFactor);
  }

  /// Lerp between two typography instances
  ChatTypography lerp(ChatTypography other, double t) {
    return ChatTypography(
      displayLarge:
          TextStyle.lerp(displayLarge, other.displayLarge, t) ?? displayLarge,
      displayMedium: TextStyle.lerp(displayMedium, other.displayMedium, t) ??
          displayMedium,
      displaySmall:
          TextStyle.lerp(displaySmall, other.displaySmall, t) ?? displaySmall,
      headlineLarge: TextStyle.lerp(headlineLarge, other.headlineLarge, t) ??
          headlineLarge,
      headlineMedium: TextStyle.lerp(headlineMedium, other.headlineMedium, t) ??
          headlineMedium,
      headlineSmall: TextStyle.lerp(headlineSmall, other.headlineSmall, t) ??
          headlineSmall,
      titleLarge: TextStyle.lerp(titleLarge, other.titleLarge, t) ?? titleLarge,
      titleMedium:
          TextStyle.lerp(titleMedium, other.titleMedium, t) ?? titleMedium,
      titleSmall: TextStyle.lerp(titleSmall, other.titleSmall, t) ?? titleSmall,
      bodyLarge: TextStyle.lerp(bodyLarge, other.bodyLarge, t) ?? bodyLarge,
      bodyMedium: TextStyle.lerp(bodyMedium, other.bodyMedium, t) ?? bodyMedium,
      bodySmall: TextStyle.lerp(bodySmall, other.bodySmall, t) ?? bodySmall,
      labelLarge: TextStyle.lerp(labelLarge, other.labelLarge, t) ?? labelLarge,
      labelMedium:
          TextStyle.lerp(labelMedium, other.labelMedium, t) ?? labelMedium,
      labelSmall: TextStyle.lerp(labelSmall, other.labelSmall, t) ?? labelSmall,
      messageBody:
          TextStyle.lerp(messageBody, other.messageBody, t) ?? messageBody,
      userMessageBody:
          TextStyle.lerp(userMessageBody, other.userMessageBody, t) ??
              userMessageBody,
      aiResponseBody: TextStyle.lerp(aiResponseBody, other.aiResponseBody, t) ??
          aiResponseBody,
      systemMessageBody:
          TextStyle.lerp(systemMessageBody, other.systemMessageBody, t) ??
              systemMessageBody,
      timestamp: TextStyle.lerp(timestamp, other.timestamp, t) ?? timestamp,
      messageMetadata:
          TextStyle.lerp(messageMetadata, other.messageMetadata, t) ??
              messageMetadata,
      inputPlaceholder:
          TextStyle.lerp(inputPlaceholder, other.inputPlaceholder, t) ??
              inputPlaceholder,
      inputText: TextStyle.lerp(inputText, other.inputText, t) ?? inputText,
      buttonText: TextStyle.lerp(buttonText, other.buttonText, t) ?? buttonText,
      errorText: TextStyle.lerp(errorText, other.errorText, t) ?? errorText,
      codeBlock: TextStyle.lerp(codeBlock, other.codeBlock, t) ?? codeBlock,
      inlineCode: TextStyle.lerp(inlineCode, other.inlineCode, t) ?? inlineCode,
    );
  }

  /// Predefined typography variants
  static const ChatTypography mobile = ChatTypography();

  static final ChatTypography tablet = const ChatTypography().scale(1.1);

  static final ChatTypography desktop = const ChatTypography().scale(1.2);

  static const ChatTypography compact = ChatTypography(
    messageBody: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.4,
      letterSpacing: 0,
    ),
    timestamp: TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w400,
      height: 1.3,
      letterSpacing: 0.4,
    ),
  );

  static const ChatTypography accessible = ChatTypography(
    messageBody: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w400,
      height: 1.6,
      letterSpacing: 0.5,
    ),
    timestamp: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 1.4,
      letterSpacing: 0.5,
    ),
  );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ChatTypography &&
            displayLarge == other.displayLarge &&
            displayMedium == other.displayMedium &&
            displaySmall == other.displaySmall &&
            messageBody == other.messageBody &&
            userMessageBody == other.userMessageBody &&
            aiResponseBody == other.aiResponseBody &&
            timestamp == other.timestamp &&
            inputText == other.inputText);
  }

  @override
  int get hashCode {
    return Object.hash(
      displayLarge,
      displayMedium,
      displaySmall,
      messageBody,
      userMessageBody,
      aiResponseBody,
      timestamp,
      inputText,
    );
  }
}
