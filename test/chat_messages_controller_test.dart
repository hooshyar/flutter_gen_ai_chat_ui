import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';

void main() {
  group('ChatMessagesController Tests', () {
    // Create a list of test messages for pagination tests
    final testMessages = List.generate(50, (index) {
      return ChatMessage(
        text: 'Message ${index + 1}',
        user: ChatUser(id: 'user1', firstName: 'Test User'),
        createdAt: DateTime.now().subtract(Duration(minutes: (50 - index) * 5)),
        customProperties: {'id': 'msg-${index + 1}'},
      );
    });

    test('loadMore adds messages in correct order (reverse mode)', () async {
      // Create controller with reverse pagination
      final controller = ChatMessagesController(
        paginationConfig: const PaginationConfig(
          enabled: true,
          loadingDelay: Duration(milliseconds: 100),
          reverseOrder: true,
        ),
      );

      // Initial batch of messages (newest 10, messages 41-50)
      final initialBatch = testMessages.sublist(40, 50);
      controller.setMessages(initialBatch);
      expect(controller.messages.length, 10);
      expect(controller.messages.first.text, 'Message 50');
      expect(controller.messages.last.text, 'Message 41');

      // Load more (next 10 messages, 31-40)
      final nextBatch = testMessages.sublist(30, 40);
      await controller.loadMore(() async => nextBatch);

      // Should now have 20 messages, with correct ordering
      expect(controller.messages.length, 20);
      expect(controller.messages.first.text, 'Message 50');
      // Controller always adds messages to the end of the list, regardless of pagination order
      expect(controller.messages.last.text, 'Message 40');

      controller.dispose();
    });

    test('loadMore adds messages in correct order (chronological mode)',
        () async {
      // Create controller with chronological pagination
      final controller = ChatMessagesController(
        paginationConfig: const PaginationConfig(
          enabled: true,
          loadingDelay: Duration(milliseconds: 100),
          reverseOrder: false,
        ),
      );

      // Initial batch of messages (oldest 10, messages 1-10)
      final initialBatch = testMessages.sublist(0, 10);
      controller.setMessages(initialBatch);
      expect(controller.messages.length, 10);
      expect(controller.messages.first.text, 'Message 1');
      expect(controller.messages.last.text, 'Message 10');

      // Load more (next 10 messages, 11-20)
      final nextBatch = testMessages.sublist(10, 20);
      await controller.loadMore(() async => nextBatch);

      // Should now have 20 messages, with correct ordering
      expect(controller.messages.length, 20);
      expect(controller.messages.first.text, 'Message 1');
      expect(controller.messages.last.text, 'Message 20');

      controller.dispose();
    });

    test('hasMoreMessages flag updates correctly', () async {
      final controller = ChatMessagesController(
        paginationConfig: const PaginationConfig(
          enabled: true,
        ),
      );

      // Initial state
      expect(controller.hasMoreMessages, true);

      // Add initial messages
      controller.setMessages(testMessages.take(10).toList());

      // Load more with empty result
      await controller.loadMore(() async => []);
      expect(controller.hasMoreMessages, false);

      // Reset pagination
      controller.resetPagination();
      expect(controller.hasMoreMessages, true);

      controller.dispose();
    });

    test('isLoadingMore flag updates during loading', () async {
      final controller = ChatMessagesController(
        paginationConfig: const PaginationConfig(
          enabled: true,
          loadingDelay: Duration(milliseconds: 100),
        ),
      );

      // Initial state
      expect(controller.isLoadingMore, false);

      // Start loading
      final loadFuture = controller.loadMore(() async {
        await Future.delayed(const Duration(milliseconds: 200));
        return testMessages.sublist(0, 10);
      });

      // Flag should be true during loading
      expect(controller.isLoadingMore, true);

      // Wait for loading to complete
      await loadFuture;

      // Flag should be false after loading
      expect(controller.isLoadingMore, false);

      controller.dispose();
    });

    test('multiple loadMore calls are handled correctly', () async {
      final controller = ChatMessagesController(
        paginationConfig: const PaginationConfig(
          enabled: true,
          loadingDelay: Duration(milliseconds: 50),
        ),
      );

      // Initial batch
      controller.setMessages(testMessages.sublist(0, 10));
      expect(controller.messages.length, 10);

      // Load first batch
      await controller.loadMore(() async {
        await Future.delayed(const Duration(milliseconds: 50));
        return testMessages.sublist(10, 20);
      });

      expect(controller.messages.length, 20);

      // Load second batch
      await controller.loadMore(() async {
        await Future.delayed(const Duration(milliseconds: 50));
        return testMessages.sublist(20, 30);
      });

      expect(controller.messages.length, 30);

      controller.dispose();
    });

    test('loadMore respects loading delay', () async {
      final loadingDelay = const Duration(milliseconds: 200);
      final controller = ChatMessagesController(
        paginationConfig: PaginationConfig(
          enabled: true,
          loadingDelay: loadingDelay,
        ),
      );

      // Measure the time it takes to load
      final stopwatch = Stopwatch()..start();
      await controller.loadMore(() async => testMessages.sublist(0, 10));
      stopwatch.stop();

      // Should have waited at least the loading delay
      expect(stopwatch.elapsed, greaterThanOrEqualTo(loadingDelay));

      controller.dispose();
    });

    test('empty results update hasMoreMessages flag', () async {
      final controller = ChatMessagesController(
        paginationConfig: const PaginationConfig(
          enabled: true,
        ),
      );

      // Initially has more messages
      expect(controller.hasMoreMessages, true);

      // Load with empty results
      await controller.loadMore(() async => []);

      // Now should not have more messages
      expect(controller.hasMoreMessages, false);

      controller.dispose();
    });

    test('paginationConfig is respected', () async {
      // Test with disabled pagination
      final controller = ChatMessagesController(
        paginationConfig: const PaginationConfig(
          enabled: false,
        ),
      );

      // Loading more should be a no-op when pagination is disabled
      await controller.loadMore(() async {
        fail('Should not be called when pagination is disabled');
        return [];
      });

      // Still has more messages
      expect(controller.hasMoreMessages, true);

      controller.dispose();
    });

    test('controller correctly transitions to hasMoreMessages=false', () async {
      final controller = ChatMessagesController(
        paginationConfig: const PaginationConfig(
          enabled: true,
        ),
      );

      // First load gets messages
      await controller.loadMore(() async => testMessages.sublist(0, 10));
      expect(controller.hasMoreMessages, true);

      // Second load gets empty list
      await controller.loadMore(() async => []);
      expect(controller.hasMoreMessages, false);

      // Reset pagination
      controller.resetPagination();
      expect(controller.hasMoreMessages, true);

      controller.dispose();
    });
  });
}
