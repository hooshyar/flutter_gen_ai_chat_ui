import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';

void main() {
  testWidgets('ResultRendererRegistry builds registered kind', (tester) async {
    const kind = 'summary';
    final registry = ResultRendererRegistry(
      builders: {kind: (context, data) => ResultCard.fromData(data)},
      child: const SizedBox(),
    );

    await tester.pumpWidget(MaterialApp(home: registry));

    final built =
        ResultRendererRegistry.of(tester.element(find.byType(SizedBox)))
            .buildResult(tester.element(find.byType(SizedBox)), kind, {
      'title': 'Analysis',
      'subtitle': 'Quick summary',
      'body': 'Everything looks good.',
    });

    expect(built, isA<ResultCard>());
  });
}
