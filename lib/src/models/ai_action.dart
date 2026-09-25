import 'package:flutter/widgets.dart';

/// Status of an action execution
enum ActionStatus {
  /// Action is idle/not running
  idle,

  /// Action is currently executing
  executing,

  /// Action completed successfully
  completed,

  /// Action failed during execution
  failed,

  /// Action is waiting for user confirmation
  waitingForConfirmation,

  /// Action was cancelled by user
  cancelled,
}

/// Types of parameters that can be passed to actions
enum ActionParameterType {
  /// String parameter
  string,

  /// Integer number parameter
  number,

  /// Boolean parameter
  boolean,

  /// Object parameter (Map&lt;String, dynamic&gt;)
  object,

  /// Array parameter (List&lt;dynamic&gt;)
  array,

  /// Array of objects parameter (List&lt;Map&lt;String, dynamic&gt;&gt;) - CopilotKit compatibility
  objectArray,
}

/// Definition of an action parameter
class ActionParameter {
  /// Name of the parameter
  final String name;

  /// Type of the parameter
  final ActionParameterType type;

  /// Human-readable description of the parameter
  final String description;

  /// Whether this parameter is required
  final bool required;

  /// Default value for the parameter (optional)
  final dynamic defaultValue;

  /// Validation function for the parameter value (returns error message or null)
  final String? Function(dynamic value)? validator;

  /// Enum values for string parameters (optional)
  final List<String>? enumValues;

  /// For array parameters: the expected item type (optional)
  final ActionParameterType? itemType;

  /// For object and object[] parameters: nested parameter attributes (CopilotKit compatibility)
  final List<ActionParameter>? attributes;

  const ActionParameter({
    required this.name,
    required this.type,
    required this.description,
    this.required = false,
    this.defaultValue,
    this.validator,
    this.enumValues,
    this.itemType,
    this.attributes,
  });

  /// Creates a string parameter
  static ActionParameter string({
    required String name,
    required String description,
    bool required = false,
    String? defaultValue,
    String? Function(dynamic value)? validator,
    List<String>? enumValues,
  }) =>
      ActionParameter(
        name: name,
        type: ActionParameterType.string,
        description: description,
        required: required,
        defaultValue: defaultValue,
        validator: validator,
        enumValues: enumValues,
      );

  /// Creates a number parameter
  static ActionParameter number({
    required String name,
    required String description,
    bool required = false,
    num? defaultValue,
    String? Function(dynamic value)? validator,
  }) =>
      ActionParameter(
        name: name,
        type: ActionParameterType.number,
        description: description,
        required: required,
        defaultValue: defaultValue,
        validator: validator,
      );

  /// Creates a boolean parameter
  static ActionParameter boolean({
    required String name,
    required String description,
    bool required = false,
    bool? defaultValue,
    String? Function(dynamic value)? validator,
  }) =>
      ActionParameter(
        name: name,
        type: ActionParameterType.boolean,
        description: description,
        required: required,
        defaultValue: defaultValue,
        validator: validator,
      );

  /// Creates an object parameter
  static ActionParameter object({
    required String name,
    required String description,
    bool required = false,
    Map<String, dynamic>? defaultValue,
    String? Function(dynamic value)? validator,
  }) =>
      ActionParameter(
        name: name,
        type: ActionParameterType.object,
        description: description,
        required: required,
        defaultValue: defaultValue,
        validator: validator,
      );

  /// Creates an array parameter
  static ActionParameter array({
    required String name,
    required String description,
    bool required = false,
    List<dynamic>? defaultValue,
    String? Function(dynamic value)? validator,
    ActionParameterType? itemType,
  }) =>
      ActionParameter(
        name: name,
        type: ActionParameterType.array,
        description: description,
        required: required,
        defaultValue: defaultValue,
        validator: validator,
        itemType: itemType,
      );

  /// Creates an object array parameter with nested attributes (CopilotKit compatibility)
  static ActionParameter objectArray({
    required String name,
    required String description,
    required List<ActionParameter> attributes,
    bool required = false,
    List<Map<String, dynamic>>? defaultValue,
    String? Function(dynamic value)? validator,
  }) =>
      ActionParameter(
        name: name,
        type: ActionParameterType.objectArray,
        description: description,
        attributes: attributes,
        required: required,
        defaultValue: defaultValue,
        validator: validator,
      );

