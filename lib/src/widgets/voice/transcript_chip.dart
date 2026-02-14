import 'package:flutter/material.dart';

/// Compact chip that shows real-time speech-to-text transcription output.
class TranscriptChip extends StatelessWidget {
  final String text;
  final bool isFinal;
  final VoidCallback? onPromote;

  const TranscriptChip({
    super.key,
    required this.text,
    required this.isFinal,
    this.onPromote,
  });

  @override
  Widget build(BuildContext context) {
    final style = isFinal
        ? Theme.of(context).textTheme.bodyMedium
        : Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontStyle: FontStyle.italic,
            color: Theme.of(context).colorScheme.onSurfaceVariant);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(text, style: style)),
          if (!isFinal && onPromote != null)
            TextButton(onPressed: onPromote, child: const Text('Promote')),
        ],
      ),
    );
  }
}
