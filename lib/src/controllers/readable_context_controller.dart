import 'dart:convert';

import 'package:flutter/widgets.dart';

/// A controller that manages readable context data for AI consumption
/// Equivalent to CopilotKit's useCopilotReadable hook
///
/// This allows your Flutter app to share state and data with the AI assistant,
/// making the AI aware of your application's current state
class ReadableContextController extends ChangeNotifier {
  final Map<String, ReadableContext> _contexts = {};

  /// Get all readable contexts as a formatted string for AI consumption
  String get contextSummary {
    if (_contexts.isEmpty) {
      return 'No application context available.';
    }

    final buffer = StringBuffer()..writeln('Application Context:');

    for (final entry in _contexts.entries) {
      final context = entry.value;
      buffer
        ..writeln('')
        ..writeln('${context.description}:')
        ..writeln(_formatValue(context.value));
    }

    return buffer.toString();
  }

  /// Get all contexts as a structured map for programmatic use
  Map<String, dynamic> get contextData {
    return _contexts.map(
      (key, context) => MapEntry(key, {
        'description': context.description,
        'value': context.value,
        'lastUpdated': context.lastUpdated.toIso8601String(),
      }),
    );
  }

  /// Add or update a readable context
  ///
  /// [key] - Unique identifier for this context
  /// [description] - Human-readable description of what this data represents
  /// [value] - The actual data to share with the AI (will be JSON serialized)
  void setReadable(String key, String description, dynamic value) {
    _contexts[key] = ReadableContext(
      key: key,
      description: description,
      value: value,
      lastUpdated: DateTime.now(),
    );
    notifyListeners();
  }

  /// Remove a readable context
  void removeReadable(String key) {
    if (_contexts.remove(key) != null) {
      notifyListeners();
    }
  }

  /// Clear all readable contexts
  void clearAll() {
    if (_contexts.isNotEmpty) {
      _contexts.clear();
      notifyListeners();
    }
  }

  /// Get specific readable context
  ReadableContext? getReadable(String key) {
    return _contexts[key];
  }

  /// Get all context keys
  List<String> get contextKeys => _contexts.keys.toList();

  /// Format value for AI consumption
  String _formatValue(dynamic value) {
    try {
      if (value == null) return 'null';

      // If already a string, return as-is
      if (value is String) return value;

      // For primitives, convert directly
      if (value is num || value is bool) return value.toString();

      // For complex objects, serialize as JSON with pretty formatting
      final encoder = const JsonEncoder.withIndent('  ');
      return encoder.convert(value);
    } catch (e) {
      // Fallback to toString() if JSON serialization fails
      return value.toString();
    }
  }

  /// Create context summary for specific keys only
  String getContextSummaryFor(List<String> keys) {
    final filteredContexts = <String, ReadableContext>{};
    for (final key in keys) {
      final context = _contexts[key];
      if (context != null) {
        filteredContexts[key] = context;
      }
    }

    if (filteredContexts.isEmpty) {
      return 'No matching context available.';
    }

    final buffer = StringBuffer()..writeln('Relevant Context:');

    for (final entry in filteredContexts.entries) {
      final context = entry.value;
      buffer
        ..writeln('')
        ..writeln('${context.description}:')
        ..writeln(_formatValue(context.value));
    }

    return buffer.toString();
  }
}

/// Represents a single readable context item
class ReadableContext {
  final String key;
  final String description;
  final dynamic value;
  final DateTime lastUpdated;

  const ReadableContext({
    required this.key,
    required this.description,
    required this.value,
    required this.lastUpdated,
  });

  ReadableContext copyWith({
    String? key,
    String? description,
    dynamic value,
    DateTime? lastUpdated,
  }) {
    return ReadableContext(
      key: key ?? this.key,
      description: description ?? this.description,
      value: value ?? this.value,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// Widget that provides readable context to descendant widgets
/// Equivalent to wrapping components with useCopilotReadable in React
class ReadableContextProvider extends InheritedWidget {
  final ReadableContextController controller;

  const ReadableContextProvider({
    super.key,
    required this.controller,
    required super.child,
  });

  static ReadableContextController? of(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<ReadableContextProvider>();
    return provider?.controller;
  }

  @override
  bool updateShouldNotify(ReadableContextProvider oldWidget) {
    return controller != oldWidget.controller;
  }
}

/// Mixin to easily add readable context functionality to any widget
mixin ReadableContextMixin<T extends StatefulWidget> on State<T> {
  ReadableContextController? _readableController;

  /// Get the readable context controller from the widget tree
  ReadableContextController get readableController {
    return _readableController ??=
        ReadableContextProvider.of(context) ?? ReadableContextController();
  }

  /// Add readable context with automatic disposal
  void setReadable(String key, String description, dynamic value) {
    readableController.setReadable(key, description, value);
  }

  /// Remove readable context
  void removeReadable(String key) {
    readableController.removeReadable(key);
  }
}
