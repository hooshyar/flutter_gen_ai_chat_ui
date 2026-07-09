import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';

import '../models/ai_context.dart';

/// Configuration for AI context management
class AiContextConfig {
  /// Maximum number of context items to keep
  final int maxContextItems;

  /// Whether to automatically clean up expired context
  final bool autoCleanExpired;

  /// How often to clean up expired context (in seconds)
  final int cleanupIntervalSeconds;

  /// Whether to log context operations for debugging
  final bool enableLogging;

  /// Custom context filters
  final List<bool Function(AiContextData)> contextFilters;

  const AiContextConfig({
    this.maxContextItems = 100,
    this.autoCleanExpired = true,
    this.cleanupIntervalSeconds = 300, // 5 minutes
    this.enableLogging = false,
    this.contextFilters = const [],
  });
}

/// Controller for managing AI context data and state observation
class AiContextController extends ChangeNotifier {
  final AiContextConfig _config;
  final Map<String, AiContextData> _contextData = {};
  final StreamController<AiContextEvent> _eventController =
      StreamController<AiContextEvent>.broadcast();

  Timer? _cleanupTimer;

  /// Listeners registered via [watchNotifier], tracked so they can be removed
  /// in [dispose]. Without this the watched [Listenable] keeps this controller
  /// (and its context map) alive for the lifetime of the notifier.
  final List<_NotifierWatch> _notifierWatches = [];

  AiContextController({AiContextConfig? config})
      : _config = config ?? const AiContextConfig() {
    if (_config.autoCleanExpired) {
      _startCleanupTimer();
    }

    if (_config.enableLogging) {
      dev.log('AiContextController initialized with config: $_config');
    }
  }

  /// Stream of context change events
  Stream<AiContextEvent> get events => _eventController.stream;

  /// All context data currently stored
  Map<String, AiContextData> get contextData => Map.unmodifiable(_contextData);

  /// Get context data by ID
  AiContextData? getContext(String id) => _contextData[id];

  /// Get all context data of a specific type
  List<AiContextData> getContextByType(AiContextType type) {
    return _contextData.values
        .where((context) => context.type == type && context.isValid)
        .toList();
  }

  /// Get context data by category
  List<AiContextData> getContextByCategory(String category) {
    return _contextData.values
        .where((context) =>
            context.categories.contains(category) && context.isValid)
        .toList();
  }

  /// Get context data by priority level
  List<AiContextData> getContextByPriority(AiContextPriority priority) {
    return _contextData.values
        .where((context) => context.priority == priority && context.isValid)
        .toList();
  }

  /// Add or update context data
  void setContext(AiContextData contextData) {
    // Apply filters
    for (final filter in _config.contextFilters) {
      if (!filter(contextData)) {
        if (_config.enableLogging) {
          dev.log('Context filtered out: ${contextData.id}');
        }
        return;
      }
    }

    final previousData = _contextData[contextData.id];
    _contextData[contextData.id] = contextData;

    // Clean up if over limit
    _enforceMaxItems();

    // Emit event
    final eventType = previousData == null
        ? AiContextEventType.added
        : AiContextEventType.updated;

    _emitEvent(AiContextEvent(
      type: eventType,
      contextData: contextData,
      previousData: previousData,
    ));

    if (_config.enableLogging) {
      dev.log('Context ${eventType.name}: ${contextData.id}');
    }

    notifyListeners();
  }

  /// Remove context data by ID
  bool removeContext(String id) {
    final contextData = _contextData.remove(id);
    if (contextData != null) {
      _emitEvent(AiContextEvent(
        type: AiContextEventType.removed,
        contextData: contextData,
      ));

      if (_config.enableLogging) {
        dev.log('Context removed: $id');
      }

      notifyListeners();
      return true;
    }
    return false;
  }

  /// Update existing context data
  bool updateContext(String id, dynamic newData) {
    final existingContext = _contextData[id];
    if (existingContext != null) {
      final updatedContext = existingContext.copyWith(
        data: newData,
        lastUpdated: DateTime.now(),
      );
      setContext(updatedContext);
      return true;
    }
    return false;
  }

  /// Clear all context data
  void clearContext() {
    _contextData.clear();

    _emitEvent(AiContextEvent(
      type: AiContextEventType.cleared,
    ));

    if (_config.enableLogging) {
      dev.log('All context cleared');
    }

    notifyListeners();
  }

  /// Get context summary for AI consumption
  String getContextSummary({
    List<AiContextType>? types,
    List<AiContextPriority>? priorities,
    List<String>? categories,
    int? maxItems,
  }) {
    var contexts = _contextData.values
        .where((context) => context.enabled && context.isValid)
        .toList();

    // Filter by type
    if (types != null && types.isNotEmpty) {
      contexts = contexts.where((c) => types.contains(c.type)).toList();
    }

    // Filter by priority
    if (priorities != null && priorities.isNotEmpty) {
      contexts =
          contexts.where((c) => priorities.contains(c.priority)).toList();
    }

    // Filter by categories
    if (categories != null && categories.isNotEmpty) {
      contexts = contexts
          .where((c) => categories.any((cat) => c.categories.contains(cat)))
          .toList();
    }

    // Sort by priority (critical first, then by last updated)
    contexts.sort((a, b) {
      final priorityOrder = {
        AiContextPriority.critical: 0,
        AiContextPriority.high: 1,
        AiContextPriority.normal: 2,
        AiContextPriority.low: 3,
      };

      final priorityComparison =
          priorityOrder[a.priority]!.compareTo(priorityOrder[b.priority]!);

      if (priorityComparison != 0) return priorityComparison;

      // If same priority, sort by most recent
      return b.lastUpdated.compareTo(a.lastUpdated);
    });

    // Limit items
    if (maxItems != null && contexts.length > maxItems) {
      contexts = contexts.take(maxItems).toList();
    }

    if (contexts.isEmpty) {
      return 'No relevant context available.';
    }

    final contextStrings = contexts.map((c) => c.toAiString()).toList();
    return 'Current Context:\n${contextStrings.join('\n')}';
  }

