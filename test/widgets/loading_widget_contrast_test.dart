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

/// Reads the base/highlight colours actually fed into the private
/// `_ShimmerEffect` that drives the `ShaderMask` behind the loading text.
///
/// `text.style.color` is not a meaningful contrast signal here: the
/// `ShaderMask(BlendMode.srcIn)` wrapping the text repaints every pixel
/// with the shimmer gradient regardless of the `Text` widget's own style,
/// so asserting on `Text.style.color` proves nothing about what actually
/// lands on screen. `_ShimmerEffect` is private to `loading_widget.dart`
/// (not `@visibleForTesting`), so its type can't be named here - locate it
/// by runtime type string instead and reach its `Color` fields dynamically
/// (member-name based dispatch, unaffected by library-level privacy).
({Color base, Color highlight}) _shimmerColors(WidgetTester tester) {
  final state = tester.state(
    find.byWidgetPredicate(
      (w) => w.runtimeType.toString() == '_ShimmerEffect',
    ),
  );
  final dynamic widget = (state as dynamic).widget;
  return (
    base: widget.baseColor as Color,
    highlight: widget.highlightColor as Color
  );
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

        final colors = _shimmerColors(tester);
        // Full opacity — never dimmed below the resting `textSecondary`.
        expect(colors.base.a, 1.0);
        // The dimmest part of the shimmer sweep (its resting `baseColor`,
        // not the brighter `highlightColor` band) is what must clear the
        // WCAG floor against the canvas — the old light default (#F7F8F8,
        // near-white) fails this by a wide margin.
        expect(
          _contrastRatio(colors.base, ChatTokens.light.canvas),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          _contrastRatio(colors.highlight, ChatTokens.light.canvas),
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

        final colors = _shimmerColors(tester);
        expect(colors.base.a, 1.0);
        expect(
          _contrastRatio(colors.base, ChatTokens.dark.canvas),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          _contrastRatio(colors.highlight, ChatTokens.dark.canvas),
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
