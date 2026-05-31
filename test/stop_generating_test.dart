import 'package:flutter/material.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final aiUser = ChatUser(id: 'ai', name: 'AI');
  final humanUser = ChatUser(id: 'user', name: 'User');

  Widget harness(ChatMessagesController controller,
      {required bool isLoading,
      VoidCallback? onCancel,
      InputOptions? inputOptions}) {
    return MaterialApp(
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

  group('Stop generating button (#39)', () {
    testWidgets('shows stop button when generating + onCancelGenerating set',
        (tester) async {
      final controller = ChatMessagesController();

      await tester.pumpWidget(
        harness(controller, isLoading: true, onCancel: () {}),
      );
      await tester.pump();

      expect(find.byIcon(Icons.stop_rounded), findsOneWidget);
      // Default send icon should be replaced.
      expect(find.byIcon(Icons.send), findsNothing);

      controller.dispose();
    });

    testWidgets('tapping stop button invokes onCancelGenerating',
        (tester) async {
      final controller = ChatMessagesController();
      var cancelled = false;

      await tester.pumpWidget(
        harness(controller, isLoading: true, onCancel: () => cancelled = true),
      );
      await tester.pump();

      await tester.tap(find.byIcon(Icons.stop_rounded));
      await tester.pump();

      expect(cancelled, isTrue);

      controller.dispose();
    });

    testWidgets('no stop button when onCancelGenerating is null',
        (tester) async {
      final controller = ChatMessagesController();

      await tester.pumpWidget(
        harness(controller, isLoading: true, onCancel: null),
      );
      await tester.pump();

      expect(find.byIcon(Icons.stop_rounded), findsNothing);
      expect(find.byIcon(Icons.send), findsOneWidget);

      controller.dispose();
    });

    testWidgets('no stop button when not loading', (tester) async {
      final controller = ChatMessagesController();

      await tester.pumpWidget(
        harness(controller, isLoading: false, onCancel: () {}),
      );
      await tester.pump();

      expect(find.byIcon(Icons.stop_rounded), findsNothing);
      expect(find.byIcon(Icons.send), findsOneWidget);

      controller.dispose();
    });

    testWidgets('stop button toggles back to send when loading ends',
        (tester) async {
      final controller = ChatMessagesController();

      await tester.pumpWidget(
        harness(controller, isLoading: true, onCancel: () {}),
      );
      await tester.pump();
      expect(find.byIcon(Icons.stop_rounded), findsOneWidget);

      // Rebuild with loading finished.
      await tester.pumpWidget(
        harness(controller, isLoading: false, onCancel: () {}),
      );
      await tester.pump();

      expect(find.byIcon(Icons.stop_rounded), findsNothing);
      expect(find.byIcon(Icons.send), findsOneWidget);

      controller.dispose();
    });

    testWidgets('custom cancelButtonBuilder renders', (tester) async {
      final controller = ChatMessagesController();

      await tester.pumpWidget(
        harness(
          controller,
          isLoading: true,
          onCancel: () {},
          inputOptions: InputOptions(
            cancelButtonBuilder: (onCancel) => IconButton(
              key: const Key('custom-stop'),
              icon: const Icon(Icons.cancel),
              onPressed: onCancel,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('custom-stop')), findsOneWidget);
      expect(find.byIcon(Icons.stop_rounded), findsNothing);

      controller.dispose();
    });
  });

  group('effectiveStopButtonBuilder', () {
    test('uses cancelButtonBuilder when provided', () {
      final options = InputOptions(
        cancelButtonBuilder: (onCancel) => const Text('stop'),
      );
      final widget = options.effectiveStopButtonBuilder(() {});
      expect(widget, isA<Text>());
    });

    test('falls back to default IconButton', () {
      const options = InputOptions();
      final widget = options.effectiveStopButtonBuilder(() {});
      expect(widget, isA<IconButton>());
    });

    test('default stop icon is configurable', () {
      const options = InputOptions(stopButtonIcon: Icons.cancel);
      expect(options.stopButtonIcon, Icons.cancel);
    });
  });

  group('Per-bubble timestamp style (#29)', () {
    testWidgets('userTimeTextStyle and aiTimeTextStyle apply independently',
        (tester) async {
      final controller = ChatMessagesController();
      const userColor = Color(0xFFAA0000);
      const aiColor = Color(0xFF00AA00);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AiChatWidget(
              currentUser: humanUser,
              aiUser: aiUser,
              controller: controller,
              onSendMessage: (_) {},
              messageOptions: MessageOptions(
                showTime: true,
                timeFormat: (_) => 'TS',
                userTimeTextStyle: const TextStyle(color: userColor),
                aiTimeTextStyle: const TextStyle(color: aiColor),
              ),
            ),
          ),
        ),
      );

      controller.addMessage(ChatMessage(
        text: 'hi from user',
        user: humanUser,
        createdAt: DateTime.now(),
      ));
      controller.addMessage(ChatMessage(
        text: 'hi from ai',
        user: aiUser,
        createdAt: DateTime.now(),
      ));
      await tester.pumpAndSettle();

      final colors = tester
          .widgetList<Text>(find.text('TS'))
          .map((t) => t.style?.color)
          .toSet();

      expect(colors.contains(userColor), isTrue);
      expect(colors.contains(aiColor), isTrue);

      controller.dispose();
    });

    testWidgets('falls back to shared timeTextStyle when per-bubble null',
        (tester) async {
      final controller = ChatMessagesController();
      const sharedColor = Color(0xFF0000AA);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AiChatWidget(
              currentUser: humanUser,
              aiUser: aiUser,
              controller: controller,
              onSendMessage: (_) {},
              messageOptions: MessageOptions(
                showTime: true,
                timeFormat: (_) => 'TS',
                timeTextStyle: const TextStyle(color: sharedColor),
              ),
            ),
          ),
        ),
      );

      controller.addMessage(ChatMessage(
        text: 'from user',
        user: humanUser,
        createdAt: DateTime.now(),
      ));
      await tester.pumpAndSettle();

      final colors = tester
          .widgetList<Text>(find.text('TS'))
          .map((t) => t.style?.color)
          .toSet();

      expect(colors.contains(sharedColor), isTrue);

      controller.dispose();
    });

    test('copyWith preserves per-bubble timestamp styles', () {
      const base = MessageOptions(
        userTimeTextStyle: TextStyle(color: Color(0xFF112233)),
        aiTimeTextStyle: TextStyle(color: Color(0xFF445566)),
      );
      final copy = base.copyWith(showTime: false);

      expect(copy.userTimeTextStyle?.color, const Color(0xFF112233));
      expect(copy.aiTimeTextStyle?.color, const Color(0xFF445566));
      expect(copy.showTime, isFalse);
    });
  });
}
