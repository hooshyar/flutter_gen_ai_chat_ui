import 'package:flutter/material.dart';
import 'package:flutter_gen_ai_chat_ui_example/examples/rtl_chat.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression coverage for DESIGN.md §9 "RTL": the home page promises a
/// "mirrored layout" for this demo, so the whole scaffold - not just the
/// chat surface - must mirror. Previously only `rtl_chat.dart`'s `body` was
/// wrapped in `Directionality(TextDirection.rtl)`, leaving the demo
/// scaffold's sidebar, top bar and back arrow LTR.
void main() {
  testWidgets('sidebar sits on the right at 1280 wide', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(home: RtlChatExample(onToggleTheme: () {})),
    );
    await tester.pumpAndSettle();

    // The sidebar lists every demo group; "Core" is always present.
    final sidebarLabel = find.text('Core');
    expect(sidebarLabel, findsOneWidget);

    final labelX = tester.getCenter(sidebarLabel).dx;
    expect(
      labelX,
      greaterThan(1280 / 2),
      reason: 'sidebar must render on the right half of the screen in RTL',
    );
  });

  testWidgets('back arrow still navigates back in the mirrored scaffold',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => RtlChatExample(onToggleTheme: () {}),
              )),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(RtlChatExample), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();

    expect(find.byType(RtlChatExample), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });
}
