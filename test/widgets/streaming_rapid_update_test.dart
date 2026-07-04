import 'package:flutter/material.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Streaming rapid-update regression', () {
    late ChatMessagesController controller;
    late ChatUser currentUser;
    late ChatUser aiUser;

    setUp(() {
      controller = ChatMessagesController();
      currentUser = ChatUser(id: 'user1', firstName: 'User');
      aiUser = ChatUser(id: 'ai', firstName: 'AI');
    });

    testWidgets(
        'updateMessage calls faster than the typing speed should still show '
        'gradual progress, not a starved animation that dumps all the text '
        'at once once the stream stops', (WidgetTester tester) async {
      const messageId = 'rapid_stream_msg';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AiChatWidget(
              currentUser: currentUser,
              aiUser: aiUser,
              controller: controller,
              onSendMessage: (message) {},
              enableAnimation: true,
              enableMarkdownStreaming: true,
              streamingWordByWord: false,
              // Default-ish typing speed. The mock/demo pattern this
              // reproduces feeds new text roughly every 12-38ms, which is
              // comparable to or faster than this.
              streamingDuration: const Duration(milliseconds: 30),
            ),
          ),
        ),
      );
      await tester.pump();

      controller.addStreamingMessage(
        ChatMessage(
          text: '',
          user: aiUser,
          createdAt: DateTime.now(),
          isMarkdown: false,
          customProperties: {'id': messageId},
        ),
      );

      final words = List.generate(30, (i) => 'word$i');
      var accumulated = '';

      // Feed updates faster than the typing speed, like a real streaming
      // source delivering chunks quickly — this is what starved the
      // animation before the fix.
      for (final word in words) {
        accumulated += (accumulated.isEmpty ? '' : ' ') + word;
        controller.updateMessage(
          ChatMessage(
            text: accumulated,
            user: aiUser,
            createdAt: DateTime.now(),
            isMarkdown: false,
            customProperties: {'id': messageId},
          ),
        );
        await tester.pump(const Duration(milliseconds: 15));
      }

      // While still mid-stream, the animation must already be showing
      // gradual progress: the first word visible, but not yet caught up to
      // the very last word. Before the fix this failed because every
      // rapid update cancelled the in-flight typing timer before it could
      // ever tick, so nothing rendered until the stream stopped.
      expect(find.textContaining('word0'), findsOneWidget);
      expect(find.textContaining('word29'), findsNothing);

      controller.stopStreamingMessage(messageId);
      await tester.pump();

      // Let the animation play out fully.
      for (var i = 0; i < 400; i++) {
        await tester.pump(const Duration(milliseconds: 30));
      }

      expect(find.textContaining('word29'), findsOneWidget);

      // Drain the post-render scroll timer scheduled by addMessage.
      await tester.pump(const Duration(milliseconds: 350));
    });

    testWidgets(
        'stopping the stream while the throttled hand-off lags must not '
        'snap the full remaining text in at once', (WidgetTester tester) async {
      const messageId = 'snap_race_msg';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AiChatWidget(
              currentUser: currentUser,
              aiUser: aiUser,
              controller: controller,
              onSendMessage: (message) {},
              enableAnimation: true,
              enableMarkdownStreaming: true,
              streamingWordByWord: false,
              // Very fast typing: the animation catches up to each throttled
              // hand-off almost immediately, so StreamingText fires
              // onComplete repeatedly while the hand-off still lags the full
              // text. The regression: treating one of those onCompletes
              // (after the data stopped) as terminal swapped in the full
              // static text in a single frame.
              streamingDuration: const Duration(milliseconds: 1),
            ),
          ),
        ),
      );
      await tester.pump();

      controller.addStreamingMessage(
        ChatMessage(
          text: '',
          user: aiUser,
          createdAt: DateTime.now(),
          isMarkdown: false,
          customProperties: {'id': messageId},
        ),
      );

      final words = List.generate(30, (i) => 'word$i');
      var accumulated = '';
      for (final word in words) {
        accumulated += (accumulated.isEmpty ? '' : ' ') + word;
        controller.updateMessage(
          ChatMessage(
            text: accumulated,
            user: aiUser,
            createdAt: DateTime.now(),
            isMarkdown: false,
            customProperties: {'id': messageId},
          ),
        );
        await tester.pump(const Duration(milliseconds: 20));
      }

      // Data ends here. The throttle only flushes every ~120ms, so the text
      // handed to the animation is still several words behind 'word29'.
      controller.stopStreamingMessage(messageId);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 30));

      // Immediately after the stop, the tail must NOT be visible yet — the
      // animation still has pending hand-offs to type through. Before the
      // fix this failed: the first post-stop onComplete marked the message
      // done and the static full text (including word29) appeared here.
      expect(find.textContaining('word29'), findsNothing,
          reason: 'Remaining text snapped in immediately after the stream '
              'stopped instead of finishing the typing animation');

      // Let the remaining flushes + animation play out; the full text must
      // eventually appear.
      for (var i = 0; i < 100; i++) {
        await tester.pump(const Duration(milliseconds: 40));
      }
      expect(find.textContaining('word29'), findsOneWidget);

      // Drain the post-render scroll timer scheduled by addMessage.
      await tester.pump(const Duration(milliseconds: 350));
    });
  });
}
