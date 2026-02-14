import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import 'chat/models.dart';
import 'example_question_config.dart';
import 'input_options.dart';
import 'welcome_message_config.dart';

/// Configuration class for loading states in the chat UI.
class LoadingConfig {
  /// Whether the chat is currently in a loading state
  final bool isLoading;

  /// Custom loading indicator widget
  final Widget? loadingIndicator;

  /// Color for the typing indicator
  final Color? typingIndicatorColor;

  /// Size of the typing indicator
  final double? typingIndicatorSize;

  /// Whether to show the loading indicator centered in the chat
  final bool showCenteredIndicator;

  const LoadingConfig({
    this.isLoading = false,
    this.loadingIndicator,
    this.typingIndicatorColor,
    this.typingIndicatorSize,
    this.showCenteredIndicator = false,
  });

  LoadingConfig copyWith({
    bool? isLoading,
    Widget? loadingIndicator,
    Color? typingIndicatorColor,
    double? typingIndicatorSize,
    bool? showCenteredIndicator,
  }) =>
      LoadingConfig(
        isLoading: isLoading ?? this.isLoading,
        loadingIndicator: loadingIndicator ?? this.loadingIndicator,
        typingIndicatorColor: typingIndicatorColor ?? this.typingIndicatorColor,
        typingIndicatorSize: typingIndicatorSize ?? this.typingIndicatorSize,
        showCenteredIndicator:
            showCenteredIndicator ?? this.showCenteredIndicator,
      );
}

/// Configuration for pagination in the chat UI.
class PaginationConfig {
  /// Whether pagination is enabled
  final bool enabled;

  /// Offset from the top at which to show the loading indicator
  final double loadingIndicatorOffset;

  /// Custom loading indicator widget for pagination
  final Widget Function({required bool isLoading})? loadMoreIndicator;

  /// Reverse order of messages (newest at bottom)
  final bool reverseOrder;

  /// Simulated delay for loading more messages
  final Duration loadingDelay;

  /// Time to debounce scroll events
  final Duration loadMoreDebounceTime;

  /// Whether to automatically load more messages when scrolling
  final bool autoLoadOnScroll;

  /// Distance in pixels from edge to trigger loading
  final double distanceToTriggerLoadPixels;

  /// Scroll position threshold to trigger loading (0.0 to 1.0)
  final double scrollThreshold;

  /// Whether to enable haptic feedback when loading more messages
  final bool enableHapticFeedback;

  /// Builder for loading indicator widget
  final Widget Function()? loadingBuilder;

  /// Builder for "no more messages" widget
  final Widget Function()? noMoreMessagesBuilder;

  /// Cache extent for ListView
  final double cacheExtent;

  /// Text for loading indicator
  final String loadingText;

  /// Text for "no more messages" indicator
  final String noMoreMessagesText;

  const PaginationConfig({
    this.enabled = false,
    this.loadingIndicatorOffset = 100.0,
    this.loadMoreIndicator,
    this.reverseOrder = true,
    this.loadingDelay = const Duration(milliseconds: 500),
    this.loadMoreDebounceTime = const Duration(milliseconds: 200),
    this.autoLoadOnScroll = true,
    this.distanceToTriggerLoadPixels = 100.0,
    this.scrollThreshold = 0.1,
    this.enableHapticFeedback = true,
    this.loadingBuilder,
    this.noMoreMessagesBuilder,
    this.cacheExtent = 300.0,
    this.loadingText = 'Loading...',
    this.noMoreMessagesText = 'No more messages',
  });

  PaginationConfig copyWith({
    bool? enabled,
    double? loadingIndicatorOffset,
    Widget Function({required bool isLoading})? loadMoreIndicator,
    bool? reverseOrder,
    Duration? loadingDelay,
    Duration? loadMoreDebounceTime,
    bool? autoLoadOnScroll,
    double? distanceToTriggerLoadPixels,
    double? scrollThreshold,
    bool? enableHapticFeedback,
    Widget Function()? loadingBuilder,
    Widget Function()? noMoreMessagesBuilder,
    double? cacheExtent,
    String? loadingText,
    String? noMoreMessagesText,
  }) =>
      PaginationConfig(
        enabled: enabled ?? this.enabled,
        loadingIndicatorOffset:
            loadingIndicatorOffset ?? this.loadingIndicatorOffset,
        loadMoreIndicator: loadMoreIndicator ?? this.loadMoreIndicator,
        reverseOrder: reverseOrder ?? this.reverseOrder,
        loadingDelay: loadingDelay ?? this.loadingDelay,
        loadMoreDebounceTime: loadMoreDebounceTime ?? this.loadMoreDebounceTime,
        autoLoadOnScroll: autoLoadOnScroll ?? this.autoLoadOnScroll,
        distanceToTriggerLoadPixels:
            distanceToTriggerLoadPixels ?? this.distanceToTriggerLoadPixels,
        scrollThreshold: scrollThreshold ?? this.scrollThreshold,
        enableHapticFeedback: enableHapticFeedback ?? this.enableHapticFeedback,
        loadingBuilder: loadingBuilder ?? this.loadingBuilder,
        noMoreMessagesBuilder:
            noMoreMessagesBuilder ?? this.noMoreMessagesBuilder,
        cacheExtent: cacheExtent ?? this.cacheExtent,
        loadingText: loadingText ?? this.loadingText,
        noMoreMessagesText: noMoreMessagesText ?? this.noMoreMessagesText,
      );
}

