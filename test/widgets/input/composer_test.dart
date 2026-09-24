import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';
import 'package:flutter_gen_ai_chat_ui/src/theme/chat_tokens.dart';
import 'package:flutter_gen_ai_chat_ui/src/widgets/input/send_stop_button.dart';
import 'package:flutter_test/flutter_test.dart';

/// Slice D4 — composer and send/stop control default visuals
/// (`DESIGN.md` §7, §8.4, §8.5). See scratchpad `codeblock/d4.txt`.
void main() {
  final aiUser = ChatUser(id: 'ai', name: 'AI');
  final humanUser = ChatUser(id: 'user', name: 'User');

  Widget harness({
    InputOptions? inputOptions,
    bool isLoading = false,
    VoidCallback? onCancel,
    ThemeData? theme,
  }) {
    final controller = ChatMessagesController();
    addTearDown(controller.dispose);

    return MaterialApp(
      theme: theme,
      home: Scaffold(
        body: AiChatWidget(
          currentUser: humanUser,
          aiUser: aiUser,
          controller: controller,
          onSendMessage: (_) {},
          loadingConfig: LoadingConfig(isLoading: isLoading),
          onCancelGenerating: onCancel,
          inputOptions: inputOptions ?? const InputOptions(),
        ),
      ),
    );
  }

  testWidgets('default send control shows Icons.arrow_upward_rounded',
      (tester) async {
    await tester.pumpWidget(harness());
    await tester.pump();

    expect(find.byIcon(Icons.arrow_upward_rounded), findsOneWidget);
  });

  testWidgets('tapping send with empty text does not call onSend',
      (tester) async {
    var sends = 0;
    final controller = ChatMessagesController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AiChatWidget(
          currentUser: humanUser,
          aiUser: aiUser,
          controller: controller,
          onSendMessage: (_) => sends++,
        ),
      ),
    ));
    await tester.pump();

    await tester.tap(find.byType(SendStopButton));
    await tester.pump();

    expect(sends, 0);
  });

  group('generating state', () {
    testWidgets('shows a control with the "Stop generating" semantics label',
        (tester) async {
      await tester.pumpWidget(harness(isLoading: true, onCancel: () {}));
      await tester.pump();

      expect(find.bySemanticsLabel('Stop generating'), findsOneWidget);
    });

    testWidgets('tapping it calls the cancel callback', (tester) async {
      var cancelled = false;
      await tester.pumpWidget(
        harness(isLoading: true, onCancel: () => cancelled = true),
      );
      await tester.pump();

      await tester.tap(find.bySemanticsLabel('Stop generating'));
      await tester.pump();

      expect(cancelled, isTrue);
    });

    testWidgets('Esc calls the cancel callback', (tester) async {
      var cancelled = false;
      await tester.pumpWidget(
        harness(isLoading: true, onCancel: () => cancelled = true),
      );
      await tester.pump();

      await tester.tap(find.byType(TextField));
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();

      expect(cancelled, isTrue);
    });
  });

  testWidgets('explicit sendButtonIcon renders that icon', (tester) async {
    await tester.pumpWidget(
      harness(inputOptions: const InputOptions(sendButtonIcon: Icons.send)),
    );
    await tester.pump();

    expect(find.byIcon(Icons.send), findsOneWidget);
    expect(find.byIcon(Icons.arrow_upward_rounded), findsNothing);
  });

  testWidgets('explicit containerDecoration is rendered untouched',
      (tester) async {
    const decoration = BoxDecoration(color: Color(0xFF123456));

    await tester.pumpWidget(
      harness(
        inputOptions: const InputOptions(containerDecoration: decoration),
      ),
    );
    await tester.pump();

    final container = tester.widget<Container>(find
        .ancestor(
          of: find.byType(TextField),
          matching: find.byType(Container),
        )
        .first);
    expect(container.decoration, decoration);
  });

  testWidgets('send control hit size is at least 44x44', (tester) async {
    await tester.pumpWidget(harness());
    await tester.pump();

    final size = tester.getSize(find.byType(SendStopButton));
    expect(size.width, greaterThanOrEqualTo(44));
    expect(size.height, greaterThanOrEqualTo(44));
  });

  testWidgets('focusing the composer changes its border to borderStrong',
      (tester) async {
    await tester.pumpWidget(harness());
    await tester.pump();

    AnimatedContainer composerBefore() => tester.widget<AnimatedContainer>(
          find
              .ancestor(
                of: find.byType(TextField),
                matching: find.byType(AnimatedContainer),
              )
              .first,
        );

    final before = composerBefore().decoration as BoxDecoration;
    expect((before.border as Border).top.color, ChatTokens.light.border);

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    final after = composerBefore().decoration as BoxDecoration;
    expect(
      (after.border as Border).top.color,
      ChatTokens.light.borderStrong,
    );
  });

  testWidgets("CustomThemeExtension.chatgpt() input fill shows on the composer",
      (tester) async {
    final ext = CustomThemeExtension.chatgpt();

    await tester.pumpWidget(harness(theme: ThemeData(extensions: [ext])));
    await tester.pump();

    final composer = tester.widget<AnimatedContainer>(find
        .ancestor(
          of: find.byType(TextField),
          matching: find.byType(AnimatedContainer),
        )
        .first);
    final decoration = composer.decoration as BoxDecoration;
    expect(decoration.color, ext.inputBackgroundColor);
  });
}
