import 'dart:async';

import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const ai = ChatUser(id: 'ai', name: 'AI');

  late ChatMessagesController controller;

  setUp(() => controller = ChatMessagesController());
  tearDown(() => controller.dispose());

  /// Lets queued stream events reach their listeners.
  Future<void> flush() => Future<void>.delayed(Duration.zero);

  ChatMessage? stored(String id) {
    for (final m in controller.messages) {
      if (m.customProperties?['id'] == id) return m;
    }
    return null;
  }

  test('appends deltas into one message and closes it when the stream ends',
      () async {
    final chunks = StreamController<String>();
    final response = controller.streamResponse(chunks.stream, user: ai);

    expect(controller.messages, isEmpty, reason: 'nothing before first text');

    chunks.add('Hello');
    await flush();
    expect(stored(response.id)?.text, 'Hello');
    expect(controller.isMessageStreaming(response.id), isTrue);
    expect(response.isActive, isTrue);

    chunks
      ..add(', ')
      ..add('world');
    await flush();
    expect(controller.messages, hasLength(1));
    expect(stored(response.id)?.text, 'Hello, world');

    await chunks.close();
    final done = await response.done;
    expect(done?.text, 'Hello, world');
    expect(done?.isMarkdown, isTrue, reason: 'LLM replies render as markdown');
    expect(controller.isMessageStreaming(response.id), isFalse);
    expect(response.isActive, isFalse);
  });

  test('accumulated: true treats each event as the whole text so far',
      () async {
    final response = controller.streamResponse(
      Stream.fromIterable(['He', 'Hell', 'Hello']),
      user: ai,
      accumulated: true,
    );
    final done = await response.done;
    expect(done?.text, 'Hello');
    expect(stored(response.id)?.text, 'Hello');
    expect(controller.messages, hasLength(1));
  });

  test('uses the given id and keeps extra customProperties', () async {
    final response = controller.streamResponse(
      Stream.fromIterable(['Hi']),
      user: ai,
      id: 'reply-1',
      customProperties: {'model': 'test-model'},
    );
    await response.done;
    expect(response.id, 'reply-1');
    expect(stored('reply-1')?.customProperties?['model'], 'test-model');
  });

  test('an error keeps the partial text, closes the message, calls onError',
      () async {
    final chunks = StreamController<String>();
    Object? reported;
    final response = controller.streamResponse(
      chunks.stream,
      user: ai,
      onError: (error, _) => reported = error,
    );

    chunks.add('Partial');
    await flush();
    chunks.addError(StateError('network'));
    final done = await response.done;

    expect(reported, isA<StateError>());
    expect(done?.text, 'Partial');
    expect(stored(response.id)?.text, 'Partial');
    expect(controller.isMessageStreaming(response.id), isFalse);
    await chunks.close();
  });

  test('cancel keeps the text so far and ignores later chunks', () async {
    final chunks = StreamController<String>();
    final response = controller.streamResponse(chunks.stream, user: ai);

    chunks.add('Stop ');
    await flush();
    await response.cancel();
    expect(chunks.hasListener, isFalse);

    expect((await response.done)?.text, 'Stop ');
    expect(controller.isMessageStreaming(response.id), isFalse);
    // Cancelling twice is harmless.
    await response.cancel();
    await chunks.close();
  });

  test('an empty stream adds nothing and completes with null', () async {
    final response =
        controller.streamResponse(Stream.fromIterable(['', '']), user: ai);
    expect(await response.done, isNull);
    expect(controller.messages, isEmpty);
  });

  test('dispose stops an active reply and completes done', () async {
    final local = ChatMessagesController();
    final chunks = StreamController<String>();
    final response = local.streamResponse(chunks.stream, user: ai);
    chunks.add('Half');
    await flush();

    local.dispose();
    expect((await response.done)?.text, 'Half');
    expect(chunks.hasListener, isFalse);
    await chunks.close();
  });

  test('two replies started in a row get different ids', () async {
    final a = controller.streamResponse(Stream.fromIterable(['A']), user: ai);
    final b = controller.streamResponse(Stream.fromIterable(['B']), user: ai);
    expect(a.id, isNot(b.id));
    await Future.wait([a.done, b.done]);
    expect(controller.messages, hasLength(2));
  });
}
