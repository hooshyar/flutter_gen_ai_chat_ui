import 'package:flutter/material.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final aiUser = ChatUser(id: 'ai', name: 'AI');
  final humanUser = ChatUser(id: 'user', name: 'User');

  group('sendOrMicBuilder', () {
    testWidgets('shows mic icon when text is empty', (tester) async {
      final controller = ChatMessagesController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AiChatWidget(
              currentUser: humanUser,
              aiUser: aiUser,
              controller: controller,
              onSendMessage: (_) {},
              inputOptions: InputOptions(
                sendOrMicBuilder: (onSend, isEmpty) => isEmpty
                    ? const Icon(Icons.mic, key: Key('mic'))
                    : IconButton(
                        key: const Key('send'),
                        icon: const Icon(Icons.send),
                        onPressed: onSend,
                      ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('mic')), findsOneWidget);
      expect(find.byKey(const Key('send')), findsNothing);

      controller.dispose();
    });

    testWidgets('shows send icon when text is entered', (tester) async {
      final controller = ChatMessagesController();
      final textController = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AiChatWidget(
              currentUser: humanUser,
              aiUser: aiUser,
              controller: controller,
              onSendMessage: (_) {},
              inputOptions: InputOptions(
                textController: textController,
                sendOrMicBuilder: (onSend, isEmpty) => isEmpty
                    ? const Icon(Icons.mic, key: Key('mic'))
                    : IconButton(
                        key: const Key('send'),
                        icon: const Icon(Icons.send),
                        onPressed: onSend,
                      ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially empty → mic
      expect(find.byKey(const Key('mic')), findsOneWidget);

      // Type text
      textController.text = 'hello';
      await tester.pump();

      // Now has text → send
      expect(find.byKey(const Key('send')), findsOneWidget);
      expect(find.byKey(const Key('mic')), findsNothing);

      // Clear text
      textController.text = '';
      await tester.pump();

      // Empty again → mic
      expect(find.byKey(const Key('mic')), findsOneWidget);

      controller.dispose();
      textController.dispose();
    });

    testWidgets('falls back to default send button when null', (tester) async {
      final controller = ChatMessagesController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AiChatWidget(
              currentUser: humanUser,
              aiUser: aiUser,
              controller: controller,
              onSendMessage: (_) {},
              inputOptions: const InputOptions(
                sendButtonIcon: Icons.arrow_upward,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Default send button should render with specified icon
      expect(find.byIcon(Icons.arrow_upward), findsOneWidget);

      controller.dispose();
    });

    testWidgets('sendButtonBuilder still works when sendOrMicBuilder is null',
        (tester) async {
      final controller = ChatMessagesController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AiChatWidget(
              currentUser: humanUser,
              aiUser: aiUser,
              controller: controller,
              onSendMessage: (_) {},
              inputOptions: InputOptions(
                sendButtonBuilder: (onSend) => IconButton(
                  key: const Key('custom-send'),
                  icon: const Icon(Icons.rocket),
                  onPressed: onSend,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('custom-send')), findsOneWidget);

      controller.dispose();
    });
  });

  group('ChatMessage.loading()', () {
    test('sets isLoading in customProperties', () {
      final msg = ChatMessage.loading(
        user: aiUser,
        id: 'load-1',
        text: 'Searching...',
      );

      expect(msg.customProperties?['isLoading'], isTrue);
      expect(msg.customProperties?['id'], 'load-1');
      expect(msg.text, 'Searching...');
    });

    test('text defaults to empty', () {
      final msg = ChatMessage.loading(user: aiUser, id: 'load-2');
      expect(msg.text, '');
      expect(msg.customProperties?['isLoading'], isTrue);
    });

    test('uses current time when createdAt not provided', () {
      final before = DateTime.now();
      final msg = ChatMessage.loading(user: aiUser, id: 'load-3');
      final after = DateTime.now();

      expect(
        msg.createdAt.isAfter(before.subtract(const Duration(seconds: 1))),
        isTrue,
      );
      expect(
        msg.createdAt.isBefore(after.add(const Duration(seconds: 1))),
        isTrue,
      );
    });

    testWidgets('renders shimmer bars in chat', (tester) async {
      final controller = ChatMessagesController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AiChatWidget(
              currentUser: humanUser,
              aiUser: aiUser,
              controller: controller,
              onSendMessage: (_) {},
            ),
          ),
        ),
      );

      controller.addMessage(ChatMessage.loading(
        user: aiUser,
        id: 'load-render',
        text: 'Processing...',
      ));
      await tester.pumpAndSettle();

      expect(find.text('Processing...'), findsOneWidget);

      controller.dispose();
    });

    testWidgets('loading message replaced by rich widget via updateMessage',
        (tester) async {
      final controller = ChatMessagesController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AiChatWidget(
              currentUser: humanUser,
              aiUser: aiUser,
              controller: controller,
              onSendMessage: (_) {},
              resultRenderers: {
                'weather': (context, data) => Text('Weather: ${data['city']}'),
              },
            ),
          ),
        ),
      );

      // Add loading
      controller.addMessage(ChatMessage.loading(
        user: aiUser,
        id: 'morph-1',
        text: 'Loading weather...',
      ));
      await tester.pumpAndSettle();
      expect(find.text('Loading weather...'), findsOneWidget);

      // Replace with rich widget
      controller.updateMessage(ChatMessage.rich(
        user: aiUser,
        id: 'morph-1',
        resultKind: 'weather',
        data: {'city': 'Baghdad'},
      ));
      await tester.pumpAndSettle();

      expect(find.text('Weather: Baghdad'), findsOneWidget);
      expect(find.text('Loading weather...'), findsNothing);

      controller.dispose();
    });

    testWidgets('loading message replaced by text via setMessages',
        (tester) async {
      final controller = ChatMessagesController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AiChatWidget(
              currentUser: humanUser,
              aiUser: aiUser,
              controller: controller,
              onSendMessage: (_) {},
            ),
          ),
        ),
      );

      // Add loading
      final loadingMsg = ChatMessage.loading(
        user: aiUser,
        id: 'morph-2',
        text: 'Thinking...',
      );
      controller.addMessage(loadingMsg);
      await tester.pumpAndSettle();
      expect(find.text('Thinking...'), findsOneWidget);

      // Replace entire messages list with final text
      controller.setMessages([
        ChatMessage(
          user: aiUser,
          text: 'Final answer here.',
          createdAt: DateTime.now(),
        ),
      ]);
      await tester.pumpAndSettle();

      expect(find.text('Thinking...'), findsNothing);

      controller.dispose();
    });
  });

  group('effectiveSendWidget', () {
    test('returns sendOrMicBuilder when set', () {
      final options = InputOptions(
        sendOrMicBuilder: (onSend, isEmpty) => const Text('custom'),
      );

      final widget = options.effectiveSendWidget(() {}, isEmpty: true);
      expect(widget, isA<Text>());
    });

    test('falls back to effectiveSendButtonBuilder when sendOrMicBuilder null',
        () {
      const options = InputOptions(sendButtonIcon: Icons.send);

      final widget = options.effectiveSendWidget(() {});
      expect(widget, isA<IconButton>());
    });

    test('passes isEmpty correctly', () {
      bool? receivedIsEmpty;
      final options = InputOptions(
        sendOrMicBuilder: (onSend, isEmpty) {
          receivedIsEmpty = isEmpty;
          return const SizedBox();
        },
      );

      options.effectiveSendWidget(() {}, isEmpty: true);
      expect(receivedIsEmpty, isTrue);

      options.effectiveSendWidget(() {}, isEmpty: false);
      expect(receivedIsEmpty, isFalse);
    });
  });

  group('ChatMessage.loading with loadingKind', () {
    test('sets loadingKind in customProperties', () {
      final msg = ChatMessage.loading(
        user: aiUser,
        id: 'load-kind-1',
        loadingKind: 'contract',
        text: 'Generating contract...',
      );

      expect(msg.customProperties?['isLoading'], isTrue);
      expect(msg.customProperties?['loadingKind'], 'contract');
      expect(msg.customProperties?['id'], 'load-kind-1');
      expect(msg.text, 'Generating contract...');
    });

    test('loadingKind is absent when not provided', () {
      final msg = ChatMessage.loading(user: aiUser, id: 'load-kind-2');

      expect(msg.customProperties?['isLoading'], isTrue);
      expect(msg.customProperties?.containsKey('loadingKind'), isFalse);
    });

    testWidgets('renders custom loading widget per kind', (tester) async {
      final controller = ChatMessagesController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AiChatWidget(
              currentUser: humanUser,
              aiUser: aiUser,
              controller: controller,
              onSendMessage: (_) {},
              resultLoadingRenderers: {
                'contract': (context, data) =>
                    const Text('Generating your contract...'),
                'lawyer_search': (context, data) =>
                    const Text('Searching lawyers near you...'),
              },
            ),
          ),
        ),
      );

      controller.addMessage(ChatMessage.loading(
        user: aiUser,
        id: 'custom-load-1',
        loadingKind: 'contract',
      ));
      await tester.pumpAndSettle();

      expect(find.text('Generating your contract...'), findsOneWidget);

      controller.dispose();
    });

    testWidgets('falls back to shimmer when loadingKind has no renderer',
        (tester) async {
      final controller = ChatMessagesController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AiChatWidget(
              currentUser: humanUser,
              aiUser: aiUser,
              controller: controller,
              onSendMessage: (_) {},
              resultLoadingRenderers: {
                'contract': (context, data) => const Text('Generating...'),
              },
            ),
          ),
        ),
      );

      // Use an unregistered kind
      controller.addMessage(ChatMessage.loading(
        user: aiUser,
        id: 'custom-load-2',
        loadingKind: 'unknown_kind',
        text: 'Processing...',
      ));
      await tester.pumpAndSettle();

      // Should show default loading with text, not the custom renderer
      expect(find.text('Processing...'), findsOneWidget);
      expect(find.text('Generating...'), findsNothing);

      controller.dispose();
    });

    testWidgets('custom loading replaced by rich widget', (tester) async {
      final controller = ChatMessagesController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AiChatWidget(
              currentUser: humanUser,
              aiUser: aiUser,
              controller: controller,
              onSendMessage: (_) {},
              resultRenderers: {
                'contract_status': (context, data) =>
                    Text('Contract: ${data['title']}'),
              },
              resultLoadingRenderers: {
                'contract': (context, data) =>
                    const Text('Drafting contract...'),
              },
            ),
          ),
        ),
      );

      // Show custom loading
      controller.addMessage(ChatMessage.loading(
        user: aiUser,
        id: 'morph-contract',
        loadingKind: 'contract',
      ));
      await tester.pumpAndSettle();
      expect(find.text('Drafting contract...'), findsOneWidget);

      // Replace with rich widget
      controller.updateMessage(ChatMessage.rich(
        user: aiUser,
        id: 'morph-contract',
        resultKind: 'contract_status',
        data: {'title': 'Employment Agreement'},
      ));
      await tester.pumpAndSettle();

      expect(find.text('Contract: Employment Agreement'), findsOneWidget);
      expect(find.text('Drafting contract...'), findsNothing);

      controller.dispose();
    });

    testWidgets('no loadingKind renders default shimmer', (tester) async {
      final controller = ChatMessagesController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AiChatWidget(
              currentUser: humanUser,
              aiUser: aiUser,
              controller: controller,
              onSendMessage: (_) {},
            ),
          ),
        ),
      );

      controller.addMessage(ChatMessage.loading(
        user: aiUser,
        id: 'default-shimmer',
        text: 'Thinking...',
      ));
      await tester.pumpAndSettle();

      // Default shimmer with text
      expect(find.text('Thinking...'), findsOneWidget);

      controller.dispose();
    });
  });
}
