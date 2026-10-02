import 'package:flutter/material.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';
import 'package:flutter_test/flutter_test.dart';

/// `DESIGN.md` §5, "Message list bottom padding above composer": 16. Zeroing
/// `AiChatWidget`'s own composer top padding (6c6e1cd, to fix the
/// scroll-to-bottom button's 12px gap) left the message list's own bottom
/// inset (`ChatSpacingConfig.messageListPadding.bottom`, previously 8) as
/// the only thing standing between the last message and the composer -
/// under the documented 16px floor, most visibly when the newest message is
/// from the user (no action row below it to add extra height).
void main() {
  const currentUser = ChatUser(id: 'user1', firstName: 'User');
  const aiUser = ChatUser(id: 'ai', firstName: 'AI');

  testWidgets(
    'the last message ends at least 16px above the composer, with the '
    'newest message from the user (no action row beneath it)',
    (tester) async {
      final controller = ChatMessagesController();
      addTearDown(controller.dispose);
      final baseTime = DateTime(2026, 1, 1);
      controller.addMessage(
        ChatMessage(text: 'Hello there', user: aiUser, createdAt: baseTime),
      );
      controller.addMessage(
        ChatMessage(
          text: 'A question from me',
          user: currentUser,
          createdAt: baseTime.add(const Duration(milliseconds: 1)),
        ),
      );

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

      final lastMessageFinder = find.textContaining('A question from me');
      final composerFinder = find.byType(ChatInput);
      expect(lastMessageFinder, findsOneWidget);
      expect(composerFinder, findsOneWidget);

      final lastMessageBottom = tester.getBottomLeft(lastMessageFinder).dy;
      final composerTop = tester.getTopLeft(composerFinder).dy;
      final gap = composerTop - lastMessageBottom;

      expect(
        gap,
        greaterThanOrEqualTo(16),
        reason: 'Last message ended ${gap}px above the composer; '
            'DESIGN.md §5 wants at least 16px there.',
      );
    },
  );

  testWidgets(
    'ChatSpacingConfig default messageListPadding.bottom is 16',
    (tester) async {
      expect(const ChatSpacingConfig().messageListPadding.bottom, 16.0);
    },
  );
}
