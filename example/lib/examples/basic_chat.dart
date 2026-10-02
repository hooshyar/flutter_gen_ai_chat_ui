// Basic Chat - the proof screen. Only the required arguments, example
// questions and a welcome title: everything else is the package default.
import 'dart:async';

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
  bool _isLoading = false;
  StreamSubscription<String>? _streamSub;
  String? _currentStreamingId;

  static const _currentUser = ChatUser(id: 'user', name: 'You');
  static const _aiUser = ChatUser(id: 'ai', name: 'AI');

  // Streams the reply word by word (via the mock service's tuned 25-40ms
  // per-word pacing) instead of popping in the full text at once, so a
  // short reply still visibly streams rather than feeling like it stalled
  // then snapped in (DESIGN.md §9 "Basic").
  void _onSendMessage(ChatMessage message) {
    _controller.addMessage(message);
    _streamSub?.cancel();
    // Finalize whatever the previous stream left open before starting a new
    // one - cancelling the subscription alone doesn't close the message, so
    // without this a fast second send leaves the prior reply stuck with a
    // permanent caret and no Copy button.
    final prevId = _currentStreamingId;
    if (prevId != null) {
      _controller.stopStreamingMessage(prevId);
    }
    setState(() => _isLoading = true);

    final messageId = 'ai_${DateTime.now().millisecondsSinceEpoch}';
    _currentStreamingId = messageId;
    final aiMessage = ChatMessage(
      text: '',
      user: _aiUser,
      createdAt: DateTime.now(),
      customProperties: {'id': messageId},
    );

    var receivedFirstChunk = false;
    _streamSub = _aiService.streamResponse(message.text).listen(
      (accumulated) {
        if (!mounted) return;
        if (receivedFirstChunk) {
          _controller.updateMessage(aiMessage.copyWith(text: accumulated));
        } else {
          receivedFirstChunk = true;
          _controller
              .addStreamingMessage(aiMessage.copyWith(text: accumulated));
        }
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

  // Cancels the in-flight response. Wired to AiChatWidget.onCancelGenerating,
  // which surfaces a stop button in the input while _isLoading is true.
  void _onCancelGenerating() {
    _streamSub?.cancel();
    _streamSub = null;
    final id = _currentStreamingId;
    if (id != null) {
      _controller.stopStreamingMessage(id);
    }
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _streamSub?.cancel();
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
        loadingConfig: LoadingConfig(isLoading: _isLoading),
        // Surfaces a stop button in the input while generating; tapping it
        // cancels the stream and finalizes the partial message.
        onCancelGenerating: _onCancelGenerating,
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
