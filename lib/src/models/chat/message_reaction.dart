import 'package:flutter/material.dart';

import 'chat_user.dart';

/// Represents a reaction to a chat message.
class MessageReaction {
  /// The emoji or text representing the reaction
  final String reaction;

  /// The user who made the reaction
  final ChatUser user;

  /// Optional metadata about the reaction
  final Map<String, dynamic>? metadata;

  /// Optional custom widget to display this reaction
  final Widget Function(BuildContext, MessageReaction)? customBuilder;

  const MessageReaction({
    required this.reaction,
    required this.user,
    this.metadata,
    this.customBuilder,
  });

  /// Creates a copy of this reaction with the given fields replaced with new values
  MessageReaction copyWith({
    String? reaction,
    ChatUser? user,
    Map<String, dynamic>? metadata,
    Widget Function(BuildContext, MessageReaction)? customBuilder,
  }) =>
      MessageReaction(
        reaction: reaction ?? this.reaction,
        user: user ?? this.user,
        metadata: metadata ?? this.metadata,
        customBuilder: customBuilder ?? this.customBuilder,
      );
}
