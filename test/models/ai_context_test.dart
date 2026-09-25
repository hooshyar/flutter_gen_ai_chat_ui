import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';

void main() {
  group('AiContextData Tests', () {
    group('Construction', () {
      test('should create context with required fields', () {
        final context = AiContextData(
          id: 'test_id',
          name: 'Test Context',
          type: AiContextType.custom,
          data: {'key': 'value'},
          description: 'Test description',
        );

        expect(context.id, equals('test_id'));
        expect(context.name, equals('Test Context'));
        expect(context.type, equals(AiContextType.custom));
        expect(context.data, equals({'key': 'value'}));
        expect(context.description, equals('Test description'));
        expect(context.priority, equals(AiContextPriority.normal));
        expect(context.categories, isEmpty);
        expect(context.enabled, isTrue);
        expect(context.expiresAt, isNull);
      });

      test('should create context with optional fields', () {
        final expiresAt = DateTime.now().add(const Duration(hours: 1));
        final context = AiContextData(
          id: 'test_id',
          name: 'Test Context',
          type: AiContextType.custom,
          data: {'key': 'value'},
          description: 'Test description',
          priority: AiContextPriority.high,
          categories: ['category1', 'category2'],
          enabled: false,
          expiresAt: expiresAt,
        );

        expect(context.priority, equals(AiContextPriority.high));
        expect(context.categories, equals(['category1', 'category2']));
        expect(context.enabled, isFalse);
        expect(context.expiresAt, equals(expiresAt));
      });
    });

    group('Factory Constructors', () {
      test('should create user profile context', () {
        final context = AiContextData.userProfile(
          id: 'user_123',
          name: 'John Doe',
          profileData: {'email': 'john@example.com', 'role': 'admin'},
          priority: AiContextPriority.high,
          categories: ['user', 'profile'],
        );

        expect(context.id, equals('user_123'));
        expect(context.name, equals('John Doe'));
        expect(context.type, equals(AiContextType.userProfile));
        expect(context.data['email'], equals('john@example.com'));
        expect(context.description, equals('User profile information'));
        expect(context.priority, equals(AiContextPriority.high));
        expect(context.categories, equals(['user', 'profile']));
      });

      test('should create application state context', () {
        final context = AiContextData.applicationState(
          id: 'app_state',
          name: 'Current State',
          stateData: {'isLoggedIn': true, 'currentPage': 'dashboard'},
          description: 'App state data',
          priority: AiContextPriority.normal,
          categories: ['app', 'state'],
        );

        expect(context.id, equals('app_state'));
        expect(context.type, equals(AiContextType.applicationState));
        expect(context.data['isLoggedIn'], isTrue);
        expect(context.description, equals('App state data'));
      });

      test('should create navigation context', () {
        final context = AiContextData.navigationContext(
          id: 'nav_context',
          currentPage: '/dashboard',
          pageData: {'section': 'overview'},
          description: 'Navigation info',
          priority: AiContextPriority.high,
        );

        expect(context.id, equals('nav_context'));
        expect(context.name, equals('Current Page'));
        expect(context.type, equals(AiContextType.navigationContext));
        expect(context.data['currentPage'], equals('/dashboard'));
        expect(context.data['pageData']['section'], equals('overview'));
        expect(context.categories, equals(['navigation', 'routing']));
      });

      test('should create business context', () {
        final context = AiContextData.businessContext(
          id: 'business_data',
          name: 'Sales Data',
          businessData: {'revenue': 100000, 'customers': 500},
          description: 'Business metrics',
          priority: AiContextPriority.normal,
          categories: ['business', 'metrics'],
        );

        expect(context.type, equals(AiContextType.businessContext));
        expect(context.data['revenue'], equals(100000));
      });

      test('should create custom context', () {
        final expiresAt = DateTime.now().add(const Duration(hours: 1));
        final context = AiContextData.custom(
          id: 'custom_id',
          name: 'Custom Context',
          data: {'custom': 'data'},
          description: 'Custom description',
          priority: AiContextPriority.low,
          categories: ['custom'],
          expiresAt: expiresAt,
        );

        expect(context.type, equals(AiContextType.custom));
        expect(context.expiresAt, equals(expiresAt));
      });
    });

    group('Validation', () {
      test('should be valid when not expired', () {
        final context = AiContextData(
          id: 'test_id',
          name: 'Test Context',
          type: AiContextType.custom,
          data: {'key': 'value'},
          description: 'Test description',
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
        );

        expect(context.isValid, isTrue);
      });

      test('should be valid when no expiration set', () {
        final context = AiContextData(
          id: 'test_id',
          name: 'Test Context',
          type: AiContextType.custom,
          data: {'key': 'value'},
          description: 'Test description',
        );

        expect(context.isValid, isTrue);
      });

      test('should be invalid when expired', () {
        final context = AiContextData(
          id: 'test_id',
          name: 'Test Context',
          type: AiContextType.custom,
          data: {'key': 'value'},
          description: 'Test description',
          expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
        );

        expect(context.isValid, isFalse);
      });
    });

    group('AI String Serialization', () {
      test('should serialize map data correctly', () {
        final context = AiContextData(
          id: 'test_id',
          name: 'User Data',
          type: AiContextType.custom,
          data: {'name': 'John', 'age': 30, 'active': true},
          description: 'Test description',
        );

        final aiString = context.toAiString();

        expect(
          aiString,
          equals('User Data: {name: John, age: 30, active: true}'),
        );
      });

      test('should serialize list data correctly', () {
        final context = AiContextData(
          id: 'test_id',
          name: 'Categories',
          type: AiContextType.custom,
          data: ['tech', 'science', 'art'],
          description: 'Test description',
        );

        final aiString = context.toAiString();

        expect(aiString, equals('Categories: [tech, science, art]'));
      });

      test('should serialize primitive data correctly', () {
        final context = AiContextData(
          id: 'test_id',
          name: 'Status',
          type: AiContextType.custom,
          data: 'active',
          description: 'Test description',
        );

        final aiString = context.toAiString();

        expect(aiString, equals('Status: active'));
      });

      test('should use custom serializer when provided', () {
        final context = AiContextData(
          id: 'test_id',
          name: 'Custom Data',
          type: AiContextType.custom,
          data: {'complex': 'data'},
          description: 'Test description',
          serializer: (data) => 'Custom: ${data['complex']}',
        );

        final aiString = context.toAiString();

        expect(aiString, equals('Custom: data'));
      });
    });

    group('Copy With', () {
      test('should create copy with updated fields', () {
        final original = AiContextData(
          id: 'test_id',
          name: 'Original',
          type: AiContextType.custom,
          data: {'key': 'value'},
          description: 'Original description',
        );

        final updated = original.copyWith(
          name: 'Updated',
          data: {'new': 'data'},
        );

        expect(updated.id, equals('test_id'));
        expect(updated.name, equals('Updated'));
        expect(updated.data, equals({'new': 'data'}));
        expect(updated.description, equals('Original description'));
        expect(updated.lastUpdated, isNot(equals(original.lastUpdated)));
      });
    });

    group('JSON Serialization', () {
      test('should convert to JSON correctly', () {
        final context = AiContextData(
          id: 'test_id',
          name: 'Test Context',
          type: AiContextType.userProfile,
          data: {'key': 'value'},
          description: 'Test description',
          priority: AiContextPriority.high,
          categories: ['test'],
        );

        final json = context.toJson();

        expect(json['id'], equals('test_id'));
        expect(json['name'], equals('Test Context'));
        expect(json['type'], equals('userProfile'));
        expect(json['description'], equals('Test description'));
        expect(json['priority'], equals('high'));
        expect(json['categories'], equals(['test']));
        expect(json['enabled'], isTrue);
        expect(json['data'], isA<String>());
        expect(json['lastUpdated'], isA<String>());
      });

      test('should include expiration in JSON when set', () {
        final expiresAt = DateTime.now().add(const Duration(hours: 1));
        final context = AiContextData(
          id: 'test_id',
          name: 'Test Context',
          type: AiContextType.custom,
          data: {'key': 'value'},
          description: 'Test description',
          expiresAt: expiresAt,
        );

        final json = context.toJson();

        expect(json['expiresAt'], equals(expiresAt.toIso8601String()));
      });
    });

    group('Equality', () {
      test('should be equal when IDs match', () {
        final context1 = AiContextData(
          id: 'same_id',
          name: 'Context 1',
          type: AiContextType.custom,
          data: {'key': 'value1'},
          description: 'Description 1',
        );

        final context2 = AiContextData(
          id: 'same_id',
          name: 'Context 2',
          type: AiContextType.userProfile,
          data: {'key': 'value2'},
          description: 'Description 2',
        );

        expect(context1, equals(context2));
        expect(context1.hashCode, equals(context2.hashCode));
      });

      test('should not be equal when IDs differ', () {
        final context1 = AiContextData(
          id: 'id1',
          name: 'Context',
          type: AiContextType.custom,
          data: {'key': 'value'},
          description: 'Description',
        );

        final context2 = AiContextData(
          id: 'id2',
          name: 'Context',
          type: AiContextType.custom,
          data: {'key': 'value'},
          description: 'Description',
        );

        expect(context1, isNot(equals(context2)));
      });
    });
  });

  group('AiContextEvent Tests', () {
    test('should create context event with required fields', () {
      final contextData = AiContextData(
        id: 'test_id',
        name: 'Test Context',
        type: AiContextType.custom,
        data: {'key': 'value'},
        description: 'Test description',
      );

      final event = AiContextEvent(
        type: AiContextEventType.added,
        contextData: contextData,
      );

      expect(event.type, equals(AiContextEventType.added));
      expect(event.contextData, equals(contextData));
      expect(event.previousData, isNull);
      expect(event.metadata, isNull);
      expect(event.timestamp, isA<DateTime>());
    });

    test('should create context event with optional fields', () {
      final contextData = AiContextData(
        id: 'test_id',
        name: 'Test Context',
        type: AiContextType.custom,
        data: {'key': 'value'},
        description: 'Test description',
      );

      final previousData = contextData.copyWith(data: {'old': 'value'});
      final timestamp = DateTime.now();
      final metadata = {'source': 'test'};

      final event = AiContextEvent(
        type: AiContextEventType.updated,
        contextData: contextData,
        previousData: previousData,
        timestamp: timestamp,
        metadata: metadata,
      );

      expect(event.type, equals(AiContextEventType.updated));
      expect(event.contextData, equals(contextData));
      expect(event.previousData, equals(previousData));
      expect(event.timestamp, equals(timestamp));
      expect(event.metadata, equals(metadata));
    });

    test('should create string representation', () {
      final contextData = AiContextData(
        id: 'test_id',
        name: 'Test Context',
        type: AiContextType.custom,
        data: {'key': 'value'},
        description: 'Test description',
      );

      final event = AiContextEvent(
        type: AiContextEventType.added,
        contextData: contextData,
      );

      final string = event.toString();

      expect(string, contains('AiContextEvent'));
      expect(string, contains('added'));
      expect(string, contains('test_id'));
    });
  });

  group('Enum Tests', () {
    test('should have correct AiContextType values', () {
      final types = AiContextType.values;

      expect(types, contains(AiContextType.userProfile));
      expect(types, contains(AiContextType.applicationState));
      expect(types, contains(AiContextType.navigationContext));
      expect(types, contains(AiContextType.businessContext));
      expect(types, contains(AiContextType.uiState));
      expect(types, contains(AiContextType.custom));
    });

    test('should have correct AiContextPriority values', () {
      final priorities = AiContextPriority.values;

      expect(priorities, contains(AiContextPriority.low));
      expect(priorities, contains(AiContextPriority.normal));
      expect(priorities, contains(AiContextPriority.high));
      expect(priorities, contains(AiContextPriority.critical));
    });

    test('should have correct AiContextEventType values', () {
      final eventTypes = AiContextEventType.values;

      expect(eventTypes, contains(AiContextEventType.added));
      expect(eventTypes, contains(AiContextEventType.updated));
      expect(eventTypes, contains(AiContextEventType.removed));
      expect(eventTypes, contains(AiContextEventType.cleared));
    });
  });
}
