import 'package:flutter/material.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final aiUser = ChatUser(id: 'ai', name: 'AI');
  final humanUser = ChatUser(id: 'user', name: 'User');

  group('Copy button localization (MessageOptions.copyButtonLabel)', () {
    testWidgets('renders custom copy label on AI messages', (tester) async {
      final controller = ChatMessagesController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AiChatWidget(
              currentUser: humanUser,
              aiUser: aiUser,
              controller: controller,
              onSendMessage: (_) {},
              messageOptions: const MessageOptions(
                showCopyButton: true,
                copyButtonLabel: 'نسخ',
              ),
            ),
          ),
        ),
      );

      controller.addMessage(ChatMessage(
        text: 'Hello from AI',
        user: aiUser,
        createdAt: DateTime.now(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('نسخ'), findsOneWidget);
      expect(find.text('Copy'), findsNothing);

      controller.dispose();
    });

    testWidgets('defaults to "Copy" when label not set', (tester) async {
      final controller = ChatMessagesController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AiChatWidget(
              currentUser: humanUser,
              aiUser: aiUser,
              controller: controller,
              onSendMessage: (_) {},
              messageOptions: const MessageOptions(showCopyButton: true),
            ),
          ),
        ),
      );

      controller.addMessage(ChatMessage(
        text: 'Hello',
        user: aiUser,
        createdAt: DateTime.now(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Copy'), findsOneWidget);

      controller.dispose();
    });

    test('copyButtonLabel and copiedToClipboardText survive copyWith', () {
      const base = MessageOptions(
        copyButtonLabel: 'نسخ',
        copiedToClipboardText: 'تم النسخ',
      );
      final copy = base.copyWith(showCopyButton: true);
      expect(copy.copyButtonLabel, 'نسخ');
      expect(copy.copiedToClipboardText, 'تم النسخ');
      expect(copy.showCopyButton, isTrue);
    });
  });

  group('Persistent example questions title', () {
    testWidgets('renders custom title when welcome is hidden', (tester) async {
      final controller = ChatMessagesController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AiChatWidget(
              currentUser: humanUser,
              aiUser: aiUser,
              controller: controller,
              onSendMessage: (_) {},
              persistentExampleQuestions: true,
              persistentExampleQuestionsTitle: 'أسئلة مقترحة',
              exampleQuestions: const [
                ExampleQuestion(question: 'ما هي عاصمة العراق؟'),
              ],
            ),
          ),
        ),
      );

      // Sending hides the welcome message (the real send path calls this),
      // which reveals the persistent example-questions bar.
      controller.addMessage(ChatMessage(
        text: 'مرحبا',
        user: humanUser,
        createdAt: DateTime.now(),
      ));
      controller.hideWelcomeMessage();
      await tester.pumpAndSettle();

      expect(find.text('أسئلة مقترحة'), findsOneWidget);
      expect(find.text('Suggested Questions'), findsNothing);

      controller.dispose();
    });

    testWidgets('defaults to "Suggested Questions"', (tester) async {
      final controller = ChatMessagesController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AiChatWidget(
              currentUser: humanUser,
              aiUser: aiUser,
              controller: controller,
              onSendMessage: (_) {},
              persistentExampleQuestions: true,
              exampleQuestions: const [
                ExampleQuestion(question: 'What is Flutter?'),
              ],
            ),
          ),
        ),
      );

      controller.addMessage(ChatMessage(
        text: 'hi',
        user: humanUser,
        createdAt: DateTime.now(),
      ));
      controller.hideWelcomeMessage();
      await tester.pumpAndSettle();

      expect(find.text('Suggested Questions'), findsOneWidget);

      controller.dispose();
    });
  });

  group('maxWidth centering', () {
    testWidgets('content is constrained and centered on wide viewports',
        (tester) async {
      tester.view.physicalSize = const Size(1600, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller = ChatMessagesController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AiChatWidget(
              maxWidth: 400,
              currentUser: humanUser,
              aiUser: aiUser,
              controller: controller,
              onSendMessage: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // A Center wraps the constrained column when maxWidth is set.
      final centered = find.descendant(
        of: find.byType(AiChatWidget),
        matching: find.byType(Center),
      );
      expect(centered, findsWidgets);

      // The constrained column should not exceed maxWidth.
      final columnFinder = find.descendant(
        of: find.byType(AiChatWidget),
        matching: find.byType(Column),
      );
      final size = tester.getSize(columnFinder.first);
      expect(size.width, lessThanOrEqualTo(400.0));

      controller.dispose();
    });

    testWidgets('renders without overflow on narrow viewport with maxWidth',
        (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller = ChatMessagesController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AiChatWidget(
              maxWidth: 720,
              currentUser: humanUser,
              aiUser: aiUser,
              controller: controller,
              onSendMessage: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // No overflow exceptions should have been thrown.
      expect(tester.takeException(), isNull);

      controller.dispose();
    });
  });
}
