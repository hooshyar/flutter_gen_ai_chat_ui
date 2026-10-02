import 'package:flutter/material.dart';
import 'package:flutter_gen_ai_chat_ui_example/examples/themed_chat.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression coverage for "segmented control changes width": switching
/// Default / ChatGPT / Claude / Gemini in `themed_chat.dart` used to shift
/// the whole `SegmentedButton`'s width, because Material's default
/// `showSelectedIcon: true` adds a checkmark's worth of space only to the
/// currently-selected segment — and the four labels ("Default", "ChatGPT",
/// "Claude", "Gemini") aren't the same length, so which segment carries
/// that extra space changes the row's total intrinsic width as selection
/// changes.
void main() {
  testWidgets(
    'the segmented control keeps a stable width across every preset',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: ThemedChatExample(onToggleTheme: () {})),
      );
      await tester.pump();

      // `SegmentedButton<_Preset>` uses a library-private enum, so it can't
      // be named directly from this test file — match by runtime type name
      // instead.
      final segmentedButtonFinder = find.byWidgetPredicate(
        (w) => w.runtimeType.toString().startsWith('SegmentedButton<'),
      );
      expect(segmentedButtonFinder, findsOneWidget);

      double widthOf() => tester.getSize(segmentedButtonFinder).width;

      final widths = <String, double>{'Default': widthOf()};

      for (final label in ['ChatGPT', 'Claude', 'Gemini', 'Default']) {
        await tester.tap(find.text(label));
        await tester.pump();
        widths[label] = widthOf();
      }

      final distinctWidths = widths.values.map((w) => w.round()).toSet();
      expect(
        distinctWidths.length,
        1,
        reason: 'Segmented control width changed across presets: $widths',
      );
    },
  );
}
