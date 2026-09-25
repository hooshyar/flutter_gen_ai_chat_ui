import 'package:flutter/material.dart';

import '../controllers/action_controller.dart';
import '../models/ai_action.dart';
import '../utils/color_extensions.dart';
import 'ai_action_provider.dart';

/// Configuration for action result display
class ActionResultConfig {
  /// Whether to show action execution in chat messages
  final bool showInMessages;

  /// Whether to show action parameters in the UI
  final bool showParameters;

  /// Whether to show execution duration
  final bool showDuration;

  /// Custom status icons
  final Map<ActionStatus, IconData>? statusIcons;

  /// Custom status colors
  final Map<ActionStatus, Color>? statusColors;

  /// Animation duration for status changes
  final Duration animationDuration;

  const ActionResultConfig({
    this.showInMessages = true,
    this.showParameters = false,
    this.showDuration = true,
    this.statusIcons,
    this.statusColors,
    this.animationDuration = const Duration(milliseconds: 300),
  });
}

/// Widget that displays the status and results of action executions
class ActionResultWidget extends StatefulWidget {
  /// ID of the execution to display
  final String executionId;

  /// Configuration for display
  final ActionResultConfig? config;

  /// Custom widget builder for different states
  final Widget Function(
    BuildContext context,
    ActionExecution execution,
    ActionResultConfig config,
  )? builder;

  const ActionResultWidget({
    super.key,
    required this.executionId,
    this.config,
    this.builder,
  });

  @override
  State<ActionResultWidget> createState() => _ActionResultWidgetState();
}

class _ActionResultWidgetState extends State<ActionResultWidget>
    with TickerProviderStateMixin {
  ActionController? _controller;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration:
          widget.config?.animationDuration ?? const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Access inherited widgets here, not in initState
    if (!mounted) return;

    final controller = AiActionProvider.of(context);
    if (_controller != controller) {
      _controller = controller;
      // Start animation after getting controller
      if (_animationController.status == AnimationStatus.dismissed) {
        _animationController.forward();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final execution = controller.getExecution(widget.executionId);
        if (execution == null) {
          return const SizedBox.shrink();
        }

        final config = widget.config ?? const ActionResultConfig();

        // Use custom builder if provided
        if (widget.builder != null) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: widget.builder!(context, execution, config),
            ),
          );
        }

        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: _buildDefaultActionResult(context, execution, config),
          ),
        );
      },
    );
  }

  Widget _buildDefaultActionResult(
    BuildContext context,
    ActionExecution execution,
    ActionResultConfig config,
  ) {
    final theme = Theme.of(context);

    // If action has custom render function, use it
    if (execution.action.render != null) {
      return execution.action.render!(
        context,
        execution.status,
        execution.parameters,
        result: execution.result,
        error: execution.error,
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Action header with status
            Row(
              children: [
                _buildStatusIcon(execution.status, config, theme),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    execution.action.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (config.showDuration &&
                    execution.status != ActionStatus.idle)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _formatDuration(execution.duration),
                      style: theme.textTheme.labelSmall,
                    ),
                  ),
              ],
            ),

            // Action description
            if (execution.action.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                execution.action.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],

            // Parameters (if enabled and available)
            if (config.showParameters && execution.parameters.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildParametersSection(context, execution.parameters, theme),
            ],

            // Status-specific content
            ..._buildStatusContent(context, execution, config, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon(
    ActionStatus status,
    ActionResultConfig config,
    ThemeData theme,
  ) {
    final defaultIcons = {
      ActionStatus.idle: Icons.radio_button_unchecked,
      ActionStatus.executing: Icons.hourglass_empty,
      ActionStatus.completed: Icons.check_circle,
      ActionStatus.failed: Icons.error,
      ActionStatus.waitingForConfirmation: Icons.help,
      ActionStatus.cancelled: Icons.cancel,
    };

    final defaultColors = {
      ActionStatus.idle: theme.colorScheme.onSurfaceVariant,
      ActionStatus.executing: theme.colorScheme.primary,
      ActionStatus.completed: Colors.green,
      ActionStatus.failed: theme.colorScheme.error,
      ActionStatus.waitingForConfirmation: theme.colorScheme.secondary,
      ActionStatus.cancelled: theme.colorScheme.onSurfaceVariant,
    };

    final icon = config.statusIcons?[status] ?? defaultIcons[status]!;
    final color = config.statusColors?[status] ?? defaultColors[status]!;

    Widget iconWidget = Icon(icon, color: color, size: 20);

    // Add animation for executing status
    if (status == ActionStatus.executing) {
      iconWidget = AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.rotate(
            angle: _animationController.value * 2 * 3.14159,
            child: iconWidget,
          );
        },
      );
    }

    return iconWidget;
  }

  List<Widget> _buildStatusContent(
    BuildContext context,
    ActionExecution execution,
    ActionResultConfig config,
    ThemeData theme,
  ) {
    switch (execution.status) {
      case ActionStatus.executing:
        return [
          const SizedBox(height: 8),
          Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Executing...',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ];

      case ActionStatus.waitingForConfirmation:
        return [
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.help_outline,
                  color: theme.colorScheme.onSecondaryContainer,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Waiting for user confirmation...',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ];

      case ActionStatus.completed:
        if (execution.result?.data != null) {
          return [
            const SizedBox(height: 8),
            _buildResultSection(context, execution.result!.data, theme),
          ];
        }
        return [
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.check, color: Colors.green, size: 16),
              const SizedBox(width: 8),
              Text(
                'Completed successfully',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.green),
              ),
            ],
          ),
        ];

      case ActionStatus.failed:
        return [
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.error_outline,
                  color: theme.colorScheme.onErrorContainer,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    execution.error ?? 'Action failed',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ];

      case ActionStatus.cancelled:
        return [
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.cancel_outlined,
                color: theme.colorScheme.onSurfaceVariant,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Cancelled by user',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ];

      default:
        return [];
    }
  }

  Widget _buildParametersSection(
    BuildContext context,
    Map<String, dynamic> parameters,
    ThemeData theme,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Parameters:',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          ...parameters.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                '${entry.key}: ${entry.value}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultSection(
    BuildContext context,
    dynamic data,
    ThemeData theme,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.green.withOpacityCompat(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.green.withOpacityCompat(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Colors.green,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Result:',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            data.toString(),
            style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else if (duration.inSeconds > 0) {
      return '${duration.inSeconds}s';
    } else {
      return '${duration.inMilliseconds}ms';
    }
  }
}
