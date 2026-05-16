// RTL chat surface tests.
//
// Mirrors the setup used by the new `example/lib/examples/rtl_chat.dart`
// screen so the README's advertised "wrap in Directionality.rtl and you're
// done" claim is pinned to a passing widget test. We don't import the
// example file directly — `test/` belongs to the package, not the example
// — so these tests reconstruct the minimal RTL wrap pattern instead.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';

void main() {
  group('RTL chat — Directionality wrap', () {
    late ChatMessagesController controller;
    late ChatUser currentUser;
    late ChatUser aiUser;

    setUp(() {
      controller = ChatMessagesController();
      currentUser = const ChatUser(id: 'user', name: 'أنت');
      aiUser = const ChatUser(id: 'ai', name: 'المساعد');
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets(
      'AiChatWidget wrapped in Directionality.rtl renders without crashing '
      'and exposes RTL direction to descendants',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(
                body: AiChatWidget(
                  currentUser: currentUser,
                  aiUser: aiUser,
                  controller: controller,
                  onSendMessage: (_) {},
                  exampleQuestions: const [
                    ExampleQuestion(question: 'ما هي عاصمة العراق؟'),
                    ExampleQuestion(question: 'اكتب لي قصيدة قصيرة'),
                  ],
                ),
              ),
            ),
          ),
        );

        await tester.pump();

        // No exception thrown during build/layout.
        expect(tester.takeException(), isNull);

        // AiChatWidget is in the tree.
        expect(find.byType(AiChatWidget), findsOneWidget);

        // Directionality resolves to rtl when read from inside the widget
        // (covers the "wrap once, descendants inherit" promise).
        final BuildContext chatContext =
            tester.element(find.byType(AiChatWidget));
        expect(Directionality.of(chatContext), TextDirection.rtl);
      },
    );

    testWidgets(
      'RTL surface accepts an Arabic message via the controller without '
      'throwing',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(
                body: AiChatWidget(
                  currentUser: currentUser,
                  aiUser: aiUser,
                  controller: controller,
                  onSendMessage: (_) {},
                ),
              ),
            ),
          ),
        );

        const arabicReply = 'بغداد هي عاصمة العراق';
        controller.addMessage(ChatMessage(
          text: arabicReply,
          user: aiUser,
          createdAt: DateTime.now(),
        ));

        // Settle animations/layout. Don't await an indefinite settle because
        // streaming widgets may keep tickers warm — bounded pump is enough.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(tester.takeException(), isNull);

        // The Arabic content is now in the controller's message list.
        expect(controller.messages.length, greaterThanOrEqualTo(1));
        expect(
          controller.messages.any((m) => m.text == arabicReply),
          isTrue,
        );

        // Ambient direction is still RTL after a message is added.
        final BuildContext chatContext =
            tester.element(find.byType(AiChatWidget));
        expect(Directionality.of(chatContext), TextDirection.rtl);
      },
    );
  });
}
