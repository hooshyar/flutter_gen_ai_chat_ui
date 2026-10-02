import 'dart:ui';

import 'package:flutter/material.dart';

/// Professional spacing system for consistent layout and visual hierarchy
@immutable
class ChatSpacing {
  /// Extra small spacing (2px)
  final double xs;

  /// Small spacing (4px)
  final double sm;

  /// Medium spacing (8px)
  final double md;

  /// Large spacing (12px)
  final double lg;

  /// Extra large spacing (16px)
  final double xl;

  /// Double extra large spacing (24px)
  final double xxl;

  /// Triple extra large spacing (32px)
  final double xxxl;

  /// Message bubble padding
  final EdgeInsets messageBubblePadding;

  /// User bubble padding
  final EdgeInsets userBubblePadding;

  /// Input field padding
  final EdgeInsets inputFieldPadding;

  /// Container padding
  final EdgeInsets containerPadding;

  /// Screen margin
  final EdgeInsets screenMargin;

  /// Message spacing (vertical gap between messages)
  final double messageSpacing;

  /// Message group spacing (gap between message groups)
  final double messageGroupSpacing;

  /// Icon spacing
  final double iconSpacing;

  /// Button spacing
  final double buttonSpacing;

  /// Attachment spacing
  final double attachmentSpacing;

  const ChatSpacing({
    this.xs = 2.0,
    this.sm = 4.0,
    this.md = 8.0,
    this.lg = 12.0,
    this.xl = 16.0,
    this.xxl = 24.0,
    this.xxxl = 32.0,
    this.messageBubblePadding = const EdgeInsets.symmetric(
      horizontal: 16.0,
      vertical: 12.0,
    ),
    this.userBubblePadding = const EdgeInsets.symmetric(
      horizontal: 16.0,
      vertical: 12.0,
    ),
    this.inputFieldPadding = const EdgeInsets.symmetric(
      horizontal: 16.0,
      vertical: 12.0,
    ),
    this.containerPadding = const EdgeInsets.all(16.0),
    this.screenMargin = const EdgeInsets.symmetric(horizontal: 16.0),
    this.messageSpacing = 8.0,
    this.messageGroupSpacing = 16.0,
    this.iconSpacing = 8.0,
    this.buttonSpacing = 12.0,
    this.attachmentSpacing = 8.0,
  });

  /// Create a copy with different values
  ChatSpacing copyWith({
    double? xs,
    double? sm,
    double? md,
    double? lg,
    double? xl,
    double? xxl,
    double? xxxl,
    EdgeInsets? messageBubblePadding,
    EdgeInsets? userBubblePadding,
    EdgeInsets? inputFieldPadding,
    EdgeInsets? containerPadding,
    EdgeInsets? screenMargin,
    double? messageSpacing,
    double? messageGroupSpacing,
    double? iconSpacing,
    double? buttonSpacing,
    double? attachmentSpacing,
  }) {
    return ChatSpacing(
      xs: xs ?? this.xs,
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      xl: xl ?? this.xl,
      xxl: xxl ?? this.xxl,
      xxxl: xxxl ?? this.xxxl,
      messageBubblePadding: messageBubblePadding ?? this.messageBubblePadding,
      userBubblePadding: userBubblePadding ?? this.userBubblePadding,
      inputFieldPadding: inputFieldPadding ?? this.inputFieldPadding,
      containerPadding: containerPadding ?? this.containerPadding,
      screenMargin: screenMargin ?? this.screenMargin,
      messageSpacing: messageSpacing ?? this.messageSpacing,
      messageGroupSpacing: messageGroupSpacing ?? this.messageGroupSpacing,
      iconSpacing: iconSpacing ?? this.iconSpacing,
      buttonSpacing: buttonSpacing ?? this.buttonSpacing,
      attachmentSpacing: attachmentSpacing ?? this.attachmentSpacing,
    );
  }

