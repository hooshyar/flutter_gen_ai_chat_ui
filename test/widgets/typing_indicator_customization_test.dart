import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';

/// Part of the documented-knob verification sweep (issue #41 Phase 0.5).
///
/// `LoadingConfig.typingIndicatorColor` / `.typingIndicatorSize` were
/// documented ("Color for the typing indicator", "Size of the typing
/// indicator") but never threaded past `AiChatWidget` — the default typing
/// dots were hardcoded to a fixed grey and 8px size regardless. Fixed by
/// plumbing both through `CustomChatWidget` into the `_DotIndicator` widget.
void main() {
  const testUser = ChatUser(id: 'user', name: 'Test User');
  const aiUser = ChatUser(id: 'ai', name: 'AI Assistant');

  Finder dotContainers(WidgetTester tester) => find.byWidgetPredicate(
        (w) =>
            w is Container &&
            w.decoration is BoxDecoration &&
            (w.decoration! as BoxDecoration).shape == BoxShape.circle,
      );

  testWidgets('default typing indicator uses the configured size',
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
            loadingConfig: const LoadingConfig(
              isLoading: true,
              typingIndicatorColor: Colors.red,
              typingIndicatorSize: 20,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final dots = dotContainers(tester);
    expect(dots, findsWidgets);
    for (final element in dots.evaluate()) {
      final container = element.widget as Container;
      expect(container.constraints?.maxWidth, 20.0);
    }
  });

  testWidgets(
      'default typing indicator falls back to the default grey/size '
      'when unconfigured', (tester) async {
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
            loadingConfig: const LoadingConfig(isLoading: true),
          ),
        ),
      ),
    );
    await tester.pump();

    final dots = dotContainers(tester);
    expect(dots, findsWidgets);
    for (final element in dots.evaluate()) {
      final container = element.widget as Container;
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.color, isNot(Colors.red));
    }
  });
}
