// ignore_for_file: deprecated_member_use_from_same_package
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';

/// Part of the documented-knob verification sweep (issue #41 Phase 0.5).
///
/// `PaginationConfig.loadingIndicatorOffset` and `.loadMoreIndicator` are
/// documented but were never read anywhere — the loading indicator's
/// visibility is actually driven by `MessageListOptions.isLoadingMore`, and
/// its widget is actually built via `PaginationConfig.loadingBuilder` (or
/// the built-in default). Both are now `@Deprecated`, pointing at the
/// mechanisms that actually work; this test locks in that the real
/// mechanisms are what render, regardless of the deprecated fields.
void main() {
  const testUser = ChatUser(id: 'user', name: 'Test User');
  const aiUser = ChatUser(id: 'ai', name: 'AI Assistant');

  testWidgets(
      'loadingBuilder (not the deprecated loadMoreIndicator) renders the '
      'load-more indicator', (tester) async {
    final controller = ChatMessagesController(
      initialMessages: [
        ChatMessage(text: 'Hi', user: testUser, createdAt: DateTime.now()),
      ],
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: AiChatWidget(
            currentUser: testUser,
            aiUser: aiUser,
            controller: controller,
            onSendMessage: (_) async {},
            paginationConfig: PaginationConfig(
              // Deprecated, ignored field — set to prove it has no effect.
              loadMoreIndicator: ({required isLoading}) =>
                  const Text('IGNORED_DEPRECATED_INDICATOR'),
              loadingBuilder: () => const Text('REAL_LOADING_INDICATOR'),
            ),
            messageListOptions: const MessageListOptions(isLoadingMore: true),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('REAL_LOADING_INDICATOR'), findsOneWidget);
    expect(find.text('IGNORED_DEPRECATED_INDICATOR'), findsNothing);
  });
}
