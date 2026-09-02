// ignore_for_file: deprecated_member_use_from_same_package
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';

/// Part of the documented-knob verification sweep (issue #41 Phase 0.5).
///
/// `AiChatWidget.aiName` was documented as "Name of the AI assistant (for
/// display)" but was never read anywhere — the displayed name always comes
/// from the `ChatUser.name` on `aiUser` (and on each message's `user`).
/// `aiName` is now `@Deprecated`; this test locks in the actual (and only
/// ever) source of truth for the displayed name so a future change can't
/// silently reintroduce a second, ignored name source.
void main() {
  testWidgets('the AI display name always comes from aiUser.name, not aiName',
      (tester) async {
    const testUser = ChatUser(id: 'user', name: 'Test User');
    const aiUser = ChatUser(id: 'ai', name: 'RealName');
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
            aiName: 'Ignored Name',
          ),
        ),
      ),
    );
    await tester.pump();

    controller.addMessage(ChatMessage(
      text: 'Hello',
      user: aiUser,
      createdAt: DateTime.now(),
    ));
    await tester.pumpAndSettle();

    expect(find.text('RealName'), findsOneWidget);
    expect(find.text('Ignored Name'), findsNothing);
  });
}
