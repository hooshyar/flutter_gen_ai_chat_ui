/// Streaming Chat — word-by-word streaming with full markdown support.
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
  final _aiService = ExampleAiService(style: ResponseStyle.markdown);
  bool _isLoading = false;
  StreamSubscription<String>? _streamSub;

  static const _currentUser = ChatUser(id: 'user', name: 'You');
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

    _controller.addStreamingMessage(aiMessage);

    _streamSub = _aiService.streamResponse(message.text).listen(
      (accumulated) {
        if (!mounted) return;
        _controller.updateMessage(aiMessage.copyWith(text: accumulated));
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
    _streamSub?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Streaming + Markdown')),
      body: AiChatWidget(
        currentUser: _currentUser,
        aiUser: _aiUser,
        controller: _controller,
        onSendMessage: _onSendMessage,
        enableMarkdownStreaming: true,
        loadingConfig: LoadingConfig(
          isLoading: _isLoading,
          loadingIndicator: const LoadingWidget(
            texts: ['Generating code...', 'Compiling thoughts...'],
          ),
        ),
        welcomeMessageConfig: WelcomeMessageConfig(
          title: 'Code Assistant ⚡',
          titleStyle: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black87,
          ),
          containerDecoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF2A2A3A)
                  : const Color(0xFFE5E7EB),
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
          ExampleQuestion(question: 'Write a Dart singleton pattern'),
          ExampleQuestion(question: 'Explain async/await with an example'),
          ExampleQuestion(question: 'Compare StatelessWidget vs StatefulWidget'),
        ],
        messageOptions: MessageOptions(
          showCopyButton: true,
          showTime: true,
          bubbleStyle: BubbleStyle(
            userBubbleColor: const Color(0xFF6366F1),
            aiBubbleColor:
                isDark ? const Color(0xFF1E1E2E) : const Color(0xFFF5F5FF),
            userBubbleTopLeftRadius: 18,
            userBubbleTopRightRadius: 18,
            aiBubbleTopLeftRadius: 18,
            aiBubbleTopRightRadius: 18,
            bottomLeftRadius: 18,
            bottomRightRadius: 4,
          ),
          userTextColor: Colors.white,
          aiTextColor: isDark ? Colors.white : Colors.black87,
        ),
      ),
    );
  }
}
