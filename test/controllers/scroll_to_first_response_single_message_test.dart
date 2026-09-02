import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';

/// Regression test for GitHub issue #42: a single long streaming AI answer
/// (not a multi-message response chain) should stop autoscrolling once the
/// top of that answer reaches the top of the viewport, instead of chasing
/// the bottom of the still-growing message and hiding its beginning.
///
/// Root cause: `scrollToMessage`/`forceScrollToFirstMessageInChain` computed
/// their scroll target from `index / itemCount`, which assumes uniform item
/// heights. With one short user message and one very long AI answer, that
/// heuristic badly mistargets the scroll position — for the default
/// `reverse: true` list it collapsed to "just show the bottom", i.e. exactly
/// the bug reported (the top of the answer scrolls out of view). The fix
/// measures the message's real rendered position via a `BuildContext`
/// resolver and uses `Scrollable.ensureVisible` instead.
///
/// This drives `scrollToMessage`/`forceScrollToFirstMessageInChain` directly
/// rather than through the full auto-scroll timer chain: that chain debounces
/// via real wall-clock `DateTime.now()`, which `tester.pump(duration)` does
/// not advance, making it untestable through fake-async pumps. Calling these
/// methods directly still exercises exactly the code path
/// `ScrollBehaviorConfig.scrollToFirstResponseMessage` invokes internally.
void main() {
  const testUser = ChatUser(id: 'user', name: 'Test User');
  const aiUser = ChatUser(id: 'ai', name: 'AI Assistant');

  Future<ChatMessagesController> pumpChatWithLongSingleResponse(
    WidgetTester tester,
  ) async {
    final controller = ChatMessagesController(
      scrollBehaviorConfig: const ScrollBehaviorConfig(
        scrollToFirstResponseMessage: true,
      ),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: AiChatWidget(
            currentUser: testUser,
            aiUser: aiUser,
            controller: controller,
            onSendMessage: (_) async {},
            // Isolate scroll-positioning correctness from the separate
            // character-by-character reveal animation.
            enableMarkdownStreaming: false,
          ),
        ),
      ),
    );
    await tester.pump();

    // A short user question...
    controller.addMessage(ChatMessage(
      text: 'Hi',
      user: testUser,
      createdAt: DateTime.now(),
      customProperties: const {'id': 'u1', 'isUserMessage': true},
    ));
    await tester.pump();

    // ...followed by one very long AI answer, delivered incrementally like a
    // real stream, ending with isStreaming: false.
    final longAnswer = List.generate(
      300,
      (i) => 'Line $i of a very long streaming answer that keeps growing.',
    ).join('\n\n');

    // `responseId`/`isStartOfResponse` are set (equal to the message's own
    // id) so both `scrollToMessage` (by id) and
    // `forceScrollToFirstMessageInChain` (by responseId) can target this
    // message.
    const responseProperties = {
      'id': 'resp1',
      'responseId': 'resp1',
      'isStartOfResponse': true,
    };

    controller.addMessage(ChatMessage(
      text: '',
      user: aiUser,
      createdAt: DateTime.now(),
      customProperties: const {...responseProperties, 'isStreaming': true},
    ));
    await tester.pump();

    for (var i = 1; i <= 5; i++) {
      final chunk =
          longAnswer.substring(0, (longAnswer.length * i / 5).floor());
      controller.updateMessage(ChatMessage(
        text: chunk,
        user: aiUser,
        createdAt: DateTime.now(),
        customProperties: const {...responseProperties, 'isStreaming': true},
      ));
      await tester.pump();
    }

    controller.updateMessage(ChatMessage(
      text: longAnswer,
      user: aiUser,
      createdAt: DateTime.now(),
      customProperties: const {...responseProperties, 'isStreaming': false},
    ));
    controller.stopStreamingMessage('resp1');
    await tester.pump();

    return controller;
  }

  double topAlignmentGap(WidgetTester tester) {
    final viewportTop = tester.getTopLeft(find.byType(ListView)).dy;
    final responseTop =
        tester.getTopLeft(find.byKey(const ValueKey('resp1'))).dy;
    return (responseTop - viewportTop).abs();
  }

  testWidgets(
      'scrollToMessage pins the top of a single long streaming answer '
      'to the top of the viewport', (tester) async {
    final controller = await pumpChatWithLongSingleResponse(tester);

    // Drain any background auto-scroll Timer that setup's addMessage/
    // updateMessage/stopStreamingMessage calls may have scheduled (whether
    // one gets scheduled at all is nondeterministic — see the wall-clock
    // debounce note above). A bare, not-yet-fired dart:async Timer isn't
    // something `pumpAndSettle` waits for on its own (it only tracks
    // scheduled frames), so a straggler here can otherwise trip "Timer
    // still pending" at teardown once this test's own explicit call below
    // finishes settling first.
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    // The AI answer is far taller than the viewport, so there is real
    // scrolling room — this guards against a false pass from a degenerate
    // (too-short) test layout.
    final responseSize = tester.getSize(find.byKey(const ValueKey('resp1')));
    final viewportSize = tester.getSize(find.byType(ListView));
    expect(responseSize.height, greaterThan(viewportSize.height * 5));

    controller.scrollToMessage('resp1');
    await tester.pumpAndSettle();

    // Before the fix, the index/itemCount heuristic collapsed (for the
    // default reverse-order list) to "just show the bottom" — i.e. exactly
    // the bug in #42, where the top of a single long answer scrolls out of
    // view. With the fix, the top of the response aligns with the top of
    // the viewport (small tolerance for list padding/bubble chrome).
    expect(topAlignmentGap(tester), lessThan(40));

    // Trailing drain: our own scroll notifies the controller's manual-scroll
    // listener, which schedules its own short reset Timer right at the tail
    // of the animation above — give it a chance to fire before teardown.
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
  });

  testWidgets(
      'forceScrollToFirstMessageInChain pins the top of a single long '
      'streaming answer to the top of the viewport', (tester) async {
    final controller = await pumpChatWithLongSingleResponse(tester);

    // Drain any background auto-scroll Timer left over from setup — see the
    // note in the `scrollToMessage` test above.
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    // `forceScrollToFirstMessageInChain` debounces against real wall-clock
    // `DateTime.now()` (not the fake-async clock `tester.pump` advances), so
    // a real (short) delay is needed to clear it before the call below is
    // guaranteed to actually run instead of being silently dropped.
    // `runAsync` steps outside the fake-async zone so this delay actually
    // elapses in real time instead of deadlocking waiting for a pump.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 850)),
    );

    controller.forceScrollToFirstMessageInChain('resp1');
    await tester.pumpAndSettle();

    expect(topAlignmentGap(tester), lessThan(40));

    // Trailing drain — see the note in the `scrollToMessage` test above.
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
  });
}