  /// Creates an object parameter with nested attributes
  static ActionParameter objectWithAttributes({
    required String name,
    required String description,
    required List<ActionParameter> attributes,
    bool required = false,
    Map<String, dynamic>? defaultValue,
    String? Function(dynamic value)? validator,
  }) =>
      ActionParameter(
        name: name,
        type: ActionParameterType.object,
        description: description,
        attributes: attributes,
        required: required,
        defaultValue: defaultValue,
        validator: validator,
      );

  /// Validates a value against this parameter definition.
  /// Returns null when valid, or an error message when invalid.
  String? validate(dynamic value) {
    // Check required constraint
    if (required && (value == null || value == '')) {
      return '$name is required';
    }

    // If value is null and not required, it's valid
    if (value == null && !required) {
      return null;
    }

    // Type validation
    switch (type) {
      case ActionParameterType.string:
        if (value is! String) return '$name must be a string';
        if (enumValues != null && !enumValues!.contains(value)) {
          return '$name must be one of: ${enumValues!.join(', ')}';
        }
        break;
      case ActionParameterType.number:
        if (value is! num) return '$name must be a number';
        break;
      case ActionParameterType.boolean:
        if (value is! bool) return '$name must be a boolean';
        break;
      case ActionParameterType.object:
        if (value is! Map<String, dynamic>) return '$name must be an object';
        break;
      case ActionParameterType.array:
        if (value is! List) return '$name must be an array';
        if (itemType != null) {
          var badType = false;
          switch (itemType!) {
            case ActionParameterType.string:
              badType = value.any((e) => e is! String);
              break;
            case ActionParameterType.number:
              badType = value.any((e) => e is! num);
              break;
            case ActionParameterType.boolean:
              badType = value.any((e) => e is! bool);
              break;
            case ActionParameterType.object:
              badType = value.any((e) => e is! Map<String, dynamic>);
              break;
            case ActionParameterType.array:
              badType = value.any((e) => e is! List);
              break;
            case ActionParameterType.objectArray:
              badType = value.any((e) => e is! List);
              break;
          }
          if (badType) {
            final itemTypeName = itemType!.toString().split('.').last;
            return 'All items in $name must be $itemTypeName';
          }
        }
        break;
      case ActionParameterType.objectArray:
        if (value is! List) return '$name must be an array of objects';
        if (value.any((e) => e is! Map<String, dynamic>)) {
          return '$name must contain only objects';
        }
        break;
    }

    // Custom validation
    if (validator != null) {
      return validator!(value);
    }

    return null;
  }

  /// Backward-compatible boolean validator
  bool isValid(dynamic value) => validate(value) == null;

  /// Converts to JSON representation
  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type.toString().split('.').last,
        'description': description,
        'required': required,
        if (defaultValue != null) 'defaultValue': defaultValue,
        if (enumValues != null) 'enumValues': enumValues,
        if (itemType != null) 'itemType': itemType.toString().split('.').last,
      };

  /// Converts to JSON schema representation used for function calling
  Map<String, dynamic> toJsonSchema() {
    final schema = <String, dynamic>{'description': description};

    String typeString(ActionParameterType t) {
      switch (t) {
        case ActionParameterType.string:
          return 'string';
        case ActionParameterType.number:
          return 'number';
        case ActionParameterType.boolean:
          return 'boolean';
        case ActionParameterType.object:
          return 'object';
        case ActionParameterType.array:
          return 'array';
        case ActionParameterType.objectArray:
          return 'array'; // JSON Schema represents object arrays as arrays
      }
    }

    schema['type'] = typeString(type);

    if (type == ActionParameterType.string && enumValues != null) {
      schema['enum'] = enumValues;
    }

    if (type == ActionParameterType.array) {
      final inner = itemType ?? ActionParameterType.string;
      schema['items'] = {'type': typeString(inner)};
    }

    // Handle object arrays with attributes (CopilotKit compatibility)
    if (type == ActionParameterType.objectArray && attributes != null) {
      final properties = <String, dynamic>{};
      final required = <String>[];

      for (final attr in attributes!) {
        properties[attr.name] = attr.toJsonSchema();
        if (attr.required) {
          required.add(attr.name);
        }
      }

      schema['items'] = {
        'type': 'object',
        'properties': properties,
        if (required.isNotEmpty) 'required': required,
      };
    }

    // Handle object parameters with attributes
    if (type == ActionParameterType.object && attributes != null) {
      final properties = <String, dynamic>{};
      final required = <String>[];

      for (final attr in attributes!) {
        properties[attr.name] = attr.toJsonSchema();
        if (attr.required) {
          required.add(attr.name);
        }
      }

      schema['properties'] = properties;
      if (required.isNotEmpty) {
        schema['required'] = required;
      }
    }

    return schema;
  }
}

