// TEMPORARY diagnostic (agent/preview-42* only, never merged): does the
// end-of-stream auto-scroll reach the bottom of a chronological list, with
// and without a pin?
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';

void main() {
  const testUser = ChatUser(id: 'user', name: 'You');
  const aiUser = ChatUser(id: 'ai', name: 'AI');
  final longAnswer = List.generate(
    160,
    (i) => 'Line $i of a very long streaming answer that keeps growing.',
  ).join('\n\n');

  for (final anchor in [
    StreamingPinAnchor.none,
    StreamingPinAnchor.responseStart,
  ]) {
    for (final behavior in [
      AutoScrollBehavior.onNewMessage,
      AutoScrollBehavior.always,
    ]) {
      for (final reduce in [false, true]) {
        testWidgets('diag $anchor $behavior reduceMotion=$reduce',
            (tester) async {
          await withClock(tester.binding.clock, () async {
            final pagination = PaginationConfig(reverseOrder: false);
            final controller = ChatMessagesController(
              scrollBehaviorConfig: ScrollBehaviorConfig(
                pinDuringStreaming: anchor,
                autoScrollBehavior: behavior,
              ),
              paginationConfig: pagination,
            );
            addTearDown(controller.dispose);
            Widget chat = AiChatWidget(
              currentUser: testUser,
              aiUser: aiUser,
              controller: controller,
              onSendMessage: (_) async {},
              paginationConfig: pagination,
              enableMarkdownStreaming: false,
            );
            if (reduce) {
              final inner = chat;
              chat = Builder(
                builder: (context) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(disableAnimations: true),
                  child: inner,
                ),
              );
            }
            await tester.pumpWidget(MaterialApp(home: Material(child: chat)));
            await tester.pump();
            Future<void> settle() async {
              for (var i = 0; i < 30; i++) {
                await tester.pump(const Duration(milliseconds: 100));
              }
            }

            ScrollPosition pos() => tester
                .state<ScrollableState>(find.byType(Scrollable).first)
                .position;
            String at() =>
                'px ${pos().pixels.toStringAsFixed(0)}/max ${pos().maxScrollExtent.toStringAsFixed(0)}';
            controller.addMessage(ChatMessage(
              text: 'Q',
              user: testUser,
              createdAt: DateTime.now(),
              customProperties: const {'id': 'u1'},
            ));
            await settle();
            ChatMessage a(int i, bool s) => ChatMessage(
                  text: longAnswer.substring(
                      0, (longAnswer.length * i / 16).floor()),
                  user: aiUser,
                  createdAt: DateTime(2026),
                  customProperties: {'id': 'resp1', 'isStreaming': s},
                );
            for (var i = 1; i <= 8; i++) {
              i == 1
                  ? controller.addMessage(a(i, true))
                  : controller.updateMessage(a(i, true));
              await tester.pump(const Duration(milliseconds: 50));
              await tester.pump(const Duration(milliseconds: 50));
            }
            await settle();
            final mid = at();
            final button = find.byIcon(Icons.arrow_downward_rounded);
            final hasButton = button.evaluate().isNotEmpty;
            if (hasButton) {
              await tester.tap(button);
              await tester.pump();
              await settle();
            }
            final afterTap = at();
            for (var i = 9; i <= 16; i++) {
              controller.updateMessage(a(i, true));
              await tester.pump(const Duration(milliseconds: 50));
              await tester.pump(const Duration(milliseconds: 50));
            }
            await settle();
            final streamed = at();
            controller.updateMessage(a(16, false));
            controller.stopStreamingMessage('resp1');
            await settle();
            final ended = at();
            // ignore: avoid_print
            print('DIAG $anchor $behavior reduce=$reduce | mid $mid | '
                'button $hasButton -> $afterTap | streamed $streamed | '
                'ended $ended');
          });
        });
      }
    }
  }
}
