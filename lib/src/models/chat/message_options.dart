import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../../theme/code_block_theme.dart';
import '../../theme/custom_theme_extension.dart';
import '../ai_chat_config.dart';
import 'chat_message.dart';
import 'chat_user.dart';
import 'citation.dart';
import 'media.dart';

/// The two AI-message presentations a [MessageOptions.aiMessageLayout] can
/// resolve to (`DESIGN.md` §8.1).
enum AiMessageLayout {
  /// No card, no border, no shadow: the reading-column default. The AI's
  /// answer reads like prose, with the action row underneath it.
  document,

  /// The legacy-compatible bordered/filled bubble, restyled per the design
  /// tokens. Chosen automatically when the consumer has opted into bubble
  /// colors via [BubbleStyle], [MessageOptions.decoration]/
  /// [MessageOptions.effectiveDecoration], or a themed bubble color.
  bubble,
}

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

  /// Optional widget builder for the AI avatar (shown next to the AI name).
  /// Receives the AI [ChatUser] and returns a widget.
  final Widget Function(ChatUser chatUser)? aiAvatarWidgetBuilder;

  /// Optional widget builder for the user avatar (shown next to the user name).
  /// Receives the [ChatUser] and returns a widget.
  final Widget Function(ChatUser chatUser)? userAvatarWidgetBuilder;

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
    this.aiAvatarWidgetBuilder,
    this.userAvatarWidgetBuilder,
  });

  /// Default style for message bubbles, per `DESIGN.md` §5-§6: no shadow
  /// (elevation is expressed by space and a hairline, never blur), the user
  /// bubble uses a uniform 20 radius, and the (opt-in) AI bubble keeps a
  /// small leading-top corner to read as "coming from the left".
  static const BubbleStyle defaultStyle = BubbleStyle(
    userBubbleTopLeftRadius: 20,
    userBubbleTopRightRadius: 20,
    aiBubbleTopLeftRadius: 6,
    aiBubbleTopRightRadius: 20,
    bottomLeftRadius: 20,
    bottomRightRadius: 20,
    enableShadow: false,
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
    Widget Function(ChatUser)? aiAvatarWidgetBuilder,
    Widget Function(ChatUser)? userAvatarWidgetBuilder,
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
      aiAvatarWidgetBuilder:
          aiAvatarWidgetBuilder ?? this.aiAvatarWidgetBuilder,
      userAvatarWidgetBuilder:
          userAvatarWidgetBuilder ?? this.userAvatarWidgetBuilder,
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

  /// Style for the timestamp text (applies to both user and AI bubbles unless
  /// overridden by [userTimeTextStyle] / [aiTimeTextStyle]).
  final TextStyle? timeTextStyle;

  /// Style for the timestamp text on **user** bubbles.
  ///
  /// Takes precedence over [timeTextStyle] for user messages. Useful when a
  /// colored user bubble makes the shared timestamp hard to read.
  final TextStyle? userTimeTextStyle;

  /// Style for the timestamp text on **AI** bubbles.
  ///
  /// Takes precedence over [timeTextStyle] for AI messages.
  final TextStyle? aiTimeTextStyle;

  /// Function to format the timestamp
  final String Function(DateTime)? timeFormat;

  /// No effect: the footer's top padding is actually controlled by
  /// `ChatSpacingConfig.messageFooterTopPadding`. Will be removed in v3.0.0.
  @Deprecated(
    'Has no effect — use ChatSpacingConfig.messageFooterTopPadding instead. '
    'Will be removed in v3.0.0.',
  )
  final double? timestampSpacing;

  /// No effect: no reaction UI is implemented anywhere in the widget tree.
  /// Will be removed in v3.0.0.
  @Deprecated(
    'Has no effect — no reaction UI exists to apply it to. '
    'Will be removed in v3.0.0.',
  )
  final int maxReactions;

  /// No effect: no reaction UI is implemented anywhere in the widget tree.
  /// Will be removed in v3.0.0.
  @Deprecated(
    'Has no effect — no reaction UI exists to apply it to. '
    'Will be removed in v3.0.0.',
  )
  final double reactionSize;

  /// No effect: quick replies are actually driven by the separate
  /// `QuickReplyOptions` passed to `AiChatWidget`. Will be removed in v3.0.0.
  @Deprecated(
    'Has no effect — quick replies are controlled by QuickReplyOptions '
    'on AiChatWidget instead. Will be removed in v3.0.0.',
  )
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

  /// Whether to show user name.
  ///
  /// Defaults to `null`, which resolves per [resolveShowUserName]: `false`
  /// for the document AI layout (the default — no name row, no avatar),
  /// `true` for the bubble layout. An explicit `true`/`false` always wins
  /// over that resolution, for both the user's own messages and the AI's.
  final bool? showUserName;

  /// Chooses between the document (default) and bubble AI message
  /// presentations. Leave `null` to let [resolveAiMessageLayout] pick
  /// automatically from whether bubble colors/decoration are in play (see
  /// [AiMessageLayout]).
  final AiMessageLayout? aiMessageLayout;

  /// Style for user names
  final TextStyle? userNameStyle;

  /// Style sheet for markdown content
  final MarkdownStyleSheet? markdownStyleSheet;

  /// Callback when link is clicked
  final MarkdownTapLinkCallback? onTapLink;

  /// Custom icon widget shown next to the AI name.
  /// Defaults to [Icons.smart_toy_outlined] when null.
  /// Set to a [SizedBox.shrink] to hide the icon entirely.
  final Widget? aiNameIcon;

  /// Whether to show copy button for AI messages
  final bool? showCopyButton;

  /// Label for the copy button. Defaults to `'Copy'`. Set this to localize the
  /// button (e.g. `'نسخ'` for Arabic).
  final String? copyButtonLabel;

  /// Snackbar text shown after a message is copied. Defaults to
  /// `'Message copied to clipboard'`. Set this to localize the confirmation.
  final String? copiedToClipboardText;

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

  /// Whether tapping an image attachment (when [onMediaTap] is not set)
  /// opens a built-in full-screen lightbox/preview with pinch-zoom and
  /// swipe-between-images support. Has no effect unless [enableImageTaps]
  /// is also true, and an explicit [onMediaTap] always takes precedence
  /// over the built-in lightbox. Defaults to false — additive, existing
  /// consumers see no change in tap behavior unless they opt in.
  final bool enableAttachmentLightbox;

  /// Callback when an image in markdown content is tapped
  /// Provides the image URL, title, and alt text
  final void Function(String url, String? title, String? alt)? onImageTap;

  /// Whether fenced code blocks are syntax-highlighted.
  ///
  /// When false, code renders as a single unhighlighted span in
  /// [CodeBlockTheme.baseStyle] — useful for very large blocks or languages
  /// the highlighter doesn't know. Defaults to true.
  final bool enableSyntaxHighlighting;

  /// Visual theme for fenced code blocks (background, border, header and
  /// token colours).
  ///
  /// When null, [CodeBlockTheme.of] resolves a light or dark palette from the
  /// ambient [Brightness]. Inline `code` chips are unaffected — they keep
  /// using `markdownStyleSheet.code`.
  final CodeBlockTheme? codeBlockTheme;

  /// Whether fenced code blocks show a header copy button that copies the
  /// raw code (without fences) to the clipboard. Defaults to true.
  final bool showCodeBlockCopyButton;

  /// Custom builder for plain text content inside the bubble
  ///
  /// Allows overriding how non-markdown message text is rendered while keeping
  /// the default bubble layout intact.
  final Widget Function(
    BuildContext context,
    String text,
    TextStyle effectiveTextStyle,
    bool isUser,
  )? textBuilder;

  /// Custom builder for markdown content inside the bubble
  ///
  /// Allows overriding how markdown message content is rendered while keeping
  /// the default bubble layout intact.
  final Widget Function(
    BuildContext context,
    String text,
    MarkdownStyleSheet effectiveStyleSheet,
    bool isUser,
  )? markdownBuilder;

  /// Custom builder for message bubbles
  ///
  /// This builder allows for complete replacement of the default message bubble.
  /// The parameters provided are:
  /// - [BuildContext] context: The build context
  /// - [ChatMessage] message: The message being rendered
  /// - [bool] isUser: Whether this message is from the current user
  ///
  /// Return a completely custom widget that replaces the entire bubble.
  /// This provides true customization rather than just wrapping the default bubble.
  ///
  /// Prefer [bubbleBuilder] if you want to *wrap* the default bubble (e.g. to add
  /// a feedback/report button around it) rather than rebuild it from scratch.
  final Widget Function(BuildContext, ChatMessage, bool)? customBubbleBuilder;

  /// Custom builder that receives the default bubble so you can *wrap* it.
  ///
  /// Arguments:
  /// - [BuildContext] context: The build context
  /// - [ChatMessage] message: The message being rendered
  /// - [bool] isCurrentUser: Whether this message is from the current user
  /// - [Widget] defaultBubble: The fully-styled default bubble for this message
  ///
  /// Use this when you want to keep the package's bubble styling but add chrome
  /// around it (badges, action buttons, gestures). Takes precedence over
  /// [customBubbleBuilder] when both are set.
  ///
  /// ```dart
  /// MessageOptions(
  ///   bubbleBuilder: (context, message, isCurrentUser, defaultBubble) => Column(
  ///     crossAxisAlignment: CrossAxisAlignment.start,
  ///     children: [defaultBubble, FeedbackButtons(message: message)],
  ///   ),
  /// )
  /// ```
  final Widget Function(
    BuildContext context,
    ChatMessage message,
    bool isCurrentUser,
    Widget defaultBubble,
  )? bubbleBuilder;

  /// Custom builder for footer content after message text (e.g., citations)
  ///
  /// This builder allows adding content between the message text and the
  /// timestamp footer. Common uses include:
  /// - Citation chips for legal/source references
  /// - Action buttons
  /// - Feedback buttons
  ///
  /// The parameters provided are:
  /// - [BuildContext] context: The build context
  /// - [ChatMessage] message: The message being rendered
  /// - [bool] isUser: Whether this message is from the current user
  ///
  /// Return null to render nothing in the footer area.
  final Widget? Function(BuildContext, ChatMessage, bool)? footerBuilder;

  /// Callback when a citation is tapped
  ///
  /// Used when citations are rendered via the default citation display.
  /// Receives the tapped [ChatCitation] for navigation or detail display.
  final void Function(ChatCitation)? onCitationTap;

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
    this.userTimeTextStyle,
    this.aiTimeTextStyle,
    this.timeFormat,
    this.timestampSpacing,
    this.maxReactions = 5,
    this.reactionSize = 24.0,
    this.enableQuickReply = true,
    this.bubbleStyle,
    this.showUserName,
    this.aiMessageLayout,
    this.userNameStyle,
    this.markdownStyleSheet,
    this.onTapLink,
    this.aiNameIcon,
    this.showCopyButton = true,
    this.copyButtonLabel,
    this.copiedToClipboardText,
    this.onCopy,
    this.userTextColor,
    this.aiTextColor,
    this.onMediaTap,
    this.enableImageTaps = false,
    this.enableAttachmentLightbox = false,
    this.onImageTap,
    this.enableSyntaxHighlighting = true,
    this.codeBlockTheme,
    this.showCodeBlockCopyButton = true,
    this.textBuilder,
    this.markdownBuilder,
    this.customBubbleBuilder,
    this.bubbleBuilder,
    this.footerBuilder,
    this.onCitationTap,
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
    TextStyle? userTimeTextStyle,
    TextStyle? aiTimeTextStyle,
    String Function(DateTime)? timeFormat,
    double? timestampSpacing,
    int? maxReactions,
    double? reactionSize,
    bool? enableQuickReply,
    BubbleStyle? bubbleStyle,
    bool? showUserName,
    AiMessageLayout? aiMessageLayout,
    TextStyle? userNameStyle,
    MarkdownStyleSheet? markdownStyleSheet,
    MarkdownTapLinkCallback? onTapLink,
    Widget? aiNameIcon,
    bool? showCopyButton,
    String? copyButtonLabel,
    String? copiedToClipboardText,
    void Function(String)? onCopy,
    Color? userTextColor,
    Color? aiTextColor,
    void Function(ChatMedia)? onMediaTap,
    bool? enableImageTaps,
    bool? enableAttachmentLightbox,
    void Function(String url, String? title, String? alt)? onImageTap,
    bool? enableSyntaxHighlighting,
    CodeBlockTheme? codeBlockTheme,
    bool? showCodeBlockCopyButton,
    Widget Function(BuildContext, String, TextStyle, bool)? textBuilder,
    Widget Function(BuildContext, String, MarkdownStyleSheet, bool)?
        markdownBuilder,
    Widget Function(BuildContext, ChatMessage, bool)? customBubbleBuilder,
    Widget Function(BuildContext, ChatMessage, bool, Widget)? bubbleBuilder,
    Widget? Function(BuildContext, ChatMessage, bool)? footerBuilder,
    void Function(ChatCitation)? onCitationTap,
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
        userTimeTextStyle: userTimeTextStyle ?? this.userTimeTextStyle,
        aiTimeTextStyle: aiTimeTextStyle ?? this.aiTimeTextStyle,
        timeFormat: timeFormat ?? this.timeFormat,
        timestampSpacing: timestampSpacing ?? this.timestampSpacing,
        maxReactions: maxReactions ?? this.maxReactions,
        reactionSize: reactionSize ?? this.reactionSize,
        enableQuickReply: enableQuickReply ?? this.enableQuickReply,
        bubbleStyle: bubbleStyle ?? this.bubbleStyle,
        showUserName: showUserName ?? this.showUserName,
        aiMessageLayout: aiMessageLayout ?? this.aiMessageLayout,
        userNameStyle: userNameStyle ?? this.userNameStyle,
        markdownStyleSheet: markdownStyleSheet ?? this.markdownStyleSheet,
        onTapLink: onTapLink ?? this.onTapLink,
        aiNameIcon: aiNameIcon ?? this.aiNameIcon,
        showCopyButton: showCopyButton ?? this.showCopyButton,
        copyButtonLabel: copyButtonLabel ?? this.copyButtonLabel,
        copiedToClipboardText:
            copiedToClipboardText ?? this.copiedToClipboardText,
        onCopy: onCopy ?? this.onCopy,
        userTextColor: userTextColor ?? this.userTextColor,
        aiTextColor: aiTextColor ?? this.aiTextColor,
        onMediaTap: onMediaTap ?? this.onMediaTap,
        enableImageTaps: enableImageTaps ?? this.enableImageTaps,
        enableAttachmentLightbox:
            enableAttachmentLightbox ?? this.enableAttachmentLightbox,
        onImageTap: onImageTap ?? this.onImageTap,
        enableSyntaxHighlighting:
            enableSyntaxHighlighting ?? this.enableSyntaxHighlighting,
        codeBlockTheme: codeBlockTheme ?? this.codeBlockTheme,
        showCodeBlockCopyButton:
            showCodeBlockCopyButton ?? this.showCodeBlockCopyButton,
        textBuilder: textBuilder ?? this.textBuilder,
        markdownBuilder: markdownBuilder ?? this.markdownBuilder,
        customBubbleBuilder: customBubbleBuilder ?? this.customBubbleBuilder,
        bubbleBuilder: bubbleBuilder ?? this.bubbleBuilder,
        footerBuilder: footerBuilder ?? this.footerBuilder,
        onCitationTap: onCitationTap ?? this.onCitationTap,
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

  /// Resolves [aiMessageLayout] when explicitly set; otherwise infers it
  /// from whether the consumer has opted into bubble colors/decoration
  /// (`DESIGN.md` §8.1): a non-null [BubbleStyle.aiBubbleColor],
  /// [effectiveDecoration], or [themeExt]'s `messageBubbleColor` all resolve
  /// to [AiMessageLayout.bubble] so existing customized apps keep their
  /// bubbles; otherwise [AiMessageLayout.document].
  AiMessageLayout resolveAiMessageLayout(CustomThemeExtension? themeExt) {
    if (aiMessageLayout != null) return aiMessageLayout!;
    final hasBubbleColor = bubbleStyle?.aiBubbleColor != null;
    final hasDecoration = effectiveDecoration != null;
    final hasThemedBubble = themeExt?.messageBubbleColor != null;
    if (hasBubbleColor || hasDecoration || hasThemedBubble) {
      return AiMessageLayout.bubble;
    }
    return AiMessageLayout.document;
  }

  /// Resolves [showUserName]: an explicit value always wins, otherwise the
  /// name row is hidden in [AiMessageLayout.document] and shown in
  /// [AiMessageLayout.bubble].
  bool resolveShowUserName(AiMessageLayout layout) =>
      showUserName ?? (layout == AiMessageLayout.bubble);
}

