import 'package:flutter/material.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';
import 'package:flutter_gen_ai_chat_ui_example/examples/actions_chat.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression coverage for DESIGN.md §9 "Actions": the home page promises
/// "Tool calls rendered as code, then a result card", but the calculator
/// result used to be one more line of markdown text instead of a card.
void main() {
  testWidgets('/calculate 42 * 7 renders a result card containing 294',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: ActionsChatExample(onToggleTheme: () {})),
    );
    await tester.pump();

    final onSendMessage =
        tester.widget<AiChatWidget>(find.byType(AiChatWidget)).onSendMessage;
    const currentUser = ChatUser(id: 'user', name: 'You');

    onSendMessage(ChatMessage(
      text: '/calculate 42 * 7',
      user: currentUser,
      createdAt: DateTime.now(),
    ));

    await tester.pumpAndSettle();

    // The JSON tool-call block still renders first.
    expect(find.textContaining('"name": "calculate"'), findsOneWidget);

    // The result renders as a card (a bordered, radius-12 Container) whose
    // text contains the computed value - not a "**Result:**" markdown line.
    expect(find.text('Result'), findsOneWidget);
    expect(find.textContaining('294'), findsOneWidget);
    expect(find.textContaining('**Result:**'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
