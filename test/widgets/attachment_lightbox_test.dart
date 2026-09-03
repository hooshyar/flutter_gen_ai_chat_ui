import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';

/// task-008: built-in lightbox/preview for image attachments.
void main() {
  const images = [
    ChatMedia(
      url: 'https://example.com/one.png',
      type: ChatMediaType.image,
      fileName: 'one.png',
    ),
    ChatMedia(
      url: 'https://example.com/two.png',
      type: ChatMediaType.image,
      fileName: 'two.png',
    ),
    ChatMedia(
      url: 'https://example.com/three.png',
      type: ChatMediaType.image,
      fileName: 'three.png',
    ),
  ];

  Future<void> pumpOpener(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => AttachmentLightbox.show(context,
                  images: images, initialIndex: 1),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('show() opens at the requested initial index', (tester) async {
    await pumpOpener(tester);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byType(AttachmentLightbox), findsOneWidget);
    expect(find.text('two.png'), findsOneWidget);
    expect(find.text('2 / 3'), findsOneWidget);
  });

  testWidgets('the close button dismisses the lightbox', (tester) async {
    await pumpOpener(tester);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(AttachmentLightbox), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.byType(AttachmentLightbox), findsNothing);
  });

  testWidgets('tapping the scrim outside the image dismisses the lightbox',
      (tester) async {
    await pumpOpener(tester);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(AttachmentLightbox), findsOneWidget);

    // Tap near the very top-left corner — outside the InteractiveViewer's
    // centered image content but still inside the full-screen scrim.
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    expect(find.byType(AttachmentLightbox), findsNothing);
  });

  testWidgets('swiping to the next page updates the page indicator',
      (tester) async {
    await pumpOpener(tester);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('2 / 3'), findsOneWidget);

    await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
    await tester.pumpAndSettle();

    expect(find.text('3 / 3'), findsOneWidget);
    expect(find.text('three.png'), findsOneWidget);
  });

  testWidgets('a single image does not render a page indicator',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => AttachmentLightbox.show(
                context,
                images: [images.first],
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byType(AttachmentLightbox), findsOneWidget);
    expect(find.textContaining(' / '), findsNothing);
  });
}
