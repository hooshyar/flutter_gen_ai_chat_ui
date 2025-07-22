import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../ai_chat_config.dart';
import '../chat_message.dart';
import 'media.dart';

/// Class for customizing chat bubble appearance
class BubbleStyle {
  /// Max width for user message bubbles
  final double? userBubbleMaxWidth;

  /// Max width for AI message bubbles
  final double? aiBubbleMaxWidth;

  /// Min width for user message bubbles
  final double? userBubbleMinWidth;

  /// Min width for AI message bubbles
  final double? aiBubbleMinWidth;

  /// Background color for user message bubbles
  final Color? userBubbleColor;

  /// Background color for AI message bubbles
  final Color? aiBubbleColor;

  /// Color for user name in user bubbles
  final Color? userNameColor;

  /// Color for AI name in AI bubbles
  final Color? aiNameColor;

  /// Color for the copy icon
  final Color? copyIconColor;

  /// Top left radius for user message bubbles
  final double? userBubbleTopLeftRadius;

  /// Top right radius for user message bubbles
  final double? userBubbleTopRightRadius;

  /// Top left radius for AI message bubbles
  final double? aiBubbleTopLeftRadius;

  /// Top right radius for AI message bubbles
  final double? aiBubbleTopRightRadius;

  /// Bottom left radius for all message bubbles
  final double? bottomLeftRadius;

  /// Bottom right radius for all message bubbles
  final double? bottomRightRadius;

  /// Whether to show shadow for message bubbles
  final bool enableShadow;

  /// Shadow opacity for message bubbles
  final double? shadowOpacity;

  /// Shadow blur radius for message bubbles
  final double? shadowBlurRadius;

  /// Shadow offset for message bubbles
  final Offset? shadowOffset;

  const BubbleStyle({
    this.userBubbleMaxWidth,
    this.aiBubbleMaxWidth,
    this.userBubbleMinWidth,
    this.aiBubbleMinWidth,
    this.userBubbleColor,
    this.aiBubbleColor,
    this.userNameColor,
    this.aiNameColor,
    this.copyIconColor,
    this.userBubbleTopLeftRadius,
    this.userBubbleTopRightRadius,
    this.aiBubbleTopLeftRadius,
    this.aiBubbleTopRightRadius,
    this.bottomLeftRadius,
    this.bottomRightRadius,
    this.enableShadow = true,
    this.shadowOpacity,
    this.shadowBlurRadius,
    this.shadowOffset,
  });

  /// Default style for message bubbles
  static const BubbleStyle defaultStyle = BubbleStyle(
    userBubbleTopLeftRadius: 18,
    userBubbleTopRightRadius: 4,
    aiBubbleTopLeftRadius: 4,
    aiBubbleTopRightRadius: 18,
    bottomLeftRadius: 18,
    bottomRightRadius: 18,
    enableShadow: true,
    shadowOpacity: 0.08,
    shadowBlurRadius: 10,
    shadowOffset: Offset(0, 3),
  );

  /// Creates a copy of this BubbleStyle with the given fields replaced
  BubbleStyle copyWith({
    double? userBubbleMaxWidth,
    double? aiBubbleMaxWidth,
    double? userBubbleMinWidth,
    double? aiBubbleMinWidth,
    Color? userBubbleColor,
    Color? aiBubbleColor,
    Color? userNameColor,
    Color? aiNameColor,
    Color? copyIconColor,
    double? userBubbleTopLeftRadius,
    double? userBubbleTopRightRadius,
    double? aiBubbleTopLeftRadius,
    double? aiBubbleTopRightRadius,
    double? bottomLeftRadius,
    double? bottomRightRadius,
    bool? enableShadow,
    double? shadowOpacity,
    double? shadowBlurRadius,
    Offset? shadowOffset,
  }) {
    return BubbleStyle(
      userBubbleMaxWidth: userBubbleMaxWidth ?? this.userBubbleMaxWidth,
      aiBubbleMaxWidth: aiBubbleMaxWidth ?? this.aiBubbleMaxWidth,
      userBubbleMinWidth: userBubbleMinWidth ?? this.userBubbleMinWidth,
      aiBubbleMinWidth: aiBubbleMinWidth ?? this.aiBubbleMinWidth,
      userBubbleColor: userBubbleColor ?? this.userBubbleColor,
      aiBubbleColor: aiBubbleColor ?? this.aiBubbleColor,
      userNameColor: userNameColor ?? this.userNameColor,
      aiNameColor: aiNameColor ?? this.aiNameColor,
      copyIconColor: copyIconColor ?? this.copyIconColor,
      userBubbleTopLeftRadius:
          userBubbleTopLeftRadius ?? this.userBubbleTopLeftRadius,
      userBubbleTopRightRadius:
          userBubbleTopRightRadius ?? this.userBubbleTopRightRadius,
      aiBubbleTopLeftRadius:
          aiBubbleTopLeftRadius ?? this.aiBubbleTopLeftRadius,
      aiBubbleTopRightRadius:
          aiBubbleTopRightRadius ?? this.aiBubbleTopRightRadius,
      bottomLeftRadius: bottomLeftRadius ?? this.bottomLeftRadius,
      bottomRightRadius: bottomRightRadius ?? this.bottomRightRadius,
      enableShadow: enableShadow ?? this.enableShadow,
      shadowOpacity: shadowOpacity ?? this.shadowOpacity,
      shadowBlurRadius: shadowBlurRadius ?? this.shadowBlurRadius,
      shadowOffset: shadowOffset ?? this.shadowOffset,
    );
  }
}

