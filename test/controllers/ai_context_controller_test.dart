import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';

void main() {
  group('AiContextController Tests', () {
    late AiContextController controller;

    setUp(() {
      controller = AiContextController();
    });

    tearDown(() {
      controller.dispose();
    });

    group('Context Management', () {
      test('should set context data successfully', () {
        final contextData = _createTestContext();

        controller.setContext(contextData);

        expect(
            controller.contextData, containsPair('test_context', contextData));
      });

      test('should get context by ID', () {
        final contextData = _createTestContext();
        controller.setContext(contextData);

        final retrieved = controller.getContext('test_context');

        expect(retrieved, equals(contextData));
      });

      test('should return null for non-existent context', () {
        final retrieved = controller.getContext('non_existent');

        expect(retrieved, isNull);
      });

      test('should remove context successfully', () {
        final contextData = _createTestContext();
        controller.setContext(contextData);

        final result = controller.removeContext('test_context');

        expect(result, isTrue);
        expect(controller.contextData, isNot(contains('test_context')));
      });

      test('should return false when removing non-existent context', () {
        final result = controller.removeContext('non_existent');

        expect(result, isFalse);
      });

      test('should update existing context', () {
        final contextData = _createTestContext();
        controller.setContext(contextData);

        final updated =
            controller.updateContext('test_context', {'updated': true});

        expect(updated, isTrue);
        final retrieved = controller.getContext('test_context');
        expect(retrieved?.data, equals({'updated': true}));
      });

      test('should clear all context', () {
        controller.setContext(_createTestContext());
        controller.setContext(_createTestContext(id: 'context2'));

        controller.clearContext();

        expect(controller.contextData, isEmpty);
      });
    });

    group('Context Filtering', () {
      setUp(() {
        controller.setContext(_createUserProfileContext());
        controller.setContext(_createApplicationStateContext());
        controller.setContext(_createNavigationContext());
      });

      test('should get context by type', () {
        final userContexts =
            controller.getContextByType(AiContextType.userProfile);

        expect(userContexts, hasLength(1));
        expect(userContexts.first.type, equals(AiContextType.userProfile));
      });

      test('should get context by category', () {
        final contexts = controller.getContextByCategory('user');

        expect(contexts, isNotEmpty);
        expect(contexts.first.categories, contains('user'));
      });

      test('should get context by priority', () {
        final highPriorityContexts =
            controller.getContextByPriority(AiContextPriority.high);

        expect(highPriorityContexts, isNotEmpty);
        expect(highPriorityContexts.first.priority,
            equals(AiContextPriority.high));
      });
    });

    group('Context Summary', () {
      setUp(() {
        controller.setContext(_createUserProfileContext());
        controller.setContext(_createApplicationStateContext());
        controller.setContext(_createNavigationContext());
      });

      test('should generate context summary', () {
        final summary = controller.getContextSummary();

        expect(summary, contains('Current Context:'));
        expect(summary, contains('User Profile'));
      });

      test('should filter summary by type', () {
        final summary = controller.getContextSummary(
          types: [AiContextType.userProfile],
        );

        expect(summary, contains('User Profile'));
        expect(summary, isNot(contains('Application State')));
      });

      test('should filter summary by priority', () {
        final summary = controller.getContextSummary(
          priorities: [AiContextPriority.high],
        );

        expect(summary, isNotEmpty);
      });

      test('should limit summary items', () {
        final summary = controller.getContextSummary(maxItems: 1);

        // Should contain only the highest priority item
        expect(summary, contains('Current Context:'));
      });

      test('should return empty message when no context available', () {
        controller.clearContext();

        final summary = controller.getContextSummary();

        expect(summary, equals('No relevant context available.'));
      });
    });

    group('Context for AI Prompts', () {
      setUp(() {
        controller.setContext(_createUserProfileContext());
        controller.setContext(_createApplicationStateContext());
      });

      test('should format context for AI prompts', () {
        final formatted = controller.getContextForPrompt();

        expect(formatted, isA<Map<String, dynamic>>());
        expect(formatted.containsKey('user_profile'), isTrue);
        expect(formatted.containsKey('app_state'), isTrue);
      });

      test('should include all context data fields', () {
        final formatted = controller.getContextForPrompt();

        final userContext = formatted['user_profile'] as Map<String, dynamic>;
        expect(userContext['name'], equals('User Profile'));
        expect(userContext['type'], equals('userProfile'));
        expect(userContext['priority'], equals('high'));
        expect(userContext['description'], isNotNull);
        expect(userContext['data'], isNotNull);
        expect(userContext['lastUpdated'], isNotNull);
      });
    });

    group('Value Watching', () {
      test('should watch ValueNotifier and update context', () {
        final notifier = ValueNotifier<String>('initial');

        controller.watchNotifier<String>(
          contextId: 'watched_value',
          contextName: 'Watched Value',
          notifier: notifier,
        );

        expect(controller.getContext('watched_value'), isNotNull);
        expect(controller.getContext('watched_value')?.data, equals('initial'));

        notifier.value = 'updated';

        expect(controller.getContext('watched_value')?.data, equals('updated'));

        notifier.dispose();
      });

      test('should watch Stream and update context', () async {
        final streamController = StreamController<String>();

        controller.watchValue<String>(
          contextId: 'stream_value',
          contextName: 'Stream Value',
          valueStream: streamController.stream,
        );

        streamController.add('stream_data');
        await Future.delayed(const Duration(milliseconds: 10));

        expect(controller.getContext('stream_value'), isNotNull);
        expect(
            controller.getContext('stream_value')?.data, equals('stream_data'));

        streamController.close();
      });
    });

    group('Event Streaming', () {
      test('should emit context added event', () async {
        AiContextEvent? receivedEvent;
        controller.events.listen((event) {
          receivedEvent = event;
        });

        final contextData = _createTestContext();
        controller.setContext(contextData);

        // Stream events are async, wait for microtask
        await Future.delayed(Duration.zero);

        expect(receivedEvent, isNotNull);
        expect(receivedEvent!.type, equals(AiContextEventType.added));
        expect(receivedEvent!.contextData, equals(contextData));
      });

      test('should emit context updated event', () async {
        final contextData = _createTestContext();
        controller.setContext(contextData);

        AiContextEvent? updateEvent;
        controller.events.listen((event) {
          if (event.type == AiContextEventType.updated) {
            updateEvent = event;
          }
        });

        controller.setContext(contextData.copyWith(data: {'updated': true}));

        await Future.delayed(Duration.zero);

        expect(updateEvent, isNotNull);
        expect(updateEvent!.type, equals(AiContextEventType.updated));
        expect(updateEvent!.contextData?.data, equals({'updated': true}));
      });

      test('should emit context removed event', () async {
        final contextData = _createTestContext();
        controller.setContext(contextData);

        AiContextEvent? removedEvent;
        controller.events.listen((event) {
          if (event.type == AiContextEventType.removed) {
            removedEvent = event;
          }
        });

        controller.removeContext('test_context');

        await Future.delayed(Duration.zero);

        expect(removedEvent, isNotNull);
        expect(removedEvent!.type, equals(AiContextEventType.removed));
        expect(removedEvent!.contextData, equals(contextData));
      });

      test('should emit context cleared event', () async {
        controller.setContext(_createTestContext());

        AiContextEvent? clearedEvent;
        controller.events.listen((event) {
          if (event.type == AiContextEventType.cleared) {
            clearedEvent = event;
          }
        });

        controller.clearContext();

        await Future.delayed(Duration.zero);

        expect(clearedEvent, isNotNull);
        expect(clearedEvent!.type, equals(AiContextEventType.cleared));
      });
    });

    group('Context Expiration', () {
      test('should respect context expiration', () {
        final expiredContext = AiContextData.custom(
          id: 'expired',
          name: 'Expired Context',
          data: 'test',
          description: 'Test context',
          expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
        );

        controller.setContext(expiredContext);

        final summary = controller.getContextSummary();
        expect(summary, equals('No relevant context available.'));
      });

      test('should clean up expired contexts', () {
        final expiredContext = AiContextData.custom(
          id: 'expired',
          name: 'Expired Context',
          data: 'test',
          description: 'Test context',
          expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
        );

        controller.setContext(expiredContext);
        controller.cleanupExpiredContext();

        expect(controller.getContext('expired'), isNull);
      });
    });
  });
}

// Helper methods for creating test contexts
AiContextData _createTestContext({String id = 'test_context'}) {
  return AiContextData(
    id: id,
    name: 'Test Context',
    type: AiContextType.custom,
    data: {'test': true},
    description: 'Test context data',
  );
}

AiContextData _createUserProfileContext() {
  return AiContextData.userProfile(
    id: 'user_profile',
    name: 'User Profile',
    profileData: {
      'name': 'John Doe',
      'email': 'john@example.com',
      'role': 'admin',
    },
    priority: AiContextPriority.high,
    categories: ['user', 'profile'],
  );
}

AiContextData _createApplicationStateContext() {
  return AiContextData.applicationState(
    id: 'app_state',
    name: 'Application State',
    stateData: {
      'currentPage': 'dashboard',
      'isLoggedIn': true,
    },
    priority: AiContextPriority.normal,
    categories: ['app', 'state'],
  );
}

AiContextData _createNavigationContext() {
  return AiContextData.navigationContext(
    id: 'navigation',
    currentPage: '/dashboard',
    pageData: {'section': 'overview'},
    priority: AiContextPriority.high,
  );
}
