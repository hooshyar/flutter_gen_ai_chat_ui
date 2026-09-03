// Golden (screenshot-diff) tests for `ScrollBehaviorConfig.pinDuringStreaming`
// (issue #42 follow-up). Same caveats as chat_golden_test.dart: pixel
// comparison is only enforced on macOS; regenerate on a Mac with
//   flutter test --update-goldens test/golden/streaming_pin_golden_test.dart
//
// The two goldens are deliberately the SAME scenario (one short question, one
// long streaming answer, captured mid-stream) with the pin off and on, so the
// pair doubles as before/after evidence: off = the answer's first lines have
// scrolled away, on = they are held at the top and the rest waits below.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';

void main() {
  const testUser = ChatUser(id: 'user', name: 'You');
  const aiUser = ChatUser(id: 'ai', name: 'Assistant');

  final longAnswer = List.generate(
    60,
    (i) => 'Paragraph ${i + 1}. A long answer keeps arriving while you read.',
  ).join('\n\n');

  Future<void> pumpScenario(
    WidgetTester tester,
    StreamingPinAnchor anchor,
  ) async {
    final controller = ChatMessagesController(
      scrollBehaviorConfig: ScrollBehaviorConfig(pinDuringStreaming: anchor),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(MaterialApp(
      home: Material(
        child: SizedBox(
          width: 400,
          height: 600,
          child: AiChatWidget(
            currentUser: testUser,
            aiUser: aiUser,
            controller: controller,
            onSendMessage: (_) async {},
            enableMarkdownStreaming: false,
          ),
        ),
      ),
    ));
    await tester.pump();

    controller.addMessage(ChatMessage(
      text: 'Explain how the pin works.',
      user: testUser,
      createdAt: DateTime(2026, 1, 1, 12),
      customProperties: const {'id': 'q', 'isUserMessage': true},
    ));
    await tester.pump();

    const props = {'id': 'a', 'responseId': 'a', 'isStartOfResponse': true};
    controller.addMessage(ChatMessage(
      text: '',
      user: aiUser,
      createdAt: DateTime(2026, 1, 1, 12, 0, 1),
      customProperties: const {...props, 'isStreaming': true},
    ));
    await tester.pump();
    for (var i = 1; i <= 4; i++) {
      controller.updateMessage(ChatMessage(
        text: longAnswer.substring(0, (longAnswer.length * i / 4).floor()),
        user: aiUser,
        createdAt: DateTime(2026, 1, 1, 12, 0, 1),
        customProperties: const {...props, 'isStreaming': true},
      ));
      await tester.pump();
      await tester.pump();
    }
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  }

  testWidgets('streaming pin OFF — bottom follows, answer start scrolled away',
      (tester) async {
    await pumpScenario(tester, StreamingPinAnchor.none);
    await expectLater(
      find.byType(AiChatWidget),
      matchesGoldenFile('goldens/streaming_pin_off.png'),
    );
  });

  testWidgets('streaming pin ON — answer start held at the viewport top',
      (tester) async {
    await pumpScenario(tester, StreamingPinAnchor.responseStart);
    await expectLater(
      find.byType(AiChatWidget),
      matchesGoldenFile('goldens/streaming_pin_on.png'),
    );
  });
}