/// Result of an action execution
class ActionResult {
  /// Whether the action was successful
  final bool success;

  /// Result data (optional)
  final dynamic data;

  /// Error message if action failed
  final String? error;

  /// Additional metadata
  final Map<String, dynamic>? metadata;

  const ActionResult({
    required this.success,
    this.data,
    this.error,
    this.metadata,
  });

  /// Creates a successful result
  static ActionResult createSuccess([
    dynamic data,
    Map<String, dynamic>? metadata,
  ]) =>
      ActionResult(success: true, data: data, metadata: metadata);

  /// Creates a failed result
  static ActionResult createFailure(
    String error, [
    Map<String, dynamic>? metadata,
  ]) =>
      ActionResult(success: false, error: error, metadata: metadata);

  /// Converts to JSON representation
  Map<String, dynamic> toJson() => {
        'success': success,
        if (data != null) 'data': data,
        if (error != null) 'error': error,
        if (metadata != null) 'metadata': metadata,
      };
}

/// Configuration for human-in-the-loop confirmations
class ActionConfirmationConfig {
  /// Title for the confirmation dialog
  final String? title;

  /// Message to show in the confirmation dialog
  final String? message;

  /// Custom confirmation widget builder
  final Widget Function(BuildContext context, Map<String, dynamic> parameters)?
      builder;

  /// Text for confirm button
  final String confirmText;

  /// Text for cancel button
  final String cancelText;

  /// Whether confirmation is required for this action
  final bool required;

  const ActionConfirmationConfig({
    this.title = 'Confirm Action',
    this.message,
    this.builder,
    this.confirmText = 'Confirm',
    this.cancelText = 'Cancel',
    this.required = false,
  });
}

/// An AiAction defines an AI-callable function with parameters, execution logic, and UI rendering
class AiAction {
  /// Unique name/identifier for this action
  final String name;

  /// Human-readable description of what this action does
  final String description;

  /// List of parameters this action accepts
  final List<ActionParameter> parameters;

  /// The function to execute when this action is called
  final Future<ActionResult> Function(Map<String, dynamic> parameters) handler;

  /// Optional widget to render during action execution or to show results
  final Widget Function(
    BuildContext context,
    ActionStatus status,
    Map<String, dynamic> parameters, {
    ActionResult? result,
    String? error,
  })? render;

  /// Configuration for human-in-the-loop confirmations
  final ActionConfirmationConfig? confirmationConfig;

  /// Whether this action can run in the background
  final bool canRunInBackground;

  /// Maximum execution time in milliseconds
  final int? timeoutMs;

  /// Metadata for this action
  final Map<String, dynamic>? metadata;

  const AiAction({
    required this.name,
    required this.description,
    required this.parameters,
    required this.handler,
    this.render,
    this.confirmationConfig,
    this.canRunInBackground = false,
    this.timeoutMs,
    this.metadata,
  });

  /// Validates parameters against this action's parameter definitions
  Map<String, String> validateParameters(Map<String, dynamic> params) {
    final errors = <String, String>{};

    for (final param in parameters) {
      final value = params[param.name];
      final error = param.validate(value);
      if (error != null) {
        errors[param.name] = error;
      }
    }

    return errors;
  }

  /// Fills in default values for missing parameters
  Map<String, dynamic> fillDefaults(Map<String, dynamic> params) {
    final result = Map<String, dynamic>.from(params);

    for (final param in parameters) {
      if (!result.containsKey(param.name) && param.defaultValue != null) {
        result[param.name] = param.defaultValue;
      }
    }

    return result;
  }

  /// Converts action definition to JSON (useful for AI function calling)
  Map<String, dynamic> toJson() => toFunctionCallingSchema();

  /// Function calling schema for AI services (OpenAI, Anthropic, etc.)
  Map<String, dynamic> toFunctionCallingSchema() => {
        'name': name,
        'description': description,
        'parameters': {
          'type': 'object',
          'properties': {
            for (final param in parameters) param.name: param.toJsonSchema(),
          },
          'required':
              parameters.where((p) => p.required).map((p) => p.name).toList(),
        },
        if (metadata != null) 'metadata': metadata,
      };
}
