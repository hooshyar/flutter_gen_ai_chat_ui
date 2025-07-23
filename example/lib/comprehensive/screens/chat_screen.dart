import 'dart:async';
import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';

import '../models/app_state.dart';
import '../services/ai_service.dart';
import '../widgets/settings_sheet.dart';

/// Main chat screen for the comprehensive example
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin {
  final _chatController = ChatMessagesController();
  final _aiService = AiService();
  final _currentUser = const ChatUser(id: 'user123', firstName: 'You');
  final _aiUser = const ChatUser(id: 'ai123', firstName: 'Insight AI');
  final _random = Random();
  bool _isLoading = false;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _chatController.dispose();
    super.dispose();
  }

  /// Handle when a user sends a message
  Future<void> _handleSendMessage(ChatMessage message) async {
    final appState = Provider.of<AppState>(context, listen: false);

    // Hide welcome message after first message
    if (_chatController.showWelcomeMessage) {
      _chatController.hideWelcomeMessage();
    }

    // User message is already added to chat by the UI

    setState(() {
      _isLoading = true;
    });

    try {
      // Generate a stable message ID
      final messageId =
          'ai_msg_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(10000)}';

      // Create an empty message that will be updated during streaming
      final aiMessage = ChatMessage(
        text: "",
        user: _aiUser,
        createdAt: DateTime.now(),
        isMarkdown: true,
        customProperties: {'id': messageId},
      );

      // Add the empty message to chat
      _chatController.addMessage(aiMessage);

      if (appState.isStreaming) {
        // Stream the response word by word
        final stream = _aiService.streamResponse(
          message.text,
          includeCodeBlock: appState.showCodeBlocks,
        );

        await for (final wordsSoFar in stream) {
          // Update the message with each new word - preserve the ID
          _chatController.updateMessage(
            aiMessage.copyWith(
              text: wordsSoFar,
              // Preserve the custom properties with the stable ID
              customProperties: {'id': messageId},
            ),
          );
        }
      } else {
        // Get the full response at once
        final response = await _aiService.generateResponse(
          message.text,
          includeCodeBlock: appState.showCodeBlocks,
        );

        // Update with complete response - preserve the ID
        _chatController.updateMessage(
          aiMessage.copyWith(
            text: response.text,
            isMarkdown: response.isMarkdown,
            customProperties: {'id': messageId},
          ),
        );
      }
    } catch (e) {
      // Handle errors
      _chatController.addMessage(
        ChatMessage(
          text:
              "I apologize, but I encountered an error processing your request. Please try again.",
          user: _aiUser,
          createdAt: DateTime.now(),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Clear all messages and show welcome message
  void _resetChat() {
    _chatController.clearMessages();
    _chatController.showWelcomeMessage = true;
  }

  /// Toggle welcome message visibility
  void _toggleWelcomeMessage() {
    _chatController.showWelcomeMessage = !_chatController.showWelcomeMessage;
  }

  /// Open settings bottom sheet
  void _openSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SettingsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Markdown style for messages
    final markdownStyleSheet = MarkdownStyleSheet(
      h1: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurface,
      ),
      h2: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurface,
      ),
      h3: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurface,
      ),
      p: TextStyle(
        fontSize: appState.fontSize,
        height: 1.5,
        color: theme.colorScheme.onSurface,
      ),
      listBullet: TextStyle(
        color: theme.colorScheme.primary,
      ),
      blockquoteDecoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
        border: Border(
          left: BorderSide(
            color: theme.colorScheme.primary,
            width: 4,
          ),
        ),
      ),
      blockquotePadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      code: TextStyle(
        fontFamily: 'monospace',
        backgroundColor: isDark
            ? Colors.black.withOpacityCompat(0.3)
            : Colors.grey.withOpacityCompat(0.2),
      ),
      codeblockDecoration: BoxDecoration(
        color: isDark ? Colors.black26 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      codeblockPadding: const EdgeInsets.all(12),
    );

    // Message styles
    final messageOptions = MessageOptions(
      showTime: true,
      showUserName: true,
      bubbleStyle: BubbleStyle(
        userBubbleColor: theme.colorScheme.primary.withOpacityCompat(0.15),
        aiBubbleColor: isDark
            ? theme.colorScheme.surfaceContainerHighest
            : theme.cardColor,
        userNameColor: theme.colorScheme.primary,
        aiNameColor: theme.colorScheme.tertiary,
        userBubbleTopLeftRadius: appState.messageBorderRadius,
        userBubbleTopRightRadius: 4,
        aiBubbleTopLeftRadius: 4,
        aiBubbleTopRightRadius: appState.messageBorderRadius,
        bottomLeftRadius: appState.messageBorderRadius,
        bottomRightRadius: appState.messageBorderRadius,
        enableShadow: true,
        shadowOpacity: isDark ? 0.2 : 0.1,
        shadowBlurRadius: 10,
        shadowOffset: const Offset(0, 2),
      ),
      textStyle: TextStyle(
        fontSize: appState.fontSize,
        height: 1.4,
        color: theme.colorScheme.onSurface,
      ),
    );

    // Input styling
    final inputOptions = InputOptions(
      decoration: InputDecoration(
        hintText: 'Message Insight AI...',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: isDark
            ? theme.colorScheme.surfaceContainerHighest
            : theme.cardColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 14,
        ),
      ),
      sendButtonBuilder: (onPressed) => Container(
        height: 42,
        width: 42,
        margin: const EdgeInsets.only(left: 8),
        child: Material(
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(21),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(21),
            child: const Icon(
              Icons.send_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
      unfocusOnTapOutside: false,
      textInputAction: TextInputAction.newline,
      inputContainerHeight: 64,
      sendButtonPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
    );

    // Welcome message configuration
    final welcomeMessageConfig = WelcomeMessageConfig(
      title: 'Welcome to ${appState.aiName}',
      titleStyle: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurface,
        letterSpacing: -0.5,
      ),
      containerDecoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacityCompat(isDark ? 0.3 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color:
              theme.colorScheme.primary.withOpacityCompat(isDark ? 0.2 : 0.1),
          width: 1.5,
        ),
      ),
      questionsSectionTitle: 'Try asking me something:',
      questionsSectionTitleStyle: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurface,
      ),
    );

    // Example questions
    final exampleQuestions = [
      const ExampleQuestion(
        question: 'What can you help me with?',
        config: ExampleQuestionConfig(
          iconData: Icons.help_outline,
          containerPadding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
      const ExampleQuestion(
        question: 'Show me a Flutter code example',
        config: ExampleQuestionConfig(
          iconData: Icons.code,
        ),
      ),
      const ExampleQuestion(
        question: 'Tell me about yourself',
        config: ExampleQuestionConfig(
          iconData: Icons.info_outline,
        ),
      ),
      const ExampleQuestion(
        question: 'What features does this chat UI have?',
        config: ExampleQuestionConfig(
          iconData: Icons.chat_bubble_outline,
        ),
      ),
    ];

    return FadeTransition(
      opacity: _fadeController,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_awesome,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(appState.aiName),
            ],
          ),
          centerTitle: true,
          actions: [
            // Reset chat button
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Reset Chat',
              onPressed: _resetChat,
            ),
            // Welcome message toggle
            IconButton(
              icon: const Icon(Icons.message_outlined),
              tooltip: 'Toggle Welcome Message',
              onPressed: _toggleWelcomeMessage,
            ),
            // Settings button
            IconButton(
              icon: const Icon(Icons.settings),
              tooltip: 'Settings',
              onPressed: _openSettings,
            ),
          ],
        ),
        body: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 5,
              sigmaY: 5,
            ),
            child: AiChatWidget(
              // Required parameters
              currentUser: _currentUser,
              aiUser: _aiUser,
              controller: _chatController,
              onSendMessage: _handleSendMessage,

              // Core configuration
              aiName: appState.aiName,
              maxWidth: appState.chatMaxWidth,
              enableAnimation: appState.enableAnimation,
              enableMarkdownStreaming:
                  appState.isStreaming && appState.enableAnimation,
              streamingDuration: const Duration(milliseconds: 25),
              markdownStyleSheet: markdownStyleSheet,

              // Messaging configuration
              messageOptions: messageOptions,
              inputOptions: inputOptions,

              // Loading configuration
              loadingConfig: LoadingConfig(
                isLoading: _isLoading,
                typingIndicatorColor: theme.colorScheme.primary,
                typingIndicatorSize: 8,
              ),

              // Welcome message and example questions
              welcomeMessageConfig: welcomeMessageConfig,
              exampleQuestions: exampleQuestions,
              persistentExampleQuestions: appState.persistentExampleQuestions,
            ),
          ),
        ),
      ),
    );
  }
}
