import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen_ai_chat_ui_example/examples/rich_widgets_chat.dart';

void main() {
  testWidgets(
      'tapping Add to Cart on the product card shows a confirmation '
      '(task-024)', (tester) async {
    // Regression coverage: the button previously had an empty onPressed
    // (`() {}`), so tapping it did nothing at all — no toast, no state
    // change, no message — and read as a dead button.
    await tester.pumpWidget(
      const MaterialApp(home: RichWidgetsChatExample()),
    );
    await tester.pump();

    await tester.tap(find.text('Show me a product'));
    await tester.pump();
    // The demo has a fixed 800ms artificial "thinking" delay before the
    // rich product-card message is added.
    await tester.pump(const Duration(milliseconds: 900));

    expect(find.text('Add to Cart'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);

    await tester.tap(find.text('Add to Cart'));
    await tester.pump();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.textContaining('added to cart'), findsOneWidget);
  });
}
