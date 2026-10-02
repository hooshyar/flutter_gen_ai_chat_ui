import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';

/// Example chat messages for demonstration purposes.
class ChatExample {
  /// Creates a chat example.
  const ChatExample({required this.question, required this.onTap});

  /// The example question text.
  final String question;

  /// Callback when the example is tapped.
  final void Function(ChatMessagesController) onTap;
}
