import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';

/// task-008: built-in lightbox wiring + per-file upload progress overlay.
/// `MessageAttachment`'s existing behavior (a null `onTap` with the
/// built-in lightbox disabled does nothing on tap) is preserved exactly —
/// both new features are opt-in via new, defaulted-off parameters.
void main() {
  const image = ChatMedia(
    url: 'https://example.com/photo.png',
    type: ChatMediaType.image,
    fileName: 'photo.png',
  );

  Future<void> pump(WidgetTester tester, Widget attachment) {
    return tester.pumpWidget(
      MaterialApp(home: Scaffold(body: attachment)),
    );
  }

  group('built-in lightbox opt-in', () {
    testWidgets(
        'tapping does nothing when enableBuiltInLightbox is false and no '
        'onTap is set (default, unchanged behavior)', (tester) async {
      await pump(tester, const MessageAttachment(media: image));
      await tester.tap(find.byType(MessageAttachment));
      await tester.pumpAndSettle();

      expect(find.byType(AttachmentLightbox), findsNothing);
    });

    testWidgets('tapping opens the built-in lightbox when enabled',
        (tester) async {
      await pump(
        tester,
        const MessageAttachment(media: image, enableBuiltInLightbox: true),
      );
      await tester.tap(find.byType(MessageAttachment));
      await tester.pumpAndSettle();

      expect(find.byType(AttachmentLightbox), findsOneWidget);
    });

    testWidgets(
        'an explicit onTap always takes precedence over the '
        'built-in lightbox', (tester) async {
      ChatMedia? tapped;
      await pump(
        tester,
        MessageAttachment(
          media: image,
          enableBuiltInLightbox: true,
          onTap: (m) => tapped = m,
        ),
      );
      await tester.tap(find.byType(MessageAttachment));
      await tester.pumpAndSettle();

      expect(tapped, image);
      expect(find.byType(AttachmentLightbox), findsNothing);
    });

    testWidgets(
        'the lightbox pages through siblingMedia, not just the '
        'tapped image', (tester) async {
      const second = ChatMedia(
        url: 'https://example.com/photo2.png',
        type: ChatMediaType.image,
        fileName: 'photo2.png',
      );
      await pump(
        tester,
        const MessageAttachment(
          media: image,
          enableBuiltInLightbox: true,
          siblingMedia: [image, second],
        ),
      );
      await tester.tap(find.byType(MessageAttachment));
      await tester.pumpAndSettle();

      expect(find.byType(AttachmentLightbox), findsOneWidget);
      expect(find.text('1 / 2'), findsOneWidget);
    });

    testWidgets(
        'non-image siblingMedia entries are excluded from the '
        'lightbox gallery', (tester) async {
      const doc = ChatMedia(
        url: 'https://example.com/doc.pdf',
        type: ChatMediaType.document,
        fileName: 'doc.pdf',
      );
      await pump(
        tester,
        const MessageAttachment(
          media: image,
          enableBuiltInLightbox: true,
          siblingMedia: [image, doc],
        ),
      );
      await tester.tap(find.byType(MessageAttachment));
      await tester.pumpAndSettle();

      // Only the one image counts — no page indicator for a single image.
      expect(find.byType(AttachmentLightbox), findsOneWidget);
      expect(find.textContaining(' / '), findsNothing);
    });
  });

  group('upload progress overlay', () {
    testWidgets('no overlay when uploadProgress is null (default)',
        (tester) async {
      await pump(tester, const MessageAttachment(media: image));
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows a percentage overlay while uploadProgress is below 1.0',
        (tester) async {
      const uploading = ChatMedia(
        url: 'https://example.com/photo.png',
        type: ChatMediaType.image,
        uploadProgress: 0.42,
      );
      await pump(tester, const MessageAttachment(media: uploading));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('42%'), findsOneWidget);
    });

    testWidgets('the overlay disappears once uploadProgress reaches 1.0',
        (tester) async {
      const uploading = ChatMedia(
        url: 'https://example.com/photo.png',
        type: ChatMediaType.image,
        uploadProgress: 0.9,
      );
      await pump(tester, const MessageAttachment(media: uploading));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Simulate the controller-driven progress update that completes the
      // upload — a fresh ChatMedia (immutable), matching how a consumer
      // would updateMessage(...) with the same media at progress 1.0.
      const done = ChatMedia(
        url: 'https://example.com/photo.png',
        type: ChatMediaType.image,
        uploadProgress: 1.0,
      );
      await pump(tester, const MessageAttachment(media: done));

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('a non-image attachment also renders the progress overlay',
        (tester) async {
      const uploadingDoc = ChatMedia(
        url: 'https://example.com/report.pdf',
        type: ChatMediaType.document,
        fileName: 'report.pdf',
        uploadProgress: 0.1,
      );
      await pump(tester, const MessageAttachment(media: uploadingDoc));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('10%'), findsOneWidget);
    });
  });

  group('end-to-end wiring through AiChatWidget', () {
    testWidgets(
        'MessageOptions.enableAttachmentLightbox reaches a real chat message',
        (tester) async {
      const testUser = ChatUser(id: 'user', name: 'Test User');
      const aiUser = ChatUser(id: 'ai', name: 'AI Assistant');
      final controller = ChatMessagesController(
        initialMessages: [
          ChatMessage(
            text: 'here is a photo',
            user: aiUser,
            createdAt: DateTime.now(),
            media: const [image],
          ),
        ],
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: AiChatWidget(
              currentUser: testUser,
              aiUser: aiUser,
              controller: controller,
              onSendMessage: (_) async {},
              messageOptions: const MessageOptions(
                enableImageTaps: true,
                enableAttachmentLightbox: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(MessageAttachment));
      await tester.pumpAndSettle();

      expect(find.byType(AttachmentLightbox), findsOneWidget);
    });
  });
}
