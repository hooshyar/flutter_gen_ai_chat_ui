import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';
import 'package:flutter_gen_ai_chat_ui/src/widgets/math_markdown.dart';

/// Part of the documented-knob verification sweep (issue #41 Phase 0.5):
/// asserts `AiChatWidget.enableMathRendering` actually changes what gets
/// rendered, rather than silently doing nothing.
void main() {
  const testUser = ChatUser(id: 'user', name: 'Test User');
  const aiUser = ChatUser(id: 'ai', name: 'AI Assistant');

  Future<ChatMessagesController> pumpWithMathMessage(
    WidgetTester tester, {
    required bool enableMathRendering,
  }) async {
    final controller = ChatMessagesController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: AiChatWidget(
            currentUser: testUser,
            aiUser: aiUser,
            controller: controller,
            onSendMessage: (_) async {},
            enableMarkdownStreaming: false,
            enableMathRendering: enableMathRendering,
          ),
        ),
      ),
    );
    await tester.pump();

    controller.addMessage(ChatMessage(
      text: r'Answer: $x^2$',
      user: aiUser,
      createdAt: DateTime.now(),
      isMarkdown: true,
      customProperties: const {'id': 'resp1'},
    ));
    await tester.pumpAndSettle();

    return controller;
  }

  testWidgets('enableMathRendering: true renders math via MathMarkdown',
      (tester) async {
    await pumpWithMathMessage(tester, enableMathRendering: true);
    expect(find.byType(MathMarkdown), findsOneWidget);
  });

  testWidgets('enableMathRendering: false (default) does not use MathMarkdown',
      (tester) async {
    await pumpWithMathMessage(tester, enableMathRendering: false);
    expect(find.byType(MathMarkdown), findsNothing);
  });
}
