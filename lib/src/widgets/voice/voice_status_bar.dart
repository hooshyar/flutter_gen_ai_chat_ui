import 'package:flutter/material.dart';

/// Current phase of a full-duplex voice conversation.
enum DuplexState { listening, speaking, thinking, connecting, idle }

/// Animated status bar showing the current voice conversation phase and level.
class VoiceStatusBar extends StatelessWidget {
  final DuplexState duplexState;
  final int? latencyMs;
  final double? packetLoss; // 0.0 - 1.0
  final VoidCallback? onInterrupt;
  final VoidCallback? onReconnect;

  const VoiceStatusBar({
    super.key,
    required this.duplexState,
    this.latencyMs,
    this.packetLoss,
    this.onInterrupt,
    this.onReconnect,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = _labelFor(duplexState);
    final latencyText = latencyMs != null ? ' • ${latencyMs}ms' : '';
    final lossText = packetLoss != null
        ? ' • ${(packetLoss! * 100).toStringAsFixed(0)}% loss'
        : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(_iconFor(duplexState), size: 18, color: scheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$text$latencyText$lossText',
              style: Theme.of(context).textTheme.labelMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (duplexState == DuplexState.speaking && onInterrupt != null)
            TextButton(onPressed: onInterrupt, child: const Text('Stop')),
          if (duplexState == DuplexState.connecting && onReconnect != null)
            TextButton(onPressed: onReconnect, child: const Text('Reconnect')),
        ],
      ),
    );
  }

  String _labelFor(DuplexState s) {
    switch (s) {
      case DuplexState.listening:
        return 'Listening';
      case DuplexState.speaking:
        return 'Speaking';
      case DuplexState.thinking:
        return 'Thinking';
      case DuplexState.connecting:
        return 'Connecting…';
      case DuplexState.idle:
        return 'Idle';
    }
  }

  IconData _iconFor(DuplexState s) {
    switch (s) {
      case DuplexState.listening:
        return Icons.hearing;
      case DuplexState.speaking:
        return Icons.volume_up;
      case DuplexState.thinking:
        return Icons.hourglass_top;
      case DuplexState.connecting:
        return Icons.wifi_tethering;
      case DuplexState.idle:
        return Icons.pause_circle_outline;
    }
  }
}
