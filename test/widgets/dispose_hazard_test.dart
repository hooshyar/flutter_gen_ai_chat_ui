// Regression tests for dispose-hazard audits (iter 3: untracked timers;
// iter 8: untracked post-frame callbacks).
//
// These widgets previously scheduled work via raw `Future.delayed`,
// untracked `Timer`s, or `WidgetsBinding.addPostFrameCallback` inside a
// State or ChangeNotifier. If the widget was disposed before the delayed
// work fired, `AutomatedTestWidgetsFlutterBinding` flagged "Timer still
// pending after dispose" (timers) or `setState() called after dispose()`
// (frame callbacks) at teardown. The fixes track each scheduled call and
// cancel/guard it from dispose(); these tests pin that behavior so a
// future regression fails loudly here rather than only in downstream
// widget tests.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';
import 'package:flutter_gen_ai_chat_ui/src/widgets/animated_chat_widgets.dart';
import 'package:flutter_gen_ai_chat_ui/src/widgets/smart_chat_input.dart';
import 'package:flutter_gen_ai_chat_ui/src/widgets/streaming_text_animations.dart';

void main() {
  group('Timer lifecycle (dispose hazard) — iter 3 audit', () {
    testWidgets(
      'StreamingTextWidget does not leak its recursive step timer on dispose',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: StreamingTextWidget(
                text: 'Hello world this is a long streaming message',
                // Slow enough that the recursive Timer is definitely pending
                // when we unmount the widget below.
                config: StreamingAnimationConfig(
                  type: StreamingAnimationType.typewriter,
                  delay: Duration(seconds: 5),
                ),
              ),
            ),
          ),
        );
        // Let initState run and schedule the first recursive Timer.
        await tester.pump(const Duration(milliseconds: 10));

        // Unmount. If _stepTimer were untracked the next pump call would
        // hit `!timersPending` at teardown.
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'AnimatedBubble does not leak its start-delay timer on dispose',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AnimatedBubble(
                decoration: const BoxDecoration(),
                // Long delay so the start timer is still pending at unmount.
                delay: const Duration(seconds: 5),
                child: const Text('hi'),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 10));

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'CopilotTextarea does not leak its suggestion debounce timer on dispose',
      (tester) async {
        final controller = TextEditingController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CopilotTextarea(
                controller: controller,
              ),
            ),
          ),
        );

        // Typing >3 chars schedules the 500ms suggestion-fetch debounce.
        controller.text = 'hello world';
        await tester.pump();

        // Unmount well before the 500ms debounce fires. Untracked timer
        // would surface as a pending-timer failure on teardown.
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      },
    );
  });

  group('Frame callback lifecycle — iter 8 audit', () {
    // Iter 8 closed the dispose-hazard trilogy (iter 3 timers, iter 5 stream
    // subs, iter 8 frame callbacks). The hazard shape: a callback scheduled
    // via `addPostFrameCallback` during initState/build runs on the next
    // frame, which may be after the State is disposed. If the callback
    // touches `widget`, calls into a controller, or fires off a disposed
    // `FocusNode`, the framework throws. The fixes guard each callback
    // with `if (!mounted) return;` — these tests pin that behaviour.
    testWidgets(
      'SmartChatInput(autoFocus: true) disposed before next frame does not '
      'request focus on a disposed FocusNode',
      (tester) async {
        // Pump the widget — initState schedules a post-frame focus request.
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SmartChatInput(autoFocus: true),
            ),
          ),
        );

        // Immediately unmount BEFORE the frame callback fires. Without the
        // `if (!mounted) return;` guard, the callback would call
        // `_focusNode.requestFocus()` after `_focusNode.dispose()` and the
        // framework would throw "A FocusNode was used after being disposed".
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'CustomChatWidget connect-scroll post-frame callback no-ops after '
      'dispose',
      (tester) async {
        // Smoke test the higher-level entry point that wraps
        // CustomChatWidget — AiChatWidget — so the dispose-mid-build
        // scenario exercises the same `_connectScrollControllerToMessagesController`
        // path. Unmount before the post-frame scroll-to-bottom fires.
        final controller = ChatMessagesController(
          initialMessages: [
            ChatMessage(
              text: 'hello',
              user: const ChatUser(id: 'u', firstName: 'U'),
              createdAt: DateTime.now(),
            ),
          ],
        );
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AiChatWidget(
                currentUser: const ChatUser(id: 'u', firstName: 'U'),
                aiUser: const ChatUser(id: 'ai', firstName: 'AI'),
                controller: controller,
                onSendMessage: (_) {},
              ),
            ),
          ),
        );

        // Unmount before the post-frame scroll-to-bottom executes. Without
        // the `if (!mounted) return;` guard this could call into the
        // controller's scroll state after the underlying ScrollController
        // detaches, surfacing as a framework assertion.
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      },
    );
  });
}
