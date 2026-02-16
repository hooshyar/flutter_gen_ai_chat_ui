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
  final _aiService = ExampleAiService();
  bool _isLoading = false;
  StreamSubscription<String>? _streamSubscription;

  static const _currentUser = ChatUser(id: 'user');
  static const _aiUser = ChatUser(id: 'ai', name: 'Copilot');

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
          title: 'Code Assistant',
          subtitle: 'Responses stream in with full markdown support.',
        ),
        exampleQuestions: [
          const ExampleQuestion(question: 'Write a Dart singleton pattern'),
          const ExampleQuestion(question: 'Explain async/await with an example'),
          const ExampleQuestion(question: 'Compare StatelessWidget vs StatefulWidget'),
        ],
      ),
    );
  }
}
