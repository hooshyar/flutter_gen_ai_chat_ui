import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';
import '../example_configs.dart';

class StreamingExample extends StatefulWidget {
  final bool isDark;
  const StreamingExample({super.key, required this.isDark});

  @override
  State<StreamingExample> createState() => _StreamingExampleState();
}

class _StreamingExampleState extends State<StreamingExample> {
  final _controller = ChatMessagesController();
  final _random = Random();
  bool _isLoading = false;

  static const _currentUser = ChatUser(id: 'user', firstName: 'You');
  static const _aiUser = ChatUser(id: 'ai', firstName: 'Claude');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSend(ChatMessage message) async {
    if (_isLoading) return;
    _controller.addMessage(message);
    setState(() => _isLoading = true);

    await Future.delayed(Duration(milliseconds: 300 + _random.nextInt(400)));
    setState(() => _isLoading = false);

    final responses = MockResponses.streamingResponses;
    final responseText = responses[_random.nextInt(responses.length)];
    final messageId = 'ai_${DateTime.now().millisecondsSinceEpoch}';
    final words = responseText.split(' ');
    var accumulated = '';

    for (int i = 0; i < words.length; i++) {
      accumulated += (i == 0 ? '' : ' ') + words[i];
      final msg = ChatMessage(
        text: accumulated,
        user: _aiUser,
        createdAt: DateTime.now(),
        isMarkdown: true,
        customProperties: {
          'id': messageId,
          'isStreaming': i < words.length - 1,
        },
      );
      if (i == 0) {
        _controller.addMessage(msg);
      } else {
        _controller.updateMessage(msg);
      }
      await Future.delayed(Duration(milliseconds: 20 + _random.nextInt(40)));
      if (!mounted) return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    // Streaming: ChatGPT-inspired — no bubble for AI, subtle user bubble, wide layout
    return AiChatWidget(
      currentUser: _currentUser,
      aiUser: _aiUser,
      controller: _controller,
      onSendMessage: _handleSend,
      maxWidth: 780,
      welcomeMessageConfig: WelcomeMessageConfig(
        title: 'What can I help with?',
        titleStyle: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white70 : Colors.black54,
        ),
        questionsSectionTitle: '',
      ),
      exampleQuestions: [
        ExampleQuestion(
          question: 'How do I set up a Flutter project?',

        ),
        ExampleQuestion(
          question: 'Explain StatelessWidget vs StatefulWidget',

        ),
        ExampleQuestion(
          question: 'Write a Repository pattern example',

        ),
      ],
      loadingConfig: LoadingConfig(
        isLoading: _isLoading,
        loadingIndicator: LoadingWidget(
          texts: const ['Thinking...'],
          shimmerBaseColor: isDark ? Colors.grey[800] : Colors.grey[200],
          shimmerHighlightColor: isDark ? Colors.grey[700] : Colors.grey[50],
        ),
      ),
      inputOptions: InputOptions(
        unfocusOnTapOutside: false,
        sendOnEnter: true,
        maxLines: 8,
        minLines: 1,
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: InputDecoration(
          hintText: 'Ask anything...',
          hintStyle: TextStyle(
            color: isDark ? Colors.white30 : Colors.black26,
            fontSize: 15,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(
              color: isDark ? const Color(0xFF444444) : const Color(0xFFDDDDDD),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(
              color: isDark ? const Color(0xFF444444) : const Color(0xFFDDDDDD),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(
              color: isDark ? const Color(0xFF666666) : const Color(0xFFBBBBBB),
            ),
          ),
          filled: true,
          fillColor: isDark ? const Color(0xFF303030) : Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
        textStyle: TextStyle(
          fontSize: 15,
          color: isDark ? Colors.white : Colors.black87,
        ),
        sendButtonBuilder: (onSend) => Padding(
          padding: const EdgeInsets.only(left: 4, right: 4),
          child: IconButton(
            onPressed: onSend,
            icon: const Icon(Icons.arrow_upward_rounded, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: isDark ? Colors.white : Colors.black,
              foregroundColor: isDark ? Colors.black : Colors.white,
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(8),
            ),
          ),
        ),
      ),
      messageOptions: MessageOptions(
        showUserName: false,
        showTime: false,
        showCopyButton: true,
        containerMargin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        bubbleStyle: BubbleStyle(
          userBubbleColor: isDark ? const Color(0xFF2F2F2F) : const Color(0xFFF0F0F0),
          aiBubbleColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          userBubbleTopLeftRadius: 20,
          userBubbleTopRightRadius: 20,
          aiBubbleTopLeftRadius: 0,
          aiBubbleTopRightRadius: 0,
          bottomLeftRadius: 20,
          bottomRightRadius: 20,
          enableShadow: false,
        ),
        userTextColor: isDark ? Colors.white : Colors.black87,
        aiTextColor: isDark ? Colors.white : Colors.black87,
        textStyle: const TextStyle(fontSize: 15, height: 1.6),
      ),
      enableAnimation: true,
      streamingDuration: const Duration(milliseconds: 30),
    );
  }
}
