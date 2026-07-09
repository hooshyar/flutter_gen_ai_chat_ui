import 'dart:async';

import 'package:flutter/material.dart';

import '../controllers/ai_context_controller.dart';
import '../models/ai_context.dart';

/// Configuration for AiContextProvider
class AiContextProviderConfig {
  /// Context controller configuration
  final AiContextConfig contextConfig;

  /// Whether to automatically provide navigation context
  final bool autoNavigationContext;

  /// Whether to automatically provide theme context
  final bool autoThemeContext;

  /// Whether to automatically provide device context
  final bool autoDeviceContext;

  /// Custom context providers
  final List<AiContextData Function(BuildContext)> customProviders;

  const AiContextProviderConfig({
    this.contextConfig = const AiContextConfig(),
    this.autoNavigationContext = true,
    this.autoThemeContext = false,
    this.autoDeviceContext = false,
    this.customProviders = const [],
  });
}

/// Provider widget that manages AI context throughout the widget tree
class AiContextProvider extends StatefulWidget {
  /// Configuration for the context provider
  final AiContextProviderConfig config;

  /// Child widget
  final Widget child;

  /// Optional external context controller
  final AiContextController? controller;

  const AiContextProvider({
    super.key,
    required this.child,
    this.config = const AiContextProviderConfig(),
    this.controller,
  });

  @override
  State<AiContextProvider> createState() => _AiContextProviderState();

  /// Get the AiContextController from the current context
  static AiContextController of(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<_AiContextInheritedWidget>();
    if (provider == null) {
      throw FlutterError(
        'AiContextProvider.of() called with a context that does not contain an AiContextProvider.\n'
        'No AiContextProvider ancestor could be found starting from the context that was passed to AiContextProvider.of().',
      );
    }
    return provider.controller;
  }

  /// Get the AiContextController from the current context, or null if not found
  static AiContextController? maybeOf(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<_AiContextInheritedWidget>();
    return provider?.controller;
  }
}

