import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../controllers/chat_messages_controller.dart';
import '../models/ai_chat_config.dart';
import '../models/chat/models.dart';
import '../models/example_question.dart';
import '../models/example_question_config.dart' hide ExampleQuestion;
import '../models/file_upload_options.dart';
import '../models/input_options.dart';
import '../models/welcome_message_config.dart';
import '../utils/color_extensions.dart';
import 'chat_input.dart';
import 'custom_chat_widget.dart';

/// A customizable chat widget for AI conversations.
class AiChatWidget extends StatefulWidget {
  const AiChatWidget({
    super.key,
    // Required parameters similar to Dila
    required this.currentUser,
    required this.aiUser,
    required this.controller,
    required this.onSendMessage,

    // Optional parameters, similar to Dila's approach
    this.messages,
    this.inputOptions,
    this.messageOptions,
    this.messageListOptions,
    this.typingUsers,
    this.readOnly = false,
    this.quickReplyOptions,
    this.scrollToBottomOptions,
    this.scrollController,

    // Optional specific to AI functionality
    this.welcomeMessageConfig,
    this.exampleQuestions = const [],
    this.persistentExampleQuestions = false,
    this.enableAnimation = true,
    this.maxWidth,
    this.loadingConfig,
    this.paginationConfig,
    this.padding,
    this.enableMarkdownStreaming = true,
    this.streamingDuration = const Duration(milliseconds: 30),
    this.markdownStyleSheet,
    this.aiName = 'AI',
    // Streaming fade-in (optional, off by default for simplicity)
    this.streamingFadeInDuration,
    this.streamingFadeInCurve,
    this.streamingFadeInEnabled,
    this.streamingWordByWord,

    // Scroll behavior configuration
    this.scrollBehaviorConfig,

    // New parameters
    this.fileUploadOptions,
  });

  /// The current user in the conversation
  final ChatUser currentUser;

  /// The AI assistant in the conversation
  final ChatUser aiUser;

  /// Name of the AI assistant (for display)
  final String aiName;

  /// The controller for managing chat messages
  final ChatMessagesController controller;

  /// Callback when a message is sent
  final void Function(ChatMessage) onSendMessage;

  /// Optional list of messages (if not using controller)
  final List<ChatMessage>? messages;

  /// Customization options for the input field
  final InputOptions? inputOptions;

  /// Customization options for messages
  final MessageOptions? messageOptions;

  /// Customization options for the message list
  final MessageListOptions? messageListOptions;

  /// Customization options for quick replies
  final QuickReplyOptions? quickReplyOptions;

  /// Customization options for the scroll-to-bottom button
  final ScrollToBottomOptions? scrollToBottomOptions;

  /// Users who are currently typing
  final List<ChatUser>? typingUsers;

  /// Whether the chat interface is in read-only mode
  final bool readOnly;

  /// Optional scroll controller
  final ScrollController? scrollController;

  /// Configuration for welcome messages.
  /// When provided, the welcome message will be shown at the start of the conversation.
  /// If this is null and exampleQuestions is empty, no welcome message will be displayed.
  final WelcomeMessageConfig? welcomeMessageConfig;

  /// Example questions to show in the welcome message.
  /// When non-empty, these will enable the welcome message at the start of the conversation
  /// even if welcomeMessageConfig is null.
  final List<ExampleQuestion> exampleQuestions;

  /// Whether to show example questions persistently
  final bool persistentExampleQuestions;

  /// Whether to enable animations
  final bool enableAnimation;

  /// Maximum width of the chat widget
  final double? maxWidth;

  /// Configuration for loading states
  final LoadingConfig? loadingConfig;

  /// Configuration for pagination
  final PaginationConfig? paginationConfig;

  /// Padding around the entire widget
  final EdgeInsets? padding;

  /// Whether to enable markdown streaming animations
  final bool enableMarkdownStreaming;

  /// Duration for streaming animations
  final Duration streamingDuration;

  /// Style sheet for markdown rendering
  final MarkdownStyleSheet? markdownStyleSheet;

