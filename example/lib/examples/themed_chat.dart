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
  ///
  /// The Claude preset's light `chatBackground` is nudged to a warm cream
  /// here (package default is pure white, same as ChatGPT's) so the two
  /// brand presets stay visually distinct at a glance - the example's
  /// choice, the package factory itself is untouched.
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
        final claude = CustomThemeExtension.claude(dark: isDark);
        return base.copyWith(
          extensions: [
            if (isDark)
              claude
            else
              claude.copyWith(chatBackground: const Color(0xFFFAF7F0)),
          ],
        );
      case _Preset.gemini:
        return base.copyWith(
          extensions: [CustomThemeExtension.gemini(dark: isDark)],
        );
    }
  }

  /// The active preset's `chatBackground`/`sendButtonColor` for the shared
  /// demo chrome (top bar, sidebar, preset bar) and the segmented control's
  /// selection tint, so the whole surface reads as one canvas instead of a
  /// themed chat area sitting inside default-toned chrome.
  Color? _presetBackground(BuildContext context) {
    if (_selected == _Preset.defaultTheme) return null;
    return _themeFor(context).extension<CustomThemeExtension>()?.chatBackground;
  }

  Color? _presetAccent(BuildContext context) {
    if (_selected == _Preset.defaultTheme) return null;
    return _themeFor(context)
        .extension<CustomThemeExtension>()
        ?.sendButtonColor;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final presetBackground = _presetBackground(context);
    final presetAccent = _presetAccent(context);

    return DemoScaffold(
      title: 'Themes',
      route: '/themed',
      isDark: isDark,
      onToggleTheme: widget.onToggleTheme,
      backgroundColor: presetBackground,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: presetBackground,
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
                // Tint the selected segment with the active preset's accent
                // instead of the app's default blue, so the control itself
                // reflects the brand it's driving.
                style: presetAccent == null
                    ? null
                    : SegmentedButton.styleFrom(
                        selectedBackgroundColor: presetAccent,
                        selectedForegroundColor:
                            ThemeData.estimateBrightnessForColor(
                                        presetAccent) ==
                                    Brightness.dark
                                ? Colors.white
                                : Colors.black,
                      ),
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
