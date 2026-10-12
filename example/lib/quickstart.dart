import 'package:flutter/material.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';

void main() => runApp(const MaterialApp(home: ChatScreen()));

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = ChatMessagesController();
  static const _user = ChatUser(id: 'user', name: 'You');
  static const _ai = ChatUser(id: 'ai', name: 'Assistant');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AiChatWidget(
        currentUser: _user,
        aiUser: _ai,
        controller: _controller,
        onSendMessage: (message) {
          _controller.addMessage(message);
          // Swap fakeLlmReply() for your model's token stream.
          _controller.streamResponse(fakeLlmReply(message.text), user: _ai);
        },
        welcomeMessageConfig: const WelcomeMessageConfig(
          title: 'Ask me anything',
        ),
      ),
    );
  }
}

/// Stands in for an LLM: streams a markdown reply one word at a time.
Stream<String> fakeLlmReply(String prompt) async* {
  final reply = 'You asked: *$prompt*\n\n'
      'This reply **streams in** word by word, with `inline code` '
      'and a list:\n\n'
      '- markdown renders as it arrives\n'
      '- the reply closes when the stream ends\n';
  for (final token in RegExp(r'\S+\s*').allMatches(reply)) {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    yield token[0]!;
  }
}
