// This file is deprecated. Use chat/chat_user.dart instead.
// Please update your imports to use the new location.

@Deprecated(
    'Use package:flutter_gen_ai_chat_ui (ChatUser from chat/chat_user.dart) '
    'instead. This compatibility shim will be removed in v3.0.0.')
export 'chat/chat_user.dart';

class ChatUser {
  final String id;
  final String name;
  final String? avatar;

  const ChatUser({
    required this.id,
    required this.name,
    this.avatar,
  });
}
