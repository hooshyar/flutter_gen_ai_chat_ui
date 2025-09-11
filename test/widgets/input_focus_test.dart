import 'package:flutter/material.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Input Focus Tests', () {
    late ChatMessagesController controller;
    late ChatUser currentUser;
    late ChatUser aiUser;

    setUp(() {
      controller = ChatMessagesController();
      currentUser = ChatUser(id: 'user1', firstName: 'User');
      aiUser = ChatUser(id: 'ai', firstName: 'AI');
    });

    testWidgets('Should support autofocus when enabled in InputOptions',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AiChatWidget(
              currentUser: currentUser,
              aiUser: aiUser,
              controller: controller,
              onSendMessage: (message) {},
              inputOptions: const InputOptions(
                autofocus: true,
              ),
            ),
          ),
        ),
      );

      // Wait for the widget to build
      await tester.pump();

      // Act & Assert
      // Find the TextField and check if it has focus
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);
      
      final textFieldWidget = tester.widget<TextField>(textField);
      expect(textFieldWidget.autofocus, isTrue);
    });

    testWidgets('Should not autofocus by default',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AiChatWidget(
              currentUser: currentUser,
              aiUser: aiUser,
              controller: controller,
              onSendMessage: (message) {},
              // No InputOptions provided, should use defaults
            ),
          ),
        ),
      );

      // Wait for the widget to build
      await tester.pump();

      // Act & Assert
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);
      
      final textFieldWidget = tester.widget<TextField>(textField);
      expect(textFieldWidget.autofocus, isFalse);
    });

    testWidgets('Should use custom FocusNode when provided',
        (WidgetTester tester) async {
      // Arrange
      final customFocusNode = FocusNode();
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AiChatWidget(
              currentUser: currentUser,
              aiUser: aiUser,
              controller: controller,
              onSendMessage: (message) {},
              inputOptions: InputOptions(
                focusNode: customFocusNode,
              ),
            ),
          ),
        ),
      );

      // Wait for the widget to build
      await tester.pump();

      // Act & Assert
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);
      
      final textFieldWidget = tester.widget<TextField>(textField);
      expect(textFieldWidget.focusNode, equals(customFocusNode));
      
      // Clean up
      customFocusNode.dispose();
    });

    testWidgets('Should support autofocus in minimal InputOptions',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AiChatWidget(
              currentUser: currentUser,
              aiUser: aiUser,
              controller: controller,
              onSendMessage: (message) {},
              inputOptions: InputOptions.minimal(
                autofocus: true,
                hintText: 'Type a message...',
              ),
            ),
          ),
        ),
      );

      // Wait for the widget to build
      await tester.pump();

      // Act & Assert
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);
      
      final textFieldWidget = tester.widget<TextField>(textField);
      expect(textFieldWidget.autofocus, isTrue);
    });

    testWidgets('Should support autofocus in glassmorphic InputOptions',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AiChatWidget(
              currentUser: currentUser,
              aiUser: aiUser,
              controller: controller,
              onSendMessage: (message) {},
              inputOptions: InputOptions.glassmorphic(
                autofocus: true,
                hintText: 'Type a message...',
              ),
            ),
          ),
        ),
      );

      // Wait for the widget to build
      await tester.pump();

      // Act & Assert
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);
      
      final textFieldWidget = tester.widget<TextField>(textField);
      expect(textFieldWidget.autofocus, isTrue);
    });

    testWidgets('Should support custom FocusNode in factory constructors',
        (WidgetTester tester) async {
      // Arrange
      final customFocusNode = FocusNode();
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AiChatWidget(
              currentUser: currentUser,
              aiUser: aiUser,
              controller: controller,
              onSendMessage: (message) {},
              inputOptions: InputOptions.glassmorphic(
                focusNode: customFocusNode,
                hintText: 'Type a message...',
              ),
            ),
          ),
        ),
      );

      // Wait for the widget to build
      await tester.pump();

      // Act & Assert
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);
      
      final textFieldWidget = tester.widget<TextField>(textField);
      expect(textFieldWidget.focusNode, equals(customFocusNode));
      
      // Clean up
      customFocusNode.dispose();
    });
  });
}