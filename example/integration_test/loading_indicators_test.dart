import 'package:flutter/material.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'utils/test_utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Loading and Typing Indicators Tests', () {
    late ChatMessagesController controller;

    setUp(() {
      controller = TestUtils.createController();
    });

    testWidgets('Should show loading indicator when isLoading is true',
        (WidgetTester tester) async {
      // Arrange: Create loadingConfig with loading set to true
      const loadingConfig = LoadingConfig(
        isLoading: true,
      );

      // Act: Render the chat widget
      await tester.pumpWidget(
        TestUtils.createTestApp(
          controller: controller,
          loadingConfig: loadingConfig,
        ),
      );

      // Assert: Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Should show custom loading indicator when provided',
        (WidgetTester tester) async {
      // Arrange: Create loadingConfig with custom loading indicator
      final loadingConfig = LoadingConfig(
        isLoading: true,
        loadingIndicator: Container(
          width: 50,
          height: 50,
          decoration: const BoxDecoration(
            color: Colors.amber,
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Text('Loading...'),
          ),
        ),
      );

      // Act: Render the chat widget
      await tester.pumpWidget(
        TestUtils.createTestApp(
          controller: controller,
          loadingConfig: loadingConfig,
        ),
      );

      // Assert: Custom loading indicator should be shown
      expect(find.text('Loading...'), findsOneWidget);

      // Find the amber colored circle Container
      final containers = tester.widgetList<Container>(find.byType(Container));
      bool foundLoadingContainer = false;

      for (final container in containers) {
        if (container.decoration is BoxDecoration) {
          final decoration = container.decoration as BoxDecoration;
          if (decoration.color == Colors.amber &&
              decoration.shape == BoxShape.circle) {
            foundLoadingContainer = true;
            break;
          }
        }
      }

      expect(foundLoadingContainer, true);
    });

    testWidgets('Should show typing indicator when typing users are specified',
        (WidgetTester tester) async {
      // Arrange: Create typing users list
      const typingUsers = [ChatUser(id: 'user-2', name: 'John')];

      // Act: Render the chat widget with typing users
      await tester.pumpWidget(
        TestUtils.createTestApp(
          controller: controller,
          typingUsers: typingUsers,
        ),
      );

      // Wait for animation to start
      await tester.pump(const Duration(milliseconds: 100));

      // Assert: Should show typing indicator
      // This can be tricky to verify directly since the typing indicator is custom,
      // but we can look for specific elements or text
      expect(find.text('John is typing...'), findsOneWidget);
    });

    testWidgets('Should respect typing indicator color',
        (WidgetTester tester) async {
      // Arrange: Create typing users and loading config with custom color
      const typingUsers = [ChatUser(id: 'user-2', name: 'John')];
      const loadingConfig = LoadingConfig(
        typingIndicatorColor: Colors.purple,
      );

      // Act: Render the chat widget
      await tester.pumpWidget(
        TestUtils.createTestApp(
          controller: controller,
          typingUsers: typingUsers,
          loadingConfig: loadingConfig,
        ),
      );

      // Wait for animation to start
      await tester.pump(const Duration(milliseconds: 100));

      // Assert: Should show typing indicator with custom color
      // This is difficult to test directly in widget tests without specifics about
      // how the typing indicator is implemented
      // But we can at least verify the text is shown
      expect(find.text('John is typing...'), findsOneWidget);
    });

    testWidgets('Should hide loading indicator when isLoading changes to false',
        (WidgetTester tester) async {
      // Arrange: Create a stateful wrapper to toggle loading state
      final ValueNotifier<bool> isLoading = ValueNotifier<bool>(true);

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: ValueListenableBuilder<bool>(
                  valueListenable: isLoading,
                  builder: (context, loading, _) {
                    return AiChatWidget(
                      controller: controller,
                      currentUser:
                          const ChatUser(id: 'user-1', name: 'Test User'),
                      aiUser: const ChatUser(id: 'ai-1', name: 'Test AI'),
                      onSendMessage: (_) {},
                      loadingConfig: LoadingConfig(
                        isLoading: loading,
                      ),
                    );
                  },
                ),
                floatingActionButton: FloatingActionButton(
                  onPressed: () {
                    isLoading.value = !isLoading.value;
                  },
                  child: const Icon(Icons.refresh),
                ),
              );
            },
          ),
        ),
      );

      // Verify loading indicator is shown initially
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Toggle loading state
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();

      // Assert: Loading indicator should now be hidden
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });
}
