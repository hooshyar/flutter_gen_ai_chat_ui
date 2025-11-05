import 'package:flutter/material.dart';

class ChatSpacingConfig {
  final EdgeInsets messageBubbleOuterPadding;
  final EdgeInsets messageBubbleInnerPadding;
  final EdgeInsets Function(bool isUser) messageBubbleMargin;
  final EdgeInsets messageUsernameBottomPadding;
  final EdgeInsets messageFooterTopPadding;
  final EdgeInsets messageMediaSpacing;
  final EdgeInsets messageListPadding;
  final EdgeInsets loadingWidgetMargin;
  final EdgeInsets loadingWidgetPadding;
  final EdgeInsets typingIndicatorPadding;
  final EdgeInsets typingIndicatorMargin;
  final EdgeInsets quickRepliesPadding;

  const ChatSpacingConfig({
    this.messageBubbleOuterPadding = const EdgeInsets.symmetric(vertical: 4.0),
    this.messageBubbleInnerPadding = const EdgeInsets.symmetric(
      vertical: 14.0,
      horizontal: 16.0,
    ),
    EdgeInsets Function(bool isUser)? messageBubbleMargin,
    this.messageUsernameBottomPadding = const EdgeInsets.only(bottom: 8.0),
    this.messageFooterTopPadding = const EdgeInsets.only(top: 8.0),
    this.messageMediaSpacing = const EdgeInsets.only(bottom: 8.0),
    this.messageListPadding = const EdgeInsets.symmetric(
      horizontal: 16.0,
      vertical: 8.0,
    ),
    this.loadingWidgetMargin = const EdgeInsets.symmetric(
      horizontal: 16.0,
      vertical: 8.0,
    ),
    this.loadingWidgetPadding = const EdgeInsets.symmetric(
      vertical: 10.0,
      horizontal: 16.0,
    ),
    this.typingIndicatorPadding = const EdgeInsets.all(12.0),
    this.typingIndicatorMargin = const EdgeInsets.symmetric(
      horizontal: 16.0,
      vertical: 4.0,
    ),
    this.quickRepliesPadding = const EdgeInsets.symmetric(
      horizontal: 8.0,
      vertical: 4.0,
    ),
  }) : messageBubbleMargin = messageBubbleMargin ?? _defaultMargin;

  static EdgeInsets _defaultMargin(bool isUser) {
    return EdgeInsets.only(
      top: 6.0,
      bottom: 6.0,
      right: isUser ? 16.0 : 64.0,
      left: isUser ? 64.0 : 16.0,
    );
  }

  factory ChatSpacingConfig.compact() => const ChatSpacingConfig(
        messageBubbleInnerPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        messageListPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      );

  factory ChatSpacingConfig.comfortable() => const ChatSpacingConfig(
        messageBubbleInnerPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        messageListPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      );

  ChatSpacingConfig copyWith({
    EdgeInsets? messageBubbleOuterPadding,
    EdgeInsets? messageBubbleInnerPadding,
    EdgeInsets Function(bool isUser)? messageBubbleMargin,
    EdgeInsets? messageUsernameBottomPadding,
    EdgeInsets? messageFooterTopPadding,
    EdgeInsets? messageMediaSpacing,
    EdgeInsets? messageListPadding,
    EdgeInsets? loadingWidgetMargin,
    EdgeInsets? loadingWidgetPadding,
    EdgeInsets? typingIndicatorPadding,
    EdgeInsets? typingIndicatorMargin,
    EdgeInsets? quickRepliesPadding,
  }) {
    return ChatSpacingConfig(
      messageBubbleOuterPadding: messageBubbleOuterPadding ?? this.messageBubbleOuterPadding,
      messageBubbleInnerPadding: messageBubbleInnerPadding ?? this.messageBubbleInnerPadding,
      messageBubbleMargin: messageBubbleMargin ?? this.messageBubbleMargin,
      messageUsernameBottomPadding: messageUsernameBottomPadding ?? this.messageUsernameBottomPadding,
      messageFooterTopPadding: messageFooterTopPadding ?? this.messageFooterTopPadding,
      messageMediaSpacing: messageMediaSpacing ?? this.messageMediaSpacing,
      messageListPadding: messageListPadding ?? this.messageListPadding,
      loadingWidgetMargin: loadingWidgetMargin ?? this.loadingWidgetMargin,
      loadingWidgetPadding: loadingWidgetPadding ?? this.loadingWidgetPadding,
      typingIndicatorPadding: typingIndicatorPadding ?? this.typingIndicatorPadding,
      typingIndicatorMargin: typingIndicatorMargin ?? this.typingIndicatorMargin,
      quickRepliesPadding: quickRepliesPadding ?? this.quickRepliesPadding,
    );
  }
}
