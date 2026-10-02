import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';

void main() {
  group('ScrollBehaviorConfig', () {
    test('default constructor sets values correctly', () {
      const config = ScrollBehaviorConfig();

      expect(
        config.autoScrollBehavior,
        equals(AutoScrollBehavior.onNewMessage),
      );
      expect(config.scrollToFirstResponseMessage, isFalse);
      expect(
        config.scrollAnimationDuration,
        equals(const Duration(milliseconds: 300)),
      );
      expect(config.scrollAnimationCurve, equals(Curves.easeOut));
    });

    test('custom values are applied correctly', () {
      const config = ScrollBehaviorConfig(
        autoScrollBehavior: AutoScrollBehavior.always,
        scrollToFirstResponseMessage: true,
        scrollAnimationDuration: Duration(milliseconds: 500),
        scrollAnimationCurve: Curves.bounceOut,
      );

      expect(config.autoScrollBehavior, equals(AutoScrollBehavior.always));
      expect(config.scrollToFirstResponseMessage, isTrue);
      expect(
        config.scrollAnimationDuration,
        equals(const Duration(milliseconds: 500)),
      );
      expect(config.scrollAnimationCurve, equals(Curves.bounceOut));
    });
  });

  group('ChatMessagesController with ScrollBehaviorConfig', () {
    late ChatMessagesController controller;

    setUp(() {
      controller = ChatMessagesController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('default config is applied', () {
      expect(
        controller.scrollBehaviorConfig.autoScrollBehavior,
        equals(AutoScrollBehavior.onNewMessage),
      );
      expect(
        controller.scrollBehaviorConfig.scrollToFirstResponseMessage,
        isFalse,
      );
    });

    test('can update scroll behavior config', () {
      const newConfig = ScrollBehaviorConfig(
        autoScrollBehavior: AutoScrollBehavior.always,
        scrollToFirstResponseMessage: true,
      );

      controller.scrollBehaviorConfig = newConfig;

      expect(
        controller.scrollBehaviorConfig.autoScrollBehavior,
        equals(AutoScrollBehavior.always),
      );
      expect(
        controller.scrollBehaviorConfig.scrollToFirstResponseMessage,
        isTrue,
      );
    });

    test('initializes with custom scroll behavior', () {
      const customConfig = ScrollBehaviorConfig(
        autoScrollBehavior: AutoScrollBehavior.never,
        scrollToFirstResponseMessage: true,
      );

      final customController = ChatMessagesController(
        scrollBehaviorConfig: customConfig,
      );

      expect(
        customController.scrollBehaviorConfig.autoScrollBehavior,
        equals(AutoScrollBehavior.never),
      );
      expect(
        customController.scrollBehaviorConfig.scrollToFirstResponseMessage,
        isTrue,
      );

      customController.dispose();
    });
  });

  group('AutoScrollBehavior', () {
    test('has correct enum values', () {
      expect(AutoScrollBehavior.values.length, equals(4));
      expect(
        AutoScrollBehavior.values,
        containsAll([
          AutoScrollBehavior.always,
          AutoScrollBehavior.onNewMessage,
          AutoScrollBehavior.onUserMessageOnly,
          AutoScrollBehavior.never,
        ]),
      );
    });
  });

  testWidgets('ChatMessagesController applies scroll behavior configs', (
    WidgetTester tester,
  ) async {
    // Create a controller and a scroll controller
    final controller = ChatMessagesController();
    final scrollController = ScrollController();
    controller.setScrollController(scrollController);

    // Set up a simple widget with a ListView
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 400,
            child: ListView.builder(
              controller: scrollController,
              itemCount: 50,
              itemBuilder: (context, index) => const SizedBox(height: 50),
            ),
          ),
        ),
      ),
    );

    // Create user objects
    const userA = ChatUser(id: 'user', name: 'Test User');
    const aiUser = ChatUser(id: 'ai', name: 'AI Assistant');

    // Test with never scrolling config
    controller.scrollBehaviorConfig = const ScrollBehaviorConfig(
      autoScrollBehavior: AutoScrollBehavior.never,
    );

    // Verify the config was applied correctly
    expect(
      controller.scrollBehaviorConfig.autoScrollBehavior,
      equals(AutoScrollBehavior.never),
    );

    // Now change to always scroll config
    controller.scrollBehaviorConfig = const ScrollBehaviorConfig(
      autoScrollBehavior: AutoScrollBehavior.always,
    );

    // Verify the config was updated
    expect(
      controller.scrollBehaviorConfig.autoScrollBehavior,
      equals(AutoScrollBehavior.always),
    );

    // Clean up
    controller.dispose();
    scrollController.dispose();
  });
}
