import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen_ai_chat_ui_example/examples/voice_chat.dart';

void main() {
  testWidgets('tapping the mic simulates listening then fills recognized text',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: VoiceChatExample()));
    await tester.pump();

    expect(find.byIcon(Icons.mic_none), findsOneWidget);

    await tester.tap(find.byIcon(Icons.mic_none));
    await tester.pump();

    // Now "listening" — the toggle mode swaps to the listening icon.
    expect(find.byIcon(Icons.hearing), findsOneWidget);

    // Let the simulated recognition timer fire.
    await tester.pump(const Duration(milliseconds: 950));

    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.controller?.text, isNotEmpty);
    expect(tester.takeException(), isNull);
  });
}
