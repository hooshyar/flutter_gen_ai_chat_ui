import 'package:flutter/material.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression coverage for "scroll-to-bottom button covering the last
/// content": with the package's default (small) `messageListPadding`, the
/// floating scroll-to-bottom button's disc landed inside the last
/// message's own vertical span at max scroll, rather than in reserved
/// empty space below it.
///
/// Fix: `CustomChatWidget._effectiveMessageListPadding` widens the list's
/// bottom padding, when needed, to clear the button's full footprint
/// (`ScrollToBottomOptions.bottomOffset` + `ScrollToBottomButton.hitAreaSize`).
void main() {
  const currentUser = ChatUser(id: 'user1', firstName: 'User');
  const aiUser = ChatUser(id: 'ai', firstName: 'AI');

  testWidgets(
    'the last message never renders underneath the scroll-to-bottom '
    'button at max scroll',
    (tester) async {
      final controller = ChatMessagesController();
      final baseTime = DateTime(2026, 1, 1);
      for (var i = 0; i < 20; i++) {
        controller.addMessage(
          ChatMessage(
            text: 'Message number $i with some reasonably long content to '
                'fill space.',
            user: i.isEven ? currentUser : aiUser,
            // Explicit, strictly-increasing timestamps (rather than
            // DateTime.now() in a tight loop): the controller generates a
            // message id from user id + millisecond timestamp, so two
            // same-user messages created within the same millisecond would
            // collide and silently drop one — flaky depending on how fast
            // this loop happens to run.
            createdAt: baseTime.add(Duration(milliseconds: i)),
          ),
        );
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 600,
              child: AiChatWidget(
                currentUser: currentUser,
                aiUser: aiUser,
                controller: controller,
                onSendMessage: (message) {},
                // alwaysVisible mirrors the real defect: the button can be
                // shown at/near max scroll (e.g. the "new content below"
                // dot while streaming with the pin released, `DESIGN.md`
                // §8.10) — not just when far from the bottom.
                scrollToBottomOptions:
                    const ScrollToBottomOptions(alwaysVisible: true),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll to the very bottom. The default `reverseOrder: true` list
      // shows the newest message at the bottom already at scroll offset 0
      // — `minScrollExtent`, not `maxScrollExtent`, which scrolls up to
      // the oldest message instead. Locate the message list's own
      // Scrollable specifically (not `.first`, which can grab an
      // unrelated Scrollable — e.g. the composer's internal EditableText).
      final scrollable = tester.state<ScrollableState>(
        find.descendant(
          of: find.byType(ListView),
          matching: find.byType(Scrollable),
        ),
      );
      scrollable.position.jumpTo(scrollable.position.minScrollExtent);
      await tester.pumpAndSettle();

      final lastMessageFinder = find.textContaining('Message number 19');
      final buttonFinder = find.byIcon(Icons.arrow_downward_rounded);
      expect(lastMessageFinder, findsOneWidget);
      expect(buttonFinder, findsOneWidget);

      final lastMessageBottom = tester.getBottomLeft(lastMessageFinder).dy;
      final buttonTop = tester.getTopLeft(buttonFinder).dy;

      expect(
        buttonTop,
        greaterThanOrEqualTo(lastMessageBottom),
        reason: 'Scroll-to-bottom button (top at $buttonTop) overlaps the '
            'last message (bottom at $lastMessageBottom) at max scroll — '
            'it should sit in reserved space below the message instead.',
      );
    },
  );
}
