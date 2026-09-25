import 'package:flutter/material.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression coverage: `WelcomeMessageConfig.questionsSectionTitle` must
/// stay a non-nullable `String` (additive-API contract) — it was briefly
/// made nullable, which is a breaking change for any code that reads it as
/// a plain `String`. The default is `''`, and an empty string is treated
/// exactly like "no heading" was previously treated with `null`.
void main() {
  test('defaults to an empty, non-null string', () {
    const config = WelcomeMessageConfig();
    expect(config.questionsSectionTitle, isA<String>());
    expect(config.questionsSectionTitle, '');
  });

  test('copyWith leaves an unset title as the empty default', () {
    const config = WelcomeMessageConfig();
    final copy = config.copyWith(title: 'Hi');
    expect(copy.questionsSectionTitle, '');
  });

  test('an explicitly supplied title is preserved', () {
    const config = WelcomeMessageConfig(
      questionsSectionTitle: 'Try asking:',
    );
    expect(config.questionsSectionTitle, 'Try asking:');
  });

  testWidgets(
    'an empty questionsSectionTitle renders no heading above the '
    'suggestion tiles',
    (tester) async {
      final controller = ChatMessagesController();
      addTearDown(controller.dispose);
      controller.showWelcomeMessage = true;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AiChatWidget(
              currentUser: const ChatUser(id: 'user', name: 'User'),
              aiUser: const ChatUser(id: 'ai', name: 'AI'),
              controller: controller,
              onSendMessage: (_) async {},
              welcomeMessageConfig: const WelcomeMessageConfig(
                title: 'Welcome',
              ),
              exampleQuestions: const [
                ExampleQuestion(question: 'What can you do?'),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('What can you do?'), findsOneWidget);
      // No heading text renders above the tiles when the title is empty.
      expect(find.text('Try asking:'), findsNothing);
    },
  );

  testWidgets(
    'a non-empty questionsSectionTitle renders the heading',
    (tester) async {
      final controller = ChatMessagesController();
      addTearDown(controller.dispose);
      controller.showWelcomeMessage = true;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AiChatWidget(
              currentUser: const ChatUser(id: 'user', name: 'User'),
              aiUser: const ChatUser(id: 'ai', name: 'AI'),
              controller: controller,
              onSendMessage: (_) async {},
              welcomeMessageConfig: const WelcomeMessageConfig(
                title: 'Welcome',
                questionsSectionTitle: 'Try asking:',
              ),
              exampleQuestions: const [
                ExampleQuestion(question: 'What can you do?'),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Try asking:'), findsOneWidget);
      expect(find.text('What can you do?'), findsOneWidget);
    },
  );
}
