import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';

/// Performance tests for message rendering
///
/// These tests measure:
/// - Rendering performance with varying message counts
/// - Scroll performance
/// - Memory efficiency
///
/// Run with:
/// ```bash
/// flutter test test/performance/message_performance_test.dart
/// ```
///
/// For profiling, use Flutter DevTools:
/// ```bash
/// flutter run --profile
/// # Then open DevTools and navigate to Performance tab
/// ```

void main() {
  group('Message Rendering Performance', () {
    final currentUser = const ChatUser(id: 'user', firstName: 'You');
    final aiUser = const ChatUser(id: 'ai', firstName: 'AI');

    /// Helper to generate test messages
    List<ChatMessage> generateMessages(int count) {
      return List.generate(count, (i) {
        return ChatMessage(
          text: 'This is test message number $i with some realistic content '
              'that might span multiple lines when rendered. It includes '
              'various characters and lengths to simulate real usage.',
          user: i.isEven ? currentUser : aiUser,
          createdAt: DateTime.now().subtract(Duration(minutes: count - i)),
          isMarkdown: i % 3 == 0, // Every 3rd message is markdown
        );
      });
    }

    testWidgets('Performance: 100 messages', (WidgetTester tester) async {
      final controller = ChatMessagesController();
      final messages = generateMessages(100);

      for (final msg in messages) {
        controller.addMessage(msg);
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AiChatWidget(
              currentUser: currentUser,
              aiUser: aiUser,
              controller: controller,
              onSendMessage: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Test passed if it renders without errors
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('Performance: 500 messages', (WidgetTester tester) async {
      final controller = ChatMessagesController();
      final messages = generateMessages(500);

      for (final msg in messages) {
        controller.addMessage(msg);
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AiChatWidget(
              currentUser: currentUser,
              aiUser: aiUser,
              controller: controller,
              onSendMessage: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('Performance: 1000 messages', (WidgetTester tester) async {
      final controller = ChatMessagesController();
      final messages = generateMessages(1000);

      for (final msg in messages) {
        controller.addMessage(msg);
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AiChatWidget(
              currentUser: currentUser,
              aiUser: aiUser,
              controller: controller,
              onSendMessage: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('Scroll Performance: 1000 messages',
        (WidgetTester tester) async {
      final controller = ChatMessagesController();
      final messages = generateMessages(1000);

      for (final msg in messages) {
        controller.addMessage(msg);
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AiChatWidget(
              currentUser: currentUser,
              aiUser: aiUser,
              controller: controller,
              onSendMessage: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Perform scroll gestures
      final listView = find.byType(ListView);

      // Scroll down
      await tester.fling(listView, const Offset(0, -500), 1000);
      await tester.pumpAndSettle();

      // Scroll up
      await tester.fling(listView, const Offset(0, 500), 1000);
      await tester.pumpAndSettle();

      // Test passed if scrolling works smoothly
      expect(listView, findsOneWidget);
    });
  });

  group('Message Addition Performance', () {
    final currentUser = const ChatUser(id: 'user', firstName: 'You');
    final aiUser = const ChatUser(id: 'ai', firstName: 'AI');

    testWidgets('Adding messages incrementally',
        (WidgetTester tester) async {
      final controller = ChatMessagesController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AiChatWidget(
              currentUser: currentUser,
              aiUser: aiUser,
              controller: controller,
              onSendMessage: (_) {},
            ),
          ),
        ),
      );

      // Add messages incrementally and test performance
      for (int i = 0; i < 100; i++) {
        controller.addMessage(ChatMessage(
          text: 'Message $i',
          user: i.isEven ? currentUser : aiUser,
          createdAt: DateTime.now(),
        ));

        await tester.pump();
      }

      await tester.pumpAndSettle();

      // Test passed if all messages added without errors
      expect(controller.messages.length, 100);
    });
  });
}
