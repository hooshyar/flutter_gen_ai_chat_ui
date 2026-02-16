import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';
import '../example_configs.dart';

class CompleteExample extends StatefulWidget {
  final bool isDark;
  const CompleteExample({super.key, required this.isDark});

  @override
  State<CompleteExample> createState() => _CompleteExampleState();
}

class _CompleteExampleState extends State<CompleteExample> {
  final _controller = ChatMessagesController();
  final _random = Random();
  bool _isLoading = false;

  static const _currentUser = ChatUser(id: 'user', firstName: 'You');
  static const _aiUser = ChatUser(id: 'ai', firstName: 'Nova');

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

    // Stream the complete response with markdown
    final responseText = MockResponses.markdownResponse;
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
      await Future.delayed(Duration(milliseconds: 15 + _random.nextInt(30)));
      if (!mounted) return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    // Complete: Premium gradient style — rich purple/blue accent, glassmorphic touches
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF0F0F1A), const Color(0xFF1A1025)]
              : [const Color(0xFFF8F6FF), const Color(0xFFF0F4FF)],
        ),
      ),
      child: AiChatWidget(
        currentUser: _currentUser,
        aiUser: _aiUser,
        controller: _controller,
        onSendMessage: _handleSend,
        maxWidth: 740,
        welcomeMessageConfig: WelcomeMessageConfig(
          title: 'Nova AI',
          titleStyle: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            foreground: Paint()
              ..shader = const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF3B82F6)],
              ).createShader(const Rect.fromLTWH(0, 0, 200, 40)),
          ),
          questionsSectionTitle: 'Get started:',
        ),
        exampleQuestions: [
          ExampleQuestion(
            question: 'Show me everything this UI can do',
  
          ),
          ExampleQuestion(
            question: 'Compare architecture patterns',
  
          ),
          ExampleQuestion(
            question: 'Best practices for Flutter apps',
  
          ),
          ExampleQuestion(
            question: 'Write a code example',
  
          ),
        ],
        loadingConfig: LoadingConfig(
          isLoading: _isLoading,
          typingIndicatorColor: const Color(0xFF7C3AED),
          loadingIndicator: LoadingWidget(
            texts: const ['Generating...', 'Almost there...'],
            shimmerBaseColor: isDark ? const Color(0xFF2D2640) : const Color(0xFFE8E0F0),
            shimmerHighlightColor: isDark ? const Color(0xFF3D3450) : const Color(0xFFF5F0FF),
          ),
        ),
        inputOptions: InputOptions(
          unfocusOnTapOutside: false,
          sendOnEnter: true,
          maxLines: 6,
          minLines: 1,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: InputDecoration(
            hintText: 'Ask Nova anything...',
            hintStyle: TextStyle(
              color: isDark ? Colors.white24 : Colors.black26,
              fontSize: 15,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: isDark
                    ? const Color(0xFF7C3AED).withOpacity(0.3)
                    : const Color(0xFF7C3AED).withOpacity(0.2),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: isDark
                    ? const Color(0xFF7C3AED).withOpacity(0.3)
                    : const Color(0xFF7C3AED).withOpacity(0.2),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFF7C3AED),
                width: 1.5,
              ),
            ),
            filled: true,
            fillColor: isDark
                ? const Color(0xFF1E1A2E).withOpacity(0.8)
                : Colors.white.withOpacity(0.9),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
          textStyle: TextStyle(
            fontSize: 15,
            color: isDark ? Colors.white : Colors.black87,
          ),
          sendButtonBuilder: (onSend) => Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF3B82F6)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                onPressed: onSend,
                icon: const Icon(Icons.arrow_upward_rounded, size: 20),
                color: Colors.white,
                padding: const EdgeInsets.all(8),
              ),
            ),
          ),
        ),
        messageOptions: MessageOptions(
          showUserName: false,
          showTime: true,
          showCopyButton: true,
          containerMargin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          bubbleStyle: BubbleStyle(
            userBubbleColor: isDark
                ? const Color(0xFF7C3AED).withOpacity(0.25)
                : const Color(0xFF7C3AED).withOpacity(0.1),
            aiBubbleColor: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.white.withOpacity(0.85),
            userBubbleTopLeftRadius: 20,
            userBubbleTopRightRadius: 20,
            aiBubbleTopLeftRadius: 20,
            aiBubbleTopRightRadius: 20,
            bottomLeftRadius: 20,
            bottomRightRadius: 6,
            enableShadow: true,
            shadowOpacity: 0.08,
            shadowBlurRadius: 12,
          ),
          userTextColor: isDark ? Colors.white : const Color(0xFF1A1025),
          aiTextColor: isDark ? Colors.white : const Color(0xFF1A1025),
          textStyle: const TextStyle(fontSize: 15, height: 1.6),
        ),
        enableAnimation: true,
        streamingDuration: const Duration(milliseconds: 25),
      ),
    );
  }
}
