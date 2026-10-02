import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression coverage for TASK-035: id-less messages from the same user in
/// the same millisecond used to collapse into one (web has ms resolution).
void main() {
  group('id-less message collisions', () {
    late ChatMessagesController controller;
    const ai = ChatUser(id: 'ai', firstName: 'AI');
    final t = DateTime(2026, 10, 2, 12, 0, 0, 5);

    setUp(() => controller = ChatMessagesController());
    tearDown(() => controller.dispose());

    ChatMessage msg(String text) =>
        ChatMessage(text: text, user: ai, createdAt: t);

    test('distinct same-millisecond messages are both kept', () {
      controller.addMessage(msg('tool call json'));
      controller.addMessage(msg('result card'));

      expect(controller.messages.map((m) => m.text).toSet(),
          {'tool call json', 'result card'});
      final ids = controller.messages
          .map((m) => m.customProperties!['id'] as String)
          .toSet();
      expect(ids.length, 2);
    });

    test('three-way collision keeps all and ids stay unique', () {
      controller.addMessage(msg('a'));
      controller.addMessage(msg('b'));
      controller.addMessage(msg('c'));
      expect(controller.messages.length, 3);
      expect(
          controller.messages
              .map((m) => m.customProperties!['id'] as String)
              .toSet()
              .length,
          3);
    });

    test('an identical re-add still dedupes', () {
      controller.addMessage(msg('same'));
      controller.addMessage(msg('same'));
      expect(controller.messages.length, 1);
    });

    test('streaming after a collision targets the new message', () {
      controller.addMessage(msg('first'));
      controller.addStreamingMessage(msg(''));
      expect(controller.messages.length, 2);

      final streamed = controller.messages.firstWhere((m) => m.text.isEmpty);
      final id = streamed.customProperties!['id'] as String;
      expect(controller.isMessageStreaming(id), isTrue);

      controller.updateMessage(streamed.copyWith(text: 'streamed answer'));
      expect(controller.messages.length, 2);
      expect(controller.messages.where((m) => m.text == 'first').length, 1);
      expect(
          controller.messages.where((m) => m.text == 'streamed answer').length,
          1);

      controller.stopStreamingMessage(id);
      expect(controller.isMessageStreaming(id), isFalse);
      expect(controller.messages.length, 2);
    });
  });
}
