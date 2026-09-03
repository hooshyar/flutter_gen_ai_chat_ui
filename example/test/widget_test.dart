import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen_ai_chat_ui_example/main.dart';

void main() {
  testWidgets('example app launches to the home gallery', (tester) async {
    await tester.pumpWidget(const ExampleApp());
    await tester.pump();

    expect(find.text('Flutter Gen AI\nChat UI'), findsOneWidget);
    expect(find.text('Basic Chat'), findsOneWidget);

    // The gallery list scrolls; the newest cards are off-screen until then.
    await tester.dragUntilVisible(
      find.text('Voice Input'),
      find.byType(Scrollable),
      const Offset(0, -100),
    );
    expect(find.text('Attachments'), findsOneWidget);
    expect(find.text('Voice Input'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
