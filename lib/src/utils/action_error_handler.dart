import 'package:flutter/foundation.dart';

import '../models/ai_action.dart';

/// Centralized error handling for AI Actions
class ActionErrorHandler {
  /// Handles errors during action execution and returns user-friendly messages
  static ActionResult handleActionError(
    String actionName,
    dynamic error,
    StackTrace? stackTrace,
  ) {
    String userMessage;
    String? errorCode;
    Map<String, dynamic>? errorMetadata;

    if (error is ActionException) {
      userMessage = error.message;
      errorCode = error.code;
      errorMetadata = error.metadata;
    } else if (error is ArgumentError) {
      userMessage = 'Invalid parameters provided to action';
      errorCode = 'INVALID_PARAMETERS';
      errorMetadata = {'originalError': error.toString()};
    } else if (error is TimeoutException) {
      userMessage = 'Action timed out. Please try again.';
      errorCode = 'TIMEOUT';
    } else if (error is NetworkException) {
      userMessage =
          'Network error occurred. Check your connection and try again.';
      errorCode = 'NETWORK_ERROR';
    } else {
      userMessage = 'An unexpected error occurred while executing the action';
      errorCode = 'UNKNOWN_ERROR';
      errorMetadata = {'originalError': error.toString()};
    }

    // Log the error for debugging
    debugPrint('Action Error [$actionName]: $error');
    if (stackTrace != null && kDebugMode) {
      debugPrint('Stack trace: $stackTrace');
    }

    return ActionResult.createFailure(userMessage, {
      'errorCode': errorCode,
      'actionName': actionName,
      'timestamp': DateTime.now().toIso8601String(),
      ...?errorMetadata,
    });
  }

  /// Validates action parameters and returns validation errors
  static Map<String, String> validateActionParameters(
    List<ActionParameter> parameters,
    Map<String, dynamic> providedParams,
  ) {
    final errors = <String, String>{};

    for (final param in parameters) {
      final value = providedParams[param.name];
      final error = param.validate(value);
      if (error != null) {
        errors[param.name] = error;
      }
    }

    return errors;
  }

  /// Creates a structured validation failure result
  static ActionResult createValidationFailure(Map<String, String> errors) {
    final errorMessages = errors.entries
        .map((entry) => '${entry.key}: ${entry.value}')
        .join(', ');

    return ActionResult.createFailure(
      'Parameter validation failed: $errorMessages',
      {
        'errorCode': 'VALIDATION_FAILED',
        'validationErrors': errors,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }
}

/// Custom exception for action-specific errors
class ActionException implements Exception {
  final String message;
  final String? code;
  final Map<String, dynamic>? metadata;

  const ActionException(this.message, {this.code, this.metadata});

  @override
  String toString() =>
      'ActionException: $message${code != null ? ' ($code)' : ''}';
}

/// Exception for network-related errors
class NetworkException extends ActionException {
  const NetworkException(super.message) : super(code: 'NETWORK_ERROR');
}

/// Exception for timeout errors
class TimeoutException extends ActionException {
  final Duration timeout;

  const TimeoutException(super.message, this.timeout) : super(code: 'TIMEOUT');
}

/// Exception for parameter validation errors
class ValidationException extends ActionException {
  final Map<String, String> validationErrors;

  const ValidationException(super.message, this.validationErrors)
      : super(code: 'VALIDATION_ERROR', metadata: validationErrors);
}
