import 'package:flutter/material.dart';

/// Card container for presenting agent action results with a title and body.
class ResultCard extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final String? body;
  final List<Widget>? actions;

  const ResultCard({
    super.key,
    this.title,
    this.subtitle,
    this.body,
    this.actions,
  });

  factory ResultCard.fromData(Map<String, dynamic> data) {
    return ResultCard(
      title: data['title']?.toString(),
      subtitle: data['subtitle']?.toString(),
      body: data['body']?.toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) Text(title!, style: textTheme.titleMedium),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle!, style: textTheme.labelMedium),
            ],
            if (body != null) ...[
              const SizedBox(height: 12),
              Text(body!, style: textTheme.bodyMedium),
            ],
            if (actions != null && actions!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(spacing: 8, children: actions!),
            ],
          ],
        ),
      ),
    );
  }
}
