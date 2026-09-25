import 'package:flutter/material.dart';
import 'package:flutter_gen_ai_chat_ui/src/theme/chat_markdown_style.dart';
import 'package:flutter_gen_ai_chat_ui/src/theme/code_block_theme.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression coverage: `chatMarkdownStyle`'s markdown table headers used to
/// render centred (flutter_markdown_plus's own `tableHeadAlign` default)
/// while body cells with no explicit column-alignment markup (` --- `, not
/// `:---`/`---:`/`:---:`) render left-aligned - so a header like "Name"
/// floated above the middle of its column instead of lining up with the
/// left-aligned cells underneath it.
const _table = '''
| Name | Score |
| --- | --- |
| Ada | 92 |
''';

Future<void> _pumpTable(WidgetTester tester, TextDirection direction) async {
  late MarkdownStyleSheet styleSheet;
  await tester.pumpWidget(
    MaterialApp(
      home: Directionality(
        textDirection: direction,
        child: Scaffold(
          body: Builder(
            builder: (context) {
              styleSheet = chatMarkdownStyle(
                context,
                const TextStyle(fontSize: 16, color: Colors.black),
                CodeBlockTheme.light(),
              );
              return Markdown(data: _table, styleSheet: styleSheet);
            },
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'LTR: table header left edge lines up with the body cell below it '
    '(±2px)',
    (tester) async {
      await _pumpTable(tester, TextDirection.ltr);

      final headerLeft = tester.getTopLeft(find.text('Name')).dx;
      final bodyLeft = tester.getTopLeft(find.text('Ada')).dx;

      expect(
        (headerLeft - bodyLeft).abs(),
        lessThanOrEqualTo(2.0),
        reason: 'header left edge ($headerLeft) should line up with the '
            'first body cell left edge ($bodyLeft) in the same column',
      );
    },
  );

  testWidgets(
    'RTL: table header start (right) edge lines up with the body cell '
    'below it (±2px)',
    (tester) async {
      await _pumpTable(tester, TextDirection.rtl);

      // In RTL, "start" is the physical right edge - a header/body pair
      // that is correctly lined up shares that right edge, not the left
      // one (their left edges differ because "Name" and "Ada" have
      // different text widths).
      final headerRight = tester.getTopRight(find.text('Name')).dx;
      final bodyRight = tester.getTopRight(find.text('Ada')).dx;

      expect(
        (headerRight - bodyRight).abs(),
        lessThanOrEqualTo(2.0),
        reason: 'header start (right) edge ($headerRight) should line up '
            'with the first body cell start edge ($bodyRight) in the same '
            'column under RTL',
      );
    },
  );
}
