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

  /// Scrolls the message list fully AWAY from the newest message (the
  /// default `reverseOrder: true` list scrolls up towards `maxScrollExtent`),
  /// which is what makes the (non-`alwaysVisible`) scroll-to-bottom button
  /// appear.
  Future<void> scrollAwayFromBottom(WidgetTester tester) async {
    final scrollable = tester.state<ScrollableState>(
      find.descendant(
        of: find.byType(ListView),
        matching: find.byType(Scrollable),
      ),
    );
    scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
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

  /// The painted 36px disc itself (not its 48px hit area, which pads beyond
  /// the visual edge) — a `DecoratedBox` with a circular shape.
  Finder discFinder() => find.byWidgetPredicate((widget) {
        if (widget is! DecoratedBox) return false;
        final decoration = widget.decoration;
        return decoration is BoxDecoration &&
            decoration.shape == BoxShape.circle &&
            decoration.border != null;
      });

  testWidgets(
    'the scroll-to-bottom button sits ~12px above the composer\'s visible '
    'container when shown',
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
      await scrollAwayFromBottom(tester);

      // The composer's actual VISIBLE container — `ChatInput`'s own rounded,
      // bordered `AnimatedContainer` — not `CustomChatWidget`'s box, which
      // (with quick replies showing) no longer ends at the composer at all.
      final composerFinder = find.byType(ChatInput);
      expect(discFinder(), findsOneWidget);
      expect(composerFinder, findsOneWidget);

      final buttonBottom = tester.getBottomLeft(discFinder()).dy;
      final composerTop = tester.getTopLeft(composerFinder).dy;
      final gap = composerTop - buttonBottom;

      expect(
        gap,
        closeTo(12, 2),
        reason: 'Scroll-to-bottom button sat ${gap}px above the composer\'s '
            'visible container; DESIGN.md §8.10 wants 12px (±2).',
      );
    },
  );

  group('scroll-to-bottom button never covers quick-reply chips', () {
    for (final size in [const Size(400, 800), const Size(1600, 1000)]) {
      testWidgets(
        'at ${size.width.toInt()}x${size.height.toInt()}, hit area does '
        'not overlap any chip and taps reach the chips',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);

          final controller = buildController(30);
          addTearDown(controller.dispose);

          const quickReplies = [
            'Option one',
            'Option two',
            'Option three',
            'Option four',
            'Option five',
          ];
          final tapped = <String>[];

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: AiChatWidget(
                  currentUser: currentUser,
                  aiUser: aiUser,
                  controller: controller,
                  onSendMessage: (message) {},
                  quickReplyOptions: QuickReplyOptions(
                    quickReplies: quickReplies,
                    onQuickReplyTap: tapped.add,
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          // Scroll the list up, away from the bottom, so the scroll-to-bottom
          // button is showing at the same time as the quick replies.
          await scrollAwayFromBottom(tester);

          final disc = discFinder();
          expect(disc, findsOneWidget);
          final buttonRect = tester.getRect(disc);

          for (final reply in quickReplies) {
            final chipFinder = find.widgetWithText(OutlinedButton, reply);
            expect(
              chipFinder,
              findsOneWidget,
              reason: 'Quick reply chip "$reply" was not found on screen.',
            );
            // The quick-reply row scrolls horizontally; make sure this chip
            // is actually within its scrollable viewport before measuring/
            // tapping it (the chip's `RenderBox` still reports a rect even
            // while clipped out of view, which would silently no-op the tap).
            await tester.ensureVisible(chipFinder);
            await tester.pumpAndSettle();
            final chipRect = tester.getRect(chipFinder);

            expect(
              buttonRect.overlaps(chipRect),
              isFalse,
              reason: 'Scroll-to-bottom button hit area $buttonRect '
                  'overlaps quick-reply chip "$reply" at $chipRect.',
            );

            await tester.tapAt(chipRect.center);
            await tester.pumpAndSettle();
          }

          expect(
            tapped,
            equals(quickReplies),
            reason: 'Tapping the centre of each quick-reply chip should '
                'fire onQuickReplyTap with that chip\'s value, not be '
                'swallowed by the scroll-to-bottom button sitting on top '
                'of it.',
          );
        },
      );
    }
  });
}
