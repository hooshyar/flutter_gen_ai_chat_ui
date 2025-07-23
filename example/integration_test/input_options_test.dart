import 'package:flutter/material.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'utils/test_utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Input Field Customization Tests', () {
    late ChatMessagesController controller;

    setUp(() {
      controller = TestUtils.createController();
    });

    testWidgets('Should apply custom input decoration',
        (WidgetTester tester) async {
      // Arrange: Create widget with custom input decoration
      const inputOptions = InputOptions(
        decoration: InputDecoration(
          hintText: 'Type a custom message...',
          border: OutlineInputBorder(),
          fillColor: Colors.grey,
          filled: true,
        ),
      );

      // Act: Render the chat widget
      await tester.pumpWidget(
        TestUtils.createTestApp(
          controller: controller,
          config: config,
        ),
      );

      // Assert: Custom decoration should be applied
      final textField =
          tester.widget<TextField>(TestUtils.findChatInputField());
      expect(textField.decoration?.hintText, 'Type a custom message...');
      expect(textField.decoration?.border, isA<OutlineInputBorder>());
      expect(textField.decoration?.fillColor, Colors.grey);
      expect(textField.decoration?.filled, true);
    });

    testWidgets('Should apply custom text style to input field',
        (WidgetTester tester) async {
      // Arrange: Create config with custom text style
      const config = AiChatConfig(
        inputOptions: InputOptions(
          textStyle: const TextStyle(
            color: Colors.blue,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

      // Act: Render the chat widget
      await tester.pumpWidget(
        TestUtils.createTestApp(
          controller: controller,
          config: config,
        ),
      );

      // Assert: Custom text style should be applied
      final textField =
          tester.widget<TextField>(TestUtils.findChatInputField());
      expect(textField.style?.color, Colors.blue);
      expect(textField.style?.fontSize, 18);
      expect(textField.style?.fontWeight, FontWeight.bold);
    });

    testWidgets('Should use custom send button builder',
        (WidgetTester tester) async {
      // Arrange: Create config with custom send button builder
      final config = AiChatConfig(
        inputOptions: InputOptions(
          sendButtonBuilder: (onSend) => IconButton(
            icon: const Icon(Icons.send_rounded, color: Colors.red),
            onPressed: onSend,
          ),
        ),
      );

      // Act: Render the chat widget
      await tester.pumpWidget(
        TestUtils.createTestApp(
          controller: controller,
          config: config,
        ),
      );

      // Assert: Custom send button should be visible
      expect(find.byIcon(Icons.send_rounded), findsOneWidget);

      // The color should be red (this is a bit tricky to test in widget tests)
      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      expect(iconButton.icon, isA<Icon>());
      final icon = iconButton.icon as Icon;
      expect(icon.color, Colors.red);
    });

    testWidgets('Should respect maxLines setting', (WidgetTester tester) async {
      // Arrange: Create config with maxLines set
      const config = AiChatConfig(
        inputOptions: const InputOptions(
          maxLines: 3,
        ),
      );

      // Act: Render the chat widget
      await tester.pumpWidget(
        TestUtils.createTestApp(
          controller: controller,
          config: config,
        ),
      );

      // Assert: TextField should have maxLines set to 3
      final textField =
          tester.widget<TextField>(TestUtils.findChatInputField());
      expect(textField.maxLines, 3);
    });

    testWidgets('Should apply custom container decoration',
        (WidgetTester tester) async {
      // Arrange: Create config with custom container decoration
      final config = AiChatConfig(
        inputOptions: InputOptions(
          containerDecoration: BoxDecoration(
            color: Colors.amber.withOpacityCompat(0.2),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacityCompat(0.1),
                blurRadius: 10,
              ),
            ],
          ),
        ),
      );

      // Act: Render the chat widget
      await tester.pumpWidget(
        TestUtils.createTestApp(
          controller: controller,
          config: config,
        ),
      );

      // Assert: Container with custom decoration should exist
      // This is a bit tricky to test directly, so we'll check for a Container with BoxDecoration
      final containers = tester.widgetList<Container>(find.byType(Container));
      bool foundMatchingContainer = false;

      for (final container in containers) {
        if (container.decoration is BoxDecoration) {
          final decoration = container.decoration as BoxDecoration;
          if (decoration.color == Colors.amber.withOpacityCompat(0.2) &&
              decoration.borderRadius == BorderRadius.circular(20)) {
            foundMatchingContainer = true;
            break;
          }
        }
      }

      expect(foundMatchingContainer, true);
    });

    testWidgets('Should use glassmorphic factory-created InputOptions',
        (WidgetTester tester) async {
      // Arrange: Create config with glassmorphic input options
      final config = AiChatConfig(
        inputOptions: InputOptions.glassmorphic(
          colors: [
            Colors.blue.withOpacityCompat(0.3),
            Colors.blue.withOpacityCompat(0.2)
          ],
          borderRadius: 25,
          blurStrength: 10,
          hintText: 'Type a message...',
        ),
      );

      // Act: Render the chat widget
      await tester.pumpWidget(
        TestUtils.createTestApp(
          controller: controller,
          config: config,
        ),
      );

      // Assert: Should have TextField and BackdropFilter for the blur effect
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(BackdropFilter), findsAtLeastNWidgets(1));
    });
  });
}
