import 'dart:async';
import 'package:flutter/material.dart';

import '../models/ai_chat_config.dart';
import '../models/chat/models.dart';

/// Controller for managing chat messages and their states.
///
/// This controller handles message operations such as adding, updating,
/// and loading more messages. It also manages the welcome message state
/// and loading states for pagination.
class ChatMessagesController extends ChangeNotifier {
  // Track if the controller is still mounted to prevent race conditions
  bool _mounted = true;
  bool get mounted => _mounted;

  // Track streaming state to prevent scroll issues
  bool _isCurrentlyStreaming = false;

  /// Whether a message is currently being streamed
  bool get isCurrentlyStreaming => _isCurrentlyStreaming;

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
    ScrollBehaviorConfig? scrollBehaviorConfig,
  }) {
    _scrollBehaviorConfig = scrollBehaviorConfig;

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

  /// Configuration for scroll behavior
  ScrollBehaviorConfig? _scrollBehaviorConfig;

  /// Get the current scroll behavior configuration
  ScrollBehaviorConfig get scrollBehaviorConfig =>
      _scrollBehaviorConfig ?? const ScrollBehaviorConfig();

  /// Set the scroll behavior configuration
  set scrollBehaviorConfig(ScrollBehaviorConfig? config) {
    _scrollBehaviorConfig = config;
    debugPrint('ChatMessagesController: Scroll behavior updated to: '
        '${config?.autoScrollBehavior.toString() ?? "null"}, '
        'scrollToFirstResponseMessage: ${config?.scrollToFirstResponseMessage ?? false}');
  }

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
  VoidCallback? _scrollListener;
  Timer? _pendingScrollTimer;

  /// The ID of the first message in the current AI response
  String? _currentResponseFirstMessageId;

  /// The user of the last message added (to track response chains)
  String? _lastMessageUserId;

  /// Is the user manually scrolling
  bool _isManuallyScrolling = false;
  DateTime _lastManualScrollTime = DateTime.now();

  /// Add this property at the top of the class with other properties
  DateTime _lastScrollTime = DateTime.now();
  int _scrollDebounceMs = 500; // Default debounce time
  String?
      _lastScrollOperation; // Track the last scroll operation to prevent conflicts

  /// Sets the scroll controller for auto-scrolling
  void setScrollController(ScrollController controller) {
    // Remove the old listener if it exists
    if (_scrollController != null && _scrollListener != null) {
      _scrollController!.removeListener(_scrollListener!);
    }

    _scrollController = controller;

    // Create and add new listener to detect manual scrolling
    _scrollListener = () {
      if (_scrollController?.hasClients == true) {
        // If user is dragging or a manual scroll action is happening
        if (_scrollController!.position.isScrollingNotifier.value) {
          _isManuallyScrolling = true;
          _lastManualScrollTime = DateTime.now();
          debugPrint('USER SCROLL: Manual scrolling detected');
        } else if (_isManuallyScrolling) {
          // Reset after a short delay to allow animations to complete
          Future.delayed(const Duration(milliseconds: 300), () {
            if (DateTime.now()
                    .difference(_lastManualScrollTime)
                    .inMilliseconds >=
                300) {
              _isManuallyScrolling = false;
              debugPrint('USER SCROLL: Manual scrolling ended');
            }
          });
        }
      }
    };

    _scrollController?.addListener(_scrollListener!);
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
        '${message.user.id}_${message.createdAt.millisecondsSinceEpoch}';
  }

  /// Public method to get a message ID (for testing/debugging)
  String getMessageId(ChatMessage message) {
    return _getMessageId(message);
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
      // Determine if this is a user message using the ID and properties
      final isFromUser =
          ((message.customProperties?['isUserMessage'] as bool?) == true) ||
              (message.customProperties?['source'] == 'user') ||
              (message.user.id != 'ai' &&
                  message.user.id != 'bot' &&
                  message.user.id != 'assistant');

      // Get the user ID for response tracking
      final userId = message.user.id;

      // Get responseId if available - for linking multiple messages as one response
      final responseId = message.customProperties?['responseId'] as String?;

      // Track if this is the start of a response (user changed and it's not a user message)
      final isStartOfResponse = (_lastMessageUserId != userId && !isFromUser) ||
          message.customProperties?['isStartOfResponse'] == true;

      _lastMessageUserId = userId;

      // Create a property map to track messaging state
      final updatedProperties = <String, dynamic>{...?message.customProperties};

      // Track the first message of an AI response
      if (isStartOfResponse) {
        _currentResponseFirstMessageId = messageId;
        // Use properties to mark this as the first message of a response
        updatedProperties['isFirstResponseMessage'] = true;
        updatedProperties['isStartOfResponse'] = true;

        debugPrint(
            'NEW RESPONSE: First message ID: $messageId from user: $userId responseId: $responseId');
      }

      // When a user message appears, we need to reset the first response tracking
      if (isFromUser) {
        // Clear the first response message ID whenever a user sends a message
        // This way, the next AI message will become the first of a new response
        _currentResponseFirstMessageId = null;
        debugPrint('USER MESSAGE: Reset response tracking for user: $userId');
      }

      // For related messages with the same responseId, we want to keep the first message
      // of the chain as the scroll target
      if (responseId != null && !isStartOfResponse && !isFromUser) {
        // Check if we already have a message with this responseId flagged as start of response
        final existingFirstMessage = _messages.firstWhere(
          (msg) =>
              msg.customProperties?['responseId'] == responseId &&
              (msg.customProperties?['isStartOfResponse'] == true ||
                  msg.customProperties?['isFirstResponseMessage'] == true),
          orElse: () => message,
        );

        // If we found a message that's marked as first in this response chain,
        // use its ID for scrolling to ensure consistent behavior
        if (existingFirstMessage != message &&
            existingFirstMessage.customProperties?['responseId'] ==
                responseId) {
          final existingFirstId = _getMessageId(existingFirstMessage);
          _currentResponseFirstMessageId = existingFirstId;
          debugPrint(
              'CHAIN MESSAGE: Using existing first message ID: $existingFirstId for responseId: $responseId');
        }
      }

      // Mark user messages for identification
      if (!updatedProperties.containsKey('isUserMessage') &&
          !updatedProperties.containsKey('source')) {
        updatedProperties['isUserMessage'] = isFromUser;
        debugPrint(
            'MESSAGE TYPE: userId=${message.user.id}, isUserMessage=$isFromUser');
      }

      // Create a copy of the message with updated properties
      final updatedMessage =
          message.copyWith(customProperties: updatedProperties);

      if (paginationConfig.reverseOrder) {
        // In reverse order (newest first), new messages go at the beginning (index 0)
        // With ListView.builder(reverse: true), this puts newest messages at the bottom
        _messages.insert(0, updatedMessage);
      } else {
        // In chronological order (oldest first), new messages go at the end
        // With ListView.builder(reverse: false), this puts newest messages at the bottom
        _messages.add(updatedMessage);
      }
      _messageCache[messageId] = updatedMessage;
      notifyListeners();

      // Determine if we should scroll based on the configuration
      final config = scrollBehaviorConfig;

      // Detect if this is a user message
      final isUserMessage = updatedProperties['isUserMessage'] as bool? ??
          updatedProperties['source'] == 'user';

      // Identify the first message in a response chain
      final isFirstResponse =
          updatedProperties['isFirstResponseMessage'] as bool? ?? false;

      final shouldScroll =
          _determineShouldScroll(config, isUserMessage, isFirstResponse);

      if (shouldScroll) {
        debugPrint('SCROLLING: After render for isUserMessage=$isUserMessage');
        _scrollAfterRender(isUserMessage, isStartOfResponse, config);
      } else {
        debugPrint('NOT SCROLLING: Message doesn\'t meet scroll criteria');
      }
    }
  }

  /// Determines if scrolling should occur based on configuration and message type
  bool _determineShouldScroll(
      ScrollBehaviorConfig config, bool isUserMessage, bool isFirstResponse) {
    // If this is a user message, always scroll (user messages should be visible)
    if (isUserMessage) {
      debugPrint('SCROLL DECISION: User message - will scroll');
      return true;
    }

    switch (config.autoScrollBehavior) {
      case AutoScrollBehavior.always:
        debugPrint('SCROLL DECISION: Always mode - will scroll');
        return true;
      case AutoScrollBehavior.onNewMessage:
        final shouldScroll = isFirstResponse;
        debugPrint(
            'SCROLL DECISION: onNewMessage mode - ${shouldScroll ? "will scroll (first response)" : "will NOT scroll (continuation)"}');
        return shouldScroll;
      case AutoScrollBehavior.onUserMessageOnly:
        debugPrint(
            'SCROLL DECISION: onUserMessageOnly mode - will NOT scroll (AI message)');
        return false;
      case AutoScrollBehavior.never:
        debugPrint('SCROLL DECISION: Never scroll mode - will NOT scroll');
        return false;
    }
  }

  /// Scroll after the message is rendered
  void _scrollAfterRender(
      bool isUserMessage, bool isStartOfResponse, ScrollBehaviorConfig config) {
    // Create a unique operation ID for this scroll request
    final operationId = 'scroll_${DateTime.now().millisecondsSinceEpoch}';

    // Apply debounce for scrolling to prevent jitter
    final now = DateTime.now();
    if (now.difference(_lastScrollTime).inMilliseconds < _scrollDebounceMs) {
      debugPrint('SCROLL AFTER RENDER DEBOUNCED: Too soon after last scroll');
      return;
    }

    // Set this as the current operation
    _lastScrollOperation = operationId;

    // Store the current response ID to prevent re-scrolling if it changes during the delay
    final currentResponseId = _currentResponseFirstMessageId;

    // Check if there's an active response chain in progress by looking at the latest message
    var isPartOfResponseChain = false;
    String? latestResponseId;

    if (_messages.isNotEmpty) {
      // Look for responseId in the most recent message first
      if (paginationConfig.reverseOrder) {
        latestResponseId =
            _messages.first.customProperties?['responseId'] as String?;
      } else {
        latestResponseId =
            _messages.last.customProperties?['responseId'] as String?;
      }

      // If the latest message doesn't have a responseId, but we're tracking a current response,
      // check if the current message being added has the same responseId as the tracked response
      if (latestResponseId == null && _currentResponseFirstMessageId != null) {
        // Look for messages with the same responseId as the current tracked response
        final relatedMessages = _messages.where((msg) {
          final msgResponseId = msg.customProperties?['responseId'] as String?;
          return msgResponseId != null &&
              _messages.any((m) =>
                  _getMessageId(m) == _currentResponseFirstMessageId &&
                  m.customProperties?['responseId'] == msgResponseId);
        });
        if (relatedMessages.isNotEmpty) {
          latestResponseId =
              relatedMessages.first.customProperties?['responseId'] as String?;
        }
      }

      isPartOfResponseChain = latestResponseId != null;
    }

    // Customize delay based on scroll behavior
    final scrollDelay =
        config.autoScrollBehavior == AutoScrollBehavior.onNewMessage
            ? const Duration(milliseconds: 300) // Longer delay for onNewMessage
            : const Duration(milliseconds: 200); // Default delay

    // Add a tracking variable to prevent multiple scroll actions
    var hasScrolled = false;

    // Longer delay to ensure messages have time to render
    Future.delayed(scrollDelay, () {
      // Check if the controller is still mounted (prevents race conditions)
      if (!mounted) {
        debugPrint('SCROLL ABORTED: Controller disposed');
        return;
      }

      // Check if this operation is still the current one (prevents race conditions)
      if (_lastScrollOperation != operationId) {
        debugPrint('SCROLL ABORTED: Newer scroll operation in progress');
        return;
      }

      // Make sure the widget is still mounted and the response ID hasn't changed
      if (_scrollController?.hasClients != true) {
        debugPrint('SCROLL ABORTED: Scroll controller no longer has clients');
        return;
      }

      // Update last scroll time for debouncing
      _lastScrollTime = DateTime.now();

      debugPrint('SCROLL EXECUTION: isUserMessage=$isUserMessage, '
          'scrollToFirstResponseMessage=${config.scrollToFirstResponseMessage}, '
          'isStartOfResponse=$isStartOfResponse, '
          'currentResponseFirstMessageId=$currentResponseId, '
          'isPartOfResponseChain=$isPartOfResponseChain, '
          'latestResponseId=$latestResponseId, '
          'autoScrollBehavior=${config.autoScrollBehavior.name}');

      // Handle scrolling to first message - only scroll to first when appropriate
      if (!isUserMessage &&
          config.scrollToFirstResponseMessage &&
          latestResponseId != null &&
          isStartOfResponse) {
        // Only scroll to first message if this is the START of a response
        // This prevents later messages in the chain from overriding the scroll position
        debugPrint(
            'AUTO SCROLL TO FIRST: responseId=$latestResponseId, isStartOfResponse=$isStartOfResponse');

        // Use longer debounce for response chains to prevent conflicts
        _scrollDebounceMs = 800;

        forceScrollToFirstMessageInChain(latestResponseId);
        hasScrolled = true;
      }
      // Handle continuation messages in a response chain
      else if (!isUserMessage &&
          config.scrollToFirstResponseMessage &&
          latestResponseId != null &&
          isPartOfResponseChain &&
          !isStartOfResponse) {
        // For continuation messages, also scroll to first to maintain position
        debugPrint(
            'MAINTAIN SCROLL TO FIRST: responseId=$latestResponseId, maintaining first message position');

        forceScrollToFirstMessageInChain(latestResponseId);
        hasScrolled = true;
      }
      // Handle scrolling to first message by ID (backward compatibility)
      else if (!isUserMessage &&
          config.scrollToFirstResponseMessage &&
          currentResponseId != null &&
          _messageCache.containsKey(currentResponseId)) {
        // Use direct scrolling for this case too
        final currentMsg = _messageCache[currentResponseId]!;
        final responseId =
            currentMsg.customProperties?['responseId'] as String?;

        if (responseId != null) {
          debugPrint(
              'USING DIRECT FORCE SCROLL to first message responseId: $responseId');
          forceScrollToFirstMessageInChain(responseId);
        } else {
          // Legacy support for older message format
          debugPrint('SCROLLING TO FIRST RESPONSE BY ID: $currentResponseId');
          scrollToMessage(currentResponseId);
        }
        hasScrolled = true;
      }
      // Only scroll to bottom if we haven't already performed a scroll action
      // AND we don't have any custom scrolling behavior active
      else if (!hasScrolled && !config.scrollToFirstResponseMessage) {
        // Standard behavior - scroll to bottom
        if (isUserMessage) {
          debugPrint('SCROLLING TO BOTTOM: User message');
        } else if (config.autoScrollBehavior == AutoScrollBehavior.always) {
          debugPrint('SCROLLING TO BOTTOM: Always mode');
        } else {
          debugPrint('SCROLLING TO BOTTOM: Default behavior');
        }

        scrollToBottom(
            config.scrollAnimationDuration, config.scrollAnimationCurve);
      } else if (!hasScrolled) {
        debugPrint('SKIPPING DEFAULT SCROLL: Custom scroll behavior is active');
      }
    });
  }

  /// Scrolls to a specific message by ID with improved position calculation
  void scrollToMessage(String messageId) {
    if (_scrollController?.hasClients != true) return;

    // Don't interrupt user's manual scrolling
    if (_isManuallyScrolling) {
      debugPrint('SCROLL CANCELED: User is manually scrolling');
      return;
    }

    try {
      // Find the message index
      final index =
          _messages.indexWhere((msg) => _getMessageId(msg) == messageId);
      if (index == -1) {
        debugPrint('MESSAGE NOT FOUND: Cannot scroll to message $messageId');
        return;
      }

      debugPrint(
          'SCROLLING: To message at index $index with ID $messageId, reverseOrder: ${paginationConfig.reverseOrder}');

      // Get configuration for animation timing
      final config = scrollBehaviorConfig;

      // Use the same improved logic as forceScrollToFirstMessageInChain
      final maxExtent = _scrollController!.position.maxScrollExtent;
      final itemCount = _messages.length;

      debugPrint(
          'SCROLL INFO: maxExtent=$maxExtent, itemCount=$itemCount, messageIndex=$index');

      double targetPosition;

      if (paginationConfig.reverseOrder) {
        // In reverse order mode (newest messages at bottom)
        if (index == 0) {
          targetPosition = 0.0; // Show the newest message (at bottom)
        } else {
          // Calculate position to show this message near the top of the viewport
          targetPosition = maxExtent * (index / itemCount) * 0.8;
        }
      } else {
        // In chronological mode (oldest messages at top)
        if (index < itemCount * 0.2) {
          // If message is in first 20% of list, scroll to top
          targetPosition = 0.0;
        } else {
          // Calculate position to show this message near the top of viewport
          targetPosition =
              (maxExtent * (index / itemCount)) - (maxExtent * 0.2);
        }
      }

      // Clamp to valid range
      targetPosition = targetPosition.clamp(0.0, maxExtent);

      debugPrint('SCROLLING: To position $targetPosition');

      _scrollController!.animateTo(
        targetPosition,
        duration: config.scrollAnimationDuration,
        curve: config.scrollAnimationCurve,
      );
    } catch (e) {
      debugPrint('ERROR SCROLLING: $e');
      // Do not scroll to bottom as fallback - this causes the double-scroll issue
    }
  }

  /// Scrolls to a specific message directly
  void scrollToMessageObject(ChatMessage message) {
    scrollToMessage(getMessageId(message));
  }

  /// Scrolls to the bottom of the message list
  void scrollToBottom([
    Duration? duration,
    Curve? curve,
  ]) {
    if (_scrollController?.hasClients != true) return;

    // Don't interrupt user's manual scrolling
    if (_isManuallyScrolling) {
      debugPrint('SCROLL BOTTOM CANCELED: User is manually scrolling');
      return;
    }

    // Apply debounce for scrollToBottom to prevent jitter
    // (less strict than for force scroll)
    final now = DateTime.now();
    const minInterval = 200; // ms
    if (now.difference(_lastScrollTime).inMilliseconds < minInterval) {
      debugPrint('SCROLL TO BOTTOM DEBOUNCED: Too soon after last scroll');
      return;
    }
    _lastScrollTime = now;

    // Use slightly longer animation for onNewMessage to reduce jitter
    final effectiveDuration =
        duration ?? scrollBehaviorConfig.scrollAnimationDuration;
    final effectiveCurve = curve ?? scrollBehaviorConfig.scrollAnimationCurve;

    // Log the animation being used
    debugPrint(
        'SCROLL TO BOTTOM: Using duration=${effectiveDuration.inMilliseconds}ms, curve=${effectiveCurve.runtimeType}');

    try {
      if (paginationConfig.reverseOrder) {
        // In reverse mode, "bottom" is actually the top (0.0)
        _scrollController!.animateTo(
          0.0,
          duration: effectiveDuration,
          curve: effectiveCurve,
        );
      } else {
        // In chronological mode, bottom is maxScrollExtent
        _scrollController!.animateTo(
          _scrollController!.position.maxScrollExtent,
          duration: effectiveDuration,
          curve: effectiveCurve,
        );
      }
    } catch (e) {
      // If we get an error (eg. because widget is disposing), just ignore it
      // This prevents errors when scrolling during state changes
      debugPrint('SCROLL TO BOTTOM ERROR: $e');
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

      // Check if this is a user message
      final isUserMessage =
          message.customProperties?['isUserMessage'] as bool? ??
              message.customProperties?['source'] == 'user';

      // When updating streaming messages, make sure we maintain proper state transitions
      if (index != -1 && isStreaming) {
        // For streaming messages, preserve the original streaming state if present
        final existingIsStreaming =
            _messages[index].customProperties?['isStreaming'] as bool? ?? false;

        // Fix: Preserve the isFirstResponseMessage and isStartOfResponse flags during updates
        final existingIsFirstResponse = _messages[index]
                .customProperties?['isFirstResponseMessage'] as bool? ??
            false;
        final existingIsStartOfResponse =
            _messages[index].customProperties?['isStartOfResponse'] as bool? ??
                false;

        // Create updated properties with preserved flags
        final updatedProperties = {...?message.customProperties};

        // Preserve the response flags during streaming updates
        if (existingIsFirstResponse) {
          updatedProperties['isFirstResponseMessage'] = true;
        }

        if (existingIsStartOfResponse) {
          updatedProperties['isStartOfResponse'] = true;
        }

        // Only override the streaming state if explicitly set to false (indicating end of stream)
        if (existingIsStreaming && isStreaming) {
          // Keep streaming active - preserve existing ID and streaming flag
          _messages[index] =
              message.copyWith(customProperties: updatedProperties);
          _messageCache[messageId] = _messages[index];
        } else {
          // End of streaming or non-streaming update - regular update
          _messages[index] =
              message.copyWith(customProperties: updatedProperties);
          _messageCache[messageId] = _messages[index];
        }
      } else if (index != -1) {
        // Regular non-streaming message update
        // Fix: Also preserve response flags for non-streaming updates
        final existingIsFirstResponse = _messages[index]
                .customProperties?['isFirstResponseMessage'] as bool? ??
            false;
        final existingIsStartOfResponse =
            _messages[index].customProperties?['isStartOfResponse'] as bool? ??
                false;

        // Create updated properties with preserved flags
        final updatedProperties = {...?message.customProperties};

        if (existingIsFirstResponse) {
          updatedProperties['isFirstResponseMessage'] = true;
        }

        if (existingIsStartOfResponse) {
          updatedProperties['isStartOfResponse'] = true;
        }

        _messages[index] =
            message.copyWith(customProperties: updatedProperties);
        _messageCache[messageId] = _messages[index];
      } else {
        // Add new message if not found - respecting list order
        // For new messages being created directly through updateMessage (rare case),
        // preserve any isStartOfResponse flag that might be set
        final newMsgProperties = {...?message.customProperties};

        // If this is explicitly marked as start of response, make it consistent
        if (newMsgProperties['isStartOfResponse'] == true) {
          newMsgProperties['isFirstResponseMessage'] = true;
          _currentResponseFirstMessageId = messageId;
        }

        final updatedMessage =
            message.copyWith(customProperties: newMsgProperties);

        if (paginationConfig.reverseOrder) {
          _messages.insert(0, updatedMessage);
        } else {
          _messages.add(updatedMessage);
        }
        _messageCache[messageId] = updatedMessage;
      }

      // Safe notification and scrolling strategy
      if (isStreaming) {
        _isCurrentlyStreaming = true;
        // For streaming: just notify, no scrolling to prevent assertion errors
        notifyListeners();
      } else {
        // If we were streaming and now we're not, this is the end of stream
        final wasStreaming = _isCurrentlyStreaming;
        _isCurrentlyStreaming = false;

        // Always notify listeners
        notifyListeners();

        // Only scroll if configured to do so and not during rapid updates
        final config = scrollBehaviorConfig;
        var shouldScroll = false;
        switch (config.autoScrollBehavior) {
          case AutoScrollBehavior.always:
            // For streaming end, scroll after a delay to prevent assertion errors
            shouldScroll = true;
            break;
          case AutoScrollBehavior.onNewMessage:
            // Only scroll on truly new messages (index == -1) or when streaming ends
            shouldScroll = index == -1 || wasStreaming;
            break;
          case AutoScrollBehavior.onUserMessageOnly:
            shouldScroll = isUserMessage;
            break;
          case AutoScrollBehavior.never:
            shouldScroll = false;
            break;
        }

        if (shouldScroll && wasStreaming) {
          // For streaming end, use a longer delay to prevent assertion errors
          // Cancel any pending scroll timer first
          _pendingScrollTimer?.cancel();
          _pendingScrollTimer = Timer(const Duration(milliseconds: 500), () {
            if (mounted && _scrollController?.hasClients == true) {
              _scrollAfterRender(isUserMessage, false, config);
            }
            _pendingScrollTimer = null;
          });
        } else if (shouldScroll) {
          _scrollAfterRender(isUserMessage, false, config);
        }
      }
    } catch (e) {
      debugPrint('Error updating message: $e');
      // If updating fails, try to add as a new message instead
      try {
        final newId =
            '${message.user.id}_${DateTime.now().millisecondsSinceEpoch}';
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

        // Only scroll if configured to do so for new messages
        final config = scrollBehaviorConfig;

        // Detect if this is a user message
        final isUserMessage =
            message.customProperties?['isUserMessage'] as bool? ??
                message.customProperties?['source'] == 'user';

        // Identify the first message in a response chain
        final isFirstResponse =
            message.customProperties?['isFirstResponseMessage'] as bool? ??
                false;

        var shouldScroll = false;
        switch (config.autoScrollBehavior) {
          case AutoScrollBehavior.always:
          case AutoScrollBehavior.onNewMessage:
            shouldScroll = !isUserMessage && !isFirstResponse;
            break;
          case AutoScrollBehavior.onUserMessageOnly:
            shouldScroll = isUserMessage && !isFirstResponse;
            break;
          case AutoScrollBehavior.never:
            shouldScroll = false;
            break;
        }

        if (shouldScroll) {
          _scrollAfterRender(false, false, config);
        } else if (isUserMessage && isFirstResponse) {
          debugPrint('SKIPPING SCROLL: Custom scroll behavior is active');
        }
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

    // Only scroll to bottom if configured to do so
    final config = scrollBehaviorConfig;

    if (_messages.isNotEmpty &&
        config.autoScrollBehavior != AutoScrollBehavior.never) {
      const isUserMessage = false; // Default assumption
      _scrollAfterRender(isUserMessage, false, config);
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
      final moreMessages = loadCallback != null
          ? await loadCallback()
          : _onLoadMoreMessagesCallback != null
              ? await _onLoadMoreMessagesCallback!(
                  _messages.isNotEmpty ? _messages.last : null)
              : <ChatMessage>[];

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

  /// Scrolls to a specific message directly with maximum reliability
  /// This is a more direct approach for ensuring the first message is visible
  void forceScrollToTop() {
    if (_scrollController?.hasClients != true) return;

    try {
      // Force scroll to the very top first (0.0)
      _scrollController!.jumpTo(0.0);
      debugPrint('FORCE SCROLL: Jumped to absolute top position');
    } catch (e) {
      debugPrint('ERROR FORCE SCROLLING: $e');
    }
  }

  /// Find first message in a response chain and force scroll to it with extra reliability
  void forceScrollToFirstMessageInChain(String responseId) {
    if (_scrollController?.hasClients != true) return;

    // Implement debounce for scrolling to prevent jitter
    final now = DateTime.now();
    if (now.difference(_lastScrollTime).inMilliseconds < _scrollDebounceMs) {
      debugPrint('SCROLL DEBOUNCED: Too soon after last scroll');
      return;
    }
    _lastScrollTime = now;

    // Log information about the animation being used for debugging
    final animationInfo =
        'Animation: duration=${scrollBehaviorConfig.scrollAnimationDuration.inMilliseconds}ms, '
        'curve=${scrollBehaviorConfig.scrollAnimationCurve.runtimeType}';
    debugPrint('SCROLL ANIMATION INFO: $animationInfo');

    try {
      // Find the first message with this responseId
      final firstMessageInChain = _messages.firstWhere(
        (msg) =>
            msg.customProperties?['responseId'] == responseId &&
            (msg.customProperties?['isStartOfResponse'] == true ||
                msg.customProperties?['isFirstResponseMessage'] == true),
        orElse: () => _messages.firstWhere(
          (msg) => msg.customProperties?['responseId'] == responseId,
          orElse: () =>
              throw Exception('No message found with responseId: $responseId'),
        ),
      );

      // Find the index of this message
      final index = _messages.indexOf(firstMessageInChain);
      if (index < 0) {
        debugPrint('FORCE SCROLL: Message not found in list');
        return;
      }

      debugPrint(
          'FORCE SCROLL: Found first message in chain at index $index with responseId: $responseId, reverseOrder: ${paginationConfig.reverseOrder}');

      // Always use animation when testing different animation curves
      final scrollDuration = scrollBehaviorConfig.scrollAnimationDuration;
      final scrollCurve = scrollBehaviorConfig.scrollAnimationCurve;

      debugPrint(
          'APPLYING ANIMATION: duration=${scrollDuration.inMilliseconds}ms, curve=$scrollCurve');

      // Use a simple approach: scroll to a calculated position based on message index
      // Get list properties
      final maxExtent = _scrollController!.position.maxScrollExtent;
      final itemCount = _messages.length;

      debugPrint(
          'SCROLL INFO: maxExtent=$maxExtent, itemCount=$itemCount, messageIndex=$index');

      double targetPosition;

      if (paginationConfig.reverseOrder) {
        // In reverse order mode (newest messages at bottom)
        // Index 0 = newest message (bottom), higher index = older messages (top)
        // We want to show the first message of the response, so scroll towards the top
        if (index == 0) {
          targetPosition = 0.0; // Show the newest message (at bottom)
        } else {
          // Calculate position to show this message near the top of the viewport
          // Since it's reverse order, we need to scroll down more to see older messages
          targetPosition = maxExtent *
              (index / itemCount) *
              0.8; // Show near top of viewport
        }
      } else {
        // In chronological mode (oldest messages at top)
        // Index 0 = oldest message (top), higher index = newer messages (bottom)
        // We want to show the first message of the response near the top
        if (index < itemCount * 0.2) {
          // If message is in first 20% of list, scroll to top
          targetPosition = 0.0;
        } else {
          // Calculate position to show this message near the top of viewport
          targetPosition =
              (maxExtent * (index / itemCount)) - (maxExtent * 0.2);
        }
      }

      // Clamp to valid range
      targetPosition = targetPosition.clamp(0.0, maxExtent);

      debugPrint(
          'FORCE SCROLL: Scrolling to position $targetPosition (reverse: ${paginationConfig.reverseOrder})');

      _scrollController!.animateTo(
        targetPosition,
        duration: scrollDuration,
        curve: scrollCurve,
      );

      debugPrint(
          'FORCE SCROLL: Animation started to first message in chain using ${scrollCurve.runtimeType}');
    } catch (e) {
      debugPrint('ERROR FORCE SCROLLING TO CHAIN: $e');
      // Fallback: just scroll to top to show the beginning of messages
      try {
        _scrollController!.animateTo(
          0.0,
          duration: scrollBehaviorConfig.scrollAnimationDuration,
          curve: scrollBehaviorConfig.scrollAnimationCurve,
        );
        debugPrint('FALLBACK SCROLL: Scrolled to top as fallback');
      } catch (fallbackError) {
        debugPrint('FALLBACK SCROLL ERROR: $fallbackError');
      }
    }
  }

  @override
  void dispose() {
    // Mark as unmounted to prevent race conditions
    _mounted = false;
    _isCurrentlyStreaming = false;

    // Cancel any pending scroll timer to prevent memory leaks
    _pendingScrollTimer?.cancel();
    _pendingScrollTimer = null;

    // Remove scroll listener to prevent memory leaks
    if (_scrollController != null && _scrollListener != null) {
      _scrollController!.removeListener(_scrollListener!);
    }
    _scrollController = null;
    _scrollListener = null;

    _messages.clear();
    _messageCache.clear();
    super.dispose();
  }
}
