// Golden (screenshot-diff) tests for the core chat surfaces.
//
// These are meaningful ONLY when run locally on macOS: `flutter_test_config.dart`
// swaps in an always-passing comparator on non-macOS platforms (font
// rendering differs too much across OSes for pixel-perfect CI comparison —
// see that file's comment). On Linux CI these tests still execute (catching
// crashes/exceptions) but the image comparison itself is a no-op.
//
// To (re)generate baselines after an intentional visual change, run on a Mac:
//   flutter test --update-goldens test/golden/chat_golden_test.dart
// then review the diff in test/golden/goldens/ before committing it.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';

void main() {
  const testUser = ChatUser(id: 'user', name: 'You');
  const aiUser = ChatUser(id: 'ai', name: 'Assistant');

  Widget wrap(Widget child,
      {TextDirection direction = TextDirection.ltr, ThemeData? theme}) {
    return MaterialApp(
      theme: theme,
      home: Directionality(
        textDirection: direction,
        child: Material(
          child: SizedBox(
            width: 400,
            height: 600,
            child: child,
          ),
        ),
      ),
    );
  }

  testWidgets('default bubble — user + AI messages', (tester) async {
    final controller = ChatMessagesController(
      initialMessages: [
        ChatMessage(
          text: 'What is the capital of Iraq?',
          user: testUser,
          createdAt: DateTime(2026, 1, 1, 12, 0),
        ),
        ChatMessage(
          text: 'The capital of Iraq is Baghdad.',
          user: aiUser,
          createdAt: DateTime(2026, 1, 1, 12, 0, 5),
        ),
      ],
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(wrap(
      AiChatWidget(
        currentUser: testUser,
        aiUser: aiUser,
        controller: controller,
        onSendMessage: (_) async {},
        enableMarkdownStreaming: false,
      ),
    ));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(AiChatWidget),
      matchesGoldenFile('goldens/default_bubble.png'),
    );
  });

  testWidgets('welcome message with example questions', (tester) async {
    final controller = ChatMessagesController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(wrap(
      AiChatWidget(
        currentUser: testUser,
        aiUser: aiUser,
        controller: controller,
        onSendMessage: (_) async {},
        enableMarkdownStreaming: false,
        welcomeMessageConfig: const WelcomeMessageConfig(
          title: 'How can I help you today?',
        ),
        exampleQuestions: const [
          ExampleQuestion(question: 'What is the capital of Iraq?'),
          ExampleQuestion(question: 'Write me a short poem'),
        ],
      ),
    ));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(AiChatWidget),
      matchesGoldenFile('goldens/welcome_message.png'),
    );
  });

  testWidgets('streaming message mid-stream (partial reveal)', (tester) async {
    final controller = ChatMessagesController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(wrap(
      AiChatWidget(
        currentUser: testUser,
        aiUser: aiUser,
        controller: controller,
        onSendMessage: (_) async {},
        // Streaming animation intentionally left OFF for the golden itself —
        // the animation's live per-frame reveal is exercised by
        // streaming_rapid_update_test.dart / streaming_disable_test.dart;
        // this golden pins the STATIC appearance of a partially-arrived
        // response (what a real mid-stream frame looks like), not the
        // ticking animation, which would make the golden nondeterministic.
        enableMarkdownStreaming: false,
      ),
    ));

    controller.addMessage(ChatMessage(
      text: 'What is the capital of Ira',
      user: aiUser,
      createdAt: DateTime(2026, 1, 1, 12, 0),
      customProperties: const {'id': 'resp1', 'isStreaming': true},
    ));
    await tester.pump();

    await expectLater(
      find.byType(AiChatWidget),
      matchesGoldenFile('goldens/streaming_mid_stream.png'),
    );
  });

  testWidgets('markdown code block rendering', (tester) async {
    final controller = ChatMessagesController(
      initialMessages: [
        ChatMessage(
          text: 'Here\'s a Dart example:\n\n'
              '```dart\n'
              'void main() {\n'
              '  print(\'Hello, world!\');\n'
              '}\n'
              '```',
          user: aiUser,
          createdAt: DateTime(2026, 1, 1, 12, 0),
          isMarkdown: true,
        ),
      ],
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(wrap(
      AiChatWidget(
        currentUser: testUser,
        aiUser: aiUser,
        controller: controller,
        onSendMessage: (_) async {},
        enableMarkdownStreaming: false,
      ),
    ));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(AiChatWidget),
      matchesGoldenFile('goldens/code_block.png'),
    );
  });

  testWidgets('RTL layout (Arabic)', (tester) async {
    const rtlUser = ChatUser(id: 'user', name: 'أنت');
    const rtlAi = ChatUser(id: 'ai', name: 'المساعد');
    final controller = ChatMessagesController(
      initialMessages: [
        ChatMessage(
          text: 'ما هي عاصمة العراق؟',
          user: rtlUser,
          createdAt: DateTime(2026, 1, 1, 12, 0),
        ),
        ChatMessage(
          text: 'بغداد هي عاصمة العراق',
          user: rtlAi,
          createdAt: DateTime(2026, 1, 1, 12, 0, 5),
        ),
      ],
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(wrap(
      AiChatWidget(
        currentUser: rtlUser,
        aiUser: rtlAi,
        controller: controller,
        onSendMessage: (_) async {},
        enableMarkdownStreaming: false,
      ),
      direction: TextDirection.rtl,
    ));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(AiChatWidget),
      matchesGoldenFile('goldens/rtl_layout.png'),
    );
  });

  testWidgets(
      'CustomThemeExtension.chatgpt() brand preset actually applies '
      '(regression guard: this extension used to be read nowhere)',
      (tester) async {
    final controller = ChatMessagesController(
      initialMessages: [
        ChatMessage(
          text: 'What is the capital of Iraq?',
          user: testUser,
          createdAt: DateTime(2026, 1, 1, 12, 0),
        ),
        ChatMessage(
          text: 'The capital of Iraq is Baghdad.',
          user: aiUser,
          createdAt: DateTime(2026, 1, 1, 12, 0, 5),
        ),
      ],
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(wrap(
      AiChatWidget(
        currentUser: testUser,
        aiUser: aiUser,
        controller: controller,
        onSendMessage: (_) async {},
        enableMarkdownStreaming: false,
      ),
      theme: ThemeData(extensions: [CustomThemeExtension.chatgpt()]),
    ));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(AiChatWidget),
      matchesGoldenFile('goldens/chatgpt_theme_preset.png'),
    );
  });
}
