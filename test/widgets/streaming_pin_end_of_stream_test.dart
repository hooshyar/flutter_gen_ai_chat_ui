import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';

/// Issue #42, follow-up bug 2 (reported against 2.16.2 and 2.19.1): "Although
/// I use StreamingPinAnchor.responseStart, after the complete message is
/// delivered it scrolls back to the beginning of the question."
///
/// These tests drive a whole turn the way an app does it, through
/// `AiChatWidget` with the default reveal animation: the user's question,
/// `LoadingConfig(isLoading: true)` while the answer is generated (what the
/// example app and most integrations do, which shows the typing indicator
/// under the answer), the answer streamed in chunks through either streaming
/// flow, then the end of the stream and `isLoading: false`. They run under
/// the test's fake clock, so the controller's time-based scroll debounces
/// behave as they do in an app instead of swallowing every scroll.
///
/// After the stream has ended and everything settled, the first line of the
/// answer must still be at the top of the viewport and the question must
/// still be out of view.
void main() {
  const testUser = ChatUser(id: 'user', name: 'You');

  final longAnswer = List.generate(
    160,
    (i) => 'Line $i of a very long streaming answer that keeps growing.',
  ).join('\n\n');

  for (final flow in _Flow.values) {
    for (final aiId in const ['ai', 'assistant-42']) {
      for (final scrollToFirst in const [false, true]) {
        for (final typingIndicator in const [true, false]) {
          final name = '${flow.label}, aiUser id "$aiId", '
              'scrollToFirstResponseMessage: $scrollToFirst, '
              '${typingIndicator ? 'with' : 'without'} typing indicator';
          testWidgets(
            'responseStart ($name): the end of the stream leaves the answer '
            'start at the top',
            (tester) async {
              await withClock(tester.binding.clock, () async {
                final chat = await _Chat.pump(
                  tester,
                  aiUser: ChatUser(id: aiId, name: 'Assistant'),
                  currentUser: testUser,
                  scrollToFirstResponseMessage: scrollToFirst,
                );
                await chat.ask('What does the pin do?');
                if (typingIndicator) chat.loading.value = true;
                await chat.settle();

                await chat.stream(flow, longAnswer, chunks: 16);
                await chat.settle();
                final before = chat.snapshot();
                expect(
                  chat.controller.isStreamingPinActive,
                  isTrue,
                  reason: 'the pin should hold the answer: $before',
                );
                expect(before.answerGap.abs(), lessThan(0.5),
                    reason: '$before');

                await chat.finish(flow, longAnswer);
                if (typingIndicator) chat.loading.value = false;
                await chat.settle();
                final after = chat.snapshot();

                expect(
                  after.answerGap.abs(),
                  lessThan(0.5),
                  reason: 'the answer start must stay at the top after the '
                      'stream ends. before: $before, after: $after',
                );
                expect(
                  after.questionVisible,
                  isFalse,
                  reason: 'nothing may scroll back to the question. '
                      'before: $before, after: $after',
                );
              });
            },
          );
        }
      }
    }
  }

  for (final aiId in const ['ai', 'assistant-42']) {
    testWidgets(
      'responseStart + scrollToFirstResponseMessage, aiUser id "$aiId": '
      'after the reader takes over, the end of the stream does not scroll '
      'back to the answer start',
      (tester) async {
        await withClock(tester.binding.clock, () async {
          final chat = await _Chat.pump(
            tester,
            aiUser: ChatUser(id: aiId, name: 'Assistant'),
            currentUser: testUser,
            scrollToFirstResponseMessage: true,
          );
          await chat.ask('What does the pin do?');
          await chat.settle();
          await chat.stream(_Flow.flags, longAnswer, chunks: 16, upTo: 8);
          await chat.settle();

          // The reader scrolls down to read along at their own pace.
          await tester.drag(_chatList, const Offset(0, -300));
          await chat.settle();
          expect(chat.controller.isStreamingPinActive, isFalse);
          // Real time passes while they read (the controller's manual-scroll
          // flag is cleared on a wall-clock timer).
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 400)),
          );

          await chat.stream(
            _Flow.flags,
            longAnswer,
            chunks: 16,
            from: 9,
            upTo: 16,
          );
          await chat.settle();
          final before = chat.snapshot();

          await chat.finish(_Flow.flags, longAnswer);
          await chat.settle();
          final after = chat.snapshot();

          expect(
            (after.answerGap - before.answerGap).abs(),
            lessThan(1.0),
            reason: 'the text the reader is looking at must not move when '
                'the stream ends. before: $before, after: $after',
          );
        });
      },
    );
  }
}

/// The chat's own list. Markdown answers contain list views of their own
/// (`flutter_markdown_plus` renders a `Markdown` as a shrink-wrapped
/// `ListView`); the chat list is the outermost one.
final _chatList = find.byType(ListView).first;

