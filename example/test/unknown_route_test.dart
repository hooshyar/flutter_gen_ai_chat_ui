// Regression test: on web, browser URL hash changes push raw route names
// that may not match the routes table exactly (case, trailing slash, query
// string). Without onGenerateRoute/onUnknownRoute, MaterialApp throws
// "Null check operator used on a null value" from _onUnknownRoute.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen_ai_chat_ui_example/main.dart';
import 'package:flutter_gen_ai_chat_ui_example/home_screen.dart';
import 'package:flutter_gen_ai_chat_ui_example/examples/streaming_chat.dart';

void setSurfaceSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> pushRoute(WidgetTester tester, String name) async {
  await tester.binding.handlePushRoute(name);
  await tester.pumpAndSettle(const Duration(seconds: 10));
  expect(tester.takeException(), isNull, reason: 'pushing "$name" threw');
}

void main() {
  testWidgets('platform-pushed routes normalize or fall back to home',
      (tester) async {
    setSurfaceSize(tester, const Size(1280, 800));

    await tester.pumpWidget(const ExampleApp());
    await tester.pumpAndSettle(const Duration(seconds: 10));
    expect(tester.takeException(), isNull);

    await pushRoute(tester, '/Streaming');
    expect(find.byType(StreamingChatExample), findsOneWidget);

    await pushRoute(tester, '/streaming/');
    expect(find.byType(StreamingChatExample), findsOneWidget);

    await pushRoute(tester, '/streaming?x=1');
    expect(find.byType(StreamingChatExample), findsOneWidget);

    await pushRoute(tester, '/nonexistent');
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(StreamingChatExample), findsNothing);
  });
}
