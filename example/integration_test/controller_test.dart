import 'package:flutter/material.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'utils/test_utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('ChatMessagesController Tests', () {
    late ChatMessagesController controller;

    setUp(() {
      controller = TestUtils.createController();
    });

    testWidgets('Should add message and update UI',
        (WidgetTester tester) async {
      // Arrange: Render the chat widget with empty controller
      await tester.pumpWidget(
        TestUtils.createTestApp(
          controller: controller,
        ),
      );

      // Verify no messages initially
      expect(find.byType(TextButton), findsNothing);

      // Act: Add a new message
      final message = TestUtils.generateUserMessage(text: 'Hello, World!');
      controller.addMessage(message);
      await tester.pumpAndSettle();

      // Assert: Message should be displayed in the UI
      expect(TestUtils.findMessageWithText('Hello, World!'), findsOneWidget);
    });

    testWidgets('Should update message and refresh UI',
        (WidgetTester tester) async {
      // Arrange: Add initial message and render
      final initialMessage =
          TestUtils.generateUserMessage(text: 'Initial message');
      controller.addMessage(initialMessage);

      await tester.pumpWidget(
        TestUtils.createTestApp(
          controller: controller,
        ),
      );

      // Verify initial message
      expect(TestUtils.findMessageWithText('Initial message'), findsOneWidget);

      // Act: Update the message
      final updatedMessage = ChatMessage(
        text: 'Updated message',
        user: initialMessage.user,
        createdAt: initialMessage.createdAt,
      );
      controller.updateMessage(updatedMessage);
      await tester.pumpAndSettle();

      // Assert: Updated message should be displayed, original gone
      expect(TestUtils.findMessageWithText('Updated message'), findsOneWidget);
      expect(TestUtils.findMessageWithText('Initial message'), findsNothing);
    });

    testWidgets('Should replace messages and update UI',
        (WidgetTester tester) async {
      // Arrange: Add two messages
      final message1 = TestUtils.generateUserMessage(text: 'First message');
      final message2 = TestUtils.generateUserMessage(text: 'Second message');
      controller.addMessages([message1, message2]);

      await tester.pumpWidget(
        TestUtils.createTestApp(
          controller: controller,
        ),
      );

      // Verify both messages
      expect(TestUtils.findMessageWithText('First message'), findsOneWidget);
      expect(TestUtils.findMessageWithText('Second message'), findsOneWidget);

      // Act: Replace messages with just the second message
      controller.setMessages([message2]);
      await tester.pumpAndSettle();

      // Assert: First message should be gone, second still there
      expect(TestUtils.findMessageWithText('First message'), findsNothing);
      expect(TestUtils.findMessageWithText('Second message'), findsOneWidget);
    });

    testWidgets('Should clear all messages and update UI',
        (WidgetTester tester) async {
      // Arrange: Add multiple messages
      final messages = [
        TestUtils.generateUserMessage(text: 'Message 1'),
        TestUtils.generateAiMessage(text: 'Message 2'),
        TestUtils.generateUserMessage(text: 'Message 3'),
      ];
      controller.addMessages(messages);

      await tester.pumpWidget(
        TestUtils.createTestApp(
          controller: controller,
        ),
      );

      // Verify messages are displayed
      expect(TestUtils.findMessageWithText('Message 1'), findsOneWidget);
      expect(TestUtils.findMessageWithText('Message 2'), findsOneWidget);
      expect(TestUtils.findMessageWithText('Message 3'), findsOneWidget);

      // Act: Clear all messages
      controller.clearMessages();
      await tester.pumpAndSettle();

      // Assert: No messages should be displayed
      expect(TestUtils.findMessageWithText('Message 1'), findsNothing);
      expect(TestUtils.findMessageWithText('Message 2'), findsNothing);
      expect(TestUtils.findMessageWithText('Message 3'), findsNothing);
    });

    testWidgets('Should stream text word by word', (WidgetTester tester) async {
      // Arrange: Render the chat widget
      await tester.pumpWidget(
        TestUtils.createTestApp(
          controller: controller,
          enableAnimation: true,
          streamingDuration: const Duration(milliseconds: 50),
        ),
      );

      // Act: Start streaming a message
      final streamingMessage = TestUtils.generateAiMessage(
        text: '',
        isStreaming: true,
      );
      controller.addMessage(streamingMessage);
      await tester.pump();

      // Stream words one by one
      final words = ['This', 'is', 'a', 'streaming', 'message'];
      String currentText = '';

      for (final word in words) {
        currentText = currentText.isEmpty ? word : '$currentText $word';

        // Update the message with the new word
        final updatedMessage = ChatMessage(
          text: currentText,
          user: streamingMessage.user,
          createdAt: streamingMessage.createdAt,
          customProperties:
              word == words.last ? null : streamingMessage.customProperties,
        );
        controller.updateMessage(updatedMessage);

        await tester.pump(const Duration(milliseconds: 100));
      }

      // Allow final animation to complete
      await tester.pumpAndSettle();

      // Assert: Final message should be displayed correctly
      expect(TestUtils.findMessageWithText('This is a streaming message'),
          findsOneWidget);
    });

    testWidgets('Should notify listeners when message list changes',
        (WidgetTester tester) async {
      // Arrange: Track notification count
      int notificationCount = 0;

      // Create a listener that increments the count
      controller.addListener(() {
        notificationCount++;
      });

      // Act & Assert: Various operations should trigger notifications

      // Test add
      controller.addMessage(TestUtils.generateUserMessage(text: 'Test 1'));
      expect(notificationCount, 1);

      // Test update
      if (controller.messages.isNotEmpty) {
        final message = controller.messages[0];
        final updated = ChatMessage(
          text: 'Updated',
          user: message.user,
          createdAt: message.createdAt,
        );
        controller.updateMessage(updated);
        expect(notificationCount, 2);
      }

      // Test setMessages (instead of remove)
      controller.setMessages([]);
      expect(notificationCount, 3);

      // Test add multiple
      controller.addMessages([
        TestUtils.generateUserMessage(text: 'Test 2'),
        TestUtils.generateAiMessage(text: 'Test 3'),
      ]);
      expect(notificationCount, 4);

      // Test clear
      controller.clearMessages();
      expect(notificationCount, 5);
    });
  });
}
