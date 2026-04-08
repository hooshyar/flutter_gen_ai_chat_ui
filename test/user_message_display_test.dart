import 'package:flutter/material.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression test for GitHub issue #36:
/// User input messages should appear in the chat list when added via controller.
void main() {
  group('User Message Display (Issue #36)', () {
    late ChatMessagesController controller;

    setUp(() {
      controller = ChatMessagesController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('addMessage should accept user messages', () {
      const user = ChatUser(id: 'user', name: 'You');
      final message = ChatMessage(
        text: 'Hello AI!',
        user: user,
        createdAt: DateTime.now(),
      );

      controller.addMessage(message);

      expect(controller.messages.length, 1);
      expect(controller.messages.first.text, 'Hello AI!');
    });

    test('user and AI messages should both appear in messages list', () {
      const user = ChatUser(id: 'user', name: 'You');
      const ai = ChatUser(id: 'ai', name: 'Bot');

      final userMsg = ChatMessage(
        text: 'What is 2+2?',
        user: user,
        createdAt: DateTime.now(),
      );
      final aiMsg = ChatMessage(
        text: '4',
        user: ai,
        createdAt: DateTime.now(),
      );

      controller.addMessage(userMsg);
      controller.addMessage(aiMsg);

      expect(controller.messages.length, 2);
      expect(controller.messages.any((m) => m.text == 'What is 2+2?'), isTrue);
      expect(controller.messages.any((m) => m.text == '4'), isTrue);
    });

    test('user message should be marked as user message', () {
      const user = ChatUser(id: 'user', name: 'You');
      final message = ChatMessage(
        text: 'Test',
        user: user,
        createdAt: DateTime.now(),
      );

      controller.addMessage(message);

      final stored = controller.messages.first;
      expect(stored.customProperties?['isUserMessage'], isTrue);
    });

    testWidgets('user message should display in AiChatWidget',
        (WidgetTester tester) async {
      const currentUser = ChatUser(id: 'user', name: 'You');
      const aiUser = ChatUser(id: 'ai', name: 'Bot');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AiChatWidget(
              controller: controller,
              currentUser: currentUser,
              aiUser: aiUser,
              onSendMessage: (message) {
                controller.addMessage(message);
                controller.addMessage(ChatMessage(
                  text: 'AI response',
                  user: aiUser,
                  createdAt: DateTime.now(),
                ));
              },
            ),
          ),
        ),
      );

      // Type and send a message
      await tester.enterText(find.byType(TextField), 'Hello from user');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      // Both user and AI messages should be in the controller
      expect(controller.messages.length, 2);
      expect(
        controller.messages.any((m) => m.text == 'Hello from user'),
        isTrue,
      );
      expect(
        controller.messages.any((m) => m.text == 'AI response'),
        isTrue,
      );
    });
  });
}
