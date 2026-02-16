/// Themed Chat Example
///
/// Demonstrates theme switching with custom bubble styles, input options,
/// and message options. Includes 3 themes: Default, Ocean, and Sunset.
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
  final _aiService = ExampleAiService();
  bool _isLoading = false;
  StreamSubscription<String>? _streamSubscription;
  ChatTheme _selectedTheme = ChatTheme.defaultTheme;

  static const _currentUser = ChatUser(id: 'user');
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

    _streamSubscription = _aiService.streamResponse(message.text).listen(
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

  // --- Theme configurations ---

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
          bottomRightRadius: 20,
        );
      case ChatTheme.sunset:
        return const BubbleStyle(
          userBubbleColor: Color(0xFFE85D04),
          aiBubbleColor: Color(0xFFFFF3E0),
          userBubbleTopLeftRadius: 4,
          userBubbleTopRightRadius: 4,
          aiBubbleTopLeftRadius: 4,
          aiBubbleTopRightRadius: 4,
          bottomLeftRadius: 4,
          bottomRightRadius: 4,
        );
      case ChatTheme.defaultTheme:
        return const BubbleStyle();
    }
  }

  InputOptions get _inputOptions {
    switch (_selectedTheme) {
      case ChatTheme.ocean:
        return const InputOptions(
          decoration: InputDecoration(
            hintText: 'Dive into a conversation...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(24)),
            ),
          ),
        );
      case ChatTheme.sunset:
        return const InputOptions(
          decoration: InputDecoration(
            hintText: 'Warm up a conversation...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(4)),
            ),
          ),
        );
      case ChatTheme.defaultTheme:
        return const InputOptions();
    }
  }

  MessageOptions get _messageOptions {
    switch (_selectedTheme) {
      case ChatTheme.ocean:
        return MessageOptions(showTime: true, bubbleStyle: _bubbleStyle);
      case ChatTheme.sunset:
        return MessageOptions(showTime: true, bubbleStyle: _bubbleStyle);
      case ChatTheme.defaultTheme:
        return const MessageOptions();
    }
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
      appBar: AppBar(
        title: const Text('Themed Chat'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SegmentedButton<ChatTheme>(
              segments: const [
                ButtonSegment(
                  value: ChatTheme.defaultTheme,
                  label: Text('Default'),
                ),
                ButtonSegment(
                  value: ChatTheme.ocean,
                  label: Text('Ocean'),
                ),
                ButtonSegment(
                  value: ChatTheme.sunset,
                  label: Text('Sunset'),
                ),
              ],
              selected: {_selectedTheme},
              onSelectionChanged: (selection) {
                setState(() => _selectedTheme = selection.first);
              },
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
        messageOptions: _messageOptions,
        inputOptions: _inputOptions,
        welcomeMessageConfig: const WelcomeMessageConfig(
          title: 'Design Playground',
        ),
        exampleQuestions: [
          const ExampleQuestion(question: 'Send me a long response'),
          const ExampleQuestion(question: 'How do custom themes work?'),
        ],
      ),
    );
  }
}
