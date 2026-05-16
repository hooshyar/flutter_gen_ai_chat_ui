import 'package:flutter/material.dart';

import '../controllers/action_controller.dart';
import '../controllers/ai_context_controller.dart';
import '../models/ai_action.dart';
import '../models/ai_context.dart';
import 'ai_context_provider.dart';

/// Configuration for an [AiActionProvider].
///
/// Bundles the [actions] that should be registered on the provider's
/// [ActionController], an optional custom [confirmationBuilder] for
/// human-in-the-loop confirmation dialogs, and a [debug] flag.
class AiActionConfig {
  /// List of actions to register on the underlying [ActionController]
  /// when the provider is mounted.
  final List<AiAction> actions;

  /// Custom confirmation dialog builder.
  ///
  /// When an action is invoked that requires confirmation (its
  /// `confirmationConfig` is non-null), this builder is called and is
  /// expected to return `true` to allow execution or `false` to cancel.
  /// When null, a default Material `AlertDialog` is shown.
  final Future<bool> Function(BuildContext context, AiAction action,
      Map<String, dynamic> parameters)? confirmationBuilder;

  /// Whether to emit verbose debug logging from the underlying controller.
  final bool debug;

  /// Creates an [AiActionConfig].
  ///
  /// All parameters are optional. Pass [actions] to pre-register actions on
  /// the provider's [ActionController].
  const AiActionConfig({
    this.actions = const [],
    this.confirmationBuilder,
    this.debug = false,
  });
}

/// Provides agent / tool-use functionality to the widget tree.
///
/// Wrap an `AiChatWidget` (or any subtree that needs to invoke
/// `AiAction`s) in an `AiActionProvider`. Descendants can then look up
/// the underlying [ActionController] via `AiActionProvider.of(context)`
/// or use the higher-level [AiActionHook].
///
/// The provider owns the [ActionController] by default. Pass an external
/// [controller] to manage its lifecycle yourself (useful for tests and
/// for sharing one controller across multiple subtrees).
///
/// Example:
/// ```dart
/// AiActionProvider(
///   config: AiActionConfig(
///     actions: [
///       AiAction(
///         name: 'add_to_cart',
///         description: 'Add a product to the user cart',
///         parameters: [
///           ActionParameter.string(name: 'sku', required: true),
///           ActionParameter.number(name: 'qty', defaultValue: 1),
///         ],
///         handler: (params) async {
///           await cart.add(
///             params['sku'] as String,
///             (params['qty'] as num).toInt(),
///           );
///           return ActionResult.createSuccess({'ok': true});
///         },
///       ),
///     ],
///   ),
///   child: AiChatWidget(/* ... */),
/// );
/// ```
class AiActionProvider extends StatefulWidget {
  /// Configuration for this provider: actions to register, optional
  /// confirmation builder, and debug flag.
  final AiActionConfig config;

  /// The subtree that should have access to the [ActionController] via
  /// `AiActionProvider.of(context)`.
  final Widget child;

  /// Optional externally-owned [ActionController].
  ///
  /// When non-null, the provider does not dispose it (the consumer keeps
  /// ownership). When null, the provider creates and disposes its own.
  final ActionController? controller;

  /// Creates an [AiActionProvider].
  ///
  /// [config] and [child] are required. Pass [controller] to share an
  /// externally-owned [ActionController] instead of letting the provider
  /// create its own.
  const AiActionProvider({
    super.key,
    required this.config,
    required this.child,
    this.controller,
  });

  @override
  State<AiActionProvider> createState() => _AiActionProviderState();

  /// Returns the nearest ancestor [ActionController] from the widget tree.
  ///
  /// Throws a [FlutterError] when no [AiActionProvider] ancestor is found.
  /// Use [maybeOf] when the absence of a provider is a valid case.
  static ActionController of(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<_AiActionInheritedWidget>();
    if (provider == null) {
      throw FlutterError(
        'AiActionProvider.of() called with a context that does not contain a AiActionProvider.\n'
        'No AiActionProvider ancestor could be found starting from the context that was passed to AiActionProvider.of().',
      );
    }
    return provider.controller;
  }

  /// Returns the nearest ancestor [ActionController], or `null` when no
  /// [AiActionProvider] is in the widget tree above [context].
  static ActionController? maybeOf(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<_AiActionInheritedWidget>();
    return provider?.controller;
  }
}

class _AiActionProviderState extends State<AiActionProvider> {
  late ActionController _controller;
  bool _isExternalController = false;

  @override
  void initState() {
    super.initState();

    // Use external controller or create new one
    if (widget.controller != null) {
      _controller = widget.controller!;
      _isExternalController = true;
    } else {
      _controller = ActionController();
      _isExternalController = false;
    }

    // Set up confirmation handler if provided
    if (widget.config.confirmationBuilder != null) {
      _controller.onConfirmationRequired = widget.config.confirmationBuilder;
    } else {
      _controller.onConfirmationRequired = _defaultConfirmationHandler;
    }

    // Register initial actions
    _registerActions();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Try to connect to context controller if available
    final contextController = AiContextProvider.maybeOf(context);
    if (contextController != null) {
      _controller.contextController = contextController;
    }
  }

  void _registerActions() {
    for (final action in widget.config.actions) {
      _controller.registerAction(action);
    }
  }

  @override
  void didUpdateWidget(AiActionProvider oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update confirmation handler
    if (widget.config.confirmationBuilder != null) {
      _controller.onConfirmationRequired = widget.config.confirmationBuilder;
    } else {
      _controller.onConfirmationRequired = _defaultConfirmationHandler;
    }

    // Handle action changes
    if (widget.config.actions != oldWidget.config.actions) {
      // Unregister old actions that are no longer present
      for (final oldAction in oldWidget.config.actions) {
        if (!widget.config.actions.any((a) => a.name == oldAction.name)) {
          _controller.unregisterAction(oldAction.name);
        }
      }

      // Register new actions
      for (final newAction in widget.config.actions) {
        if (!oldWidget.config.actions.any((a) => a.name == newAction.name)) {
          _controller.registerAction(newAction);
        }
      }
    }
  }

