import 'package:flutter/material.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression coverage for `DESIGN.md` §8.10: with the package's DEFAULT
/// [ScrollToBottomOptions] (button not always-visible), a prior version of
/// `CustomChatWidget._effectiveMessageListPadding` unconditionally reserved
/// the scroll-to-bottom button's full footprint (bottomOffset + hit area =
/// 120px) at the bottom of the message list — even though that button is
/// hidden once scrolled within ~100px of the bottom (`DESIGN.md` says it
/// only shows past 200px). That permanently doubled the resting gap between
/// the last message and the composer from ~85px to ~197px in every default
/// chat, for a button nobody was looking at.
///
/// Fix: only widen the list's bottom padding when
/// [ScrollToBottomOptions.alwaysVisible] is true — the one case where the
/// button really can be showing at max scroll. The default (non-
/// `alwaysVisible`) case now uses the bare [ChatSpacingConfig.messageListPadding]
/// again, matching the package's pre-regression (857b47a) behaviour.
void main() {
  const currentUser = ChatUser(id: 'user1', firstName: 'User');
  const aiUser = ChatUser(id: 'ai', firstName: 'AI');

  ChatMessagesController buildController(int messageCount) {
    final controller = ChatMessagesController();
    final baseTime = DateTime(2026, 1, 1);
    for (var i = 0; i < messageCount; i++) {
      controller.addMessage(
        ChatMessage(
          text: 'Message number $i with some reasonably long content to '
              'fill horizontal space in the bubble.',
          user: i.isEven ? currentUser : aiUser,
          createdAt: baseTime.add(Duration(milliseconds: i)),
        ),
      );
    }
    return controller;
  }

  /// Scrolls the message list all the way to the newest message (the
  /// default `reverseOrder: true` list shows it at scroll offset
  /// `minScrollExtent`, not `maxScrollExtent`).
  Future<void> scrollToBottom(WidgetTester tester) async {
    final scrollable = tester.state<ScrollableState>(
      find.descendant(
        of: find.byType(ListView),
        matching: find.byType(Scrollable),
      ),
    );
    scrollable.position.jumpTo(scrollable.position.minScrollExtent);
    await tester.pumpAndSettle();
  }

  for (final size in [const Size(400, 800), const Size(1600, 1000)]) {
    for (final messageCount in [2, 30]) {
      testWidgets(
        'default scroll gap stays ~85px at ${size.width.toInt()}x'
        '${size.height.toInt()} with $messageCount messages',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);

          final controller = buildController(messageCount);
          addTearDown(controller.dispose);

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
          await tester.pumpAndSettle();
          await scrollToBottom(tester);

          final lastMessageFinder = find.textContaining(
            'Message number ${messageCount - 1}',
          );
          expect(lastMessageFinder, findsOneWidget);
          final composerFinder = find.byType(ChatInput);
          expect(composerFinder, findsOneWidget);

          final lastMessageBottom = tester.getBottomLeft(lastMessageFinder).dy;
          final composerTop = tester.getTopLeft(composerFinder).dy;
          final gap = composerTop - lastMessageBottom;

          expect(
            gap,
            inClosedOpenRange(40, 110),
            reason: 'Gap between the last message and the composer was '
                '${gap}px; expected roughly the pre-regression 85px '
                '(857b47a), not the ~197px the 230b5e2 regression produced '
                'by permanently reserving the (hidden) scroll button\'s '
                'footprint.',
          );
        },
      );
    }
  }

  testWidgets(
    'the scroll-to-bottom button sits ~12px above the composer when shown',
    (tester) async {
      final controller = buildController(30);
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 800,
              child: AiChatWidget(
                currentUser: currentUser,
                aiUser: aiUser,
                controller: controller,
                onSendMessage: (message) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll away from the bottom so the (non-alwaysVisible) button shows
      // (`DESIGN.md` §8.10: past ~200px from the bottom).
      final scrollable = tester.state<ScrollableState>(
        find.descendant(
          of: find.byType(ListView),
          matching: find.byType(Scrollable),
        ),
      );
      scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
      await tester.pumpAndSettle();

      // The painted 36px disc itself (not its 48px hit area, which pads
      // beyond the visual edge) — a DecoratedBox with a circular shape.
      final discFinder = find.byWidgetPredicate((widget) {
        if (widget is! DecoratedBox) return false;
        final decoration = widget.decoration;
        return decoration is BoxDecoration &&
            decoration.shape == BoxShape.circle &&
            decoration.border != null;
      });
      // `CustomChatWidget`'s own box ends exactly at the composer's top
      // edge (`AiChatWidget` places it in an `Expanded` immediately above
      // the composer) — this is "the composer" from this button's own
      // component's frame of reference. `find.byType(ChatInput)` sits a
      // further fixed 8px below that (an unrelated top padding
      // `AiChatWidget` applies around the composer card itself, present
      // before and after this fix), so it isn't what `bottomOffset` alone
      // can be measured against.
      final composerTopEdgeFinder = find.byType(CustomChatWidget);
      expect(discFinder, findsOneWidget);
      expect(composerTopEdgeFinder, findsOneWidget);

      final buttonBottom = tester.getBottomLeft(discFinder).dy;
      final composerTopEdge = tester.getBottomLeft(composerTopEdgeFinder).dy;
      final gap = composerTopEdge - buttonBottom;

      expect(
        gap,
        closeTo(12, 2),
        reason: 'Scroll-to-bottom button sat ${gap}px above the composer; '
            'DESIGN.md §8.10 wants 12px (±2), not the ~60px-higher '
            'regression.',
      );
    },
  );
}