/// Options for customizing the message list
class MessageListOptions {
  /// Custom scroll controller for the message list
  final ScrollController? scrollController;

  /// Custom scroll physics for the message list
  final ScrollPhysics? scrollPhysics;

  final ScrollViewKeyboardDismissBehavior? keyboardDismissBehavior;

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
    this.keyboardDismissBehavior,
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
    ScrollViewKeyboardDismissBehavior? keyboardDismissBehavior,
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
        keyboardDismissBehavior:
            keyboardDismissBehavior ?? this.keyboardDismissBehavior,
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

  /// Distance from the bottom of the MESSAGE LIST (not the whole chat
  /// surface, and not the viewport/screen bottom despite the field's name)
  /// this button floats over, to the button's 48x48 hit area. Default is 6,
  /// chosen so the painted 36px disc, centred within that hit area, lands
  /// ~12px above whatever sits directly below the list — the composer's own
  /// visible container (its rounded, bordered `ChatInput` box) when there
  /// are no quick replies, or the quick-replies row when there are — per
  /// `DESIGN.md` §8.10.
  final double bottomOffset;

  /// Distance from right of the screen (default is 16). Only applied when
  /// [position] is [ScrollToBottomPosition.end] — the package default
  /// ([ScrollToBottomPosition.center]) horizontally centers the button on
  /// the reading column instead (`DESIGN.md` §8.10).
  final double rightOffset;

