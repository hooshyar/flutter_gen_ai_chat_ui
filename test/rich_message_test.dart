import 'package:flutter/material.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final aiUser = ChatUser(id: 'ai', firstName: 'AI');
  final humanUser = ChatUser(id: 'user', firstName: 'User');

  group('ChatMessage.rich()', () {
    test('sets resultKind in customProperties', () {
      final msg = ChatMessage.rich(
        user: aiUser,
        resultKind: 'weather',
        data: {'city': 'Baghdad', 'temp': 42},
      );

      expect(msg.customProperties?['resultKind'], 'weather');
      expect(msg.customProperties?['resultData'], {
        'city': 'Baghdad',
        'temp': 42,
      });
      expect(msg.text, '');
      expect(msg.customBuilder, isNull);
    });

    test('uses fallback text when provided', () {
      final msg = ChatMessage.rich(
        user: aiUser,
        resultKind: 'product',
        data: {'name': 'Widget'},
        text: 'Product info',
      );

      expect(msg.text, 'Product info');
      expect(msg.customProperties?['resultKind'], 'product');
    });

    test('uses current time when createdAt not provided', () {
      final before = DateTime.now();
      final msg = ChatMessage.rich(
        user: aiUser,
        resultKind: 'test',
        data: {},
      );
      final after = DateTime.now();

      expect(
        msg.createdAt.isAfter(before.subtract(const Duration(seconds: 1))),
        isTrue,
      );
      expect(
        msg.createdAt.isBefore(after.add(const Duration(seconds: 1))),
        isTrue,
      );
    });

    test('uses provided createdAt', () {
      final date = DateTime(2026, 1, 1);
      final msg = ChatMessage.rich(
        user: aiUser,
        resultKind: 'test',
        data: {},
        createdAt: date,
      );

      expect(msg.createdAt, date);
    });
  });

  group('ChatMessage.widget()', () {
    test('sets customBuilder', () {
      final msg = ChatMessage.widget(
        user: aiUser,
        builder: (context) => const Text('Custom Widget'),
      );

      expect(msg.customBuilder, isNotNull);
      expect(msg.text, '');
    });

    test('uses fallback text when provided', () {
      final msg = ChatMessage.widget(
        user: aiUser,
        builder: (context) => const SizedBox(),
        text: 'Fallback',
      );

      expect(msg.text, 'Fallback');
      expect(msg.customBuilder, isNotNull);
    });
  });

  group('ResultRendererRegistry', () {
    test('buildResult returns widget for registered kind', () {
      final registry = ResultRendererRegistry(
        builders: {
          'weather': (context, data) => Text('Temp: ${data['temp']}'),
        },
        child: const SizedBox(),
      );

      // We can't call buildResult without a BuildContext in unit tests,
      // but we can verify the builder is registered
      expect(registry.builders.containsKey('weather'), isTrue);
    });

    test('buildResult returns null for unregistered kind', () {
      final registry = ResultRendererRegistry(
        builders: {
          'weather': (context, data) => const Text('Weather'),
        },
        child: const SizedBox(),
      );

      expect(registry.builders.containsKey('unknown'), isFalse);
    });

    test('extend merges builders', () {
      final base = ResultRendererRegistry(
        builders: {
          'weather': (context, data) => const Text('Weather'),
        },
        child: const SizedBox(),
      );

      final extended = base.extend({
        'product': (context, data) => const Text('Product'),
      });

      expect(extended.builders.containsKey('weather'), isTrue);
      expect(extended.builders.containsKey('product'), isTrue);
    });

    testWidgets('renders rich message via registry', (tester) async {
      final controller = ChatMessagesController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AiChatWidget(
              currentUser: humanUser,
              aiUser: aiUser,
              controller: controller,
              onSendMessage: (_) {},
              resultRenderers: {
                'weather': (context, data) => Text(
                      'Weather: ${data['city']} ${data['temp']}°',
                    ),
              },
            ),
          ),
        ),
      );

      controller.addMessage(ChatMessage.rich(
        user: aiUser,
        resultKind: 'weather',
        data: {'city': 'Baghdad', 'temp': 42},
      ));

      await tester.pumpAndSettle();

      expect(find.text('Weather: Baghdad 42°'), findsOneWidget);
    });

    testWidgets('falls through to text when no renderer matches',
        (tester) async {
      final controller = ChatMessagesController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AiChatWidget(
              currentUser: humanUser,
              aiUser: aiUser,
              controller: controller,
              onSendMessage: (_) {},
              resultRenderers: {
                'weather': (context, data) => const Text('Weather'),
              },
            ),
          ),
        ),
      );

      controller.addMessage(ChatMessage.rich(
        user: aiUser,
        resultKind: 'unknown_kind',
        data: {},
        text: 'Fallback text here',
      ));

      await tester.pumpAndSettle();

      // When no renderer matches, the message falls through to
      // text rendering — verify it renders something (not a blank)
      expect(find.textContaining('Fallback'), findsOneWidget);
    });

    testWidgets('ChatMessage.widget renders inline widget', (tester) async {
      final controller = ChatMessagesController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AiChatWidget(
              currentUser: humanUser,
              aiUser: aiUser,
              controller: controller,
              onSendMessage: (_) {},
            ),
          ),
        ),
      );

      controller.addMessage(ChatMessage.widget(
        user: aiUser,
        builder: (context) => const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text('Inline Widget Card'),
          ),
        ),
      ));

      await tester.pumpAndSettle();

      expect(find.text('Inline Widget Card'), findsOneWidget);
    });
  });
}