/// Options for customizing message appearance and behavior
class MessageOptions {
  /// Style for the message text
  final TextStyle? textStyle;

  /// Padding around the message bubble
  final EdgeInsets? padding;

  /// Margin around the message bubble
  final EdgeInsets? containerMargin;

  /// Decoration for the message bubble
  final BoxDecoration? decoration;

  /// Decoration for the message bubble (containerDecoration is the new name)
  final BoxDecoration? containerDecoration;

  /// Color for the message bubble background
  final Color? containerColor; // Added for backward compatibility

  /// Whether to show message timestamp
  final bool showTime;

  /// Style for the timestamp text
  final TextStyle? timeTextStyle;

  /// Function to format the timestamp
  final String Function(DateTime)? timeFormat;

  /// Spacing between message bubble and timestamp
  final double? timestampSpacing;

  /// Maximum number of reactions to show
  final int maxReactions;

  /// Size of reaction bubbles
  final double reactionSize;

  /// Whether to enable quick replies
  final bool enableQuickReply;

  /// Style options for message bubbles
  ///
  /// This property allows customizing the appearance of message bubbles,
  /// including colors, border radius, and shadows.
  ///
  /// The [bubbleStyle] colors (userBubbleColor and aiBubbleColor) will be used
  /// even when decoration or containerDecoration is provided.
  ///
  /// To completely customize the bubble appearance (overriding bubbleStyle):
  /// 1. Set bubbleStyle to null
  /// 2. Provide a custom decoration or containerDecoration
  final BubbleStyle? bubbleStyle;

  /// Whether to show user name
  final bool? showUserName;

  /// Style for user names
  final TextStyle? userNameStyle;

  /// Style sheet for markdown content
  final MarkdownStyleSheet? markdownStyleSheet;

  /// Callback when link is clicked
  final MarkdownTapLinkCallback? onTapLink;

  /// Whether to show copy button for AI messages
  final bool? showCopyButton;

  /// Callback when message is copied
  final void Function(String)? onCopy;

  /// Color for user message text
  final Color? userTextColor;

  /// Color for AI message text
  final Color? aiTextColor;

  /// Callback when media is tapped in a message
  final void Function(ChatMedia)? onMediaTap;

  /// Whether to enable tapping on images in markdown content
  final bool enableImageTaps;

  /// Custom builder for message bubbles
  final Widget Function(BuildContext, ChatMessage, Widget)? customBubbleBuilder;

  /// Creates an instance of [MessageOptions].
  ///
  /// Note about decorations:
  /// - If [bubbleStyle] is provided, its color settings will take precedence
  ///   over [decoration] and [containerDecoration] colors.
  /// - Use [bubbleStyle] for customizing bubble colors, radii, and shadows.
  /// - Use [decoration] or [containerDecoration] for more advanced decorations
  ///   like gradients and images, but be aware that [bubbleStyle] colors will
  ///   still be applied.
  /// - To fully bypass [bubbleStyle], set it to null and only use
  ///   [decoration] or [containerDecoration].
  const MessageOptions({
    this.textStyle,
    this.padding,
    this.containerMargin,
    this.decoration,
    this.containerDecoration,
    this.containerColor,
    this.showTime = true,
    this.timeTextStyle,
    this.timeFormat,
    this.timestampSpacing,
    this.maxReactions = 5,
    this.reactionSize = 24.0,
    this.enableQuickReply = true,
    this.bubbleStyle,
    this.showUserName = true,
    this.userNameStyle,
    this.markdownStyleSheet,
    this.onTapLink,
    this.showCopyButton = false,
    this.onCopy,
    this.userTextColor,
    this.aiTextColor,
    this.onMediaTap,
    this.enableImageTaps = false,
    this.customBubbleBuilder,
  });

