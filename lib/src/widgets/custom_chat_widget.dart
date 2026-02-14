import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_streaming_text_markdown/flutter_streaming_text_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controllers/chat_messages_controller.dart';
import '../models/chat/models.dart';
import '../models/example_question.dart';
import '../models/input_options.dart';
import '../models/welcome_message_config.dart';
import '../utils/color_extensions.dart';
import 'message_attachment.dart';

/// Full-featured chat widget with streaming markdown, typing indicators, and pagination.
class CustomChatWidget extends StatefulWidget {
  final ChatUser currentUser;
  final List<ChatMessage> messages;
  final void Function(ChatMessage) onSend;
  final MessageOptions messageOptions;
  final InputOptions inputOptions;
  final List<ChatUser>? typingUsers;
  final MessageListOptions messageListOptions;
  final bool readOnly;
  final QuickReplyOptions quickReplyOptions;
  final ScrollToBottomOptions scrollToBottomOptions;
  final ChatMessagesController? controller;

  /// Streaming animation configuration
  final Duration streamingTypingSpeed;
  final bool streamingEnabled;
  final Duration streamingFadeInDuration;
  final Curve streamingFadeInCurve;
  final bool streamingFadeInEnabled;
  final bool streamingWordByWord;

  final ChatSpacingConfig spacingConfig;

  /// Custom widget to display instead of the default typing indicator
  final Widget? typingIndicator;

  /// Configuration for the welcome message
  final WelcomeMessageConfig? welcomeMessageConfig;

  /// Example questions to show in the welcome message
  final List<ExampleQuestion> exampleQuestions;

  const CustomChatWidget({
    super.key,
    required this.currentUser,
    required this.messages,
    required this.onSend,
    required this.messageOptions,
    this.inputOptions = const InputOptions(),
    required this.typingUsers,
    required this.messageListOptions,
    required this.readOnly,
    required this.quickReplyOptions,
    required this.scrollToBottomOptions,
    this.typingIndicator,
    this.controller,
    this.welcomeMessageConfig,
    this.exampleQuestions = const [],
    this.streamingTypingSpeed = const Duration(milliseconds: 28),
    this.streamingEnabled = true,
    this.streamingFadeInDuration = const Duration(milliseconds: 260),
    this.streamingFadeInCurve = Curves.easeInOut,
    this.streamingFadeInEnabled = false,
    this.streamingWordByWord = false,
    required this.spacingConfig,
  });

  @override
  State<CustomChatWidget> createState() => _CustomChatWidgetState();
}

class _CustomChatWidgetState extends State<CustomChatWidget> {
  late ScrollController _scrollController;
  bool _showScrollToBottom = false;
  Timer? _scrollDebounce;

  /// Check if welcome message should be shown
  bool _shouldShowWelcomeMessage() {
    return widget.controller?.showWelcomeMessage == true &&
        (widget.welcomeMessageConfig != null ||
            widget.exampleQuestions.isNotEmpty) &&
        widget.messages.isEmpty; // Only show if there are no messages
  }

  @override
  void initState() {
    super.initState();
    _scrollController =
        widget.messageListOptions.scrollController ?? ScrollController();
    _scrollController.addListener(_handleScroll);

    // Connect scroll controller to the messages controller if available
    _connectScrollControllerToMessagesController();
  }

