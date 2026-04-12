import 'package:flutter/material.dart';

typedef ResultBuilder = Widget Function(
    BuildContext context, Map<String, dynamic> data);

/// UI-only registry mapping a string `kind` to a result widget builder.
///
/// Also supports per-kind loading widgets via [loadingBuilders]. When a
/// `ChatMessage.loading(loadingKind: 'weather')` is rendered, the registry
/// looks up the matching loading builder to show a custom loading state.
class ResultRendererRegistry extends InheritedWidget {
  final Map<String, ResultBuilder> builders;

  /// Custom loading widget builders keyed by kind.
  ///
  /// When a message has `isLoading: true` and a `loadingKind`, the registry
  /// renders the matching loading builder instead of the default shimmer.
  final Map<String, ResultBuilder> loadingBuilders;

  const ResultRendererRegistry({
    super.key,
    required super.child,
    this.builders = const {},
    this.loadingBuilders = const {},
  });

  static ResultRendererRegistry of(BuildContext context) {
    final registry =
        context.dependOnInheritedWidgetOfExactType<ResultRendererRegistry>();
    assert(registry != null, 'ResultRendererRegistry not found in context');
    return registry!;
  }

  static ResultRendererRegistry? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ResultRendererRegistry>();
  }

  /// Returns a widget for the given kind, or null if not registered.
  Widget? buildResult(
      BuildContext context, String kind, Map<String, dynamic> data) {
    final builder = builders[kind];
    if (builder == null) return null;
    return builder(context, data);
  }

  /// Returns a loading widget for the given kind, or null if not registered.
  Widget? buildLoading(
      BuildContext context, String kind, Map<String, dynamic> data) {
    final builder = loadingBuilders[kind];
    if (builder == null) return null;
    return builder(context, data);
  }

  /// Returns a new registry with additional/overridden builders.
  ResultRendererRegistry extend(
    Map<String, ResultBuilder> additions, {
    Map<String, ResultBuilder>? loadingAdditions,
  }) {
    return ResultRendererRegistry(
      builders: {...builders, ...additions},
      loadingBuilders: {
        ...loadingBuilders,
        ...?loadingAdditions,
      },
      child: child,
    );
  }

  @override
  bool updateShouldNotify(covariant ResultRendererRegistry oldWidget) {
    // Rebuild dependents when builder map identity changes
    return !identical(oldWidget.builders, builders);
  }
}
