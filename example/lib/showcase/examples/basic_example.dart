import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';
import '../example_configs.dart';

class BasicExample extends StatefulWidget {
  final bool isDark;
  const BasicExample({super.key, required this.isDark});

  @override
  State<BasicExample> createState() => _BasicExampleState();
}

class _BasicExampleState extends State<BasicExample> {
  final _controller = ChatMessagesController();
  final _random = Random();
  bool _isLoading = false;

  static const _currentUser = ChatUser(id: 'user', firstName: 'You');
  static const _aiUser = ChatUser(id: 'ai', firstName: 'Mira');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSend(ChatMessage message) async {
    if (_isLoading) return;
    _controller.addMessage(message);
    setState(() => _isLoading = true);

    await Future.delayed(Duration(milliseconds: 400 + _random.nextInt(600)));

    final responses = MockResponses.basicResponses;
    _controller.addMessage(ChatMessage(
      text: responses[_random.nextInt(responses.length)],
      user: _aiUser,
      createdAt: DateTime.now(),
    ));
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    // Basic: Clean, minimal WhatsApp-like style — green user bubbles, white AI
    return AiChatWidget(
      currentUser: _currentUser,
      aiUser: _aiUser,
      controller: _controller,
      onSendMessage: _handleSend,
      maxWidth: 680,
      welcomeMessageConfig: WelcomeMessageConfig(
        title: 'Mira',
        titleStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : Colors.black87,
        ),
        questionsSectionTitle: 'Try asking:',
      ),
      exampleQuestions: [
        ExampleQuestion(
          question: 'What can you help me with?',

        ),
        ExampleQuestion(
          question: 'Tell me a fun fact',

        ),
        ExampleQuestion(
          question: 'How does this work?',

        ),
      ],
      loadingConfig: LoadingConfig(
        isLoading: _isLoading,
        typingIndicatorColor: const Color(0xFF25D366),
        loadingIndicator: LoadingWidget(
          texts: const ['Typing...'],
          shimmerBaseColor: isDark ? Colors.grey[700] : Colors.grey[300],
          shimmerHighlightColor: isDark ? Colors.grey[600] : Colors.grey[100],
        ),
      ),
      inputOptions: InputOptions(
        unfocusOnTapOutside: false,
        sendOnEnter: true,
        maxLines: 4,
        minLines: 1,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: InputDecoration(
          hintText: 'Message...',
          hintStyle: TextStyle(
            color: isDark ? Colors.white38 : Colors.black38,
            fontSize: 15,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F0F0),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        ),
        textStyle: TextStyle(
          fontSize: 15,
          color: isDark ? Colors.white : Colors.black87,
        ),
        sendButtonBuilder: (onSend) => Padding(
          padding: const EdgeInsets.only(left: 4),
          child: IconButton(
            onPressed: onSend,
            icon: const Icon(Icons.send_rounded, size: 22),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              foregroundColor: Colors.white,
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(10),
            ),
          ),
        ),
      ),
      messageOptions: MessageOptions(
        showUserName: false,
        showTime: true,
        showCopyButton: false,
        containerMargin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        bubbleStyle: BubbleStyle(
          userBubbleColor: isDark ? const Color(0xFF005C4B) : const Color(0xFFDCF8C6),
          aiBubbleColor: isDark ? const Color(0xFF1F2C34) : Colors.white,
          userBubbleTopLeftRadius: 18,
          userBubbleTopRightRadius: 4,
          aiBubbleTopLeftRadius: 4,
          aiBubbleTopRightRadius: 18,
          bottomLeftRadius: 18,
          bottomRightRadius: 18,
          enableShadow: false,
        ),
        userTextColor: isDark ? Colors.white : Colors.black87,
        aiTextColor: isDark ? Colors.white : Colors.black87,
        textStyle: const TextStyle(fontSize: 15, height: 1.4),
      ),
      enableAnimation: false,
    );
  }
}
