import 'package:flutter/material.dart';
import 'package:flutter_gen_ai_chat_ui/src/theme/chat_markdown_style.dart';
import 'package:flutter_gen_ai_chat_ui/src/theme/code_block_theme.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression coverage: JetBrains Mono ligatures turn `=>` into "⇒" and
/// `<=` into "≤" in rendered code — wrong for code a reader might copy.
/// Both the fenced-code-block base style and the inline-code style must
/// disable contextual alternates (`calt`) and standard ligatures (`liga`).
void main() {
  const expectedFeatures = [
    FontFeature.disable('calt'),
    FontFeature.disable('liga'),
  ];

  test('CodeBlockTheme.light().baseStyle disables ligatures', () {
    final theme = CodeBlockTheme.light();
    expect(theme.baseStyle.fontFeatures, expectedFeatures);
  });

  test('CodeBlockTheme.dark().baseStyle disables ligatures', () {
    final theme = CodeBlockTheme.dark();
    expect(theme.baseStyle.fontFeatures, expectedFeatures);
  });

  testWidgets(
    'chatMarkdownStyle\'s inline code style disables ligatures',
    (tester) async {
      late TextStyle inlineCodeStyle;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              inlineCodeStyle = chatMarkdownStyle(
                context,
                const TextStyle(fontSize: 16),
                CodeBlockTheme.light(),
              ).code!;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(inlineCodeStyle.fontFeatures, expectedFeatures);
    },
  );
}
