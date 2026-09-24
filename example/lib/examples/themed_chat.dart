// Themed Chat - switch between brand presets and the package default via
// CustomThemeExtension.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';

import '../services/mock_ai_service.dart';
import '../shell/demo_scaffold.dart';

enum _Preset { defaultTheme, chatgpt, claude, gemini }

class ThemedChatExample extends StatefulWidget {
  const ThemedChatExample({super.key, required this.onToggleTheme});

  final VoidCallback onToggleTheme;

  @override
  State<ThemedChatExample> createState() => _ThemedChatExampleState();
}

class _ThemedChatExampleState extends State<ThemedChatExample> {
  final _controller = ChatMessagesController();
  final _aiService = ExampleAiService(style: ResponseStyle.conversational);
  bool _isLoading = false;
  StreamSubscription<String>? _streamSub;
  String? _currentStreamingId;
  _Preset _selected = _Preset.defaultTheme;

  static const _currentUser = ChatUser(id: 'user', name: 'You');
  static const _aiUser = ChatUser(id: 'ai', name: 'Aria');

  void _onSendMessage(ChatMessage message) {
    _controller.addMessage(message);
    _streamSub?.cancel();
    setState(() => _isLoading = true);

    final messageId = 'ai_${DateTime.now().millisecondsSinceEpoch}';
    _currentStreamingId = messageId;
    final aiMessage = ChatMessage(
      text: '',
      user: _aiUser,
      createdAt: DateTime.now(),
      isMarkdown: true,
      customProperties: {'id': messageId},
    );

    // The AI bubble is only added once the first chunk arrives - until then
    // the LoadingWidget alone signals that a reply is being generated.
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

  /// Resolves the ambient theme plus, for a brand preset, its
  /// [CustomThemeExtension] - the widgets that read chat styling
  /// (`AiChatWidget`, `ChatInput`, message bubbles) pick it up from there.
  ThemeData _themeFor(BuildContext context) {
    final base = Theme.of(context);
    final isDark = base.brightness == Brightness.dark;
    switch (_selected) {
      case _Preset.defaultTheme:
        return base;
      case _Preset.chatgpt:
        return base.copyWith(
          extensions: [CustomThemeExtension.chatgpt(dark: isDark)],
        );
      case _Preset.claude:
        return base.copyWith(
          extensions: [CustomThemeExtension.claude(dark: isDark)],
        );
      case _Preset.gemini:
        return base.copyWith(
          extensions: [CustomThemeExtension.gemini(dark: isDark)],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DemoScaffold(
      title: 'Themes',
      route: '/themed',
      isDark: isDark,
      onToggleTheme: widget.onToggleTheme,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Center(
              child: SegmentedButton<_Preset>(
                segments: const [
                  ButtonSegment(
                      value: _Preset.defaultTheme, label: Text('Default')),
                  ButtonSegment(value: _Preset.chatgpt, label: Text('ChatGPT')),
                  ButtonSegment(value: _Preset.claude, label: Text('Claude')),
                  ButtonSegment(value: _Preset.gemini, label: Text('Gemini')),
                ],
                selected: {_selected},
                onSelectionChanged: (s) => setState(() => _selected = s.first),
              ),
            ),
          ),
          Expanded(
            child: Theme(
              data: _themeFor(context),
              child: AiChatWidget(
                currentUser: _currentUser,
                aiUser: _aiUser,
                controller: _controller,
                onSendMessage: _onSendMessage,
                enableMarkdownStreaming: true,
                // Surfaces a stop button in the input while generating;
                // tapping it cancels the stream and finalizes the partial
                // message.
                onCancelGenerating: _onCancelGenerating,
                loadingConfig: LoadingConfig(
                  isLoading: _isLoading,
                  loadingIndicator: const LoadingWidget(
                    texts: ['Aria is typing...', 'Styling response...'],
                  ),
                ),
                welcomeMessageConfig: const WelcomeMessageConfig(
                  title: 'Design Playground',
                  questionsSectionTitle: 'Switch themes above, then try:',
                ),
                exampleQuestions: const [
                  ExampleQuestion(question: 'Send me a long response'),
                  ExampleQuestion(question: 'How do custom themes work?'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
