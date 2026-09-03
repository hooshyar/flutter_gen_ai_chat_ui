import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';

/// Regression for the first live report against `pinDuringStreaming`
/// (2026-09-03 QA on the web demo): the pin held for a couple of seconds and
/// then "silently jumped forward".
///
/// Cause: `addStreamingMessage` → `addMessage` schedules the delayed
/// auto-scroll for the new AI message BEFORE the pin is armed (arming happens
/// right after, in `addStreamingMessage` itself). When that timer fired it
/// called the public `scrollToBottom`, which — being "the reader taking over"
/// — released the pin and dragged the list to the bottom. The example app uses
/// exactly this flow, the widget tests used the `isStreaming: true` flow, so
/// the tests were green while the demo was broken.
///
/// The two wall-clock facts this test has to respect: the auto-scroll is only
/// scheduled if ~800 ms of REAL time passed since the previous scroll (a
/// `DateTime.now()` debounce, which `tester.pump` does not advance), and it
/// then fires after a 300 ms fake-time delay. So: real 1 s sleep, then fake
/// pump past the delay.
void main() {
  const testUser = ChatUser(id: 'user', name: 'You');
  const aiUser = ChatUser(id: 'ai', name: 'AI');
  final longAnswer = List.generate(
    300,
    (i) => 'Line $i of a very long streaming answer that keeps growing.',
  ).join('\n\n');

  testWidgets(
      'the delayed auto-scroll scheduled by addStreamingMessage must not '
      'release the pin or pull the list to the bottom', (tester) async {
    final controller = ChatMessagesController(
      scrollBehaviorConfig: const ScrollBehaviorConfig(
        pinDuringStreaming: StreamingPinAnchor.responseStart,
      ),
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(MaterialApp(
      home: Material(
        child: AiChatWidget(
          currentUser: testUser,
          aiUser: aiUser,
          controller: controller,
          onSendMessage: (_) async {},
          enableMarkdownStreaming: false,
        ),
      ),
    ));
    await tester.pump();

    controller.addMessage(ChatMessage(
      text: 'Hi',
      user: testUser,
      createdAt: DateTime.now(),
      customProperties: const {'id': 'u1', 'isUserMessage': true},
    ));
    await tester.pump();
    // Let the user message's own scroll happen and the wall-clock debounce
    // window (800 ms of real time) pass, so the AI message's auto-scroll is
    // actually scheduled — that is the path under test.
    await tester.pump(const Duration(seconds: 2));
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 1000)));

    final aiMessage = ChatMessage(
      text: '',
      user: aiUser,
      createdAt: DateTime.now(),
      customProperties: const {'id': 'stream1'},
    );
    controller.addStreamingMessage(aiMessage);
    await tester.pump();
    expect(controller.isStreamingPinActive, isTrue);

    // Stream enough to outgrow the viewport so the pin is actually holding.
    for (var i = 1; i <= 3; i++) {
      controller.updateMessage(aiMessage.copyWith(
        text: longAnswer.substring(0, (longAnswer.length * i / 6).floor()),
      ));
      await tester.pump();
      await tester.pump();
    }
    final viewportTop = tester.getTopLeft(find.byType(ListView)).dy;
    double gap() =>
        (tester.getTopLeft(find.byKey(const ValueKey('stream1'))).dy -
                viewportTop)
            .abs();
    expect(gap(), lessThan(40));
    final position =
        tester.state<ScrollableState>(find.byType(Scrollable).first).position;
    expect(position.pixels, greaterThan(100));

    // Now let the delayed auto-scroll (300 ms fake time) fire, plus its own
    // animation, plus the end-of-stream/manual-scroll timers.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    // Before the fix: pin released, list at the bottom (pixels == 0).
    expect(controller.isStreamingPinActive, isTrue,
        reason: 'the internal delayed auto-scroll must not release the pin');
    expect(position.pixels, greaterThan(100),
        reason: 'the list must not be pulled to the bottom');
    expect(gap(), lessThan(40));

    // And the pin keeps holding through the rest of the stream.
    for (var i = 4; i <= 6; i++) {
      controller.updateMessage(aiMessage.copyWith(
        text: longAnswer.substring(0, (longAnswer.length * i / 6).floor()),
      ));
      await tester.pump();
      await tester.pump();
    }
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(gap(), lessThan(40));
    expect(controller.isStreamingPinActive, isTrue);
  });
}
