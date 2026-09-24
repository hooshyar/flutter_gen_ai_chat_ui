import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';
import 'package:flutter_gen_ai_chat_ui_example/home_screen.dart';
import 'package:flutter_gen_ai_chat_ui_example/shell/app_theme.dart';

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
