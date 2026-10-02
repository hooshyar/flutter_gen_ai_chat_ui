import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';

void main() {
  group('Intermediate Example Message Flow', () {
    late ChatMessagesController controller;
    late ChatUser currentUser;
    late ChatUser aiUser;

    setUp(() {
      controller = ChatMessagesController();
      currentUser = const ChatUser(id: 'user123', firstName: 'You');
      aiUser = const ChatUser(id: 'ai123', firstName: 'AI Assistant');
    });

    tearDown(() {
      controller.dispose();
    });

    test('should add user message before AI response', () {
      // Simulate user sending a message
      final userMessage = ChatMessage(
        text: 'Hello, how are you?',
        user: currentUser,
        createdAt: DateTime.now(),
      );

      // Add user message (this is what _handleSendMessage should do first)
      controller.addMessage(userMessage);

      // Verify user message is added
      expect(controller.messages.length, 1);
      expect(controller.messages[0].text, 'Hello, how are you?');
      expect(controller.messages[0].user.id, 'user123');

      // Then add AI response
      final aiMessage = ChatMessage(
        text: 'Hello! I\'m doing well, thank you.',
        user: aiUser,
        createdAt: DateTime.now(),
        customProperties: {'id': 'ai_response_123'},
      );

      controller.addMessage(aiMessage);

      // Verify both messages are present (reverse order - newest first)
      expect(controller.messages.length, 2);
      expect(controller.messages[0].text, 'Hello! I\'m doing well, thank you.');
      expect(controller.messages[0].user.id, 'ai123');
      expect(controller.messages[1].text, 'Hello, how are you?');
      expect(controller.messages[1].user.id, 'user123');
    });

    test('should handle streaming with user message visible', () {
      final userMessage = ChatMessage(
        text: 'Tell me a story',
        user: currentUser,
        createdAt: DateTime.now(),
      );

      // Add user message first
      controller.addMessage(userMessage);
      expect(controller.messages.length, 1);

      // Add initial empty AI message for streaming
      final streamingMessageId =
          'streaming_${DateTime.now().millisecondsSinceEpoch}';
      final aiMessage = ChatMessage(
        text: '',
        user: aiUser,
        createdAt: DateTime.now(),
        customProperties: {'id': streamingMessageId, 'isStreaming': true},
      );

      controller.addMessage(aiMessage);
      expect(controller.messages.length, 2);
      expect(
        controller.messages[0].text,
        '',
      ); // Empty initially (newest message)

      // Update with streaming text
      final words = ['Once', 'upon', 'a', 'time'];
      String accumulated = '';

      for (var i = 0; i < words.length; i++) {
        accumulated += (i > 0 ? ' ' : '') + words[i];

        controller.updateMessage(
          ChatMessage(
            text: accumulated,
            user: aiUser,
            createdAt: aiMessage.createdAt,
            customProperties: {
              'id': streamingMessageId,
              'isStreaming': i < words.length - 1,
            },
          ),
        );

        // Should still have only 2 messages (user + AI)
        expect(controller.messages.length, 2);
        expect(
          controller.messages[1].user.id,
          'user123',
        ); // User message still there (older)
        expect(
          controller.messages[0].text,
          accumulated,
        ); // AI message updated (newer)
      }

      // Final check
      expect(
        controller.messages[0].text,
        'Once upon a time',
      ); // AI message (newest)
    });
  });
}
