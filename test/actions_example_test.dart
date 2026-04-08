import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests for the AI Actions feature used in the actions example (Issue #35).
void main() {
  group('AI Actions Example Tests', () {
    late ActionController actionController;

    setUp(() {
      actionController = ActionController();

      actionController.registerAction(AiAction(
        name: 'calculate',
        description: 'Perform a math calculation',
        parameters: [
          ActionParameter.string(
            name: 'expression',
            description: 'Math expression',
            required: true,
          ),
        ],
        handler: (params) async {
          return ActionResult.createSuccess({
            'expression': params['expression'],
            'result': 42,
          });
        },
      ));

      actionController.registerAction(AiAction(
        name: 'get_weather',
        description: 'Get weather for a city',
        parameters: [
          ActionParameter.string(
            name: 'city',
            description: 'City name',
            required: true,
          ),
        ],
        handler: (params) async {
          return ActionResult.createSuccess({
            'city': params['city'],
            'temperature': 22,
            'conditions': 'Sunny',
          });
        },
      ));
    });

    tearDown(() {
      actionController.dispose();
    });

    test('should register actions', () {
      expect(actionController.actions.length, 2);
      expect(actionController.actions.containsKey('calculate'), isTrue);
      expect(actionController.actions.containsKey('get_weather'), isTrue);
    });

    test('calculate action should return success', () async {
      final result = await actionController.executeAction(
        'calculate',
        {'expression': '6 * 7'},
      );

      expect(result.success, isTrue);
      expect((result.data as Map)['result'], 42);
    });

    test('weather action should return success', () async {
      final result = await actionController.executeAction(
        'get_weather',
        {'city': 'Paris'},
      );

      expect(result.success, isTrue);
      expect((result.data as Map)['city'], 'Paris');
      expect((result.data as Map)['conditions'], 'Sunny');
    });

    test('unknown action should return failure', () async {
      final result = await actionController.executeAction(
        'unknown_action',
        {},
      );

      expect(result.success, isFalse);
    });

    test('action with missing required param should fail validation', () async {
      final result = await actionController.executeAction(
        'calculate',
        {},
      );

      expect(result.success, isFalse);
    });

    test('action events should be emitted', () async {
      final events = <ActionEvent>[];
      actionController.events.listen(events.add);

      await actionController.executeAction(
        'calculate',
        {'expression': '1 + 1'},
      );

      // Wait for events to be processed
      await Future.delayed(const Duration(milliseconds: 100));

      expect(events.any((e) => e.type == ActionEventType.started), isTrue);
      expect(events.any((e) => e.type == ActionEventType.completed), isTrue);
    });
  });
}
