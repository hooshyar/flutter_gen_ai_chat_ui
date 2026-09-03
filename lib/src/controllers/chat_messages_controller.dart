import 'dart:async';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderAbstractViewport;

import '../models/ai_chat_config.dart';
import '../models/chat/models.dart';

/// Controller for managing chat messages and their states.
///
/// `ChatMessagesController` is the canonical message store for an
/// `AiChatWidget`. It is a [ChangeNotifier] and is owned by the consumer
/// across rebuilds (same pattern as `TextEditingController`).
///
/// The controller exposes `addMessage`, `updateMessage`, `clearMessages`
/// and `scrollToBottom` for the common chat flow, plus pagination
/// (`loadMore`, `resetPagination`), streaming helpers
/// (`addStreamingMessage`, `setStreamingMessage`, `stopStreamingMessage`),
/// and scroll-targeting helpers
/// (`scrollToMessage`, `forceScrollToFirstMessageInChain`).
///
/// Streaming usage:
/// ```dart
/// // 1. Add an empty AI message with a stable id.
/// const responseId = 'response-42';
/// controller.addMessage(ChatMessage(
///   user: aiUser,
///   text: '',
///   createdAt: DateTime.now(),
///   customProperties: {'id': responseId, 'isStreaming': true},
/// ));
///
/// // 2. As tokens arrive, replace the text in-place.
/// await for (final delta in tokenStream) {
///   accumulated += delta;
///   controller.updateMessage(ChatMessage(
///     user: aiUser,
///     text: accumulated,
///     createdAt: DateTime.now(),
///     customProperties: {'id': responseId, 'isStreaming': true},
///   ));
/// }
///
/// // 3. Flip isStreaming to false to end the animation.
/// controller.stopStreamingMessage(responseId);
/// ```
///
/// Always call [dispose] when the owning widget is removed; pending scroll
/// and streaming-simulation timers are cancelled in `dispose`.
class ChatMessagesController extends ChangeNotifier {
  // Track if the controller is still mounted to prevent race conditions
  bool _mounted = true;

  /// Whether this controller has not yet been disposed.
  ///
  /// Becomes false inside [dispose] and stays false afterwards. Used
  /// internally to short-circuit scheduled callbacks that would otherwise
  /// notify a disposed controller.
  bool get mounted => _mounted;

  // Track streaming state to prevent scroll issues
  bool _isCurrentlyStreaming = false;

  /// Whether a message is currently being streamed
  bool get isCurrentlyStreaming => _isCurrentlyStreaming;

  /// The ID of the message currently being streamed
  String? get currentlyStreamingMessageId => _currentlyStreamingMessageId;

  /// The ID of the most recently delivered (non-streaming) AI message.
  /// Cleared after the first frame so the animation only plays once.
  String? get newlyDeliveredMessageId => _newlyDeliveredMessageId;

