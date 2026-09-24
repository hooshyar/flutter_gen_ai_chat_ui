import 'package:flutter/material.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const highlighter = CodeHighlighter();
  final theme = CodeBlockTheme.dark();

  setUp(CodeHighlighter.debugClearCache);

  /// Recursively collects every [TextSpan] in the tree.
  List<TextSpan> flatten(TextSpan root) {
    final out = <TextSpan>[root];
    for (final child in root.children ?? const <InlineSpan>[]) {
      if (child is TextSpan) out.addAll(flatten(child));
    }
    return out;
  }

  /// Finds the first span whose text contains [needle].
  TextSpan spanContaining(TextSpan root, String needle) =>
      flatten(root).firstWhere(
        (s) => (s.text ?? '').contains(needle),
        orElse: () => throw StateError('no span containing "$needle"'),
      );

  group('CodeHighlighter', () {
    test('dart keywords, strings and comments get distinct colours', () {
      final span = highlighter.highlight(
        '// greeting\nfinal x = "hi";\n',
        language: 'dart',
        theme: theme,
      );
      final comment = spanContaining(span, '// greeting');
      final keyword = spanContaining(span, 'final');
      final string = spanContaining(span, '"hi"');

      expect(comment.style?.color, theme.commentColor);
      expect(keyword.style?.color, theme.keywordColor);
      expect(string.style?.color, theme.stringColor);

      final colors = {
        comment.style?.color,
        keyword.style?.color,
        string.style?.color,
      };
      expect(colors.length, 3);
    });

    test('enabled:false yields a single plain span in baseStyle', () {
      const code = 'final x = "hi";';
      final span = highlighter.highlight(
        code,
        language: 'dart',
        theme: theme,
        enabled: false,
      );
      expect(span.text, code);
      expect(span.children, isNull);
      expect(span.style, theme.baseStyle);
    });

    test('no span in the tree sets backgroundColor', () {
      final span = highlighter.highlight(
        'final a = 1; // c\nString s = "x";\nvoid f() { g(2); }\n'
        '@override\nclass Foo extends Bar {}\n',
        language: 'dart',
        theme: theme,
      );
      for (final s in flatten(span)) {
        expect(s.style?.backgroundColor, isNull);
      }
    });

    test('memoized repeat call does not re-tokenize', () {
      const code = 'final x = 1;';
      highlighter.highlight(code, language: 'dart', theme: theme);
      expect(CodeHighlighter.debugHighlightCount, 1);
      highlighter.highlight(code, language: 'dart', theme: theme);
      expect(CodeHighlighter.debugHighlightCount, 1);
      highlighter.highlight('var y = 2;', language: 'dart', theme: theme);
      expect(CodeHighlighter.debugHighlightCount, 2);
    });

    test('unknown language falls back without throwing', () {
      final span = highlighter.highlight(
        'x = 1; // ok',
        language: 'brainfuck-plus',
        theme: theme,
      );
      expect(span.toPlainText(), contains('x = 1;'));
      // Generic fallback still tokenizes comments.
      expect(spanContaining(span, '// ok').style?.color, theme.commentColor);
    });

    test('null language falls back without throwing', () {
      final span = highlighter.highlight('x = 1;', theme: theme);
      expect(span.toPlainText(), 'x = 1;');
    });

    test('light and dark themes produce different colours', () {
      const code = 'final x = "s";';
      final darkSpan = highlighter.highlight(
        code,
        language: 'dart',
        theme: CodeBlockTheme.dark(),
      );
      final lightSpan = highlighter.highlight(
        code,
        language: 'dart',
        theme: CodeBlockTheme.light(),
      );
      final darkColors = flatten(darkSpan)
          .map((s) => s.style?.color)
          .whereType<Color>()
          .toSet();
      final lightColors = flatten(lightSpan)
          .map((s) => s.style?.color)
          .whereType<Color>()
          .toSet();
      expect(darkColors, isNot(equals(lightColors)));
      expect(CodeBlockTheme.dark(), isNot(equals(CodeBlockTheme.light())));
    });
  });

  group('CodeBlockTheme', () {
    test('of(Brightness.dark) == dark(), of(Brightness.light) == light()', () {
      expect(CodeBlockTheme.of(Brightness.dark), CodeBlockTheme.dark());
      expect(CodeBlockTheme.of(Brightness.light), CodeBlockTheme.light());
    });

    test('equal themes have equal hashCodes and const identity', () {
      expect(CodeBlockTheme.dark(), CodeBlockTheme.dark());
      expect(CodeBlockTheme.dark().hashCode, CodeBlockTheme.dark().hashCode);
      expect(identical(CodeBlockTheme.dark(), CodeBlockTheme.dark()), isTrue);
    });

    test('baseStyle uses bundled JetBrainsMono with fallbacks', () {
      final style = CodeBlockTheme.dark().baseStyle;
      // `package:` folds into fontFamily and each fallback as a
      // `packages/<pkg>/` prefix.
      expect(
        style.fontFamily,
        'packages/flutter_gen_ai_chat_ui/${CodeBlockTheme.monoFontFamily}',
      );
      expect(
        style.fontFamilyFallback,
        CodeBlockTheme.monoFontFallback
            .map((f) => 'packages/flutter_gen_ai_chat_ui/$f')
            .toList(),
      );
      expect(style.fontSize, 13.5);
      expect(style.height, 1.48);
      expect(style.backgroundColor, isNull);
    });

    test('tooltips default to spec values', () {
      expect(CodeBlockTheme.dark().copyTooltip, 'Copy code');
      expect(CodeBlockTheme.dark().copiedTooltip, 'Copied');
    });
  });
}
