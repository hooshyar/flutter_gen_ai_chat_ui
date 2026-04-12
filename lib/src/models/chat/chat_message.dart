import 'package:flutter/material.dart';
import 'chat_user.dart';
import 'media.dart';
import 'message_reaction.dart';
import 'quick_reply.dart';

/// Represents a message in the chat.
class ChatMessage {
  /// The text content of the message
  final String text;

  /// The user who sent the message
  final ChatUser user;

  /// When the message was created
  final DateTime createdAt;

  /// Whether the message contains markdown formatting
  final bool isMarkdown;

  /// Optional list of media attachments
  final List<ChatMedia>? media;

  /// Optional list of quick replies
  final List<QuickReply>? quickReplies;

  /// Optional list of reactions to this message
  final List<MessageReaction>? reactions;

  /// Optional custom properties for the message
  final Map<String, dynamic>? customProperties;

  /// Optional custom widget to display this message
  final Widget Function(BuildContext, ChatMessage)? customBuilder;

  /// Whether the message is currently being sent
  final bool isSending;

  /// Whether there was an error sending the message
  final bool hasError;

  /// Optional error message if there was an error
  final String? errorMessage;

  const ChatMessage({
    required this.text,
    required this.user,
    required this.createdAt,
    this.isMarkdown = false,
    this.media,
    this.quickReplies,
    this.reactions,
    this.customProperties,
    this.customBuilder,
    this.isSending = false,
    this.hasError = false,
    this.errorMessage,
  });

  /// Creates a rich widget message rendered by a result renderer registry.
  ///
  /// The [resultKind] is matched against registered builders to render a
  /// custom widget. The [data] map is passed to the builder. If no matching
  /// builder is found, the optional [text] is displayed as a fallback.
  ///
  /// ```dart
  /// ChatMessage.rich(
  ///   user: aiUser,
  ///   resultKind: 'weather',
  ///   data: {'city': 'Baghdad', 'temp': 42},
  /// );
  /// ```
  factory ChatMessage.rich({
    required ChatUser user,
    required String resultKind,
    required Map<String, dynamic> data,
    DateTime? createdAt,
    String? text,
    String? id,
  }) {
    return ChatMessage(
      text: text ?? '',
      user: user,
      createdAt: createdAt ?? DateTime.now(),
      customProperties: {
        'resultKind': resultKind,
        'resultData': data,
        if (id != null) 'id': id,
      },
    );
  }

  /// Creates a message with an inline custom widget.
  ///
  /// Use this when you need a one-off widget that doesn't need a registry.
  ///
  /// ```dart
  /// ChatMessage.widget(
  ///   user: aiUser,
  ///   builder: (context) => MyCard(data: {...}),
  /// );
  /// ```
  factory ChatMessage.widget({
    required ChatUser user,
    required Widget Function(BuildContext context) builder,
    DateTime? createdAt,
    String? text,
  }) {
    return ChatMessage(
      text: text ?? '',
      user: user,
      createdAt: createdAt ?? DateTime.now(),
      customBuilder: (context, _) => builder(context),
    );
  }

  /// Creates a loading placeholder that can later be replaced via
  /// `ChatMessagesController.updateMessage` with a rich widget or text.
  ///
  /// ```dart
  /// // Show loading
  /// controller.addMessage(ChatMessage.loading(
  ///   user: aiUser,
  ///   id: 'response-42',
  ///   text: 'Searching for lawyers...',
  /// ));
  ///
  /// // Later, replace with rich widget
  /// controller.updateMessage(ChatMessage.rich(
  ///   user: aiUser,
  ///   id: 'response-42',
  ///   resultKind: 'lawyer_search',
  ///   data: results,
  /// ));
  /// ```
  factory ChatMessage.loading({
    required ChatUser user,
    required String id,
    String? text,
    String? loadingKind,
    DateTime? createdAt,
  }) {
    return ChatMessage(
      text: text ?? '',
      user: user,
      createdAt: createdAt ?? DateTime.now(),
      customProperties: {
        'id': id,
        'isLoading': true,
        if (loadingKind != null) 'loadingKind': loadingKind,
      },
    );
  }

  /// Creates a copy of this message with the given fields replaced with new values
  ChatMessage copyWith({
    String? text,
    ChatUser? user,
    DateTime? createdAt,
    bool? isMarkdown,
    List<ChatMedia>? media,
    List<QuickReply>? quickReplies,
    List<MessageReaction>? reactions,
    Map<String, dynamic>? customProperties,
    Widget Function(BuildContext, ChatMessage)? customBuilder,
    bool? isSending,
    bool? hasError,
    String? errorMessage,
  }) =>
      ChatMessage(
        text: text ?? this.text,
        user: user ?? this.user,
        createdAt: createdAt ?? this.createdAt,
        isMarkdown: isMarkdown ?? this.isMarkdown,
        media: media ?? this.media,
        quickReplies: quickReplies ?? this.quickReplies,
        reactions: reactions ?? this.reactions,
        customProperties: customProperties ?? this.customProperties,
        customBuilder: customBuilder ?? this.customBuilder,
        isSending: isSending ?? this.isSending,
        hasError: hasError ?? this.hasError,
        errorMessage: errorMessage ?? this.errorMessage,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMessage &&
          runtimeType == other.runtimeType &&
          text == other.text &&
          user == other.user &&
          createdAt == other.createdAt &&
          isMarkdown == other.isMarkdown &&
          isSending == other.isSending &&
          hasError == other.hasError;

  @override
  int get hashCode =>
      text.hashCode ^
      user.hashCode ^
      createdAt.hashCode ^
      isMarkdown.hashCode ^
      isSending.hashCode ^
      hasError.hashCode;
}
