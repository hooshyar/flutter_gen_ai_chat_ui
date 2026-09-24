import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';
import 'package:flutter_gen_ai_chat_ui_example/examples/streaming_chat.dart';

void main() {
  // Tall surface so every code block in the long reply is built at once
  // instead of lazily as the list scrolls.
  void useTallSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(1400, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  // Sends "Same function in Dart, Python and TypeScript" via the toolbar
  // shortcut and waits for the streamed reply to finish.
  Future<void> sendMultiLanguagePrompt(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.language));
    await tester.pump();
    await tester.pumpAndSettle(const Duration(seconds: 30));
  }

  List<TextSpan> codeSpans(WidgetTester tester) => tester
      .widgetList<Text>(find.descendant(
        of: find.byType(CodeBlockView),
        matching: find.byType(Text),
      ))
      .map((t) => t.textSpan)
      .whereType<TextSpan>()
      .toList();

  testWidgets('multi-language reply renders one copy button per code block',
      (tester) async {
    useTallSurface(tester);
    await tester.pumpWidget(const MaterialApp(home: StreamingChatExample()));
    await tester.pump();

    await sendMultiLanguagePrompt(tester);

    // dart, python, ts, bash, yaml + one fence with no language tag.
    expect(find.byType(CodeBlockView), findsNWidgets(6));
    expect(find.byTooltip('Copy code'), findsNWidgets(6));

    // Highlighted: at least one block mixes token colours.
    expect(codeSpans(tester).any(_hasMultipleColors), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('toggling syntax highlighting off renders single-colour code',
      (tester) async {
    useTallSurface(tester);
    await tester.pumpWidget(const MaterialApp(home: StreamingChatExample()));
    await tester.pump();

    // Toggle off before the reply renders — flutter_markdown_plus caches a
    // message's built children, so the flag only affects newly-rendered
    // messages.
    await tester.tap(find.byTooltip('Syntax highlighting'));
    await tester.pump();
    expect(find.byIcon(Icons.code_off), findsOneWidget);

    await sendMultiLanguagePrompt(tester);

    // Every code block renders as a single span in one colour — the
    // effective base style, not per-token colours.
    final spans = codeSpans(tester);
    expect(spans, hasLength(6));
    for (final span in spans) {
      expect(_spanColors(span), hasLength(1));
    }
    expect(find.byTooltip('Copy code'), findsNWidgets(6));
    expect(tester.takeException(), isNull);
  });
}

Set<Color> _spanColors(InlineSpan span) {
  final colors = <Color>{};
  if (span is TextSpan) {
    final color = span.style?.color;
    if (color != null) colors.add(color);
    for (final child in span.children ?? const <InlineSpan>[]) {
      colors.addAll(_spanColors(child));
    }
  }
  return colors;
}

bool _hasMultipleColors(InlineSpan span) => _spanColors(span).length > 1;
