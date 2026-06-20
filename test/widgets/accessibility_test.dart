// Accessibility tests. The default send button is icon-only; it must expose a
// semantic label (tooltip) for screen readers. The label is localizable via
// InputOptions.sendButtonTooltip.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';

void main() {
  Widget host({InputOptions? inputOptions}) {
    final controller = ChatMessagesController();
    addTearDown(controller.dispose);
    return MaterialApp(
      home: Scaffold(
        body: AiChatWidget(
          currentUser: const ChatUser(id: 'u', firstName: 'U'),
          aiUser: const ChatUser(id: 'ai', firstName: 'AI'),
          controller: controller,
          onSendMessage: (_) {},
          inputOptions: inputOptions,
        ),
      ),
    );
  }

  testWidgets('default send button exposes a semantic tooltip', (tester) async {
    await tester.pumpWidget(host());
    await tester.pump();

    expect(find.byTooltip('Send message'), findsOneWidget);
  });

  testWidgets('send button tooltip is localizable', (tester) async {
    await tester.pumpWidget(host(
      inputOptions: const InputOptions(sendButtonTooltip: 'إرسال'),
    ));
    await tester.pump();

    expect(find.byTooltip('إرسال'), findsOneWidget);
    expect(find.byTooltip('Send message'), findsNothing);
  });

}
