import 'package:flutter/material.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';
import 'package:flutter_gen_ai_chat_ui/src/widgets/rich_message_content.dart';
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

  /// The [Text.rich] inside a [CodeBlockView] that renders the code body.
  Text codeTextOf(WidgetTester tester, Finder view) {
    final texts = tester.widgetList<Text>(
      find.descendant(of: view, matching: find.byType(Text)),
    );
    return texts.firstWhere((t) => t.textSpan != null);
  }

  Widget wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );
  }

  group('MarkdownContent code blocks', () {
    testWidgets(
        'enableSyntaxHighlighting false renders plain code in a '
        'CodeBlockView', (tester) async {
      await tester.pumpWidget(
        wrap(
          const MarkdownContent(
            markdown: '```dart\nvoid main() {}\n```',
            enableSyntaxHighlighting: false,
          ),
        ),
      );

      final view = find.byType(CodeBlockView);
      expect(view, findsOneWidget);
      final widget = tester.widget<CodeBlockView>(view);
      expect(widget.enableSyntaxHighlighting, isFalse);
      expect(widget.language, 'dart');

      final span = codeTextOf(tester, view).textSpan! as TextSpan;
      expect(span.text, 'void main() {}');
      expect(span.children, isNull);
    });

    testWidgets(
        'enableSyntaxHighlighting true renders multiple coloured '
        'spans', (tester) async {
      await tester.pumpWidget(
        wrap(
          const MarkdownContent(
            markdown: '```dart\nvoid main() { return 42; }\n```',
            enableSyntaxHighlighting: true,
          ),
        ),
      );

      final view = find.byType(CodeBlockView);
      expect(view, findsOneWidget);

      final spans = flatten(codeTextOf(tester, view).textSpan!);
      expect(spans.length, greaterThan(1));
      final colors = spans.map((s) => s.style?.color).toSet();
      expect(colors.length, greaterThan(1));
      for (final s in spans) {
        expect(s.style?.fontFamily, contains('JetBrainsMono'));
        expect(s.style?.backgroundColor, isNull);
      }
    });

    testWidgets('legacy codeTheme maps token colors, ignores unknown keys', (
      tester,
    ) async {
      const keywordColor = Color(0xFF123456);
      await tester.pumpWidget(
        wrap(
          const MarkdownContent(
            markdown: '```dart\nreturn 42\n```',
            codeTheme: {
              'keyword': TextStyle(color: keywordColor),
              'not-a-token': TextStyle(color: Colors.red),
            },
          ),
        ),
      );

      final view = find.byType(CodeBlockView);
      expect(view, findsOneWidget);
      expect(
        tester.widget<CodeBlockView>(view).theme?.keywordColor,
        keywordColor,
      );

      final spans = flatten(codeTextOf(tester, view).textSpan!);
      final keywordSpan = spans.firstWhere((s) => s.toPlainText() == 'return');
      expect(keywordSpan.style?.color, keywordColor);
    });
  });
}
