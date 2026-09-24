import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';

/// Slice D3: default empty state (`DESIGN.md` §8.6).
void main() {
  late ChatMessagesController controller;
  late ChatUser testUser;
  late ChatUser aiUser;

  setUp(() {
    controller = ChatMessagesController();
    testUser = const ChatUser(id: 'user', name: 'Test User');
    aiUser = const ChatUser(id: 'ai', name: 'AI Assistant');
  });

  tearDown(() => controller.dispose());

  Future<void> pumpEmptyState(
    WidgetTester tester, {
    List<ExampleQuestion> exampleQuestions = const [
      ExampleQuestion(question: 'Alpha question'),
      ExampleQuestion(question: 'Beta question'),
      ExampleQuestion(question: 'Gamma question'),
    ],
    void Function(ChatMessage)? onSendMessage,
  }) async {
    controller.showWelcomeMessage = true;
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: AiChatWidget(
            currentUser: testUser,
            aiUser: aiUser,
            controller: controller,
            onSendMessage: onSendMessage ?? (_) {},
            exampleQuestions: exampleQuestions,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('default welcome has no leading/trailing suggestion icons',
      (tester) async {
    await pumpEmptyState(tester);

    expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsNothing);
    expect(find.byIcon(Icons.arrow_forward_ios_rounded), findsNothing);
  });

  testWidgets('tapping a suggestion tile sends its text', (tester) async {
    ChatMessage? sent;
    await pumpEmptyState(tester, onSendMessage: (m) => sent = m);

    await tester.tap(find.text('Alpha question'));
    await tester.pump();

    expect(sent, isNotNull);
    expect(sent!.text, 'Alpha question');
  });

  testWidgets('explicit WelcomeMessageConfig.builder still wins',
      (tester) async {
    controller.showWelcomeMessage = true;
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: AiChatWidget(
            currentUser: testUser,
            aiUser: aiUser,
            controller: controller,
            onSendMessage: (_) {},
            exampleQuestions: const [
              ExampleQuestion(question: 'Alpha question'),
            ],
            welcomeMessageConfig: WelcomeMessageConfig(
              builder: () => const Text('Totally custom welcome'),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Totally custom welcome'), findsOneWidget);
    expect(find.text('Alpha question'), findsNothing);
  });

  testWidgets(
      'suggestion tiles share a row at 800 width but stack at 390 width',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1.0;

    tester.view.physicalSize = const Size(800, 900);
    await pumpEmptyState(tester);
    final wideFirst = tester.getTopLeft(find.text('Alpha question')).dy;
    final wideSecond = tester.getTopLeft(find.text('Beta question')).dy;
    expect(wideFirst, closeTo(wideSecond, 0.5));

    tester.view.physicalSize = const Size(390, 900);
    await pumpEmptyState(tester);
    final narrowFirst = tester.getTopLeft(find.text('Alpha question')).dy;
    final narrowSecond = tester.getTopLeft(find.text('Beta question')).dy;
    expect(narrowFirst, isNot(closeTo(narrowSecond, 0.5)));
  });
}
