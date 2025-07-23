import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'utils/test_utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Streaming Text and Markdown Tests', () {
    late ChatMessagesController controller;

    setUp(() {
      controller = TestUtils.createController();
    });

    testWidgets('Should render streaming text with animation',
        (WidgetTester tester) async {
      // Arrange: Create a streaming message
      final streamingMessage = TestUtils.generateAiMessage(
        text: 'This is a streaming text message',
        isStreaming: true,
      );
      controller.addMessage(streamingMessage);

      // Act: Render the chat widget with streaming enabled
      await tester.pumpWidget(
        TestUtils.createTestApp(
          controller: controller,
          enableAnimation: true,
          streamingDuration: const Duration(milliseconds: 30),
        ),
      );

      // Pump a few frames to allow animation to start
      await tester.pump(const Duration(milliseconds: 10));

      // Get the message text at the beginning of streaming
      // It should be partially visible or empty at the start
      final initialFrameFinder =
          find.text('This is a streaming text message', findRichText: true);

      // Wait for animation to complete
      await tester.pumpAndSettle();

      // Assert: The full text should be visible after animation completes
      expect(find.text('This is a streaming text message', findRichText: true),
          findsOneWidget);
    });

    testWidgets('Should render markdown content correctly',
        (WidgetTester tester) async {
      // Arrange: Create a message with markdown
      final markdownMessage = TestUtils.generateAiMessage(
        text: '''
# Header
- List item 1
- List item 2

```dart
void main() {
  print('Hello World');
}
```
''',
      );
      controller.addMessage(markdownMessage);

      // Act: Render the chat widget
      await tester.pumpWidget(
        TestUtils.createTestApp(
          controller: controller,
          enableMarkdownStreaming: true,
        ),
      );

      // Wait for rendering to complete
      await tester.pumpAndSettle();

      // Assert: Markdown elements should be rendered
      // Headers become text with specific styles in RichText
      expect(find.textContaining('Header', findRichText: true), findsOneWidget);

      // Lists and code blocks should have been rendered in some form
      expect(
          find.textContaining('List item', findRichText: true), findsWidgets);
      expect(find.textContaining('Hello World', findRichText: true),
          findsOneWidget);
    });

    testWidgets('Should update streaming text progressively',
        (WidgetTester tester) async {
      // Arrange: Create a streaming message with initial text
      final streamingMessage = TestUtils.generateAiMessage(
        text: 'Initial',
        isStreaming: true,
      );
      controller.addMessage(streamingMessage);

      // Act: Render the chat widget
      await tester.pumpWidget(
        TestUtils.createTestApp(
          controller: controller,
          enableAnimation: true,
          streamingDuration: const Duration(milliseconds: 50),
        ),
      );

      // Let initial text render
      await tester.pump(const Duration(milliseconds: 100));

      // Update the streaming message twice to simulate progressive updates
      // Create a new message with updated text but same other properties
      ChatMessage updatedMessage = ChatMessage(
        text: 'Initial text',
        user: streamingMessage.user,
        createdAt: streamingMessage.createdAt,
        customProperties: streamingMessage.customProperties,
      );
      controller.updateMessage(updatedMessage);

      await tester.pump(const Duration(milliseconds: 100));

      // Final update - remove streaming flag
      ChatMessage finalMessage = ChatMessage(
        text: 'Initial text has been completed',
        user: streamingMessage.user,
        createdAt: streamingMessage.createdAt,
        customProperties: null, // Remove streaming flag
      );
      controller.updateMessage(finalMessage);

      // Wait for all animations to complete
      await tester.pumpAndSettle();

      // Assert: Final text should be visible
      expect(find.text('Initial text has been completed', findRichText: true),
          findsOneWidget);
    });

    testWidgets('Should not animate streaming when disabled',
        (WidgetTester tester) async {
      // Arrange: Create a streaming message
      final streamingMessage = TestUtils.generateAiMessage(
        text: 'This should appear immediately without animation',
        isStreaming: true,
      );
      controller.addMessage(streamingMessage);

      // Act: Render the chat widget with streaming disabled
      await tester.pumpWidget(
        TestUtils.createTestApp(
          controller: controller,
          enableAnimation: false, // Disable animation
        ),
      );

      // Pump a single frame
      await tester.pump();

      // Assert: The full text should be visible immediately
      expect(
        find.text('This should appear immediately without animation',
            findRichText: true),
        findsOneWidget,
      );
    });
  });
}
