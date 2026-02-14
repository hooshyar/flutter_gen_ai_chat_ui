import 'package:flutter/material.dart';

/// Displays a vertical list of label–value pairs for structured metadata.
class KeyValueList extends StatelessWidget {
  final Map<String, String> items;
  final EdgeInsetsGeometry padding;
  final double spacing;

  const KeyValueList({
    super.key,
    required this.items,
    this.padding = const EdgeInsets.all(12),
    this.spacing = 8,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final entries = items.entries.toList(growable: false);
    return Card(
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < entries.length; i++) ...[
              if (i > 0) SizedBox(height: spacing),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(entries[i].key, style: textTheme.labelMedium),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: Text(entries[i].value, style: textTheme.bodyMedium),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
