// Streaming Chat - word-by-word streaming with full markdown support.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';

import '../services/mock_ai_service.dart';
import '../shell/app_theme.dart';
import '../shell/demo_scaffold.dart';

class StreamingChatExample extends StatefulWidget {
  const StreamingChatExample({super.key, required this.onToggleTheme});

  final VoidCallback onToggleTheme;

  @override
  State<StreamingChatExample> createState() => _StreamingChatExampleState();
}

class _StreamingChatExampleState extends State<StreamingChatExample> {
  final _controller = ChatMessagesController(
    scrollBehaviorConfig: const ScrollBehaviorConfig(
      pinDuringStreaming: StreamingPinAnchor.responseStart,
    ),
  );
  final _textController = TextEditingController();
  final _aiService = ExampleAiService(style: ResponseStyle.markdown);
  bool _isLoading = false;
  StreamSubscription<String>? _streamSub;
  String? _currentStreamingId;

  /// Drives `MessageOptions.enableSyntaxHighlighting` - toggled from the
  /// demo scaffold's trailing actions so you can compare highlighted vs
  /// plain code blocks.
  bool _syntaxHighlighting = true;

  /// Demo of `ScrollBehaviorConfig.pinDuringStreaming`: pick what stays at
  /// the top of the viewport while a long answer streams in.
  StreamingPinAnchor _pinAnchor = StreamingPinAnchor.responseStart;

  void _setPinAnchor(StreamingPinAnchor anchor) {
    setState(() => _pinAnchor = anchor);
    _controller.scrollBehaviorConfig =
        ScrollBehaviorConfig(pinDuringStreaming: anchor);
  }

  static const _pinLabels = {
    StreamingPinAnchor.none: 'No pin (follow the answer)',
    StreamingPinAnchor.responseStart: 'Pin the start of the answer',
    StreamingPinAnchor.userMessage: 'Pin my question',
  };

  static const _currentUser = ChatUser(id: 'user', name: 'You');
  static const _aiUser = ChatUser(id: 'ai', name: 'Copilot');

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
    final colors = context.appColors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 2, 0, 4),
      child: Row(
        children: [
          _ToolbarIcon(
            icon: Icons.code_rounded,
            tooltip: 'Write code',
            color: colors.textSecondary,
            onTap: () => _insertPrompt('Write a Dart function that '),
          ),
          _ToolbarIcon(
            icon: Icons.bug_report_outlined,
            tooltip: 'Debug code',
            color: colors.textSecondary,
            onTap: () => _insertPrompt('Debug this code: '),
          ),
          _ToolbarIcon(
            icon: Icons.lightbulb_outline_rounded,
            tooltip: 'Explain concept',
            color: colors.textSecondary,
            onTap: () => _sendPrompt('Explain async/await with an example'),
          ),
          _ToolbarIcon(
            icon: Icons.table_chart_outlined,
            tooltip: 'Compare widgets',
            color: colors.textSecondary,
            onTap: () =>
                _sendPrompt('Compare StatelessWidget vs StatefulWidget'),
          ),
          _ToolbarIcon(
            icon: Icons.language,
            tooltip: 'Same function in 3 languages',
            color: colors.textSecondary,
            onTap: () =>
                _sendPrompt('Same function in Dart, Python and TypeScript'),
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
    final colors = context.appColors;

    return DemoScaffold(
      title: 'Streaming',
      route: '/streaming',
      isDark: isDark,
      onToggleTheme: widget.onToggleTheme,
      actions: [
        IconButton(
          tooltip: 'Syntax highlighting',
          icon: Icon(
            _syntaxHighlighting ? Icons.code : Icons.code_off,
            color: colors.textSecondary,
          ),
          onPressed: () =>
              setState(() => _syntaxHighlighting = !_syntaxHighlighting),
        ),
        PopupMenuButton<StreamingPinAnchor>(
          tooltip: 'Pin while streaming',
          icon: Icon(Icons.push_pin_outlined, color: colors.textSecondary),
          initialValue: _pinAnchor,
          onSelected: _setPinAnchor,
          itemBuilder: (context) => [
            for (final anchor in StreamingPinAnchor.values)
              CheckedPopupMenuItem(
                value: anchor,
                checked: anchor == _pinAnchor,
                child: Text(_pinLabels[anchor]!),
              ),
          ],
        ),
      ],
      body: AiChatWidget(
        currentUser: _currentUser,
        aiUser: _aiUser,
        controller: _controller,
        onSendMessage: _onSendMessage,
        enableMarkdownStreaming: true,
        // The fixed-height persistent strip clips a chip row and covers the
        // top of the message list - the input toolbar already offers prompts.
        persistentExampleQuestions: false,
        loadingConfig: LoadingConfig(
          isLoading: _isLoading,
          loadingIndicator: const LoadingWidget(
            texts: ['Generating code...', 'Compiling thoughts...'],
          ),
        ),
        // Surfaces a stop button in the input while generating; tapping it
        // cancels the stream and finalizes the partial message.
        onCancelGenerating: _onCancelGenerating,
        welcomeMessageConfig: const WelcomeMessageConfig(
          title: 'Code Assistant',
          questionsSectionTitle: 'Try asking:',
        ),
        exampleQuestions: const [
          ExampleQuestion(question: 'Write a Dart singleton pattern'),
          ExampleQuestion(question: 'Explain async/await with an example'),
          ExampleQuestion(
              question: 'Compare StatelessWidget vs StatefulWidget'),
          ExampleQuestion(
              question: 'Same function in Dart, Python and TypeScript'),
        ],
        inputOptions: InputOptions(
          textController: _textController,
          inputToolbarBuilder: _buildToolbar,
        ),
        messageOptions: MessageOptions(
          showCopyButton: true,
          showTime: true,
          // Fenced code blocks: highlighted by default, copy button in the
          // header, theme resolved from ambient brightness.
          enableSyntaxHighlighting: _syntaxHighlighting,
          codeBlockTheme: CodeBlockTheme.of(Theme.of(context).brightness),
          showCodeBlockCopyButton: true,
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
      child: SizedBox(
        width: 44,
        height: 44,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}
