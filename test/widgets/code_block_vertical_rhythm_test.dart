import 'package:flutter/material.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression coverage for "spacing after code blocks": text after a fenced
/// block ("Result:", a blockquote, "Key rules:") used to sit tighter to the
/// block (8px, from flutter_markdown_plus's `blockSpacing` alone) than a
/// heading sits above it (16px, `h*Padding.bottom` + `blockSpacing`) —
/// `DESIGN.md` §4 wants both roughly matching the ~12-16px paragraph
/// rhythm.
///
/// Root cause: flutter_markdown_plus always wraps a custom `pre` builder's
/// output in `Container(decoration: styleSheet.codeblockDecoration)` with
/// no public hook to add space *outside* that container, so the fix has
/// `CodeBlockMarkdownBuilder` paint the code block's own chrome (via
/// `CodeBlockView(decorate: true)`) inside a bottom `Padding`, and
/// `chatMarkdownStyle` leaves the ambient `codeblockDecoration` fully
/// transparent so it doesn't double up.
void main() {
  const me = ChatUser(id: 'user', firstName: 'Me');
  const ai = ChatUser(id: 'ai', firstName: 'Assistant');

  Widget buildChat(ChatMessagesController controller) {
    return MaterialApp(
      home: Scaffold(
        body: AiChatWidget(
          currentUser: me,
          aiUser: ai,
          controller: controller,
          onSendMessage: (_) {},
        ),
      ),
    );
  }

  testWidgets(
    'the gap below a code block matches the gap above it (within 4px) and '
    'is at least 12px',
    (tester) async {
      final controller = ChatMessagesController();
      controller.addMessage(
        ChatMessage(
          text: '## Heading Before\n'
              '```dart\n'
              'final x = 1;\n'
              '```\n'
              '\n'
              'Result: this is the paragraph after the code block.\n',
          user: ai,
          createdAt: DateTime.now(),
          isMarkdown: true,
        ),
      );

      await tester.pumpWidget(buildChat(controller));
      await tester.pumpAndSettle();

      final headingBottom =
          tester.getBottomLeft(find.textContaining('Heading Before')).dy;
      final codeBlockFinder = find.ancestor(
        of: find.textContaining('final x = 1;'),
        matching: find.byWidgetPredicate(
          (w) => w is Container && w.decoration != null,
        ),
      );
      final codeTop = tester.getTopLeft(codeBlockFinder.first).dy;
      final codeBottom = tester.getBottomLeft(codeBlockFinder.first).dy;
      final paraTop = tester.getTopLeft(find.textContaining('Result:')).dy;

      final gapAbove = codeTop - headingBottom;
      final gapBelow = paraTop - codeBottom;

      expect(
        gapBelow,
        greaterThanOrEqualTo(12),
        reason: 'Gap below the code block ($gapBelow px) is tighter than '
            'DESIGN.md §4\'s ~12-16px paragraph rhythm.',
      );
      expect(
        (gapBelow - gapAbove).abs(),
        lessThanOrEqualTo(4),
        reason: 'Gap below the code block ($gapBelow px) should read as the '
            'same rhythm as the gap above it ($gapAbove px), not '
            'noticeably tighter.',
      );
    },
  );

  testWidgets(
    'the gap below a code block does not stack on top of a following '
    'heading\'s own top padding (no double-spacing before a heading)',
    (tester) async {
      final controller = ChatMessagesController();
      controller.addMessage(
        ChatMessage(
          text: '```dart\n'
              'final x = 1;\n'
              '```\n'
              '\n'
              '## Next Section\n'
              'More text.\n',
          user: ai,
          createdAt: DateTime.now(),
          isMarkdown: true,
        ),
      );

      await tester.pumpWidget(buildChat(controller));
      await tester.pumpAndSettle();

      final codeBlockFinder = find.ancestor(
        of: find.textContaining('final x = 1;'),
        matching: find.byWidgetPredicate(
          (w) => w is Container && w.decoration != null,
        ),
      );
      final codeBottom = tester.getBottomLeft(codeBlockFinder.first).dy;
      final headingTop =
          tester.getTopLeft(find.textContaining('Next Section')).dy;
      final gap = headingTop - codeBottom;

      // The heading's own top padding (20px per DESIGN.md §4) already
      // supplies ample space; the code block's own bottom margin (added
      // for the paragraph case above) must not additionally stack a full
      // second helping of spacing on top of that.
      expect(
        gap,
        lessThan(40),
        reason: 'Gap between the code block and the following heading '
            '($gap px) suggests the fix doubled up on top of the '
            'heading\'s own top padding.',
      );
    },
  );
}
