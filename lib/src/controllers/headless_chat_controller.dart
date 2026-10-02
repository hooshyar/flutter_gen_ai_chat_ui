import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/chat/chat_message.dart';
import '../models/chat_thread.dart';

/// Headless chat controller providing full programmatic control
/// Equivalent to CopilotKit's useCopilotChat hook
class HeadlessChatController extends ChangeNotifier {
  ThreadState _state = const ThreadState();
  final StreamController<ChatMessage> _messageStreamController =
      StreamController<ChatMessage>.broadcast();
  final StreamController<ThreadState> _stateStreamController =
      StreamController<ThreadState>.broadcast();

  // Getters equivalent to useCopilotChat return values
  ThreadState get state => _state;
  List<ChatMessage> get visibleMessages => _state.activeThread?.messages ?? [];
  bool get isLoading => _state.isLoading;
  String? get activeThreadId => _state.activeThreadId;
  Stream<ChatMessage> get messageStream => _messageStreamController.stream;
  Stream<ThreadState> get stateStream => _stateStreamController.stream;

  /// Create a new chat thread
  String createThread({String? title}) {
    final threadId = DateTime.now().millisecondsSinceEpoch.toString();
    final thread = ChatThread(
      id: threadId,
      title: title ?? 'New Chat',
      messages: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final updatedThreads = Map<String, ChatThread>.from(_state.threads);
    updatedThreads[threadId] = thread;

    _updateState(
      _state.copyWith(threads: updatedThreads, activeThreadId: threadId),
    );

    return threadId;
  }

  /// Switch to a different thread
  void switchThread(String threadId) {
    if (_state.threads.containsKey(threadId)) {
      _updateState(_state.copyWith(activeThreadId: threadId));
    }
  }

  /// Delete a thread
  void deleteThread(String threadId) {
    final updatedThreads = Map<String, ChatThread>.from(_state.threads)
      ..remove(threadId);

    String? newActiveId;
    if (_state.activeThreadId == threadId && updatedThreads.isNotEmpty) {
      newActiveId = updatedThreads.values.first.id;
    }

    _updateState(
      _state.copyWith(threads: updatedThreads, activeThreadId: newActiveId),
    );
  }

  /// Append a message to the current thread
  void appendMessage(ChatMessage message) {
    if (_state.activeThreadId == null) {
      createThread();
    }

    final currentThread = _state.activeThread!;
    final updatedMessages = [...currentThread.messages, message];
    final updatedThread = currentThread.copyWith(
      messages: updatedMessages,
      updatedAt: DateTime.now(),
    );

    final updatedThreads = Map<String, ChatThread>.from(_state.threads);
    updatedThreads[currentThread.id] = updatedThread;

    _updateState(_state.copyWith(threads: updatedThreads));
    _messageStreamController.add(message);
  }

  /// Replace all messages in the current thread
  void setMessages(List<ChatMessage> messages) {
    if (_state.activeThreadId == null) {
      createThread();
    }

    final currentThread = _state.activeThread!;
    final updatedThread = currentThread.copyWith(
      messages: messages,
      updatedAt: DateTime.now(),
    );

    final updatedThreads = Map<String, ChatThread>.from(_state.threads);
    updatedThreads[currentThread.id] = updatedThread;

    _updateState(_state.copyWith(threads: updatedThreads));
  }

  /// Update the last message in the current thread
  void updateLastMessage(ChatMessage updatedMessage) {
    if (_state.activeThread == null || _state.activeThread!.messages.isEmpty) {
      return;
    }

    final currentThread = _state.activeThread!;
    final messages = [...currentThread.messages];
    messages[messages.length - 1] = updatedMessage;

    final updatedThread = currentThread.copyWith(
      messages: messages,
      updatedAt: DateTime.now(),
    );

    final updatedThreads = Map<String, ChatThread>.from(_state.threads);
    updatedThreads[currentThread.id] = updatedThread;

    _updateState(_state.copyWith(threads: updatedThreads));
  }

  /// Stream response with intermediate states
  Stream<String> streamResponse(
    String prompt, {
    void Function(Map<String, dynamic>)? onIntermediateState,
  }) async* {
    _updateState(_state.copyWith(isLoading: true));

    try {
      // Simulate streaming response with intermediate states
      final words =
          'This is a simulated streaming AI response with multiple chunks and intermediate state updates.'
              .split(' ');

      for (var i = 0; i < words.length; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));

        // Simulate intermediate state updates
        if (onIntermediateState != null && i % 3 == 0) {
          onIntermediateState({
            'progress': (i / words.length * 100).round(),
            'currentWord': words[i],
            'processingState': 'generating',
          });
        }

        yield '${words[i]} ';
      }
    } finally {
      _updateState(_state.copyWith(isLoading: false));
    }
  }

  /// Reset current thread
  void resetThread() {
    if (_state.activeThreadId == null) return;

    final currentThread = _state.activeThread!;
    final updatedThread = currentThread.copyWith(
      messages: [],
      updatedAt: DateTime.now(),
    );

    final updatedThreads = Map<String, ChatThread>.from(_state.threads);
    updatedThreads[currentThread.id] = updatedThread;

    _updateState(_state.copyWith(threads: updatedThreads));
  }

  /// Load thread state from storage
  Future<void> loadThreadState(Map<String, dynamic> data) async {
    final threads = <String, ChatThread>{};

    if (data['threads'] != null) {
      for (final entry in (data['threads'] as Map).entries) {
        threads[entry.key as String] = ChatThread.fromJson(
          entry.value as Map<String, dynamic>,
        );
      }
    }

    _updateState(
      ThreadState(
        threads: threads,
        activeThreadId: data['activeThreadId'] as String?,
        isLoading: false,
      ),
    );
  }

  /// Save thread state to storage
  Map<String, dynamic> saveThreadState() {
    return {
      'threads': _state.threads.map(
        (key, thread) => MapEntry(key, thread.toJson()),
      ),
      'activeThreadId': _state.activeThreadId,
    };
  }

  void _updateState(ThreadState newState) {
    _state = newState;
    notifyListeners();
    _stateStreamController.add(_state);
  }

  @override
  void dispose() {
    _messageStreamController.close();
    _stateStreamController.close();
    super.dispose();
  }
}
