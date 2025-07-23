import 'package:flutter/material.dart';

import '../models/ai_chat_config.dart';
import '../models/chat/models.dart';

/// Controller for managing chat messages and their states.
///
/// This controller handles message operations such as adding, updating,
/// and loading more messages. It also manages the welcome message state
/// and loading states for pagination.
class ChatMessagesController extends ChangeNotifier {
  /// Creates a new chat messages controller.
  ///
  /// [initialMessages] - Optional list of messages to initialize the chat with.
  /// [paginationConfig] - Configuration for pagination behavior.
  /// [onLoadMoreMessages] - Callback for loading more messages (for backward compatibility).
  /// [showWelcomeMessage] - Whether to show the welcome message.
  ChatMessagesController({
    final List<ChatMessage>? initialMessages,
    this.paginationConfig = const PaginationConfig(),
    final Future<List<ChatMessage>> Function(ChatMessage? lastMessage)?
        onLoadMoreMessages,
    bool showWelcomeMessage = false,
  }) {
    if (initialMessages != null && initialMessages.isNotEmpty) {
      _messages = List.from(initialMessages);
      _messageCache = {for (var m in _messages) _getMessageId(m): m};
      _showWelcomeMessage = false;
    } else {
      _showWelcomeMessage = showWelcomeMessage;
    }

    // Store the callback for backward compatibility
    _onLoadMoreMessagesCallback = onLoadMoreMessages;
  }

  /// Configuration for pagination behavior
  final PaginationConfig paginationConfig;

  /// Callback for loading more messages (backward compatibility)
  Future<List<ChatMessage>> Function(ChatMessage? lastMessage)?
      _onLoadMoreMessagesCallback;

  List<ChatMessage> _messages = [];
  Map<String, ChatMessage> _messageCache = {};
  bool _showWelcomeMessage = false;
  bool _isLoadingMore = false;
  bool _hasMoreMessages = true;
  int _currentPage = 1;
  ScrollController? _scrollController;

  /// Sets the scroll controller for auto-scrolling
  void setScrollController(ScrollController controller) {
    _scrollController = controller;
  }

  /// Whether more messages are currently being loaded.
  bool get isLoadingMore => _isLoadingMore;

  /// Whether there are more messages to load.
  bool get hasMoreMessages => _hasMoreMessages;

  /// List of all chat messages.
  /// If paginationConfig.reverseOrder is true, newest messages are first (index 0).
  /// If paginationConfig.reverseOrder is false, oldest messages are first (index 0).
  List<ChatMessage> get messages => _messages;

  /// Whether to show the welcome message.
  bool get showWelcomeMessage => _showWelcomeMessage;

  /// Sets whether to show the welcome message
  set showWelcomeMessage(bool value) {
    if (_showWelcomeMessage != value) {
      _showWelcomeMessage = value;
      notifyListeners();
    }
  }

  /// Current page of pagination
  int get currentPage => _currentPage;

  /// Generates a unique ID for a message
  String _getMessageId(ChatMessage message) {
    final customId = message.customProperties?['id'] as String?;
    return customId ??
        '${message.user.id}_${message.createdAt.millisecondsSinceEpoch}_${message.text.hashCode}';
  }

void addAgentMessage(ChatMessage message) {
    final messageId = _getMessageId(message);
    if (!_messageCache.containsKey(messageId)) {
      if (paginationConfig.reverseOrder) {
        // In reverse order (newest first), new messages go at the beginning (index 0)
        // With ListView.builder(reverse: true), this puts newest messages at the bottom
        _messages.insert(0, message);
      } else {
        // In chronological order (oldest first), new messages go at the end
        // With ListView.builder(reverse: false), this puts newest messages at the bottom
        _messages.add(message);
      }
      _messageCache[messageId] = message;
      notifyListeners();

      // After adding a message, scroll to bottom
      //_scrollToBottomAfterRender();
    }
  }
  /// Adds a new message to the chat.
  void addMessage(ChatMessage message) {
    final messageId = _getMessageId(message);
    if (!_messageCache.containsKey(messageId)) {
      if (paginationConfig.reverseOrder) {
        // In reverse order (newest first), new messages go at the beginning (index 0)
        // With ListView.builder(reverse: true), this puts newest messages at the bottom
        _messages.insert(0, message);
      } else {
        // In chronological order (oldest first), new messages go at the end
        // With ListView.builder(reverse: false), this puts newest messages at the bottom
        _messages.add(message);
      }
      _messageCache[messageId] = message;
      notifyListeners();

      // After adding a message, scroll to bottom
      _scrollToBottomAfterRender();
    }
  }

