/// Basic Chat Example
///
/// Minimal working chat with mock AI responses. No streaming, no themes,
/// no markdown — just a clean, working chat interface.
import 'package:flutter/material.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';

import '../services/mock_ai_service.dart';

class BasicChatExample extends StatefulWidget {
  const BasicChatExample({super.key});

  @override
  State<BasicChatExample> createState() => _BasicChatExampleState();
}

class _BasicChatExampleState extends State<BasicChatExample> {
  final _controller = ChatMessagesController();
  final _aiService = MockAiService();
  bool _isLoading = false;

  static const _currentUser = ChatUser(id: 'user', name: 'You');
  static const _aiUser = ChatUser(id: 'ai', name: 'AI Assistant');

  void _onSendMessage(ChatMessage message) async {
    setState(() => _isLoading = true);

    try {
      final response = await _aiService.generateResponse(message.text);
      if (!mounted) return;

      _controller.addMessage(
        ChatMessage(
          text: response,
          user: _aiUser,
          createdAt: DateTime.now(),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Basic Chat')),
      body: AiChatWidget(
        currentUser: _currentUser,
        aiUser: _aiUser,
        controller: _controller,
        onSendMessage: _onSendMessage,
        loadingConfig: _isLoading ? const LoadingConfig() : null,
        enableAnimation: false,
        enableMarkdownStreaming: false,
        welcomeMessageConfig: const WelcomeMessageConfig(
          title: 'Welcome! Ask me anything.',
        ),
        exampleQuestions: [
          const ExampleQuestion(question: 'Tell me about Flutter'),
          const ExampleQuestion(question: 'Show me a code example'),
          const ExampleQuestion(question: 'What can you help with?'),
        ],
      ),
    );
  }
}
