import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';

/// Issue #42, follow-up bug 1 (reported against 2.16.2 and 2.19.1): with
/// `pinDuringStreaming: StreamingPinAnchor.responseStart` the list "stops
/// scrolling at the right position, but it always scrolls a few pixels more
/// than required and then resets / scrolls back to the correct position. So
/// there is a kind of flickering." Also with `AutoScrollBehavior.never`.
///
/// In the default `reverse: true` list the scroll offset is measured from
/// the bottom, so every chunk that makes the answer taller moves its first
/// line up by exactly that growth while the offset stays put. The pin used to
/// undo that with a `jumpTo` from a `ScrollMetricsNotification` (dispatched
/// from a microtask after the frame) or a post-frame callback, i.e. only
/// after the frame showing the anchor too high had already been painted.
///
/// The other pin tests look at positions after a pair of pumps or a settle,
/// i.e. after that correction, which is why they never saw the flicker. These
/// tests record the anchor's position in every frame right after the
/// rendering pipeline ran: a persistent frame callback registered after the
/// binding's own one runs after build, layout and paint, but before the
/// post-frame callbacks and the microtasks that used to correct the position.
/// That is the frame the user actually sees.
void main() {
  const testUser = ChatUser(id: 'user', name: 'Test User');
  const aiUser = ChatUser(id: 'ai', name: 'AI Assistant');

  const responseProperties = {
    'id': 'resp1',
    'responseId': 'resp1',
    'isStartOfResponse': true,
  };

  String longAnswer(int lines) => List.generate(
        lines,
        (i) => 'Line $i of a very long streaming answer that keeps growing.',
      ).join('\n\n');

  Future<ChatMessagesController> pumpChat(
    WidgetTester tester, {
    required ScrollBehaviorConfig scrollConfig,
    bool enableMarkdownStreaming = false,
  }) async {
    final controller = ChatMessagesController(
      scrollBehaviorConfig: scrollConfig,
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
            enableMarkdownStreaming: enableMarkdownStreaming,
          ),
        ),
      ),
    );
    await tester.pump();
    return controller;
  }

  Future<void> askQuestion(
    WidgetTester tester,
    ChatMessagesController controller,
  ) async {
    controller.addMessage(
      ChatMessage(
        text: 'Hi',
        user: testUser,
        createdAt: DateTime.now(),
        customProperties: const {'id': 'u1', 'isUserMessage': true},
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  /// Streams [text] in [chunks] `updateMessage` calls flagged
  /// `isStreaming: true`, one 16 ms frame per chunk plus one more frame
  /// before the next chunk arrives.
  Future<void> streamWithFlags(
    WidgetTester tester,
    ChatMessagesController controller,
    String text, {
    required int chunks,
    int from = 1,
  }) async {
    for (var i = from; i <= chunks; i++) {
      final message = ChatMessage(
        text: text.substring(0, (text.length * i / chunks).floor()),
        user: aiUser,
        createdAt: DateTime.now(),
        customProperties: const {...responseProperties, 'isStreaming': true},
      );
      if (i == 1) {
        controller.addMessage(message);
      } else {
        controller.updateMessage(message);
      }
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  double viewportTop(WidgetTester tester) =>
      tester.getTopLeft(find.byType(ListView)).dy;

  ScrollPosition position(WidgetTester tester) =>
      tester.state<ScrollableState>(find.byType(Scrollable).first).position;

  group('streaming pin: no overshoot in any painted frame', () {
    testWidgets(
      'responseStart: the answer start is never painted above the viewport '
      'top while chunks arrive (isStreaming flags)',
      (tester) async {
        final controller = await pumpChat(
          tester,
          scrollConfig: const ScrollBehaviorConfig(
            pinDuringStreaming: StreamingPinAnchor.responseStart,
          ),
        );
        await askQuestion(tester, controller);

        final recorder = _PaintedTopRecorder('resp1', viewportTop(tester));
        addTearDown(recorder.stop);
        await streamWithFlags(tester, controller, longAnswer(240), chunks: 48);
        recorder.stop();

        // The scenario really reached the held state: the answer is far
        // taller than the viewport and its first line sits at the top.
        expect(controller.isStreamingPinActive, isTrue);
        expect(position(tester).pixels, greaterThan(1000));
        expect(recorder.gaps.last.abs(), lessThan(0.5));

        expect(
          recorder.minGap,
          greaterThanOrEqualTo(-0.5),
          reason: 'painted frames showed the answer start above the viewport '
              'top (overshoot, then a jump back): ${recorder.overshoots}',
        );
      },
    );

    testWidgets(
      'responseStart: no overshoot either with the addStreamingMessage flow, '
      'the default reveal animation and AutoScrollBehavior.never',
      (tester) async {
        final controller = await pumpChat(
          tester,
          scrollConfig: const ScrollBehaviorConfig(
            pinDuringStreaming: StreamingPinAnchor.responseStart,
            autoScrollBehavior: AutoScrollBehavior.never,
          ),
          enableMarkdownStreaming: true,
        );
        await askQuestion(tester, controller);

        final recorder = _PaintedTopRecorder('stream1', viewportTop(tester));
        addTearDown(recorder.stop);

        final text = longAnswer(90);
        final aiMessage = ChatMessage(
          text: '',
          user: aiUser,
          createdAt: DateTime.now(),
          customProperties: const {'id': 'stream1'},
        );
        const chunks = 15;
        for (var i = 1; i <= chunks; i++) {
          final chunk = aiMessage.copyWith(
            text: text.substring(0, (text.length * i / chunks).floor()),
          );
          if (i == 1) {
            controller.addStreamingMessage(chunk);
          } else {
            controller.updateMessage(chunk);
          }
          // A chunk every ~100 ms; the reveal animation grows the answer on
          // its own ticker in between.
          for (var f = 0; f < 6; f++) {
            await tester.pump(const Duration(milliseconds: 16));
          }
        }
        // Let the reveal catch up with the last chunk.
        for (var f = 0; f < 120; f++) {
          await tester.pump(const Duration(milliseconds: 16));
        }
        recorder.stop();

        expect(controller.isStreamingPinActive, isTrue);
        expect(position(tester).pixels, greaterThan(1000));
        expect(recorder.gaps.last.abs(), lessThan(0.5));
        expect(
          recorder.minGap,
          greaterThanOrEqualTo(-0.5),
          reason: 'painted frames showed the answer start above the viewport '
              'top: ${recorder.overshoots}',
        );
      },
    );

    testWidgets(
      'userMessage: the question is never painted above the viewport top',
      (tester) async {
        final controller = await pumpChat(
          tester,
          scrollConfig: const ScrollBehaviorConfig(
            pinDuringStreaming: StreamingPinAnchor.userMessage,
          ),
        );
        await askQuestion(tester, controller);

        final recorder = _PaintedTopRecorder('u1', viewportTop(tester));
        addTearDown(recorder.stop);
        await streamWithFlags(tester, controller, longAnswer(240), chunks: 48);
        recorder.stop();

        expect(controller.streamingPinAnchorMessageId, 'u1');
        expect(position(tester).pixels, greaterThan(1000));
        expect(recorder.gaps.last.abs(), lessThan(0.5));
        expect(
          recorder.minGap,
          greaterThanOrEqualTo(-0.5),
          reason: 'painted frames showed the question above the viewport '
              'top: ${recorder.overshoots}',
        );
      },
    );

    testWidgets(
      'after the reader takes over, the text they are reading does not jump '
      'in any painted frame as more chunks arrive',
      (tester) async {
        final controller = await pumpChat(
          tester,
          scrollConfig: const ScrollBehaviorConfig(
            pinDuringStreaming: StreamingPinAnchor.responseStart,
          ),
        );
        await askQuestion(tester, controller);
        final text = longAnswer(240);
        await streamWithFlags(tester, controller, text, chunks: 48);
        await tester.pump(const Duration(seconds: 1));

        // The reader drags the list to read further down the answer, which
        // hands the scroll position back to them for the rest of the answer.
        await tester.drag(find.byType(ListView), const Offset(0, -150));
        await tester.pump(const Duration(seconds: 2));
        expect(controller.isStreamingPinActive, isFalse);

        final top = viewportTop(tester);
        final start =
            tester.getTopLeft(find.byKey(const ValueKey('resp1'))).dy - top;
        final recorder = _PaintedTopRecorder('resp1', top);
        addTearDown(recorder.stop);

        final moreText = '$text\n\n${longAnswer(60)}';
        for (var i = 1; i <= 12; i++) {
          controller.updateMessage(
            ChatMessage(
              text: moreText.substring(
                0,
                text.length +
                    ((moreText.length - text.length) * i / 12).floor(),
              ),
              user: aiUser,
              createdAt: DateTime.now(),
              customProperties: const {
                ...responseProperties,
                'isStreaming': true,
              },
            ),
          );
          await tester.pump(const Duration(milliseconds: 16));
          await tester.pump(const Duration(milliseconds: 16));
        }
        recorder.stop();
        // Let the controller's 300 ms manual-scroll reset timer run out.
        await tester.pump(const Duration(seconds: 1));

        expect(controller.isStreamingPinActive, isFalse);
        final moved = recorder.gaps
            .map((g) => g - start)
            .where((d) => d.abs() > 0.5)
            .map((d) => d.toStringAsFixed(1))
            .toList();
        expect(
          moved,
          isEmpty,
          reason: 'painted frames moved the text the reader is looking at '
              '(px relative to where they left it)',
        );
      },
    );
  });
}

/// Records, for every frame the binding draws, how far [messageId]'s top
/// edge sits below the top of the chat list's viewport (negative: above it,
/// i.e. the anchor has been pushed out of view).
///
/// Persistent frame callbacks cannot be removed, so [stop] (also registered
/// as a tear-down) only deactivates it.
class _PaintedTopRecorder {
  _PaintedTopRecorder(this.messageId, this.viewportTop) {
    SchedulerBinding.instance.addPersistentFrameCallback(_onFrame);
  }

  final String messageId;
  final double viewportTop;
  final List<double> gaps = [];
  bool _active = true;

  void _onFrame(Duration _) {
    if (!_active) return;
    final elements =
        find.byKey(ValueKey<String>(messageId), skipOffstage: false).evaluate();
    for (final element in elements) {
      final box = element.renderObject;
      if (box is RenderBox && box.attached && box.hasSize) {
        gaps.add(box.localToGlobal(Offset.zero).dy - viewportTop);
      }
    }
  }

  void stop() => _active = false;

  double get minGap => gaps.isEmpty ? 0 : gaps.reduce(math.min);

  List<String> get overshoots =>
      gaps.where((g) => g < -0.5).map((g) => g.toStringAsFixed(1)).toList();
}
