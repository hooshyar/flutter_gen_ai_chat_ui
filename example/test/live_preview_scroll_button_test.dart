import 'package:flutter/material.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';
import 'package:flutter_gen_ai_chat_ui_example/shell/live_preview.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression coverage for DESIGN.md §9: the home page's live preview panel
/// must never show the floating scroll-to-bottom button - at phone widths it
/// covers the preview's own code block.
void main() {
  testWidgets('no scroll-to-bottom button appears in the preview at 390x844',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: LivePreview(height: 440)),
    ));

    // Let the scripted question/answer exchange play out (question, then a
    // word-by-word streamed markdown reply with a code block) - this is
    // exactly the scenario that scrolls the list and would surface the
    // button if it weren't suppressed.
    for (var i = 0; i < 80; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.byType(ScrollToBottomButton), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
