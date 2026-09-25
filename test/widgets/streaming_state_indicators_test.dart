import 'package:flutter/material.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';
import 'package:flutter_gen_ai_chat_ui/src/widgets/message/streaming_caret.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression test for `_isCurrentlyStreaming` (`custom_chat_widget.dart`):
/// it used to derive "is this message streaming?" purely from the reveal
/// ticker's own backlog (`revealed < text.length`). Once the reveal ticker
/// caught up to the latest chunk of a real, still-open stream — which
/// happens well before the stream actually ends — the live caret vanished
/// and the copy/timestamp action row appeared on a message that was still
/// receiving tokens. It also never returned true at all when
/// `enableMarkdownStreaming` is false, since the reveal ticker (and its
/// backlog bookkeeping) never runs in that mode.
///
/// Fixed by also treating a message as streaming whenever its
/// `customProperties['isStreaming']` flag is true (the documented streaming
/// contract — see `ChatMessagesController`'s own doc comment: "Flip
/// isStreaming to false to end the animation"), independent of the reveal
/// ticker's backlog and of `enableMarkdownStreaming`.
void main() {
  final testUser = ChatUser(id: 'user', firstName: 'User');
  final aiUser = ChatUser(id: 'ai', firstName: 'AI');

  const fullAnswer =
      'This is a long streaming answer with plenty of words so the reveal '
      'ticker has real backlog to work through before it catches up to the '
      'latest chunk that has arrived from the simulated network stream.';

  Future<ChatMessagesController> pumpChat(
    WidgetTester tester, {
    required bool enableMarkdownStreaming,
  }) async {
    final controller = ChatMessagesController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AiChatWidget(
            currentUser: testUser,
            aiUser: aiUser,
            controller: controller,
            onSendMessage: (_) async {},
            enableMarkdownStreaming: enableMarkdownStreaming,
          ),
        ),
      ),
    );
    await tester.pump();
    return controller;
  }

  Future<void> runScenario(
    WidgetTester tester, {
    required bool enableMarkdownStreaming,
  }) async {
    final controller = await pumpChat(
      tester,
      enableMarkdownStreaming: enableMarkdownStreaming,
    );

    // The documented streaming contract: `isStreaming: true` on every
    // update, flipped to `false` on the final one — this is the precise,
    // unambiguous signal `_isCurrentlyStreaming` reads regardless of
    // `enableMarkdownStreaming`.
    final aiMessage = ChatMessage(
      text: '',
      user: aiUser,
      createdAt: DateTime.now(),
      isMarkdown: true,
      customProperties: const {'id': 'stream1', 'isStreaming': true},
    );
    controller.addMessage(aiMessage);
    await tester.pump();

    // Deliver the whole answer in one chunk update (as a real fast stream
    // delta might), then hold the stream open — still flagged
    // `isStreaming: true` — and advance real ticker time well past the
    // reveal loop's own catch-up window (well under a second per
    // `DESIGN.md` §7) so the reveal backlog empties out while the stream is
    // still logically open.
    controller.updateMessage(
      aiMessage.copyWith(
        text: fullAnswer,
        customProperties: const {'id': 'stream1', 'isStreaming': true},
      ),
    );
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    // Still streaming: caret shown, copy action hidden.
    expect(
      find.byType(StreamingCaret),
      findsOneWidget,
      reason: 'caret must stay visible for the whole open stream, '
          'even after the reveal ticker has caught up to the latest chunk '
          '(enableMarkdownStreaming: $enableMarkdownStreaming)',
    );
    expect(
      find.byIcon(Icons.content_copy_rounded),
      findsNothing,
      reason: 'the copy action must stay hidden while the message is still '
          'streaming (enableMarkdownStreaming: $enableMarkdownStreaming)',
    );

    // End the stream: flip `isStreaming` to false, per the documented
    // contract, and clear the controller's own streaming-message id too
    // (`updateMessage` only ever touches the `isStreaming` customProperty;
    // `currentlyStreamingMessageId` — the fallback signal for
    // `enableMarkdownStreaming: false`, where no reveal ticker runs to
    // provide any other completion signal — is only ever cleared by
    // `stopStreamingMessage`/a subsequent AI message).
    controller.updateMessage(
      aiMessage.copyWith(
        text: fullAnswer,
        customProperties: const {'id': 'stream1', 'isStreaming': false},
      ),
    );
    controller.stopStreamingMessage('stream1');
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(
      find.byType(StreamingCaret),
      findsNothing,
      reason: 'the caret must disappear once the stream actually ends '
          '(enableMarkdownStreaming: $enableMarkdownStreaming)',
    );
    expect(
      find.byIcon(Icons.content_copy_rounded),
      findsOneWidget,
      reason: 'the copy action must appear once the stream ends '
          '(enableMarkdownStreaming: $enableMarkdownStreaming)',
    );
  }

  testWidgets(
    'caret stays visible and copy hidden through a full open stream '
    '(enableMarkdownStreaming: true)',
    (tester) async {
      await runScenario(tester, enableMarkdownStreaming: true);
    },
  );

  testWidgets(
    'caret stays visible and copy hidden through a full open stream '
    '(enableMarkdownStreaming: false)',
    (tester) async {
      await runScenario(tester, enableMarkdownStreaming: false);
    },
  );
}