/// Configuration for scroll behavior in the chat.
///
/// This class allows control over how and when the chat widget automatically scrolls,
/// which can be important for accessibility and user experience, especially with long responses.
///
/// Example:
/// ```dart
/// AiChatWidget(
///   // ... other parameters
///   scrollBehaviorConfig: ScrollBehaviorConfig(
///     // Only scroll for user messages, allowing manual scrolling for AI responses
///     autoScrollBehavior: AutoScrollBehavior.onUserMessageOnly,
///     // When scrolling happens for AI responses, scroll to the first message
///     // instead of the last (preventing the top of the response from being hidden)
///     scrollToFirstResponseMessage: true,
///   ),
/// )
/// ```
///
/// Example for very long messages:
/// ```dart
/// // For handling very long AI responses (e.g., code explanations, technical documentation)
/// AiChatWidget(
///   scrollBehaviorConfig: ScrollBehaviorConfig(
///     // Prevent auto-scrolling for AI responses, giving user control
///     autoScrollBehavior: AutoScrollBehavior.onUserMessageOnly,
///     // Important: Ensure first message of AI response is visible
///     scrollToFirstResponseMessage: true,
///     // Slower animation for better user orientation with large content
///     scrollAnimationDuration: const Duration(milliseconds: 500),
///     // Ease in-out curve for smoother scrolling experience
///     scrollAnimationCurve: Curves.easeInOutCubic,
///   ),
///   config: AiChatConfig(
///     // Enable markdown for formatted long content
///     defaultMessageOptions: MessageOptions(
///       isMarkdown: true,
///     ),
///     // Optional: Custom styling for code blocks in long responses
///     markdownConfig: MarkdownConfig(
///       styleSheet: MarkdownStyleSheet(
///         code: TextStyle(
///           backgroundColor: Colors.grey[850],
///           color: Colors.lightGreenAccent,
///           fontFamily: 'monospace',
///           fontSize: 14,
///         ),
///         codeblockDecoration: BoxDecoration(
///           color: Colors.grey[850],
///           borderRadius: BorderRadius.circular(8),
///         ),
///       ),
///     ),
///   ),
/// )
/// ```
class ScrollBehaviorConfig {
  /// Controls when to automatically scroll to the bottom
  final AutoScrollBehavior autoScrollBehavior;

  /// Whether to scroll to the first message of a response instead of the last message.
  ///
  /// When set to true, after an AI response completes, the widget will scroll to show
  /// the first message of the response rather than scrolling all the way to the bottom.
  /// This is useful for long responses where users might want to read from the beginning.
  final bool scrollToFirstResponseMessage;

  /// Duration for the scroll animation
  final Duration scrollAnimationDuration;

  /// Curve for the scroll animation
  final Curve scrollAnimationCurve;

  const ScrollBehaviorConfig({
    this.autoScrollBehavior = AutoScrollBehavior.onNewMessage,
    this.scrollToFirstResponseMessage = false,
    this.scrollAnimationDuration = const Duration(milliseconds: 300),
    this.scrollAnimationCurve = Curves.easeOut,
  });

  /// Creates a smooth scrolling configuration with easeInOut curve
  /// Great for a natural, smooth scrolling experience
  static ScrollBehaviorConfig smooth({
    AutoScrollBehavior autoScrollBehavior = AutoScrollBehavior.onNewMessage,
    bool scrollToFirstResponseMessage = false,
    Duration duration = const Duration(milliseconds: 400),
  }) {
    return ScrollBehaviorConfig(
      autoScrollBehavior: autoScrollBehavior,
      scrollToFirstResponseMessage: scrollToFirstResponseMessage,
      scrollAnimationDuration: duration,
      scrollAnimationCurve: Curves.easeInOutCubic,
    );
  }