  /// Creates a new chat messages controller.
  ///
  /// [initialMessages] - Optional list of messages to initialize the chat with.
  /// [paginationConfig] - Configuration for pagination behavior.
  /// [onLoadMoreMessages] - Callback for loading more messages (for backward compatibility).
  /// [showWelcomeMessage] - Whether to show the welcome message.
  /// [persistence] - Optional hook for restoring/saving a long-running thread
  /// across app restarts. See [restoreFromPersistence] and [autoPersist].
  ChatMessagesController({
    final List<ChatMessage>? initialMessages,
    this.paginationConfig = const PaginationConfig(),
    final Future<List<ChatMessage>> Function(ChatMessage? lastMessage)?
        onLoadMoreMessages,
    bool showWelcomeMessage = false,
    ScrollBehaviorConfig? scrollBehaviorConfig,
    this.persistence,
    this.autoPersist = true,
    this.persistDebounce = const Duration(milliseconds: 500),
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

  /// Optional hook for restoring/saving a long-running thread across app
  /// restarts. Null by default — persistence is entirely opt-in and never
  /// forces a storage backend. See [ChatPersistence].
  final ChatPersistence? persistence;

  /// Whether to automatically call [ChatPersistence.saveMessages] (debounced
  /// by [persistDebounce]) after a message-list mutation, when [persistence]
  /// is set. Has no effect when [persistence] is null. Defaults to true so
  /// setting `persistence` alone is enough to keep storage in sync; set to
  /// false to call [persistNow] manually instead (e.g. only on app
  /// backgrounding, to avoid writing on every keystroke of a streamed reply).
  final bool autoPersist;

  /// How long to wait after the last mutation before calling
  /// [ChatPersistence.saveMessages], when [autoPersist] is true. Coalesces a
  /// burst of `updateMessage` calls during streaming into a single save
  /// instead of one per chunk.
  final Duration persistDebounce;

  Timer? _persistDebounceTimer;

  /// Loads messages from [persistence] and replaces the current list.
  ///
  /// A no-op if [persistence] is null. Call this explicitly (e.g. once in
  /// `initState`, before the first frame) rather than having the
  /// constructor do it implicitly — a constructor can't be `async`, and an
  /// explicit call lets the consumer show a loading state around the
  /// `await` and decide exactly when a restore happens.
  Future<void> restoreFromPersistence() async {
    final store = persistence;
    if (store == null) return;
    final restored = await store.loadMessages();
    if (!_mounted) return;
    setMessages(restored);
  }

  /// Immediately calls [ChatPersistence.saveMessages] with the current
  /// message list, bypassing [persistDebounce]. A no-op if [persistence] is
  /// null. Useful when [autoPersist] is false and you want to persist at a
  /// specific moment (e.g. app backgrounding) instead of after every
  /// mutation.
  Future<void> persistNow() async {
    final store = persistence;
    if (store == null) return;
    _persistDebounceTimer?.cancel();
    _persistDebounceTimer = null;
    await store.saveMessages(List.unmodifiable(_messages));
  }

  /// Schedules a debounced [ChatPersistence.saveMessages] call, restarting
  /// the debounce window on every call — a trailing debounce, so a burst of
  /// mutations (e.g. word-by-word streaming) results in one save shortly
  /// after the burst ends, not one per mutation. No-ops when [persistence]
  /// is null or [autoPersist] is false.
  void _scheduleAutoPersist() {
    if (persistence == null || !autoPersist) return;
    _persistDebounceTimer?.cancel();
    _persistDebounceTimer = Timer(persistDebounce, () {
      _persistDebounceTimer = null;
      if (!_mounted) return;
      persistence!.saveMessages(List.unmodifiable(_messages));
    });
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

  /// Sets which message is currently being streamed
  void setStreamingMessage(String? messageId) {
    if (_currentlyStreamingMessageId != messageId) {
      _currentlyStreamingMessageId = messageId;
      _isCurrentlyStreaming = messageId != null;
      notifyListeners();
      debugPrint(
          'ChatMessagesController: Streaming message set to: $messageId');
    }
  }

  /// Stops streaming for a specific message (marks it as complete)
  void stopStreamingMessage(String messageId) {
    if (_currentlyStreamingMessageId == messageId) {
      _currentlyStreamingMessageId = null;
      _isCurrentlyStreaming = false;
      notifyListeners();
      debugPrint(
          'ChatMessagesController: Streaming stopped for message: $messageId');
    }
  }

  /// Adds a new message with streaming enabled
  void addStreamingMessage(ChatMessage message) {
    // Add the message first
    addMessage(message);

    // If it's an AI message, keep it streaming
    final isFromUser =
        message.customProperties?['isUserMessage'] as bool? ?? false;
    if (!isFromUser) {
      final messageId = _getMessageId(message);
      setStreamingMessage(messageId);
      _armStreamingPin(messageId);
    }
  }

  /// Active timers scheduled by [simulateStreamingCompletion]. Tracked so
  /// [dispose] can cancel them and avoid `Timer still pending` failures in
  /// widget tests that exercise the demo / simulation path.
  final Set<Timer> _simulateStreamingTimers = {};

  /// Simulates streaming completion after a delay (useful for demos)
  void simulateStreamingCompletion(String messageId,
      {Duration delay = const Duration(seconds: 3)}) {
    if (!_mounted) return;
    late Timer timer;
    timer = Timer(delay, () {
      _simulateStreamingTimers.remove(timer);
      if (mounted) {
        stopStreamingMessage(messageId);
      }
    });
    _simulateStreamingTimers.add(timer);
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

  /// Resolves a message id to the [BuildContext] of its rendered widget
  /// subtree, wired by `CustomChatWidget` so [scrollToMessage] and
  /// [forceScrollToFirstMessageInChain] can measure the message's actual
  /// rendered position instead of guessing from `index / itemCount`, which
  /// assumes uniform item heights and badly mistargets a chat where one
  /// message — e.g. a single long streaming answer — dominates the total
  /// list height (see issue #42).
  BuildContext? Function(String messageId)? _messageContextResolver;

  /// Timer that fires the delayed scroll after a new message is rendered.
  /// Tracked so [dispose] can cancel it and prevent dangling timers in tests.
  Timer? _scrollAfterRenderTimer;

  /// Timer that resets the manual-scroll flag after the user finishes
  /// interacting with the scroll view. Tracked so [dispose] can cancel it.
  Timer? _manualScrollResetTimer;

  /// The ID of the first message in the current AI response
  String? _currentResponseFirstMessageId;

  /// The user of the last message added (to track response chains)
  String? _lastMessageUserId;

  /// The ID of the message currently being streamed
  String? _currentlyStreamingMessageId;

  /// The ID of the most recently delivered (non-streaming) AI message.
  /// Used to trigger one-shot word-by-word animation for addMessage() calls.
  String? _newlyDeliveredMessageId;

  // ---- Streaming pin (ScrollBehaviorConfig.pinDuringStreaming) ----------

  /// Id of the streaming AI message the current pin belongs to, or null when
  /// no pin has been armed for the current turn.
  String? _pinnedResponseId;

  /// Id of the message whose top edge is held at the top of the viewport.
  String? _pinAnchorMessageId;

  /// Set once the user takes over (scroll gesture / scroll-to-bottom button)
  /// for the pinned response; the pin stays released until the next answer.
  bool _pinReleased = false;

  /// Rendered height of the streaming answer the last time
  /// [maintainStreamingPin] looked; the delta between calls is how much the
  /// answer grew, used to keep the reader's text still in a reverse list
  /// after they took over. (Not `maxScrollExtent`: a lazily built list
  /// re-estimates that as it scrolls, so it is not a growth signal.)
  double? _pinLastResponseHeight;

  /// Cached element lookups for the pin's anchor/response messages, so the
  /// per-frame check does not walk the element tree while nothing changed.
  final Map<String, BuildContext> _pinContextCache = {};

  /// Whether a streaming pin is currently holding a message at the top of
  /// the viewport. See [ScrollBehaviorConfig.pinDuringStreaming].
  bool get isStreamingPinActive => _pinnedResponseId != null && !_pinReleased;

  /// The id of the message currently held at the top of the viewport by the
  /// streaming pin, or null when no pin is active.
  String? get streamingPinAnchorMessageId =>
      isStreamingPinActive ? _pinAnchorMessageId : null;

  /// Is the user manually scrolling
  bool _isManuallyScrolling = false;
  DateTime _lastManualScrollTime = DateTime.now();

  /// Timestamp of the last executed auto-scroll, used to debounce
  /// [_scrollAfterRender], [forceScrollToFirstMessageInChain] and
  /// [_scrollToBottomInternal] against firing too close together.
  ///
  /// Read via [clock.now()][clock] (`package:clock`), not raw
  /// `DateTime.now()` (task-019): the debounce compares real elapsed time,
  /// which under a heavily loaded machine can occasionally exceed the
  /// debounce window between a test's controller construction and its
  /// first `addMessage` call — scheduling a genuine `Timer` that a test's
  /// `pump`/`pumpAndSettle` may not drain long enough to fire, causing an
  /// intermittent "A Timer is still pending" failure unrelated to whatever
  /// the test was actually checking. `package:clock`'s ambient `clock` is
  /// real wall-clock time by default (zero behavior change for production
  /// and for any test that doesn't opt in), but a test can wrap itself in
  /// `withClock(someControllableClock, () { ... })` to make this debounce
  /// deterministic instead of dependent on real elapsed time.
  DateTime _lastScrollTime = clock.now();
  int _scrollDebounceMs =
      800; // Increased default debounce time to reduce frequency
  String?
      _lastScrollOperation; // Track the last scroll operation to prevent conflicts

  /// Wires a [ScrollController] up to this controller for auto-scrolling.
  ///
  /// The widget calls this once during build; consumers normally do not need
  /// to invoke it. Installs a listener that tracks manual scrolling so that
  /// automatic scroll-to-bottom does not fight the user mid-drag. Any prior
  /// scroll controller is detached cleanly.
  void setScrollController(ScrollController controller) {
    if (!_mounted) return;

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
          // Reset after a short delay to allow animations to complete.
          // Tracked via _manualScrollResetTimer so dispose() can cancel it
          // and tests don't leave dangling timers after widget teardown.
          _manualScrollResetTimer?.cancel();
          _manualScrollResetTimer =
              Timer(const Duration(milliseconds: 300), () {
            _manualScrollResetTimer = null;
            if (!_mounted) return;
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

  /// Registers a resolver mapping a message id to the [BuildContext] of its
  /// rendered widget subtree.
  ///
  /// `CustomChatWidget` calls this internally so [scrollToMessage] and
  /// [forceScrollToFirstMessageInChain] can use [Scrollable.ensureVisible]
  /// (an exact, measured scroll) instead of the `index / itemCount`
  /// proportional-position fallback. Consumers driving the controller
  /// outside of `AiChatWidget` normally don't need to call this — the
  /// heuristic fallback still applies when no resolver is set.
  void setMessageContextResolver(
      BuildContext? Function(String messageId)? resolver) {
    _messageContextResolver = resolver;
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

  /// Adds an agent-authored message without running the response-tracking
  /// or auto-scroll logic that [addMessage] applies.
  ///
  /// Use this for messages emitted by the agent surface (`AgentOrchestrator`,
  /// `ActionController`) where the orchestrator has already taken
  /// responsibility for response grouping. Prefer [addMessage] for ordinary
  /// chat responses.
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
    // Ensure message has a stable id; if missing, generate and persist it
    var messageId = _getMessageId(message);
    if (message.customProperties == null ||
        message.customProperties!['id'] == null) {
      final generatedId =
          '${message.user.id}_${message.createdAt.millisecondsSinceEpoch}';
      message = message.copyWith(
        customProperties: {
          ...?message.customProperties,
          'id': generatedId,
        },
      );
      messageId = generatedId;
    }
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

      // If this is an AI message, set it as the currently streaming message
      if (!isFromUser) {
        setStreamingMessage(messageId);
      }

      // Streaming pin bookkeeping: a user message starts a new turn (any pin
      // from the previous answer ends); an AI message that arrives already
      // streaming arms the pin for this answer.
      if (isFromUser) {
        _clearStreamingPin();
      } else if (updatedProperties['isStreaming'] == true) {
        _armStreamingPin(messageId);
      }

      notifyListeners();
      _scheduleAutoPersist();

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
    // While a streaming pin holds the answer's start (or the user's question)
    // at the top of the viewport, automatic scrolling for AI content would
    // yank the reader away from it — the pin owns the scroll position for
    // the rest of this answer. User messages still scroll as usual (they end
    // the pin in addMessage before reaching here).
    if (!isUserMessage && isStreamingPinActive) {
      debugPrint('NOT SCROLLING: streaming pin active');
      return;
    }

    // Create a unique operation ID for this scroll request
    final operationId = 'scroll_${DateTime.now().millisecondsSinceEpoch}';

    // Apply debounce for scrolling to prevent jitter
    final now = clock.now();
    if (now.difference(_lastScrollTime).inMilliseconds < _scrollDebounceMs) {
      return; // Removed debug print to reduce log spam
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

    // Longer delay to ensure messages have time to render.
    // Tracked via _scrollAfterRenderTimer so dispose() can cancel it and
    // tests don't leave dangling timers after widget teardown.
    _scrollAfterRenderTimer?.cancel();
    _scrollAfterRenderTimer = Timer(scrollDelay, () {
      _scrollAfterRenderTimer = null;
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

      // Re-check the streaming pin at FIRE time, not only when this timer was
      // scheduled: `addStreamingMessage` schedules this scroll from inside
      // `addMessage` and only arms the pin afterwards, so by the time the delay
      // elapses the pin is active and this scroll would tear the reader away
      // from the anchor (and, worse, count as an explicit scroll-to-bottom).
      if (!isUserMessage && isStreamingPinActive) {
        debugPrint('SCROLL ABORTED: streaming pin active');
        return;
      }

      // Make sure the widget is still mounted and the response ID hasn't changed
      if (_scrollController?.hasClients != true) {
        debugPrint('SCROLL ABORTED: Scroll controller no longer has clients');
        return;
      }

      // Update last scroll time for debouncing
      _lastScrollTime = clock.now();

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

        _scrollToBottomInternal(
            config.scrollAnimationDuration, config.scrollAnimationCurve);
      } else if (!hasScrolled) {
        debugPrint('SKIPPING DEFAULT SCROLL: Custom scroll behavior is active');
      }
    });
  }

  /// Scrolls to a specific message by ID with improved position calculation
  void scrollToMessage(String messageId) {
    if (!_mounted || _scrollController?.hasClients != true) return;

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

      // Prefer an exact, measured scroll over the index/itemCount heuristic
      // below — that heuristic assumes uniform item heights and mistargets
      // badly when one message dominates the list's total height (#42).
      final resolvedContext = _messageContextResolver?.call(messageId);
      if (resolvedContext != null && resolvedContext.mounted) {
        debugPrint('SCROLLING (measured): To message ID $messageId');
        Scrollable.ensureVisible(
          resolvedContext,
          duration: config.scrollAnimationDuration,
          curve: config.scrollAnimationCurve,
          // `alignment: 0.0` means "align to the scroll axis's start edge".
          // In a `reverse: true` list (the package default) the axis is
          // flipped, so the start edge is the viewport's VISUAL BOTTOM —
          // aligning a message's top there would do nothing useful. Use
          // 1.0 (the axis end edge) in that case to align the message's
          // visual top with the viewport's visual top instead.
          alignment: paginationConfig.reverseOrder ? 1.0 : 0.0,
        );
        return;
      }

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
    // An explicit scroll-to-bottom is the reader taking over: release any
    // streaming pin so it does not immediately pull the list back up. The
    // controller's own automatic scrolls go through [_scrollToBottomInternal]
    // and never release the pin.
    releaseStreamingPin();
    _scrollToBottomInternal(duration, curve);
  }

  void _scrollToBottomInternal([
    Duration? duration,
    Curve? curve,
  ]) {
    if (!_mounted || _scrollController?.hasClients != true) return;

    // Don't interrupt user's manual scrolling
    if (_isManuallyScrolling) {
      debugPrint('SCROLL BOTTOM CANCELED: User is manually scrolling');
      return;
    }

    // Apply debounce for scrollToBottom to prevent jitter
    // (less strict than for force scroll)
    final now = clock.now();
    const minInterval = 400; // ms - increased from 200ms to reduce frequency
    if (now.difference(_lastScrollTime).inMilliseconds < minInterval) {
      return; // Removed debug print to reduce log spam
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
      _scheduleAutoPersist();
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

      // Streaming pin: an answer counts as streaming for the pin whether the
      // consumer flags each update with `isStreaming: true` or drives the
      // controller's own streaming state (addStreamingMessage /
      // stopStreamingMessage) and just updates the text.
      final isStreamingForPin = isStreaming ||
          (_currentlyStreamingMessageId != null &&
              _currentlyStreamingMessageId == messageId);
      if (isStreamingForPin && !isUserMessage) {
        _armStreamingPin(messageId);
      }
      if (isStreamingForPin && _pinnedResponseId != null) {
        // The widget rebuilds on the next frame; re-check the pin once that
        // frame has laid out the grown message (the widget also calls
        // maintainStreamingPin on every scroll-metrics change, so this is
        // just the earliest possible correction).
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_mounted) maintainStreamingPin();
        });
      }

      // Safe notification and scrolling strategy
      if (isStreaming) {
        _isCurrentlyStreaming = true;
        // For streaming: just notify, no scrolling to prevent assertion errors
        notifyListeners();
        _scheduleAutoPersist();
      } else {
        // If we were streaming and now we're not, this is the end of stream
        final wasStreaming = _isCurrentlyStreaming;
        _isCurrentlyStreaming = false;

        // Always notify listeners
        notifyListeners();
        _scheduleAutoPersist();

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

        if (shouldScroll && wasStreaming && isStreamingPinActive) {
          // The reader is already where they want to be (the pinned anchor);
          // an end-of-stream scroll — to the bottom or back to the first
          // message — is exactly the jump the pin exists to prevent.
          debugPrint('NOT SCROLLING: end of stream with streaming pin active');
        } else if (shouldScroll && wasStreaming) {
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
        _scheduleAutoPersist();

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
    _clearStreamingPin();
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
    // Note: also fires right after restoreFromPersistence() calls this
    // internally, re-saving the same data it just loaded — a harmless
    // redundant write, not worth special-casing.
    _scheduleAutoPersist();

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
    _clearStreamingPin();
    _messages.clear();
    _messageCache.clear();
    _currentPage = 1;
    _hasMoreMessages = true;
    notifyListeners();
    _scheduleAutoPersist();
  }

  /// Loads more messages using the provided callback.
  ///
  /// Returns early if already loading or no more messages.
  /// The callback should return a list of messages to add.
  Future<void> loadMore(
      Future<List<ChatMessage>> Function()? loadCallback) async {
    if (_isLoadingMore || !_hasMoreMessages || !paginationConfig.enabled) {
      return;
    }

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

  /// Submits an example question as if the user had typed and sent it.
  ///
  /// Hides the welcome message and adds [question] as a user-authored
  /// [ChatMessage]. The chat widget's `onSendMessage` callback is **not**
  /// invoked by this method — consumers wiring example questions to a real
  /// API should listen to the controller and call their send pipeline.
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

  /// Hides the welcome message overlay and notifies listeners.
  ///
  /// Called automatically the first time a message is sent through
  /// [handleExampleQuestion]; consumers can also call it directly to dismiss
  /// the welcome panel programmatically.
  void hideWelcomeMessage() {
    _showWelcomeMessage = false;
    notifyListeners();
  }

  /// Jumps to the very top of the list (no animation).
  ///
  /// Useful when entering a new conversation or when an animated scroll has
  /// drifted off-target. No-ops if the scroll controller is not attached
  /// or the controller has been disposed.
  void forceScrollToTop() {
    if (!_mounted || _scrollController?.hasClients != true) return;

    try {
      // Force scroll to the very top first (0.0)
      _scrollController!.jumpTo(0.0);
      debugPrint('FORCE SCROLL: Jumped to absolute top position');
    } catch (e) {
      debugPrint('ERROR FORCE SCROLLING: $e');
    }
  }

  /// Animates to the first message in the response chain identified by
  /// [responseId], so the start of a multi-part AI response stays in view.
  ///
  /// Messages participate in a chain by setting
  /// `customProperties['responseId']` to the same value; the first message
  /// additionally sets `customProperties['isStartOfResponse'] = true`.
  /// This is the mechanism that powers
  /// `ScrollBehaviorConfig.scrollToFirstResponseMessage`.
  ///
  /// No-ops if no scroll controller is attached, the controller is
  /// disposed, the user is currently manually scrolling, or no matching
  /// message exists.
  void forceScrollToFirstMessageInChain(String responseId) {
    if (!_mounted || _scrollController?.hasClients != true) return;

    // Implement debounce for scrolling to prevent jitter
    final now = clock.now();
    if (now.difference(_lastScrollTime).inMilliseconds < _scrollDebounceMs) {
      return; // Removed debug print to reduce log spam
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

      // Prefer an exact, measured scroll over the index/itemCount heuristic
      // below — see the note in scrollToMessage (#42).
      final chainMessageId = _getMessageId(firstMessageInChain);
      final resolvedContext = _messageContextResolver?.call(chainMessageId);
      if (resolvedContext != null && resolvedContext.mounted) {
        debugPrint(
            'FORCE SCROLL (measured): To first message in chain ID $chainMessageId');
        Scrollable.ensureVisible(
          resolvedContext,
          duration: scrollDuration,
          curve: scrollCurve,
          // See the note in scrollToMessage: reverse lists flip which edge
          // "alignment 0.0" refers to.
          alignment: paginationConfig.reverseOrder ? 1.0 : 0.0,
        );
        return;
      }

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

  // ---- Streaming pin implementation --------------------------------------

  bool _isUserMessage(ChatMessage message) =>
      (message.customProperties?['isUserMessage'] as bool?) == true ||
      message.customProperties?['source'] == 'user';

  /// Arms the streaming pin for [responseMessageId] (idempotent per answer)
  /// according to [ScrollBehaviorConfig.pinDuringStreaming].
  void _armStreamingPin(String responseMessageId) {
    final anchor = scrollBehaviorConfig.pinDuringStreaming;
    if (anchor == StreamingPinAnchor.none) return;
    if (_pinnedResponseId == responseMessageId) return;

    String? anchorId;
    if (anchor == StreamingPinAnchor.userMessage) {
      // The most recent user message — the question this answer replies to.
      final newestFirst =
          paginationConfig.reverseOrder ? _messages : _messages.reversed;
      for (final m in newestFirst) {
        if (_isUserMessage(m)) {
          anchorId = _getMessageId(m);
          break;
        }
      }
    }

    _pinnedResponseId = responseMessageId;
    _pinAnchorMessageId = anchorId ?? responseMessageId;
    _pinReleased = false;
    _pinLastResponseHeight = null;
    _pinContextCache.clear();
    debugPrint('STREAMING PIN: armed for $responseMessageId, '
        'anchor=$_pinAnchorMessageId');
  }

  void _clearStreamingPin() {
    _pinnedResponseId = null;
    _pinAnchorMessageId = null;
    _pinReleased = false;
    _pinLastResponseHeight = null;
    _pinContextCache.clear();
  }

  /// Releases the streaming pin for the current answer: the reader has taken
  /// over (a scroll gesture, or the scroll-to-bottom button). The pin stays
  /// released until the next answer starts streaming. Safe to call when no
  /// pin is active.
  void releaseStreamingPin() {
    if (_pinnedResponseId == null || _pinReleased) return;
    _pinReleased = true;
    debugPrint('STREAMING PIN: released by the user');
  }

  /// Re-applies the streaming pin after the list's content changed.
  ///
  /// `CustomChatWidget` calls this on every scroll-metrics change (i.e. every
  /// time the streaming answer grows); consumers normally never need to.
  /// No-op unless [ScrollBehaviorConfig.pinDuringStreaming] armed a pin for
  /// the answer currently streaming.
  ///
  /// While the pin is HELD the rule is direction-agnostic: compute the scroll
  /// offset that puts the anchor's visual top at the viewport's visual top,
  /// clamp it to the scrollable range, and only ever scroll *towards* it —
  /// never past it. While the answer is still short that offset is out of
  /// reach, so the list keeps following the answer exactly as before; once
  /// the anchor reaches the top it is held there and new text arrives below
  /// the fold.
  ///
  /// After the reader has RELEASED the pin (see [releaseStreamingPin]) a
  /// `reverse: true` list has one more job: its scroll offset is measured
  /// from the bottom of the newest message, so every chunk appended to a
  /// still-streaming answer would push the text the reader is looking at
  /// upwards. The offset is therefore advanced by exactly the amount the
  /// content grew, which keeps that text still — unless the reader is at the
  /// very bottom, where following the answer is what they want.
  void maintainStreamingPin() {
    if (!_mounted) return;
    final responseId = _pinnedResponseId;
    if (responseId == null) return;
    final controller = _scrollController;
    if (controller?.hasClients != true) return;
    final position = controller!.position;

    try {
      if (_pinReleased) {
        if (!paginationConfig.reverseOrder) return;
        final responseBox = _pinRenderBox(responseId);
        if (responseBox == null) return;
        final height = responseBox.size.height;
        final previousHeight = _pinLastResponseHeight;
        _pinLastResponseHeight = height;
        if (previousHeight == null || position.pixels <= 0.5) return;
        final grown = height - previousHeight;
        if (grown <= 0.5) return;
        final target = (position.pixels + grown)
            .clamp(position.minScrollExtent, position.maxScrollExtent);
        if (target > position.pixels + 0.5) {
          controller.jumpTo(target);
        }
        return;
      }

      final anchorId = _pinAnchorMessageId;
      if (anchorId == null) return;
      final responseBox = _pinRenderBox(responseId);
      if (responseBox != null) {
        _pinLastResponseHeight = responseBox.size.height;
      }
      final reveal = _offsetToRevealTop(anchorId);
      if (reveal != null) {
        final target =
            reveal.clamp(position.minScrollExtent, position.maxScrollExtent);
        if (position.pixels < target - 0.5) {
          controller.jumpTo(target);
        }
        return;
      }

      // The anchor is not built right now (a `userMessage` anchor sits just
      // above the answer, and a large chunk can push it past the list's
      // cache extent in one frame). Bring the answer's own start to the top
      // first — that puts the anchor within reach — and finish the alignment
      // on the next frame.
      if (responseId == anchorId) return;
      final responseReveal = _offsetToRevealTop(responseId);
      if (responseReveal == null) return;
      final target = responseReveal.clamp(
          position.minScrollExtent, position.maxScrollExtent);
      if (position.pixels < target - 0.5) {
        controller.jumpTo(target);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_mounted) maintainStreamingPin();
        });
      }
    } catch (e) {
      debugPrint('STREAMING PIN: could not maintain pin: $e');
    }
  }

  /// The laid-out [RenderBox] of [messageId], or null when it is not built.
  /// Resolved contexts are cached per pin turn; a cached element that has
  /// since been unmounted (scrolled out of the list's cache extent) is
  /// looked up again.
  RenderBox? _pinRenderBox(String messageId) {
    var context = _pinContextCache[messageId];
    if (context == null || !context.mounted) {
      _pinContextCache.remove(messageId);
      context = _messageContextResolver?.call(messageId);
      if (context == null || !context.mounted) return null;
      _pinContextCache[messageId] = context;
    }
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox ||
        !renderObject.attached ||
        !renderObject.hasSize) {
      return null;
    }
    return renderObject;
  }

  /// The scroll offset that aligns the visual top of [messageId] with the
  /// visual top of the viewport, or null when the message is not currently
  /// built. Same edge convention as [scrollToMessage]: in a reverse list the
  /// axis is flipped, so alignment 1.0 is the visual top.
  double? _offsetToRevealTop(String messageId) {
    final renderObject = _pinRenderBox(messageId);
    if (renderObject == null) return null;
    final viewport = RenderAbstractViewport.maybeOf(renderObject);
    if (viewport == null) return null;
    return viewport
        .getOffsetToReveal(
            renderObject, paginationConfig.reverseOrder ? 1.0 : 0.0)
        .offset;
  }

  @override
  void dispose() {
    // Mark as unmounted to prevent race conditions
    _mounted = false;
    _isCurrentlyStreaming = false;

    // Cancel any pending scroll timer to prevent memory leaks
    _pendingScrollTimer?.cancel();
    _pendingScrollTimer = null;

    // Cancel the post-render scroll timer (replaces the prior untracked
    // Future.delayed) so tests don't hit "Timer still pending" after teardown.
    _scrollAfterRenderTimer?.cancel();
    _scrollAfterRenderTimer = null;

    // Cancel the manual-scroll reset timer (replaces the prior untracked
    // Future.delayed) for the same reason.
    _manualScrollResetTimer?.cancel();
    _manualScrollResetTimer = null;

    // Cancel the auto-persist debounce timer (task-009) for the same reason.
    _persistDebounceTimer?.cancel();
    _persistDebounceTimer = null;

    // Cancel any pending simulate-streaming-completion timers (iter 3).
    for (final t in _simulateStreamingTimers) {
      t.cancel();
    }
    _simulateStreamingTimers.clear();

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
