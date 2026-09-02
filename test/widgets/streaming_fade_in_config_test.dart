import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_streaming_text_markdown/flutter_streaming_text_markdown.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';

/// Part of the documented-knob verification sweep (issue #41 Phase 0.5).
///
/// `AiChatWidget.streamingFadeInEnabled` / `.streamingFadeInDuration` /
/// `.streamingFadeInCurve` were wired through to the underlying
/// `StreamingText` widget but had no test asserting the values actually
/// arrive there rather than being silently dropped or defaulted.
void main() {
  const testUser = ChatUser(id: 'user', name: 'Test User');
  const aiUser = ChatUser(id: 'ai', name: 'AI Assistant');

  testWidgets(
      'streamingFadeIn* config reaches the underlying StreamingText widget',
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
            streamingWordByWord: true,
            streamingFadeInEnabled: true,
            streamingFadeInDuration: const Duration(milliseconds: 777),
            streamingFadeInCurve: Curves.bounceIn,
          ),
        ),
      ),
    );
    await tester.pump();

    // addMessage() marks any AI message as "currently streaming" regardless
    // of intent, which would otherwise route it through the separate
    // controller-driven reveal ticker instead of the one-shot StreamingText
    // path this test targets. Stop it immediately (before the next pump) to
    // exercise the "complete message added via addMessage()" case the
    // streamingWordByWord + StreamingText path is documented to cover.
    controller.addMessage(ChatMessage(
      text: 'A complete AI answer delivered all at once.',
      user: aiUser,
      createdAt: DateTime.now(),
      customProperties: const {'id': 'resp1'},
    ));
    controller.stopStreamingMessage('resp1');
    await tester.pump();

    final streamingText = tester.widget<StreamingText>(
      find.byType(StreamingText),
    );
    expect(streamingText.fadeInEnabled, isTrue);
    expect(streamingText.fadeInDuration, const Duration(milliseconds: 777));
    expect(streamingText.fadeInCurve, Curves.bounceIn);

    // addMessage() may schedule a debounced auto-scroll Timer (up to 300ms)
    // that a bare `pump()` above doesn't wait out; drain it before teardown
    // so it isn't reported as still pending.
    await tester.pump(const Duration(milliseconds: 350));
  });

  testWidgets('streamingFadeInEnabled defaults to false', (tester) async {
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
            streamingWordByWord: true,
          ),
        ),
      ),
    );
    await tester.pump();

    // addMessage() marks any AI message as "currently streaming" regardless
    // of intent, which would otherwise route it through the separate
    // controller-driven reveal ticker instead of the one-shot StreamingText
    // path this test targets. Stop it immediately (before the next pump) to
    // exercise the "complete message added via addMessage()" case the
    // streamingWordByWord + StreamingText path is documented to cover.
    controller.addMessage(ChatMessage(
      text: 'A complete AI answer delivered all at once.',
      user: aiUser,
      createdAt: DateTime.now(),
      customProperties: const {'id': 'resp1'},
    ));
    controller.stopStreamingMessage('resp1');
    await tester.pump();

    final streamingText = tester.widget<StreamingText>(
      find.byType(StreamingText),
    );
    expect(streamingText.fadeInEnabled, isFalse);

    // See the drain note in the test above.
    await tester.pump(const Duration(milliseconds: 350));
  });
}
