// Smoke test: every demo route renders without exceptions at a phone and a
// desktop viewport, in light and dark. DESIGN.md 9 "Example app shell".
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen_ai_chat_ui_example/main.dart';
import 'package:flutter_gen_ai_chat_ui_example/shell/demo_catalog.dart';

void setSurfaceSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  const sizes = {
    'phone (390x844)': Size(390, 844),
    'desktop (1280x800)': Size(1280, 800),
  };
  const brightnesses = {
    'light': Brightness.light,
    'dark': Brightness.dark,
  };

  for (final sizeEntry in sizes.entries) {
    for (final brightnessEntry in brightnesses.entries) {
      for (final entry in demoCatalog) {
        testWidgets(
          '${entry.route} renders at ${sizeEntry.key} in '
          '${brightnessEntry.key} with no exceptions',
          (tester) async {
            setSurfaceSize(tester, sizeEntry.value);
            tester.platformDispatcher.platformBrightnessTestValue =
                brightnessEntry.value;
            addTearDown(
              tester.platformDispatcher.clearPlatformBrightnessTestValue,
            );

            await tester.pumpWidget(const ExampleApp());
            await tester.pump();
            // The demo index can run off the fold at these sizes; scroll it
            // into view before tapping.
            await tester.ensureVisible(find.text(entry.title));
            await tester.pump();
            await tester.tap(find.text(entry.title));
            await tester.pumpAndSettle(const Duration(seconds: 10));

            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }
}
