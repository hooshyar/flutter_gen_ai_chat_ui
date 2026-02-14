import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Interaction mode for voice input (push-to-talk or toggle on/off).
enum VoiceSendMode { pushToTalk, toggle }

/// Current state of the voice recording lifecycle.
enum VoiceState {
  idle,
  listening,
  detecting,
  recording,
  sending,
  error,
  disabled
}

/// Microphone button that handles push-to-talk and toggle voice recording.
class VoiceSendButton extends StatelessWidget {
  final VoiceSendMode mode;
  final VoiceState state;
  final VoidCallback? onHoldStart;
  final VoidCallback? onHoldEnd;
  final ValueChanged<bool>? onToggle;
  final String? semanticsLabel;
  final double diameter; // visual diameter inside tap target
  final double minTapTarget;
  final BorderRadius? borderRadius;
  final bool enableHaptics;

  const VoiceSendButton({
    super.key,
    required this.mode,
    required this.state,
    this.onHoldStart,
    this.onHoldEnd,
    this.onToggle,
    this.semanticsLabel,
    this.diameter = 40,
    this.minTapTarget = 48,
    this.borderRadius,
    this.enableHaptics = false,
  });

  bool get _isDisabled => state == VoiceState.disabled;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final icon = _iconFor(state);

    final button = Semantics(
      button: true,
      enabled: !_isDisabled,
      label: semanticsLabel ?? 'Voice button: ${_stateLabel(state)}',
      child: _buildGestureWrapper(
        context,
        _buildVisual(icon, color),
      ),
    );

    return button;
  }

  Widget _buildVisual(IconData icon, ColorScheme color) {
    final radius = borderRadius ?? BorderRadius.circular(diameter);
    final inner = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        color: _isDisabled
            ? color.surfaceContainerHighest
            : color.primaryContainer,
        borderRadius: radius,
      ),
      alignment: Alignment.center,
      child: Icon(
        icon,
        color: _isDisabled ? color.onSurfaceVariant : color.onPrimaryContainer,
      ),
    );

    return ConstrainedBox(
      constraints:
          BoxConstraints(minWidth: minTapTarget, minHeight: minTapTarget),
      child: inner,
    );
  }

  Widget _buildGestureWrapper(BuildContext context, Widget child) {
    if (_isDisabled) return child;
    final shortcuts = <ShortcutActivator, Intent>{
      const SingleActivator(LogicalKeyboardKey.space): const ActivateIntent(),
      const SingleActivator(LogicalKeyboardKey.enter): const ActivateIntent(),
    };
    final actions = <Type, Action<Intent>>{
      ActivateIntent: CallbackAction<ActivateIntent>(
        onInvoke: (_) {
          if (mode == VoiceSendMode.toggle) {
            onToggle?.call(!(state == VoiceState.listening ||
                state == VoiceState.recording));
          } else {
            onHoldStart?.call();
            onHoldEnd?.call();
          }
          return null;
        },
      ),
    };
    switch (mode) {
      case VoiceSendMode.pushToTalk:
        return Shortcuts(
          shortcuts: shortcuts,
          child: Actions(
            actions: actions,
            child: GestureDetector(
              // Support both long-press and simple press down/up for broader device behavior
              onTapDown: (_) => onHoldStart?.call(),
              onTapUp: (_) => onHoldEnd?.call(),
              onTapCancel: () => onHoldEnd?.call(),
              onLongPressStart: (_) => onHoldStart?.call(),
              onLongPressEnd: (_) => onHoldEnd?.call(),
              onLongPressCancel: () => onHoldEnd?.call(),
              child: Focus(autofocus: false, child: child),
            ),
          ),
        );
      case VoiceSendMode.toggle:
        return Shortcuts(
          shortcuts: shortcuts,
          child: Actions(
            actions: actions,
            child: InkWell(
              borderRadius: borderRadius ?? BorderRadius.circular(diameter),
              onTap: () => onToggle?.call(!(state == VoiceState.listening ||
                  state == VoiceState.recording)),
              child: Focus(autofocus: false, child: child),
            ),
          ),
        );
    }
  }

  IconData _iconFor(VoiceState s) {
    switch (s) {
      case VoiceState.idle:
        return Icons.mic_none;
      case VoiceState.listening:
        return Icons.hearing;
      case VoiceState.detecting:
        return Icons.graphic_eq;
      case VoiceState.recording:
        return Icons.mic;
      case VoiceState.sending:
        return Icons.cloud_upload_outlined;
      case VoiceState.error:
        return Icons.error_outline;
      case VoiceState.disabled:
        return Icons.mic_off;
    }
  }

  String _stateLabel(VoiceState s) {
    switch (s) {
      case VoiceState.idle:
        return 'idle';
      case VoiceState.listening:
        return 'listening';
      case VoiceState.detecting:
        return 'detecting';
      case VoiceState.recording:
        return 'recording';
      case VoiceState.sending:
        return 'sending';
      case VoiceState.error:
        return 'error';
      case VoiceState.disabled:
        return 'disabled';
    }
  }
}
