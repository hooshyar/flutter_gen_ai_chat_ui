import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';

/// `ScrollBehaviorConfig.pinDuringStreaming` — the follow-up to issue #42.
///
/// The reporter's expected behaviour, verbatim:
///   1. I hit Go on my question
///   2. The AI starts answering and the screen starts scrolling
///   3. Now my question or the start of the AI's answer (should be definable)
///      should not scroll out of the viewport. The conditional
///      scroll-to-bottom button appears
///   4. Now I can read the answer and scroll to the end at my reading speed
///
/// These tests drive the real `AiChatWidget` through the public controller
/// API exactly the way a consumer streams an answer (`addMessage` with
/// `isStreaming: true`, repeated `updateMessage`, final update with
/// `isStreaming: false`), and assert on measured positions — never on
/// internal state alone.
void main() {
  const testUser = ChatUser(id: 'user', name: 'Test User');
  const aiUser = ChatUser(id: 'ai', name: 'AI Assistant');

  const responseProperties = {
    'id': 'resp1',
    'responseId': 'resp1',
    'isStartOfResponse': true,
  };

  final longAnswer = List.generate(
    300,
    (i) => 'Line $i of a very long streaming answer that keeps growing.',
  ).join('\n\n');

  Future<ChatMessagesController> pumpChat(
    WidgetTester tester, {
    required ScrollBehaviorConfig scrollConfig,
    bool reverseOrder = true,
  }) async {
    final paginationConfig = PaginationConfig(reverseOrder: reverseOrder);
    final controller = ChatMessagesController(
      scrollBehaviorConfig: scrollConfig,
      paginationConfig: paginationConfig,
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
            paginationConfig: paginationConfig,
            // Isolate scroll behaviour from the character-reveal animation.
            enableMarkdownStreaming: false,
          ),
        ),
      ),
    );
    await tester.pump();
    return controller;
  }

  /// Step 1: the user's question.
  Future<void> askQuestion(
      WidgetTester tester, ChatMessagesController controller) async {
    controller.addMessage(ChatMessage(
      text: 'Hi',
      user: testUser,
      createdAt: DateTime.now(),
      customProperties: const {'id': 'u1', 'isUserMessage': true},
    ));
    await tester.pump();
  }

  /// Step 2: the answer starts streaming and grows in [chunks] steps.
  Future<void> streamAnswer(
    WidgetTester tester,
    ChatMessagesController controller, {
    int chunks = 6,
    int from = 1,
    int upTo = 6,
  }) async {
    if (!controller.messages.any((m) => m.customProperties?['id'] == 'resp1')) {
      controller.addMessage(ChatMessage(
        text: '',
        user: aiUser,
        createdAt: DateTime.now(),
        customProperties: const {...responseProperties, 'isStreaming': true},
      ));
      await tester.pump();
    }
    for (var i = from; i <= upTo; i++) {
      final chunk =
          longAnswer.substring(0, (longAnswer.length * i / chunks).floor());
      controller.updateMessage(ChatMessage(
        text: chunk,
        user: aiUser,
        createdAt: DateTime.now(),
        customProperties: const {...responseProperties, 'isStreaming': true},
      ));
      // Two pumps: one frame for the rebuild, one for the post-frame /
      // scroll-metrics correction that the pin applies after layout.
      await tester.pump();
      await tester.pump();
    }
  }

  Future<void> finishAnswer(
      WidgetTester tester, ChatMessagesController controller) async {
    controller.updateMessage(ChatMessage(
      text: longAnswer,
      user: aiUser,
      createdAt: DateTime.now(),
      customProperties: const {...responseProperties, 'isStreaming': false},
    ));
    controller.stopStreamingMessage('resp1');
    await tester.pump();
    await tester.pump();
  }

  /// Drains every wall-clock Timer the controller's auto-scroll paths may
  /// have scheduled, so the assertion below sees the *settled* position and
  /// teardown never trips "Timer still pending".
  Future<void> settle(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  }

  double gapToViewportTop(WidgetTester tester, String messageId) {
    final viewportTop = tester.getTopLeft(find.byType(ListView)).dy;
    final top = tester.getTopLeft(find.byKey(ValueKey(messageId))).dy;
    return top - viewportTop;
  }

  ScrollPosition position(WidgetTester tester) =>
      tester.state<ScrollableState>(find.byType(Scrollable).first).position;

  group('pinDuringStreaming: none (default) — behaviour unchanged', () {
    testWidgets(
        'the bottom of the list keeps following the growing answer, so the '
        'top of a long answer scrolls out of view', (tester) async {
      final controller =
          await pumpChat(tester, scrollConfig: const ScrollBehaviorConfig());
      await askQuestion(tester, controller);
      await streamAnswer(tester, controller);
      await settle(tester);

      // Sanity: the answer is far taller than the viewport.
      expect(tester.getSize(find.byKey(const ValueKey('resp1'))).height,
          greaterThan(tester.getSize(find.byType(ListView)).height * 5));

      // Classic reverse-list behaviour: offset 0 == bottom visible.
      expect(position(tester).pixels, 0.0);
      expect(gapToViewportTop(tester, 'resp1'), lessThan(-100));
      expect(controller.isStreamingPinActive, isFalse);
    });
  });

  group('pinDuringStreaming: responseStart', () {
    const config = ScrollBehaviorConfig(
      pinDuringStreaming: StreamingPinAnchor.responseStart,
    );

    testWidgets(
        'while the answer is still short the list follows it as before '
        '(nothing is pinned prematurely)', (tester) async {
      final controller = await pumpChat(tester, scrollConfig: config);
      await askQuestion(tester, controller);
      controller.addMessage(ChatMessage(
        text: 'Short answer.',
        user: aiUser,
        createdAt: DateTime.now(),
        customProperties: const {...responseProperties, 'isStreaming': true},
      ));
      await tester.pump();
      await tester.pump();
      await settle(tester);

      expect(controller.isStreamingPinActive, isTrue);
      expect(position(tester).pixels, 0.0);
      // The answer's top is comfortably inside the viewport.
      expect(gapToViewportTop(tester, 'resp1'), greaterThan(0));
    });

    testWidgets(
        'once the answer outgrows the viewport its first line is held at '
        'the top and new text arrives below the fold', (tester) async {
      final controller = await pumpChat(tester, scrollConfig: config);
      await askQuestion(tester, controller);
      await streamAnswer(tester, controller);
      await settle(tester);

      expect(controller.isStreamingPinActive, isTrue);
      expect(controller.streamingPinAnchorMessageId, 'resp1');
      // Top of the answer aligned with the top of the viewport (small
      // tolerance for list padding / bubble chrome).
      expect(gapToViewportTop(tester, 'resp1').abs(), lessThan(40));
      // The reader is NOT at the bottom: the rest of the answer is below.
      expect(position(tester).pixels, greaterThan(100));
      final answerBottom =
          tester.getBottomLeft(find.byKey(const ValueKey('resp1'))).dy;
      final viewportBottom = tester.getBottomLeft(find.byType(ListView)).dy;
      expect(answerBottom, greaterThan(viewportBottom));
    });

    testWidgets('the scroll-to-bottom button appears while pinned',
        (tester) async {
      final controller = await pumpChat(tester, scrollConfig: config);
      await askQuestion(tester, controller);
      await streamAnswer(tester, controller);
      await settle(tester);

      expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
    });

    testWidgets('the pin keeps holding as more chunks arrive', (tester) async {
      final controller = await pumpChat(tester, scrollConfig: config);
      await askQuestion(tester, controller);
      await streamAnswer(tester, controller, chunks: 6, upTo: 3);
      await settle(tester);
      final gapAfterThree = gapToViewportTop(tester, 'resp1');
      expect(gapAfterThree.abs(), lessThan(40));

      await streamAnswer(tester, controller, chunks: 6, from: 4, upTo: 6);
      await settle(tester);
      expect(gapToViewportTop(tester, 'resp1').abs(), lessThan(40));
    });

    testWidgets('the end of the stream does not jump anywhere', (tester) async {
      final controller = await pumpChat(tester, scrollConfig: config);
      await askQuestion(tester, controller);
      await streamAnswer(tester, controller);
      await settle(tester);
      final pixelsBefore = position(tester).pixels;

      await finishAnswer(tester, controller);
      await settle(tester);

      expect(gapToViewportTop(tester, 'resp1').abs(), lessThan(40));
      expect(position(tester).pixels, closeTo(pixelsBefore, 1.0));
    });

    testWidgets(
        'end of stream still does not jump when scrollToFirstResponseMessage '
        'is also on (the pin already put the reader there)', (tester) async {
      final controller = await pumpChat(
        tester,
        scrollConfig: config.copyWith(scrollToFirstResponseMessage: true),
      );
      await askQuestion(tester, controller);
      await streamAnswer(tester, controller);
      await settle(tester);
      final pixelsBefore = position(tester).pixels;

      await finishAnswer(tester, controller);
      await settle(tester);

      expect(position(tester).pixels, closeTo(pixelsBefore, 1.0));
      expect(gapToViewportTop(tester, 'resp1').abs(), lessThan(40));
    });

    testWidgets('a user scroll gesture releases the pin for this answer',
        (tester) async {
      final controller = await pumpChat(tester, scrollConfig: config);
      await askQuestion(tester, controller);
      await streamAnswer(tester, controller, chunks: 6, upTo: 3);
      await settle(tester);
      expect(controller.isStreamingPinActive, isTrue);

      // The reader drags the list (reads further down the answer).
      await tester.drag(find.byType(ListView), const Offset(0, -150));
      await settle(tester);
      expect(controller.isStreamingPinActive, isFalse);
      final gapAfterDrag = gapToViewportTop(tester, 'resp1');
      final pixelsAfterDrag = position(tester).pixels;
      final maxAfterDrag = position(tester).maxScrollExtent;

      // More text arrives. The pin must NOT pull the list back up to the
      // answer's first line — and, this being a reverse list, the text the
      // reader is looking at must not be pushed away by the new chunks
      // either: the offset advances by exactly the growth, so the answer's
      // top stays where the reader left it.
      await streamAnswer(tester, controller, chunks: 6, from: 4, upTo: 6);
      await settle(tester);
      expect(controller.isStreamingPinActive, isFalse);
      final grown = position(tester).maxScrollExtent - maxAfterDrag;
      expect(grown, greaterThan(1000));
      expect(position(tester).pixels, closeTo(pixelsAfterDrag + grown, 1.0));
      expect(gapToViewportTop(tester, 'resp1'), closeTo(gapAfterDrag, 1.0));
    });

    testWidgets(
        'after a release at the very bottom the list keeps following the '
        'answer (no compensation there)', (tester) async {
      final controller = await pumpChat(tester, scrollConfig: config);
      await askQuestion(tester, controller);
      await streamAnswer(tester, controller, chunks: 6, upTo: 3);
      await settle(tester);

      await tester.tap(find.byIcon(Icons.keyboard_arrow_down));
      await settle(tester);
      expect(controller.isStreamingPinActive, isFalse);
      expect(position(tester).pixels, closeTo(0.0, 1.0));

      await streamAnswer(tester, controller, chunks: 6, from: 4, upTo: 6);
      await settle(tester);
      expect(position(tester).pixels, closeTo(0.0, 1.0));
    });

    testWidgets('tapping the scroll-to-bottom button releases the pin',
        (tester) async {
      final controller = await pumpChat(tester, scrollConfig: config);
      await askQuestion(tester, controller);
      await streamAnswer(tester, controller);
      await settle(tester);
      expect(controller.isStreamingPinActive, isTrue);

      await tester.tap(find.byIcon(Icons.keyboard_arrow_down));
      await settle(tester);

      expect(controller.isStreamingPinActive, isFalse);
      expect(position(tester).pixels, closeTo(0.0, 1.0));
    });

    testWidgets('the next question re-arms the pin for the next answer',
        (tester) async {
      final controller = await pumpChat(tester, scrollConfig: config);
      await askQuestion(tester, controller);
      await streamAnswer(tester, controller);
      await finishAnswer(tester, controller);
      await settle(tester);
      controller.releaseStreamingPin();
      expect(controller.isStreamingPinActive, isFalse);

      controller.addMessage(ChatMessage(
        text: 'Second question',
        user: testUser,
        createdAt: DateTime.now(),
        customProperties: const {'id': 'u2', 'isUserMessage': true},
      ));
      await tester.pump();
      await settle(tester);
      // (Whether the user message's own scroll-to-bottom fires here depends
      // on a wall-clock debounce that `pump` cannot advance — see the note
      // in scroll_to_first_response_single_message_test.dart — so only the
      // pin bookkeeping is asserted.)
      expect(controller.isStreamingPinActive, isFalse);

      controller.addMessage(ChatMessage(
        text: '',
        user: aiUser,
        createdAt: DateTime.now(),
        customProperties: const {
          'id': 'resp2',
          'responseId': 'resp2',
          'isStartOfResponse': true,
          'isStreaming': true,
        },
      ));
      await tester.pump();
      expect(controller.isStreamingPinActive, isTrue);
      expect(controller.streamingPinAnchorMessageId, 'resp2');
    });

    testWidgets('works for a chronological (reverseOrder: false) list too',
        (tester) async {
      final controller =
          await pumpChat(tester, scrollConfig: config, reverseOrder: false);
      await askQuestion(tester, controller);
      await streamAnswer(tester, controller);
      await settle(tester);

      expect(controller.isStreamingPinActive, isTrue);
      expect(gapToViewportTop(tester, 'resp1').abs(), lessThan(40));
      final answerBottom =
          tester.getBottomLeft(find.byKey(const ValueKey('resp1'))).dy;
      final viewportBottom = tester.getBottomLeft(find.byType(ListView)).dy;
      expect(answerBottom, greaterThan(viewportBottom));
    });
  });

  group('pinDuringStreaming with the addStreamingMessage flow', () {
    testWidgets(
        'arms and holds when the consumer streams via addStreamingMessage + '
        'updateMessage(text) + stopStreamingMessage, with no isStreaming flag',
        (tester) async {
      final controller = await pumpChat(
        tester,
        scrollConfig: const ScrollBehaviorConfig(
          pinDuringStreaming: StreamingPinAnchor.responseStart,
        ),
      );
      await askQuestion(tester, controller);

      final aiMessage = ChatMessage(
        text: '',
        user: aiUser,
        createdAt: DateTime.now(),
        customProperties: const {'id': 'stream1'},
      );
      controller.addStreamingMessage(aiMessage);
      await tester.pump();
      expect(controller.isStreamingPinActive, isTrue);
      expect(controller.streamingPinAnchorMessageId, 'stream1');

      for (var i = 1; i <= 6; i++) {
        controller.updateMessage(aiMessage.copyWith(
          text: longAnswer.substring(0, (longAnswer.length * i / 6).floor()),
        ));
        await tester.pump();
        await tester.pump();
      }
      await settle(tester);
      expect(gapToViewportTop(tester, 'stream1').abs(), lessThan(40));
      expect(position(tester).pixels, greaterThan(100));

      final pixelsBefore = position(tester).pixels;
      controller.stopStreamingMessage('stream1');
      await settle(tester);
      expect(position(tester).pixels, closeTo(pixelsBefore, 1.0));
    });
  });

  group('pinDuringStreaming: userMessage', () {
    const config = ScrollBehaviorConfig(
      pinDuringStreaming: StreamingPinAnchor.userMessage,
    );

    testWidgets("the user's question is held at the top of the viewport",
        (tester) async {
      final controller = await pumpChat(tester, scrollConfig: config);
      await askQuestion(tester, controller);
      await streamAnswer(tester, controller);
      await settle(tester);

      expect(controller.streamingPinAnchorMessageId, 'u1');
      expect(gapToViewportTop(tester, 'u1').abs(), lessThan(40));
      // The answer starts right below the question and continues off-screen.
      final answerTop =
          tester.getTopLeft(find.byKey(const ValueKey('resp1'))).dy;
      final questionBottom =
          tester.getBottomLeft(find.byKey(const ValueKey('u1'))).dy;
      expect(answerTop, greaterThanOrEqualTo(questionBottom - 1));
    });

    testWidgets('falls back to the answer start when there is no question',
        (tester) async {
      final controller = await pumpChat(tester, scrollConfig: config);
      await streamAnswer(tester, controller);
      await settle(tester);

      expect(controller.streamingPinAnchorMessageId, 'resp1');
      expect(gapToViewportTop(tester, 'resp1').abs(), lessThan(40));
    });
  });

  group('ScrollBehaviorConfig API compatibility', () {
    test('every constructor defaults pinDuringStreaming to none', () {
      expect(const ScrollBehaviorConfig().pinDuringStreaming,
          StreamingPinAnchor.none);
      expect(ScrollBehaviorConfig.smooth().pinDuringStreaming,
          StreamingPinAnchor.none);
      expect(ScrollBehaviorConfig.bouncy().pinDuringStreaming,
          StreamingPinAnchor.none);
      expect(ScrollBehaviorConfig.decelerate().pinDuringStreaming,
          StreamingPinAnchor.none);
      expect(ScrollBehaviorConfig.accelerate().pinDuringStreaming,
          StreamingPinAnchor.none);
      expect(ScrollBehaviorConfig.fast().pinDuringStreaming,
          StreamingPinAnchor.none);
    });

    test('named constructors accept pinDuringStreaming and copyWith keeps it',
        () {
      final c = ScrollBehaviorConfig.smooth(
          pinDuringStreaming: StreamingPinAnchor.userMessage);
      expect(c.pinDuringStreaming, StreamingPinAnchor.userMessage);
      expect(c.scrollAnimationCurve, Curves.easeInOutCubic);
      final copy = c.copyWith(scrollToFirstResponseMessage: true);
      expect(copy.pinDuringStreaming, StreamingPinAnchor.userMessage);
      expect(copy.scrollToFirstResponseMessage, isTrue);
      expect(
          copy
              .copyWith(pinDuringStreaming: StreamingPinAnchor.none)
              .pinDuringStreaming,
          StreamingPinAnchor.none);
    });

    test('controller pin API is a safe no-op without a pin', () {
      final controller = ChatMessagesController();
      addTearDown(controller.dispose);
      expect(controller.isStreamingPinActive, isFalse);
      expect(controller.streamingPinAnchorMessageId, isNull);
      controller.releaseStreamingPin();
      controller.maintainStreamingPin();
      expect(controller.isStreamingPinActive, isFalse);
    });
  });
}
