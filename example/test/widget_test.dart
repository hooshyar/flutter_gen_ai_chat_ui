import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen_ai_chat_ui_example/main.dart';

void main() {
  testWidgets('example app launches to the home gallery', (tester) async {
    tester.view.physicalSize = const Size(1400, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ExampleApp());
    await tester.pumpAndSettle(const Duration(seconds: 10));

    expect(find.text('Chat UI for Flutter AI apps'), findsOneWidget);
    expect(find.text('Basic'), findsOneWidget);
    expect(find.text('Streaming'), findsOneWidget);
    expect(find.text('RTL'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