class _AiContextProviderState extends State<AiContextProvider>
    with WidgetsBindingObserver, RouteAware {
  late AiContextController _controller;
  bool _isExternalController = false;
  StreamSubscription<AiContextEvent>? _eventSubscription;
  bool _didSetupContexts = false;

  @override
  void initState() {
    super.initState();

    // Use external controller or create new one
    if (widget.controller != null) {
      _controller = widget.controller!;
      _isExternalController = true;
    } else {
      _controller = AiContextController(config: widget.config.contextConfig);
      _isExternalController = false;
    }

    // Listen to lifecycle changes
    WidgetsBinding.instance.addObserver(this);

    // Set up event monitoring for debugging
    if (widget.config.contextConfig.enableLogging) {
      _eventSubscription = _controller.events.listen(_logContextEvent);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Perform initial setup that requires BuildContext only once
    if (!_didSetupContexts) {
      _setupAutomaticContext();
      _setupCustomContextProviders();
      _didSetupContexts = true;
    } else {
      // Keep navigation context up to date on dependency changes
      _updateNavigationContext();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _controller.setContext(AiContextData.custom(
      id: 'app_lifecycle',
      name: 'App Lifecycle',
      data: state.toString().split('.').last,
      description: 'Current application lifecycle state',
      categories: ['system', 'lifecycle'],
      priority: AiContextPriority.low,
    ));
  }

  void _setupAutomaticContext() {
    if (widget.config.autoNavigationContext) {
      _updateNavigationContext();
    }

    if (widget.config.autoThemeContext) {
      _updateThemeContext();
    }

    if (widget.config.autoDeviceContext) {
      _updateDeviceContext();
    }
  }

  void _setupCustomContextProviders() {
    for (final provider in widget.config.customProviders) {
      try {
        final contextData = provider(context);
        _controller.setContext(contextData);
      } catch (e) {
        debugPrint('Error in custom context provider: $e');
      }
    }
  }

  void _updateNavigationContext() {
    if (!widget.config.autoNavigationContext) return;

    final route = ModalRoute.of(context);
    if (route != null) {
      _controller.setContext(AiContextData.navigationContext(
        id: 'current_route',
        currentPage: route.settings.name ?? 'unknown',
        pageData: route.settings.arguments as Map<String, dynamic>?,
        priority: AiContextPriority.high,
      ));
    }
  }

  void _updateThemeContext() {
    final theme = Theme.of(context);
    _controller.setContext(AiContextData.custom(
      id: 'theme_context',
      name: 'Theme Settings',
      data: {
        'brightness': theme.brightness.toString().split('.').last,
        'primaryColor': theme.primaryColor.toString(),
        'platform': theme.platform.toString().split('.').last,
        'visualDensity': theme.visualDensity.toString(),
      },
      description: 'Current theme and UI settings',
      categories: ['ui', 'theme'],
      priority: AiContextPriority.low,
    ));
  }

  void _updateDeviceContext() {
    final mediaQuery = MediaQuery.of(context);
    _controller.setContext(AiContextData.custom(
      id: 'device_context',
      name: 'Device Information',
      data: {
        'screenSize':
            '${mediaQuery.size.width.round()}x${mediaQuery.size.height.round()}',
        'devicePixelRatio': mediaQuery.devicePixelRatio,
        'platformBrightness':
            mediaQuery.platformBrightness.toString().split('.').last,
        'textScaler': mediaQuery.textScaler.toString(),
        'orientation': mediaQuery.orientation.toString().split('.').last,
      },
      description: 'Device and screen information',
      categories: ['device', 'screen'],
      priority: AiContextPriority.low,
    ));
  }

  void _logContextEvent(AiContextEvent event) {
    debugPrint('AiContext Event: ${event.type} - ${event.contextData?.id}');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _eventSubscription?.cancel();

    // Only dispose if we created the controller
    if (!_isExternalController) {
      _controller.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _AiContextInheritedWidget(
      controller: _controller,
      config: widget.config,
      child: widget.child,
    );
  }
}

/// Inherited widget that exposes the AiContextController
class _AiContextInheritedWidget extends InheritedWidget {
  final AiContextController controller;
  final AiContextProviderConfig config;

  const _AiContextInheritedWidget({
    required this.controller,
    required this.config,
    required super.child,
  });

  @override
  bool updateShouldNotify(_AiContextInheritedWidget oldWidget) {
    return controller != oldWidget.controller || config != oldWidget.config;
  }
}

/// Hook-like access to AI context functionality
class AiContextHook {
  final AiContextController _controller;

  AiContextHook._(this._controller);

  /// Factory constructor to create from context
  factory AiContextHook.of(BuildContext context) {
    final controller = AiContextProvider.of(context);
    return AiContextHook._(controller);
  }

  /// Set context data
  void setContext(AiContextData contextData) {
    _controller.setContext(contextData);
  }

  /// Get context data by ID
  AiContextData? getContext(String id) {
    return _controller.getContext(id);
  }

  /// Remove context data
  bool removeContext(String id) {
    return _controller.removeContext(id);
  }

  /// Update existing context data
  bool updateContext(String id, dynamic newData) {
    return _controller.updateContext(id, newData);
  }

  /// Get context summary for AI
  String getContextSummary({
    List<AiContextType>? types,
    List<AiContextPriority>? priorities,
    List<String>? categories,
    int? maxItems,
  }) {
    return _controller.getContextSummary(
      types: types,
      priorities: priorities,
      categories: categories,
      maxItems: maxItems,
    );
  }

  /// Get context for AI prompts
  Map<String, dynamic> getContextForPrompt({
    List<AiContextType>? types,
    List<AiContextPriority>? priorities,
    List<String>? categories,
  }) {
    return _controller.getContextForPrompt(
      types: types,
      priorities: priorities,
      categories: categories,
    );
  }

  /// Watch a value and automatically update context
  StreamSubscription<T> watchValue<T>({
    required String contextId,
    required String contextName,
    required Stream<T> valueStream,
    AiContextType type = AiContextType.applicationState,
    AiContextPriority priority = AiContextPriority.normal,
    String? description,
    List<String> categories = const [],
    String Function(T value)? serializer,
  }) {
    return _controller.watchValue<T>(
      contextId: contextId,
      contextName: contextName,
      valueStream: valueStream,
      type: type,
      priority: priority,
      description: description,
      categories: categories,
      serializer: serializer,
    );
  }

  /// Watch a ValueNotifier and automatically update context.
  ///
  /// Returns a disposer that stops watching; the listener is also removed
  /// automatically when the underlying controller is disposed.
  VoidCallback watchNotifier<T>({
    required String contextId,
    required String contextName,
    required ValueNotifier<T> notifier,
    AiContextType type = AiContextType.applicationState,
    AiContextPriority priority = AiContextPriority.normal,
    String? description,
    List<String> categories = const [],
    String Function(T value)? serializer,
  }) {
    return _controller.watchNotifier<T>(
      contextId: contextId,
      contextName: contextName,
      notifier: notifier,
      type: type,
      priority: priority,
      description: description,
      categories: categories,
      serializer: serializer,
    );
  }

  /// Stream of context events
  Stream<AiContextEvent> get events => _controller.events;

  /// All current context data
  Map<String, AiContextData> get contextData => _controller.contextData;
}

/// Widget builder that provides access to AiContextHook
class AiContextBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, AiContextHook hook) builder;

  const AiContextBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final hook = AiContextHook.of(context);
    return builder(context, hook);
  }
}

/// Mixin for widgets that need to provide context to AI
mixin AiContextAware<T extends StatefulWidget> on State<T> {
  late AiContextHook _contextHook;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _contextHook = AiContextHook.of(context);
    _provideContext();
  }

  /// Override this to provide context data
  void _provideContext() {
    // Default implementation - override in your widget
  }

  /// Helper to set context
  void setContext(AiContextData contextData) {
    _contextHook.setContext(contextData);
  }

  /// Helper to update context
  void updateContext(String id, dynamic data) {
    _contextHook.updateContext(id, data);
  }

  /// Helper to remove context
  void removeContext(String id) {
    _contextHook.removeContext(id);
  }
}
