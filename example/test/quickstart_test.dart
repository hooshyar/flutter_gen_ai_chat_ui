import 'package:flutter/material.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';
import 'package:flutter_gen_ai_chat_ui/src/widgets/message/streaming_caret.dart';
import 'package:flutter_gen_ai_chat_ui_example/quickstart.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('the README quick start streams a reply and closes it',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ChatScreen()));
    await tester.pump();

    final onSendMessage =
        tester.widget<AiChatWidget>(find.byType(AiChatWidget)).onSendMessage;
    onSendMessage(ChatMessage(
      text: 'Hello',
      user: const ChatUser(id: 'user', name: 'You'),
      createdAt: DateTime.now(),
    ));

    // Bounded pump loop: the caret's repeating animation never settles
    // while the reply is open, so pumpAndSettle would time out.
    for (var i = 0; i < 200; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (i > 10 && find.byType(StreamingCaret).evaluate().isEmpty) break;
    }
    // Let the reveal animation finish.
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(tester.takeException(), isNull);
    expect(find.byType(StreamingCaret), findsNothing);
    expect(
      find.textContaining('the reply closes when the stream ends',
          findRichText: true),
      findsOneWidget,
    );
  });
}
