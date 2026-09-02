import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';

/// Part of the documented-knob verification sweep (issue #41 Phase 0.5).
///
/// Two more `AiChatWidget` top-level convenience parameters were found
/// completely dead this tick, the same bug class as `paginationConfig`:
/// never merged into the effective options handed to `CustomChatWidget`.
void main() {
  const testUser = ChatUser(id: 'user', name: 'Test User');
  const aiUser = ChatUser(id: 'ai', name: 'AI Assistant');

  testWidgets('AiChatWidget.padding actually applies', (tester) async {
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
            padding: const EdgeInsets.all(37),
          ),
        ),
      ),
    );
    await tester.pump();

    final padding = tester.widgetList<Padding>(find.byType(Padding)).where(
          (p) => p.padding == const EdgeInsets.all(37),
        );
    expect(padding, isNotEmpty);
  });

  testWidgets(
      'AiChatWidget.markdownStyleSheet actually applies without setting '
      'messageOptions', (tester) async {
    final controller = ChatMessagesController(
      initialMessages: [
        ChatMessage(
          text: 'Hello',
          user: aiUser,
          createdAt: DateTime.now(),
          isMarkdown: true,
        ),
      ],
    );
    addTearDown(controller.dispose);

    final customSheet = MarkdownStyleSheet(
      p: const TextStyle(color: Colors.deepOrange),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: AiChatWidget(
            currentUser: testUser,
            aiUser: aiUser,
            controller: controller,
            onSendMessage: (_) async {},
            enableMarkdownStreaming: false,
            markdownStyleSheet: customSheet,
          ),
        ),
      ),
    );
    await tester.pump();

    final markdown = tester.widget<Markdown>(find.byType(Markdown));
    expect(markdown.styleSheet, same(customSheet));
  });
}