  MessageOptions copyWith({
    TextStyle? textStyle,
    EdgeInsets? padding,
    EdgeInsets? containerMargin,
    BoxDecoration? decoration,
    BoxDecoration? containerDecoration,
    Color? containerColor,
    bool? showTime,
    TextStyle? timeTextStyle,
    String Function(DateTime)? timeFormat,
    double? timestampSpacing,
    int? maxReactions,
    double? reactionSize,
    bool? enableQuickReply,
    BubbleStyle? bubbleStyle,
    bool? showUserName,
    TextStyle? userNameStyle,
    MarkdownStyleSheet? markdownStyleSheet,
    MarkdownTapLinkCallback? onTapLink,
    bool? showCopyButton,
    void Function(String)? onCopy,
    Color? userTextColor,
    Color? aiTextColor,
    void Function(ChatMedia)? onMediaTap,
    bool? enableImageTaps,
    Widget Function(BuildContext, ChatMessage, Widget)? customBubbleBuilder,
  }) =>
      MessageOptions(
        textStyle: textStyle ?? this.textStyle,
        padding: padding ?? this.padding,
        containerMargin: containerMargin ?? this.containerMargin,
        decoration: decoration ?? this.decoration,
        containerDecoration: containerDecoration ?? this.containerDecoration,
        containerColor: containerColor ?? this.containerColor,
        showTime: showTime ?? this.showTime,
        timeTextStyle: timeTextStyle ?? this.timeTextStyle,
        timeFormat: timeFormat ?? this.timeFormat,
        timestampSpacing: timestampSpacing ?? this.timestampSpacing,
        maxReactions: maxReactions ?? this.maxReactions,
        reactionSize: reactionSize ?? this.reactionSize,
        enableQuickReply: enableQuickReply ?? this.enableQuickReply,
        bubbleStyle: bubbleStyle ?? this.bubbleStyle,
        showUserName: showUserName ?? this.showUserName,
        userNameStyle: userNameStyle ?? this.userNameStyle,
        markdownStyleSheet: markdownStyleSheet ?? this.markdownStyleSheet,
        onTapLink: onTapLink ?? this.onTapLink,
        showCopyButton: showCopyButton ?? this.showCopyButton,
        onCopy: onCopy ?? this.onCopy,
        userTextColor: userTextColor ?? this.userTextColor,
        aiTextColor: aiTextColor ?? this.aiTextColor,
        onMediaTap: onMediaTap ?? this.onMediaTap,
        enableImageTaps: enableImageTaps ?? this.enableImageTaps,
        customBubbleBuilder: customBubbleBuilder ?? this.customBubbleBuilder,
      );

  /// Get effective decoration with fallback to containerColor
  BoxDecoration? get effectiveDecoration {
    if (containerDecoration != null) {
      return containerDecoration;
    }
    if (decoration != null) {
      return decoration;
    }
    if (containerColor != null) {
      return BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(12),
      );
    }
    return null;
  }
}

/// Options for customizing the message list
class MessageListOptions {
  /// Custom scroll controller for the message list
  final ScrollController? scrollController;

  /// Custom scroll physics for the message list
  final ScrollPhysics? scrollPhysics;

  /// Builder for date separator between messages
  final Widget Function(DateTime)? dateSeparatorBuilder;

  /// Widget to show while loading more messages
  final Widget? loadingWidget;

  /// Callback when loading earlier messages via button
  final Future<void> Function()? onLoadEarlier;

  /// Pagination configuration for message loading
  final PaginationConfig paginationConfig;

  /// Whether more messages are currently loading
  final bool isLoadingMore;

  /// Whether there are more messages to load
  final bool hasMoreMessages;

  /// Callback when automatic loading more messages is triggered by scroll
  final Future<void> Function()? onLoadMore;

  const MessageListOptions({
    this.scrollController,
    this.scrollPhysics,
    this.dateSeparatorBuilder,
    this.loadingWidget,
    this.onLoadEarlier,
    this.paginationConfig = const PaginationConfig(),
    this.isLoadingMore = false,
    this.hasMoreMessages = true,
    this.onLoadMore,
  });

