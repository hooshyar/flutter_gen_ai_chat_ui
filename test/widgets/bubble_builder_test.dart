// Tests for MessageOptions.bubbleBuilder (added 2.15.0). The README long
// documented a 4-arg bubble builder that receives the default bubble to wrap,
// but only a 3-arg full-replacement `customBubbleBuilder` existed and it lived
// on MessageOptions (not AiChatWidget) — the cause of the confusion in #18/#30.
// `bubbleBuilder` now provides the documented wrap-the-default behaviour and
// takes precedence over `customBubbleBuilder`.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';

void main() {
  Widget host(MessageOptions options) {
    final controller = ChatMessagesController(
      initialMessages: [
        ChatMessage(
          text: 'hello',
          // A current-user message renders a plain bubble (no markdown
          // streaming animation), keeping the test free of pending timers.
          user: const ChatUser(id: 'u', firstName: 'U'),
          createdAt: DateTime.now(),
        ),
      ],
    );
    addTearDown(controller.dispose);
    return MaterialApp(
      home: Scaffold(
        body: AiChatWidget(
          currentUser: const ChatUser(id: 'u', firstName: 'U'),
          aiUser: const ChatUser(id: 'ai', firstName: 'AI'),
          controller: controller,
          onSendMessage: (_) {},
          messageOptions: options,
        ),
      ),
    );
  }

  testWidgets('bubbleBuilder wraps the default bubble', (tester) async {
    Widget? receivedDefault;
    await tester.pumpWidget(host(MessageOptions(
      bubbleBuilder: (context, message, isCurrentUser, defaultBubble) {
        receivedDefault = defaultBubble;
        return Column(
          children: [
            const Text('WRAP', key: Key('wrap_marker')),
            defaultBubble,
          ],
        );
      },
    )));
    await tester.pump();

    expect(find.byKey(const Key('wrap_marker')), findsOneWidget);
    expect(receivedDefault, isNotNull);
  });

  testWidgets('bubbleBuilder takes precedence over customBubbleBuilder',
      (tester) async {
    await tester.pumpWidget(host(MessageOptions(
      bubbleBuilder: (context, message, isCurrentUser, defaultBubble) =>
          const Text('FROM_WRAP', key: Key('from_wrap')),
      customBubbleBuilder: (context, message, isCurrentUser) =>
          const Text('FROM_CUSTOM', key: Key('from_custom')),
    )));
    await tester.pump();

    expect(find.byKey(const Key('from_wrap')), findsOneWidget);
    expect(find.byKey(const Key('from_custom')), findsNothing);
  });
}
