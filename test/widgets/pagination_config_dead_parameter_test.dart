import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';

/// Part of the documented-knob verification sweep (issue #41 Phase 0.5).
///
/// `AiChatWidget.paginationConfig` — documented as "Configuration for
/// pagination" — was never read anywhere in `ai_chat_widget.dart`'s build
/// method: pagination only actually worked when set via
/// `AiChatWidget(messageListOptions: MessageListOptions(paginationConfig:
/// ...))`. Fixed by merging `widget.paginationConfig` into the
/// `messageListOptions` handed to `CustomChatWidget` (same precedence the
/// widget already gives its `scrollController` shortcut over
/// `messageListOptions.scrollController`).
void main() {
  const testUser = ChatUser(id: 'user', name: 'Test User');
  const aiUser = ChatUser(id: 'ai', name: 'AI Assistant');

  testWidgets(
      'AiChatWidget.paginationConfig actually reaches the loading indicator',
      (tester) async {
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
            paginationConfig:
                const PaginationConfig(loadingText: 'CustomLoadingText123'),
            messageListOptions: const MessageListOptions(isLoadingMore: true),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('CustomLoadingText123'), findsOneWidget);
  });
}
