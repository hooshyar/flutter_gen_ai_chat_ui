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

  testWidgets(
      'the bot reply is context-appropriate, not the themed-demo pitch '
      '(task-023)', (tester) async {
    // Regression coverage: this screen used to share ResponseStyle
    // .conversational with themed_chat.dart, so recognized voice phrases —
    // none of which mention themes — got the "Try switching between the
    // Ocean/Sunset/Default themes above" reply anyway.
    await tester.pumpWidget(const MaterialApp(home: VoiceChatExample()));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.mic_none));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 950));

    // The first simulated phrase is "What is the weather like today?".
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();
    // Let the mock AI service's simulated response delay (250-600ms) finish
    // and the resulting rebuild land. A single pump right at ~700ms is
    // occasionally too tight on a loaded machine; pump twice with margin.
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 2));

    expect(find.textContaining('switching between'), findsNothing);
    expect(find.textContaining('themes above'), findsNothing);
    expect(find.textContaining('weather'), findsWidgets);
  });
}
