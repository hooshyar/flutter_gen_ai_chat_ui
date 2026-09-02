import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';

/// Part of the documented-knob verification sweep (issue #41 Phase 0.5).
///
/// `PaginationConfig.enableHapticFeedback` — documented "Whether to enable
/// haptic feedback when loading more messages" — was never read anywhere;
/// load-more never triggered haptic feedback regardless of the setting.
void main() {
  const testUser = ChatUser(id: 'user', name: 'Test User');
  const aiUser = ChatUser(id: 'ai', name: 'AI Assistant');

  Future<int> pumpAndTriggerLoadMore(
    WidgetTester tester, {
    required bool enableHapticFeedback,
  }) async {
    var hapticCalls = 0;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') hapticCalls++;
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    final controller = ChatMessagesController(
      initialMessages: List.generate(
        30,
        (i) => ChatMessage(
          text: 'Message $i ' * 8,
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
              messageListOptions: MessageListOptions(
                hasMoreMessages: true,
                isLoadingMore: false,
                onLoadMore: () async {},
                paginationConfig: PaginationConfig(
                  enabled: true,
                  autoLoadOnScroll: true,
                  distanceToTriggerLoadPixels: 100,
                  loadMoreDebounceTime: Duration.zero,
                  enableHapticFeedback: enableHapticFeedback,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    // Move away from the edge first so there's a real position change to
    // notify on, then jump back near the reverse-order edge (pixels near 0)
    // to fire the "near the edge" pagination trigger — it's only evaluated
    // inside the scroll listener, not on initial layout.
    expect(scrollController.position.maxScrollExtent, greaterThan(200));
    scrollController.jumpTo(scrollController.position.maxScrollExtent);
    await tester.pump(const Duration(milliseconds: 50));
    scrollController.jumpTo(1);
    await tester.pump(const Duration(milliseconds: 50));

    return hapticCalls;
  }

  testWidgets('haptic feedback fires on load-more when enabled',
      (tester) async {
    final calls =
        await pumpAndTriggerLoadMore(tester, enableHapticFeedback: true);
    expect(calls, greaterThan(0));
  });

  testWidgets('haptic feedback does not fire when disabled', (tester) async {
    final calls =
        await pumpAndTriggerLoadMore(tester, enableHapticFeedback: false);
    expect(calls, 0);
  });
}