  /// Whether to show text next to the icon (default is false)
  final bool showText;

  /// Custom text to display next to the icon (default is "Scroll to bottom")
  final String buttonText;

  /// Where the button sits relative to the reading column. Defaults to
  /// [ScrollToBottomPosition.center] (`DESIGN.md` §8.10): a floating button
  /// must never park over code in the bottom-right. Set to
  /// [ScrollToBottomPosition.end] to restore the legacy trailing-edge
  /// placement, which honors [rightOffset].
  final ScrollToBottomPosition position;

  const ScrollToBottomOptions({
    this.disabled = false,
    this.alwaysVisible = false,
    this.onScrollToBottomPress,
    this.scrollToBottomBuilder,
    this.bottomOffset = 6,
    this.rightOffset = 16,
    this.showText = false,
    this.buttonText = 'Scroll to bottom',
    this.position = ScrollToBottomPosition.center,
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
    ScrollToBottomPosition? position,
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
        position: position ?? this.position,
      );
}

/// Where a [ScrollToBottomOptions]-configured button sits relative to the
/// reading column (`DESIGN.md` §8.10).
enum ScrollToBottomPosition {
  /// Horizontally centered on the reading column, just above the composer.
  /// The package default.
  center,

  /// Pinned to the trailing edge of the column, honoring
  /// [ScrollToBottomOptions.rightOffset]. Legacy placement.
  end,
}
