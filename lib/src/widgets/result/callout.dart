import 'package:flutter/material.dart';

/// Severity level for a [Callout] banner.
enum CalloutType { info, warning, error, success }

/// Colored banner for displaying informational, warning, error, or success messages.
class Callout extends StatelessWidget {
  final String title;
  final String message;
  final CalloutType type;

  const Callout({
    super.key,
    required this.title,
    required this.message,
    this.type = CalloutType.info,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = _colorsFor(type, scheme);
    final semanticsLabel = _semanticsLabelFor(type, title, message);
    final isAssertive =
        type == CalloutType.error || type == CalloutType.warning;

    return Semantics(
      container: true,
      label: semanticsLabel,
      liveRegion: isAssertive,
      child: Container(
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.border),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(colors.icon, color: colors.accent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(color: colors.accent)),
                  const SizedBox(height: 4),
                  Text(message, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalloutColors {
  final Color background;
  final Color border;
  final Color accent;
  final IconData icon;
  const _CalloutColors(this.background, this.border, this.accent, this.icon);
}

_CalloutColors _colorsFor(CalloutType type, ColorScheme scheme) {
  switch (type) {
    case CalloutType.info:
      return _CalloutColors(
        scheme.surfaceContainerLow,
        scheme.outlineVariant,
        scheme.primary,
        Icons.info_outline,
      );
    case CalloutType.warning:
      return _CalloutColors(
        scheme.surfaceContainerLow,
        scheme.outlineVariant,
        scheme.tertiary,
        Icons.warning_amber_rounded,
      );
    case CalloutType.error:
      return _CalloutColors(
        scheme.surfaceContainerLow,
        scheme.outlineVariant,
        scheme.error,
        Icons.error_outline,
      );
    case CalloutType.success:
      return _CalloutColors(
        scheme.surfaceContainerLow,
        scheme.outlineVariant,
        scheme.secondary,
        Icons.check_circle_outline,
      );
  }
}

String _semanticsLabelFor(CalloutType type, String title, String message) {
  String prefix;
  switch (type) {
    case CalloutType.info:
      prefix = 'Info';
      break;
    case CalloutType.warning:
      prefix = 'Warning';
      break;
    case CalloutType.error:
      prefix = 'Error';
      break;
    case CalloutType.success:
      prefix = 'Success';
      break;
  }
  return '$prefix: $title. $message';
}