  /// Scale all spacing values by a factor
  ChatSpacing scale(double scaleFactor) {
    return ChatSpacing(
      xs: xs * scaleFactor,
      sm: sm * scaleFactor,
      md: md * scaleFactor,
      lg: lg * scaleFactor,
      xl: xl * scaleFactor,
      xxl: xxl * scaleFactor,
      xxxl: xxxl * scaleFactor,
      messageBubblePadding: EdgeInsets.fromLTRB(
        messageBubblePadding.left * scaleFactor,
        messageBubblePadding.top * scaleFactor,
        messageBubblePadding.right * scaleFactor,
        messageBubblePadding.bottom * scaleFactor,
      ),
      userBubblePadding: EdgeInsets.fromLTRB(
        userBubblePadding.left * scaleFactor,
        userBubblePadding.top * scaleFactor,
        userBubblePadding.right * scaleFactor,
        userBubblePadding.bottom * scaleFactor,
      ),
      inputFieldPadding: EdgeInsets.fromLTRB(
        inputFieldPadding.left * scaleFactor,
        inputFieldPadding.top * scaleFactor,
        inputFieldPadding.right * scaleFactor,
        inputFieldPadding.bottom * scaleFactor,
      ),
      containerPadding: EdgeInsets.fromLTRB(
        containerPadding.left * scaleFactor,
        containerPadding.top * scaleFactor,
        containerPadding.right * scaleFactor,
        containerPadding.bottom * scaleFactor,
      ),
      screenMargin: EdgeInsets.fromLTRB(
        screenMargin.left * scaleFactor,
        screenMargin.top * scaleFactor,
        screenMargin.right * scaleFactor,
        screenMargin.bottom * scaleFactor,
      ),
      messageSpacing: messageSpacing * scaleFactor,
      messageGroupSpacing: messageGroupSpacing * scaleFactor,
      iconSpacing: iconSpacing * scaleFactor,
      buttonSpacing: buttonSpacing * scaleFactor,
      attachmentSpacing: attachmentSpacing * scaleFactor,
    );
  }

  /// Lerp between two spacing instances
  ChatSpacing lerp(ChatSpacing other, double t) {
    return ChatSpacing(
      xs: lerpDouble(xs, other.xs, t) ?? xs,
      sm: lerpDouble(sm, other.sm, t) ?? sm,
      md: lerpDouble(md, other.md, t) ?? md,
      lg: lerpDouble(lg, other.lg, t) ?? lg,
      xl: lerpDouble(xl, other.xl, t) ?? xl,
      xxl: lerpDouble(xxl, other.xxl, t) ?? xxl,
      xxxl: lerpDouble(xxxl, other.xxxl, t) ?? xxxl,
      messageBubblePadding: EdgeInsets.lerp(
            messageBubblePadding,
            other.messageBubblePadding,
            t,
          ) ??
          messageBubblePadding,
      userBubblePadding:
          EdgeInsets.lerp(userBubblePadding, other.userBubblePadding, t) ??
              userBubblePadding,
      inputFieldPadding:
          EdgeInsets.lerp(inputFieldPadding, other.inputFieldPadding, t) ??
              inputFieldPadding,
      containerPadding:
          EdgeInsets.lerp(containerPadding, other.containerPadding, t) ??
              containerPadding,
      screenMargin:
          EdgeInsets.lerp(screenMargin, other.screenMargin, t) ?? screenMargin,
      messageSpacing:
          lerpDouble(messageSpacing, other.messageSpacing, t) ?? messageSpacing,
      messageGroupSpacing:
          lerpDouble(messageGroupSpacing, other.messageGroupSpacing, t) ??
              messageGroupSpacing,
      iconSpacing: lerpDouble(iconSpacing, other.iconSpacing, t) ?? iconSpacing,
      buttonSpacing:
          lerpDouble(buttonSpacing, other.buttonSpacing, t) ?? buttonSpacing,
      attachmentSpacing:
          lerpDouble(attachmentSpacing, other.attachmentSpacing, t) ??
              attachmentSpacing,
    );
  }

  /// Predefined spacing variants
  static const ChatSpacing mobile = ChatSpacing();

  static final ChatSpacing tablet = const ChatSpacing().scale(1.1);

  static final ChatSpacing desktop = const ChatSpacing().scale(1.2);

  static const ChatSpacing compact = ChatSpacing(
    messageBubblePadding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
    messageSpacing: 6.0,
    messageGroupSpacing: 12.0,
  );

  static const ChatSpacing comfortable = ChatSpacing(
    messageBubblePadding: EdgeInsets.symmetric(
      horizontal: 20.0,
      vertical: 16.0,
    ),
    messageSpacing: 12.0,
    messageGroupSpacing: 20.0,
  );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ChatSpacing &&
            xs == other.xs &&
            sm == other.sm &&
            md == other.md &&
            lg == other.lg &&
            xl == other.xl &&
            xxl == other.xxl &&
            xxxl == other.xxxl &&
            messageBubblePadding == other.messageBubblePadding &&
            userBubblePadding == other.userBubblePadding &&
            inputFieldPadding == other.inputFieldPadding &&
            containerPadding == other.containerPadding &&
            screenMargin == other.screenMargin &&
            messageSpacing == other.messageSpacing &&
            messageGroupSpacing == other.messageGroupSpacing);
  }

  @override
  int get hashCode {
    return Object.hash(
      xs,
      sm,
      md,
      lg,
      xl,
      xxl,
      xxxl,
      messageBubblePadding,
      userBubblePadding,
      inputFieldPadding,
      containerPadding,
      screenMargin,
      messageSpacing,
      messageGroupSpacing,
    );
  }
}
