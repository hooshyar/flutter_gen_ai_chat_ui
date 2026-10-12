// Layout - the 2.21 layout options side by side: the stacked (2.20 default)
// or single-row (pre-2.20) composer, the attach button before the field or
// next to send, a centred or bottom-anchored welcome, one or two columns of
// suggestions, and a custom code-block copy button. Flip the chips to compare.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';

import '../services/mock_ai_service.dart';
import '../shell/demo_scaffold.dart';

class LayoutChatExample extends StatefulWidget {
  const LayoutChatExample({super.key, required this.onToggleTheme});

  final VoidCallback onToggleTheme;

  @override
  State<LayoutChatExample> createState() => _LayoutChatExampleState();
}

class _LayoutChatExampleState extends State<LayoutChatExample> {
  final _controller = ChatMessagesController();
  final _aiService = ExampleAiService();
  bool _isLoading = false;
  StreamSubscription<String>? _streamSub;
  String? _currentStreamingId;

  // Defaults show the pre-2.20 ("classic") look, the one issue #48 asked
  // for; switch them to compare with the 2.20 defaults.
  ComposerLayout _composerLayout = ComposerLayout.singleRow;
  AttachmentButtonPosition _attachPosition = AttachmentButtonPosition.leading;
  bool _centerWelcome = true;
  bool _singleColumn = true;
  bool _customCopyButton = true;

  static const _currentUser = ChatUser(id: 'user', name: 'You');
  static const _aiUser = ChatUser(id: 'ai', name: 'AI');

  void _onSendMessage(ChatMessage message) {
    _controller.addMessage(message);
    _streamSub?.cancel();
    final prevId = _currentStreamingId;
    if (prevId != null) {
      _controller.stopStreamingMessage(prevId);
    }
    setState(() => _isLoading = true);

    final messageId = 'ai_${DateTime.now().millisecondsSinceEpoch}';
    _currentStreamingId = messageId;
    final aiMessage = ChatMessage(
      text: '',
      user: _aiUser,
      createdAt: DateTime.now(),
      customProperties: {'id': messageId},
    );

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

  Widget _choice<T>(String label, T value, T groupValue, ValueChanged<T> set) {
    return ChoiceChip(
      label: Text(label),
      selected: value == groupValue,
      onSelected: (_) => setState(() => set(value)),
    );
  }

  Widget _toggle(String label, bool value, ValueChanged<bool> set) {
    return FilterChip(
      label: Text(label),
      selected: value,
      onSelected: (selected) => setState(() => set(selected)),
    );
  }

  Widget _optionsBar(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelMedium;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('Composer', style: labelStyle),
          _choice('Single row', ComposerLayout.singleRow, _composerLayout,
              (v) => _composerLayout = v),
          _choice('Stacked', ComposerLayout.stacked, _composerLayout,
              (v) => _composerLayout = v),
          const SizedBox(width: 8),
          Text('Attach', style: labelStyle),
          _choice('Leading', AttachmentButtonPosition.leading, _attachPosition,
              (v) => _attachPosition = v),
          _choice('Trailing', AttachmentButtonPosition.trailing,
              _attachPosition, (v) => _attachPosition = v),
          const SizedBox(width: 8),
          _toggle('Centred welcome', _centerWelcome, (v) => _centerWelcome = v),
          _toggle('One column', _singleColumn, (v) => _singleColumn = v),
          _toggle('Custom copy button', _customCopyButton,
              (v) => _customCopyButton = v),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DemoScaffold(
      title: 'Layout',
      route: '/layout',
      isDark: isDark,
      onToggleTheme: widget.onToggleTheme,
      body: Column(
        children: [
          _optionsBar(context),
          Expanded(
            child: AiChatWidget(
              currentUser: _currentUser,
              aiUser: _aiUser,
              controller: _controller,
              onSendMessage: _onSendMessage,
              loadingConfig: LoadingConfig(isLoading: _isLoading),
              onCancelGenerating: _onCancelGenerating,
              inputOptions: InputOptions(composerLayout: _composerLayout),
              fileUploadOptions: FileUploadOptions(
                enabled: true,
                uploadTooltip: 'Attach a file',
                buttonPosition: _attachPosition,
                // The demo only shows where the button sits.
                onFilesSelected: (_) {},
              ),
              messageOptions: MessageOptions(
                codeBlockCopyButtonBuilder: _customCopyButton
                    ? (context, copied, onCopy) => TextButton.icon(
                          onPressed: onCopy,
                          icon: Icon(
                            copied ? Icons.check : Icons.copy_all,
                            size: 14,
                          ),
                          label: Text(copied ? 'Copied' : 'Copy'),
                        )
                    : null,
              ),
              welcomeMessageConfig: WelcomeMessageConfig(
                title: 'Pick a layout above, then ask something',
                questionsSectionTitle: 'Try asking:',
                centerVertically: _centerWelcome,
                singleColumnQuestions: _singleColumn,
              ),
              exampleQuestions: const [
                ExampleQuestion(question: 'Write a Dart singleton pattern'),
                ExampleQuestion(
                    question: 'Explain async/await with an example'),
                ExampleQuestion(question: 'What is Flutter?'),
                ExampleQuestion(
                    question: 'Compare StatelessWidget and StatefulWidget'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