  /// Get context formatted for AI prompts
  Map<String, dynamic> getContextForPrompt({
    List<AiContextType>? types,
    List<AiContextPriority>? priorities,
    List<String>? categories,
  }) {
    final filteredContexts = _contextData.values
        .where((context) => context.enabled && context.isValid)
        .where((context) {
      if (types != null && !types.contains(context.type)) return false;
      if (priorities != null && !priorities.contains(context.priority)) {
        return false;
      }
      if (categories != null &&
          !categories.any((cat) => context.categories.contains(cat))) {
        return false;
      }
      return true;
    }).toList();

    final result = <String, dynamic>{};

    for (final context in filteredContexts) {
      result[context.id] = {
        'name': context.name,
        'type': context.type.toString().split('.').last,
        'priority': context.priority.toString().split('.').last,
        'description': context.description,
        'data': context.data,
        'lastUpdated': context.lastUpdated.toIso8601String(),
      };
    }

    return result;
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
    return valueStream.listen((value) {
      setContext(AiContextData(
        id: contextId,
        name: contextName,
        type: type,
        priority: priority,
        data: value,
        description: description ?? 'Watched value: $contextName',
        categories: categories,
        serializer: serializer != null ? (data) => serializer(data as T) : null,
      ));
    });
  }

  /// Watch a ValueNotifier and automatically update context.
  ///
  /// Returns a disposer that removes the listener. The listener is also
  /// removed automatically when this controller is disposed, so calling the
  /// disposer is only needed if you want to stop watching earlier.
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
    void updateContext() {
      setContext(AiContextData(
        id: contextId,
        name: contextName,
        type: type,
        priority: priority,
        data: notifier.value,
        description: description ?? 'ValueNotifier: $contextName',
        categories: categories,
        serializer: serializer != null ? (data) => serializer(data as T) : null,
      ));
    }

    // Set initial context
    updateContext();

    // Listen for changes
    notifier.addListener(updateContext);
    final watch = _NotifierWatch(notifier, updateContext);
    _notifierWatches.add(watch);

    return () {
      notifier.removeListener(updateContext);
      _notifierWatches.remove(watch);
    };
  }

  /// Clean up expired context data
  void cleanupExpiredContext() {
    final expiredIds = _contextData.entries
        .where((entry) => !entry.value.isValid)
        .map((entry) => entry.key)
        .toList();

    for (final id in expiredIds) {
      removeContext(id);
    }

    if (_config.enableLogging && expiredIds.isNotEmpty) {
      dev.log('Cleaned up ${expiredIds.length} expired context items');
    }
  }

  /// Start automatic cleanup timer
  void _startCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(
      Duration(seconds: _config.cleanupIntervalSeconds),
      (_) => cleanupExpiredContext(),
    );
  }

  /// Enforce maximum context items limit
  void _enforceMaxItems() {
    if (_contextData.length <= _config.maxContextItems) return;

    final sortedContexts = _contextData.values.toList()
      ..sort((a, b) {
        // Sort by priority first (low priority items get removed first)
        final priorityOrder = {
          AiContextPriority.low: 0,
          AiContextPriority.normal: 1,
          AiContextPriority.high: 2,
          AiContextPriority.critical: 3,
        };

        final priorityComparison =
            priorityOrder[a.priority]!.compareTo(priorityOrder[b.priority]!);

        if (priorityComparison != 0) return priorityComparison;

        // If same priority, remove oldest first
        return a.lastUpdated.compareTo(b.lastUpdated);
      });

    final itemsToRemove = _contextData.length - _config.maxContextItems;
    for (var i = 0; i < itemsToRemove; i++) {
      _contextData.remove(sortedContexts[i].id);

      if (_config.enableLogging) {
        dev.log('Removed context due to limit: ${sortedContexts[i].id}');
      }
    }
  }

  /// Emit a context event
  void _emitEvent(AiContextEvent event) {
    if (!_eventController.isClosed) {
      _eventController.add(event);
    }
  }

  @override
  void dispose() {
    _cleanupTimer?.cancel();
    for (final watch in _notifierWatches) {
      watch.notifier.removeListener(watch.listener);
    }
    _notifierWatches.clear();
    _eventController.close();
    super.dispose();
  }
}

/// Internal record of a [Listenable] watched via
/// [AiContextController.watchNotifier] and the callback registered on it.
class _NotifierWatch {
  _NotifierWatch(this.notifier, this.listener);

  final Listenable notifier;
  final VoidCallback listener;
}
