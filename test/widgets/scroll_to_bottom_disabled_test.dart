import 'package:flutter/material.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';
import 'package:flutter_test/flutter_test.dart';

/// The painted 36px disc itself (not its 48px hit area, which pads beyond
/// the visual edge) — a `DecoratedBox` with a circular shape.
Finder discFinder() => find.byWidgetPredicate((widget) {
      if (widget is! DecoratedBox) return false;
      final decoration = widget.decoration;
      return decoration is BoxDecoration &&
          decoration.shape == BoxShape.circle &&
          decoration.border != null;
    });

/// `ScrollToBottomOptions.disabled` was only read by
/// `CustomChatWidget._effectiveMessageListPadding` (to widen the list's own
/// bottom padding) — `_buildScrollToBottomButton` never checked it, so the
/// button still rendered (default disc or a caller's `scrollToBottomBuilder`
/// alike) even with `disabled: true`. This is a long-standing bug: the
/// pre-`DESIGN.md` code never read the flag either.
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
              'fill vertical space in the list.',
          user: i.isEven ? currentUser : aiUser,
          createdAt: baseTime.add(Duration(milliseconds: i)),
        ),
      );
    }
    return controller;
  }

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

  testWidgets(
    'disabled: true never shows the default scroll-to-bottom disc, even '
    'scrolled away from the bottom',
    (tester) async {
      final controller = buildController(30);
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AiChatWidget(
              currentUser: currentUser,
              aiUser: aiUser,
              controller: controller,
              onSendMessage: (message) {},
              scrollToBottomOptions:
                  const ScrollToBottomOptions(disabled: true),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await scrollAwayFromBottom(tester);

      expect(discFinder(), findsNothing);
    },
  );

  testWidgets(
    'disabled: true never invokes a custom scrollToBottomBuilder',
    (tester) async {
      final controller = buildController(30);
      addTearDown(controller.dispose);
      var builderCalls = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AiChatWidget(
              currentUser: currentUser,
              aiUser: aiUser,
              controller: controller,
              onSendMessage: (message) {},
              scrollToBottomOptions: ScrollToBottomOptions(
                disabled: true,
                scrollToBottomBuilder: (_) {
                  builderCalls++;
                  return const Icon(Icons.arrow_circle_down);
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await scrollAwayFromBottom(tester);

      expect(builderCalls, 0);
      expect(find.byIcon(Icons.arrow_circle_down), findsNothing);
    },
  );

  testWidgets(
    'disabled: true also suppresses an alwaysVisible button',
    (tester) async {
      final controller = buildController(2);
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AiChatWidget(
              currentUser: currentUser,
              aiUser: aiUser,
              controller: controller,
              onSendMessage: (message) {},
              scrollToBottomOptions: const ScrollToBottomOptions(
                disabled: true,
                alwaysVisible: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(discFinder(), findsNothing);
    },
  );
}
