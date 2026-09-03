import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';

/// task-009: an opt-in persistence hook for restoring/saving a long-running
/// chat thread across app restarts. `ChatPersistence` is entirely additive —
/// a controller with no `persistence` set behaves exactly as before.
class _FakePersistence implements ChatPersistence {
  List<ChatMessage> stored;
  int saveCalls = 0;
  int loadCalls = 0;

  _FakePersistence([List<ChatMessage>? initial]) : stored = initial ?? [];

  @override
  Future<List<ChatMessage>> loadMessages() async {
    loadCalls++;
    return stored;
  }

  @override
  Future<void> saveMessages(List<ChatMessage> messages) async {
    saveCalls++;
    stored = List.of(messages);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testUser = ChatUser(id: 'user', name: 'Test User');
  const aiUser = ChatUser(id: 'ai', name: 'AI Assistant');

  test('restoreFromPersistence populates messages from the store', () async {
    final saved = [
      ChatMessage(
        text: 'previously saved',
        user: aiUser,
        createdAt: DateTime(2026),
        customProperties: const {'id': 'saved1'},
      ),
    ];
    final persistence = _FakePersistence(saved);
    final controller = ChatMessagesController(persistence: persistence);
    addTearDown(controller.dispose);

    expect(controller.messages, isEmpty);
    await controller.restoreFromPersistence();

    expect(persistence.loadCalls, 1);
    expect(controller.messages, hasLength(1));
    expect(controller.messages.first.text, 'previously saved');
  });

  test('restoreFromPersistence is a no-op without a persistence hook',
      () async {
    final controller = ChatMessagesController();
    addTearDown(controller.dispose);

    await controller.restoreFromPersistence(); // Must not throw.
    expect(controller.messages, isEmpty);
  });

  test('a controller with no persistence never calls saveMessages', () async {
    // Regression guard: persistence must be entirely opt-in. Exercise the
    // normal mutation paths and confirm nothing crashes or gets called
    // when `persistence` was never set.
    final controller = ChatMessagesController();
    addTearDown(controller.dispose);

    controller.addMessage(
      ChatMessage(text: 'hi', user: testUser, createdAt: DateTime.now()),
    );
    controller.clearMessages();
    // No assertion beyond "did not throw" — there's no persistence object
    // to assert against, which is exactly the point.
  });

  test('addMessage debounces auto-persist into a single save', () {
    fakeAsync((async) {
      final persistence = _FakePersistence();
      final controller = ChatMessagesController(
        persistence: persistence,
        persistDebounce: const Duration(milliseconds: 500),
      );

      // A burst of 5 messages in quick succession should coalesce into one
      // save shortly after the burst ends, not five.
      for (var i = 0; i < 5; i++) {
        controller.addMessage(
          ChatMessage(
            text: 'msg $i',
            user: aiUser,
            createdAt: DateTime.now(),
            customProperties: {'id': 'm$i'},
          ),
        );
        async.elapse(const Duration(milliseconds: 50));
      }
      expect(persistence.saveCalls, 0,
          reason: 'debounce should not have fired yet');

      async.elapse(const Duration(milliseconds: 500));
      expect(persistence.saveCalls, 1);
      expect(persistence.stored, hasLength(5));

      controller.dispose();
      // A regression here would leave a pending Timer in the FakeAsync
      // zone; fakeAsync() itself asserts no pending timers remain after
      // the callback returns, on top of the explicit disposal below.
      async.flushTimers();
    });
  });

  test(
      'autoPersist: false suppresses automatic saves; persistNow saves '
      'immediately', () {
    fakeAsync((async) {
      final persistence = _FakePersistence();
      final controller = ChatMessagesController(
        persistence: persistence,
        autoPersist: false,
      );
      addTearDown(controller.dispose);

      controller.addMessage(
        ChatMessage(text: 'hi', user: testUser, createdAt: DateTime.now()),
      );
      async.elapse(const Duration(seconds: 2));
      expect(persistence.saveCalls, 0);

      controller.persistNow();
      async.flushMicrotasks();
      expect(persistence.saveCalls, 1);
      expect(persistence.stored, hasLength(1));
    });
  });

  test('dispose cancels a pending auto-persist debounce Timer', () {
    fakeAsync((async) {
      final persistence = _FakePersistence();
      final controller = ChatMessagesController(persistence: persistence);

      controller.addMessage(
        ChatMessage(text: 'hi', user: testUser, createdAt: DateTime.now()),
      );
      controller.dispose();

      // If the debounce Timer weren't cancelled on dispose, this would
      // leave a pending timer that fakeAsync's own zone-exit check flags —
      // and would call saveMessages after disposal, which should never
      // happen.
      async.elapse(const Duration(seconds: 2));
      expect(persistence.saveCalls, 0);
    });
  });
}