  void _connectScrollControllerToMessagesController() {
    // If a controller was passed to the widget, connect our scroll controller to it
    if (widget.controller != null) {
      widget.controller!.setScrollController(_scrollController);

      // Attempt an initial scroll to bottom after widget is built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.messages.isNotEmpty) {
          widget.controller!.scrollToBottom();
        }
      });
    }
  }

  @override
  void didUpdateWidget(CustomChatWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update the controller if it changed
    if (oldWidget.messageListOptions.scrollController !=
        widget.messageListOptions.scrollController) {
      _scrollController.removeListener(_handleScroll);
      _scrollController =
          widget.messageListOptions.scrollController ?? ScrollController();
      _scrollController.addListener(_handleScroll);

      // Reconnect scroll controller
      _connectScrollControllerToMessagesController();
    }
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;

    // Debounce scroll events to avoid excessive rebuilds
    _scrollDebounce?.cancel();
    _scrollDebounce = Timer(
        widget.messageListOptions.paginationConfig.loadMoreDebounceTime, () {
      if (!mounted) return;

      final position = _scrollController.position.pixels;
      final maxScroll = _scrollController.position.maxScrollExtent;

      // Update scroll to bottom button visibility
      final shouldShow = widget.messageListOptions.paginationConfig.reverseOrder
          ? position >
              100 // In reverse mode, scroll from bottom means we've scrolled up
          : (maxScroll - position) >
              100; // In normal mode, we need to check distance from bottom

      if (shouldShow != _showScrollToBottom) {
        setState(() => _showScrollToBottom = shouldShow);
      }

      // Check if we should load more messages
      final paginationConfig = widget.messageListOptions.paginationConfig;
      if (!paginationConfig.enabled || !paginationConfig.autoLoadOnScroll) {
        return;
      }

      // Determine if we are near the edge for loading more messages
      bool shouldLoadMore;
      if (paginationConfig.reverseOrder) {
        // In reverse mode: Check if we're near the top
        shouldLoadMore = _scrollController.position.pixels <
            paginationConfig.distanceToTriggerLoadPixels;
      } else {
        // Normal mode: Check if we're near the bottom
        shouldLoadMore = (maxScroll - _scrollController.position.pixels) <
            paginationConfig.distanceToTriggerLoadPixels;
      }

      if (shouldLoadMore &&
          !widget.messageListOptions.isLoadingMore &&
          widget.messageListOptions.hasMoreMessages) {
        widget.messageListOptions.onLoadMore?.call();
      }
    });
  }

  @override
  void dispose() {
    _scrollDebounce?.cancel();
    _scrollController.removeListener(_handleScroll);

    // Only dispose the scroll controller if we created it ourselves
    // If it was provided via messageListOptions.scrollController, don't dispose it
    if (widget.messageListOptions.scrollController == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _buildMessageList(),
            ),
            if (widget.quickReplyOptions.quickReplies != null &&
                widget.quickReplyOptions.quickReplies!.isNotEmpty)
              Padding(
                padding: widget.spacingConfig.quickRepliesPadding,
                child: _buildQuickReplies(),
              ),
          ],
        ),
        if (_showScrollToBottom || widget.scrollToBottomOptions.alwaysVisible)
          _buildScrollToBottomButton(),
      ],
    );
  }

  Widget _buildMessageList() {
    final paginationConfig = widget.messageListOptions.paginationConfig;

    // Build loading header/footer if needed
    Widget? loadingWidget;
    Widget? noMoreMessagesWidget;

    if (widget.messageListOptions.isLoadingMore) {
      loadingWidget = paginationConfig.loadingBuilder?.call() ??
          _buildDefaultLoadingIndicator();
    } else if (!widget.messageListOptions.hasMoreMessages &&
        widget.messages.isNotEmpty) {
      noMoreMessagesWidget = paginationConfig.noMoreMessagesBuilder?.call() ??
          _buildNoMoreMessagesIndicator();
    }

    // Build the list with header/footer as needed
    return ListView.builder(
      // key: const PageStorageKey('chat_messages'),
      controller: _scrollController,
      reverse: paginationConfig.reverseOrder,
      physics: widget.messageListOptions.scrollPhysics ??
          const BouncingScrollPhysics(),
      keyboardDismissBehavior: widget.messageListOptions.keyboardDismissBehavior ??
          ScrollViewKeyboardDismissBehavior.onDrag,
      padding: widget.spacingConfig.messageListPadding,
      itemCount: widget.messages.length +
          (widget.typingUsers?.isNotEmpty == true ? 1 : 0) +
          (loadingWidget != null ? 1 : 0) +
          (noMoreMessagesWidget != null ? 1 : 0) +
          (_shouldShowWelcomeMessage() ? 1 : 0),
      cacheExtent: paginationConfig.cacheExtent,
      itemBuilder: (context, index) {
        // In reverse mode (newest at bottom), we want to show the loading indicator at index 0 (bottom of screen)
        if (paginationConfig.reverseOrder) {
          // Handle typing indicator at the bottom position (index 0)
          if (widget.typingUsers?.isNotEmpty == true && index == 0) {
            return _buildTypingIndicator();
          }

          // Shift message index up by 1 if there's a typing indicator
          if (widget.typingUsers?.isNotEmpty == true && index > 0) {
            index = index - 1;
          }

          // Handle pagination loading indicators at the top (end of list)
          if (loadingWidget != null &&
              index ==
                  widget.messages.length +
                      (widget.typingUsers?.isNotEmpty == true ? 0 : 0)) {
            return loadingWidget;
          }

          if (noMoreMessagesWidget != null &&
              index ==
                  widget.messages.length +
                      (widget.typingUsers?.isNotEmpty == true ? 0 : 0)) {
            return noMoreMessagesWidget;
          }

          // Handle welcome message at the top (highest index) in reverse mode
          if (_shouldShowWelcomeMessage() &&
              index ==
                  widget.messages.length +
                      (widget.typingUsers?.isNotEmpty == true ? 0 : 0) +
                      (loadingWidget != null ? 1 : 0) +
                      (noMoreMessagesWidget != null ? 1 : 0)) {
            return _buildWelcomeMessage();
          }
        } else {
          // In chronological mode (oldest at bottom)
          // Pagination indicators at the beginning
          if (loadingWidget != null && index == 0) {
            return loadingWidget;
          }

          if (noMoreMessagesWidget != null && index == 0) {
            return noMoreMessagesWidget;
          }

          // Typing indicator at the end
          if (index == widget.messages.length &&
              widget.typingUsers?.isNotEmpty == true) {
            return _buildTypingIndicator();
          }

          // Handle welcome message in chronological mode - after pagination but before messages
          final welcomeOffset = _shouldShowWelcomeMessage() ? 1 : 0;
          final paginationOffset =
              (loadingWidget != null || noMoreMessagesWidget != null) ? 1 : 0;

          if (_shouldShowWelcomeMessage() && index == paginationOffset) {
            return _buildWelcomeMessage();
          }

          // Adjust index for header items
          if ((loadingWidget != null ||
                  noMoreMessagesWidget != null ||
                  _shouldShowWelcomeMessage()) &&
              index > paginationOffset + welcomeOffset - 1) {
            index = index - paginationOffset - welcomeOffset;
          }
        }

        // Render message bubble
        if (index < widget.messages.length) {
          final message = widget.messages[index];
          final isUser = message.user.id == widget.currentUser.id;
          final messageId = widget.controller?.getMessageId(message) ??
              (message.customProperties?['id'] as String? ??
                  '${message.user.id}_${message.createdAt.millisecondsSinceEpoch}');

          // return _buildMessageBubble(message, isUser);
          return RepaintBoundary(
            child: KeyedSubtree(
              key: ValueKey(messageId),
              child: _buildMessageBubble(message, isUser),
            ),
          );
        }

        return null;
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isUser) {
    // Check for custom message builder from the message itself
    if (message.customBuilder != null) {
      return message.customBuilder!(context, message);
    }

    // Helper function to build the default bubble
    Widget buildDefaultBubble() {
      return _buildDefaultMessageBubble(message, isUser);
    }

    // Check for custom bubble builder from MessageOptions
    if (widget.messageOptions.customBubbleBuilder != null) {
      return widget.messageOptions.customBubbleBuilder!(
        context,
        message,
        isUser,
      );
    }

    // Return default bubble if no custom builder is provided
    return buildDefaultBubble();
  }

  /// Builds the default message bubble with all standard styling and features.
  ///
  /// This method contains the original bubble building logic and is used as
  /// the fallback when no custom bubble builder is provided, or as the default
  /// bubble passed to custom bubble builders.
  Widget _buildDefaultMessageBubble(ChatMessage message, bool isUser) {
    Size measureText(
      String text, {
      double maxWidth = double.infinity,
      TextStyle? style,
    }) {
      final textPainter = TextPainter(
        text: TextSpan(text: text, style: style),
        maxLines: 1,
        textDirection: TextDirection.ltr,
      )..layout(minWidth: 0, maxWidth: maxWidth);

      return textPainter.size;
    }

    final textSize = measureText(message.text,
        style: const TextStyle(
          fontSize: 15,
          height: 1.5,
          letterSpacing: 0.2,
        ));

    ///need to add this to check username size
    final usernameTextSize = measureText(message.user.name,
        style: const TextStyle(
          fontSize: 15,
          height: 1.5,
          letterSpacing: 0.2,
        ));

    ///need to add this to check time stamp size
    final timeTextSize = measureText(
        widget.messageOptions.timeFormat != null
            ? widget.messageOptions.timeFormat!(message.createdAt)
            : _defaultTimestampFormat(message.createdAt),
        style: const TextStyle(
          fontSize: 15,
          height: 1.5,
          letterSpacing: 0.2,
        ));

    // Get effective decoration from MessageOptions
    final effectiveDecoration = widget.messageOptions.effectiveDecoration;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;

    // Get bubble style configuration
    final bubbleStyle =
        widget.messageOptions.bubbleStyle ?? BubbleStyle.defaultStyle;

    // Premium design colors for a sophisticated look
    final defaultUserBubbleColor = isDark
        ? primaryColor.withOpacityCompat(0.18)
        : primaryColor.withOpacityCompat(0.06);
    final defaultAiBubbleColor =
        isDark ? const Color(0xFF2D2D2D) : Colors.white;

    // Refined corner radius values for modern messaging apps
    final topLeftRadius = isUser
        ? bubbleStyle.userBubbleTopLeftRadius ?? 22
        : bubbleStyle.aiBubbleTopLeftRadius ?? 2;
    final topRightRadius = isUser
        ? bubbleStyle.userBubbleTopRightRadius ?? 2
        : bubbleStyle.aiBubbleTopRightRadius ?? 22;
    final bottomLeftRadius = bubbleStyle.bottomLeftRadius ?? 22;
    final bottomRightRadius = bubbleStyle.bottomRightRadius ?? 22;

    final defaultMargin = widget.spacingConfig.messageBubbleMargin(isUser);

    final defaultMaxWidth = MediaQuery.of(context).size.width * 0.75;
    // Use different widths for user vs AI messages
    final maxWidth = isUser
        ? bubbleStyle.userBubbleMaxWidth ??
            (textSize.width < defaultMaxWidth
                ? (115 +
                        max(textSize.width,
                            max(usernameTextSize.width, timeTextSize.width)))
                    .toDouble()
                : defaultMaxWidth)
        : bubbleStyle.aiBubbleMaxWidth ??
            MediaQuery.of(context).size.width * 0.88;
    // final maxWidth = isUser
    //     ? bubbleStyle.userBubbleMaxWidth ??
    //         MediaQuery.of(context).size.width * 0.75
    //     : bubbleStyle.aiBubbleMaxWidth ??
    //         MediaQuery.of(context).size.width * 0.88;

    final minWidth = isUser
        ? bubbleStyle.userBubbleMinWidth ?? 0.0
        : bubbleStyle.aiBubbleMinWidth ?? 0.0;

    // Use custom colors if provided, otherwise use premium defaults
    final userBubbleColor =
        bubbleStyle.userBubbleColor ?? defaultUserBubbleColor;
    final aiBubbleColor = bubbleStyle.aiBubbleColor ?? defaultAiBubbleColor;

    // Enhanced text colors with precise opacity for readability
    final _ = isDark
        ? Colors.white.withOpacityCompat(0.96)
        : Colors.black.withOpacityCompat(0.86);

    // Premium AI message container border
    final aiBorder = !isUser
        ? Border.all(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
            width: 1,
          )
        : null;

    // Premium shadow for depth and elevation
    final boxShadow = bubbleStyle.enableShadow
        ? [
            BoxShadow(
              color: Colors.black.withOpacityCompat(isUser ? 0.04 : 0.06),
              blurRadius: isUser ? 4 : 8,
              offset: Offset(0, isUser ? 1 : 2),
              spreadRadius: isUser ? 0 : 1,
            ),
          ]
        : null;

    // Create a custom decoration that prioritizes bubbleStyle colors
    BoxDecoration createBubbleDecoration() {
      if (effectiveDecoration != null) {
        // Start with the effective decoration
        final decorator = BoxDecoration(
          color: isUser ? userBubbleColor : aiBubbleColor,
          borderRadius: effectiveDecoration.borderRadius ??
              BorderRadius.only(
                topLeft: Radius.circular(topLeftRadius),
                topRight: Radius.circular(topRightRadius),
                bottomLeft: Radius.circular(bottomLeftRadius),
                bottomRight: Radius.circular(bottomRightRadius),
              ),
          gradient: effectiveDecoration.gradient,
          image: effectiveDecoration.image,
          boxShadow: effectiveDecoration.boxShadow ?? boxShadow,
          border: effectiveDecoration.border ?? aiBorder,
          backgroundBlendMode: effectiveDecoration.backgroundBlendMode,
          shape: effectiveDecoration.shape,
        );

        return decorator;
      } else {
        // Use bubble style settings for decoration
        return BoxDecoration(
          color: isUser ? userBubbleColor : aiBubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(topLeftRadius),
            topRight: Radius.circular(topRightRadius),
            bottomLeft: Radius.circular(bottomLeftRadius),
            bottomRight: Radius.circular(bottomRightRadius),
          ),
          boxShadow: boxShadow,
          border: aiBorder,
        );
      }
    }

    // Enhanced bubble implementation with premium styling
    return Padding(
      padding: widget.spacingConfig.messageBubbleOuterPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxWidth,
                minWidth: minWidth,
              ),
              child: Container(
                margin: widget.messageOptions.containerMargin ?? defaultMargin,
                decoration: createBubbleDecoration(),
                child: Padding(
                  padding: widget.messageOptions.padding ??
                      widget.spacingConfig.messageBubbleInnerPadding,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Display user name if needed
                      if (widget.messageOptions.showUserName ?? true)
                        Padding(
                          padding: widget.spacingConfig.messageUsernameBottomPadding,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Add premium icon for AI messages
                              if (!isUser)
                                Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: Icon(
                                    Icons.smart_toy_outlined,
                                    size: 14,
                                    color:
                                        bubbleStyle.aiNameColor ?? primaryColor,
                                  ),
                                ),
                              Text(
                                message.user.name,
                                style: widget.messageOptions.userNameStyle ??
                                    TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      letterSpacing: 0.1,
                                      color: isUser
                                          ? (bubbleStyle.userNameColor ??
                                              Colors.blue[700])
                                          : (bubbleStyle.aiNameColor ??
                                              primaryColor),
                                    ),
                              ),
                            ],
                          ),
                        ),

                      // Handle markdown or plain text with premium styling
                      _buildMessageContent(message, context),

                      // Custom footer content (e.g., citations)
                      // Waits for streaming to complete before appearing
                      if (widget.messageOptions.footerBuilder != null)
                        _AnimatedFooter(
                          message: message,
                          isUser: isUser,
                          footerBuilder: widget.messageOptions.footerBuilder!,
                          controller: widget.controller,
                          streamingEnabled: widget.streamingEnabled,
                        ),

                      // Footer with timestamp and action buttons
                      Padding(
                        padding: EdgeInsets.only(
                            top: widget.messageOptions.showTime
                              ? widget.spacingConfig.messageFooterTopPadding.top
                              : 0),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Show timestamp with refined styling
                            if (widget.messageOptions.showTime)
                              Text(
                                widget.messageOptions.timeFormat != null
                                    ? widget.messageOptions
                                        .timeFormat!(message.createdAt)
                                    : _defaultTimestampFormat(
                                        message.createdAt),
                                style: widget.messageOptions.timeTextStyle ??
                                    TextStyle(
                                      fontSize: 11,
                                      letterSpacing: 0.1,
                                      color: isDark
                                          ? Colors.grey[500]
                                          : Colors.grey[600],
                                    ),
                              ),

                            // Show premium copy button for AI messages
                            if (!isUser &&
                                (widget.messageOptions.showCopyButton ?? false))
                              Material(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () {
                                    Clipboard.setData(
                                        ClipboardData(text: message.text));
                                    // Show premium feedback if provided
                                    if (widget.messageOptions.onCopy != null) {
                                      widget
                                          .messageOptions.onCopy!(message.text);
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: const Text(
                                              'Message copied to clipboard'),
                                          duration: const Duration(seconds: 2),
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          backgroundColor: isDark
                                              ? Colors.grey[800]
                                              : Colors.grey[900],
                                        ),
                                      );
                                    }
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.copy_outlined,
                                          size: 14,
                                          color: bubbleStyle.copyIconColor ??
                                              primaryColor,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Copy',
                                          style: TextStyle(
                                            fontSize: 12,
                                            letterSpacing: 0.1,
                                            color: bubbleStyle.copyIconColor ??
                                                primaryColor,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(ChatMessage message, BuildContext context) {
    // Use the custom builder if provided
    if (message.customBuilder != null) {
      return message.customBuilder!(context, message);
    }

    // Get the theme's brightness
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCurrentUser = message.user.id == widget.currentUser.id;

    // Check if this message should show streaming animation
    // Only animate the message that is currently being streamed
    final messageId = message.customProperties?['id'] as String? ??
        '${message.user.id}_${message.createdAt.millisecondsSinceEpoch}';
    final isCurrentlyStreaming =
        widget.controller?.currentlyStreamingMessageId == messageId;
    final shouldAnimate =
        isCurrentlyStreaming == true && widget.streamingEnabled;

    // Get appropriate text color from message options
    final textStyle = TextStyle(
      color: isCurrentUser
          ? widget.messageOptions.userTextColor ??
              (isDark ? Colors.white : Colors.black)
          : widget.messageOptions.aiTextColor ??
              (isDark ? Colors.white : Colors.black),
      fontSize: widget.messageOptions.textStyle?.fontSize,
      fontWeight: widget.messageOptions.textStyle?.fontWeight,
      fontFamily: widget.messageOptions.textStyle?.fontFamily,
      letterSpacing: widget.messageOptions.textStyle?.letterSpacing,
      height: widget.messageOptions.textStyle?.height,
    );

    Widget textWidget;

    // Handle markdown and non-markdown text
    if (message.isMarkdown) {
      // First, allow a custom markdown builder override
      final effectiveStyleSheet = widget.messageOptions.markdownStyleSheet ??
          MarkdownStyleSheet(
            p: textStyle,
            code: TextStyle(
              fontFamily: 'monospace',
              backgroundColor: (isDark ? Colors.black : Colors.grey[200])
                  ?.withOpacityCompat(0.3),
            ),
            codeblockDecoration: BoxDecoration(
              color: (isDark ? Colors.black : Colors.grey[200])
                  ?.withOpacityCompat(0.3),
              borderRadius: BorderRadius.circular(4),
            ),
          );

      final customMarkdown = widget.messageOptions.markdownBuilder?.call(
        context,
        message.text,
        effectiveStyleSheet,
        isCurrentUser,
      );
      if (customMarkdown != null) {
        return customMarkdown;
      }

      final needsInteractiveMarkdown =
          widget.messageOptions.onTapLink != null ||
              widget.messageOptions.onImageTap != null ||
              widget.messageOptions.enableImageTaps;

      if (needsInteractiveMarkdown) {
        // Preserve interactive Markdown behavior
        textWidget = Markdown(
          data: message.text,
          selectable: false,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          onTapLink: (text, href, title) async {
            if (widget.messageOptions.onTapLink != null) {
              widget.messageOptions.onTapLink!(text, href, title);
            } else if (href != null) {
              final uri = Uri.tryParse(href);
              if (uri != null && await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            }
          },
          styleSheet: effectiveStyleSheet,
          imageBuilder: widget.messageOptions.enableImageTaps
              ? null
              : (uri, title, alt) {
                  return GestureDetector(
                    onTap: widget.messageOptions.onImageTap != null
                        ? () => widget.messageOptions.onImageTap!(
                              uri.toString(),
                              title,
                              alt,
                            )
                        : null,
                    child: Image.network(
                      uri.toString(),
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.broken_image,
                                color: Colors.grey[600],
                              ),
                              if (alt != null)
                                Text(
                                  alt,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
        );
      } else {
        // Default: Check if streaming is enabled for markdown
        if (shouldAnimate && widget.streamingEnabled) {
          // Stream markdown using StreamingText
          textWidget = StreamingText(
            text: message.text,
            style: textStyle,
            typingSpeed: widget.streamingTypingSpeed,
            markdownEnabled: true,
            fadeInEnabled: widget.streamingFadeInEnabled,
            fadeInDuration: widget.streamingFadeInDuration,
            fadeInCurve: widget.streamingFadeInCurve,
            wordByWord: widget.streamingWordByWord,
            showCursor: false,
          );
        } else {
          // Static markdown rendering when streaming is disabled
          textWidget = Markdown(
            data: message.text,
            selectable: false,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            styleSheet: effectiveStyleSheet,
            padding: EdgeInsets.zero,
          );
        }
      }
    } else {
      // Non-markdown: allow custom text builder override
      final customText = widget.messageOptions.textBuilder?.call(
        context,
        message.text,
        textStyle,
        isCurrentUser,
      );
      if (customText != null) {
        return customText;
      }
      // Handle streaming vs static plain text
      if (shouldAnimate) {
        // Stream plain text only for active streaming messages
        textWidget = StreamingText(
          text: message.text,
          style: textStyle,
          typingSpeed: widget.streamingTypingSpeed,
          markdownEnabled: false,
          fadeInEnabled: widget.streamingFadeInEnabled,
          fadeInDuration: widget.streamingFadeInDuration,
          fadeInCurve: widget.streamingFadeInCurve,
          wordByWord: widget.streamingWordByWord,
          showCursor: false,
        );
      } else {
        // Static plain text for completed messages
        textWidget = Text(
          message.text,
          style: textStyle,
        );
      }
    }

    // Detect text direction from customProperties or infer from text content
    // This supports RTL languages like Arabic and Kurdish
    TextDirection? textDirection;
    final directionProp = message.customProperties?['textDirection'];
    final isRTL = message.customProperties?['isRTL'];

    if (directionProp == 'rtl' || isRTL == true) {
      textDirection = TextDirection.rtl;
    } else if (directionProp == 'ltr' || isRTL == false) {
      textDirection = TextDirection.ltr;
    } else {
      // Auto-detect from text content if not specified
      textDirection = _detectTextDirection(message.text);
    }

    // Wrap with Directionality to ensure proper RTL/LTR rendering
    final directionalTextWidget = Directionality(
      textDirection: textDirection,
      child: textWidget,
    );

    // Display media attachments if present
    if (message.media != null && message.media!.isNotEmpty) {
      return Column(
        crossAxisAlignment: textDirection == TextDirection.rtl
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          directionalTextWidget,
          const SizedBox(height: 8),
          ...message.media!.map((media) {
            return Padding(
              padding: widget.spacingConfig.messageMediaSpacing,
              child: MessageAttachment(
                media: media,
                onTap: widget.messageOptions.onMediaTap,
                enableImageTaps: widget.messageOptions.enableImageTaps,
              ),
            );
          }),
        ],
      );
    }

    return directionalTextWidget;
  }

  /// Detects text direction based on the first strong directional character.
  /// Returns RTL for Arabic, Persian, Kurdish, Hebrew, etc.
  TextDirection _detectTextDirection(String text) {
    // Remove markdown formatting, URLs, and code blocks for direction detection
    final cleanText = text
        .replaceAll(RegExp(r'```[\s\S]*?```'), '') // code blocks
        .replaceAll(RegExp(r'`[^`]+`'), '') // inline code
        .replaceAll(RegExp(r'\[([^\]]+)\]\([^\)]+\)'), r'\1') // links
        .replaceAll(RegExp(r'https?://[^\s]+'), '') // URLs
        .replaceAll(RegExp(r'[*_#>\-\[\]]'), '') // markdown chars
        .trim();

    // RTL Unicode ranges: Arabic, Hebrew, Persian/Kurdish extensions
    final rtlRegex = RegExp(
      r'[\u0600-\u06FF'  // Arabic
      r'\u0750-\u077F'   // Arabic Supplement
      r'\u08A0-\u08FF'   // Arabic Extended-A
      r'\uFB50-\uFDFF'   // Arabic Presentation Forms-A
      r'\uFE70-\uFEFF'   // Arabic Presentation Forms-B
      r'\u0590-\u05FF'   // Hebrew
      r']'
    );

    // Check first 100 characters for RTL
    final sample = cleanText.length > 100 ? cleanText.substring(0, 100) : cleanText;
    if (rtlRegex.hasMatch(sample)) {
      return TextDirection.rtl;
    }

    return TextDirection.ltr;
  }

  String _defaultTimestampFormat(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      // More precise date format for older messages
      final month = dateTime.month.toString().padLeft(2, '0');
      final day = dateTime.day.toString().padLeft(2, '0');
      return '$month/$day/${dateTime.year}';
    }
  }

  Widget _buildQuickReplies() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: widget.quickReplyOptions.quickReplies!.map((quickReply) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ElevatedButton(
              onPressed: () {
                widget.quickReplyOptions.onQuickReplyTap?.call(quickReply);
                widget.onSend(
                  ChatMessage(
                    text: quickReply,
                    user: widget.currentUser,
                    createdAt: DateTime.now(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[200],
                foregroundColor: Colors.black87,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(quickReply),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    // Use custom typing indicator if provided
    if (widget.typingIndicator != null) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ensure this is the only widget shown
            widget.typingIndicator!,
          ],
        ),
      );
    }

    // Default typing indicator dots
    return Padding(
      padding: widget.spacingConfig.typingIndicatorMargin,
      child: Row(
        children: [
          Container(
            padding: widget.spacingConfig.typingIndicatorPadding,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                _DotIndicator(),
                SizedBox(width: 4),
                _DotIndicator(delay: 0.2),
                SizedBox(width: 4),
                _DotIndicator(delay: 0.4),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultLoadingIndicator() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Column(
          children: [
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(height: 8),
            Text(
              widget.messageListOptions.paginationConfig.loadingText,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoMoreMessagesIndicator() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Text(
          widget.messageListOptions.paginationConfig.noMoreMessagesText,
          style: const TextStyle(
            fontSize: 12,
            fontStyle: FontStyle.italic,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildScrollToBottomButton() {
    if (!_showScrollToBottom && !widget.scrollToBottomOptions.alwaysVisible) {
      return const SizedBox.shrink();
    }

    return widget.scrollToBottomOptions.scrollToBottomBuilder
            ?.call(_scrollController) ??
        Positioned(
          bottom: widget.scrollToBottomOptions.bottomOffset,
          right: widget.scrollToBottomOptions.rightOffset,
          child: AnimatedOpacity(
            opacity: _showScrollToBottom ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[800]
                    : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacityCompat(0.08),
                    blurRadius: 8,
                    spreadRadius: 1,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(24),
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () {
                    if (_scrollController.hasClients) {
                      final paginationConfig =
                          widget.messageListOptions.paginationConfig;
                      if (paginationConfig.reverseOrder) {
                        // In reverse mode, scroll to top (0)
                        _scrollController.animateTo(
                          0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      } else {
                        // In chronological mode, scroll to bottom (maxScrollExtent)
                        _scrollController.animateTo(
                          _scrollController.position.maxScrollExtent,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      }
                    }
                    widget.scrollToBottomOptions.onScrollToBottomPress?.call();
                  },
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.keyboard_arrow_down,
                          size: 20,
                          color: Theme.of(context).primaryColor,
                        ),
                        if (widget.scrollToBottomOptions.showText) ...[
                          const SizedBox(width: 4),
                          Text(
                            widget.scrollToBottomOptions.buttonText,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
  }

  /// Build the welcome message widget
  Widget _buildWelcomeMessage() {
    // If custom builder is provided, use it
    if (widget.welcomeMessageConfig?.builder != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        child: widget.welcomeMessageConfig!.builder!(),
      );
    }

    // Otherwise, build default welcome message with title and example questions
    return _buildDefaultWelcomeMessage();
  }

  /// Build default welcome message with title and example questions
  Widget _buildDefaultWelcomeMessage() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      margin: widget.welcomeMessageConfig?.containerMargin ??
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: widget.welcomeMessageConfig?.containerPadding ??
          const EdgeInsets.all(24),
      decoration: widget.welcomeMessageConfig?.containerDecoration ??
          BoxDecoration(
            color: isDarkMode
                ? const Color(0xFF1E2026).withOpacityCompat(0.9)
                : Colors.white.withOpacityCompat(0.95),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          if (widget.welcomeMessageConfig?.title != null) ...[
            Text(
              widget.welcomeMessageConfig!.title!,
              style: widget.welcomeMessageConfig?.titleStyle ??
                  TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
            ),
            const SizedBox(height: 16),
          ],

          // Example questions
          if (widget.exampleQuestions.isNotEmpty) ...[
            Container(
              padding: widget.welcomeMessageConfig?.questionsSectionPadding ??
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration:
                  widget.welcomeMessageConfig?.questionsSectionDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.welcomeMessageConfig?.questionsSectionTitle ??
                        'Here are some questions you can ask:',
                    style: widget
                            .welcomeMessageConfig?.questionsSectionTitleStyle ??
                        TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: isDarkMode ? Colors.white70 : Colors.black87,
                        ),
                  ),
                  SizedBox(
                      height:
                          widget.welcomeMessageConfig?.questionSpacing ?? 12.0),
                  ...widget.exampleQuestions.map(
                    (question) =>
                        _buildExampleQuestionInWelcome(question, isDarkMode),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build an example question within the welcome message
  Widget _buildExampleQuestionInWelcome(
      ExampleQuestion question, bool isDarkMode) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    return Padding(
      padding: EdgeInsets.only(
          bottom: widget.welcomeMessageConfig?.questionSpacing ?? 12.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleExampleQuestionTap(question.question),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: question.config?.containerPadding ??
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: question.config?.containerDecoration ??
                BoxDecoration(
                  color:
                      primaryColor.withOpacityCompat(isDarkMode ? 0.12 : 0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color:
                        primaryColor.withOpacityCompat(isDarkMode ? 0.3 : 0.15),
                    width: 1,
                  ),
                ),
            child: Row(
              children: [
                Icon(
                  question.config?.iconData ?? Icons.chat_bubble_outline_rounded,
                  size: question.config?.iconSize ?? 18,
                  color: question.config?.iconColor ??
                      (isDarkMode
                          ? Colors.white.withOpacityCompat(0.8)
                          : primaryColor.withOpacityCompat(0.8)),
                ),
                SizedBox(width: question.config?.spacing ?? 12),
                Expanded(
                  child: Text(
                    question.question,
                    style: question.config?.textStyle ??
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
                  question.config?.trailingIconData ??
                      Icons.arrow_forward_ios_rounded,
                  size: question.config?.trailingIconSize ?? 16,
                  color: question.config?.trailingIconColor ??
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

  /// Handle example question tap in welcome message
  void _handleExampleQuestionTap(String question) {
    // Hide welcome message first
    if (widget.controller?.showWelcomeMessage == true) {
      widget.controller?.hideWelcomeMessage();
    }

    // Create and send the message
    final message = ChatMessage(
      text: question,
      user: widget.currentUser,
      createdAt: DateTime.now(),
    );

    // Call the onSend callback
    widget.onSend(message);
  }
}

class _DotIndicator extends StatefulWidget {
  final double delay;

  const _DotIndicator({this.delay = 0.0});

  @override
  State<_DotIndicator> createState() => _DotIndicatorState();
}

class _DotIndicatorState extends State<_DotIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _animation = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(widget.delay, 1.0, curve: Curves.easeInOut),
      ),
    );

    _controller.repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Color.lerp(
              Colors.grey[400],
              Colors.grey[800],
              _animation.value,
            ),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

/// Animated footer widget that waits for streaming to complete before appearing.
/// Uses a subtle, human-touch animation - no flashy AI effects.
class _AnimatedFooter extends StatefulWidget {
  const _AnimatedFooter({
    required this.message,
    required this.isUser,
    required this.footerBuilder,
    required this.controller,
    required this.streamingEnabled,
  });

  final ChatMessage message;
  final bool isUser;
  final Widget? Function(BuildContext, ChatMessage, bool) footerBuilder;
  final ChatMessagesController? controller;
  final bool streamingEnabled;

  @override
  State<_AnimatedFooter> createState() => _AnimatedFooterState();
}

class _AnimatedFooterState extends State<_AnimatedFooter>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _shouldShow = false;
  bool _wasStreaming = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 320),
      vsync: this,
    );

    // Subtle fade - not starting from 0 to feel more natural
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    ));

    // Very subtle upward slide - feels like content settling into place
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));

    // Listen to controller changes for streaming state updates
    widget.controller?.addListener(_onControllerChanged);

    _checkStreamingState();
  }

  void _onControllerChanged() {
    // Re-check streaming state when controller notifies (e.g., streaming stopped)
    if (mounted) {
      setState(_checkStreamingState);
    }
  }

  void _checkStreamingState() {
    final messageId = widget.message.customProperties?['id'] as String? ??
        '${widget.message.user.id}_${widget.message.createdAt.millisecondsSinceEpoch}';
    final controllerStreamingId = widget.controller?.currentlyStreamingMessageId;
    final isCurrentlyStreaming = controllerStreamingId == messageId;
    final isStreaming = isCurrentlyStreaming && widget.streamingEnabled;

    debugPrint('🎬 AnimatedFooter - messageId: $messageId');
    debugPrint('🎬 AnimatedFooter - controllerStreamingId: $controllerStreamingId');
    debugPrint('🎬 AnimatedFooter - isCurrentlyStreaming: $isCurrentlyStreaming');
    debugPrint('🎬 AnimatedFooter - streamingEnabled: ${widget.streamingEnabled}');
    debugPrint('🎬 AnimatedFooter - isStreaming: $isStreaming');
    debugPrint('🎬 AnimatedFooter - _wasStreaming: $_wasStreaming');

    if (isStreaming) {
      _wasStreaming = true;
      _shouldShow = false;
      debugPrint('🎬 AnimatedFooter - Currently streaming, hiding footer');
    } else {
      // Not streaming - show the footer
      if (_wasStreaming) {
        // Was streaming, now complete - animate in
        _shouldShow = true;
        _animController.forward();
        debugPrint('🎬 AnimatedFooter - Streaming complete, animating footer in');
      } else {
        // Was never streaming (loaded message) - show immediately
        _shouldShow = true;
        _animController.value = 1.0;
        debugPrint('🎬 AnimatedFooter - Never streamed, showing immediately');
      }
    }
    debugPrint('🎬 AnimatedFooter - _shouldShow: $_shouldShow');
  }

  @override
  void didUpdateWidget(_AnimatedFooter oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Handle controller changes
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onControllerChanged);
      widget.controller?.addListener(_onControllerChanged);
    }
    _checkStreamingState();
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onControllerChanged);
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🎬 AnimatedFooter.build - _shouldShow: $_shouldShow, isUser: ${widget.isUser}');
    if (!_shouldShow) {
      debugPrint('🎬 AnimatedFooter.build - Returning SizedBox (not showing)');
      return const SizedBox.shrink();
    }

    final footerWidget = widget.footerBuilder(
      context,
      widget.message,
      widget.isUser,
    );

    debugPrint('🎬 AnimatedFooter.build - footerWidget is null: ${footerWidget == null}');
    if (footerWidget == null) {
      debugPrint('🎬 AnimatedFooter.build - Returning SizedBox (footer is null)');
      return const SizedBox.shrink();
    }

    debugPrint('🎬 AnimatedFooter.build - Returning animated footer');
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: footerWidget,
      ),
    );
  }
}
