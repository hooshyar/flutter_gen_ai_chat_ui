import 'package:flutter/material.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression coverage for the 760px reading column (`DESIGN.md` §5): on a
/// wide viewport, every message row must be centred in a column capped at
/// `ChatLayout.readingMaxWidth` (760) instead of stretching the whole
/// `AiChatWidget` width, so it lines up with the composer (max width 800,
/// also centred).
void main() {
  const me = ChatUser(id: 'user', name: 'Me');
  const ai = ChatUser(id: 'ai', name: 'Assistant');

  const aiText = 'This is the AI response text used to find the reading '
      'column in the widget tree.';
  const userText = 'A user question';

  testWidgets(
    'at a 1600px viewport, AI content is capped at 760 and centred; the '
    'user bubble stays inside the same centred column',
    (tester) async {
      tester.view.physicalSize = const Size(1600, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller = ChatMessagesController(
        initialMessages: [
          ChatMessage(
            text: userText,
            user: me,
            createdAt: DateTime(2026, 1, 1, 12, 0),
          ),
          ChatMessage(
            text: aiText,
            user: ai,
            createdAt: DateTime(2026, 1, 1, 12, 1),
          ),
        ],
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AiChatWidget(
              currentUser: me,
              aiUser: ai,
              controller: controller,
              onSendMessage: (_) async {},
            ),
          ),
        ),
      );
      await tester.pump();

      final viewportWidth = tester.getSize(find.byType(AiChatWidget)).width;
      expect(viewportWidth, 1600);

      // The reading column wrapper is the `SizedBox` with width capped at
      // `ChatLayout.readingMaxWidth` that every message row is centred in.
      final aiColumn = find
          .ancestor(
            of: find.text(aiText),
            matching: find.byWidgetPredicate(
              (w) => w is SizedBox && w.width == ChatLayout.readingMaxWidth,
            ),
          )
          .first;
      final aiRect = tester.getRect(aiColumn);

      expect(aiRect.width, lessThanOrEqualTo(ChatLayout.readingMaxWidth));
      expect(
        aiRect.center.dx,
        closeTo(viewportWidth / 2, 1),
        reason: 'the AI content column must be centred on the viewport',
      );

      final userColumn = find
          .ancestor(
            of: find.text(userText),
            matching: find.byWidgetPredicate(
              (w) => w is SizedBox && w.width == ChatLayout.readingMaxWidth,
            ),
          )
          .first;
      final userColumnRect = tester.getRect(userColumn);

      final userBubbleContainer = find
          .ancestor(
            of: find.text(userText),
            matching: find.byType(Container),
          )
          .first;
      final userBubbleRect = tester.getRect(userBubbleContainer);

      expect(
        userBubbleRect.right,
        lessThanOrEqualTo(userColumnRect.right + 0.5),
        reason: "the user bubble's right edge must stay inside the same "
            'centred reading column as the AI content',
      );
    },
  );
}
