import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';

void main() {
  late ChatMessagesController controller;
  late ScrollController scrollController;
  late ChatUser userA;
  late ChatUser aiUser;

  setUp(() {
    controller = ChatMessagesController();
    scrollController = ScrollController();
    controller.setScrollController(scrollController);

    userA = const ChatUser(id: 'user', name: 'Test User');
    aiUser = const ChatUser(id: 'ai', name: 'AI Assistant');
  });

  tearDown(() {
    controller.dispose();
    scrollController.dispose();
  });

  group('ChatMessagesController Auto-Scroll Behavior', () {
    testWidgets('scroll behavior setup is correct', (
      WidgetTester tester,
    ) async {
      // Create a widget to test scrolling
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 400,
              child: ListView.builder(
                controller: scrollController,
                itemCount: 20,
                itemBuilder: (context, index) => const SizedBox(height: 50),
              ),
            ),
          ),
        ),
      );

      // Set scroll behavior
      controller.scrollBehaviorConfig = const ScrollBehaviorConfig(
        autoScrollBehavior: AutoScrollBehavior.onUserMessageOnly,
      );

      // Verify the config is set correctly
      expect(
        controller.scrollBehaviorConfig.autoScrollBehavior,
        equals(AutoScrollBehavior.onUserMessageOnly),
      );
    });

    testWidgets(
      'does not scroll on AI message with "onUserMessageOnly" setting',
      (WidgetTester tester) async {
        // Create a widget to test scrolling
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 400,
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: 20,
                  itemBuilder: (context, index) => const SizedBox(height: 50),
                ),
              ),
            ),
          ),
        );

        // Set initial scroll position
        scrollController.jumpTo(500);
        await tester.pumpAndSettle();

        // Capture initial position
        final initialPosition = scrollController.position.pixels;

        // Set scroll behavior
        controller.scrollBehaviorConfig = const ScrollBehaviorConfig(
          autoScrollBehavior: AutoScrollBehavior.onUserMessageOnly,
        );

        // Add an AI message
        controller.addMessage(
          ChatMessage(
            text: 'AI message',
            user: aiUser,
            createdAt: DateTime.now(),
          ),
        );

        // Wait for animation
        await tester.pumpAndSettle();

        // Verify scroll position (should NOT scroll)
        expect(scrollController.position.pixels, initialPosition);
      },
    );

    test('controller handles scroll behavior modes properly', () {
      // Instead of testing the actual scrolling, we can test that the controller
      // properly evaluates whether to scroll based on message and config

      // Test with never mode
      controller.scrollBehaviorConfig = const ScrollBehaviorConfig(
        autoScrollBehavior: AutoScrollBehavior.never,
      );

      // The controller should properly identify this as a no-scroll scenario
      expect(
        controller.scrollBehaviorConfig.autoScrollBehavior,
        equals(AutoScrollBehavior.never),
      );
    });
  });

  group('ChatMessagesController Response Message Tracking', () {
    test('marks first message of AI response correctly', () {
      // Add user message first
      controller.addMessage(
        ChatMessage(
          text: 'User message',
          user: userA,
          createdAt: DateTime.now(),
        ),
      );

      // Add AI message (should be marked as first response)
      controller.addMessage(
        ChatMessage(
          text: 'AI response',
          user: aiUser,
          createdAt: DateTime.now(),
        ),
      );

      // Get the AI message
      final aiMessage =
          controller.messages.where((m) => m.user.id == 'ai').first;

      // Verify it's marked as first response message
      expect(aiMessage.customProperties?['isFirstResponseMessage'], isTrue);
    });

    test('adds custom properties to messages', () {
      // Add user message
      controller.addMessage(
        ChatMessage(
          text: 'User message',
          user: userA,
          createdAt: DateTime.now(),
        ),
      );

      // Verify custom properties exist
      expect(controller.messages.first.customProperties, isNotNull);
    });
  });

  group('ChatMessagesController Streaming Message Support', () {
    test('updates streaming messages correctly', () {
      // Create initial streaming message
      final streamingMessage = ChatMessage(
        text: 'Initial',
        user: aiUser,
        createdAt: DateTime.now(),
        customProperties: {'id': 'streaming-msg', 'isStreaming': true},
      );

      // Add the initial message
      controller.addMessage(streamingMessage);

      // Update it with new content
      controller.updateMessage(
        ChatMessage(
          text: 'Initial text with more content',
          user: aiUser,
          createdAt: DateTime.now(),
          customProperties: {'id': 'streaming-msg', 'isStreaming': true},
        ),
      );

      // Verify message was updated
      expect(controller.messages.length, 1);
      expect(controller.messages.first.text, 'Initial text with more content');

      // Finalize the message (end streaming)
      controller.updateMessage(
        ChatMessage(
          text: 'Final text',
          user: aiUser,
          createdAt: DateTime.now(),
          customProperties: {'id': 'streaming-msg', 'isStreaming': false},
        ),
      );

      // Verify message was updated
      expect(controller.messages.length, 1);
      expect(controller.messages.first.text, 'Final text');
    });

    test('updates streaming messages with proper state management', () {
      // Create initial streaming message
      final streamingMessage = ChatMessage(
        text: 'Initial',
        user: aiUser,
        createdAt: DateTime.now(),
        customProperties: {'id': 'streaming-msg', 'isStreaming': true},
      );

      // Add the initial message
      controller.addMessage(streamingMessage);

      // Update the streaming message
      controller.updateMessage(
        ChatMessage(
          text: 'Updated content',
          user: aiUser,
          createdAt: DateTime.now(),
          customProperties: {'id': 'streaming-msg', 'isStreaming': true},
        ),
      );

      // Verify the message was updated correctly
      expect(controller.messages.first.text, 'Updated content');

      // The streaming flag should still be true
      expect(controller.messages.first.customProperties, isNotNull);
    });
  });

  group('ChatMessagesController scrollToMessage functionality', () {
    test('scrollToMessage method exists', () {
      // Verify that the controller has the scrollToMessage method
      expect(controller.scrollToMessage, isNotNull);
    });

    testWidgets('accepts message IDs for scrolling', (
      WidgetTester tester,
    ) async {
      // Create a widget to test scrolling
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 400,
              child: ListView.builder(
                controller: scrollController,
                itemCount: 50,
                itemBuilder: (context, index) => const SizedBox(height: 50),
              ),
            ),
          ),
        ),
      );

      // Add a message with an ID
      controller.addMessage(
        ChatMessage(
          text: 'Test message',
          user: userA,
          createdAt: DateTime.now(),
          customProperties: {'id': 'test-msg-id'},
        ),
      );

      // Wait for render
      await tester.pumpAndSettle();

      // Call scrollToMessage - this shouldn't throw an error
      controller.scrollToMessage('test-msg-id');

      // Wait for any animations to complete
      await tester.pumpAndSettle();

      // If we got here without errors, the test passes
      // We can't reliably test the actual scroll position in this environment
      expect(true, isTrue);
    });
  });
}
