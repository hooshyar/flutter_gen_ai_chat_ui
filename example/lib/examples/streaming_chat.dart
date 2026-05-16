// Streaming Chat — word-by-word streaming with full markdown support.
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
  final _textController = TextEditingController();
  final _aiService = ExampleAiService(style: ResponseStyle.markdown);
  bool _isLoading = false;
  StreamSubscription<String>? _streamSub;

  static const _currentUser = ChatUser(id: 'user', name: 'You');
  static const _aiUser = ChatUser(id: 'ai', name: 'Copilot');

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

  void _insertPrompt(String text) {
    _textController.text = text;
    _textController.selection = TextSelection.collapsed(offset: text.length);
  }

  void _sendPrompt(String text) {
    _onSendMessage(ChatMessage(
      text: text,
      user: _currentUser,
      createdAt: DateTime.now(),
    ));
  }

  Widget _buildToolbar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? Colors.white38 : Colors.black38;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 2, 0, 4),
      child: Row(
        children: [
          _ToolbarIcon(
            icon: Icons.code_rounded,
            tooltip: 'Write code',
            color: iconColor,
            onTap: () => _insertPrompt('Write a Dart function that '),
          ),
          _ToolbarIcon(
            icon: Icons.bug_report_outlined,
            tooltip: 'Debug code',
            color: iconColor,
            onTap: () => _insertPrompt('Debug this code: '),
          ),
          _ToolbarIcon(
            icon: Icons.lightbulb_outline_rounded,
            tooltip: 'Explain concept',
            color: iconColor,
            onTap: () => _sendPrompt('Explain async/await with an example'),
          ),
          _ToolbarIcon(
            icon: Icons.table_chart_outlined,
            tooltip: 'Compare widgets',
            color: iconColor,
            onTap: () =>
                _sendPrompt('Compare StatelessWidget vs StatefulWidget'),
          ),
          const SizedBox(width: 2),
          Container(
            width: 1,
            height: 16,
            color: isDark ? Colors.white12 : Colors.black12,
          ),
          const SizedBox(width: 6),
          Text(
            'Streaming',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white30 : Colors.black26,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    _textController.dispose();
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
        persistentExampleQuestions: true,
        loadingConfig: LoadingConfig(
          isLoading: _isLoading,
          loadingIndicator: const LoadingWidget(
            texts: ['Generating code...', 'Compiling thoughts...'],
          ),
        ),
        welcomeMessageConfig: WelcomeMessageConfig(
          title: 'Code Assistant',
          titleStyle: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black87,
          ),
          containerDecoration: BoxDecoration(
            color: isDark ? const Color(0xFF2A2A3A) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF2A2A3A) : const Color(0xFFE5E7EB),
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
          ExampleQuestion(
              question: 'Compare StatelessWidget vs StatefulWidget'),
        ],
        inputOptions: InputOptions(
          textController: _textController,
          decoration: InputDecoration(
            hintText: 'Ask about code...',
            hintStyle: TextStyle(
              color: isDark ? Colors.white30 : Colors.black26,
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          containerDecoration: BoxDecoration(
            color: isDark ? const Color(0xFF2A2A3A) : const Color(0xFFF4F4F8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.08),
            ),
          ),
          containerPadding:
              const EdgeInsets.only(top: 4, bottom: 0, left: 4, right: 8),
          sendButtonIcon: Icons.arrow_upward_rounded,
          sendButtonColor: const Color(0xFF6366F1),
          sendButtonIconSize: 20,
          sendButtonPadding: const EdgeInsets.all(6),
          textStyle: TextStyle(
            fontSize: 15,
            color: isDark ? Colors.white : Colors.black87,
          ),
          inputToolbarBuilder: _buildToolbar,
        ),
        messageOptions: MessageOptions(
          showCopyButton: true,
          showTime: true,
          bubbleStyle: BubbleStyle(
            userBubbleColor:
                isDark ? const Color(0xFF4338CA) : const Color(0xFF6366F1),
            aiBubbleColor:
                isDark ? const Color(0xFF2A2A3A) : const Color(0xFFF5F5FF),
            userBubbleTopLeftRadius: 18,
            userBubbleTopRightRadius: 18,
            aiBubbleTopLeftRadius: 18,
            aiBubbleTopRightRadius: 18,
            bottomLeftRadius: 18,
            bottomRightRadius: 4,
          ),
          userTextColor: Colors.white,
          aiTextColor:
              isDark ? Colors.white.withValues(alpha: 0.95) : Colors.black87,
        ),
      ),
    );
  }
}

class _ToolbarIcon extends StatelessWidget {
  const _ToolbarIcon({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}