  /// Creates a bouncy scrolling configuration
  /// Adds a slight bounce effect at the end of the scroll
  static ScrollBehaviorConfig bouncy({
    AutoScrollBehavior autoScrollBehavior = AutoScrollBehavior.onNewMessage,
    bool scrollToFirstResponseMessage = false,
    Duration duration = const Duration(milliseconds: 500),
  }) {
    return ScrollBehaviorConfig(
      autoScrollBehavior: autoScrollBehavior,
      scrollToFirstResponseMessage: scrollToFirstResponseMessage,
      scrollAnimationDuration: duration,
      scrollAnimationCurve: Curves.elasticOut,
    );
  }

  /// Creates a deceleration scrolling configuration
  /// Starts fast and slows down toward the end
  static ScrollBehaviorConfig decelerate({
    AutoScrollBehavior autoScrollBehavior = AutoScrollBehavior.onNewMessage,
    bool scrollToFirstResponseMessage = false,
    Duration duration = const Duration(milliseconds: 350),
  }) {
    return ScrollBehaviorConfig(
      autoScrollBehavior: autoScrollBehavior,
      scrollToFirstResponseMessage: scrollToFirstResponseMessage,
      scrollAnimationDuration: duration,
      scrollAnimationCurve: Curves.decelerate,
    );
  }

  /// Creates a gentle acceleration scrolling configuration
  /// Starts slow and speeds up toward the end
  static ScrollBehaviorConfig accelerate({
    AutoScrollBehavior autoScrollBehavior = AutoScrollBehavior.onNewMessage,
    bool scrollToFirstResponseMessage = false,
    Duration duration = const Duration(milliseconds: 350),
  }) {
    return ScrollBehaviorConfig(
      autoScrollBehavior: autoScrollBehavior,
      scrollToFirstResponseMessage: scrollToFirstResponseMessage,
      scrollAnimationDuration: duration,
      scrollAnimationCurve: Curves.easeIn,
    );
  }

  /// Creates a fast scrolling configuration with minimal animation
  /// For situations where you want quick, direct scrolling
  static ScrollBehaviorConfig fast({
    AutoScrollBehavior autoScrollBehavior = AutoScrollBehavior.onNewMessage,
    bool scrollToFirstResponseMessage = false,
  }) {
    return ScrollBehaviorConfig(
      autoScrollBehavior: autoScrollBehavior,
      scrollToFirstResponseMessage: scrollToFirstResponseMessage,
      scrollAnimationDuration: const Duration(milliseconds: 150),
      scrollAnimationCurve: Curves.easeOutQuart,
    );
  }
}

/// Defines when the chat should automatically scroll to the bottom
enum AutoScrollBehavior {
  /// Always scroll to the bottom when messages are added or updated.
  /// This is the most aggressive scrolling behavior but ensures all new content is visible.
  always,

  /// Only scroll to the bottom when a new message is added (not during updates).
  /// This gives more control to the user during streaming messages, but ensures
  /// the user sees new messages when they are completed.
  onNewMessage,

  /// Only scroll when the user sends a message (not for AI responses).
  /// This gives users full control over scrolling when viewing AI responses,
  /// which is useful for long responses that they want to read from the beginning.
  onUserMessageOnly,

  /// Never automatically scroll.
  /// The user is fully responsible for scrolling the chat view.
  never
}

/// Configuration class for customizing the AI chat interface.
///
/// @Deprecated: This class is being phased out in favor of direct parameters in AiChatWidget.
/// For new code, pass configuration options directly to AiChatWidget constructor.
/// Aggregated configuration for the AI chat widget (deprecated in favor of direct parameters).
@Deprecated(
    'Use direct parameters in AiChatWidget instead. This class will be removed in a future version.')
class AiChatConfig {
  const AiChatConfig({
    // Basic settings
    this.userName = 'User',
    this.aiName = 'AI',
    this.hintText,
    this.maxWidth,
    this.padding,

    // Feature flags
    this.enableAnimation = true,
    this.showTimestamp = true,
    this.readOnly = false,
    this.persistentExampleQuestions = false,
    this.enableMarkdownStreaming = true,

    // Message content options
    this.exampleQuestions = const [],
    this.markdownStyleSheet,
    this.streamingDuration = const Duration(milliseconds: 30),

    // Main options aligned with Dila
    this.inputOptions,
    this.messageOptions,
    this.messageListOptions,
    this.quickReplyOptions,
    this.scrollToBottomOptions,

    // Specialized configs
    this.welcomeMessageConfig,
    this.loadingConfig = const LoadingConfig(),
    this.paginationConfig = const PaginationConfig(),

    // Other options
    this.typingUsers,

    /// Configuration for scroll behavior
    this.scrollBehaviorConfig,
  });

  /// The name of the user in the chat interface.
  final String userName;

