import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';

void main() {
  group('Streaming Message Tests', () {
    late ChatMessagesController controller;
    late ChatUser testUser;
    late ChatMessage baseMessage;

    setUp(() {
      controller = ChatMessagesController();
      testUser = const ChatUser(id: 'test_user', firstName: 'Test');
      baseMessage = ChatMessage(
        text: '',
        user: testUser,
        createdAt: DateTime(2024, 1, 1, 12, 0),
        customProperties: {
          'id': 'test_message_123',
          'isStreaming': true,
        },
      );
    });

    tearDown(() {
      controller.dispose();
    });

    test('should update existing message when using custom ID', () {
      // Add initial message
      controller.addMessage(baseMessage);
      expect(controller.messages.length, 1);
      expect(controller.messages[0].text, '');

      // Update with partial text
      final updated1 = baseMessage.copyWith(text: 'Hello');
      controller.updateMessage(updated1);
      expect(controller.messages.length, 1);
      expect(controller.messages[0].text, 'Hello');

      // Update with more text
      final updated2 = baseMessage.copyWith(text: 'Hello world');
      controller.updateMessage(updated2);
      expect(controller.messages.length, 1);
      expect(controller.messages[0].text, 'Hello world');

      // Final update
      final updated3 = baseMessage.copyWith(
        text: 'Hello world!',
        customProperties: {
          'id': 'test_message_123',
          'isStreaming': false,
        },
      );
      controller.updateMessage(updated3);
      expect(controller.messages.length, 1);
      expect(controller.messages[0].text, 'Hello world!');
    });

    test('should maintain stable ID throughout streaming', () {
      // Add initial message
      controller.addMessage(baseMessage);
      final initialId = controller.getMessageId(controller.messages[0]);

      // Update multiple times
      final texts = ['H', 'He', 'Hel', 'Hell', 'Hello'];
      for (final text in texts) {
        controller.updateMessage(baseMessage.copyWith(text: text));
        expect(controller.messages.length, 1);
        expect(controller.getMessageId(controller.messages[0]), initialId);
      }
    });

    test('should not create duplicate messages during streaming', () {
      // Create message without custom ID (will use generated ID)
      final messageWithoutId = ChatMessage(
        text: '',
        user: testUser,
        createdAt: DateTime(2024, 1, 1, 12, 0),
      );

      controller.addMessage(messageWithoutId);
      expect(controller.messages.length, 1);

      // Update should work with consistent createdAt
      final updated = ChatMessage(
        text: 'Updated text',
        user: testUser,
        createdAt: messageWithoutId.createdAt,
      );
      controller.updateMessage(updated);

      // Should still have only one message
      expect(controller.messages.length, 1);
      expect(controller.messages[0].text, 'Updated text');
    });

    test('should handle rapid updates during streaming', () async {
      controller.addMessage(baseMessage);

      // Simulate rapid streaming updates
      final words = 'This is a test of streaming text functionality'.split(' ');
      String accumulated = '';

      for (var i = 0; i < words.length; i++) {
        accumulated += (i > 0 ? ' ' : '') + words[i];
        controller.updateMessage(baseMessage.copyWith(text: accumulated));

        // Verify we still have only one message
        expect(controller.messages.length, 1);
        expect(controller.messages[0].text, accumulated);
      }

      expect(controller.messages[0].text,
          'This is a test of streaming text functionality');
    });

    test('should preserve message properties during updates', () {
      // Add message with various properties
      final complexMessage = ChatMessage(
        text: '',
        user: testUser,
        createdAt: DateTime(2024, 1, 1, 12, 0),
        isMarkdown: true,
        customProperties: {
          'id': 'complex_123',
          'isStreaming': true,
          'responseId': 'response_456',
          'isFirstResponseMessage': true,
        },
      );

      controller.addMessage(complexMessage);

      // Update text multiple times
      controller.updateMessage(complexMessage.copyWith(text: 'Updated'));

      // Verify properties are preserved
      final updatedMessage = controller.messages[0];
      expect(updatedMessage.isMarkdown, true);
      expect(updatedMessage.customProperties?['responseId'], 'response_456');
      expect(updatedMessage.customProperties?['isFirstResponseMessage'], true);
    });

    test('message ID should not change with text updates', () {
      // Test that the fixed ID generation doesn't include text hash
      final message1 = ChatMessage(
        text: 'Hello',
        user: testUser,
        createdAt: DateTime.utc(2024, 1, 1, 12, 0),
      );

      final message2 = ChatMessage(
        text: 'Hello world',
        user: testUser,
        createdAt: DateTime.utc(2024, 1, 1, 12, 0),
      );

      final id1 = controller.getMessageId(message1);
      final id2 = controller.getMessageId(message2);

      // IDs should be the same since they have same user and timestamp
      expect(id1, equals(id2));
      expect(id1, 'test_user_1704110400000');
    });
  });
}
