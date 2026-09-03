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
}
