import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';

import '../models/ai_action.dart';
import '../models/ai_context.dart';
import '../utils/action_error_handler.dart';
import 'ai_context_controller.dart';

/// Event types for action execution
enum ActionEventType {
  /// Action started executing
  started,

  /// Backward-compat alias
  executionStarted,

  /// Action completed successfully
  completed,

  /// Backward-compat alias
  executionCompleted,

  /// Action failed
  failed,

  /// Backward-compat alias
  executionFailed,

  /// Action was cancelled
  cancelled,

  /// Action is waiting for confirmation
  waitingForConfirmation,

  /// Action confirmation was provided
  confirmationProvided,
}

/// Event data for action execution events
class ActionEvent {
  /// Type of the event
  final ActionEventType type;

  /// Action name
  final String actionName;

  /// Parameters passed to the action
  final Map<String, dynamic> parameters;

  /// Result of action execution (if completed)
  final ActionResult? result;

  /// Error message (if failed)
  final String? error;

  /// Timestamp of the event
  final DateTime timestamp;

  /// Additional metadata
  final Map<String, dynamic>? metadata;

  ActionEvent({
    required this.type,
    required this.actionName,
    required this.parameters,
    this.result,
    this.error,
    DateTime? timestamp,
    this.metadata,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// State of a running action
class ActionExecution {
  /// Unique ID for this execution
  final String id;

  /// The action being executed
  final AiAction action;

  /// Parameters for this execution
  final Map<String, dynamic> parameters;

  /// Current status
  ActionStatus status;

  /// Start time
  final DateTime startTime;

  /// End time (if completed)
  DateTime? endTime;

  /// Result (if completed)
  ActionResult? result;

  /// Error message (if failed)
  String? error;

  /// Completer for waiting on confirmation
  Completer<bool>? confirmationCompleter;

  /// Completer for the overall execution
  final Completer<ActionResult> completer;

  ActionExecution({
    required this.id,
    required this.action,
    required this.parameters,
    this.status = ActionStatus.idle,
    DateTime? startTime,
  })  : startTime = startTime ?? DateTime.now(),
        completer = Completer<ActionResult>();

  /// Duration of execution (if completed) or current duration
  Duration get duration => (endTime ?? DateTime.now()).difference(startTime);

  /// Whether this execution is still active
  bool get isActive => !completer.isCompleted;
}

/// Controller for managing AiAction executions with context awareness
class ActionController extends ChangeNotifier {
  final Map<String, AiAction> _actions = {};
  final Map<String, ActionExecution> _executions = {};
  final StreamController<ActionEvent> _eventController =
      StreamController<ActionEvent>.broadcast();

  /// Optional context controller for context-aware actions
  AiContextController? _contextController;

  /// Stream of action execution events
  Stream<ActionEvent> get events => _eventController.stream;

  /// Currently registered actions
  Map<String, AiAction> get actions => Map.unmodifiable(_actions);

  /// Currently running executions
  Map<String, ActionExecution> get executions => Map.unmodifiable(_executions);

  /// Context controller for accessing application context
  AiContextController? get contextController => _contextController;

  /// Set the context controller for context-aware actions
  set contextController(AiContextController? controller) {
    _contextController = controller;

    if (controller != null) {
      dev.log('ActionController: Context controller attached');
    }
  }

  /// Callback for showing confirmation dialogs
  Future<bool> Function(BuildContext context, AiAction action,
      Map<String, dynamic> parameters)? onConfirmationRequired;

  /// Register a new action
  void registerAction(AiAction action) {
    if (_actions.containsKey(action.name)) {
      dev.log(
          'Warning: Action "${action.name}" already exists and will be overwritten');
    }

    _actions[action.name] = action;
    dev.log('Registered action: ${action.name}');
    notifyListeners();
  }

  /// Unregister an action
  void unregisterAction(String name) {
    if (_actions.remove(name) != null) {
      dev.log('Unregistered action: $name');
      notifyListeners();
    }
  }

  /// Execute an action by name with parameters
  Future<ActionResult> executeAction(
    String actionName,
    Map<String, dynamic> parameters, {
    BuildContext? context,
  }) async {
    final action = _actions[actionName];
    if (action == null) {
      final error = 'Action "$actionName" not found';
      dev.log('Error: $error');
      return ActionResult.createFailure(error);
    }

    return _executeAction(action, parameters, context: context);
  }

  /// Execute a AiAction directly
  Future<ActionResult> _executeAction(
    AiAction action,
    Map<String, dynamic> parameters, {
    BuildContext? context,
  }) async {
    // Generate unique execution ID
    final executionId =
        '${action.name}_${DateTime.now().millisecondsSinceEpoch}';

    // Validate parameters using centralized error handler
    final validationErrors = ActionErrorHandler.validateActionParameters(
      action.parameters,
      parameters,
    );
    if (validationErrors.isNotEmpty) {
      return ActionErrorHandler.createValidationFailure(validationErrors);
    }

    // Fill in default values
    final finalParams = action.fillDefaults(parameters);

    // Create execution tracking
    final execution = ActionExecution(
      id: executionId,
      action: action,
      parameters: finalParams,
    );

    _executions[executionId] = execution;
    notifyListeners();

    try {
      // Check if confirmation is required
      if (action.confirmationConfig?.required == true) {
        if (context == null || onConfirmationRequired == null) {
          final error =
              'Action requires confirmation but no context or confirmation handler provided';
          return _completeExecution(
              execution, ActionResult.createFailure(error));
        }

        execution.status = ActionStatus.waitingForConfirmation;
        _emitEvent(ActionEvent(
          type: ActionEventType.waitingForConfirmation,
          actionName: action.name,
          parameters: finalParams,
        ));
        notifyListeners();

        // Wait for confirmation
        final confirmed =
            await onConfirmationRequired!(context, action, finalParams);

        _emitEvent(ActionEvent(
          type: ActionEventType.confirmationProvided,
          actionName: action.name,
          parameters: finalParams,
          metadata: {'confirmed': confirmed},
        ));

        if (!confirmed) {
          return _completeExecution(
              execution,
              ActionResult.createFailure('Action cancelled by user'),
              ActionStatus.cancelled);
        }
      }

      // Start execution
      execution.status = ActionStatus.executing;
      _emitEvent(ActionEvent(
        type: ActionEventType.started,
        actionName: action.name,
        parameters: finalParams,
      ));
      // Emit backward-compat mirror event
      _emitEvent(ActionEvent(
        type: ActionEventType.executionStarted,
        actionName: action.name,
        parameters: finalParams,
      ));
      notifyListeners();

      // Execute with timeout if specified
      late ActionResult result;
      if (action.timeoutMs != null) {
        result = await action.handler(finalParams).timeout(
              Duration(milliseconds: action.timeoutMs!),
              onTimeout: () => ActionResult.createFailure(
                  'Action timed out after ${action.timeoutMs}ms'),
            );
      } else {
        result = await action.handler(finalParams);
      }

      // Complete execution
      final eventType =
          result.success ? ActionEventType.completed : ActionEventType.failed;
      final status =
          result.success ? ActionStatus.completed : ActionStatus.failed;

      _emitEvent(ActionEvent(
        type: eventType,
        actionName: action.name,
        parameters: finalParams,
        result: result.success ? result : null,
        error: result.success ? null : result.error,
      ));
      // Emit backward-compat mirror event
      _emitEvent(ActionEvent(
        type: result.success
            ? ActionEventType.executionCompleted
            : ActionEventType.executionFailed,
        actionName: action.name,
        parameters: finalParams,
        result: result.success ? result : null,
        error: result.success ? null : result.error,
      ));

      return _completeExecution(execution, result, status);
    } catch (e, stackTrace) {
      final result = ActionErrorHandler.handleActionError(
        action.name,
        e,
        stackTrace,
      );

      _emitEvent(ActionEvent(
        type: ActionEventType.failed,
        actionName: action.name,
        parameters: finalParams,
        error: result.error,
      ));

      return _completeExecution(execution, result, ActionStatus.failed);
    }
  }

  /// Complete an action execution
  ActionResult _completeExecution(
    ActionExecution execution,
    ActionResult result, [
    ActionStatus? status,
  ]) {
    execution
      ..result = result
      ..error = result.error
      ..status = status ??
          (result.success ? ActionStatus.completed : ActionStatus.failed)
      ..endTime = DateTime.now();

    if (!execution.completer.isCompleted) {
      execution.completer.complete(result);
    }

    // Remove from active executions after a short delay so consumers can read
    // the final status before it disappears. Tracked via [_cleanupTimers] so
    // [dispose] can cancel pending timers — otherwise widget tests that
    // dispose this controller within 2s of completion hit "Timer still
    // pending after dispose" (iter 3 audit).
    late Timer cleanupTimer;
    cleanupTimer = Timer(const Duration(seconds: 2), () {
      _cleanupTimers.remove(cleanupTimer);
      if (!mounted) return;
      _executions.remove(execution.id);
      notifyListeners();
    });
    _cleanupTimers.add(cleanupTimer);

    notifyListeners();
    return result;
  }

  /// Tracked post-completion cleanup timers (iter 3). Cancelled on [dispose].
  final Set<Timer> _cleanupTimers = {};

  /// Whether the controller is still mounted/active
  bool mounted = true;

  /// Cancel a running execution
  bool cancelExecution(String executionId) {
    final execution = _executions[executionId];
    if (execution == null || !execution.isActive) {
      return false;
    }

    final result = ActionResult.createFailure('Action cancelled by user');
    _emitEvent(ActionEvent(
      type: ActionEventType.cancelled,
      actionName: execution.action.name,
      parameters: execution.parameters,
    ));

    _completeExecution(execution, result, ActionStatus.cancelled);
    return true;
  }

  /// Get execution by ID
  ActionExecution? getExecution(String executionId) => _executions[executionId];

  /// Get all executions for a specific action
  List<ActionExecution> getExecutionsForAction(String actionName) {
    return _executions.values
        .where((execution) => execution.action.name == actionName)
        .toList();
  }

  /// Get currently running executions
  List<ActionExecution> getRunningExecutions() {
    return _executions.values.where((execution) => execution.isActive).toList();
  }

  /// Clear completed executions
  void clearCompletedExecutions() {
    _executions.removeWhere((key, execution) => !execution.isActive);
    notifyListeners();
  }

  /// Backward-compat API used by tests
  void clearActions() {
    _actions.clear();
    notifyListeners();
  }

  /// Get all registered actions
  List<AiAction> get registeredActions => _actions.values.toList();

  /// Emit an action event
  void _emitEvent(ActionEvent event) {
    if (!_eventController.isClosed) {
      _eventController.add(event);
    }
  }

  /// Get action definitions in OpenAI function calling format
  List<Map<String, dynamic>> getActionsForFunctionCalling() {
    return _actions.values.map((action) => action.toJson()).toList();
  }

  /// Get action definitions with current context for enhanced AI prompts
  Map<String, dynamic> getActionsWithContext({
    List<AiContextType>? contextTypes,
    List<AiContextPriority>? contextPriorities,
    List<String>? contextCategories,
  }) {
    final actions = getActionsForFunctionCalling();

    String? contextSummary;
    Map<String, dynamic>? contextData;

    if (_contextController != null) {
      contextSummary = _contextController!.getContextSummary(
        types: contextTypes,
        priorities: contextPriorities,
        categories: contextCategories,
        maxItems: 20,
      );

      contextData = _contextController!.getContextForPrompt(
        types: contextTypes,
        priorities: contextPriorities,
        categories: contextCategories,
      );
    }

    return {
      'actions': actions,
      'contextSummary': contextSummary ?? 'No context available',
      'contextData': contextData ?? {},
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Handle function calling response from AI with context awareness
  Future<ActionResult> handleFunctionCall(
    String functionName,
    Map<String, dynamic> arguments, {
    BuildContext? context,
    bool includeContext = true,
  }) async {
    dev.log('Handling function call: $functionName with arguments: $arguments');

    // Add current context to action execution if available
    if (includeContext && _contextController != null) {
      final contextSummary = _contextController!.getContextSummary(
        maxItems: 10,
        priorities: [AiContextPriority.critical, AiContextPriority.high],
      );

      // Log context for debugging
      dev.log('Context for action execution: $contextSummary');

      // Add context as metadata to action execution
      final executionId =
          '${functionName}_${DateTime.now().millisecondsSinceEpoch}';
      _contextController!.setContext(AiContextData.custom(
        id: 'action_execution_$executionId',
        name: 'Action Execution Context',
        data: {
          'actionName': functionName,
          'arguments': arguments,
          'executionId': executionId,
          'timestamp': DateTime.now().toIso8601String(),
        },
        description: 'Context for action execution: $functionName',
        categories: ['action', 'execution'],
        priority: AiContextPriority.normal,
        expiresAt: DateTime.now().add(const Duration(minutes: 5)),
      ));
    }

    return executeAction(functionName, arguments, context: context);
  }

  /// Get enhanced prompt with context for AI interactions
  String getEnhancedPrompt(
    String basePrompt, {
    List<AiContextType>? contextTypes,
    List<AiContextPriority>? contextPriorities,
    List<String>? contextCategories,
    bool includeActions = true,
  }) {
    final parts = <String>[basePrompt];

    // Add context information
    if (_contextController != null) {
      final contextSummary = _contextController!.getContextSummary(
        types: contextTypes,
        priorities: contextPriorities,
        categories: contextCategories,
        maxItems: 15,
      );

      if (contextSummary.isNotEmpty &&
          contextSummary != 'No relevant context available.') {
        parts.add('\n\n$contextSummary');
      }
    }

    // Add available actions
    if (includeActions && _actions.isNotEmpty) {
      final actionsList = _actions.values
          .map((action) => '- ${action.name}: ${action.description}')
          .join('\n');

      parts.add('\n\nAvailable Actions:\n$actionsList');
    }

    return parts.join('');
  }

  @override
  void dispose() {
    mounted = false;

    // Cancel pending post-completion cleanup timers (iter 3) so test
    // teardown is clean.
    for (final t in _cleanupTimers) {
      t.cancel();
    }
    _cleanupTimers.clear();

    _eventController.close();

    // Cancel all running executions
    for (final execution in _executions.values) {
      if (execution.isActive) {
        cancelExecution(execution.id);
      }
    }
    _executions.clear();

    super.dispose();
  }
}
