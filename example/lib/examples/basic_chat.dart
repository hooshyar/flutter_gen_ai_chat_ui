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
  ChatResponseStream? _reply;
  bool _isLoading = false;

  static const _currentUser = ChatUser(id: 'user', name: 'You');
  static const _aiUser = ChatUser(id: 'ai', name: 'AI');

  // streamResponse adds the reply with its first words, updates it as the
  // mock service streams (25-40ms per word), and closes it when the stream
  // ends. The mock yields the whole text so far on each event, hence
  // `accumulated: true`; a real LLM's token deltas need nothing extra.
  void _onSendMessage(ChatMessage message) {
    _controller.addMessage(message);
    // A new send closes the previous reply if it is still streaming, so it
    // never stays stuck with a caret and no Copy button.
    _reply?.cancel();
    final reply = _controller.streamResponse(
      _aiService.streamResponse(message.text),
      user: _aiUser,
      accumulated: true,
    );
    _reply = reply;
    setState(() => _isLoading = true);
    reply.done.whenComplete(() {
      if (mounted && identical(_reply, reply)) {
        setState(() => _isLoading = false);
      }
    });
  }

  // Wired to AiChatWidget.onCancelGenerating, which shows a stop button in
  // the input while _isLoading is true.
  void _onCancelGenerating() {
    _reply?.cancel();
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _reply?.cancel();
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
