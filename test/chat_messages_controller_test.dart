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

    test(
      'loadMore adds messages in correct order (chronological mode)',
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
      },
    );

    test('hasMoreMessages flag updates correctly', () async {
      final controller = ChatMessagesController(
        paginationConfig: const PaginationConfig(enabled: true),
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
        paginationConfig: const PaginationConfig(enabled: true),
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
        paginationConfig: const PaginationConfig(enabled: false),
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
        paginationConfig: const PaginationConfig(enabled: true),
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

    test(
        'addMessage does not drop a same-millisecond AI message '
        '(auto id collision)', () {
      // Regression test: a caller that adds two AI messages back-to-back in
      // the same synchronous handler - e.g. a tool-call JSON block
      // immediately followed by a `ChatMessage.rich` result card, with
      // neither message given an explicit id - relies on addMessage()'s
      // auto id generation ('${user.id}_${createdAt.millisecondsSinceEpoch}')
      // to keep both messages distinct.
      //
      // `DateTime.now()` only has millisecond resolution on web (it's
      // backed by JS `Date.now()`, unlike the VM's microsecond clock), so
      // two such calls a few statements apart reliably return the SAME
      // instant there - and did in the real example app
      // (example/lib/examples/actions_chat.dart's `/calculate` and
      // `/weather` handlers) even though this rarely reproduced on the Dart
      // VM, where flutter's own test suite runs by default. This test
      // reproduces the collision deterministically, on any platform, by
      // constructing two messages with an explicit, identical `createdAt`
      // instead of depending on real-clock timing.
      final controller = ChatMessagesController();
      final aiUser = ChatUser(id: 'ai', firstName: 'Agent');
      final sameInstant = DateTime(2026, 1, 1, 12, 0, 0);

      controller.addMessage(ChatMessage(
        text: 'Calling the calculator tool: ...',
        user: aiUser,
        createdAt: sameInstant,
        isMarkdown: true,
      ));
      controller.addMessage(ChatMessage.rich(
        user: aiUser,
        resultKind: 'action_result',
        data: const {'label': 'Result', 'value': '42 * 7 = 294'},
        createdAt: sameInstant,
      ));

      expect(controller.messages.length, 2);
      expect(
        controller.messages
            .where((m) => m.customProperties?['resultKind'] == 'action_result')
            .length,
        1,
        reason: 'the rich result-card message must not be dropped when it '
            'shares its auto-generated id with the preceding AI message',
      );

      // The two auto-generated ids must be distinct even though both
      // messages were created at the exact same instant.
      final ids = controller.messages.map(controller.getMessageId).toSet();
      expect(ids.length, 2);

      controller.dispose();
    });

    test(
        'addMessage still dedupes re-adding the exact same id-less message '
        '(round-10 fix must not break this)', () {
      // Regression test for a bug introduced by the same-millisecond-id
      // suffix fix above: it must only suffix when the collision is with a
      // genuinely DIFFERENT message. Re-adding the SAME message content
      // (no explicit id, same user/createdAt/text) must still collapse to
      // one stored message, exactly like before the suffix fix existed.
      final controller = ChatMessagesController();
      final aiUser = ChatUser(id: 'ai', firstName: 'Agent');
      final sameInstant = DateTime(2026, 1, 1, 12, 0, 0);

      final message = ChatMessage(
        text: 'Hello there',
        user: aiUser,
        createdAt: sameInstant,
      );

      controller.addMessage(message);
      controller.addMessage(message);

      expect(controller.messages.length, 1,
          reason: 'adding the identical message twice must dedupe, not '
              'create a second entry with a suffixed id');

      controller.dispose();
    });

    test('setMessages then addMessage of the same id-less message dedupes', () {
      final controller = ChatMessagesController();
      final aiUser = ChatUser(id: 'ai', firstName: 'Agent');
      final sameInstant = DateTime(2026, 1, 1, 12, 0, 0);

      final message = ChatMessage(
        text: 'Hello there',
        user: aiUser,
        createdAt: sameInstant,
      );

      controller.setMessages([message]);
      controller.addMessage(message);

      expect(controller.messages.length, 1);

      controller.dispose();
    });

    test(
        'addMessage dedupes onto an existing suffixed id, not just the base '
        'id', () {
      // Three id-less messages share the same millisecond: A, then a
      // DIFFERENT message B (forces the base id to be taken by A and B to
      // land on `baseId_1`), then A again. The third add must dedupe onto
      // B's `baseId_1` slot... no - onto A's original (base) id, since A's
      // content matches the FIRST stored message under the base id, which
      // is walked before any suffix.
      final controller = ChatMessagesController();
      final aiUser = ChatUser(id: 'ai', firstName: 'Agent');
      final sameInstant = DateTime(2026, 1, 1, 12, 0, 0);

      final messageA = ChatMessage(
        text: 'Message A',
        user: aiUser,
        createdAt: sameInstant,
      );
      final messageB = ChatMessage(
        text: 'Message B',
        user: aiUser,
        createdAt: sameInstant,
      );

      controller.addMessage(messageA);
      controller.addMessage(messageB);
      expect(controller.messages.length, 2);

      // Re-add content-identical to B (which is stored under the `_1`
      // suffix) - must dedupe onto B's id, not create a third message.
      controller.addMessage(ChatMessage(
        text: 'Message B',
        user: aiUser,
        createdAt: sameInstant,
      ));

      expect(controller.messages.length, 2,
          reason: 're-adding content identical to the message stored under '
              'the suffixed id must dedupe onto it, not add a third message');

      controller.dispose();
    });

    test(
        'two different id-less messages sharing user+createdAt are kept as '
        'two distinct messages', () {
      // Same scenario as the collision test above, phrased directly per the
      // acceptance criteria: distinct content, same millisecond, no
      // explicit ids - both must survive.
      final controller = ChatMessagesController();
      final aiUser = ChatUser(id: 'ai', firstName: 'Agent');
      final sameInstant = DateTime(2026, 1, 1, 12, 0, 0);

      controller.addMessage(ChatMessage(
        text: 'First distinct message',
        user: aiUser,
        createdAt: sameInstant,
      ));
      controller.addMessage(ChatMessage.rich(
        user: aiUser,
        resultKind: 'weather',
        data: const {'city': 'Baghdad', 'temp': 42},
        createdAt: sameInstant,
      ));

      expect(controller.messages.length, 2);

      controller.dispose();
    });
  });
}
