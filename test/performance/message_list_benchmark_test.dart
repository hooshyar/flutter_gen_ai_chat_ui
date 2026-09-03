import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';

/// Timed benchmarks backing the README's "Performance Benchmarks" claims
/// (60 FPS with 1000+ messages, optimized for 10K+ conversations, <100ms
/// init). These are coarse, environment-sensitive wall-clock measurements —
/// not a substitute for profiling on a real device — so thresholds are kept
/// generous to avoid CI flakiness (see task-019's notes on wall-clock
/// flakiness under concurrent machine load) while still catching a gross
/// regression (a missing `ListView.builder`, an accidental O(n^2) path).
///
/// Numbers are printed with `debugPrint` so a human can read the actual
/// measured values from `flutter test` output and update the baseline
/// recorded in CHANGELOG.md if behavior meaningfully changes.
void main() {
  const testUser = ChatUser(id: 'user', name: 'Test User');
  const aiUser = ChatUser(id: 'ai', name: 'AI Assistant');

  List<ChatMessage> generateMessages(int count) {
    final now = DateTime.now();
    return List.generate(count, (i) {
      final isUser = i.isEven;
      return ChatMessage(
        text: 'Message number $i with representative body text so each '
            'bubble does a realistic amount of markdown/text layout work '
            'during this benchmark run instead of measuring an empty string.',
        user: isUser ? testUser : aiUser,
        createdAt: now.add(Duration(milliseconds: i)),
        isMarkdown: !isUser,
        customProperties: {'id': 'msg_$i'},
      );
    });
  }

  group('ChatMessagesController benchmarks (pure Dart, no widget tree)', () {
    for (final count in [500, 1000, 2000]) {
      test('setMessages with $count messages completes in bounded time', () {
        final controller = ChatMessagesController();
        addTearDown(controller.dispose);
        final messages = generateMessages(count);

        final stopwatch = Stopwatch()..start();
        controller.setMessages(messages);
        stopwatch.stop();

        debugPrint(
          'BENCHMARK setMessages($count): ${stopwatch.elapsedMilliseconds}ms',
        );
        expect(controller.messages.length, count);
        // Generous ceiling — this is a pure list assignment, should be near
        // instant; catches an accidental O(n^2) regression, not micro-perf.
        expect(stopwatch.elapsedMilliseconds, lessThan(2000));
      });
    }

    test(
        'addMessage (append order) with 2000 existing messages stays fast '
        'per call', () {
      final controller = ChatMessagesController();
      addTearDown(controller.dispose);
      controller.setMessages(generateMessages(2000));

      final stopwatch = Stopwatch()..start();
      for (var i = 0; i < 50; i++) {
        controller.addMessage(
          ChatMessage(
            text: 'Appended message $i',
            user: aiUser,
            createdAt: DateTime.now(),
            customProperties: {'id': 'appended_$i'},
          ),
        );
      }
      stopwatch.stop();

      debugPrint(
        'BENCHMARK addMessage x50 (2000 existing, append order): '
        '${stopwatch.elapsedMilliseconds}ms total, '
        '${stopwatch.elapsedMicroseconds / 50}us/call avg',
      );
      expect(controller.messages.length, 2050);
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
    });

    test(
        'updateMessage (simulated word-by-word streaming) on the last of '
        '2000 messages, chronological order', () {
      // Chronological (append) order is the worst case for
      // updateMessage's indexWhere scan: the actively-streaming message
      // sits at the END of the list, so every update call scans past all
      // prior messages. This quantifies that cost rather than fixing it —
      // see docs/AWARD-PLAN.md / follow-up task for the fix itself.
      final controller = ChatMessagesController(
        paginationConfig: const PaginationConfig(reverseOrder: false),
      );
      addTearDown(controller.dispose);
      controller.setMessages(generateMessages(2000));

      final streamingId = 'streaming_target';
      controller.addMessage(
        ChatMessage(
          text: '',
          user: aiUser,
          createdAt: DateTime.now(),
          customProperties: {'id': streamingId, 'isStreaming': true},
        ),
      );

      final stopwatch = Stopwatch()..start();
      var text = '';
      for (var i = 0; i < 100; i++) {
        text += 'word$i ';
        controller.updateMessage(
          ChatMessage(
            text: text,
            user: aiUser,
            createdAt: DateTime.now(),
            customProperties: {'id': streamingId, 'isStreaming': i < 99},
          ),
        );
      }
      stopwatch.stop();

      debugPrint(
        'BENCHMARK updateMessage x100 (streaming, 2000 messages ahead of '
        'target, chronological order): ${stopwatch.elapsedMilliseconds}ms '
        'total, ${stopwatch.elapsedMicroseconds / 100}us/call avg',
      );
      expect(stopwatch.elapsedMilliseconds, lessThan(2000));
    });

    test(
        'updateMessage (simulated word-by-word streaming) on the newest '
        'message, reverse order (default pagination)', () {
      // Reverse order (newest-first list, the package default) puts the
      // streaming message at index 0, so indexWhere finds it on the first
      // comparison regardless of history length — the fast case.
      final controller = ChatMessagesController();
      addTearDown(controller.dispose);
      controller.setMessages(generateMessages(2000));

      final streamingId = 'streaming_target';
      controller.addMessage(
        ChatMessage(
          text: '',
          user: aiUser,
          createdAt: DateTime.now(),
          customProperties: {'id': streamingId, 'isStreaming': true},
        ),
      );

      final stopwatch = Stopwatch()..start();
      var text = '';
      for (var i = 0; i < 100; i++) {
        text += 'word$i ';
        controller.updateMessage(
          ChatMessage(
            text: text,
            user: aiUser,
            createdAt: DateTime.now(),
            customProperties: {'id': streamingId, 'isStreaming': i < 99},
          ),
        );
      }
      stopwatch.stop();

      debugPrint(
        'BENCHMARK updateMessage x100 (streaming, 2000 messages, reverse '
        'order): ${stopwatch.elapsedMilliseconds}ms total, '
        '${stopwatch.elapsedMicroseconds / 100}us/call avg',
      );
      expect(stopwatch.elapsedMilliseconds, lessThan(2000));
    });
  });

  group('AiChatWidget render benchmarks (widget tree)', () {
    Future<ChatMessagesController> pumpChatWith(
      WidgetTester tester,
      int messageCount,
    ) async {
      final controller = ChatMessagesController();
      addTearDown(controller.dispose);
      controller.setMessages(generateMessages(messageCount));

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: AiChatWidget(
              currentUser: testUser,
              aiUser: aiUser,
              controller: controller,
              onSendMessage: (_) async {},
              enableMarkdownStreaming: false,
            ),
          ),
        ),
      );
      return controller;
    }

    testWidgets('initial build+layout with 1000 messages is bounded',
        (tester) async {
      final stopwatch = Stopwatch()..start();
      await pumpChatWith(tester, 1000);
      await tester.pump();
      stopwatch.stop();

      debugPrint(
        'BENCHMARK AiChatWidget initial build (1000 messages): '
        '${stopwatch.elapsedMilliseconds}ms',
      );
      // Lazy ListView.builder means only visible items should actually
      // build — this stays well under a second even loaded, so a
      // regression to eager building of all 1000 items would show up here.
      expect(stopwatch.elapsedMilliseconds, lessThan(5000));
    });

    testWidgets('scrolling through 1000 messages stays bounded',
        (tester) async {
      await pumpChatWith(tester, 1000);
      await tester.pump();

      final listFinder = find.byType(Scrollable).first;

      final stopwatch = Stopwatch()..start();
      for (var i = 0; i < 10; i++) {
        await tester.fling(listFinder, const Offset(0, -400), 2000);
        await tester.pump();
      }
      stopwatch.stop();

      debugPrint(
        'BENCHMARK scroll x10 flings through 1000 messages: '
        '${stopwatch.elapsedMilliseconds}ms total, '
        '${stopwatch.elapsedMilliseconds / 10}ms/fling avg',
      );
      expect(stopwatch.elapsedMilliseconds, lessThan(10000));
    });
  });
}
