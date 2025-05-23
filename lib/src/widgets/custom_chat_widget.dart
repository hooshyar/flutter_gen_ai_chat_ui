import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../controllers/chat_messages_controller.dart';
import '../models/chat/models.dart';
import '../models/input_options.dart';
import '../utils/color_extensions.dart';
import 'message_attachment.dart';

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

  /// Custom widget to display instead of the default typing indicator
  final Widget? typingIndicator;

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
  });

  @override
  State<CustomChatWidget> createState() => _CustomChatWidgetState();
}

class _CustomChatWidgetState extends State<CustomChatWidget> {
  late ScrollController _scrollController;
  bool _showScrollToBottom = false;
  Timer? _scrollDebounce;
  bool _isNearEdge = false;

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
        if (paginationConfig.distanceToTriggerLoadPixels > 0) {
          shouldLoadMore = maxScroll > 0 &&
              (maxScroll - position) <=
                  paginationConfig.distanceToTriggerLoadPixels;
        } else {
          shouldLoadMore = maxScroll > 0 &&
              (maxScroll - position) / maxScroll <=
                  (1.0 - paginationConfig.scrollThreshold);
        }
      } else {
        // In chronological mode: Check if we're near the top
        if (paginationConfig.distanceToTriggerLoadPixels > 0) {
          shouldLoadMore =
              position <= paginationConfig.distanceToTriggerLoadPixels;
        } else {
          shouldLoadMore = maxScroll > 0 &&
              position / maxScroll <= paginationConfig.scrollThreshold;
        }
      }

      // If we should load more and weren't previously near the edge,
      // call the load more callback
      if (shouldLoadMore && !_isNearEdge) {
        _isNearEdge = true;
        // Provide haptic feedback if enabled
        if (paginationConfig.enableHapticFeedback) {
          HapticFeedback.lightImpact();
        }
        widget.messageListOptions.onLoadMore?.call();
      } else if (!shouldLoadMore && _isNearEdge) {
        _isNearEdge = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: _buildQuickReplies(),
                ),
            ],
          ),
          if (_showScrollToBottom || widget.scrollToBottomOptions.alwaysVisible)
            _buildScrollToBottomButton(),
        ],
      ),
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
      key: const PageStorageKey('chat_messages'),
      controller: _scrollController,
      reverse: paginationConfig.reverseOrder,
      physics: widget.messageListOptions.scrollPhysics ??
          const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: widget.messages.length +
          (widget.typingUsers?.isNotEmpty == true ? 1 : 0) +
          (loadingWidget != null ? 1 : 0) +
          (noMoreMessagesWidget != null ? 1 : 0),
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

          // Adjust index for header items
          if ((loadingWidget != null || noMoreMessagesWidget != null) &&
              index > 0) {
            index = index - 1;
          }
        }

        // Render message bubble
        if (index < widget.messages.length) {
          final message = widget.messages[index];
          final isUser = message.user.id == widget.currentUser.id;
          final messageId = message.customProperties?['id'] as String? ??
              '${message.user.id}_${message.createdAt.millisecondsSinceEpoch}_${message.text.hashCode}';

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

    // Professional margin with precise spacing
    final defaultMargin = EdgeInsets.only(
      top: 6,
      bottom: 6,
      right: isUser ? 16 : 64,
      left: isUser ? 64 : 16,
    );

    // Use different widths for user vs AI messages
    final maxWidth = isUser
        ? bubbleStyle.userBubbleMaxWidth ??
            MediaQuery.of(context).size.width * 0.75
        : bubbleStyle.aiBubbleMaxWidth ??
            MediaQuery.of(context).size.width * 0.88;

    final minWidth = isUser
        ? bubbleStyle.userBubbleMinWidth ?? 0.0
        : bubbleStyle.aiBubbleMinWidth ??
            MediaQuery.of(context).size.width * 0.5;

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
      padding: const EdgeInsets.symmetric(vertical: 4.0),
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
                      EdgeInsets.symmetric(
                          vertical: 14, horizontal: isUser ? 16 : 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Display user name if needed
                      if (widget.messageOptions.showUserName ?? true)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
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

                      // Premium footer with timestamp and action buttons
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
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
      // For Markdown content, we need a different approach
      // Create a properly styled markdown widget
      final markdownWidget = Markdown(
        key: ValueKey('markdown_${message.text.hashCode}'),
        data: message.text,
        selectable: true,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        onTapLink: widget.messageOptions.onTapLink,
        styleSheet: widget.messageOptions.markdownStyleSheet ??
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
            ),
      );

      textWidget = markdownWidget;
    } else {
      // For regular text messages
      textWidget = Text(
        message.text,
        style: textStyle,
      );
    }

    // Display media attachments if present
    if (message.media != null && message.media!.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          textWidget,
          const SizedBox(height: 8),
          ...message.media!.map((media) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: MessageAttachment(
                media: media,
                onTap: widget.messageOptions.onMediaTap,
                enableImageTaps: widget.messageOptions.enableImageTaps,
              ),
            );
          }).toList(),
        ],
      );
    }

    return textWidget;
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
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
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

  @override
  void dispose() {
    _scrollDebounce?.cancel();
    if (widget.messageListOptions.scrollController == null) {
      _scrollController.dispose();
    }
    super.dispose();
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
