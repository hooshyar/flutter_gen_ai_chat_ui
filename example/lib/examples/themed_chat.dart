/// Themed Chat — switch between Ocean, Sunset, and Default styles.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';

import '../services/mock_ai_service.dart';

enum ChatTheme { defaultTheme, ocean, sunset }

class ThemedChatExample extends StatefulWidget {
  const ThemedChatExample({super.key});

  @override
  State<ThemedChatExample> createState() => _ThemedChatExampleState();
}

class _ThemedChatExampleState extends State<ThemedChatExample> {
  final _controller = ChatMessagesController();
  final _aiService = ExampleAiService(style: ResponseStyle.conversational);
  bool _isLoading = false;
  StreamSubscription<String>? _streamSub;
  ChatTheme _selectedTheme = ChatTheme.defaultTheme;

  static const _currentUser = ChatUser(id: 'user', name: 'You');
  static const _aiUser = ChatUser(id: 'ai', name: 'Aria');

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

  // --- Theme-specific styles ---

  BubbleStyle get _bubbleStyle {
    switch (_selectedTheme) {
      case ChatTheme.ocean:
        return const BubbleStyle(
          userBubbleColor: Color(0xFF0077B6),
          aiBubbleColor: Color(0xFFCAF0F8),
          userBubbleTopLeftRadius: 20,
          userBubbleTopRightRadius: 20,
          aiBubbleTopLeftRadius: 20,
          aiBubbleTopRightRadius: 20,
          bottomLeftRadius: 20,
          bottomRightRadius: 4,
          enableShadow: true,
        );
      case ChatTheme.sunset:
        return const BubbleStyle(
          userBubbleColor: Color(0xFFE85D04),
          aiBubbleColor: Color(0xFFFFF3E0),
          userBubbleTopLeftRadius: 4,
          userBubbleTopRightRadius: 16,
          aiBubbleTopLeftRadius: 16,
          aiBubbleTopRightRadius: 4,
          bottomLeftRadius: 16,
          bottomRightRadius: 16,
        );
      case ChatTheme.defaultTheme:
        return const BubbleStyle();
    }
  }

  Color get _userTextColor {
    switch (_selectedTheme) {
      case ChatTheme.ocean:
        return Colors.white;
      case ChatTheme.sunset:
        return Colors.white;
      case ChatTheme.defaultTheme:
        return Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : Colors.black87;
    }
  }

  Color get _aiTextColor {
    switch (_selectedTheme) {
      case ChatTheme.ocean:
        return const Color(0xFF023E8A);
      case ChatTheme.sunset:
        return const Color(0xFF6B3410);
      case ChatTheme.defaultTheme:
        return Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : Colors.black87;
    }
  }

  InputDecoration get _inputDecoration {
    switch (_selectedTheme) {
      case ChatTheme.ocean:
        return InputDecoration(
          hintText: 'Dive into a conversation...',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: const BorderSide(color: Color(0xFF90E0EF)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: const BorderSide(color: Color(0xFF0077B6), width: 2),
          ),
          filled: true,
          fillColor: const Color(0xFFCAF0F8).withOpacity(0.3),
        );
      case ChatTheme.sunset:
        return InputDecoration(
          hintText: 'Warm up a conversation...',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: Color(0xFFFFBD73)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: Color(0xFFE85D04), width: 2),
          ),
          filled: true,
          fillColor: const Color(0xFFFFF3E0).withOpacity(0.3),
        );
      case ChatTheme.defaultTheme:
        return const InputDecoration(hintText: 'Type a message...');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Themes'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SegmentedButton<ChatTheme>(
              segments: const [
                ButtonSegment(value: ChatTheme.defaultTheme, label: Text('Default')),
                ButtonSegment(value: ChatTheme.ocean, label: Text('Ocean')),
                ButtonSegment(value: ChatTheme.sunset, label: Text('Sunset')),
              ],
              selected: {_selectedTheme},
              onSelectionChanged: (s) => setState(() => _selectedTheme = s.first),
            ),
          ),
        ),
      ),
      body: AiChatWidget(
        currentUser: _currentUser,
        aiUser: _aiUser,
        controller: _controller,
        onSendMessage: _onSendMessage,
        enableMarkdownStreaming: true,
        loadingConfig: LoadingConfig(isLoading: _isLoading),
        messageOptions: MessageOptions(
          showTime: true,
          bubbleStyle: _bubbleStyle,
          userTextColor: _userTextColor,
          aiTextColor: _aiTextColor,
        ),
        inputOptions: InputOptions(decoration: _inputDecoration),
        welcomeMessageConfig: WelcomeMessageConfig(
          title: 'Design Playground 🎨',
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
          questionsSectionTitle: 'Switch themes above, then try:',
          questionsSectionTitleStyle: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white54 : Colors.black45,
          ),
        ),
        exampleQuestions: const [
          ExampleQuestion(question: 'Send me a long response'),
          ExampleQuestion(question: 'How do custom themes work?'),
        ],
      ),
    );
  }
}
