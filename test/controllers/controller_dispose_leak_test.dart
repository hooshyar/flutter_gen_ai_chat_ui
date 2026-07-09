// Regression tests for the lifecycle-leak audit:
//   * AiContextController.watchNotifier used to add a listener to the watched
//     ValueNotifier that was never removed, pinning the controller alive and
//     firing notifyListeners() after dispose.
//   * ContextAwareChatController constructed ChatMessages/Readable/Action
//     sub-controllers when none were supplied but never disposed them, while it
//     must NOT dispose controllers the consumer passed in.

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AiContextController.watchNotifier', () {
    test('removes its listener on dispose (no use-after-dispose)', () {
      final controller = AiContextController();
      final notifier = ValueNotifier<int>(0);
      addTearDown(notifier.dispose);

      controller.watchNotifier<int>(
        contextId: 'count',
        contextName: 'Count',
        notifier: notifier,
      );

      controller.dispose();

      // Before the fix this fired updateContext -> setContext ->
      // notifyListeners() on a disposed ChangeNotifier and threw.
      expect(() => notifier.value = 1, returnsNormally);
    });

    test('returned disposer stops further updates', () {
      final controller = AiContextController();
      addTearDown(controller.dispose);
      final notifier = ValueNotifier<int>(0);
      addTearDown(notifier.dispose);

      final stop = controller.watchNotifier<int>(
        contextId: 'count',
        contextName: 'Count',
        notifier: notifier,
      );

      notifier.value = 1;
      expect(controller.contextData['count']?.data, 1);

      stop();
      notifier.value = 2;
      expect(controller.contextData['count']?.data, 1);
    });
  });

  group('ContextAwareChatController ownership', () {
    test('disposes internally-created sub-controllers', () {
      final controller = ContextAwareChatController();
      final internalAction = controller.actionController;

      controller.dispose();

      // A disposed ChangeNotifier throws on addListener in debug builds. Before
      // the fix the internal controller was never disposed and this returned
      // normally.
      expect(() => internalAction.addListener(() {}), throwsFlutterError);
    });

    test('does not dispose consumer-owned sub-controllers', () {
      final action = ActionController();
      addTearDown(action.dispose);

      final controller = ContextAwareChatController(actionController: action);
      controller.dispose();

      // Consumer still owns `action`; it must remain usable.
      expect(() => action.addListener(() {}), returnsNormally);
    });
  });
}
