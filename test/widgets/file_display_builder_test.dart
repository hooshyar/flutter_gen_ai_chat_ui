// Regression test for issue #40: FileUploadOptions.fileDisplayBuilder was
// declared on the model but never consumed by the render tree, so customizing
// how media attachments appear in a message had no effect. The builder is now
// threaded AiChatWidget -> CustomChatWidget -> MessageAttachment.customBuilder.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';

void main() {
  testWidgets(
    'fileDisplayBuilder renders custom media widget inside a message (#40)',
    (tester) async {
      final controller = ChatMessagesController(
        initialMessages: [
          ChatMessage(
            text: 'here is an image',
            user: const ChatUser(id: 'ai', firstName: 'AI'),
            createdAt: DateTime.now(),
            media: const [
              ChatMedia(
                url: 'https://example.com/photo.png',
              ),
            ],
          ),
        ],
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AiChatWidget(
              currentUser: const ChatUser(id: 'u', firstName: 'U'),
              aiUser: const ChatUser(id: 'ai', firstName: 'AI'),
              controller: controller,
              onSendMessage: (_) {},
              fileUploadOptions: FileUploadOptions(
                fileDisplayBuilder: (context, media) => Text(
                  'custom:${media.url}',
                  key: const Key('custom_media'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // The consumer's builder must be used to render the attachment. Before the
      // fix this never fired and the default Image.network renderer was used.
      expect(find.byKey(const Key('custom_media')), findsOneWidget);
      expect(
        find.text('custom:https://example.com/photo.png'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'without fileDisplayBuilder the default attachment renderer is used',
    (tester) async {
      final controller = ChatMessagesController(
        initialMessages: [
          ChatMessage(
            text: 'a document',
            user: const ChatUser(id: 'ai', firstName: 'AI'),
            createdAt: DateTime.now(),
            media: const [
              ChatMedia(
                url: 'https://example.com/report.pdf',
                type: ChatMediaType.document,
                fileName: 'report.pdf',
                extension: 'pdf',
              ),
            ],
          ),
        ],
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AiChatWidget(
              currentUser: const ChatUser(id: 'u', firstName: 'U'),
              aiUser: const ChatUser(id: 'ai', firstName: 'AI'),
              controller: controller,
              onSendMessage: (_) {},
            ),
          ),
        ),
      );
      await tester.pump();

      // Default document renderer shows the file name; no custom widget exists.
      expect(find.text('report.pdf'), findsOneWidget);
      expect(find.byKey(const Key('custom_media')), findsNothing);
    },
  );
}
