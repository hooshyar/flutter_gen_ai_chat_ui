import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_streaming_text_markdown/flutter_streaming_text_markdown.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const me = ChatUser(id: 'user', firstName: 'Me');
  const ai = ChatUser(id: 'ai', firstName: 'Assistant');

  const dartBlock = '```dart\nvoid main() {}\n```';

  setUp(CodeHighlighter.debugClearCache);

  /// Recursively collects every [TextSpan] in the tree.
  List<TextSpan> flatten(InlineSpan root) {
    final out = <TextSpan>[];
    if (root is TextSpan) {
      out.add(root);
      for (final child in root.children ?? const <InlineSpan>[]) {
        out.addAll(flatten(child));
      }
    }
    return out;
  }

  /// The [Text.rich] inside a [CodeBlockView] that renders the code body.
  Text codeTextOf(WidgetTester tester, Finder view) {
    final texts = tester.widgetList<Text>(
      find.descendant(of: view, matching: find.byType(Text)),
    );
    return texts.firstWhere((t) => t.textSpan != null);
  }

  /// Asserts the rendered code spans are monospace and carry no
  /// backgroundColor/background paint (the bug this slice fixes: every line
  /// of a fenced block used to get its own grey chip).
  void expectCleanMonoSpans(WidgetTester tester, Finder view) {
    final span = codeTextOf(tester, view).textSpan!;
    final spans = flatten(span);
    expect(spans, isNotEmpty);
    for (final s in spans) {
      expect(s.style?.fontFamily, contains('JetBrainsMono'));
      expect(s.style?.backgroundColor, isNull);
      expect(s.style?.background, isNull);
    }
  }

  Widget buildChat({
    ChatMessagesController? controller,
    List<ChatMessage>? messages,
    MessageOptions messageOptions = const MessageOptions(),
    bool streamingEnabled = true,
    bool streamingWordByWord = false,
    bool enableMathRendering = false,
    ThemeData? theme,
  }) {
    return MaterialApp(
      theme: theme,
      home: Scaffold(
        body: CustomChatWidget(
          currentUser: me,
          controller: controller,
          messages: messages ?? controller?.messages ?? const [],
          onSend: (_) {},
          messageOptions: messageOptions,
          typingUsers: const [],
          messageListOptions: const MessageListOptions(),
          readOnly: false,
          quickReplyOptions: const QuickReplyOptions(),
          scrollToBottomOptions: const ScrollToBottomOptions(),
          spacingConfig: const ChatSpacingConfig(),
          streamingEnabled: streamingEnabled,
          streamingWordByWord: streamingWordByWord,
          enableMathRendering: enableMathRendering,
        ),
      ),
    );
  }

  ChatMessage codeMessage(
    String text, {
    String? id,
    Map<String, dynamic>? extraProps,
  }) {
    return ChatMessage(
      text: text,
      user: ai,
      createdAt: DateTime(2026, 1, 1),
      isMarkdown: true,
      customProperties: {if (id != null) 'id': id, ...?extraProps},
    );
  }

  group('code block rendering — every chat markdown path', () {
    testWidgets('static markdown renders CodeBlockView with clean mono spans', (
      tester,
    ) async {
      final controller = ChatMessagesController();
      controller.addMessage(codeMessage('Here:\n\n$dartBlock'));

      await tester.pumpWidget(
        buildChat(controller: controller, streamingEnabled: false),
      );
      await tester.pump();

      final view = find.byType(CodeBlockView);
      expect(view, findsOneWidget);
      expect(tester.widget<CodeBlockView>(view).language, 'dart');
      expectCleanMonoSpans(tester, view);

      // The pre builder is registered on the underlying markdown widget.
      final markdown = tester.widget<Markdown>(find.byType(Markdown));
      expect(markdown.builders['pre'], isA<CodeBlockMarkdownBuilder>());
    });

    testWidgets('interactive markdown path (onTapLink) renders CodeBlockView', (
      tester,
    ) async {
      final controller = ChatMessagesController();
      controller.addMessage(codeMessage(dartBlock));

      await tester.pumpWidget(
        buildChat(
          controller: controller,
          messageOptions: MessageOptions(onTapLink: (_, __, ___) {}),
        ),
      );
      await tester.pump();

      final view = find.byType(CodeBlockView);
      expect(view, findsOneWidget);
      expectCleanMonoSpans(tester, view);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'streaming reveal: unclosed fence withheld without throwing, closed '
      'block renders once with a single highlight pass',
      (tester) async {
        final controller = ChatMessagesController();
        await tester.pumpWidget(buildChat(controller: controller));

        controller.addStreamingMessage(
          codeMessage('Working on it:\n\n```dart\nvoid ma', id: 's1'),
        );
        await tester.pumpWidget(buildChat(controller: controller));
        await tester.pump(const Duration(milliseconds: 120));

        // Fence still open — withheld, so no code block and no crash.
        expect(find.byType(CodeBlockView), findsNothing);
        expect(tester.takeException(), isNull);

        controller.updateMessage(
          codeMessage(
            'Working on it:\n\n$dartBlock\n\nDone.',
            id: 's1',
            extraProps: {'isStreaming': true},
          ),
        );
        // Several reveal ticks while the stream is still marked active.
        for (var i = 0; i < 6; i++) {
          await tester.pump(const Duration(milliseconds: 60));
        }
        controller.stopStreamingMessage('s1');
        // Let the reveal drain to the end and settle into the static path.
        for (var i = 0; i < 30; i++) {
          await tester.pump(const Duration(milliseconds: 60));
        }

        final view = find.byType(CodeBlockView);
        expect(view, findsOneWidget);
        expectCleanMonoSpans(tester, view);
        expect(tester.takeException(), isNull);

        // The fence only ever rendered with its final content, so the
        // highlighter ran exactly once across all reveal ticks and the
        // subsequent static render (everything else was a cache hit).
        expect(CodeHighlighter.debugHighlightCount, 1);
      },
    );

    testWidgets(
      'math path (LaTeX + enableMathRendering) renders CodeBlockView',
      (tester) async {
        final controller = ChatMessagesController();
        controller.addMessage(
          codeMessage('$dartBlock\n\nAnd math:\n\n\$\$e=mc^2\$\$'),
        );

        await tester.pumpWidget(
          buildChat(
            controller: controller,
            streamingEnabled: false,
            enableMathRendering: true,
          ),
        );
        await tester.pump();

        expect(find.byType(MathMarkdown), findsOneWidget);
        final view = find.byType(CodeBlockView);
        expect(view, findsOneWidget);
        expectCleanMonoSpans(tester, view);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'word-by-word StreamingText path renders fenced code via codeBuilder',
      (tester) async {
        // No controller: controller.addMessage would mark the AI message as
        // currently-streaming, which takes the reveal path instead of the
        // one-shot StreamingText animation.
        final messages = <ChatMessage>[];
        await tester.pumpWidget(
          buildChat(messages: messages, streamingWordByWord: true),
        );

        // A complete AI message added externally → one-shot typing animation.
        messages.add(
          codeMessage('Here is code:\n\n$dartBlock\n\nDone.', id: 'w1'),
        );
        await tester.pumpWidget(
          buildChat(messages: messages, streamingWordByWord: true),
        );

        // Advance the typing animation until the closed fence is revealed
        // inside the StreamingText subtree.
        var found = false;
        for (var i = 0; i < 100 && !found; i++) {
          await tester.pump(const Duration(milliseconds: 100));
          found = find
              .descendant(
                of: find.byType(StreamingText),
                matching: find.byType(CodeBlockView),
              )
              .evaluate()
              .isNotEmpty;
        }

        expect(find.byType(StreamingText), findsOneWidget);
        expect(find.byType(CodeBlockView), findsOneWidget);
        expectCleanMonoSpans(tester, find.byType(CodeBlockView));
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('MessageOptions code block flags', () {
    testWidgets('enableSyntaxHighlighting:false renders a single-style span', (
      tester,
    ) async {
      final controller = ChatMessagesController();
      controller.addMessage(codeMessage(dartBlock));

      await tester.pumpWidget(
        buildChat(
          controller: controller,
          streamingEnabled: false,
          messageOptions: const MessageOptions(enableSyntaxHighlighting: false),
        ),
      );
      await tester.pump();

      final span =
          codeTextOf(tester, find.byType(CodeBlockView)).textSpan! as TextSpan;
      expect(span.children, isNull);
      expect(span.text, contains('void main()'));
      expect(span.style?.fontFamily, contains('JetBrainsMono'));
      expect(CodeHighlighter.debugHighlightCount, 0);
    });

    testWidgets('showCodeBlockCopyButton:false hides the copy affordance', (
      tester,
    ) async {
      final controller = ChatMessagesController();
      controller.addMessage(codeMessage(dartBlock));

      await tester.pumpWidget(
        buildChat(
          controller: controller,
          streamingEnabled: false,
          messageOptions: const MessageOptions(showCodeBlockCopyButton: false),
        ),
      );
      await tester.pump();

      expect(find.byType(CodeBlockView), findsOneWidget);
      // Scoped to the code block: MessageActionRow's own copy control (now
      // shown by default) uses the same glyph (Icons.content_copy_rounded
      // aliases Icons.copy_rounded), so an unscoped search would also match
      // it.
      expect(
        find.descendant(
          of: find.byType(CodeBlockView),
          matching: find.byIcon(Icons.copy_rounded),
        ),
        findsNothing,
      );
    });

    testWidgets('copy button copies the raw code without fences', (
      tester,
    ) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(() {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        );
      });

      final controller = ChatMessagesController();
      controller.addMessage(codeMessage(dartBlock));
      await tester.pumpWidget(
        buildChat(controller: controller, streamingEnabled: false),
      );
      await tester.pump();

      // Scoped to the code block: MessageActionRow's own copy control (now
      // shown by default) uses the same glyph (Icons.content_copy_rounded
      // aliases Icons.copy_rounded), so an unscoped tap would be ambiguous.
      await tester.tap(
        find.descendant(
          of: find.byType(CodeBlockView),
          matching: find.byIcon(Icons.copy_rounded),
        ),
      );
      await tester.pump();
      expect(copied, 'void main() {}');
    });

    testWidgets('codeBlockTheme overrides the resolved palette', (
      tester,
    ) async {
      final controller = ChatMessagesController();
      controller.addMessage(codeMessage(dartBlock));

      const custom = CodeBlockTheme(
        backgroundColor: Colors.black,
        borderColor: Colors.black,
        headerTextColor: Colors.white,
        baseStyle: TextStyle(
          fontFamily: CodeBlockTheme.monoFontFamily,
          package: 'flutter_gen_ai_chat_ui',
          fontFamilyFallback: CodeBlockTheme.monoFontFallback,
          color: Colors.white,
        ),
        commentColor: Colors.white,
        stringColor: Colors.white,
        numberColor: Colors.white,
        keywordColor: Color(0xFF00FF00),
        typeColor: Colors.white,
        functionColor: Colors.white,
        annotationColor: Colors.white,
        punctuationColor: Colors.white,
      );

      await tester.pumpWidget(
        buildChat(
          controller: controller,
          streamingEnabled: false,
          messageOptions: MessageOptions(codeBlockTheme: custom),
        ),
      );
      await tester.pump();

      final view = tester.widget<CodeBlockView>(find.byType(CodeBlockView));
      expect(view.theme, same(custom));

      final spans = flatten(
        codeTextOf(tester, find.byType(CodeBlockView)).textSpan!,
      );
      final keyword = spans.firstWhere((s) => s.text == 'void');
      expect(keyword.style?.color, const Color(0xFF00FF00));
    });
  });

  group('overrides and theming', () {
    testWidgets(
      'user markdownStyleSheet codeblockDecoration still wraps the block',
      (tester) async {
        final controller = ChatMessagesController();
        controller.addMessage(codeMessage(dartBlock));

        const decoration = BoxDecoration(color: Color(0xFF123456));
        await tester.pumpWidget(
          buildChat(
            controller: controller,
            streamingEnabled: false,
            messageOptions: MessageOptions(
              markdownStyleSheet: MarkdownStyleSheet(
                codeblockDecoration: decoration,
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(CodeBlockView), findsOneWidget);
        final containers = tester.widgetList<Container>(
          find.descendant(
            of: find.byType(Markdown),
            matching: find.byType(Container),
          ),
        );
        expect(
          containers.any((c) => c.decoration == decoration),
          isTrue,
          reason: 'flutter_markdown_plus should wrap the pre builder output in '
              'the stylesheet codeblockDecoration',
        );
      },
    );

    testWidgets('user markdownBuilder still wins over the default rendering', (
      tester,
    ) async {
      final controller = ChatMessagesController();
      controller.addMessage(codeMessage(dartBlock));

      await tester.pumpWidget(
        buildChat(
          controller: controller,
          streamingEnabled: false,
          messageOptions: MessageOptions(
            markdownBuilder: (context, text, styleSheet, isUser) =>
                const Text('CUSTOM MARKDOWN'),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('CUSTOM MARKDOWN'), findsOneWidget);
      expect(find.byType(CodeBlockView), findsNothing);
    });

    testWidgets('dark ambient theme resolves CodeBlockTheme.dark colours', (
      tester,
    ) async {
      final controller = ChatMessagesController();
      controller.addMessage(codeMessage(dartBlock));

      await tester.pumpWidget(
        buildChat(
          controller: controller,
          streamingEnabled: false,
          theme: ThemeData.dark(),
        ),
      );
      await tester.pump();

      final spans = flatten(
        codeTextOf(tester, find.byType(CodeBlockView)).textSpan!,
      );
      final keyword = spans.firstWhere((s) => s.text == 'void');
      expect(keyword.style?.color, CodeBlockTheme.dark().keywordColor);
    });
  });
}