enum _Flow {
  /// `addMessage`/`updateMessage` flagged `isStreaming: true`, closed by an
  /// update flagged `isStreaming: false` plus `stopStreamingMessage`.
  flags('isStreaming flags'),

  /// The example app's flow: `addStreamingMessage` with the first chunk,
  /// bare `updateMessage` calls, `stopStreamingMessage`.
  addStreamingMessage('addStreamingMessage');

  const _Flow(this.label);
  final String label;
}

class _Snapshot {
  _Snapshot(this.answerGap, this.questionGap, this.questionBottom, this.pixels);

  /// Top of the answer minus top of the viewport.
  final double answerGap;

  /// Top/bottom of the question minus top of the viewport, null when the
  /// question is not built.
  final double? questionGap;
  final double? questionBottom;
  final double pixels;

  bool get questionVisible => questionBottom != null && questionBottom! > 0.5;

  @override
  String toString() => '(answerGap ${answerGap.toStringAsFixed(1)}, '
      'questionTop ${questionGap?.toStringAsFixed(1)}, '
      'questionBottom ${questionBottom?.toStringAsFixed(1)}, '
      'pixels ${pixels.toStringAsFixed(1)})';
}

class _Chat {
  _Chat(this.tester, this.controller, this.loading, this.aiUser,
      this.currentUser);

  final WidgetTester tester;
  final ChatMessagesController controller;
  final ValueNotifier<bool> loading;
  final ChatUser aiUser;
  final ChatUser currentUser;

  static const answerId = 'answer1';
  static const questionId = 'q1';

  static Future<_Chat> pump(
    WidgetTester tester, {
    required ChatUser aiUser,
    required ChatUser currentUser,
    required bool scrollToFirstResponseMessage,
  }) async {
    final controller = ChatMessagesController();
    addTearDown(controller.dispose);
    final loading = ValueNotifier<bool>(false);
    addTearDown(loading.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: ValueListenableBuilder<bool>(
            valueListenable: loading,
            builder: (context, isLoading, _) => AiChatWidget(
              currentUser: currentUser,
              aiUser: aiUser,
              controller: controller,
              onSendMessage: (_) async {},
              loadingConfig: LoadingConfig(isLoading: isLoading),
              scrollBehaviorConfig: ScrollBehaviorConfig(
                pinDuringStreaming: StreamingPinAnchor.responseStart,
                scrollToFirstResponseMessage: scrollToFirstResponseMessage,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    return _Chat(tester, controller, loading, aiUser, currentUser);
  }

  Future<void> ask(String question) async {
    controller.addMessage(
      ChatMessage(
        text: question,
        user: currentUser,
        createdAt: DateTime.now(),
        customProperties: const {'id': questionId},
      ),
    );
    await tester.pump();
  }

  ChatMessage _answer(String text, {bool? isStreaming}) => ChatMessage(
        text: text,
        user: aiUser,
        createdAt: DateTime(2026, 1, 1),
        isMarkdown: true,
        customProperties: {
          'id': answerId,
          if (isStreaming != null) 'isStreaming': isStreaming,
        },
      );

  Future<void> stream(
    _Flow flow,
    String text, {
    required int chunks,
    int from = 1,
    int? upTo,
  }) async {
    for (var i = from; i <= (upTo ?? chunks); i++) {
      final chunk = text.substring(0, (text.length * i / chunks).floor());
      switch (flow) {
        case _Flow.flags:
          final message = _answer(chunk, isStreaming: true);
          if (i == 1) {
            controller.addMessage(message);
          } else {
            controller.updateMessage(message);
          }
        case _Flow.addStreamingMessage:
          final message = _answer(chunk);
          if (i == 1) {
            controller.addStreamingMessage(message);
          } else {
            controller.updateMessage(message);
          }
      }
      for (var f = 0; f < 5; f++) {
        await tester.pump(const Duration(milliseconds: 20));
      }
    }
  }

  Future<void> finish(_Flow flow, String text) async {
    if (flow == _Flow.flags) {
      controller.updateMessage(_answer(text, isStreaming: false));
    }
    controller.stopStreamingMessage(answerId);
    await tester.pump();
  }

  /// Bounded pumps instead of `pumpAndSettle`: while the answer is still
  /// streaming the live caret keeps animating forever.
  Future<void> settle() async {
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  _Snapshot snapshot() {
    final viewportTop = tester.getTopLeft(_chatList).dy;
    final answer = find.byKey(const ValueKey(answerId));
    final question = find.byKey(const ValueKey(questionId));
    final hasQuestion = question.evaluate().isNotEmpty;
    return _Snapshot(
      tester.getTopLeft(answer).dy - viewportTop,
      hasQuestion ? tester.getTopLeft(question).dy - viewportTop : null,
      hasQuestion ? tester.getBottomLeft(question).dy - viewportTop : null,
      tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .pixels,
    );
  }
}
