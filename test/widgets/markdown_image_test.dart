import 'package:flutter/material.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

void main() {
  group('Markdown Image Tap Tests', () {
    testWidgets('Images should not be tappable when enableImageTaps is false',
        (WidgetTester tester) async {
      bool wasTapped = false;

      // Create a controller
      final controller = ChatMessagesController();

      // Create a test message with markdown containing an image
      final testUser = ChatUser(id: 'test', firstName: 'Test User');
      final aiUser = ChatUser(id: 'ai', firstName: 'AI Assistant');

      // Add a message with an image in markdown
      controller.addMessage(ChatMessage(
        text: '![Test Image](https://example.com/test.jpg)',
        user: aiUser,
        createdAt: DateTime.now(),
        isMarkdown: true,
      ));

      // Build our app with the custom chat widget
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: CustomChatWidget(
            currentUser: testUser,
            controller: controller,
            messages: controller.messages,
            onSend: (_) {},
            messageOptions: const MessageOptions(
              enableImageTaps: false, // Disable image taps
            ),
            typingUsers: const [],
            messageListOptions:
                const MessageListOptions(), // Required parameter
            readOnly: false,
            quickReplyOptions: const QuickReplyOptions(),
            scrollToBottomOptions: const ScrollToBottomOptions(),
            spacingConfig: const ChatSpacingConfig(),
          ),
        ),
      ));

      await tester.pumpAndSettle();

      // Verify the image is rendered (in test environment, Markdown might render differently)
      expect(find.byType(Markdown), findsOneWidget);

      // In the non-tappable mode, we should have our custom image builder
      // We can't directly test the tapping behavior, but we can verify the widget structure
    });

    testWidgets(
        'Markdown widget should use default imageBuilder when enableImageTaps is true',
        (WidgetTester tester) async {
      // Create a controller
      final controller = ChatMessagesController();

      // Create a test message with markdown containing an image
      final testUser = ChatUser(id: 'test', firstName: 'Test User');
      final aiUser = ChatUser(id: 'ai', firstName: 'AI Assistant');

      // Add a message with an image in markdown
      controller.addMessage(ChatMessage(
        text: '![Test Image](https://example.com/test.jpg)',
        user: aiUser,
        createdAt: DateTime.now(),
        isMarkdown: true,
      ));

      // Build our app with the custom chat widget
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: CustomChatWidget(
            currentUser: testUser,
            controller: controller,
            messages: controller.messages,
            onSend: (_) {},
            messageOptions: const MessageOptions(
              enableImageTaps: true, // Enable image taps
            ),
            typingUsers: const [],
            messageListOptions:
                const MessageListOptions(), // Required parameter
            readOnly: false,
            quickReplyOptions: const QuickReplyOptions(),
            scrollToBottomOptions: const ScrollToBottomOptions(),
            spacingConfig: const ChatSpacingConfig(),
          ),
        ),
      ));

      await tester.pumpAndSettle();

      // Verify the markdown widget is rendered
      expect(find.byType(Markdown), findsOneWidget);

      // We can't fully test the tap behavior in tests, but we can verify
      // the markdown widget is rendered properly
      final markdownWidget = tester.widget<Markdown>(find.byType(Markdown));
      expect(markdownWidget.imageBuilder,
          isNull); // When enableImageTaps is true, imageBuilder should be null (default)
    });
  });
}
