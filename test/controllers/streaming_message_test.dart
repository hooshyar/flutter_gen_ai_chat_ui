import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';

void main() {
  late ChatMessagesController controller;
  late ChatUser userA;
  late ChatUser aiUser;

  setUp(() {
    controller = ChatMessagesController();
    userA = const ChatUser(id: 'user', name: 'Test User');
    aiUser = const ChatUser(id: 'ai', name: 'AI Assistant');
  });

  tearDown(() {
    controller.dispose();
  });

  group('ChatMessagesController Streaming Messages', () {
    test('handles initial streaming message', () {
      // Create streaming message
      final streamingMessage = ChatMessage(
        text: 'Initial streaming text',
        user: aiUser,
        createdAt: DateTime.now(),
        customProperties: {'id': 'stream-1', 'isStreaming': true},
      );

      // Add message
      controller.addMessage(streamingMessage);

      // Check message was added correctly
      expect(controller.messages.length, 1);
      expect(controller.messages.first.text, 'Initial streaming text');
      expect(
        controller.messages.first.customProperties?['isStreaming'],
        isTrue,
      );
    });

    test('updates streaming message content', () {
      // Create initial streaming message
      final streamingMessage = ChatMessage(
        text: 'Initial',
        user: aiUser,
        createdAt: DateTime.now(),
        customProperties: {'id': 'stream-1', 'isStreaming': true},
      );

      // Add message
      controller.addMessage(streamingMessage);

      // Update with new content
      final updatedMessage = ChatMessage(
        text: 'Initial with more text',
        user: aiUser,
        createdAt: DateTime.now(),
        customProperties: {'id': 'stream-1', 'isStreaming': true},
      );

      controller.updateMessage(updatedMessage);

      // Check message was updated
      expect(controller.messages.length, 1);
      expect(controller.messages.first.text, 'Initial with more text');
      expect(
        controller.messages.first.customProperties?['isStreaming'],
        isTrue,
      );
    });

    test('completes streaming by setting isStreaming to false', () {
      // Create and add initial streaming message
      controller.addMessage(
        ChatMessage(
          text: 'Streaming content',
          user: aiUser,
          createdAt: DateTime.now(),
          customProperties: {'id': 'stream-1', 'isStreaming': true},
        ),
      );

      // Finalize the message by setting isStreaming to false
      controller.updateMessage(
        ChatMessage(
          text: 'Final content',
          user: aiUser,
          createdAt: DateTime.now(),
          customProperties: {'id': 'stream-1', 'isStreaming': false},
        ),
      );

      // Check message was updated and marked as not streaming
      expect(controller.messages.length, 1);
      expect(controller.messages.first.text, 'Final content');
      expect(
        controller.messages.first.customProperties?['isStreaming'],
        isFalse,
      );
    });

    test('state handling in streaming context', () {
      // Create a simple streaming message
      final streamingMessage = ChatMessage(
        text: 'Initial content',
        user: aiUser,
        createdAt: DateTime.now(),
        customProperties: {'id': 'stream-test', 'isStreaming': true},
      );

      controller.addMessage(streamingMessage);

      // Verify the message exists and has streaming flag
      expect(controller.messages.length, 1);
      expect(
        controller.messages.first.customProperties?['isStreaming'],
        isTrue,
      );

      // Update with new content
      controller.updateMessage(
        ChatMessage(
          text: 'Updated content',
          user: aiUser,
          createdAt: DateTime.now(),
          customProperties: {'id': 'stream-test', 'isStreaming': true},
        ),
      );

      // Verify the update took effect
      expect(controller.messages.first.text, 'Updated content');
      expect(
        controller.messages.first.customProperties?['isStreaming'],
        isTrue,
      );
    });

    test('handles multiple streaming messages', () {
      // Add first streaming message
      controller.addMessage(
        ChatMessage(
          text: 'First streaming message',
          user: aiUser,
          createdAt: DateTime.now(),
          customProperties: {'id': 'stream-1', 'isStreaming': true},
        ),
      );

      // Add second streaming message
      controller.addMessage(
        ChatMessage(
          text: 'Second streaming message',
          user: aiUser,
          createdAt: DateTime.now(),
          customProperties: {'id': 'stream-2', 'isStreaming': true},
        ),
      );

      // Both messages should be in the list
      expect(controller.messages.length, 2);

      // Update first message
      controller.updateMessage(
        ChatMessage(
          text: 'First streaming message updated',
          user: aiUser,
          createdAt: DateTime.now(),
          customProperties: {'id': 'stream-1', 'isStreaming': false},
        ),
      );

      // First message should be updated, second should be unchanged
      expect(controller.messages.length, 2);

      // Find messages by ID
      final message1 = controller.messages.firstWhere(
        (m) => m.customProperties?['id'] == 'stream-1',
      );
      final message2 = controller.messages.firstWhere(
        (m) => m.customProperties?['id'] == 'stream-2',
      );

      expect(message1.text, 'First streaming message updated');
      expect(message1.customProperties?['isStreaming'], isFalse);
      expect(message2.text, 'Second streaming message');
      expect(message2.customProperties?['isStreaming'], isTrue);
    });

    test('handles markdown streaming updates', () {
      // Add markdown streaming message
      controller.addMessage(
        ChatMessage(
          text: '# Heading',
          user: aiUser,
          createdAt: DateTime.now(),
          isMarkdown: true,
          customProperties: {'id': 'markdown-stream', 'isStreaming': true},
        ),
      );

      // Update with more markdown content
      controller.updateMessage(
        ChatMessage(
          text: '# Heading\n\nParagraph with **bold** text',
          user: aiUser,
          createdAt: DateTime.now(),
          isMarkdown: true,
          customProperties: {'id': 'markdown-stream', 'isStreaming': true},
        ),
      );

      // Message should maintain markdown flag
      expect(controller.messages.first.isMarkdown, isTrue);
      expect(
        controller.messages.first.text,
        '# Heading\n\nParagraph with **bold** text',
      );
    });

    test('controller properly preserves streaming state', () {
      // Add initial streaming message with a metadata property
      controller.addMessage(
        ChatMessage(
          text: 'Streaming content',
          user: aiUser,
          createdAt: DateTime.now(),
          customProperties: {
            'id': 'stream-metadata-test',
            'isStreaming': true,
            'metadata': {'key': 'value'},
          },
        ),
      );

      // Verify it was added
      expect(controller.messages.length, 1);

      // Update with different content
      controller.updateMessage(
        ChatMessage(
          text: 'Updated streaming content',
          user: aiUser,
          createdAt: DateTime.now(),
          customProperties: {'id': 'stream-metadata-test', 'isStreaming': true},
        ),
      );

      // Verify text was updated
      expect(controller.messages.first.text, 'Updated streaming content');

      // Verify isStreaming is still true
      expect(
        controller.messages.first.customProperties?['isStreaming'],
        isTrue,
      );
    });
  });
}
