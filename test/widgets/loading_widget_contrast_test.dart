import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';
import 'package:flutter_test/flutter_test.dart';

/// Linearizes one sRGB channel (`0..1`) per the WCAG 2.x relative-luminance
/// formula. Duplicated from `test/theme/chat_tokens_test.dart` (private
/// there, and not worth a shared-test-utils import for four lines).
double _linearize(double c) {
  return c <= 0.03928
      ? c / 12.92
      : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
}

double _relativeLuminance(Color color) {
  return 0.2126 * _linearize(color.r) +
      0.7152 * _linearize(color.g) +
      0.0722 * _linearize(color.b);
}

double _contrastRatio(Color a, Color b) {
  final la = _relativeLuminance(a);
  final lb = _relativeLuminance(b);
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  group(
    'LoadingWidget default text/shimmer colour (the faint "Generating '
    'code..." label, DESIGN.md §3)',
    () {
      testWidgets('light: base colour is textSecondary, contrast >= 4.5', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light(),
            home: Scaffold(
              backgroundColor: ChatTokens.light.canvas,
              body: const LoadingWidget(texts: ['Generating code...']),
            ),
          ),
        );
        await tester.pump();

        final text = tester.widget<Text>(
          find.text('Generating code...'),
        );
        final color = text.style?.color;
        expect(color, isNotNull);
        // Full opacity — never dimmed below the resting `textSecondary`.
        expect(color!.a, 1.0);
        expect(
          _contrastRatio(color, ChatTokens.light.canvas),
          greaterThanOrEqualTo(4.5),
        );
      });

      testWidgets('dark: base colour is textSecondary, contrast >= 4.5', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: Scaffold(
              backgroundColor: ChatTokens.dark.canvas,
              body: const LoadingWidget(texts: ['Generating code...']),
            ),
          ),
        );
        await tester.pump();

        final text = tester.widget<Text>(
          find.text('Generating code...'),
        );
        final color = text.style?.color;
        expect(color, isNotNull);
        expect(color!.a, 1.0);
        expect(
          _contrastRatio(color, ChatTokens.dark.canvas),
          greaterThanOrEqualTo(4.5),
        );
      });

      testWidgets(
        'an explicit textStyle color still overrides the default',
        (tester) async {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: LoadingWidget(
                  texts: const ['Generating code...'],
                  textStyle: const TextStyle(color: Colors.pink),
                ),
              ),
            ),
          );
          await tester.pump();

          final text = tester.widget<Text>(
            find.text('Generating code...'),
          );
          expect(text.style?.color, Colors.pink);
        },
      );
    },
  );
}
