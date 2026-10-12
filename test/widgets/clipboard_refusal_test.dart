// The platform can refuse a clipboard write (on the web, for example, when
// the page isn't focused or clipboard permission is denied). The copy
// buttons used to let the resulting PlatformException escape as an uncaught
// error and could show "copied" feedback for a copy that never happened.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';
import 'package:flutter_gen_ai_chat_ui/src/utils/clipboard_utils.dart';
import 'package:flutter_gen_ai_chat_ui/src/widgets/message/message_action_row.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// Makes every `Clipboard.setData` call fail the way the web engine does.
  void refuseClipboardWrites(WidgetTester tester) {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          throw PlatformException(
            code: 'copy_fail',
            message: 'Clipboard.setData failed',
          );
        }
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });
  }

  testWidgets('copyTextToClipboard reports a refused write as false', (
    tester,
  ) async {
    refuseClipboardWrites(tester);
    expect(await copyTextToClipboard('x'), isFalse);
  });

  testWidgets('copyTextToClipboard reports an accepted write as true', (
    tester,
  ) async {
    String? written;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          written = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });
    expect(await copyTextToClipboard('hello'), isTrue);
    expect(written, 'hello');
  });

  testWidgets(
    'code block copy: a refused write throws nothing and shows no check',
    (tester) async {
      refuseClipboardWrites(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CodeBlockView(code: 'void main() {}', language: 'dart'),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.copy_rounded));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.copy_rounded), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsNothing);
    },
  );

  testWidgets(
    'message copy: a refused write throws nothing, skips onCopy and shows '
    'no check',
    (tester) async {
      refuseClipboardWrites(tester);
      var onCopyCalls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: MessageActionRow(
                text: 'Some AI reply text',
                timestampText: 'Just now',
                alwaysVisible: true,
                onCopy: (_) => onCopyCalls++,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(IconButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1600));

      expect(tester.takeException(), isNull);
      expect(onCopyCalls, 0);
      expect(find.byIcon(Icons.content_copy_rounded), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsNothing);
    },
  );
}
