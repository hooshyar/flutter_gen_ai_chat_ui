import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';
import 'package:flutter_test/flutter_test.dart';

// Hardware Enter behavior on AiChatWidget. Soft-keyboard submit is a separate
// path (TextField.onSubmitted) and is not exercised here.
void main() {
  group('ChatInput hardware Enter', () {
    late ChatMessagesController controller;
    late ChatUser user;
    late ChatUser ai;

    setUp(() {
      controller = ChatMessagesController();
      user = ChatUser(id: 'u', firstName: 'U');
      ai = ChatUser(id: 'a', firstName: 'A');
    });

    Future<void> pump(
      WidgetTester tester, {
      required void Function(ChatMessage) onSend,
      InputOptions? inputOptions,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AiChatWidget(
              currentUser: user,
              aiUser: ai,
              controller: controller,
              onSendMessage: onSend,
              inputOptions: inputOptions ?? const InputOptions(),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('bare Enter sends when sendOnEnter is true and text non-empty',
        (tester) async {
      var sends = 0;
      ChatMessage? sent;
      await pump(tester, onSend: (m) {
        sends++;
        sent = m;
      });

      await tester.tap(find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'hello world');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(sends, 1);
      expect(sent?.text, 'hello world');
    });

    testWidgets('Enter on empty input is a no-op', (tester) async {
      var sends = 0;
      await pump(tester, onSend: (_) => sends++);

      await tester.tap(find.byType(TextField));
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(sends, 0);
    });

    testWidgets('Enter on whitespace-only input is a no-op', (tester) async {
      var sends = 0;
      await pump(tester, onSend: (_) => sends++);

      await tester.tap(find.byType(TextField));
      await tester.enterText(find.byType(TextField), '   ');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(sends, 0);
    });

    testWidgets('sendOnEnter: false leaves Enter to the TextField',
        (tester) async {
      var sends = 0;
      await pump(
        tester,
        onSend: (_) => sends++,
        inputOptions: const InputOptions(sendOnEnter: false),
      );

      await tester.tap(find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'hello');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(sends, 0);
    });

    testWidgets('Numpad Enter also sends', (tester) async {
      var sends = 0;
      await pump(tester, onSend: (_) => sends++);

      await tester.tap(find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'hello');
      await tester.sendKeyEvent(LogicalKeyboardKey.numpadEnter);
      await tester.pump();

      expect(sends, 1);
    });

    testWidgets('Holding Enter does not fire onSend repeatedly',
        (tester) async {
      var sends = 0;
      await pump(tester, onSend: (_) => sends++);

      await tester.tap(find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'hello');

      // KeyDown (handled, sends once) followed by KeyRepeat (must not fire).
      await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(sends, 1);
    });

    testWidgets('Shift+Enter does not send', (tester) async {
      var sends = 0;
      await pump(tester, onSend: (_) => sends++);

      await tester.tap(find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'hello');

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pump();

      expect(sends, 0);
    });

    testWidgets('options.onSubmitted is forwarded when Enter sends',
        (tester) async {
      String? submitted;
      await pump(
        tester,
        onSend: (_) {},
        inputOptions: InputOptions(onSubmitted: (t) => submitted = t),
      );

      await tester.tap(find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'ping');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(submitted, 'ping');
    });

    testWidgets('IME composing range suppresses send', (tester) async {
      var sends = 0;
      final externalController = TextEditingController();
      await pump(
        tester,
        onSend: (_) => sends++,
        inputOptions: InputOptions(textController: externalController),
      );

      await tester.tap(find.byType(TextField));
      // Simulate an IME with an active composing range.
      externalController.value = const TextEditingValue(
        text: 'にほ',
        selection: TextSelection.collapsed(offset: 2),
        composing: TextRange(start: 0, end: 2),
      );
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(sends, 0);
    });

    testWidgets('Custom focusNode passed via InputOptions still sends',
        (tester) async {
      var sends = 0;
      final fn = FocusNode();
      await pump(
        tester,
        onSend: (_) => sends++,
        inputOptions: InputOptions(focusNode: fn),
      );

      await tester.tap(find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'hello');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(sends, 1);
      fn.dispose();
    });
  });
}
