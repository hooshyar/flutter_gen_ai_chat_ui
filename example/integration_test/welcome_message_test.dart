import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'utils/test_utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Welcome Message and Example Questions Tests', () {
    late ChatMessagesController controller;
    late List<ChatMessage> sentMessages;

    setUp(() {
      controller = TestUtils.createController();
      sentMessages = [];
    });

    testWidgets('Should display welcome message when configured',
        (WidgetTester tester) async {
      // Arrange: Create welcomeMessageConfig
      final welcomeMessageConfig = TestUtils.createWelcomeMessageConfig();

      // Act: Render the chat widget
      await tester.pumpWidget(
        TestUtils.createTestApp(
          controller: controller,
          welcomeMessageConfig: welcomeMessageConfig,
        ),
      );

      // Allow welcome message to appear
      await tester.pumpAndSettle();

      // Assert: Welcome message should be displayed
      expect(find.text('Welcome to the chat'), findsOneWidget);
    });

    testWidgets('Should display example questions',
        (WidgetTester tester) async {
      // Arrange: Create config with example questions
      final exampleQuestions = [
        const ExampleQuestion(question: 'What is your name?'),
        const ExampleQuestion(question: 'How can you help me?'),
        const ExampleQuestion(question: 'Tell me a joke'),
      ];

      final welcomeMessageConfig = TestUtils.createWelcomeMessageConfig();

      // Act: Render the chat widget
      await tester.pumpWidget(
        TestUtils.createTestApp(
          controller: controller,
          exampleQuestions: exampleQuestions,
          welcomeMessageConfig: welcomeMessageConfig,
          onSendMessage: (message) {
            sentMessages.add(message);
          },
        ),
      );

      // Allow welcome message and questions to appear
      await tester.pumpAndSettle();

      // Assert: Example questions should be displayed
      expect(
          TestUtils.findExampleQuestion('What is your name?'), findsOneWidget);
      expect(TestUtils.findExampleQuestion('How can you help me?'),
          findsOneWidget);
      expect(TestUtils.findExampleQuestion('Tell me a joke'), findsOneWidget);
    });

    testWidgets('Should send message when example question is tapped',
        (WidgetTester tester) async {
      // Arrange: Create config with example questions
      final exampleQuestions = [
        const ExampleQuestion(question: 'What is your name?'),
      ];

      final welcomeMessageConfig = TestUtils.createWelcomeMessageConfig();

      // Act: Render the chat widget
      await tester.pumpWidget(
        TestUtils.createTestApp(
          controller: controller,
          exampleQuestions: exampleQuestions,
          welcomeMessageConfig: welcomeMessageConfig,
          onSendMessage: (message) {
            sentMessages.add(message);
            // Simulate AI response
            controller.addMessage(
              TestUtils.generateAiMessage(text: 'Response to: ${message.text}'),
            );
          },
        ),
      );

      // Allow welcome message and questions to appear
      await tester.pumpAndSettle();

      // Tap on the example question
      await tester.tap(TestUtils.findExampleQuestion('What is your name?'));
      await tester.pumpAndSettle();

      // Assert: The example question should be sent as a message
      expect(sentMessages.length, 1);
      expect(sentMessages.first.text, 'What is your name?');

      // The message should be displayed in the chat
      expect(
          TestUtils.findMessageWithText('What is your name?'), findsOneWidget);
      expect(TestUtils.findMessageWithText('Response to: What is your name?'),
          findsOneWidget);
    });
  });
}
