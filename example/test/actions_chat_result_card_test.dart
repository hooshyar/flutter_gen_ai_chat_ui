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
/// message and the following `ChatMessage.rich` result card back-to-back,
/// synchronously, with no explicit id and no explicit `createdAt` for the
/// card. `ChatMessagesController` used to derive a message's auto id purely
/// from `user.id` + `createdAt.millisecondsSinceEpoch`; `DateTime.now()`
/// only has millisecond resolution on web (it's backed by JS `Date.now()`,
/// unlike the VM's microsecond-resolution clock), so two back-to-back
/// `DateTime.now()` calls reliably land in the same millisecond there. The
/// two messages then got the same auto id, and the second `addMessage` call
/// was silently dropped by the "id already cached" de-dup guard.
///
/// This is why the bug only reproduced in a real browser and never
/// reliably in a plain `flutter test` run: on the Dart VM, two
/// `DateTime.now()` calls a few statements apart are - empirically -
/// typically microseconds to a few milliseconds apart and rarely collide.
///
/// `ChatMessagesController` now disambiguates a same-millisecond id
/// collision between two genuinely DIFFERENT messages with a suffix
/// (instead of silently dropping the second one) while still deduping a
/// truly identical re-added message onto its existing id - see
/// `ChatMessagesController._resolveGeneratedMessageId`. The real proof of
/// that fix is the deterministic, explicit-`createdAt` collision test in
/// `test/chat_messages_controller_test.dart`; this suite is the
/// integration-level regression for the concrete example that surfaced the
/// bug, and now runs on the Dart VM like the rest of the suite. It can
/// also be run with `flutter test --platform chrome` to exercise the real
/// web timing directly.
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
}
