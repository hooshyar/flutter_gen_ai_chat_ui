import 'package:flutter/material.dart';

/// A single button/action in the chat action bar.
class ChatAction {
  /// The icon to display.
  final IconData icon;

  /// Optional tooltip or label text.
  final String? tooltip;

  /// Callback when tapped.
  final VoidCallback onTap;

  /// Optional custom builder for advanced usage.
  final Widget Function(BuildContext context, VoidCallback onTap)? builder;

  /// Whether this action is currently visible.
  final bool visible;

  const ChatAction({
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.builder,
    this.visible = true,
  });
}

/// Configuration for the chat-style action bar.
class ChatActionsBarConfig {
  /// Ordered list of actions to render.
  final List<ChatAction> actions;

  /// Optional background color of the bar.
  final Color? backgroundColor;

  /// Padding around the actions row.
  final EdgeInsetsGeometry padding;

  const ChatActionsBarConfig({
    required this.actions,
    this.backgroundColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  });
}

/// A horizontal bar of chat actions (➕, 🔍, 🎤, etc.) above the input field.
class ChatActionsBar extends StatelessWidget {
  final ChatActionsBarConfig config;

  const ChatActionsBar(this.config, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: config.backgroundColor ?? Colors.transparent,
      padding: config.padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: config.actions.where((a) => a.visible).map((action) {
          if (action.builder != null) {
            return action.builder!(context, action.onTap);
          }
          return IconButton(
            icon: Icon(action.icon),
            tooltip: action.tooltip,
            onPressed: action.onTap,
          );
        }).toList(),
      ),
    );
  }
}
