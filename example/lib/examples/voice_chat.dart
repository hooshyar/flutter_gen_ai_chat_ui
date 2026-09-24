// Voice input - mic/send toggle using the package's VoiceSendButton.
//
// The package ships the mic UI + state machine (VoiceSendButton) but not
// speech recognition itself (kept out of core, same reasoning as file
// picking - see FileUploadOptions). A real app wires a package like
// `speech_to_text` at onToggle/onHoldStart/onHoldEnd; this demo simulates a
// short "listening" then "recognized" cycle so the toggle flow can be shown
// without microphone permissions or a running device.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';

import '../services/mock_ai_service.dart';
import '../shell/app_theme.dart';
import '../shell/demo_scaffold.dart';

class VoiceChatExample extends StatefulWidget {
  const VoiceChatExample({super.key, required this.onToggleTheme});

  final VoidCallback onToggleTheme;

  @override
  State<VoiceChatExample> createState() => _VoiceChatExampleState();
}

class _VoiceChatExampleState extends State<VoiceChatExample> {
  final _controller = ChatMessagesController();
  final _textController = TextEditingController();
  final _aiService = ExampleAiService(style: ResponseStyle.assistant);
  bool _isLoading = false;
  VoiceState _voiceState = VoiceState.idle;
  Timer? _simulatedRecognitionTimer;

  static const _currentUser = ChatUser(id: 'user', name: 'You');
  static const _aiUser = ChatUser(id: 'ai', name: 'Assistant');

  static const _simulatedPhrases = [
    'What is the weather like today?',
    'Tell me a fun fact about Flutter',
    'Summarize this in one sentence',
  ];
  var _phraseIndex = 0;

  void _onSendMessage(ChatMessage message) async {
    _controller.addMessage(message);
    setState(() => _isLoading = true);
    try {
      final response = await _aiService.generateResponse(message.text);
      if (!mounted) return;
      _controller.addMessage(
        ChatMessage(text: response, user: _aiUser, createdAt: DateTime.now()),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleMicToggle(bool startListening) {
    _simulatedRecognitionTimer?.cancel();
    if (!startListening) {
      setState(() => _voiceState = VoiceState.idle);
      return;
    }

    setState(() => _voiceState = VoiceState.listening);
    _simulatedRecognitionTimer = Timer(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      final phrase = _simulatedPhrases[_phraseIndex % _simulatedPhrases.length];
      _phraseIndex++;
      setState(() {
        _voiceState = VoiceState.idle;
        _textController.text = phrase;
      });
    });
  }

  @override
  void dispose() {
    _simulatedRecognitionTimer?.cancel();
    _controller.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = context.appColors;

    return DemoScaffold(
      title: 'Voice',
      route: '/voice',
      isDark: isDark,
      onToggleTheme: widget.onToggleTheme,
      body: AiChatWidget(
        currentUser: _currentUser,
        aiUser: _aiUser,
        controller: _controller,
        onSendMessage: _onSendMessage,
        loadingConfig: LoadingConfig(isLoading: _isLoading),
        inputOptions: InputOptions(
          textController: _textController,
          // Mic when the field is empty, send button once there's text -
          // the same toggle pattern ChatGPT's mobile app uses.
          sendOrMicBuilder: (onSend, isEmpty) => isEmpty
              ? VoiceSendButton(
                  mode: VoiceSendMode.toggle,
                  state: _voiceState,
                  onToggle: _handleMicToggle,
                )
              : IconButton(
                  tooltip: 'Send',
                  icon: Icon(
                    Icons.arrow_upward_rounded,
                    size: 20,
                    color: colors.onAccent,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: colors.accent,
                    padding: const EdgeInsets.all(6),
                    minimumSize: const Size(44, 44),
                  ),
                  onPressed: onSend,
                ),
        ),
        welcomeMessageConfig: const WelcomeMessageConfig(
          title: 'Tap the mic to speak (simulated)',
        ),
        exampleQuestions: const [
          ExampleQuestion(question: 'What is the weather like today?'),
          ExampleQuestion(question: 'Tell me a fun fact about Flutter'),
          ExampleQuestion(question: 'Summarize this in one sentence'),
        ],
      ),
    );
  }
}
