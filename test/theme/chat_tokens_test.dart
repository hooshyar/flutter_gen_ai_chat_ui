import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';
import 'package:flutter_test/flutter_test.dart';

/// Linearizes one sRGB channel (`0..1`) per the WCAG 2.x relative-luminance
/// formula.
double _linearize(double c) {
  return c <= 0.03928
      ? c / 12.92
      : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
}

/// WCAG 2.x relative luminance of [color].
double _relativeLuminance(Color color) {
  return 0.2126 * _linearize(color.r) +
      0.7152 * _linearize(color.g) +
      0.0722 * _linearize(color.b);
}

/// WCAG 2.x contrast ratio between two colors. Always `>= 1.0`.
double contrastRatio(Color a, Color b) {
  final la = _relativeLuminance(a);
  final lb = _relativeLuminance(b);
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  group('contrastRatio helper', () {
    test('black vs white is 21:1', () {
      expect(contrastRatio(Colors.black, Colors.white), closeTo(21, 0.01));
    });

    test('a color against itself is 1:1', () {
      expect(
        contrastRatio(
            ChatTokens.light.textPrimary, ChatTokens.light.textPrimary),
        closeTo(1, 0.001),
      );
    });
  });

  void checkTextContrast(String label, ChatTokens t) {
    group('$label text contrast', () {
      final backgrounds = <String, Color>{
        'canvas': t.canvas,
        'surfaceSunken': t.surfaceSunken,
        'userBubble': t.userBubble,
        'codeBg': t.codeBg,
        'inlineCodeBg': t.inlineCodeBg,
      };
      final foregrounds = <String, Color>{
        'textPrimary': t.textPrimary,
        'textSecondary': t.textSecondary,
        'textTertiary': t.textTertiary,
        'danger': t.danger,
      };

      for (final fgEntry in foregrounds.entries) {
        for (final bgEntry in backgrounds.entries) {
          test('${fgEntry.key} on ${bgEntry.key} >= 4.5', () {
            expect(
              contrastRatio(fgEntry.value, bgEntry.value),
              greaterThanOrEqualTo(4.5),
            );
          });
        }
      }

      test('borderStrong >= 3.0 vs canvas and surfaceSunken', () {
        expect(
            contrastRatio(t.borderStrong, t.canvas), greaterThanOrEqualTo(3.0));
        expect(
          contrastRatio(t.borderStrong, t.surfaceSunken),
          greaterThanOrEqualTo(3.0),
        );
      });
    });
  }

  checkTextContrast('light', ChatTokens.light);
  checkTextContrast('dark', ChatTokens.dark);

  void checkSyntaxContrast(String label, CodeBlockTheme theme) {
    test('$label: every syntax colour >= 4.5 vs its own background', () {
      final colors = <String, Color>{
        'commentColor': theme.commentColor,
        'stringColor': theme.stringColor,
        'numberColor': theme.numberColor,
        'keywordColor': theme.keywordColor,
        'typeColor': theme.typeColor,
        'functionColor': theme.functionColor,
        'annotationColor': theme.annotationColor,
        'punctuationColor': theme.punctuationColor,
      };
      for (final entry in colors.entries) {
        expect(
          contrastRatio(entry.value, theme.backgroundColor),
          greaterThanOrEqualTo(4.5),
          reason: '${entry.key} vs backgroundColor',
        );
      }
    });
  }

  group('CodeBlockTheme syntax contrast', () {
    checkSyntaxContrast('light', CodeBlockTheme.light());
    checkSyntaxContrast('dark', CodeBlockTheme.dark());
  });

  group('ChatTokens value tables', () {
    test('light matches DESIGN.md §3 exactly', () {
      const t = ChatTokens.light;
      expect(t.canvas, const Color(0xFFFBFBFA));
      expect(t.surface, const Color(0xFFFFFFFF));
      expect(t.surfaceSunken, const Color(0xFFF3F3F1));
      expect(t.userBubble, const Color(0xFFEFEFEC));
      expect(t.border, const Color(0xFFE4E4E2));
      expect(t.borderStrong, const Color(0xFF85858D));
      expect(t.textPrimary, const Color(0xFF18181B));
      expect(t.textSecondary, const Color(0xFF52525B));
      expect(t.textTertiary, const Color(0xFF6B6B73));
      expect(t.ink, const Color(0xFF18181B));
      expect(t.onInk, const Color(0xFFFBFBFA));
      expect(t.danger, const Color(0xFFC4321C));
      expect(t.inlineCodeBg, const Color(0xFFEEEEEB));
      expect(t.codeBg, const Color(0xFFF6F6F4));
      expect(t.codeBorder, const Color(0xFFE4E4E2));
    });

    test('dark matches DESIGN.md §3 exactly', () {
      const t = ChatTokens.dark;
      expect(t.canvas, const Color(0xFF111113));
      expect(t.surface, const Color(0xFF18181B));
      expect(t.surfaceSunken, const Color(0xFF1C1C1F));
      expect(t.userBubble, const Color(0xFF26262A));
      expect(t.border, const Color(0xFF2A2A2F));
      expect(t.borderStrong, const Color(0xFF6A6A72));
      expect(t.textPrimary, const Color(0xFFEDEDEF));
      expect(t.textSecondary, const Color(0xFFA8A8B0));
      expect(t.textTertiary, const Color(0xFF8C8C94));
      expect(t.ink, const Color(0xFFEDEDEF));
      expect(t.onInk, const Color(0xFF111113));
      expect(t.danger, const Color(0xFFFF7A66));
      expect(t.inlineCodeBg, const Color(0xFF232327));
      expect(t.codeBg, const Color(0xFF161618));
      expect(t.codeBorder, const Color(0xFF2A2A2F));
    });
  });

  group('ChatSpace / ChatRadius / ChatLayout', () {
    test('spacing scale', () {
      expect(ChatSpace.s2, 2);
      expect(ChatSpace.s4, 4);
      expect(ChatSpace.s8, 8);
      expect(ChatSpace.s12, 12);
      expect(ChatSpace.s16, 16);
      expect(ChatSpace.s20, 20);
      expect(ChatSpace.s24, 24);
      expect(ChatSpace.s32, 32);
      expect(ChatSpace.s48, 48);
      expect(ChatSpace.s64, 64);
    });

    test('radius scale', () {
      expect(ChatRadius.inline, 4);
      expect(ChatRadius.sm, 8);
      expect(ChatRadius.md, 12);
      expect(ChatRadius.bubble, 20);
      expect(ChatRadius.composer, 24);
      expect(ChatRadius.tail, 6);
    });

    test('layout constraints', () {
      expect(ChatLayout.readingMaxWidth, 760);
      expect(ChatLayout.composerMaxWidth, 800);
      expect(ChatLayout.userBubbleMaxFraction, 0.8);
      expect(ChatLayout.userBubbleMaxWidth, 560);
    });
  });

  group('ChatMotion', () {
    test('duration tokens match DESIGN.md §7', () {
      expect(ChatMotion.press, const Duration(milliseconds: 100));
      expect(ChatMotion.fast, const Duration(milliseconds: 150));
      expect(ChatMotion.base, const Duration(milliseconds: 220));
      expect(ChatMotion.slow, const Duration(milliseconds: 320));
      expect(ChatMotion.sendMorph, const Duration(milliseconds: 160));
      expect(ChatMotion.streamFade, const Duration(milliseconds: 180));
      expect(ChatMotion.caretPulse, const Duration(milliseconds: 900));
      expect(ChatMotion.thinkingSweep, const Duration(milliseconds: 1600));
    });

    testWidgets('of() returns Duration.zero under reduced motion',
        (tester) async {
      late BuildContext capturedContext;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Builder(
            builder: (context) {
              capturedContext = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(ChatMotion.reduced(capturedContext), isTrue);
      expect(ChatMotion.of(capturedContext, ChatMotion.base), Duration.zero);
    });

    testWidgets('of() returns the given duration when motion is not reduced',
        (tester) async {
      late BuildContext capturedContext;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: false),
          child: Builder(
            builder: (context) {
              capturedContext = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(ChatMotion.reduced(capturedContext), isFalse);
      expect(
        ChatMotion.of(capturedContext, ChatMotion.base),
        ChatMotion.base,
      );
    });
  });

  group('ChatTokens.of', () {
    testWidgets('binds accent/onAccent to the host colorScheme',
        (tester) async {
      late BuildContext capturedContext;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF123456),
              onPrimary: Color(0xFFFEDCBA),
            ),
          ),
          home: Builder(
            builder: (context) {
              capturedContext = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      final tokens = ChatTokens.of(capturedContext);
      expect(tokens.accent, const Color(0xFF123456));
      expect(tokens.onAccent, const Color(0xFFFEDCBA));
      expect(tokens.canvas, ChatTokens.light.canvas);
    });

    testWidgets('resolves the dark token set under a dark theme',
        (tester) async {
      late BuildContext capturedContext;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: Brightness.dark),
          home: Builder(
            builder: (context) {
              capturedContext = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      final tokens = ChatTokens.of(capturedContext);
      expect(tokens.canvas, ChatTokens.dark.canvas);
    });
  });

  group('CodeBlockView header/copy target', () {
    testWidgets('header is 44 tall, copy hit target is >= 44x44, radius 12',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: CodeBlockView(code: 'final x = 1;', language: 'dart'),
            ),
          ),
        ),
      );

      final headerBox = tester
          .widgetList<SizedBox>(
            find.descendant(
              of: find.byType(CodeBlockView),
              matching: find.byType(SizedBox),
            ),
          )
          .firstWhere((box) => box.height == 44);
      expect(headerBox.height, 44);

      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      expect(iconButton.constraints?.minWidth, greaterThanOrEqualTo(44));
      expect(iconButton.constraints?.minHeight, greaterThanOrEqualTo(44));

      final container = tester
          .widgetList<Container>(
            find.descendant(
              of: find.byType(CodeBlockView),
              matching: find.byType(Container),
            ),
          )
          .firstWhere((c) => c.decoration is BoxDecoration);
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(12));
    });
  });
}
