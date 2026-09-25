// The hero's live AiChatWidget: a framed, bordered panel that auto-plays one
// scripted exchange on first build (a debounce-helper question), then leaves
// the composer live so a visitor can keep typing into the mock service.
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';

import 'app_theme.dart';

const _currentUser = ChatUser(id: 'user', name: 'You');
const _aiUser = ChatUser(id: 'ai', name: 'Assistant');

const _scriptedQuestion = 'Write a debounce helper in Dart';
const _scriptedAnswer = "Here's a debounce helper for Dart:\n\n"
    '```dart\n'
    'void Function() debounce(void Function() action, Duration delay) {\n'
    '  Timer? timer;\n'
    '  return () {\n'
    '    timer?.cancel();\n'
    '    timer = Timer(delay, action);\n'
    '  };\n'
    '}\n'
    '```\n\n'
    'Call the returned function on every keystroke; only the last call '
    'within `delay` actually fires.';

/// A default-config [AiChatWidget] inside a bordered panel (radius 16,
/// height per [height]) that plays [_scriptedQuestion]/[_scriptedAnswer]
/// once, streamed word by word, the first time it builds. DESIGN.md §9.
class LivePreview extends StatefulWidget {
  const LivePreview({super.key, required this.height});

  final double height;

  @override
  State<LivePreview> createState() => _LivePreviewState();
}

class _LivePreviewState extends State<LivePreview> {
  final _controller = ChatMessagesController();
  final _random = Random();
  StreamSubscription<String>? _streamSub;
  bool _isLoading = false;
  String? _currentStreamingId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _playScript());
  }

  Future<void> _playScript() async {
    if (!mounted) return;

    _controller.addMessage(ChatMessage(
      text: _scriptedQuestion,
      user: _currentUser,
      createdAt: DateTime.now(),
    ));

    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    _streamScriptedAnswer();
  }

  void _streamScriptedAnswer() {
    setState(() => _isLoading = true);

    final messageId = 'ai_preview_${DateTime.now().millisecondsSinceEpoch}';
    _currentStreamingId = messageId;
    final aiMessage = ChatMessage(
      text: '',
      user: _aiUser,
      createdAt: DateTime.now(),
      isMarkdown: true,
      customProperties: {'id': messageId},
    );

    var receivedFirstChunk = false;
    _streamSub = _wordByWord(_scriptedAnswer).listen(
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
    );
  }

  Stream<String> _wordByWord(String text) async* {
    final words = text.split(' ');
    var accumulated = '';
    for (final word in words) {
      accumulated += (accumulated.isEmpty ? '' : ' ') + word;
      yield accumulated;
      await Future<void>.delayed(
        Duration(milliseconds: 12 + _random.nextInt(26)),
      );
    }
  }

  void _onSendMessage(ChatMessage message) {
    // Keep the composer live after the scripted exchange: anything typed
    // gets a short, generic reply so the panel never looks broken.
    _controller.addMessage(message);
    _streamSub?.cancel();
    // Finalize whatever the previous stream left open before starting a new
    // one - cancelling the subscription alone doesn't close the message, so
    // without this a fast second send leaves the prior reply stuck with a
    // permanent caret and no Copy button.
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
      isMarkdown: true,
      customProperties: {'id': messageId},
    );

    const reply = "In a real app, this is where your AI backend's response "
        'would stream in.';
    var receivedFirstChunk = false;
    _streamSub = _wordByWord(reply).listen(
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
    );
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      height: widget.height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: AiChatWidget(
        currentUser: _currentUser,
        aiUser: _aiUser,
        controller: _controller,
        onSendMessage: _onSendMessage,
        enableMarkdownStreaming: true,
        persistentExampleQuestions: false,
        // Keep the scripted exchange readable from its start in the framed
        // panel: pin the user's question at the top while the answer
        // streams in instead of chasing the growing code block to the
        // bottom, which otherwise clips the header and the start of the
        // answer at phone widths (DESIGN.md §9).
        scrollBehaviorConfig: const ScrollBehaviorConfig(
          pinDuringStreaming: StreamingPinAnchor.userMessage,
        ),
        // The framed hero panel is short (per [height]) and never needs a
        // scroll-to-bottom affordance - at phone widths the floating button
        // otherwise covers the code block. `disabled` on
        // `ScrollToBottomOptions` is declared but not actually consulted by
        // `_buildScrollToBottomButton` (it only affects list bottom
        // padding), so it doesn't hide the button on its own - a custom
        // builder that renders nothing does. DESIGN.md §9.
        scrollToBottomOptions: ScrollToBottomOptions(
          scrollToBottomBuilder: (_) => const SizedBox.shrink(),
        ),
        loadingConfig: LoadingConfig(isLoading: _isLoading),
        onCancelGenerating: () {
          _streamSub?.cancel();
          _streamSub = null;
          final id = _currentStreamingId;
          if (id != null) _controller.stopStreamingMessage(id);
          setState(() => _isLoading = false);
        },
      ),
    );
  }
}
