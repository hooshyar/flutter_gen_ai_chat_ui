import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';

/// Part of the documented-knob verification sweep (task-002 / issue #41
/// Phase 0.5).
///
/// `InputOptions.autocorrect` (defaults to `true`) was never passed to the
/// underlying `TextField` in `chat_input.dart` — setting it to `false` had
/// no effect at all. Fixed by wiring `autocorrect: options.autocorrect`
/// into the `TextField`.
void main() {
  const testUser = ChatUser(id: 'user', name: 'Test User');
  const aiUser = ChatUser(id: 'ai', name: 'AI Assistant');

  testWidgets('InputOptions.autocorrect reaches the underlying TextField',
      (tester) async {
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
            inputOptions: const InputOptions(autocorrect: false),
          ),
        ),
      ),
    );
    await tester.pump();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.autocorrect, isFalse);
  });

  testWidgets('InputOptions.autocorrect defaults to true (unchanged)',
      (tester) async {
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
          ),
        ),
      ),
    );
    await tester.pump();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.autocorrect, isTrue);
  });
}
