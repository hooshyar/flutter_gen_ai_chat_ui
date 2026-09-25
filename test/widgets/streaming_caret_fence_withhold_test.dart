import 'package:flutter/material.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';
import 'package:flutter_gen_ai_chat_ui/src/widgets/message/streaming_caret.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression coverage for the "stray bullet mid-stream" report: while
/// streaming the package example's async/await mock reply, a lone dot sat
/// directly under the "## Future Example" heading for the entire time its
/// fenced code block was being typed.
///
/// Root cause (confirmed by instrumenting the real widget tree, not just
/// re-implementing the withhold regexes in isolation — see round-6 build
/// notes): it is NOT a dangling markdown list/heading marker slipping past
/// `_withholdDanglingMarker`. Exhaustively checking every prefix of this
/// exact mock reply through `_withholdDanglingMarker` +
/// `_withholdIncompleteFence` (piped through `package:markdown` with the
/// GitHub-flavored extension set `flutter_markdown_plus` itself uses)
/// never produces an empty `<li>`/bare heading for this text.
///
/// The actual culprit is `StreamingCaret`: `_buildAiFooter` used to render
/// it unconditionally while `isStreaming`, "below the last block,
/// start-aligned" per `DESIGN.md` §8.9. A fenced code block renders as
/// *nothing* until its closing fence arrives (`_withholdIncompleteFence`
/// withholds the whole thing while the fence count is odd) — so for the
/// entire time a block is being generated, every new revealed-text prefix
/// gets trimmed back to the exact same point (right before the open
/// fence), and the caret sits frozen at that one spot, immediately under
/// whatever preceded the fence (here, the "Future Example" heading) even
/// though the underlying message keeps growing. In a screenshot that reads
/// exactly like an orphaned bullet under the heading.
void main() {
  const messageId = 'async_await_probe';

  // Exact mock reply from example/lib/services/mock_ai_service.dart's
  // "async"/"await" branch (the "Explain async/await with an example"
  // reproduction from the bug report).
  const fullText = '# Async/Await in Dart\n\n'
      'Dart uses `Future` for async operations and `Stream` for '
      'sequences of async events.\n\n'
      '## Future Example\n'
      '```dart\n'
      'Future<String> fetchUser() async {\n'
      '  final response = await http.get(\n'
      '    Uri.parse(\'https://api.example.com/user\'),\n'
      '  );\n'
      '  return response.body;\n'
      '}\n'
      '```\n\n'
      '## Error Handling\n'
      '```dart\n'
      'try {\n'
      '  final user = await fetchUser();\n'
      '  print(user);\n'
      '} on SocketException {\n'
      '  print(\'No internet\');\n'
      '} catch (e) {\n'
      '  print(\'Error: \$e\');\n'
      '}\n'
      '```\n\n'
      '**Key rules:**\n'
      '- Mark functions `async` to use `await`\n'
      '- `await` pauses execution until the `Future` completes\n'
      '- Always handle errors with `try/catch`\n';

  testWidgets(
    'live caret does not sit frozen in place while a fenced code block is '
    'withheld mid-stream (the "stray bullet under a heading" defect)',
    (tester) async {
      final controller = ChatMessagesController();
      final currentUser = ChatUser(id: 'user1', firstName: 'User');
      final aiUser = ChatUser(id: 'ai', firstName: 'AI');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AiChatWidget(
              currentUser: currentUser,
              aiUser: aiUser,
              controller: controller,
              onSendMessage: (message) {},
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
          isMarkdown: true,
          customProperties: {'id': messageId},
        ),
      );
      await tester.pump();

      var accumulated = '';
      double? lastRelativeGap;
      var frozenStreak = 0;
      var maxFrozenStreak = 0;
      var lastAccumulatedLenAtFreeze = 0;
      final headingFinder = find.textContaining('Future Example');

      for (final word in fullText.split(' ')) {
        accumulated += (accumulated.isEmpty ? '' : ' ') + word;
        controller.updateMessage(
          ChatMessage(
            text: accumulated,
            user: aiUser,
            createdAt: DateTime.now(),
            isMarkdown: true,
            customProperties: {'id': messageId},
          ),
        );
        await tester.pump(const Duration(milliseconds: 30));

        final caretFinder = find.byType(StreamingCaret);
        if (caretFinder.evaluate().isEmpty ||
            headingFinder.evaluate().isEmpty) {
          // No caret, or the heading hasn't revealed yet — the "frozen in
          // one spot" streak can't continue without both reference points.
          lastRelativeGap = null;
          frozenStreak = 0;
          continue;
        }

        // Measure the caret's position RELATIVE to the (also-scrolling)
        // "Future Example" heading, not either widget's absolute screen Y
        // — the list auto-scrolls to keep the actively-streaming message's
        // tail pinned near the same viewport position, which would make an
        // absolute-Y check falsely report "frozen" during completely
        // normal, continuously-growing reveal too (both the heading and
        // the caret drift up together under auto-scroll). The gap BETWEEN
        // them only stays constant across frames when nothing is actually
        // being added between the heading and the caret — exactly the
        // "withheld" signature the bug report describes.
        final headingY = tester.getBottomLeft(headingFinder.first).dy;
        final caretY = tester.getTopLeft(caretFinder.first).dy;
        final relativeGap = caretY - headingY;
        if (lastRelativeGap != null && relativeGap == lastRelativeGap) {
          frozenStreak++;
        } else {
          frozenStreak = 0;
        }
        lastRelativeGap = relativeGap;
        if (frozenStreak > maxFrozenStreak) {
          maxFrozenStreak = frozenStreak;
          lastAccumulatedLenAtFreeze = accumulated.length;
        }
      }

      controller.stopStreamingMessage(messageId);
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      // Before the fix, the caret sits at the exact same Y position for
      // the entire ~20-word "Future Example" fence (frozen while the
      // message keeps growing underneath it) — a long streak. After the
      // fix, the caret is hidden for that whole window instead, so no
      // long "stuck in place" streak can build up.
      expect(
        maxFrozenStreak < 5,
        isTrue,
        reason: 'Live caret stayed pinned at the same position for '
            '$maxFrozenStreak consecutive streamed words (message had grown '
            'to $lastAccumulatedLenAtFreeze chars by then) — it is frozen '
            'in place under a heading while later content is withheld, '
            'reading as a stray bullet in a single-frame screenshot.',
      );
    },
  );

  testWidgets(
    'live caret still renders normally while streaming plain prose with no '
    'open fence',
    (tester) async {
      final controller = ChatMessagesController();
      final currentUser = ChatUser(id: 'user1', firstName: 'User');
      final aiUser = ChatUser(id: 'ai', firstName: 'AI');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AiChatWidget(
              currentUser: currentUser,
              aiUser: aiUser,
              controller: controller,
              onSendMessage: (message) {},
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
          isMarkdown: true,
          customProperties: {'id': messageId},
        ),
      );
      await tester.pump();

      controller.updateMessage(
        ChatMessage(
          text: 'Plain prose with no fence, still streaming',
          user: aiUser,
          createdAt: DateTime.now(),
          isMarkdown: true,
          customProperties: {'id': messageId},
        ),
      );
      await tester.pump(const Duration(milliseconds: 30));
      await tester.pump(const Duration(milliseconds: 60));

      // No fence is open here, so the caret must still render while
      // streaming — the fix only suppresses it during an actively
      // withheld fence, not generally.
      expect(find.byType(StreamingCaret), findsOneWidget);

      controller.stopStreamingMessage(messageId);
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(find.byType(StreamingCaret), findsNothing);
    },
  );
}
