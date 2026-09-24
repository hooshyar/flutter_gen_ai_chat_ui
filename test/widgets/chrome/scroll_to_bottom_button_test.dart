import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';

/// Slice D3: floating scroll-to-bottom control (`DESIGN.md` §8.10).
void main() {
  testWidgets(
      'default (center) position sits horizontally centered with a >=44 hit area',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(800, 600);

    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: ScrollToBottomButton(
            visible: true,
            onPressed: () => tapped = true,
            options: const ScrollToBottomOptions(),
          ),
        ),
      ),
    );
    await tester.pump();

    final iconRect = tester.getRect(
      find.byIcon(Icons.arrow_downward_rounded),
    );
    // The InkWell is the actual tap region — the package rounds the 44px
    // accessibility floor up to Material's 48x48 guideline for this
    // control (see accessibility_tap_targets_test).
    final hitSize = tester.getSize(find.byType(InkWell));
    expect(hitSize.width, greaterThanOrEqualTo(44));
    expect(hitSize.height, greaterThanOrEqualTo(44));

    expect((iconRect.center.dx - 400).abs(), lessThanOrEqualTo(1.0));

    await tester.tap(find.byIcon(Icons.arrow_downward_rounded));
    expect(tapped, isTrue);
  });

  testWidgets('end position honors rightOffset instead of centering',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(800, 600);

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: ScrollToBottomButton(
            visible: true,
            onPressed: () {},
            options: const ScrollToBottomOptions(
              position: ScrollToBottomPosition.end,
              rightOffset: 20,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final iconRect = tester.getRect(
      find.byIcon(Icons.arrow_downward_rounded),
    );
    // Pinned to the trailing edge, well clear of the horizontal center.
    expect(iconRect.center.dx, greaterThan(600));
  });
}
