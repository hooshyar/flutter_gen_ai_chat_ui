import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';

/// Slice D3: pre-first-token "Thinking" state (`DESIGN.md` §8.7).
void main() {
  late ChatMessagesController controller;
  late ChatUser testUser;
  late ChatUser aiUser;

  setUp(() {
    controller = ChatMessagesController();
    testUser = const ChatUser(id: 'user', name: 'Test User');
    aiUser = const ChatUser(id: 'ai', name: 'AI Assistant');
  });

  tearDown(() => controller.dispose());

  testWidgets('"Thinking" is present while loading with no AI text',
      (tester) async {
    controller.addMessage(
      ChatMessage.loading(user: aiUser, id: 'loading-1'),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: AiChatWidget(
            currentUser: testUser,
            aiUser: aiUser,
            controller: controller,
            onSendMessage: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Thinking'), findsOneWidget);
  });

  testWidgets('reduced motion collapses the thinking sweep to a static frame',
      (tester) async {
    controller.addMessage(
      ChatMessage.loading(user: aiUser, id: 'loading-1'),
    );

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: Material(
          child: AiChatWidget(
            currentUser: testUser,
            aiUser: aiUser,
            controller: controller,
            onSendMessage: (_) {},
          ),
        ),
      ),
    );

    // pumpAndSettle throws if a repeating animation is still ticking, so
    // this is the load-bearing assertion: no running animation remains.
    await tester.pumpAndSettle();

    expect(find.text('Thinking'), findsOneWidget);
  });
}