  /// The name of the AI assistant in the chat interface.
  final String aiName;

  /// Placeholder text for the input field.
  final String? hintText;

  /// Maximum width of the chat interface. If null, takes full width.
  final double? maxWidth;

  /// Padding around the chat interface.
  final EdgeInsets? padding;

  /// Whether to enable message animations. Defaults to true.
  final bool enableAnimation;

  /// Whether to show message timestamps. Defaults to true.
  final bool showTimestamp;

  /// Whether the chat is in read-only mode. Defaults to false.
  final bool readOnly;

  /// List of example questions to show in the welcome message.
  final List<ExampleQuestion> exampleQuestions;

  /// Whether to show example questions persistently, even after welcome message disappears.
  final bool persistentExampleQuestions;

  /// Configuration for the welcome message section
  final WelcomeMessageConfig? welcomeMessageConfig;

  /// Custom options for the input field.
  final InputOptions? inputOptions;

  /// Custom options for message display.
  final MessageOptions? messageOptions;

  /// Custom options for the message list.
  final MessageListOptions? messageListOptions;

  /// Custom options for quick replies.
  final QuickReplyOptions? quickReplyOptions;

  /// Custom options for the scroll-to-bottom button.
  final ScrollToBottomOptions? scrollToBottomOptions;

  /// Whether to enable markdown streaming animations.
  final bool enableMarkdownStreaming;

  /// Duration for streaming animations.
  final Duration streamingDuration;

  /// Style sheet for markdown rendering.
  final MarkdownStyleSheet? markdownStyleSheet;

  /// Configuration for pagination
  final PaginationConfig paginationConfig;

  /// Configuration for loading states
  final LoadingConfig loadingConfig;

  /// List of users currently typing.
  final List<ChatUser>? typingUsers;

  /// Configuration for scroll behavior
  final ScrollBehaviorConfig? scrollBehaviorConfig;

  /// Creates a copy of this config with the given fields replaced with new values
  ///
  /// @Deprecated: Use direct parameters in AiChatWidget instead.
  AiChatConfig copyWith({
    String? userName,
    String? aiName,
    String? hintText,
    double? maxWidth,
    EdgeInsets? padding,
    bool? enableAnimation,
    bool? showTimestamp,
    bool? readOnly,
    List<ExampleQuestion>? exampleQuestions,
    bool? persistentExampleQuestions,
    WelcomeMessageConfig? welcomeMessageConfig,
    InputOptions? inputOptions,
    MessageOptions? messageOptions,
    MessageListOptions? messageListOptions,
    QuickReplyOptions? quickReplyOptions,
    ScrollToBottomOptions? scrollToBottomOptions,
    bool? enableMarkdownStreaming,
    Duration? streamingDuration,
    MarkdownStyleSheet? markdownStyleSheet,
    PaginationConfig? paginationConfig,
    LoadingConfig? loadingConfig,
    List<ChatUser>? typingUsers,
    ScrollBehaviorConfig? scrollBehaviorConfig,
  }) =>
      AiChatConfig(
        userName: userName ?? this.userName,
        aiName: aiName ?? this.aiName,
        hintText: hintText ?? this.hintText,
        maxWidth: maxWidth ?? this.maxWidth,
        padding: padding ?? this.padding,
        enableAnimation: enableAnimation ?? this.enableAnimation,
        showTimestamp: showTimestamp ?? this.showTimestamp,
        readOnly: readOnly ?? this.readOnly,
        exampleQuestions: exampleQuestions ?? this.exampleQuestions,
        persistentExampleQuestions:
            persistentExampleQuestions ?? this.persistentExampleQuestions,
        welcomeMessageConfig: welcomeMessageConfig ?? this.welcomeMessageConfig,
        inputOptions: inputOptions ?? this.inputOptions,
        messageOptions: messageOptions ?? this.messageOptions,
        messageListOptions: messageListOptions ?? this.messageListOptions,
        quickReplyOptions: quickReplyOptions ?? this.quickReplyOptions,
        scrollToBottomOptions:
            scrollToBottomOptions ?? this.scrollToBottomOptions,
        enableMarkdownStreaming:
            enableMarkdownStreaming ?? this.enableMarkdownStreaming,
        streamingDuration: streamingDuration ?? this.streamingDuration,
        markdownStyleSheet: markdownStyleSheet ?? this.markdownStyleSheet,
        paginationConfig: paginationConfig ?? this.paginationConfig,
        loadingConfig: loadingConfig ?? this.loadingConfig,
        typingUsers: typingUsers ?? this.typingUsers,
        scrollBehaviorConfig: scrollBehaviorConfig ?? this.scrollBehaviorConfig,
      );
}
