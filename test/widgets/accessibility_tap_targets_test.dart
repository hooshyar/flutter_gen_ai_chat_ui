import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';

/// Tap-target sizing audit (issue #41 Phase 1).
///
/// Found two real icon-only tap targets under the Material/WCAG 48x48
/// minimum:
///
/// - The default send button's `IconButton` has its own 48x48 minimum
///   constraint, but a fixed-height `Container` around it (approximating
///   the text field's height) was capping it at ~38px tall. Fixed by
///   flooring that approximated height at 48 in `chat_input.dart` — the
///   icon itself is unchanged, only its container gets enough room.
/// - The scroll-to-bottom button (icon-only by default, `showText: false`)
///   sized its tap area directly from `Padding` + icon size, landing at
///   ~36-44px. Fixed by bumping that padding to 48 total in
///   `custom_chat_widget.dart`.
///
/// The default `TextField`'s own semantics node also fails
/// `androidTapTargetGuideline` (it reports its intrinsic single-line text
/// content box — ~24px tall — rather than the full decorated input area).
/// That's a known Flutter quirk, not specific to this package, and fixing
/// it would mean deliberately growing the default input row's height as a
/// visual design decision — out of scope for a tap-target *sizing* fix that
/// shouldn't change how anything looks. Not asserted here for that reason;
/// each button is checked individually instead of running the guideline
/// against the whole widget tree.
void main() {
  const testUser = ChatUser(id: 'user', name: 'Test User');
  const aiUser = ChatUser(id: 'ai', name: 'AI Assistant');

  const minTapTarget = Size(48, 48);

  testWidgets('default send button meets the 48x48 minimum tap target',
      (tester) async {
    final controller = ChatMessagesController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: AiChatWidget(
            currentUser: testUser,
            aiUser: aiUser,
            controller: controller,
            onSendMessage: (_) async {},
          ),
        ),
      ),
    );
    await tester.pump();

    final sendButton = find.widgetWithIcon(IconButton, Icons.send);
    expect(sendButton, findsOneWidget);
    final size = tester.getSize(sendButton);
    expect(size.width, greaterThanOrEqualTo(minTapTarget.width));
    expect(size.height, greaterThanOrEqualTo(minTapTarget.height));
  });

  testWidgets(
      'file upload button meets the 48x48 minimum tap target when enabled',
      (tester) async {
    final controller = ChatMessagesController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: AiChatWidget(
            currentUser: testUser,
            aiUser: aiUser,
            controller: controller,
            onSendMessage: (_) async {},
            fileUploadOptions: FileUploadOptions(
              enabled: true,
              onFilesSelected: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final uploadButton = find.widgetWithIcon(IconButton, Icons.attach_file);
    expect(uploadButton, findsOneWidget);
    final size = tester.getSize(uploadButton);
    expect(size.width, greaterThanOrEqualTo(minTapTarget.width));
    expect(size.height, greaterThanOrEqualTo(minTapTarget.height));
  });

  testWidgets(
      'icon-only scroll-to-bottom button meets the 48x48 minimum tap target',
      (tester) async {
    final controller = ChatMessagesController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: AiChatWidget(
            currentUser: testUser,
            aiUser: aiUser,
            controller: controller,
            onSendMessage: (_) async {},
            // showText defaults to false, so this is the icon-only case.
            scrollToBottomOptions:
                const ScrollToBottomOptions(alwaysVisible: true),
          ),
        ),
      ),
    );
    await tester.pump();

    final scrollButton = find.ancestor(
      of: find.byIcon(Icons.keyboard_arrow_down),
      matching: find.byType(InkWell),
    );
    expect(scrollButton, findsOneWidget);
    final size = tester.getSize(scrollButton);
    expect(size.width, greaterThanOrEqualTo(minTapTarget.width));
    expect(size.height, greaterThanOrEqualTo(minTapTarget.height));
  });
}
