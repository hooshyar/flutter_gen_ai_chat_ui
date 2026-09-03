import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen_ai_chat_ui_example/examples/attachments_chat.dart';

void main() {
  testWidgets('tapping the attach button adds a file attachment message',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AttachmentsChatExample()),
    );
    await tester.pump();

    expect(find.text('quarterly-report.pdf'), findsNothing);

    await tester.tap(find.byIcon(Icons.attach_file));
    await tester.pump();

    expect(find.textContaining('quarterly-report.pdf'), findsWidgets);

    // Let the mock AI service's simulated response delay (250-600ms) finish
    // so its Timer doesn't leak past the test.
    await tester.pump(const Duration(milliseconds: 700));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'the bot reply is context-appropriate, not the themed-demo pitch '
      '(task-023)', (tester) async {
    // Regression coverage: this screen used to share ResponseStyle
    // .conversational with themed_chat.dart, so every reply here — including
    // this one, about an attached file — was "Try switching between the
    // Ocean/Sunset/Default themes above", even though this screen has no
    // theme selector at all.
    await tester.pumpWidget(
      const MaterialApp(home: AttachmentsChatExample()),
    );
    await tester.pump();

    await tester.tap(find.byIcon(Icons.attach_file));
    await tester.pump();
    // Let the mock AI service's simulated response delay (250-600ms) finish
    // and the resulting rebuild land. A single pump right at ~700ms is
    // occasionally too tight on a loaded machine; pump twice with margin.
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 2));

    expect(find.textContaining('switching between'), findsNothing);
    expect(find.textContaining('themes above'), findsNothing);
    expect(find.textContaining('business report'), findsOneWidget);
  });
}
