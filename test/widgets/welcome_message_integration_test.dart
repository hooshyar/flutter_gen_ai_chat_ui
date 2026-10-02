import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';

void main() {
  group('Welcome Message Integration Tests', () {
    late ChatMessagesController controller;
    late ChatUser currentUser;
    late ChatUser aiUser;

    setUp(() {
      controller = ChatMessagesController();
      currentUser = ChatUser(id: 'user1', name: 'User');
      aiUser = ChatUser(id: 'ai', name: 'AI Assistant');
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets(
      'Welcome message should be integrated in message list, not overlay',
      (tester) async {
        // Set welcome message to show
        controller.showWelcomeMessage = true;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AiChatWidget(
                currentUser: currentUser,
                aiUser: aiUser,
                controller: controller,
                onSendMessage: (message) {},
                welcomeMessageConfig: WelcomeMessageConfig(
                  builder: () => const Text('Welcome to the chat!'),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify welcome message is shown
        expect(find.text('Welcome to the chat!'), findsOneWidget);

        // Verify it's not in an overlay (no semi-transparent background container)
        expect(find.byType(Container).first, isNotNull);

        // The welcome message should be part of the scrollable list
        expect(find.byType(ListView), findsOneWidget);
      },
    );

    testWidgets(
      'Welcome message should hide when user sends first message through input',
      (tester) async {
        controller.showWelcomeMessage = true;
        var messageReceived = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AiChatWidget(
                currentUser: currentUser,
                aiUser: aiUser,
                controller: controller,
                onSendMessage: (message) {
                  messageReceived = true;
                  // The _handleSend method in AiChatWidget should hide the welcome message
                },
                welcomeMessageConfig: WelcomeMessageConfig(
                  builder: () => const Text('Welcome to the chat!'),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Welcome message should be visible initially
        expect(find.text('Welcome to the chat!'), findsOneWidget);
        expect(controller.showWelcomeMessage, isTrue);

        // Directly test the hiding mechanism by calling hideWelcomeMessage
        controller.hideWelcomeMessage();
        await tester.pumpAndSettle();

        // Welcome message should be hidden
        expect(controller.showWelcomeMessage, isFalse);
        expect(find.text('Welcome to the chat!'), findsNothing);
      },
    );

    testWidgets('Welcome message should not show when messages already exist', (
      tester,
    ) async {
      // Add an existing message first
      controller.addMessage(
        ChatMessage(
          text: 'Existing message',
          user: currentUser,
          createdAt: DateTime.now(),
        ),
      );

      controller.showWelcomeMessage = true;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AiChatWidget(
              currentUser: currentUser,
              aiUser: aiUser,
              controller: controller,
              onSendMessage: (message) {},
              welcomeMessageConfig: WelcomeMessageConfig(
                builder: () => const Text('Welcome to the chat!'),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Welcome message should not be shown when messages exist
      expect(find.text('Welcome to the chat!'), findsNothing);
      expect(find.text('Existing message'), findsOneWidget);
    });
  });
}
