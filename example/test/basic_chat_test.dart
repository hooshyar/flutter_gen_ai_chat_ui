import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';
import 'package:flutter_gen_ai_chat_ui/src/widgets/message/streaming_caret.dart';
import 'package:flutter_gen_ai_chat_ui_example/examples/basic_chat.dart';

/// Regression coverage for the Basic demo's double-send gap: the old
/// `_onSendMessage` called `_streamSub?.cancel()` on a second send without
/// ever closing the FIRST reply's stream (no `stopStreamingMessage`, no
/// `isLoading`/`onCancelGenerating` guard at all), so a second send fired
/// mid-stream left the first reply with a permanent caret and no Copy
/// button. This drives `onSendMessage` directly (bypassing the send/stop
/// button) so it exercises the state-management fix itself rather than the
/// UI-level guard that also got wired in.
void main() {
  testWidgets(
      'a second send mid-stream finalizes the first reply '
      '(no stuck caret, Copy present for both)', (tester) async {
    await tester
        .pumpWidget(MaterialApp(home: BasicChatExample(onToggleTheme: () {})));
    await tester.pump();

    final onSendMessage =
        tester.widget<AiChatWidget>(find.byType(AiChatWidget)).onSendMessage;
    const currentUser = ChatUser(id: 'user', name: 'You');

    onSendMessage(ChatMessage(
      text: 'Tell me about Flutter',
      user: currentUser,
      createdAt: DateTime.now(),
    ));

    // ~400ms in small steps - the first reply is still mid-stream (the mock
    // service's initial "thinking" delay plus ~25-40ms/word streaming keeps
    // a multi-sentence reply going well past this).
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    onSendMessage(ChatMessage(
      text: 'Tell me about Dart',
      user: currentUser,
      createdAt: DateTime.now(),
    ));

    // Bounded pump loop until both streams finish. `pumpAndSettle` would
    // time out here: `StreamingCaret` runs a repeating (reverse: true)
    // animation ticker for as long as any message is open, so there is
    // never a fully-settled frame while a caret is on screen.
    for (var i = 0; i < 120; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find.byType(StreamingCaret).evaluate().isEmpty) break;
    }

    expect(
      find.byType(StreamingCaret),
      findsNothing,
      reason: 'both replies must be fully closed out once streaming ends',
    );
    expect(
      find.byTooltip('Copy'),
      findsNWidgets(2),
      reason: 'the first reply must not be left stuck open without a '
          'Copy action just because a second send arrived mid-stream',
    );
    expect(tester.takeException(), isNull);
  });
}