  /// Scroll to bottom after the message is rendered
  void _scrollToBottomAfterRender() {
    // Use a microtask to ensure the message is rendered first
    // Then add a short delay to ensure layout is complete
    Future.microtask(() {
      // Add a small delay to ensure the rendering is complete
      Future.delayed(const Duration(milliseconds: 100), scrollToBottom);
    });
  }

  /// Scrolls to the bottom of the message list
  void scrollToBottom() {
    if (_scrollController?.hasClients == true) {
      try {
        if (paginationConfig.reverseOrder) {
          // In reverse mode, "bottom" is actually the top (0.0)
          _scrollController!.animateTo(
            0.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        } else {
          // In chronological mode, bottom is maxScrollExtent
          _scrollController!.animateTo(
            _scrollController!.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      } catch (e) {
        // If we get an error (eg. because widget is disposing), just ignore it
        // This prevents errors when scrolling during state changes
      }
    }
  }

  /// Adds multiple messages to the chat at once.
  ///
  /// In reverse order mode, the expected behavior with pagination is:
  /// - Newest messages (initial) appear at the top of the list (index 0)
  /// - When loading more messages, older ones appear at the bottom
  ///
  /// In chronological order mode:
  /// - Oldest messages (initial) appear at the top of the list (index 0)
  /// - When loading more messages, newer ones appear at the bottom
  void addMessages(List<ChatMessage> messages) {
    var hasNewMessages = false;

    for (final message in messages) {
      final messageId = _getMessageId(message);
      if (!_messageCache.containsKey(messageId)) {
        // For pagination, we always append at the end regardless of order mode
        // This is appropriate for loading older messages in both modes
        _messages.add(message);
        _messageCache[messageId] = message;
        hasNewMessages = true;
      }
    }

    if (hasNewMessages) {
      notifyListeners();
    }
  }

  /// Updates an existing message or adds it if not found.
  ///
  /// Useful for updating streaming messages or editing existing ones.
  void updateMessage(final ChatMessage message) {
    try {
      // Get the message ID - first from customProperties, then calculate if not present
      final customId = message.customProperties?['id'] as String?;
      final messageId = customId ?? _getMessageId(message);

      // Check if the message exists
      final index = _messages.indexWhere(
        (final msg) => _getMessageId(msg) == messageId,
      );

      final isStreaming =
          message.customProperties?['isStreaming'] as bool? ?? false;

      // When updating streaming messages, make sure we maintain proper state transitions
      if (index != -1 && isStreaming) {
        // For streaming messages, preserve the original streaming state if present
        final existingIsStreaming =
            _messages[index].customProperties?['isStreaming'] as bool? ?? false;

        // Only override the streaming state if explicitly set to false (indicating end of stream)
        if (existingIsStreaming && isStreaming) {
          // Keep streaming active - preserve existing ID and streaming flag
          _messages[index] = message;
          _messageCache[messageId] = message;
        } else {
          // End of streaming or non-streaming update - regular update
          _messages[index] = message;
          _messageCache[messageId] = message;
        }
      } else if (index != -1) {
        // Regular non-streaming message update
        _messages[index] = message;
        _messageCache[messageId] = message;
      } else {
        // Add new message if not found - respecting list order
        if (paginationConfig.reverseOrder) {
          _messages.insert(0, message);
        } else {
          _messages.add(message);
        }
        _messageCache[messageId] = message;
      }

      // Notify listeners about the change
      notifyListeners();

      // Also scroll to bottom when a message is updated
      // This is important for streaming messages
      _scrollToBottomAfterRender();
    } catch (e) {
      debugPrint('Error updating message: $e');
      // If updating fails, try to add as a new message instead
      try {
        final newId =
            '${message.user.id}_${DateTime.now().millisecondsSinceEpoch}_${message.text.hashCode}';
        final messageWithId = ChatMessage(
          text: message.text,
          user: message.user,
          createdAt: message.createdAt,
          isMarkdown: message.isMarkdown,
          customProperties: {...?message.customProperties, 'id': newId},
        );

        if (paginationConfig.reverseOrder) {
          _messages.insert(0, messageWithId);
        } else {
          _messages.add(messageWithId);
        }
        _messageCache[newId] = messageWithId;
        notifyListeners();
        _scrollToBottomAfterRender();
      } catch (fallbackError) {
        debugPrint('Failed to add message as fallback: $fallbackError');
      }
    }
  }

  /// Replaces all existing messages with a new list.
  void setMessages(List<ChatMessage> messages) {
    // Make a defensive copy of the messages
    _messages = List<ChatMessage>.from(messages);

    // Ensure the ordering is correct based on pagination configuration
    if (paginationConfig.reverseOrder) {
      // For reverse mode, sort by newest first
      // With ListView.builder(reverse: true), newest messages will appear at the bottom
      _messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else {
      // For chronological mode, sort by oldest first
      // With ListView.builder(reverse: false), newest messages will appear at the bottom
      _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }

    _messageCache = {for (var m in _messages) _getMessageId(m): m};
    _currentPage = 1;
    notifyListeners();

    // Scroll to bottom after setting messages
    if (_messages.isNotEmpty) {
      _scrollToBottomAfterRender();
    }
  }

  /// Clears all messages and shows the welcome message.
  void clearMessages() {
    _messages.clear();
    _messageCache.clear();
    _currentPage = 1;
    _hasMoreMessages = true;
    notifyListeners();
  }

  /// Loads more messages using the provided callback.
  ///
  /// Returns early if already loading or no more messages.
  /// The callback should return a list of messages to add.
  Future<void> loadMore(
      Future<List<ChatMessage>> Function()? loadCallback) async {
//    if (_isLoadingMore || !_hasMoreMessages || !paginationConfig.enabled) {
//      return;
//    }

    try {
      _isLoadingMore = true;
      notifyListeners();

      // Simulate network delay if specified
      if (paginationConfig.loadingDelay.inMilliseconds > 0) {
        await Future<void>.delayed(paginationConfig.loadingDelay);
      }

      // Get more messages from the callback or use the backward compatibility one
      final List<ChatMessage> moreMessages;
      if (loadCallback != null) {
        moreMessages = await loadCallback();
      } else if (_onLoadMoreMessagesCallback != null) {
        // Use the last message as a reference for pagination
        final lastMessage = _messages.isNotEmpty ? _messages.last : null;
        moreMessages = await _onLoadMoreMessagesCallback!(lastMessage);
      } else {
        moreMessages = [];
      }

      if (moreMessages.isEmpty) {
        _hasMoreMessages = false;
      } else {
        // Add the messages
        addMessages(moreMessages);
        _currentPage++;
      }
    } catch (e) {
      _hasMoreMessages = true; // Allow retry on error
      rethrow;
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Resets pagination state
  void resetPagination() {
    _hasMoreMessages = true;
    _currentPage = 1;
    notifyListeners();
  }

  /// Handles an example question by creating and adding appropriate messages.
  void handleExampleQuestion(
      String question, ChatUser currentUser, ChatUser aiUser) {
    hideWelcomeMessage();
    addMessage(
      ChatMessage(
        text: question,
        user: currentUser,
        createdAt: DateTime.now(),
      ),
    );
  }

  void hideWelcomeMessage() {
    _showWelcomeMessage = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _messages.clear();
    _messageCache.clear();
    super.dispose();
  }
}
