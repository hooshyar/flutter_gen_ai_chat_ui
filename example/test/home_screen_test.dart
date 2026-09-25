import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';
import 'package:flutter_gen_ai_chat_ui_example/home_screen.dart';
import 'package:flutter_gen_ai_chat_ui_example/shell/app_theme.dart';
import 'package:flutter_gen_ai_chat_ui_example/shell/live_preview.dart';

void setSurfaceSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget buildHome({ThemeMode themeMode = ThemeMode.light}) {
  return MaterialApp(
    theme: AppTheme.light(),
    darkTheme: AppTheme.dark(),
    themeMode: themeMode,
    home: HomeScreen(onToggleTheme: () {}),
    routes: {
      '/streaming': (_) =>
          const Scaffold(body: Center(child: Text('Streaming demo'))),
    },
  );
}

/// Pumps until the [LivePreview]'s scripted auto-play stream finishes, so no
/// timers are left pending when the test ends.
Future<void> settleLivePreview(WidgetTester tester) async {
  await tester.pumpAndSettle(const Duration(seconds: 10));
}

void main() {
  testWidgets(
      'wide viewport: headline and live preview render inside the viewport',
      (tester) async {
    setSurfaceSize(tester, const Size(1280, 800));

    await tester.pumpWidget(buildHome());
    await settleLivePreview(tester);

    expect(find.text('Chat UI for Flutter AI apps'), findsOneWidget);

    final previewRect = tester.getRect(find.byType(AiChatWidget));
    expect(previewRect.left, greaterThanOrEqualTo(0));
    expect(previewRect.top, greaterThanOrEqualTo(0));
    expect(previewRect.right, lessThanOrEqualTo(1280));
    expect(previewRect.bottom, lessThanOrEqualTo(800));

    expect(tester.takeException(), isNull);
  });

  testWidgets('phone viewport: install command is visible without scrolling',
      (tester) async {
    setSurfaceSize(tester, const Size(390, 844));

    await tester.pumpWidget(buildHome());
    await settleLivePreview(tester);

    expect(
      find.text('flutter pub add flutter_gen_ai_chat_ui'),
      findsOneWidget,
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('demo index renders 4 groups and 8 rows', (tester) async {
    setSurfaceSize(tester, const Size(1280, 2000));

    await tester.pumpWidget(buildHome());
    await settleLivePreview(tester);

    expect(find.byType(DemoGroupSection), findsNWidgets(4));
    expect(find.byType(DemoIndexRow), findsNWidgets(8));
    expect(find.text('Core'), findsOneWidget);
    expect(find.text('Agents'), findsOneWidget);
    expect(find.text('Input'), findsOneWidget);
    expect(find.text('Global'), findsOneWidget);
  });

  testWidgets('tapping Streaming pushes the /streaming route', (tester) async {
    setSurfaceSize(tester, const Size(1280, 2000));

    await tester.pumpWidget(buildHome());
    await settleLivePreview(tester);

    await tester.tap(find.text('Streaming'));
    await tester.pumpAndSettle(const Duration(seconds: 10));

    expect(find.text('Streaming demo'), findsOneWidget);
  });

  testWidgets(
      'live preview keeps its finished state across the 1024 breakpoint '
      'resize instead of replaying', (tester) async {
    setSurfaceSize(tester, const Size(1280, 800));

    await tester.pumpWidget(buildHome());
    await settleLivePreview(tester);

    // The scripted exchange has finished: the question appears once and
    // there is no stop button (which only shows while a reply streams).
    expect(find.text('Write a debounce helper in Dart'), findsOneWidget);
    expect(find.byIcon(Icons.stop_rounded), findsNothing);

    // Cross the split-hero breakpoint downward - the Row/Column swap would
    // recreate LivePreview's State (and replay the script) without a
    // GlobalKey preserving it across the rebuild.
    //
    // Capture the State object itself before resizing: a 10s pumpAndSettle
    // alone can't tell "preserved" from "replayed", since a fast replay of
    // the scripted exchange settles into the exact same visible text and
    // icons within that window. Checking object identity right after a
    // SINGLE pump - not a full settle - is the precise signal: a
    // recreated State is a different instance immediately, before any
    // replay has had time to run at all.
    final stateBeforeResize = tester.state(find.byType(LivePreview));
    setSurfaceSize(tester, const Size(390, 844));
    await tester.pump();

    expect(
      identical(stateBeforeResize, tester.state(find.byType(LivePreview))),
      isTrue,
      reason: 'LivePreview\'s State must survive the breakpoint resize, not '
          'be torn down and recreated (which would replay the script)',
    );

    await tester.pumpAndSettle(const Duration(seconds: 10));

    expect(find.text('Write a debounce helper in Dart'), findsOneWidget);
    expect(find.byIcon(Icons.stop_rounded), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders without exceptions in light and dark', (tester) async {
    setSurfaceSize(tester, const Size(1280, 900));

    await tester.pumpWidget(buildHome(themeMode: ThemeMode.light));
    await settleLivePreview(tester);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(buildHome(themeMode: ThemeMode.dark));
    await settleLivePreview(tester);
    expect(tester.takeException(), isNull);
  });
}
