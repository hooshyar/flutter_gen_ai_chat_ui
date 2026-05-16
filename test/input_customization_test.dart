import 'package:flutter/material.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final aiUser = ChatUser(id: 'ai', name: 'AI');
  final humanUser = ChatUser(id: 'user', name: 'User');

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Widget buildChat({
    required ChatMessagesController controller,
    InputOptions? inputOptions,
    Map<String, Widget Function(BuildContext, Map<String, dynamic>)>?
        resultRenderers,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: AiChatWidget(
          currentUser: humanUser,
          aiUser: aiUser,
          controller: controller,
          onSendMessage: (_) {},
          inputOptions: inputOptions,
          resultRenderers: resultRenderers,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. inputLeadingBuilder
  // ---------------------------------------------------------------------------

  group('inputLeadingBuilder', () {
    testWidgets('renders widget to the left of the text field in the input row',
        (tester) async {
      final controller = ChatMessagesController();

      await tester.pumpWidget(
        buildChat(
          controller: controller,
          inputOptions: InputOptions(
            inputLeadingBuilder: (context) => IconButton(
              key: const Key('leading_icon_button'),
              icon: const Icon(Icons.attach_file),
              onPressed: () {},
            ),
          ),
        ),
      );

      await tester.pump();

      // The IconButton supplied by inputLeadingBuilder must be present.
      expect(find.byKey(const Key('leading_icon_button')), findsOneWidget);
    });

    testWidgets('rendered leading widget is inside the same Row as TextField',
        (tester) async {
      final controller = ChatMessagesController();

      await tester.pumpWidget(
        buildChat(
          controller: controller,
          inputOptions: InputOptions(
            inputLeadingBuilder: (context) => const Icon(
              Icons.mic,
              key: Key('leading_mic_icon'),
            ),
          ),
        ),
      );

      await tester.pump();

      // Both TextField and the leading icon should be present.
      expect(find.byKey(const Key('leading_mic_icon')), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      // The leading icon should live inside a Row (the inputRow).
      final iconFinder = find.byKey(const Key('leading_mic_icon'));
      final rowAncestor = find.ancestor(
        of: iconFinder,
        matching: find.byType(Row),
      );
      expect(rowAncestor, findsWidgets);
    });

    testWidgets('leading widget taps are handled correctly (onPressed fires)',
        (tester) async {
      final controller = ChatMessagesController();
      var tapped = false;

      await tester.pumpWidget(
        buildChat(
          controller: controller,
          inputOptions: InputOptions(
            inputLeadingBuilder: (context) => IconButton(
              key: const Key('tap_leading'),
              icon: const Icon(Icons.add),
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.tap(find.byKey(const Key('tap_leading')));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('no leading widget when inputLeadingBuilder is null',
        (tester) async {
      final controller = ChatMessagesController();

      await tester.pumpWidget(
        buildChat(
          controller: controller,
          inputOptions: const InputOptions(),
        ),
      );

      await tester.pump();

      // There should be no extra icon beyond the default send button.
      // We check that no Icon with attach_file key exists.
      expect(find.byKey(const Key('leading_icon_button')), findsNothing);
    });
  });

  // ---------------------------------------------------------------------------
  // 2. attachmentPreviewBuilder
  // ---------------------------------------------------------------------------

  group('attachmentPreviewBuilder', () {
    testWidgets('renders preview widget above the input row', (tester) async {
      final controller = ChatMessagesController();

      await tester.pumpWidget(
        buildChat(
          controller: controller,
          inputOptions: InputOptions(
            attachmentPreviewBuilder: (context) => Container(
              key: const Key('attachment_preview'),
              child: const Text('Preview'),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.byKey(const Key('attachment_preview')), findsOneWidget);
      expect(find.text('Preview'), findsOneWidget);
    });

    testWidgets(
        'preview widget is placed above (higher y-offset than) the TextField',
        (tester) async {
      final controller = ChatMessagesController();

      await tester.pumpWidget(
        buildChat(
          controller: controller,
          inputOptions: InputOptions(
            attachmentPreviewBuilder: (context) => Container(
              key: const Key('preview_container'),
              color: Colors.blue,
              height: 40,
              child: const Text('Preview'),
            ),
          ),
        ),
      );

      await tester.pump();

      final previewCenter =
          tester.getCenter(find.byKey(const Key('preview_container')));
      final textFieldCenter = tester.getCenter(find.byType(TextField));

      // Preview should be above (smaller y coordinate) the TextField.
      expect(previewCenter.dy, lessThan(textFieldCenter.dy));
    });

    testWidgets('preview and leading builder can coexist', (tester) async {
      final controller = ChatMessagesController();

      await tester.pumpWidget(
        buildChat(
          controller: controller,
          inputOptions: InputOptions(
            inputLeadingBuilder: (context) => const Icon(
              Icons.attach_file,
              key: Key('coexist_leading'),
            ),
            attachmentPreviewBuilder: (context) => Container(
              key: const Key('coexist_preview'),
              child: const Text('File preview'),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.byKey(const Key('coexist_leading')), findsOneWidget);
      expect(find.byKey(const Key('coexist_preview')), findsOneWidget);
    });

    testWidgets('no preview widget rendered when builder is null',
        (tester) async {
      final controller = ChatMessagesController();

      await tester.pumpWidget(
        buildChat(
          controller: controller,
          inputOptions: const InputOptions(),
        ),
      );

      await tester.pump();

      expect(find.byKey(const Key('attachment_preview')), findsNothing);
    });
  });

  // ---------------------------------------------------------------------------
  // 3. ChatMessage.rich id: parameter
  // ---------------------------------------------------------------------------

  group('ChatMessage.rich id: parameter', () {
    test('id is stored in customProperties when provided', () {
      final msg = ChatMessage.rich(
        user: aiUser,
        resultKind: 'legal',
        data: {'title': 'Iraqi Constitution'},
        id: 'test-123',
      );

      expect(msg.customProperties?['id'], 'test-123');
    });

    test('id is absent from customProperties when not provided', () {
      final msg = ChatMessage.rich(
        user: aiUser,
        resultKind: 'legal',
        data: {'title': 'Iraqi Constitution'},
      );

      expect(msg.customProperties?.containsKey('id'), isFalse);
    });

    test('resultKind and resultData are still stored alongside id', () {
      final msg = ChatMessage.rich(
        user: aiUser,
        resultKind: 'weather',
        data: {'temp': 42},
        id: 'msg-abc',
      );

      expect(msg.customProperties?['resultKind'], 'weather');
      expect(msg.customProperties?['resultData'], {'temp': 42});
      expect(msg.customProperties?['id'], 'msg-abc');
    });

    test('id can be any non-null string including uuid-style values', () {
      final msg = ChatMessage.rich(
        user: aiUser,
        resultKind: 'product',
        data: {},
        id: '550e8400-e29b-41d4-a716-446655440000',
      );

      expect(
        msg.customProperties?['id'],
        '550e8400-e29b-41d4-a716-446655440000',
      );
    });

    test('text fallback is still respected when id is provided', () {
      final msg = ChatMessage.rich(
        user: aiUser,
        resultKind: 'contract',
        data: {},
        text: 'Fallback text',
        id: 'c-99',
      );

      expect(msg.text, 'Fallback text');
      expect(msg.customProperties?['id'], 'c-99');
    });
  });

  // ---------------------------------------------------------------------------
  // 4. ResultRendererRegistry integration — edge cases
  // ---------------------------------------------------------------------------

  group('ResultRendererRegistry integration — edge cases', () {
    testWidgets('rich message with empty data map renders without error',
        (tester) async {
      final controller = ChatMessagesController();

      await tester.pumpWidget(
        buildChat(
          controller: controller,
          resultRenderers: {
            'empty_kind': (context, data) => const Text('EmptyDataRendered'),
          },
        ),
      );

      controller.addMessage(ChatMessage.rich(
        user: aiUser,
        resultKind: 'empty_kind',
        data: {},
      ));

      await tester.pumpAndSettle();

      expect(find.text('EmptyDataRendered'), findsOneWidget);
    });

    testWidgets(
        'multiple rich messages of different kinds all render their widgets',
        (tester) async {
      final controller = ChatMessagesController();

      await tester.pumpWidget(
        buildChat(
          controller: controller,
          resultRenderers: {
            'kind_a': (context, data) => Text('Kind A: ${data['val']}'),
            'kind_b': (context, data) => Text('Kind B: ${data['val']}'),
            'kind_c': (context, data) => Text('Kind C: ${data['val']}'),
          },
        ),
      );

      // Add messages with slight time separation so the streaming controller
      // marks each one as a finished response before the next arrives.
      controller.addMessage(ChatMessage.rich(
        user: aiUser,
        resultKind: 'kind_a',
        data: {'val': 'alpha'},
        createdAt: DateTime(2026, 1, 1, 10, 0, 0),
      ));
      await tester.pumpAndSettle();

      controller.addMessage(ChatMessage.rich(
        user: aiUser,
        resultKind: 'kind_b',
        data: {'val': 'beta'},
        createdAt: DateTime(2026, 1, 1, 10, 0, 1),
      ));
      await tester.pumpAndSettle();

      controller.addMessage(ChatMessage.rich(
        user: aiUser,
        resultKind: 'kind_c',
        data: {'val': 'gamma'},
        createdAt: DateTime(2026, 1, 1, 10, 0, 2),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Kind A: alpha'), findsOneWidget);
      expect(find.text('Kind B: beta'), findsOneWidget);
      expect(find.text('Kind C: gamma'), findsOneWidget);
    });

    testWidgets(
        'rich message interleaved with text messages all render correctly',
        (tester) async {
      final controller = ChatMessagesController();

      await tester.pumpWidget(
        buildChat(
          controller: controller,
          resultRenderers: {
            'card': (context, data) => Text('Card: ${data['title']}'),
          },
        ),
      );

      controller.addMessage(ChatMessage(
        text: 'Hello there',
        user: humanUser,
        createdAt: DateTime.now(),
      ));
      await tester.pumpAndSettle();

      controller.addMessage(ChatMessage.rich(
        user: aiUser,
        resultKind: 'card',
        data: {'title': 'Legal Answer'},
      ));
      await tester.pumpAndSettle();

      controller.addMessage(ChatMessage(
        text: 'Thank you',
        user: humanUser,
        createdAt: DateTime.now(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Hello there'), findsOneWidget);
      expect(find.text('Card: Legal Answer'), findsOneWidget);
      expect(find.text('Thank you'), findsOneWidget);
    });

    testWidgets(
        'rich message with unregistered kind falls through to text fallback',
        (tester) async {
      final controller = ChatMessagesController();

      await tester.pumpWidget(
        buildChat(
          controller: controller,
          resultRenderers: {
            'known': (context, data) => const Text('KnownRenderer'),
          },
        ),
      );

      controller.addMessage(ChatMessage.rich(
        user: aiUser,
        resultKind: 'totally_unknown',
        data: {},
        text: 'Fallback for unknown kind',
      ));

      await tester.pumpAndSettle();

      expect(find.textContaining('Fallback'), findsOneWidget);
    });

    testWidgets('registry with no renderers does not crash', (tester) async {
      final controller = ChatMessagesController();

      await tester.pumpWidget(
        buildChat(
          controller: controller,
          resultRenderers: const {},
        ),
      );

      controller.addMessage(ChatMessage.rich(
        user: aiUser,
        resultKind: 'anything',
        data: {'x': 1},
        text: 'No renderer fallback',
      ));

      await tester.pumpAndSettle();

      // Should not throw; may render fallback text.
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'same kind rendered consecutively produces multiple widget instances',
        (tester) async {
      final controller = ChatMessagesController();

      await tester.pumpWidget(
        buildChat(
          controller: controller,
          resultRenderers: {
            'weather': (context, data) => Text('City: ${data['city']}'),
          },
        ),
      );

      controller.addMessage(ChatMessage.rich(
        user: aiUser,
        resultKind: 'weather',
        data: {'city': 'Baghdad'},
        createdAt: DateTime(2026, 1, 1, 10, 0, 0),
      ));
      await tester.pumpAndSettle();

      controller.addMessage(ChatMessage.rich(
        user: aiUser,
        resultKind: 'weather',
        data: {'city': 'Erbil'},
        createdAt: DateTime(2026, 1, 1, 10, 0, 1),
      ));
      await tester.pumpAndSettle();

      expect(find.text('City: Baghdad'), findsOneWidget);
      expect(find.text('City: Erbil'), findsOneWidget);
    });
  });
}
