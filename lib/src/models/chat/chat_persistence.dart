import 'chat_message.dart';

/// A pluggable persistence hook for restoring and saving a long-running
/// chat thread across app restarts.
///
/// This package doesn't pick a storage backend — implement this interface
/// with `shared_preferences`, `sqflite`, `Hive`, a REST API, or whatever
/// already fits your app, then pass an instance to
/// `ChatMessagesController`'s `persistence` parameter.
///
/// Example (a trivial in-memory implementation; a real one would read/write
/// actual storage):
/// ```dart
/// class MyChatPersistence implements ChatPersistence {
///   final _storage = <ChatMessage>[];
///
///   @override
///   Future<List<ChatMessage>> loadMessages() async => _storage;
///
///   @override
///   Future<void> saveMessages(List<ChatMessage> messages) async {
///     _storage
///       ..clear()
///       ..addAll(messages);
///   }
/// }
///
/// final controller = ChatMessagesController(persistence: MyChatPersistence());
/// await controller.restoreFromPersistence(); // e.g. in initState
/// ```
abstract class ChatPersistence {
  /// Loads previously saved messages, e.g. on app startup.
  ///
  /// Return an empty list if nothing has been saved yet. Called by
  /// `ChatMessagesController.restoreFromPersistence` — the controller never
  /// calls this on its own, so a consumer controls exactly when a restore
  /// happens (and can show a loading state around the `await`).
  Future<List<ChatMessage>> loadMessages();

  /// Persists the current full message list.
  ///
  /// Called automatically by `ChatMessagesController` after a message-list
  /// mutation when `persistence` is set and `autoPersist` is true (the
  /// default), debounced by `persistDebounce` so a fast burst of
  /// `updateMessage` calls during streaming triggers one save, not one per
  /// chunk. Receives the controller's full current message list each time,
  /// not a diff — implement this as a replace, not an append.
  Future<void> saveMessages(List<ChatMessage> messages);
}
