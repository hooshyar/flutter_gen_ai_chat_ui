import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';
import 'package:flutter_gen_ai_chat_ui/src/widgets/chrome/thinking_indicator.dart';

/// Slice D3: pre-first-token "Thinking" state (`DESIGN.md` §8.7).
void main() {
  late ChatMessagesController controller;
  late ChatUser testUser;
  late ChatUser aiUser;

  setUp(() {
    controller = ChatMessagesController();
    testUser = const ChatUser(id: 'user', name: 'Test User');
    aiUser = const ChatUser(id: 'ai', name: 'AI Assistant');
  });

  tearDown(() => controller.dispose());

  testWidgets('"Thinking" is present while loading with no AI text', (
    tester,
  ) async {
    controller.addMessage(ChatMessage.loading(user: aiUser, id: 'loading-1'));

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: AiChatWidget(
            currentUser: testUser,
            aiUser: aiUser,
            controller: controller,
            onSendMessage: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Thinking'), findsOneWidget);
  });

  testWidgets('reduced motion collapses the thinking sweep to a static frame', (
    tester,
  ) async {
    controller.addMessage(ChatMessage.loading(user: aiUser, id: 'loading-1'));

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: Material(
          child: AiChatWidget(
            currentUser: testUser,
            aiUser: aiUser,
            controller: controller,
            onSendMessage: (_) {},
          ),
        ),
      ),
    );

    // pumpAndSettle throws if a repeating animation is still ticking, so
    // this is the load-bearing assertion: no running animation remains.
    await tester.pumpAndSettle();

    expect(find.text('Thinking'), findsOneWidget);
  });

  testWidgets(
    'the "Thinking" Text widget itself always carries a full-opacity '
    'textSecondary color (the sweep only recolors pixels via ShaderMask, '
    'never dims the underlying label style)',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Material(child: ThinkingIndicator())),
      );
      await tester.pump();

      final texts = tester.widgetList<Text>(find.text('Thinking'));
      for (final text in texts) {
        final color = text.style?.color;
        expect(color, isNotNull);
        expect(color!.a, 1.0);
      }

      // Let the repeating sweep run a bit, then check again — the
      // underlying Text's own style never changes; only the ShaderMask
      // recolors its painted pixels.
      await tester.pump(const Duration(milliseconds: 400));
      final textsMidSweep = tester.widgetList<Text>(find.text('Thinking'));
      for (final text in textsMidSweep) {
        expect(text.style?.color?.a, 1.0);
      }
    },
  );

  group('sweep gradient never fades below the resting textSecondary color', () {
    // Mirrors the exact formula in `_ThinkingIndicatorState.build`'s
    // `ShaderMask`/`LinearGradient`: a 3-stop gradient (secondary, primary,
    // secondary) whose begin/end alignment slides across the label as the
    // controller repeats, clamped outside its own span.
    double dxFor(double t) => -1.0 + 3.0 * t;

    /// The gradient's own parametric fraction (0..1, clamped past the
    /// ends) sampled at widget-local x (-1..1) and animation time t.
    double fractionAt(double t, double localX) {
      final dx = dxFor(t);
      final beginX = dx - 1;
      final endX = dx + 1;
      final fraction = (localX - beginX) / (endX - beginX);
      return fraction.clamp(0.0, 1.0);
    }

    Color colorAtFraction(double fraction, Color secondary, Color primary) {
      if (fraction <= 0.5) {
        return Color.lerp(secondary, primary, fraction / 0.5)!;
      }
      return Color.lerp(primary, secondary, (fraction - 0.5) / 0.5)!;
    }

    void assertNeverBelowSecondary(Color secondary, Color primary) {
      // Sample densely across the whole animation cycle and the whole
      // label width: every resulting colour's channels must lie between
      // `secondary`'s and `primary`'s (inclusive) — i.e. the label can only
      // brighten toward `primary`, never dim past `secondary`.
      for (var ti = 0; ti <= 40; ti++) {
        final t = ti / 40;
        for (var xi = 0; xi <= 20; xi++) {
          final localX = -1.0 + (xi / 20) * 2.0;
          final fraction = fractionAt(t, localX);
          final color = colorAtFraction(fraction, secondary, primary);

          final loR = min(secondary.r, primary.r);
          final hiR = max(secondary.r, primary.r);
          final loG = min(secondary.g, primary.g);
          final hiG = max(secondary.g, primary.g);
          final loB = min(secondary.b, primary.b);
          final hiB = max(secondary.b, primary.b);

          expect(color.r, inInclusiveRange(loR - 0.001, hiR + 0.001));
          expect(color.g, inInclusiveRange(loG - 0.001, hiG + 0.001));
          expect(color.b, inInclusiveRange(loB - 0.001, hiB + 0.001));
          expect(color.a, 1.0);
        }
      }
    }

    test('light tokens', () {
      const tokens = ChatTokens.light;
      assertNeverBelowSecondary(tokens.textSecondary, tokens.textPrimary);
    });

    test('dark tokens', () {
      const tokens = ChatTokens.dark;
      assertNeverBelowSecondary(tokens.textSecondary, tokens.textPrimary);
    });
  });
}
