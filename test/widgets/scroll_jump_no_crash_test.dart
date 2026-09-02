import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';

/// Regression guard: an earlier fix for issue #42 (see
/// scroll_to_first_response_single_message_test.dart) attached a persistent
/// [GlobalKey] to every `ListView.builder` message item so the controller
/// could measure a message's real rendered position. That tripped a Flutter
/// framework semantics assertion (`_needsLayout` during `flushSemantics`)
/// the moment the list was actually scrolled via `ScrollController.jumpTo`
/// (or a drag gesture) — not just measured — because `ListView.builder`
/// recycles/repositions items as it scrolls, which doesn't mix safely with a
/// long-lived `GlobalKey` on the recycled item itself. The fix replaced the
/// `GlobalKey` with a plain element-tree walk keyed off the existing
/// `ValueKey`, which has no such lifecycle interaction with the scrolling
/// item. This test exercises the exact failure shape (many messages, a
/// direct `jumpTo`) so a regression here fails loudly instead of only
/// showing up for real users mid-scroll.
void main() {
  testWidgets('scrolling the message list via jumpTo does not throw',
      (tester) async {
    const testUser = ChatUser(id: 'user', name: 'Test User');
    const aiUser = ChatUser(id: 'ai', name: 'AI Assistant');
    final controller = ChatMessagesController(
      initialMessages: List.generate(
        20,
        (i) => ChatMessage(
          text: 'Message $i',
          user: i.isEven ? testUser : aiUser,
          createdAt: DateTime.now(),
        ),
      ),
    );
    addTearDown(controller.dispose);
    final scrollController = ScrollController();
    addTearDown(scrollController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: SizedBox(
            height: 400,
            child: AiChatWidget(
              currentUser: testUser,
              aiUser: aiUser,
              controller: controller,
              onSendMessage: (_) async {},
              scrollController: scrollController,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    // Exercises the code path that previously crashed: jumping the position
    // (not an animated scroll) while the list has more built items than fit
    // in the viewport.
    scrollController.jumpTo(1);
    await tester.pump();
    scrollController.jumpTo(scrollController.position.maxScrollExtent);
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