  MessageListOptions copyWith({
    ScrollController? scrollController,
    ScrollPhysics? scrollPhysics,
    Widget Function(DateTime)? dateSeparatorBuilder,
    Widget? loadingWidget,
    Future<void> Function()? onLoadEarlier,
    PaginationConfig? paginationConfig,
    bool? isLoadingMore,
    bool? hasMoreMessages,
    Future<void> Function()? onLoadMore,
  }) =>
      MessageListOptions(
        scrollController: scrollController ?? this.scrollController,
        scrollPhysics: scrollPhysics ?? this.scrollPhysics,
        dateSeparatorBuilder: dateSeparatorBuilder ?? this.dateSeparatorBuilder,
        loadingWidget: loadingWidget ?? this.loadingWidget,
        onLoadEarlier: onLoadEarlier ?? this.onLoadEarlier,
        paginationConfig: paginationConfig ?? this.paginationConfig,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        hasMoreMessages: hasMoreMessages ?? this.hasMoreMessages,
        onLoadMore: onLoadMore ?? this.onLoadMore,
      );
}

/// Options for customizing quick replies
class QuickReplyOptions {
  /// List of quick reply options
  final List<String>? quickReplies;

  /// Callback when a quick reply is tapped
  final void Function(String)? onQuickReplyTap;

  /// Decoration for quick reply buttons
  final BoxDecoration? decoration;

  /// Text style for quick reply buttons
  final TextStyle? textStyle;

  const QuickReplyOptions({
    this.quickReplies,
    this.onQuickReplyTap,
    this.decoration,
    this.textStyle,
  });

  QuickReplyOptions copyWith({
    List<String>? quickReplies,
    void Function(String)? onQuickReplyTap,
    BoxDecoration? decoration,
    TextStyle? textStyle,
  }) =>
      QuickReplyOptions(
        quickReplies: quickReplies ?? this.quickReplies,
        onQuickReplyTap: onQuickReplyTap ?? this.onQuickReplyTap,
        decoration: decoration ?? this.decoration,
        textStyle: textStyle ?? this.textStyle,
      );
}

/// Options for customizing scroll to bottom button
///
/// This button allows users to quickly scroll to the most recent messages.
/// - In chronological mode (reverseOrder: false), it scrolls to the bottom of the list.
/// - In reverse mode (reverseOrder: true), it scrolls to the top of the list.
class ScrollToBottomOptions {
  /// Whether to disable the scroll to bottom button
  final bool disabled;

  /// Whether to always show the scroll to bottom button
  final bool alwaysVisible;

  /// Callback when scroll to bottom button is pressed
  final VoidCallback? onScrollToBottomPress;

  /// Custom builder for scroll to bottom button
  final Widget Function(ScrollController)? scrollToBottomBuilder;

  /// Distance from bottom of the screen (default is 72)
  final double bottomOffset;

  /// Distance from right of the screen (default is 16)
  final double rightOffset;

  /// Whether to show text next to the icon (default is true)
  final bool showText;

  /// Custom text to display next to the icon (default is "Scroll to bottom")
  final String buttonText;

  const ScrollToBottomOptions({
    this.disabled = false,
    this.alwaysVisible = false,
    this.onScrollToBottomPress,
    this.scrollToBottomBuilder,
    this.bottomOffset = 72,
    this.rightOffset = 16,
    this.showText = false,
    this.buttonText = 'Scroll to bottom',
  });

  ScrollToBottomOptions copyWith({
    bool? disabled,
    bool? alwaysVisible,
    VoidCallback? onScrollToBottomPress,
    Widget Function(ScrollController)? scrollToBottomBuilder,
    double? bottomOffset,
    double? rightOffset,
    bool? showText,
    String? buttonText,
  }) =>
      ScrollToBottomOptions(
        disabled: disabled ?? this.disabled,
        alwaysVisible: alwaysVisible ?? this.alwaysVisible,
        onScrollToBottomPress:
            onScrollToBottomPress ?? this.onScrollToBottomPress,
        scrollToBottomBuilder:
            scrollToBottomBuilder ?? this.scrollToBottomBuilder,
        bottomOffset: bottomOffset ?? this.bottomOffset,
        rightOffset: rightOffset ?? this.rightOffset,
        showText: showText ?? this.showText,
        buttonText: buttonText ?? this.buttonText,
      );
}