  /// Optional fade-in configuration for streaming text
  /// If not provided, fade-in is disabled for a simpler default.
  final Duration? streamingFadeInDuration;
  final Curve? streamingFadeInCurve;
  final bool? streamingFadeInEnabled;
  final bool? streamingWordByWord;

  /// Configuration for scroll behavior
  final ScrollBehaviorConfig? scrollBehaviorConfig;

  /// Optional file upload options
  final FileUploadOptions? fileUploadOptions;

  @override
  State<AiChatWidget> createState() => _AiChatWidgetState();
}

class _AiChatWidgetState extends State<AiChatWidget>
    with TickerProviderStateMixin {
  late ScrollController _effectiveScrollController;
  late AnimationController _animationController;
  late TextEditingController _textController;
  late FocusNode _inputFocusNode;
  bool _isComposing = false;
  VoidCallback? _textControllerListener;

  @override
  void initState() {
    super.initState();
    _effectiveScrollController = widget.scrollController ?? ScrollController();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animationController.forward();

    _textController =
        widget.inputOptions?.textController ?? TextEditingController();
    _inputFocusNode = widget.inputOptions?.focusNode ?? FocusNode();

    // Create and store the listener to prevent memory leaks
    _textControllerListener = () {
      final isComposing = _textController.text.isNotEmpty;
      if (isComposing != _isComposing) {
        setState(() {
          _isComposing = isComposing;
        });
      }
    };

    _textController.addListener(_textControllerListener!);

    // Set the scroll behavior configuration
    if (widget.scrollBehaviorConfig != null) {
      widget.controller.scrollBehaviorConfig = widget.scrollBehaviorConfig;
      debugPrint('AiChatWidget: Initially set scroll behavior to: '
          '${widget.scrollBehaviorConfig!.autoScrollBehavior}, '
          'scrollToFirstMessage: ${widget.scrollBehaviorConfig!.scrollToFirstResponseMessage}');
    }

    // Set welcome message visibility based on configurations
    final hasWelcomeConfig = widget.welcomeMessageConfig != null;
    final hasExampleQuestions = widget.exampleQuestions.isNotEmpty;

    // Debug check for example questions
    debugPrint('AiChatWidget: Has welcome config: $hasWelcomeConfig');
    debugPrint(
        'AiChatWidget: Has example questions: $hasExampleQuestions (count: ${widget.exampleQuestions.length})');
    if (hasExampleQuestions) {
      for (var i = 0; i < widget.exampleQuestions.length; i++) {
        debugPrint('  Question $i: ${widget.exampleQuestions[i].question}');
      }
    }
    debugPrint(
        'AiChatWidget: Current message count: ${widget.controller.messages.length}');

    // Only show welcome message if welcome config or example questions are provided
    if ((hasWelcomeConfig || hasExampleQuestions) &&
        widget.controller.messages.isEmpty) {
      debugPrint('AiChatWidget: Setting showWelcomeMessage to true');
      widget.controller.showWelcomeMessage = true;
    } else {
      debugPrint(
          'AiChatWidget: Not showing welcome message. Conditions not met.');
    }
  }

  @override
  void didUpdateWidget(AiChatWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if the scroll behavior config has changed
    if (widget.scrollBehaviorConfig != oldWidget.scrollBehaviorConfig) {
      if (widget.scrollBehaviorConfig != null) {
        widget.controller.scrollBehaviorConfig = widget.scrollBehaviorConfig;
        debugPrint('AiChatWidget: Updated scroll behavior config to: '
            '${widget.scrollBehaviorConfig!.autoScrollBehavior}, '
            'scrollToFirstMessage: ${widget.scrollBehaviorConfig!.scrollToFirstResponseMessage}');
      }
    }
  }

  void _handleSend(final ChatMessage message) {
    // Hide welcome message first, just like in example questions
    if (widget.controller.showWelcomeMessage) {
      widget.controller.hideWelcomeMessage();
    }

    widget.onSendMessage(message);
  }

  void handleExampleQuestionTap(final String question) {
    // Hide welcome message first
    widget.controller.hideWelcomeMessage();

    // Create and send the message
    final message = ChatMessage(
      text: question,
      user: widget.currentUser,
      createdAt: DateTime.now(),
    );

    // Call the onSendMessage callback to trigger AI response
    widget.onSendMessage(message);
  }

  /// Returns the effective typing users list, including the AI user when loading
  /// if no other typing users are provided
  List<ChatUser> _getEffectiveTypingUsers() {
    final isLoading = widget.loadingConfig?.isLoading ?? false;

    // If we have explicitly set typing users, use those regardless of loading state
    if (widget.typingUsers != null && widget.typingUsers!.isNotEmpty) {
      return widget.typingUsers!;
    }

    // If we're loading and don't have typing users, add the AI user as typing
    if (isLoading) {
      return [widget.aiUser];
    }

    // No typing users
    return [];
  }

  @override
  Widget build(final BuildContext context) => ListenableBuilder(
        listenable: widget.controller,
        builder: (final context, final child) => Container(
          width: widget.maxWidth,
          constraints: widget.maxWidth != null
              ? BoxConstraints(maxWidth: widget.maxWidth!)
              : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Show persistent example questions if enabled and welcome message is hidden
              if (!widget.controller.showWelcomeMessage &&
                  widget.persistentExampleQuestions &&
                  widget.exampleQuestions.isNotEmpty) ...[
                Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.15,
                  ),
                  margin: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 4,
                    bottom: 12,
                  ),
                  child: _buildPersistentExampleQuestions(context),
                ),
              ],
              Expanded(
                child: CustomChatWidget(
                  controller: widget.controller,
                  currentUser: widget.currentUser,
                  messages: widget.messages ?? widget.controller.messages,
                  onSend: _handleSend,
                  messageOptions:
                      widget.messageOptions ?? const MessageOptions(),
                  inputOptions: widget.inputOptions ?? const InputOptions(),
                  typingUsers: _getEffectiveTypingUsers(),
                  messageListOptions:
                      (widget.messageListOptions ?? const MessageListOptions())
                          .copyWith(
                    scrollController: _effectiveScrollController,
                  ),
                  readOnly: widget.readOnly,
                  quickReplyOptions:
                      widget.quickReplyOptions ?? const QuickReplyOptions(),
                  scrollToBottomOptions: widget.scrollToBottomOptions ??
                      const ScrollToBottomOptions(),
                  typingIndicator: (widget.loadingConfig?.isLoading ?? false)
                      ? widget.loadingConfig?.loadingIndicator
                      : null,
                  welcomeMessageConfig: widget.welcomeMessageConfig,
                  exampleQuestions: widget.exampleQuestions,
                  // Pass streaming configuration down to the renderer
                  streamingTypingSpeed: widget.streamingDuration,
                  streamingEnabled: widget.enableMarkdownStreaming,
                  streamingFadeInEnabled:
                      widget.streamingFadeInEnabled ?? false,
                  streamingFadeInDuration: widget.streamingFadeInDuration ??
                      const Duration(milliseconds: 260),
                  streamingFadeInCurve:
                      widget.streamingFadeInCurve ?? Curves.easeInOut,
                  streamingWordByWord: widget.streamingWordByWord ?? false,
                ),
              ),
              // Loading indicator overlay
              if ((widget.loadingConfig?.isLoading ?? false) &&
                  (widget.loadingConfig?.showCenteredIndicator ?? false))
                Container(
                  color: Colors.black26,
                  child: Center(
                    child: widget.loadingConfig?.loadingIndicator ??
                        const CircularProgressIndicator(),
                  ),
                ),
              // Input at bottom instead of positioned
              if (!widget.readOnly)
                (widget.inputOptions?.useOuterContainer == false)
                    ? Container(
                        // Bottom sheet style container
                        width: double.infinity,
                        decoration: widget.inputOptions?.containerDecoration,
                        padding: EdgeInsets.only(
                          left: widget.inputOptions?.padding?.left ?? 16,
                          right: widget.inputOptions?.padding?.right ?? 16,
                          top: widget.inputOptions?.padding?.top ?? 16,
                          bottom: (widget.inputOptions?.padding?.bottom ?? 16) +
                              MediaQuery.of(context).viewInsets.bottom +
                              MediaQuery.of(context).padding.bottom,
                        ),
                        child: _buildChatInput(),
                      )
                    : Material(
                        elevation: widget.inputOptions?.materialElevation ?? 0,
                        color:
                            widget.inputOptions?.useScaffoldBackground == true
                                ? Theme.of(context).scaffoldBackgroundColor
                                : widget.inputOptions?.materialColor,
                        shape: widget.inputOptions?.materialShape ??
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22),
                              side: BorderSide.none,
                            ),
                        clipBehavior: Clip.antiAlias,
                        child: Container(
                          padding: widget.inputOptions?.materialPadding ??
                              const EdgeInsets.all(8.0),
                          child: _buildChatInput(),
                        ),
                      ),
            ],
          ),
        ),
      );

  // Welcome message is now handled in CustomChatWidget as part of the message list

  // Add a new method for building just the example questions without the welcome message
  Widget _buildPersistentExampleQuestions(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;
    // Get the first question's config as a default, if available
    final defaultQuestionConfig = widget.exampleQuestions.isNotEmpty
        ? widget.exampleQuestions.first.config
        : null;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: isDarkMode
            ? const Color(0xFF1E2026).withOpacityCompat(0.9)
            : Colors.white.withOpacityCompat(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacityCompat(isDarkMode ? 0.2 : 0.06),
            blurRadius: 15,
            offset: const Offset(0, 5),
            spreadRadius: -5,
          ),
        ],
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withOpacityCompat(0.1)
              : Colors.black.withOpacityCompat(0.05),
          width: 0.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 8, bottom: 12),
            child: Text(
              'Suggested Questions',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.exampleQuestions.map(
                  (question) {
                    // Get the question's config or use the default
                    final effectiveConfig =
                        question.config ?? defaultQuestionConfig;
                    return _buildPersistentQuestionChip(
                      question,
                      effectiveConfig ?? const ExampleQuestionConfig(),
                      isDarkMode,
                      primaryColor,
                    );
                  },
                ).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // New method for building question chips in a more compact form
  Widget _buildPersistentQuestionChip(
    ExampleQuestion question,
    ExampleQuestionConfig effectiveConfig,
    bool isDarkMode,
    Color primaryColor,
  ) {
    final chipColor = isDarkMode
        ? primaryColor.withOpacityCompat(0.15)
        : primaryColor.withOpacityCompat(0.08);

    return InkWell(
      onTap: () => handleExampleQuestionTap(question.question),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: chipColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: primaryColor.withOpacityCompat(0.2),
            width: 1,
          ),
        ),
        child: Text(
          question.question,
          style: TextStyle(
            fontSize: 13,
            color: isDarkMode ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // Build the chat input bar
  Widget _buildChatInput() {
    return ChatInput(
      controller: _textController,
      onSend: () {
        if (_textController.text.trim().isNotEmpty) {
          final message = ChatMessage(
            text: _textController.text.trim(),
            user: widget.currentUser,
            createdAt: DateTime.now(),
          );
          _textController.clear();
          _handleSend(message);
        }
      },
      options: widget.inputOptions ?? const InputOptions(),
      focusNode: _inputFocusNode,
      fileUploadOptions: widget.fileUploadOptions,
    );
  }

  @override
  void dispose() {
    // Only dispose scroll controller if we created it
    if (widget.scrollController == null) {
      _effectiveScrollController.dispose();
    }
    _animationController.dispose();

    // Remove text controller listener to prevent memory leaks
    if (_textControllerListener != null) {
      _textController.removeListener(_textControllerListener!);
    }

    // Don't dispose if using external controller
    if (widget.inputOptions?.textController == null) {
      _textController.dispose();
    }

    // Don't dispose if using external focus node
    if (widget.inputOptions?.focusNode == null) {
      _inputFocusNode.dispose();
    }
    super.dispose();
  }
}