  /// Default confirmation dialog implementation
  Future<bool> _defaultConfirmationHandler(
    BuildContext context,
    AiAction action,
    Map<String, dynamic> parameters,
  ) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            final config = action.confirmationConfig!;

            // Use custom builder if provided
            if (config.builder != null) {
              return Dialog(
                child: config.builder!(context, parameters),
              );
            }

            // Default confirmation dialog
            return AlertDialog(
              title: Text(config.title ?? 'Confirm Action'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(config.message ??
                      'Do you want to execute "${action.name}"?'),
                  const SizedBox(height: 16),
                  if (parameters.isNotEmpty) ...[
                    const Text(
                      'Parameters:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        parameters.entries
                            .map((e) => '${e.key}: ${e.value}')
                            .join('\n'),
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(config.cancelText),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(config.confirmText),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  @override
  void dispose() {
    // Only dispose if we created the controller
    if (!_isExternalController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _AiActionInheritedWidget(
      controller: _controller,
      config: widget.config,
      child: widget.child,
    );
  }
}

/// Inherited widget that exposes the ActionController
class _AiActionInheritedWidget extends InheritedWidget {
  final ActionController controller;
  final AiActionConfig config;

  const _AiActionInheritedWidget({
    required this.controller,
    required this.config,
    required super.child,
  });

  @override
  bool updateShouldNotify(_AiActionInheritedWidget oldWidget) {
    return controller != oldWidget.controller || config != oldWidget.config;
  }
}

/// Hook-style accessor for the AI action system within a widget.
///
/// `AiActionHook` is a thin wrapper over [ActionController] that captures
/// the calling [BuildContext] so executions can show confirmation dialogs
/// and other context-dependent UI. Construct via [AiActionHook.of] inside
/// a `build` method, or use the [AiActionBuilder] convenience widget.
///
/// Example:
/// ```dart
/// AiActionBuilder(
///   builder: (context, hook) {
///     return ElevatedButton(
///       onPressed: () async {
///         final result = await hook.executeAction(
///           'add_to_cart',
///           {'sku': 'WIDGET-1', 'qty': 1},
///         );
///         debugPrint('action ok: ${result.success}');
///       },
///       child: const Text('Run action'),
///     );
///   },
/// );
/// ```
class AiActionHook {
  final BuildContext _context;
  final ActionController _controller;

  AiActionHook._(this._context, this._controller);

  /// Resolves the nearest [AiActionProvider] and binds its
  /// [ActionController] to [context]. Throws if no provider is found.
  factory AiActionHook.of(BuildContext context) {
    final controller = AiActionProvider.of(context);
    return AiActionHook._(context, controller);
  }

  /// Register a new action (similar to useAiAction)
  void registerAction(AiAction action) {
    _controller.registerAction(action);
  }

  /// Execute an action by name
  Future<ActionResult> executeAction(
    String actionName,
    Map<String, dynamic> parameters,
  ) {
    return _controller.executeAction(actionName, parameters, context: _context);
  }

  /// Get all registered actions
  Map<String, AiAction> get actions => _controller.actions;

  /// Get current executions
  Map<String, ActionExecution> get executions => _controller.executions;

  /// Stream of action events
  Stream<ActionEvent> get events => _controller.events;

  /// Get actions formatted for AI function calling
  List<Map<String, dynamic>> getActionsForFunctionCalling() {
    return _controller.getActionsForFunctionCalling();
  }

  /// Get actions with current context for enhanced AI prompts
  Map<String, dynamic> getActionsWithContext({
    List<AiContextType>? contextTypes,
    List<AiContextPriority>? contextPriorities,
    List<String>? contextCategories,
  }) {
    return _controller.getActionsWithContext(
      contextTypes: contextTypes,
      contextPriorities: contextPriorities,
      contextCategories: contextCategories,
    );
  }

  /// Handle function call from AI with context awareness
  Future<ActionResult> handleFunctionCall(
    String functionName,
    Map<String, dynamic> arguments, {
    bool includeContext = true,
  }) {
    return _controller.handleFunctionCall(
      functionName,
      arguments,
      context: _context,
      includeContext: includeContext,
    );
  }

  /// Get enhanced prompt with context for AI interactions
  String getEnhancedPrompt(
    String basePrompt, {
    List<AiContextType>? contextTypes,
    List<AiContextPriority>? contextPriorities,
    List<String>? contextCategories,
    bool includeActions = true,
  }) {
    return _controller.getEnhancedPrompt(
      basePrompt,
      contextTypes: contextTypes,
      contextPriorities: contextPriorities,
      contextCategories: contextCategories,
      includeActions: includeActions,
    );
  }

  /// Get context controller if available
  AiContextController? get contextController => _controller.contextController;
}

/// Convenience widget that exposes an [AiActionHook] to its [builder].
///
/// Equivalent to calling `AiActionHook.of(context)` inside a child widget's
/// own `build` method, but avoids the boilerplate when you only need the
/// hook for a single subtree.
class AiActionBuilder extends StatelessWidget {
  /// Called on every build with the current [BuildContext] and a fresh
  /// [AiActionHook] resolved from the nearest [AiActionProvider].
  final Widget Function(BuildContext context, AiActionHook hook) builder;

  /// Creates an [AiActionBuilder]. The [builder] is required.
  const AiActionBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final hook = AiActionHook.of(context);
    return builder(context, hook);
  }
}
