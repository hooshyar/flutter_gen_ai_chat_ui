import 'package:flutter/material.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'utils/test_utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Basic Chat Functionality Tests', () {
    late ChatMessagesController controller;
    late List<ChatMessage> sentMessages;

    setUp(() {
      controller = TestUtils.createController();
      sentMessages = [];
    });

    testWidgets('Should display messages in the chat',
        (WidgetTester tester) async {
      // Arrange: Add initial messages to the controller
      final userMessage = TestUtils.generateUserMessage(text: 'Hello, AI!');
      final aiMessage = TestUtils.generateAiMessage(text: 'Hello, User!');
      controller.addMessages([userMessage, aiMessage]);

      // Act: Render the chat widget
      await tester.pumpWidget(
        TestUtils.createTestApp(controller: controller),
      );

      // Assert: Messages should be displayed
      expect(TestUtils.findMessageWithText('Hello, AI!'), findsOneWidget);
      expect(TestUtils.findMessageWithText('Hello, User!'), findsOneWidget);
    });

    testWidgets('Should send a message when pressing send button',
        (WidgetTester tester) async {
      // Arrange: Setup chat with callback to capture sent messages
      await tester.pumpWidget(
        TestUtils.createTestApp(
          controller: controller,
          onSendMessage: (message) {
            sentMessages.add(message);
            // Add AI response for display testing
            controller.addMessage(
              TestUtils.generateAiMessage(text: 'Received: ${message.text}'),
            );
          },
        ),
      );

      // Act: Send a message
      await TestUtils.sendMessage(tester, 'Test message');

      // Allow time for the message to be processed and the response to be added
      await tester.pumpAndSettle();

      // Assert: Message was sent and response was received
      expect(sentMessages.length, 1);
      expect(sentMessages.first.text, 'Test message');
      expect(TestUtils.findMessageWithText('Test message'), findsOneWidget);
      expect(TestUtils.findMessageWithText('Received: Test message'),
          findsOneWidget);
    });

    testWidgets('Should clear input field after sending message',
        (WidgetTester tester) async {
      // Arrange: Setup chat
      await tester.pumpWidget(
        TestUtils.createTestApp(controller: controller),
      );

      // Act: Write text and send message
      await tester.enterText(TestUtils.findChatInputField(), 'Message to send');
      await tester.pump();

      // Verify text is in the input field
      expect(find.text('Message to send'), findsOneWidget);

      // Send the message
      await tester.tap(TestUtils.findSendButton());
      await tester.pump();

      // Assert: Input field should be cleared
      expect(find.text('Message to send'), findsNothing);
    });

    testWidgets('Should respect read-only mode', (WidgetTester tester) async {
      // Arrange: Setup chat in read-only mode
      await tester.pumpWidget(
        TestUtils.createTestApp(
          controller: controller,
          readOnly: true,
        ),
      );

      // Act: Try to enter text
      await tester.enterText(
          TestUtils.findChatInputField(), 'Attempting to type');
      await tester.pump();

      // Assert: Input field should not accept input in read-only mode
      final textField =
          tester.widget<TextField>(TestUtils.findChatInputField());
      expect(textField.readOnly, isTrue);

      // Try to send a message - the send button should not be enabled
      // Note: In some implementations, the send button might not even be visible in read-only mode
      if (TestUtils.findSendButton().evaluate().isNotEmpty) {
        await tester.tap(TestUtils.findSendButton());
        await tester.pump();
        expect(controller.messages.length, 0); // No message should be added
      }
    });
  });
}
