// Regression tests for issue #48 (2.20 layout regressions: welcome
// centring, suggestion width, one-row composer) and issue #49 (custom code
// block copy button), plus the image-tap and AI-user-id fixes shipped with
// them.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const user = ChatUser(id: 'u', firstName: 'U');
  const ai = ChatUser(id: 'ai', firstName: 'AI');
  const gemini = ChatUser(id: 'gemini', firstName: 'Gemini');

  Widget emptyState(WelcomeMessageConfig config, {bool topOffset = true}) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: ChatEmptyState(
            exampleQuestions: const [
              ExampleQuestion(question: 'Q1'),
              ExampleQuestion(question: 'Q2'),
            ],
            onQuestionTap: (_) {},
            welcomeMessageConfig: config,
            applyTopOffset: topOffset,
          ),
        ),
      ),
    );
  }

  Widget chatApp(
    ChatMessagesController controller,
    InputOptions input,
    FileUploadOptions upload,
  ) {
    return MaterialApp(
      home: Scaffold(
        body: AiChatWidget(
          currentUser: user,
          aiUser: gemini,
          controller: controller,
          onSendMessage: (_) {},
          inputOptions: input,
          fileUploadOptions: upload,
        ),
      ),
    );
  }

  group('issue #48 welcome', () {
    testWidgets('applyTopOffset false drops the offset', (tester) async {
      await tester.pumpWidget(
        emptyState(const WelcomeMessageConfig(title: 'Hi')),
      );
      final defaultTop = tester.getTopLeft(find.text('Hi')).dy;

      await tester.pumpWidget(
        emptyState(const WelcomeMessageConfig(title: 'Hi'), topOffset: false),
      );
      final noOffsetTop = tester.getTopLeft(find.text('Hi')).dy;

      // Default: the greeting sits ~38% down the 800px test viewport.
      expect(defaultTop, greaterThan(200));
      expect(noOffsetTop, lessThan(1));
    });

    testWidgets('centerVertically centres the greeting', (tester) async {
      final controller = ChatMessagesController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AiChatWidget(
              currentUser: user,
              aiUser: ai,
              controller: controller,
              onSendMessage: (_) {},
              welcomeMessageConfig: const WelcomeMessageConfig(
                title: 'Welcome',
                centerVertically: true,
              ),
              exampleQuestions: const [ExampleQuestion(question: 'Q1')],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Centred in the ~700px list area of the 800px view. With the 38%
      // offset added on top (the #48 bug) it landed below the middle.
      final top = tester.getTopLeft(find.text('Welcome')).dy;
      expect(top, greaterThan(100));
      expect(top, lessThan(400));
    });

    testWidgets('singleColumnQuestions stacks tiles', (tester) async {
      // flutter_test_config.dart uses a 400x800 view; the two-column grid
      // needs a reading column of at least 600px.
      tester.view.physicalSize = const Size(1000, 800);
      addTearDown(() => tester.view.physicalSize = const Size(400, 800));

      await tester.pumpWidget(emptyState(const WelcomeMessageConfig()));
      final gridQ1 = tester.getTopLeft(find.text('Q1')).dy;
      final gridQ2 = tester.getTopLeft(find.text('Q2')).dy;
      // A 1000px-wide view gives the two-column grid by default.
      expect(gridQ2, closeTo(gridQ1, 0.5));

      await tester.pumpWidget(
        emptyState(const WelcomeMessageConfig(singleColumnQuestions: true)),
      );
      final listQ1 = tester.getTopLeft(find.text('Q1')).dy;
      final listQ2 = tester.getTopLeft(find.text('Q2')).dy;
      expect(listQ2, greaterThan(listQ1 + 20));
    });
  });

  group('issue #48 composer', () {
    testWidgets('stacked default puts attach below', (tester) async {
      final controller = ChatMessagesController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        chatApp(controller, const InputOptions(), const FileUploadOptions()),
      );
      await tester.pump();

      final attach = tester.getRect(find.byTooltip('Attach files'));
      final field = tester.getRect(find.byType(TextField).first);
      expect(attach.center.dy, greaterThan(field.center.dy + 10));
    });

    testWidgets('singleRow keeps attach beside field', (tester) async {
      final controller = ChatMessagesController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        chatApp(
          controller,
          const InputOptions(composerLayout: ComposerLayout.singleRow),
          const FileUploadOptions(),
        ),
      );
      await tester.pump();

      final attach = tester.getRect(find.byTooltip('Attach files'));
      final field = tester.getRect(find.byType(TextField).first);
      expect(attach.center.dy, closeTo(field.center.dy, 2));
      expect(attach.center.dx, lessThan(field.left));
    });

    testWidgets('trailing attach in stacked layout', (tester) async {
      final controller = ChatMessagesController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        chatApp(
          controller,
          const InputOptions(),
          const FileUploadOptions(
            buttonPosition: AttachmentButtonPosition.trailing,
          ),
        ),
      );
      await tester.pump();

      final attach = tester.getRect(find.byTooltip('Attach files'));
      final field = tester.getRect(find.byType(TextField).first);
      expect(attach.center.dy, greaterThan(field.center.dy + 10));
      expect(attach.center.dx, greaterThan(field.center.dx));
    });

    testWidgets('trailing attach sits after field', (tester) async {
      final controller = ChatMessagesController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        chatApp(
          controller,
          const InputOptions(composerLayout: ComposerLayout.singleRow),
          const FileUploadOptions(
            buttonPosition: AttachmentButtonPosition.trailing,
          ),
        ),
      );
      await tester.pump();

      final attach = tester.getRect(find.byTooltip('Attach files'));
      final field = tester.getRect(find.byType(TextField).first);
      expect(attach.center.dy, closeTo(field.center.dy, 2));
      expect(attach.center.dx, greaterThan(field.right));
    });
  });

  group('custom AI user id', () {
    testWidgets('AiChatWidget passes the AI id on', (tester) async {
      final controller = ChatMessagesController();
      addTearDown(controller.dispose);
      expect(controller.aiUserId, isNull);
      await tester.pumpWidget(
        chatApp(controller, const InputOptions(), const FileUploadOptions()),
      );
      expect(controller.aiUserId, 'gemini');
    });

    test('aiUserId marks its replies as AI', () {
      final legacy = ChatMessagesController();
      final configured = ChatMessagesController();
      configured.aiUserId = 'gemini';
      addTearDown(legacy.dispose);
      addTearDown(configured.dispose);

      for (final controller in [legacy, configured]) {
        controller.addMessage(
          ChatMessage(text: 'hi', user: user, createdAt: DateTime(2026)),
        );
        controller.addMessage(
          ChatMessage(text: 'yo', user: gemini, createdAt: DateTime(2027)),
        );
      }

      bool? flag(ChatMessagesController c, String text) {
        final message = c.messages.firstWhere((m) => m.text == text);
        return message.customProperties?['isUserMessage'] as bool?;
      }

      // Without aiUserId only 'ai'/'bot'/'assistant' count as AI.
      expect(flag(legacy, 'yo'), isTrue);
      expect(flag(configured, 'yo'), isFalse);
      // Other people stay human either way.
      expect(flag(legacy, 'hi'), isTrue);
      expect(flag(configured, 'hi'), isTrue);
    });
  });

  group('issue #49 copy button', () {
    testWidgets('copyButtonBuilder replaces the icon', (tester) async {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async => null,
      );
      addTearDown(() {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        );
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CodeBlockView(
              code: 'print(1);',
              language: 'dart',
              copyButtonBuilder: (context, copied, onCopy) => TextButton(
                onPressed: onCopy,
                child: Text(copied ? 'Copied' : 'Copy'),
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.copy_rounded), findsNothing);
      expect(find.text('Copy'), findsOneWidget);

      await tester.tap(find.text('Copy'));
      await tester.pump();
      await tester.pumpAndSettle();
      expect(find.text('Copied'), findsOneWidget);

      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.text('Copy'), findsOneWidget);
    });

    testWidgets('showCopyButton false hides custom too', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CodeBlockView(
              code: 'print(1);',
              showCopyButton: false,
              copyButtonBuilder: (context, copied, onCopy) => const Text('X'),
            ),
          ),
        ),
      );
      expect(find.text('X'), findsNothing);
    });
  });

  testWidgets('enableImageTaps keeps onImageTap', (tester) async {
    final controller = ChatMessagesController();
    addTearDown(controller.dispose);
    controller.addMessage(
      ChatMessage(
        text: '![Test Image](https://example.com/test.jpg)',
        user: ai,
        createdAt: DateTime(2026),
        isMarkdown: true,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomChatWidget(
            currentUser: user,
            controller: controller,
            messages: controller.messages,
            onSend: (_) {},
            messageOptions: MessageOptions(
              enableImageTaps: true,
              onImageTap: (url, title, alt) {},
            ),
            typingUsers: const [],
            messageListOptions: const MessageListOptions(),
            readOnly: false,
            quickReplyOptions: const QuickReplyOptions(),
            scrollToBottomOptions: const ScrollToBottomOptions(),
            spacingConfig: const ChatSpacingConfig(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Before the fix enableImageTaps: true dropped the tappable builder, so
    // onImageTap could never fire.
    final markdown = tester.widget<Markdown>(find.byType(Markdown));
    expect(markdown.imageBuilder, isNotNull);
  });

  testWidgets('link-only markdown keeps the image builder', (tester) async {
    final controller = ChatMessagesController();
    addTearDown(controller.dispose);
    controller.addMessage(
      ChatMessage(
        text: '![Test Image](https://example.com/test.jpg)',
        user: ai,
        createdAt: DateTime(2026),
        isMarkdown: true,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomChatWidget(
            currentUser: user,
            controller: controller,
            messages: controller.messages,
            onSend: (_) {},
            messageOptions: MessageOptions(
              onTapLink: (text, href, title) {},
            ),
            typingUsers: const [],
            messageListOptions: const MessageListOptions(),
            readOnly: false,
            quickReplyOptions: const QuickReplyOptions(),
            scrollToBottomOptions: const ScrollToBottomOptions(),
            spacingConfig: const ChatSpacingConfig(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Unchanged from 2.20: only enableImageTaps without onImageTap falls
    // back to the default builder.
    final markdown = tester.widget<Markdown>(find.byType(Markdown));
    expect(markdown.imageBuilder, isNotNull);
  });
}
