import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';

/// How the two ways of taking over from a streaming pin differ (issue #42
/// follow-up review), and what app code listening to the list still sees.
///
/// * A scroll GESTURE releases the pin: the reader reads at their own pace
///   and the end of that answer does not scroll anywhere (covered in
///   streaming_pin_end_of_stream_test.dart and streaming_pin_test.dart).
/// * The scroll-to-bottom BUTTON ends the pin for that answer: the list
///   follows the rest of it, and whatever comes after it, exactly as it
///   would without a pin.
void main() {
  const testUser = ChatUser(id: 'user', name: 'You');
  const aiUser = ChatUser(id: 'ai', name: 'AI');

  final longAnswer = List.generate(
    160,
    (i) => 'Line $i of a very long streaming answer that keeps growing.',
  ).join('\n\n');

  final chatList = find.byType(ListView).first;
  final scrollToBottomButton = find.byIcon(Icons.arrow_downward_rounded);

  ScrollPosition position(WidgetTester tester) =>
      tester.state<ScrollableState>(find.byType(Scrollable).first).position;

  double gapToViewportTop(WidgetTester tester, String id) =>
      tester.getTopLeft(find.byKey(ValueKey(id))).dy -
      tester.getTopLeft(chatList).dy;

  Future<ChatMessagesController> pumpChat(
    WidgetTester tester, {
    required ScrollBehaviorConfig config,
    required bool reverseOrder,
    bool reduceMotion = false,
    Widget Function(Widget chat)? wrap,
  }) async {
    final paginationConfig = PaginationConfig(reverseOrder: reverseOrder);
    final controller = ChatMessagesController(
      scrollBehaviorConfig: config,
      paginationConfig: paginationConfig,
    );
    addTearDown(controller.dispose);

    Widget chat = AiChatWidget(
      currentUser: testUser,
      aiUser: aiUser,
      controller: controller,
      onSendMessage: (_) async {},
      paginationConfig: paginationConfig,
      enableMarkdownStreaming: false,
    );
    if (reduceMotion) {
      final inner = chat;
      chat = Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: inner,
        ),
      );
    }
    if (wrap != null) chat = wrap(chat);

    await tester.pumpWidget(
      MaterialApp(key: UniqueKey(), home: Material(child: chat)),
    );
    await tester.pump();
    return controller;
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> ask(
    WidgetTester tester,
    ChatMessagesController controller,
  ) async {
    controller.addMessage(
      ChatMessage(
        text: 'What does the pin do?',
        user: testUser,
        createdAt: DateTime.now(),
        customProperties: const {'id': 'u1'},
      ),
    );
    await tester.pump();
    await settle(tester);
  }

  ChatMessage answer(int chunk, {bool streaming = true}) => ChatMessage(
        text: longAnswer.substring(0, (longAnswer.length * chunk / 16).floor()),
        user: aiUser,
        createdAt: DateTime(2026, 1, 1),
        customProperties: {'id': 'resp1', 'isStreaming': streaming},
      );

  /// Streams chunks [from]..[to] of 16 (`isStreaming` flags), pumping
  /// [framesPerChunk] 16 ms frames after each.
  Future<void> stream(
    WidgetTester tester,
    ChatMessagesController controller, {
    required int from,
    required int to,
    int framesPerChunk = 4,
  }) async {
    for (var i = from; i <= to; i++) {
      if (i == 1) {
        controller.addMessage(answer(i));
      } else {
        controller.updateMessage(answer(i));
      }
      for (var f = 0; f < framesPerChunk; f++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
    }
  }

  Future<void> finish(
    WidgetTester tester,
    ChatMessagesController controller,
  ) async {
    controller.updateMessage(answer(16, streaming: false));
    controller.stopStreamingMessage('resp1');
    await tester.pump();
    await settle(tester);
  }

  testWidgets(
    'chronological list: after the scroll-to-bottom button ends the pin, the '
    'rest of the turn (end of the answer, a tool-result card, a loading '
    'placeholder turning into a rich result) scrolls exactly as without a '
    'pin',
    (tester) async {
      await withClock(tester.binding.clock, () async {
        // The same turn with and without a pin. scrollToFirstResponseMessage
        // with AutoScrollBehavior.always is the configuration in which the
        // controller scrolls for AI content (back to the answer's first
        // message); zero-length scroll animations and reduced motion (the
        // button then jumps) keep the controller's manual-scroll detection,
        // which any scroll animation trips, out of the comparison.
        Future<List<String>> runTurn(StreamingPinAnchor anchor) async {
          final controller = await pumpChat(
            tester,
            config: ScrollBehaviorConfig(
              pinDuringStreaming: anchor,
              scrollToFirstResponseMessage: true,
              autoScrollBehavior: AutoScrollBehavior.always,
              scrollAnimationDuration: Duration.zero,
            ),
            reverseOrder: false,
            reduceMotion: true,
          );
          final checkpoints = <String>[];
          void checkpoint(String name) {
            final p = position(tester);
            checkpoints.add(
              '$name: pixels ${p.pixels.toStringAsFixed(1)}, '
              'max ${p.maxScrollExtent.toStringAsFixed(1)}',
            );
          }

          await ask(tester, controller);
          await stream(tester, controller, from: 1, to: 8);
          await settle(tester);
          checkpoint('mid-answer');

          await tester.tap(scrollToBottomButton);
          await tester.pump();
          await settle(tester);
          expect(controller.isStreamingPinActive, isFalse);
          expect(
            position(tester).pixels,
            closeTo(position(tester).maxScrollExtent, 0.5),
          );
          checkpoint('after the button');

          await stream(tester, controller, from: 9, to: 16);
          await settle(tester);
          // The pin is not armed again for this answer.
          expect(controller.isStreamingPinActive, isFalse);
          checkpoint('rest of the answer streamed');

          await finish(tester, controller);
          checkpoint('end of the answer');

          final p = position(tester);
          p.jumpTo(p.maxScrollExtent);
          await settle(tester);
          controller.addMessage(
            ChatMessage.rich(
              user: aiUser,
              resultKind: 'tool_result',
              data: const {'ok': true},
              id: 'card1',
              text: 'Tool result',
            ),
          );
          await tester.pump();
          await settle(tester);
          checkpoint('tool-result card');

          controller.addMessage(
            ChatMessage.loading(user: aiUser, id: 'morph1', text: 'Working'),
          );
          await tester.pump();
          await settle(tester);
          p.jumpTo(p.maxScrollExtent);
          await settle(tester);
          controller.updateMessage(
            ChatMessage.rich(
              user: aiUser,
              resultKind: 'tool_result',
              data: const {'ok': true},
              id: 'morph1',
              text: 'Done',
            ),
          );
          await tester.pump();
          await settle(tester);
          checkpoint('loading turned into a rich result');
          return checkpoints;
        }

        final withoutPin = await runTurn(StreamingPinAnchor.none);
        final withPin = await runTurn(StreamingPinAnchor.responseStart);

        expect(withPin.skip(1), withoutPin.skip(1));
        // And those scrolls really ran: at the end of the answer the list
        // went back to the answer's first message.
        expect(gapToViewportTop(tester, 'resp1').abs(), lessThan(1.0));
      });
    },
  );

  testWidgets(
    'reverse list: after the scroll-to-bottom button the list reaches the '
    'bottom and follows the answer there to its end, even when chunks keep '
    'arriving while it scrolls down',
    (tester) async {
      await withClock(tester.binding.clock, () async {
        final controller = await pumpChat(
          tester,
          config: const ScrollBehaviorConfig(
            pinDuringStreaming: StreamingPinAnchor.responseStart,
          ),
          reverseOrder: true,
        );
        await ask(tester, controller);
        await stream(tester, controller, from: 1, to: 6);
        await settle(tester);
        expect(controller.isStreamingPinActive, isTrue);
        expect(position(tester).pixels, greaterThan(1000));

        await tester.tap(scrollToBottomButton);
        await tester.pump();
        // Chunks keep arriving during the button's scroll animation.
        await stream(tester, controller, from: 7, to: 10, framesPerChunk: 5);
        await settle(tester);
        expect(controller.isStreamingPinActive, isFalse);
        expect(
          position(tester).pixels,
          closeTo(0.0, 0.5),
          reason: 'the list must have reached the bottom',
        );

        for (var i = 11; i <= 16; i++) {
          await stream(tester, controller, from: i, to: i);
          expect(
            position(tester).pixels,
            closeTo(0.0, 0.5),
            reason: 'the list must keep following the answer (chunk $i)',
          );
        }
        await finish(tester, controller);
        expect(controller.isStreamingPinActive, isFalse);
        expect(position(tester).pixels, closeTo(0.0, 0.5));
      });
    },
  );

  testWidgets(
    'scroll notifications are dispatched for the moves the pin makes during '
    'layout (as they were for its former post-frame jumpTo)',
    (tester) async {
      var updates = 0;
      var starts = 0;
      var ends = 0;
      var delta = 0.0;
      final controller = await pumpChat(
        tester,
        config: const ScrollBehaviorConfig(
          pinDuringStreaming: StreamingPinAnchor.responseStart,
        ),
        reverseOrder: true,
        wrap: (chat) => NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            // Only the chat list (the composer has a scrollable too).
            if (notification.metrics.axisDirection != AxisDirection.up) {
              return false;
            }
            if (notification is ScrollStartNotification) starts++;
            if (notification is ScrollEndNotification) ends++;
            if (notification is ScrollUpdateNotification) {
              updates++;
              delta += notification.scrollDelta ?? 0;
            }
            return false;
          },
          child: chat,
        ),
      );
      await ask(tester, controller);
      final start = position(tester).pixels;
      updates = 0;
      starts = 0;
      ends = 0;
      delta = 0;

      await stream(tester, controller, from: 1, to: 16);
      await settle(tester);

      expect(controller.isStreamingPinActive, isTrue);
      final moved = position(tester).pixels - start;
      expect(moved, greaterThan(1000));
      expect(updates, greaterThan(0));
      expect(starts, updates);
      expect(ends, updates);
      expect(delta, closeTo(moved, 1.0));
    },
  );
}
