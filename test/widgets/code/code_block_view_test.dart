import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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

  /// The [Text.rich] inside a [CodeBlockView] that renders the code body
  /// (as opposed to the header's language label, which has no `textSpan`).
  Text codeTextOf(WidgetTester tester, Finder view) {
    final texts = tester.widgetList<Text>(
      find.descendant(of: view, matching: find.byType(Text)),
    );
    return texts.firstWhere((t) => t.textSpan != null);
  }

  Widget wrap(Widget child, {TextDirection direction = TextDirection.ltr}) {
    return MaterialApp(
      home: Directionality(
        textDirection: direction,
        child: Scaffold(body: Center(child: child)),
      ),
    );
  }

  group('CodeBlockView', () {
    testWidgets('copy button copies raw code and shows transient check icon',
        (tester) async {
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
        tester.binding.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null);
      });

      await tester.pumpWidget(
        wrap(
          MarkdownBody(
            data: '```dart\nvoid main() {}\n```',
            builders: {'pre': CodeBlockMarkdownBuilder()},
          ),
        ),
      );

      expect(find.byIcon(Icons.copy_rounded), findsOneWidget);
      await tester.tap(find.byIcon(Icons.copy_rounded));
      await tester.pump();
      // The icon swap runs inside an AnimatedSwitcher (ChatMotion.fast);
      // let its cross-fade finish before asserting on the settled icon.
      await tester.pumpAndSettle();

      expect(copied, 'void main() {}');
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      expect(find.byIcon(Icons.copy_rounded), findsNothing);

      await tester.pump(const Duration(seconds: 2));
      // Settle the AnimatedSwitcher's cross-fade back to the copy icon.
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.copy_rounded), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsNothing);
    });

    testWidgets('a 300-char line scrolls horizontally without overflow',
        (tester) async {
      final longLine = 'final s = "${'x' * 300}";';
      await tester.pumpWidget(
        wrap(CodeBlockView(code: longLine, language: 'dart')),
      );

      expect(tester.takeException(), isNull);
      final scrollView = tester.widget<SingleChildScrollView>(
        find.descendant(
          of: find.byType(CodeBlockView),
          matching: find.byType(SingleChildScrollView),
        ),
      );
      expect(scrollView.scrollDirection, Axis.horizontal);

      final codeText = codeTextOf(tester, find.byType(CodeBlockView));
      expect(codeText.softWrap, isFalse);
      expect(
        tester.getSize(find.byWidget(codeText)).width,
        greaterThan(tester.getSize(find.byType(CodeBlockView)).width),
      );
    });

    testWidgets('stays LTR inside an RTL directionality', (tester) async {
      await tester.pumpWidget(
        wrap(
          const CodeBlockView(code: 'final x = 1;', language: 'dart'),
          direction: TextDirection.rtl,
        ),
      );

      final codeText = codeTextOf(tester, find.byType(CodeBlockView));
      final context = tester.element(find.byWidget(codeText));
      expect(Directionality.of(context), TextDirection.ltr);
    });

    testWidgets('code spans use JetBrainsMono and never set backgroundColor',
        (tester) async {
      await tester.pumpWidget(
        wrap(const CodeBlockView(code: 'final x = "hi";', language: 'dart')),
      );

      final span = codeTextOf(tester, find.byType(CodeBlockView)).textSpan!;
      final spans = flatten(span);
      expect(spans.length, greaterThan(1));
      for (final s in spans) {
        expect(s.style?.fontFamily, contains('JetBrainsMono'));
        expect(s.style?.backgroundColor, isNull);
        expect(s.style?.background, isNull);
      }
    });

    testWidgets('baseStyle override keeps family/size but drops background',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          const CodeBlockView(
            code: 'final x = 1;',
            language: 'dart',
            baseStyle: TextStyle(
              fontSize: 20,
              backgroundColor: Colors.red,
            ),
          ),
        ),
      );

      final span = codeTextOf(tester, find.byType(CodeBlockView)).textSpan!;
      for (final s in flatten(span)) {
        expect(s.style?.fontSize, 20);
        expect(s.style?.backgroundColor, isNull);
        expect(s.style?.fontFamily, contains('JetBrainsMono'));
      }
    });

    testWidgets('enableSyntaxHighlighting false renders a single-style span',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          const CodeBlockView(
            code: 'void main() {}',
            language: 'dart',
            enableSyntaxHighlighting: false,
          ),
        ),
      );

      final span =
          codeTextOf(tester, find.byType(CodeBlockView)).textSpan! as TextSpan;
      expect(span.text, 'void main() {}');
      expect(span.children, isNull);
    });
  });

  group('CodeBlockMarkdownBuilder', () {
    testWidgets(
        'pre builder renders one CodeBlockView with parsed language, no span '
        'backgroundColor despite stylesheet code background', (tester) async {
      await tester.pumpWidget(
        wrap(
          MarkdownBody(
            data: '```dart\nvoid main() {}\n```',
            builders: {'pre': CodeBlockMarkdownBuilder()},
            styleSheet: MarkdownStyleSheet(
              code: const TextStyle(backgroundColor: Colors.grey),
            ),
          ),
        ),
      );

      final view = find.byType(CodeBlockView);
      expect(view, findsOneWidget);
      expect(tester.widget<CodeBlockView>(view).language, 'dart');

      final span = codeTextOf(tester, view).textSpan!;
      for (final s in flatten(span)) {
        expect(s.style?.backgroundColor, isNull);
        expect(s.style?.background, isNull);
      }
    });

    testWidgets('unfenced-language block renders with no language label',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          MarkdownBody(
            data: '```\nplain code\n```',
            builders: {'pre': CodeBlockMarkdownBuilder()},
          ),
        ),
      );

      final view = find.byType(CodeBlockView);
      expect(view, findsOneWidget);
      expect(tester.widget<CodeBlockView>(view).language, isNull);
      expect(find.byIcon(Icons.copy_rounded), findsOneWidget);
    });
  });
}
