// Basic Chat - the proof screen. Only the required arguments, example
// questions and a welcome title: everything else is the package default.
import 'package:flutter/material.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';

import '../services/mock_ai_service.dart';
import '../shell/demo_scaffold.dart';

class BasicChatExample extends StatefulWidget {
  const BasicChatExample({super.key, required this.onToggleTheme});

  final VoidCallback onToggleTheme;

  @override
  State<BasicChatExample> createState() => _BasicChatExampleState();
}

class _BasicChatExampleState extends State<BasicChatExample> {
  final _controller = ChatMessagesController();
  final _aiService = ExampleAiService(style: ResponseStyle.plain);

  static const _currentUser = ChatUser(id: 'user', name: 'You');
  static const _aiUser = ChatUser(id: 'ai', name: 'AI');

  void _onSendMessage(ChatMessage message) async {
    _controller.addMessage(message);
    final response = await _aiService.generateResponse(message.text);
    if (!mounted) return;
    _controller.addMessage(
      ChatMessage(text: response, user: _aiUser, createdAt: DateTime.now()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DemoScaffold(
      title: 'Basic',
      route: '/basic',
      isDark: isDark,
      onToggleTheme: widget.onToggleTheme,
      body: AiChatWidget(
        currentUser: _currentUser,
        aiUser: _aiUser,
        controller: _controller,
        onSendMessage: _onSendMessage,
        welcomeMessageConfig:
            const WelcomeMessageConfig(title: 'How can I help?'),
        exampleQuestions: const [
          ExampleQuestion(question: 'What can you help me with?'),
          ExampleQuestion(question: 'Tell me about Flutter'),
          ExampleQuestion(question: 'What is Dart?'),
        ],
      ),
    );
  }
}
