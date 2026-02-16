/// Streaming Chat Example
///
/// Builds on the basic example with streaming responses, markdown rendering,
/// and a loading indicator. Shows how to use addStreamingMessage and
/// updateMessage for real-time text streaming.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';

import '../services/mock_ai_service.dart';

class StreamingChatExample extends StatefulWidget {
  const StreamingChatExample({super.key});

  @override
  State<StreamingChatExample> createState() => _StreamingChatExampleState();
}

class _StreamingChatExampleState extends State<StreamingChatExample> {
  final _controller = ChatMessagesController();
  final _aiService = MockAiService();
  bool _isLoading = false;
  StreamSubscription<String>? _streamSubscription;

  static const _currentUser = ChatUser(id: 'user', name: 'You');
  static const _aiUser = ChatUser(id: 'ai', name: 'AI Assistant');

  void _onSendMessage(ChatMessage message) {
    setState(() => _isLoading = true);

    final messageId = 'ai_${DateTime.now().millisecondsSinceEpoch}';
    final aiMessage = ChatMessage(
      text: '',
      user: _aiUser,
      createdAt: DateTime.now(),
      isMarkdown: true,
      customProperties: {'id': messageId},
    );

    // Add an empty streaming message
    _controller.addStreamingMessage(aiMessage);

    _streamSubscription = _aiService.streamResponse(message.text).listen(
      (accumulated) {
        if (!mounted) return;
        _controller.updateMessage(
          aiMessage.copyWith(text: accumulated),
        );
      },
      onDone: () {
        if (!mounted) return;
        _controller.stopStreamingMessage(messageId);
        setState(() => _isLoading = false);
      },
      onError: (_) {
        if (!mounted) return;
        _controller.stopStreamingMessage(messageId);
        setState(() => _isLoading = false);
      },
    );
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Streaming Chat')),
      body: AiChatWidget(
        currentUser: _currentUser,
        aiUser: _aiUser,
        controller: _controller,
        onSendMessage: _onSendMessage,
        enableMarkdownStreaming: true,
        loadingConfig: _isLoading ? const LoadingConfig() : null,
        welcomeMessageConfig: const WelcomeMessageConfig(
          title: 'Ask me anything — responses stream in real-time.',
        ),
        exampleQuestions: [
          const ExampleQuestion(question: 'Tell me about Flutter'),
          const ExampleQuestion(question: 'Show me a code example'),
          const ExampleQuestion(question: 'What can you help with?'),
          const ExampleQuestion(question: 'Say hello'),
        ],
      ),
    );
  }
}
