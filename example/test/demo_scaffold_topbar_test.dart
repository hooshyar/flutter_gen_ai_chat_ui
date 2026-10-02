import 'package:flutter/material.dart';
import 'package:flutter_gen_ai_chat_ui_example/shell/demo_scaffold.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression coverage for DESIGN.md §9 "Demo scaffold": the top bar must be
/// opaque (the canvas colour) at every width, and shows a 1px bottom border
/// only once the body content has scrolled under it.
void main() {
  Future<void> pumpScaffoldAt(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      home: DemoScaffold(
        title: 'Probe',
        route: '/probe',
        isDark: false,
        onToggleTheme: () {},
        body: ListView.builder(
          itemCount: 50,
          itemBuilder: (context, i) =>
              SizedBox(height: 60, child: Text('item $i')),
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  BoxDecoration topBarDecoration(WidgetTester tester) {
    final container = tester.widget<Container>(find.byType(Container).first);
    return container.decoration as BoxDecoration;
  }

  testWidgets('top bar is opaque at phone width, before any scroll',
      (tester) async {
    await pumpScaffoldAt(tester, const Size(390, 844));
    final decoration = topBarDecoration(tester);
    expect(decoration.color, isNotNull);
    expect(decoration.color!.a, 1.0,
        reason: 'top bar background must be opaque');
  });

  testWidgets('bottom border is absent before scroll, appears once scrolled',
      (tester) async {
    await pumpScaffoldAt(tester, const Size(390, 844));

    final before = topBarDecoration(tester).border as Border?;
    expect(before!.bottom.color.a, 0.0,
        reason: 'no border until content is scrolled under the bar');

    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();

    final after = topBarDecoration(tester).border as Border?;
    expect(after!.bottom.color.a, 1.0,
        reason: 'border must appear once the body is scrolled under the bar');
    expect(after.bottom.width, 1.0);
  });

  testWidgets('top bar stays opaque at wide (sidebar) widths too',
      (tester) async {
    await pumpScaffoldAt(tester, const Size(1280, 900));
    final decoration = topBarDecoration(tester);
    expect(decoration.color!.a, 1.0);
  });
}
