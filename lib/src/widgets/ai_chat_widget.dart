import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../controllers/chat_messages_controller.dart';
import '../models/ai_chat_config.dart';
import '../models/chat/models.dart';
import '../models/example_question_config.dart';
import '../models/input_options.dart';
import '../models/welcome_message_config.dart';
import '../theme/custom_theme_extension.dart';
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

  @override
  State<AiChatWidget> createState() => _AiChatWidgetState();
}

class _AiChatWidgetState extends State<AiChatWidget>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToBottom = false;
  late AnimationController _animationController;
  late TextEditingController _textController;
  late FocusNode _inputFocusNode;
  bool _isComposing = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animationController.forward();

    _textController =
        widget.inputOptions?.textController ?? TextEditingController();
    _inputFocusNode = FocusNode();

    _textController.addListener(() {
      final isComposing = _textController.text.isNotEmpty;
      if (isComposing != _isComposing) {
        setState(() {
          _isComposing = isComposing;
        });
      }
    });

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

  void _scrollListener() {
    if (_scrollController.hasClients) {
      final shouldShowButton =
          _scrollController.position.pixels > 100; // Show after scrolling 100px
      if (shouldShowButton != _showScrollToBottom) {
        setState(() {
          _showScrollToBottom = shouldShowButton;
        });
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
        builder: (final context, final child) => Material(
          color: Colors.transparent,
          child: SizedBox(
            width: widget.maxWidth ?? double.infinity,
            height: double.infinity,
            // padding: widget.padding ?? const EdgeInsets.all(8),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Column(
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
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Add padding at the bottom to prevent content from being hidden behind input
                          Padding(
                            padding: EdgeInsets.only(
                                bottom: !widget.readOnly ? 80 : 0),
                            child: CustomChatWidget(
                              controller: widget.controller,
                              currentUser: widget.currentUser,
                              messages:
                                  widget.messages ?? widget.controller.messages,
                              onSend: _handleSend,
                              messageOptions: widget.messageOptions ??
                                  const MessageOptions(),
                              inputOptions:
                                  widget.inputOptions ?? const InputOptions(),
                              typingUsers: _getEffectiveTypingUsers(),
                              messageListOptions: widget.messageListOptions ??
                                  const MessageListOptions(),
                              readOnly: widget.readOnly,
                              quickReplyOptions: widget.quickReplyOptions ??
                                  const QuickReplyOptions(),
                              scrollToBottomOptions:
                                  widget.scrollToBottomOptions ??
                                      const ScrollToBottomOptions(),
                              typingIndicator:
                                  (widget.loadingConfig?.isLoading ?? false)
                                      ? widget.loadingConfig?.loadingIndicator
                                      : null,
                            ),
                          ),
                          if ((widget.loadingConfig?.isLoading ?? false) &&
                              (widget.loadingConfig?.showCenteredIndicator ??
                                  false))
                            Center(
                              child: widget.loadingConfig?.loadingIndicator ??
                                  const CircularProgressIndicator(),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Position welcome message as an overlay on top
                if (widget.controller.showWelcomeMessage)
                  Container(
                    color: Colors.black.withOpacityCompat(0.03),
                    child: Center(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: widget.welcomeMessageConfig?.builder?.call() ??
                            _buildWelcomeMessage(context),
                      ),
                    ),
                  ),
                if (!widget.readOnly)
                  Positioned(
                    left: widget.inputOptions?.positionedLeft ?? 0,
                    right: widget.inputOptions?.positionedRight ?? 0,
                    bottom: widget.inputOptions?.positionedBottom ?? 0.1,
                    child: widget.inputOptions?.useOuterContainer == false
                        ? _buildChatInput() // Render input directly without container
                        : Material(
                            elevation:
                                widget.inputOptions?.materialElevation ?? 0,
                            color: widget.inputOptions?.useScaffoldBackground ==
                                    true
                                ? Theme.of(context).scaffoldBackgroundColor
                                : widget.inputOptions?.materialColor,
                            shape: widget.inputOptions?.materialShape ??
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(22),
                                  side: BorderSide.none,
                                ),
                            clipBehavior: Clip.antiAlias,
                            child: Padding(
                              padding: widget.inputOptions?.materialPadding ??
                                  const EdgeInsets.all(8.0),
                              child: _buildChatInput(),
                            ),
                          ),
                  ),
              ],
            ),
          ),
        ),
      );

  Widget _buildWelcomeMessage(final BuildContext context) {
    debugPrint(
        'AiChatWidget: Building welcome message with ${widget.exampleQuestions.length} questions');

    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;
    final screenSize = MediaQuery.of(context).size;

    final welcomeConfig = widget.welcomeMessageConfig;
    // Get the first question's config as a default, if available
    final defaultQuestionConfig = widget.exampleQuestions.isNotEmpty
        ? widget.exampleQuestions.first.config
        : null;

    // Log if no questions to display
    if (widget.exampleQuestions.isEmpty) {
      debugPrint(
          'AiChatWidget: No example questions to display in welcome message');
    }

    return FadeTransition(
      opacity: _animationController,
      child: Container(
        // Constrain width to prevent excessive horizontal stretching
        width: math.min(500, screenSize.width * 0.9),
        // Use margin to center the welcome message
        margin: welcomeConfig?.containerMargin ??
            const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
        padding: welcomeConfig?.containerPadding ?? const EdgeInsets.all(24),
        decoration: welcomeConfig?.containerDecoration ??
            BoxDecoration(
              color: isDarkMode ? const Color(0xFF1E2026) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color:
                      Colors.black.withOpacityCompat(isDarkMode ? 0.3 : 0.08),
                  blurRadius: 20,
                  spreadRadius: -4,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(
                color: primaryColor.withOpacityCompat(isDarkMode ? 0.2 : 0.15),
                width: 1.5,
              ),
            ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              welcomeConfig?.title ?? widget.aiName,
              style: welcomeConfig?.titleStyle ??
                  TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.5,
                    color: isDarkMode ? Colors.white : Colors.black,
                    height: 1.3,
                  ),
            ),
            if (widget.exampleQuestions.isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                padding: welcomeConfig?.questionsSectionPadding ??
                    const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                decoration: welcomeConfig?.questionsSectionDecoration ??
                    BoxDecoration(
                      color: primaryColor
                          .withOpacityCompat(isDarkMode ? 0.15 : 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: primaryColor
                            .withOpacityCompat(isDarkMode ? 0.3 : 0.2),
                      ),
                    ),
                child: Text(
                  welcomeConfig?.questionsSectionTitle ??
                      'Try asking one of these questions:',
                  style: welcomeConfig?.questionsSectionTitleStyle ??
                      TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                ),
              ),
              const SizedBox(height: 16),
              ...widget.exampleQuestions.map(
                (question) {
                  // Get the question's config or use the default
                  final effectiveConfig =
                      question.config ?? defaultQuestionConfig;
                  return _buildExampleQuestion(
                    question,
                    effectiveConfig ?? const ExampleQuestionConfig(),
                    isDarkMode,
                    primaryColor,
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExampleQuestion(
    final ExampleQuestion question,
    final ExampleQuestionConfig effectiveConfig,
    final bool isDarkMode,
    final Color primaryColor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => handleExampleQuestionTap(question.question),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: effectiveConfig.containerPadding,
            decoration: effectiveConfig.containerDecoration ??
                BoxDecoration(
                  color:
                      primaryColor.withOpacityCompat(isDarkMode ? 0.12 : 0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color:
                        primaryColor.withOpacityCompat(isDarkMode ? 0.3 : 0.15),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor
                          .withOpacityCompat(isDarkMode ? 0.12 : 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                      spreadRadius: -2,
                    ),
                  ],
                ),
            child: Row(
              children: [
                Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: effectiveConfig.iconSize,
                  color: effectiveConfig.iconColor ??
                      (isDarkMode
                          ? Colors.white.withOpacityCompat(0.8)
                          : primaryColor.withOpacityCompat(0.8)),
                ),
                SizedBox(width: effectiveConfig.spacing),
                Expanded(
                  child: Text(
                    question.question,
                    style: effectiveConfig.textStyle ??
                        TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDarkMode
                              ? Colors.white.withOpacityCompat(0.9)
                              : Colors.black.withOpacityCompat(0.8),
                          height: 1.4,
                        ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  effectiveConfig.trailingIconData ??
                      Icons.arrow_forward_ios_rounded,
                  size: effectiveConfig.trailingIconSize,
                  color: effectiveConfig.trailingIconColor ??
                      (isDarkMode
                          ? Colors.white.withOpacityCompat(0.5)
                          : primaryColor.withOpacityCompat(0.5)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

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
        ? primaryColor.withOpacityCompat(0.15 * 255)
        : primaryColor.withOpacityCompat(0.08 * 255);

    return InkWell(
      onTap: () => handleExampleQuestionTap(question.question),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: chipColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: primaryColor.withOpacityCompat(0.2 * 255),
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

  // Update the _buildChatInput method
  Widget _buildChatInput() {
    if (widget.readOnly) {
      return const SizedBox.shrink();
    }

    // Get the app's text direction
    final appDirection = Directionality.of(context);
    final theme = Theme.of(context);
    final themeExtension = theme.extension<CustomThemeExtension>();
    final isDarkMode = theme.brightness == Brightness.dark;

    // Get the appropriate input options
    final baseInputOptions = widget.inputOptions ?? const InputOptions();

    // Get default decoration
    final decoration = baseInputOptions.decoration;

    // Apply theme-specific colors
    final effectiveDecoration = decoration?.copyWith(
      fillColor: themeExtension?.inputBackgroundColor ??
          (isDarkMode ? const Color(0xFF1E2026) : Colors.white),
    );

    // Create input options without dynamic direction changes
    final effectiveInputOptions = InputOptions(
      // Preserve original properties
      textStyle: baseInputOptions.textStyle,
      decoration: effectiveDecoration,
      margin: baseInputOptions.margin,
      containerDecoration: baseInputOptions.containerDecoration?.copyWith(
        color: themeExtension?.inputBackgroundColor ??
            (isDarkMode ? const Color(0xFF1E2026) : Colors.white),
      ),
      containerBackgroundColor: baseInputOptions.containerBackgroundColor,
      blurStrength: baseInputOptions.blurStrength,
      containerPadding: baseInputOptions.containerPadding,
      clipBehavior: baseInputOptions.clipBehavior,
      materialElevation: baseInputOptions.materialElevation,
      materialColor: themeExtension?.inputBackgroundColor ??
          (isDarkMode ? const Color(0xFF1E2026) : Colors.white),
      materialShape: baseInputOptions.materialShape,
      useScaffoldBackground: baseInputOptions.useScaffoldBackground,
      materialPadding: baseInputOptions.materialPadding,
      inputHeight: baseInputOptions.inputHeight,
      inputContainerHeight: baseInputOptions.inputContainerHeight,
      inputContainerConstraints: baseInputOptions.inputContainerConstraints,
      inputContainerWidth: baseInputOptions.inputContainerWidth,
      useOuterContainer: baseInputOptions.useOuterContainer,
      useOuterMaterial: baseInputOptions.useOuterMaterial,
      sendButtonBuilder: baseInputOptions.sendButtonBuilder,
      sendOnEnter: baseInputOptions.sendOnEnter,
      autocorrect: baseInputOptions.autocorrect,

      // Use app direction instead of dynamic direction
      inputTextDirection: appDirection,
    );

    return ChatInput(
      controller: _textController,
      focusNode: _inputFocusNode,
      options: effectiveInputOptions,
      onSend: _handleSubmitted,
    );
  }

  void _handleSubmitted() {
    if (_textController.text.trim().isNotEmpty) {
      _handleSend(
        ChatMessage(
          text: _textController.text,
          user: widget.currentUser,
          createdAt: DateTime.now(),
          isMarkdown: false,
        ),
      );
      _textController.clear();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();

    _textController.removeListener(() {});

    // Don't dispose if using external controller
    if (widget.inputOptions?.textController == null) {
      _textController.dispose();
    }
    _inputFocusNode.dispose();
    super.dispose();
  }
}
