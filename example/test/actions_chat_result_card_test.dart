import 'package:flutter/material.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';
import 'package:flutter_gen_ai_chat_ui_example/examples/actions_chat.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression coverage for DESIGN.md §9 "Actions": the home page promises
/// "Tool calls rendered as code, then a result card", but the calculator
/// and weather results used to be silently dropped instead of rendering as
/// a card.
///
/// Root cause: `ActionsChatExample` adds the "Calling the ... tool:" text
/// message and the following `ChatMessage.rich` result card back to back.
/// When a message has no explicit id, `ChatMessagesController` builds one
/// from `user.id` + `createdAt.millisecondsSinceEpoch`, and a second message
/// that lands on an already-cached id is dropped. Two messages added in the
/// same millisecond can collide on any platform; on web it is more likely
/// because `DateTime.now()` only has millisecond resolution.
///
/// Fix (in the example): the tool-call message and the result card now get
/// explicit, distinct ids (`tool-call-<n>` / `tool-result-<n>`), so they
/// never depend on generated ids. The controller behaviour is unchanged and
/// documented as a known limitation in the README and CHANGELOG. A proper
/// controller-side fix is tracked in backlog task-035.
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

  testWidgets('/weather Paris renders a result card', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: ActionsChatExample(onToggleTheme: () {})),
    );
    await tester.pump();

    final onSendMessage =
        tester.widget<AiChatWidget>(find.byType(AiChatWidget)).onSendMessage;
    const currentUser = ChatUser(id: 'user', name: 'You');

    onSendMessage(ChatMessage(
      text: '/weather Paris',
      user: currentUser,
      createdAt: DateTime.now(),
    ));

    await tester.pumpAndSettle();

    expect(find.textContaining('"name": "get_weather"'), findsOneWidget);
    expect(find.text('Result'), findsOneWidget);
    expect(find.textContaining('Paris:'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'tool-call block and result card both render even when they share '
      'the exact same createdAt (reproduces the web same-millisecond '
      'case on the VM)', (tester) async {
    // `DateTime.now()` only has millisecond resolution on web, so two
    // back-to-back calls inside `_onSendMessage` can return the exact same
    // instant there even though they rarely do on the VM's microsecond
    // clock. This test forces that collision directly by constructing both
    // messages - the way `ActionsChatExample._onSendMessage` does for
    // `/calculate` - with an identical `createdAt`, proving the explicit
    // `tool-call-<n>` / `tool-result-<n>` ids (not auto-generated
    // user+timestamp ids) are what keeps them from colliding.
    final controller = ChatMessagesController();
    addTearDown(controller.dispose);
    const aiUser = ChatUser(id: 'ai', name: 'Agent');
    final sameInstant = DateTime(2026, 1, 1, 12, 0, 0);

    controller.addMessage(ChatMessage(
      text: 'Calling the calculator tool:\n\n'
          '```json\n{"name": "calculate", "arguments": {"expression": "42 * 7"}}\n```',
      user: aiUser,
      createdAt: sameInstant,
      isMarkdown: true,
      customProperties: const {'id': 'tool-call-0'},
    ));
    controller.addMessage(ChatMessage.rich(
      user: aiUser,
      resultKind: 'action_result',
      data: const {'label': 'Result', 'value': '42 * 7 = 294'},
      createdAt: sameInstant,
      id: 'tool-result-0',
    ));

    // Both messages must be stored - the same-millisecond createdAt must
    // not cause the second one to be dropped or merged with the first.
    expect(controller.messages.length, 2);

    await tester.pumpWidget(MaterialApp(
      home: AiChatWidget(
        currentUser: const ChatUser(id: 'user', name: 'You'),
        aiUser: aiUser,
        controller: controller,
        onSendMessage: (_) {},
        resultRenderers: {
          'action_result': (context, data) => Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['label'] as String? ?? 'Result'),
                    Text(data['value'] as String? ?? ''),
                  ],
                ),
              ),
        },
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining('"name": "calculate"'), findsOneWidget);
    expect(find.text('Result'), findsOneWidget);
    expect(find.textContaining('294'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
