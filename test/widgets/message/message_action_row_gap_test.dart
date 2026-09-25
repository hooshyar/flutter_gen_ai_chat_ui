import 'package:flutter/material.dart';
import 'package:flutter_gen_ai_chat_ui/src/widgets/message/message_action_row.dart';
import 'package:flutter_test/flutter_test.dart';

/// `DESIGN.md` §8.8: the action row is "icon, then about 4-8px, then the
/// caption" - a tight row. A prior version sized the copy button's 48px
/// hit area as its own ROW width (instead of just reserving that width for
/// hit-testing), which pushed the timestamp roughly 40px away from the
/// glyph instead of the documented single-digit gap.
void main() {
  testWidgets(
    'the gap between the copy icon glyph and the timestamp is <= 12px',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: MessageActionRow(
                text: 'Some AI reply text',
                timestampText: 'Just now',
                alwaysVisible: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final iconFinder = find.byIcon(Icons.content_copy_rounded);
      final timestampFinder = find.text('Just now');
      expect(iconFinder, findsOneWidget);
      expect(timestampFinder, findsOneWidget);

      final iconEnd = tester.getTopRight(iconFinder).dx;
      final timestampStart = tester.getTopLeft(timestampFinder).dx;
      final gap = timestampStart - iconEnd;

      expect(
        gap,
        inInclusiveRange(0, 12),
        reason: 'Gap between the copy icon glyph and the timestamp was '
            '${gap}px; DESIGN.md §8.8 wants a tight row (<=12px), not the '
            'copy button\'s 48px hit area pushing the timestamp away.',
      );
    },
  );

  testWidgets(
    'the copy control keeps its full 48x48 hit area',
    (tester) async {
      var copied = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: MessageActionRow(
                text: 'Some AI reply text',
                timestampText: 'Just now',
                alwaysVisible: true,
                onCopy: (_) => copied = true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final iconButtonFinder = find.byType(IconButton);
      expect(iconButtonFinder, findsOneWidget);
      expect(tester.getSize(iconButtonFinder), const Size(48, 48));

      await tester.tap(iconButtonFinder);
      await tester.pump();
      expect(copied, isTrue);
      // Drains the 1500ms "just copied" reset timer so teardown doesn't hit
      // "Timer still pending" after the widget tree is disposed.
      await tester.pump(const Duration(milliseconds: 1600));
    },
  );
}
