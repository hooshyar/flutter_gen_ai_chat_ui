// Themed Chat — switch between Ocean, Sunset, and Default styles.
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
    _controller.addMessage(message);
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

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  BubbleStyle get _bubbleStyle {
    final isDark = _isDark;
    switch (_selectedTheme) {
      case ChatTheme.ocean:
        return BubbleStyle(
          userBubbleColor: isDark ? const Color(0xFF005F8A) : const Color(0xFF0077B6),
          aiBubbleColor: isDark ? const Color(0xFF1A2F3A) : const Color(0xFFCAF0F8),
          userBubbleTopLeftRadius: 20,
          userBubbleTopRightRadius: 20,
          aiBubbleTopLeftRadius: 20,
          aiBubbleTopRightRadius: 20,
          bottomLeftRadius: 20,
          bottomRightRadius: 4,
          enableShadow: !isDark,
        );
      case ChatTheme.sunset:
        return BubbleStyle(
          userBubbleColor: isDark ? const Color(0xFFC44D03) : const Color(0xFFE85D04),
          aiBubbleColor: isDark ? const Color(0xFF3A2A1A) : const Color(0xFFFFF3E0),
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
    return Colors.white;
  }

  Color get _aiTextColor {
    final isDark = _isDark;
    switch (_selectedTheme) {
      case ChatTheme.ocean:
        return isDark ? const Color(0xFF90D5EC) : const Color(0xFF023E8A);
      case ChatTheme.sunset:
        return isDark ? const Color(0xFFFFBD73) : const Color(0xFF6B3410);
      case ChatTheme.defaultTheme:
        return isDark ? Colors.white : Colors.black87;
    }
  }

  InputDecoration get _inputDecoration {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hintColor = isDark ? Colors.white38 : Colors.black38;
    const hintSize = 15.0;

    switch (_selectedTheme) {
      case ChatTheme.ocean:
        return InputDecoration(
          hintText: 'Dive into a conversation...',
          hintStyle: TextStyle(color: hintColor, fontSize: hintSize),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: isDark
              ? const Color(0xFF0A2A3A)
              : const Color(0xFFE6F7FC),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        );
      case ChatTheme.sunset:
        return InputDecoration(
          hintText: 'Warm up a conversation...',
          hintStyle: TextStyle(color: hintColor, fontSize: hintSize),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: isDark
              ? const Color(0xFF3A2010)
              : const Color(0xFFFFF0E0),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        );
      case ChatTheme.defaultTheme:
        return InputDecoration(
          hintText: 'Type a message...',
          hintStyle: TextStyle(color: hintColor, fontSize: hintSize),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: isDark
              ? const Color(0xFF2A2A3A)
              : const Color(0xFFF2F2F7),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        );
    }
  }

  Color get _sendButtonColor {
    switch (_selectedTheme) {
      case ChatTheme.ocean:
        return const Color(0xFF0077B6);
      case ChatTheme.sunset:
        return const Color(0xFFE85D04);
      case ChatTheme.defaultTheme:
        return const Color(0xFF6366F1);
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
                ButtonSegment(
                    value: ChatTheme.defaultTheme, label: Text('Default')),
                ButtonSegment(
                    value: ChatTheme.ocean, label: Text('Ocean')),
                ButtonSegment(
                    value: ChatTheme.sunset, label: Text('Sunset')),
              ],
              selected: {_selectedTheme},
              onSelectionChanged: (s) =>
                  setState(() => _selectedTheme = s.first),
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
        loadingConfig: LoadingConfig(
          isLoading: _isLoading,
          loadingIndicator: const LoadingWidget(
            texts: ['Aria is typing...', 'Styling response...'],
          ),
        ),
        messageOptions: MessageOptions(
          showTime: true,
          bubbleStyle: _bubbleStyle,
          userTextColor: _userTextColor,
          aiTextColor: _aiTextColor,
        ),
        inputOptions: InputOptions(
          decoration: _inputDecoration,
          sendButtonIcon: Icons.arrow_upward_rounded,
          sendButtonColor: _sendButtonColor,
          sendButtonIconSize: 20,
          sendButtonPadding: const EdgeInsets.all(6),
          textStyle: TextStyle(
            fontSize: 15,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        welcomeMessageConfig: WelcomeMessageConfig(
          title: 'Design Playground 🎨',
          titleStyle: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black87,
          ),
          containerDecoration: BoxDecoration(
            color: isDark ? const Color(0xFF2A2A3A) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF2A2A3A)
                  : const Color(0xFFE5E7EB),
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
