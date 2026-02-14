import 'package:flutter/material.dart';

/// Lightweight data table for rendering structured rows and columns in chat results.
class DataTableLite extends StatelessWidget {
  final List<String> columns;
  final List<List<String>> rows;
  final EdgeInsetsGeometry padding;
  final bool dense;

  const DataTableLite({
    super.key,
    required this.columns,
    required this.rows,
    this.padding = const EdgeInsets.all(12),
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final headingStyle = Theme.of(context).textTheme.labelMedium;
    final dataStyle = Theme.of(context).textTheme.bodyMedium;
    final horizontalMargin = dense ? 8.0 : 24.0;
    final dataRowMinHeight = dense ? 24.0 : 40.0;
    final headingRowHeight = dense ? 28.0 : 48.0;

    return Card(
      child: Padding(
        padding: padding,
        child: DataTable(
          horizontalMargin: horizontalMargin,
          headingRowHeight: headingRowHeight,
          dataRowMinHeight: dataRowMinHeight,
          columns: [
            for (final c in columns)
              DataColumn(
                label: Text(c, style: headingStyle),
              ),
          ],
          rows: [
            for (final r in rows)
              DataRow(
                cells: [
                  for (final cell in r) DataCell(Text(cell, style: dataStyle)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
