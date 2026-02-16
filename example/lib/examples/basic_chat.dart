/// Basic Chat — minimal working chat. No streaming, no markdown.
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
  final _aiService = ExampleAiService(style: ResponseStyle.plain);
  bool _isLoading = false;

  static const _currentUser = ChatUser(id: 'user', name: 'You');
  static const _aiUser = ChatUser(id: 'ai', name: 'Bot');

  void _onSendMessage(ChatMessage message) async {
    setState(() => _isLoading = true);
    try {
      final response = await _aiService.generateResponse(message.text);
      if (!mounted) return;
      _controller.addMessage(
        ChatMessage(text: response, user: _aiUser, createdAt: DateTime.now()),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Basic Chat')),
      body: AiChatWidget(
        currentUser: _currentUser,
        aiUser: _aiUser,
        controller: _controller,
        onSendMessage: _onSendMessage,
        loadingConfig: LoadingConfig(isLoading: _isLoading),
        enableAnimation: false,
        enableMarkdownStreaming: false,
        welcomeMessageConfig: WelcomeMessageConfig(
          title: 'Hello! 👋',
          titleStyle: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black87,
          ),
          containerDecoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF2A2A3A) : const Color(0xFFE5E7EB),
            ),
          ),
          questionsSectionTitle: 'Try asking:',
          questionsSectionTitleStyle: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white54 : Colors.black45,
          ),
        ),
        exampleQuestions: const [
          ExampleQuestion(question: 'What can you help me with?'),
          ExampleQuestion(question: 'Tell me about Flutter'),
          ExampleQuestion(question: 'Show me a code example'),
        ],
      ),
    );
  }
}
