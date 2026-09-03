import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';

/// task-019: the auto-scroll debounce in `ChatMessagesController`
/// (`_scrollAfterRender`, `forceScrollToFirstMessageInChain`,
/// `_scrollToBottomInternal`) reads `package:clock`'s ambient `clock`
/// instead of raw `DateTime.now()`, specifically so this debounce can be
/// driven deterministically in a test via `withClock(...)`.
///
/// Before this fix, whether the debounce's internal ~200-300ms delayed
/// scroll `Timer` got scheduled at all depended on how much REAL wall-clock
/// time had elapsed between controller construction and the first
/// `addMessage` call — comfortably under the 800ms debounce window on a
/// fast machine (so no `Timer` is created, masking the whole mechanism),
/// but occasionally over it under heavy load, at which point a real `Timer`
/// got scheduled that a test's `pump`/`pumpAndSettle` might not drain long
/// enough to fire, failing with "A Timer is still pending" for reasons
/// unrelated to whatever the test was actually checking. That was
/// inherently unreproducible on demand — it depended on machine load at
/// the moment the test happened to run.
///
/// These tests use a manually-advanceable fake clock to force the
/// debounce's "not recently scrolled" branch open on every iteration of a
/// tight loop, reproducing on demand the exact condition (a real scroll
/// `Timer` getting scheduled) that previously only occurred by chance.
void main() {
  const testUser = ChatUser(id: 'user', name: 'Test User');
  const aiUser = ChatUser(id: 'ai', name: 'AI Assistant');

  Future<ChatMessagesController> pumpChat(
    WidgetTester tester, {
    required ScrollBehaviorConfig scrollConfig,
  }) async {
    final controller =
        ChatMessagesController(scrollBehaviorConfig: scrollConfig);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: AiChatWidget(
            currentUser: testUser,
            aiUser: aiUser,
            controller: controller,
            onSendMessage: (_) async {},
            enableMarkdownStreaming: false,
          ),
        ),
      ),
    );
    return controller;
  }

  testWidgets(
    'repeatedly forcing the debounce open via an advanced fake clock does '
    'not leave a scroll Timer pending after disposal (task-019 stress test)',
    (tester) async {
      var fakeNow = DateTime(2026);

      await withClock(Clock(() => fakeNow), () async {
        final controller = await pumpChat(
          tester,
          scrollConfig: const ScrollBehaviorConfig(
            autoScrollBehavior: AutoScrollBehavior.onNewMessage,
          ),
        );

        // Each iteration advances the fake clock well past the 800ms
        // debounce window before adding a message, so the "not recently
        // scrolled" branch opens deterministically every time — forcing a
        // real (re)scheduled scroll Timer on every single iteration,
        // rather than relying on real elapsed time to occasionally exceed
        // the window as under the old wall-clock implementation.
        for (var i = 0; i < 25; i++) {
          fakeNow = fakeNow.add(const Duration(seconds: 2));
          controller.addMessage(
            ChatMessage(
              text: 'stress message $i',
              user: i.isEven ? testUser : aiUser,
              createdAt: fakeNow,
              customProperties: {'id': 'stress_$i'},
            ),
          );
          await tester.pump();
        }

        // Drain the final scheduled scroll Timer completely (300ms delay
        // for onNewMessage) before the controller is disposed by
        // addTearDown. A real regression here throws "A Timer is still
        // pending" at teardown rather than failing a normal expectation.
        await tester.pump(const Duration(milliseconds: 350));
      });
    },
  );

  testWidgets(
    'the debounce blocks a second scroll call when the fake clock has not '
    'advanced (task-019)',
    (tester) async {
      var fakeNow = DateTime(2026);

      await withClock(Clock(() => fakeNow), () async {
        final controller = await pumpChat(
          tester,
          scrollConfig: const ScrollBehaviorConfig(
            autoScrollBehavior: AutoScrollBehavior.onNewMessage,
          ),
        );

        // First message: clock has already advanced past construction,
        // opens the debounce and schedules a scroll Timer.
        fakeNow = fakeNow.add(const Duration(seconds: 2));
        controller.addMessage(
          ChatMessage(
            text: 'first',
            user: aiUser,
            createdAt: fakeNow,
            customProperties: {'id': 'first'},
          ),
        );
        await tester.pump(const Duration(milliseconds: 350));

        // Second message, added with NO further clock advancement: the
        // debounce should block scheduling another Timer immediately
        // (same guarantee the original DateTime.now()-based version made,
        // now made deterministic instead of load-dependent).
        controller.addMessage(
          ChatMessage(
            text: 'second',
            user: aiUser,
            createdAt: fakeNow,
            customProperties: {'id': 'second'},
          ),
        );

        // No pending Timer should exist to drain — a bare pump() with no
        // duration is enough; if the debounce failed to block, this would
        // leave a 200-300ms Timer pending at disposal below.
        await tester.pump();
      });
    },
  );
}
