import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';

void main() {
  group('AiAction Tests', () {
    group('Action Creation', () {
      test('should create action with required fields', () {
        final action = AiAction(
          name: 'test_action',
          description: 'Test action',
          parameters: [],
          handler: (params) async => ActionResult.createSuccess({}),
        );

        expect(action.name, equals('test_action'));
        expect(action.description, equals('Test action'));
        expect(action.parameters, isEmpty);
        expect(action.handler, isNotNull);
      });

      test('should create action with optional render function', () {
        Widget renderFunction(
          BuildContext context,
          ActionStatus status,
          Map<String, dynamic> params, {
          ActionResult? result,
          String? error,
        }) {
          return const Text('Rendered');
        }

        final action = AiAction(
          name: 'test_action',
          description: 'Test action',
          parameters: [],
          handler: (params) async => ActionResult.createSuccess({}),
          render: renderFunction,
        );

        expect(action.render, equals(renderFunction));
      });

      test('should create action with confirmation config', () {
        final confirmationConfig = ActionConfirmationConfig(
          title: 'Confirm',
          message: 'Are you sure?',
          required: true,
        );

        final action = AiAction(
          name: 'test_action',
          description: 'Test action',
          parameters: [],
          handler: (params) async => ActionResult.createSuccess({}),
          confirmationConfig: confirmationConfig,
        );

        expect(action.confirmationConfig, equals(confirmationConfig));
      });
    });

    group('Function Calling Schema', () {
      test('should generate correct function calling schema', () {
        final action = AiAction(
          name: 'calculate',
          description: 'Perform calculation',
          parameters: [
            ActionParameter.number(
              name: 'a',
              description: 'First number',
              required: true,
            ),
            ActionParameter.string(
              name: 'operation',
              description: 'Operation to perform',
              required: true,
              enumValues: ['add', 'subtract'],
            ),
          ],
          handler: (params) async => ActionResult.createSuccess({}),
        );

        final schema = action.toFunctionCallingSchema();

        expect(schema['name'], equals('calculate'));
        expect(schema['description'], equals('Perform calculation'));
        expect(schema['parameters']['type'], equals('object'));

        final properties =
            schema['parameters']['properties'] as Map<String, dynamic>;
        expect(properties.containsKey('a'), isTrue);
        expect(properties.containsKey('operation'), isTrue);

        final aParam = properties['a'] as Map<String, dynamic>;
        expect(aParam['type'], equals('number'));
        expect(aParam['description'], equals('First number'));

        final operationParam = properties['operation'] as Map<String, dynamic>;
        expect(operationParam['type'], equals('string'));
        expect(operationParam['enum'], equals(['add', 'subtract']));

        final required = schema['parameters']['required'] as List;
        expect(required, contains('a'));
        expect(required, contains('operation'));
      });
    });
  });

  group('ActionParameter Tests', () {
    group('String Parameters', () {
      test('should create string parameter', () {
        final param = ActionParameter.string(
          name: 'text',
          description: 'Text input',
          required: true,
        );

        expect(param.name, equals('text'));
        expect(param.type, equals(ActionParameterType.string));
        expect(param.description, equals('Text input'));
        expect(param.required, isTrue);
      });

      test('should create string parameter with enum values', () {
        final param = ActionParameter.string(
          name: 'choice',
          description: 'Choose option',
          enumValues: ['option1', 'option2'],
        );

        expect(param.enumValues, equals(['option1', 'option2']));
      });

      test('should validate string parameter', () {
        final param = ActionParameter.string(
          name: 'text',
          description: 'Text input',
          required: true,
        );

        expect(param.validate('hello'), isNull);
        expect(param.validate(null), equals('text is required'));
        expect(param.validate(123), equals('text must be a string'));
      });

      test('should validate string enum parameter', () {
        final param = ActionParameter.string(
          name: 'choice',
          description: 'Choose option',
          enumValues: ['option1', 'option2'],
        );

        expect(param.validate('option1'), isNull);
        expect(
          param.validate('invalid'),
          equals('choice must be one of: option1, option2'),
        );
      });
    });

    group('Number Parameters', () {
      test('should create number parameter', () {
        final param = ActionParameter.number(
          name: 'count',
          description: 'Number input',
          required: true,
        );

        expect(param.name, equals('count'));
        expect(param.type, equals(ActionParameterType.number));
        expect(param.description, equals('Number input'));
        expect(param.required, isTrue);
      });

      test('should validate number parameter', () {
        final param = ActionParameter.number(
          name: 'count',
          description: 'Number input',
          required: true,
        );

        expect(param.validate(42), isNull);
        expect(param.validate(3.14), isNull);
        expect(param.validate(null), equals('count is required'));
        expect(
          param.validate('not a number'),
          equals('count must be a number'),
        );
      });
    });

    group('Boolean Parameters', () {
      test('should create boolean parameter', () {
        final param = ActionParameter.boolean(
          name: 'enabled',
          description: 'Enable feature',
        );

        expect(param.name, equals('enabled'));
        expect(param.type, equals(ActionParameterType.boolean));
        expect(param.description, equals('Enable feature'));
      });

      test('should validate boolean parameter', () {
        final param = ActionParameter.boolean(
          name: 'enabled',
          description: 'Enable feature',
          required: true,
        );

        expect(param.validate(true), isNull);
        expect(param.validate(false), isNull);
        expect(param.validate(null), equals('enabled is required'));
        expect(
          param.validate('not a boolean'),
          equals('enabled must be a boolean'),
        );
      });
    });

    group('Array Parameters', () {
      test('should create array parameter', () {
        final param = ActionParameter.array(
          name: 'items',
          description: 'List of items',
          itemType: ActionParameterType.string,
        );

        expect(param.name, equals('items'));
        expect(param.type, equals(ActionParameterType.array));
        expect(param.itemType, equals(ActionParameterType.string));
      });

      test('should validate array parameter', () {
        final param = ActionParameter.array(
          name: 'items',
          description: 'List of items',
          itemType: ActionParameterType.string,
          required: true,
        );

        expect(param.validate(['item1', 'item2']), isNull);
        expect(param.validate(null), equals('items is required'));
        expect(
          param.validate('not an array'),
          equals('items must be an array'),
        );
        expect(
          param.validate([1, 2]),
          equals('All items in items must be string'),
        );
      });
    });

    group('Custom Validation', () {
      test('should use custom validator', () {
        final param = ActionParameter.string(
          name: 'email',
          description: 'Email address',
          validator: (value) {
            if (value == null) return null;
            if (value is! String) return 'Must be string';
            if (!value.contains('@')) return 'Invalid email format';
            return null;
          },
        );

        expect(param.validate('test@example.com'), isNull);
        expect(param.validate('invalid-email'), equals('Invalid email format'));
      });
    });

    group('Schema Generation', () {
      test('should generate correct JSON schema for string', () {
        final param = ActionParameter.string(
          name: 'text',
          description: 'Text input',
          required: true,
          enumValues: ['a', 'b'],
        );

        final schema = param.toJsonSchema();

        expect(schema['type'], equals('string'));
        expect(schema['description'], equals('Text input'));
        expect(schema['enum'], equals(['a', 'b']));
      });

      test('should generate correct JSON schema for number', () {
        final param = ActionParameter.number(
          name: 'count',
          description: 'Number input',
        );

        final schema = param.toJsonSchema();

        expect(schema['type'], equals('number'));
        expect(schema['description'], equals('Number input'));
      });

      test('should generate correct JSON schema for array', () {
        final param = ActionParameter.array(
          name: 'items',
          description: 'List of items',
          itemType: ActionParameterType.string,
        );

        final schema = param.toJsonSchema();

        expect(schema['type'], equals('array'));
        expect(schema['description'], equals('List of items'));
        expect(schema['items']['type'], equals('string'));
      });
    });
  });

  group('ActionResult Tests', () {
    test('should create success result', () {
      final result = ActionResult.createSuccess({'key': 'value'});

      expect(result.success, isTrue);
      expect(result.data, equals({'key': 'value'}));
      expect(result.error, isNull);
    });

    test('should create failure result', () {
      final result = ActionResult.createFailure('Something went wrong');

      expect(result.success, isFalse);
      expect(result.data, isNull);
      expect(result.error, equals('Something went wrong'));
    });
  });

  group('ActionConfirmationConfig Tests', () {
    test('should create confirmation config with defaults', () {
      const config = ActionConfirmationConfig();

      expect(config.title, equals('Confirm Action'));
      expect(config.message, isNull);
      expect(config.confirmText, equals('Confirm'));
      expect(config.cancelText, equals('Cancel'));
      expect(config.required, isFalse);
      expect(config.builder, isNull);
    });

    test('should create confirmation config with custom values', () {
      const config = ActionConfirmationConfig(
        title: 'Custom Title',
        message: 'Custom message',
        confirmText: 'Yes',
        cancelText: 'No',
        required: true,
      );

      expect(config.title, equals('Custom Title'));
      expect(config.message, equals('Custom message'));
      expect(config.confirmText, equals('Yes'));
      expect(config.cancelText, equals('No'));
      expect(config.required, isTrue);
    });
  });
}
