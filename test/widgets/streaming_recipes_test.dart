import 'package:flutter/material.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';
import 'package:flutter_gen_ai_chat_ui/src/widgets/message/streaming_caret.dart';
import 'package:flutter_test/flutter_test.dart';

/// Covers both documented streaming recipes end to end, for both
/// `enableMarkdownStreaming: true` and `false`:
///
/// - Recipe (a) — README ~lines 167-187: `addMessage`/`updateMessage` with
///   `isStreaming: true` on every call, ended ONLY by
///   `stopStreamingMessage(id)` (no `updateMessage(isStreaming: false)`).
/// - Recipe (b) — README ~line 606 and the example app
///   (`example/lib/shell/live_preview.dart`): `addStreamingMessage`, then
///   plain `updateMessage` calls with no `isStreaming` flag at all, ended by
///   `stopStreamingMessage`.
///
/// For each: the caret must stay visible and the Copy action hidden for the
/// whole open stream — even well past the reveal ticker's own catch-up
/// window — and, once the stream ends exactly as the recipe documents, the
/// caret must disappear and Copy must appear, with `pumpAndSettle` reaching
/// a stable frame.
///
/// A control case checks the ordinary, non-streaming path: a single complete
/// `addMessage` (no streaming at all) settles with Copy visible.
void main() {
  final testUser = ChatUser(id: 'user', firstName: 'User');
  final aiUser = ChatUser(id: 'ai', firstName: 'AI');

  const fullAnswer =
      'This is a long streaming answer with plenty of words so the reveal '
      'ticker has real backlog to work through before it catches up to the '
      'latest chunk that has arrived from the simulated network stream.';

  Future<ChatMessagesController> pumpChat(
    WidgetTester tester, {
    required bool enableMarkdownStreaming,
  }) async {
    final controller = ChatMessagesController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AiChatWidget(
            currentUser: testUser,
            aiUser: aiUser,
            controller: controller,
            onSendMessage: (_) async {},
            enableMarkdownStreaming: enableMarkdownStreaming,
          ),
        ),
      ),
    );
    await tester.pump();
    return controller;
  }

  Future<void> pumpPastReveal(WidgetTester tester) async {
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  void expectStillStreaming(bool enableMarkdownStreaming, String recipe) {
    expect(
      find.byType(StreamingCaret),
      findsOneWidget,
      reason: 'caret must stay visible for the whole open stream '
          '(recipe: $recipe, enableMarkdownStreaming: $enableMarkdownStreaming)',
    );
    expect(
      find.byIcon(Icons.content_copy_rounded),
      findsNothing,
      reason: 'the copy action must stay hidden while streaming '
          '(recipe: $recipe, enableMarkdownStreaming: $enableMarkdownStreaming)',
    );
  }

  void expectStreamEnded(bool enableMarkdownStreaming, String recipe) {
    expect(
      find.byType(StreamingCaret),
      findsNothing,
      reason: 'the caret must disappear once the stream ends '
          '(recipe: $recipe, enableMarkdownStreaming: $enableMarkdownStreaming)',
    );
    expect(
      find.byIcon(Icons.content_copy_rounded),
      findsOneWidget,
      reason: 'the copy action must appear once the stream ends '
          '(recipe: $recipe, enableMarkdownStreaming: $enableMarkdownStreaming)',
    );
  }

  /// Recipe (a): addMessage/updateMessage with isStreaming: true, ended
  /// ONLY by stopStreamingMessage(id) — no updateMessage(isStreaming: false).
  Future<void> runRecipeA(
    WidgetTester tester, {
    required bool enableMarkdownStreaming,
  }) async {
    final controller = await pumpChat(
      tester,
      enableMarkdownStreaming: enableMarkdownStreaming,
    );

    final aiMessage = ChatMessage(
      text: '',
      user: aiUser,
      createdAt: DateTime.now(),
      isMarkdown: true,
      customProperties: const {'id': 'recipeA', 'isStreaming': true},
    );
    controller.addMessage(aiMessage);
    await tester.pump();

    controller.updateMessage(
      aiMessage.copyWith(
        text: fullAnswer,
        customProperties: const {'id': 'recipeA', 'isStreaming': true},
      ),
    );
    await pumpPastReveal(tester);

    expectStillStreaming(enableMarkdownStreaming, 'a');

    // End EXACTLY as the recipe documents: stopStreamingMessage only.
    controller.stopStreamingMessage('recipeA');
    await tester.pumpAndSettle();

    expectStreamEnded(enableMarkdownStreaming, 'a');
  }

  /// Recipe (b): addStreamingMessage, then updateMessage with no flag,
  /// ended by stopStreamingMessage.
  Future<void> runRecipeB(
    WidgetTester tester, {
    required bool enableMarkdownStreaming,
  }) async {
    final controller = await pumpChat(
      tester,
      enableMarkdownStreaming: enableMarkdownStreaming,
    );

    final aiMessage = ChatMessage(
      text: '',
      user: aiUser,
      createdAt: DateTime.now(),
      isMarkdown: true,
      customProperties: const {'id': 'recipeB'},
    );
    controller.addStreamingMessage(aiMessage);
    await tester.pump();

    // Bare updateMessage calls — no isStreaming flag at all.
    controller.updateMessage(aiMessage.copyWith(text: fullAnswer));
    await pumpPastReveal(tester);

    expectStillStreaming(enableMarkdownStreaming, 'b');

    controller.stopStreamingMessage('recipeB');
    await tester.pumpAndSettle();

    expectStreamEnded(enableMarkdownStreaming, 'b');
  }

  group('recipe (a): isStreaming flag, stopStreamingMessage only', () {
    testWidgets('enableMarkdownStreaming: true', (tester) async {
      await runRecipeA(tester, enableMarkdownStreaming: true);
    });

    testWidgets('enableMarkdownStreaming: false', (tester) async {
      await runRecipeA(tester, enableMarkdownStreaming: false);
    });
  });

  group('recipe (b): addStreamingMessage + bare updateMessage', () {
    testWidgets('enableMarkdownStreaming: true', (tester) async {
      await runRecipeB(tester, enableMarkdownStreaming: true);
    });

    testWidgets('enableMarkdownStreaming: false', (tester) async {
      await runRecipeB(tester, enableMarkdownStreaming: false);
    });
  });

  testWidgets(
    'control: a plain complete addMessage settles with Copy visible',
    (tester) async {
      final controller = await pumpChat(
        tester,
        enableMarkdownStreaming: true,
      );

      controller.addMessage(ChatMessage(
        text: 'A short, complete answer with no streaming at all.',
        user: aiUser,
        createdAt: DateTime.now(),
        isMarkdown: true,
        customProperties: const {'id': 'plain1'},
      ));
      await tester.pumpAndSettle();

      expect(
        find.byType(StreamingCaret),
        findsNothing,
        reason: 'a plain, complete message must never show the live caret',
      );
      expect(
        find.byIcon(Icons.content_copy_rounded),
        findsOneWidget,
        reason: 'a plain, complete message must show the copy action',
      );
    },
  );

  group('ChatMessagesController.isMessageStreaming unit semantics', () {
    late ChatMessagesController controller;

    setUp(() {
      controller = ChatMessagesController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('addStreamingMessage opens the stream', () {
      final aiMessage = ChatMessage(
        text: '',
        user: aiUser,
        createdAt: DateTime.now(),
        customProperties: const {'id': 'u1'},
      );
      controller.addStreamingMessage(aiMessage);
      expect(controller.isMessageStreaming('u1'), isTrue);
    });

    test('the public setStreamingMessage opens the stream', () {
      controller.setStreamingMessage('u2');
      expect(controller.isMessageStreaming('u2'), isTrue);
    });

    test('addMessage with isStreaming: true opens the stream', () {
      controller.addMessage(ChatMessage(
        text: '',
        user: aiUser,
        createdAt: DateTime.now(),
        customProperties: const {'id': 'u3', 'isStreaming': true},
      ));
      expect(controller.isMessageStreaming('u3'), isTrue);
    });

    test('a plain addMessage (no isStreaming key) does NOT open the stream',
        () {
      controller.addMessage(ChatMessage(
        text: 'hello',
        user: aiUser,
        createdAt: DateTime.now(),
        customProperties: const {'id': 'u4'},
      ));
      expect(controller.isMessageStreaming('u4'), isFalse);
    });

    test('updateMessage with isStreaming: false closes an open stream', () {
      controller.setStreamingMessage('u5');
      expect(controller.isMessageStreaming('u5'), isTrue);

      controller.updateMessage(ChatMessage(
        text: 'done',
        user: aiUser,
        createdAt: DateTime.now(),
        customProperties: const {'id': 'u5', 'isStreaming': false},
      ));
      expect(controller.isMessageStreaming('u5'), isFalse);
    });

    test(
        'updateMessage with a MISSING isStreaming key does not close an '
        'open stream', () {
      controller.setStreamingMessage('u6');
      expect(controller.isMessageStreaming('u6'), isTrue);

      controller.updateMessage(ChatMessage(
        text: 'still going',
        user: aiUser,
        createdAt: DateTime.now(),
        customProperties: const {'id': 'u6'},
      ));
      expect(
        controller.isMessageStreaming('u6'),
        isTrue,
        reason: 'a missing isStreaming key must never close an open stream',
      );
    });

    test('stopStreamingMessage unconditionally closes the stream', () {
      controller.setStreamingMessage('u7');
      expect(controller.isMessageStreaming('u7'), isTrue);

      controller.stopStreamingMessage('u7');
      expect(controller.isMessageStreaming('u7'), isFalse);
    });

    test(
        'stopStreamingMessage rewrites a stored isStreaming:true message to '
        'false', () {
      controller.addMessage(ChatMessage(
        text: 'partial',
        user: aiUser,
        createdAt: DateTime.now(),
        customProperties: const {'id': 'u8', 'isStreaming': true},
      ));
      controller.stopStreamingMessage('u8');

      final stored = controller.messages
          .firstWhere((m) => controller.getMessageId(m) == 'u8');
      expect(stored.customProperties?['isStreaming'], isFalse);
    });

    test(
        'stopStreamingMessage acts even when the id is not '
        'currentlyStreamingMessageId', () {
      // Simulate a newer AI message having already taken over
      // currentlyStreamingMessageId.
      controller.setStreamingMessage('older');
      controller.setStreamingMessage('newer');
      expect(controller.isMessageStreaming('older'), isTrue);

      controller.stopStreamingMessage('older');
      expect(controller.isMessageStreaming('older'), isFalse);
    });
  });
}
