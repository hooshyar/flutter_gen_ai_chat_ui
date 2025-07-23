import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';
import 'package:provider/provider.dart';
import 'dart:math';

import '../models/app_state.dart';
import '../services/mock_ai_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  static void clearMessages(BuildContext context) {
    final state = context.findAncestorStateOfType<_ChatScreenState>();
    state?._chatController.clearMessages();
  }

  static void toggleWelcomeMessage(BuildContext context) {
    final state = context.findAncestorStateOfType<_ChatScreenState>();
    state?._toggleWelcomeMessage();
  }

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin {
  final _chatController = ChatMessagesController();
  final _mockAiService = MockAiService();
  final _currentUser = const ChatUser(id: 'user123', firstName: 'You');
  final _aiUser = const ChatUser(id: 'ai123', firstName: 'Dila');
  final _random = Random();
  bool _isLoading = false;
  bool _welcomeMessageVisible = true;
  late AnimationController _fadeController;
  final _inputController = TextEditingController();

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
    _inputController.dispose();
    super.dispose();
  }

  /// Handle sending a message to the AI
  Future<void> _handleSendMessage(ChatMessage message) async {
    // Hide welcome message after first message
    if (_chatController.showWelcomeMessage) {
      _chatController.hideWelcomeMessage();
      setState(() {
        _welcomeMessageVisible = false;
      });
    }

    // Add the user's message to the chat controller
    _chatController.addMessage(message);

    setState(() {
      _isLoading = true;
    });

    final appState = Provider.of<AppState>(context, listen: false);

    try {
      // Generate a stable message ID that won't change during streaming
      final messageId =
          'ai_msg_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(10000)}';

      // First delay to show the loading indicator
      await Future.delayed(const Duration(milliseconds: 1000));

      setState(() {
        _isLoading = false;
      });

      // Create a new AI message with empty text (we'll stream it)
      final aiMessage = ChatMessage(
        text: "",
        user: _aiUser,
        createdAt: DateTime.now(),
        isMarkdown: true,
        customProperties: {'isStreaming': true, 'id': messageId},
      );

      // Add the empty message to chat
      _chatController.addMessage(aiMessage);

      if (appState.isStreaming) {
        try {
          // Stream the response word by word
          final stream = _mockAiService.streamResponse(
            message.text,
            includeCodeBlock: appState.showCodeBlocks,
          );

          String accumulatedText = "";
          await for (final wordsSoFar in stream) {
            // Sometimes stream events can be empty or null - skip those
            if (wordsSoFar.isEmpty) continue;

            accumulatedText = wordsSoFar;

            // Update the message with each new word - preserve the ID and streaming flag
            _chatController.updateMessage(
              ChatMessage(
                text: accumulatedText,
                user: _aiUser,
                createdAt: aiMessage.createdAt,
                isMarkdown: true,
                // Preserve the custom properties with the stable ID
                customProperties: {'isStreaming': true, 'id': messageId},
              ),
            );

            // Small delay for visual effect if needed
            // await Future.delayed(const Duration(milliseconds: 10));
          }

          // Mark streaming as complete
          _chatController.updateMessage(
            ChatMessage(
              text: accumulatedText,
              user: _aiUser,
              createdAt: aiMessage.createdAt,
              isMarkdown: true,
              customProperties: {'isStreaming': false, 'id': messageId},
            ),
          );
        } catch (streamingError) {
          debugPrint('Error during streaming: $streamingError');
          // Update message to show error state
          _chatController.updateMessage(
            ChatMessage(
              text:
                  "Sorry, there was an error generating the streaming response.",
              user: _aiUser,
              createdAt: aiMessage.createdAt,
              isMarkdown: true,
              customProperties: {'isStreaming': false, 'id': messageId},
            ),
          );
        }
      } else {
        // Non-streaming mode - get the full response at once
        final response = await _mockAiService.getResponse(
          message.text,
          includeCodeBlock: appState.showCodeBlocks,
        );

        // Small delay to simulate processing time
        await Future.delayed(const Duration(milliseconds: 300));

        // Update with complete response
        _chatController.updateMessage(
          ChatMessage(
            text: response,
            user: _aiUser,
            createdAt: aiMessage.createdAt,
            isMarkdown: true,
            customProperties: {'id': messageId}, // No streaming flag needed
          ),
        );
      }
    } catch (e) {
      debugPrint('Error handling message: $e');
      setState(() {
        _isLoading = false;
      });

      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDarkMode = appState.themeMode == ThemeMode.dark;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return FadeTransition(
      opacity: _fadeController,
      child: Scaffold(
        body: Stack(
          children: [
            // Main chat widget
            AiChatWidget(
              // Required parameters
              currentUser: _currentUser,
              aiUser: _aiUser,
              controller: _chatController,
              onSendMessage: _handleSendMessage,
              // Loading state - only for typing indicator
              loadingConfig: LoadingConfig(
                isLoading: _isLoading,
                typingIndicatorColor: colorScheme.primary,
                typingIndicatorSize: 10.0,
                showCenteredIndicator: false,
                loadingIndicator: const LoadingWidget(
                  texts: [
                    'AI is thinking...',
                    'Generating response...',
                    'Almost there...'
                  ],
                  shimmerBaseColor: Colors.red,
                  shimmerHighlightColor: Colors.blue,
                ),
              ),

              // UI customization
              maxWidth: 900,
              padding: const EdgeInsets.all(16),

              // Input field customization
              inputOptions: _buildInputOptions(theme, isDarkMode),

              // Message styling
              messageOptions: MessageOptions(
                showTime: true,
                showUserName: true,
                bubbleStyle: BubbleStyle(
                  userBubbleColor: colorScheme.primary.withOpacityCompat(0.12),
                  aiBubbleColor:
                      isDarkMode ? colorScheme.surface : Colors.white,
                  userNameColor: colorScheme.primary,
                  aiNameColor: colorScheme.tertiary,
                  userBubbleTopLeftRadius: 18,
                  userBubbleTopRightRadius: 8,
                  aiBubbleTopLeftRadius: 8,
                  aiBubbleTopRightRadius: 18,
                  bottomLeftRadius: 18,
                  bottomRightRadius: 18,
                  enableShadow: true,
                  shadowOpacity: isDarkMode ? 0.2 : 0.1,
                  shadowBlurRadius: 12,
                  shadowOffset: const Offset(0, 2),
                ),
                textStyle: TextStyle(
                  fontSize: 15,
                  height: 1.4,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),

              // Message list styling
              messageListOptions: const MessageListOptions(
                scrollPhysics: AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
              ),

              // AI-specific features
              enableMarkdownStreaming: true,
              streamingDuration: const Duration(milliseconds: 30),
              exampleQuestions: const [
                ExampleQuestion(
                  question: 'What can you help me with?',
                  config: ExampleQuestionConfig(
                    iconData: Icons.help_outline,
                    containerPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
                ExampleQuestion(
                  question: 'Tell me about Flutter',
                  config: ExampleQuestionConfig(
                    iconData: Icons.flutter_dash,
                  ),
                ),
                ExampleQuestion(
                  question: 'Show me a code example',
                  config: ExampleQuestionConfig(
                    iconData: Icons.code,
                  ),
                ),
                ExampleQuestion(
                  question: 'What are some AI use cases?',
                  config: ExampleQuestionConfig(
                    iconData: Icons.smart_toy_outlined,
                  ),
                ),
              ],
              welcomeMessageConfig: WelcomeMessageConfig(
                title: 'Welcome to Dila Assistant',
                questionsSectionTitle: 'Try asking one of these questions:',
                containerMargin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                containerPadding: const EdgeInsets.all(24),
                titleStyle: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                  height: 1.2,
                ),
                containerDecoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF1E2026) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withOpacityCompat(isDarkMode ? 0.3 : 0.1),
                      blurRadius: 20,
                      spreadRadius: -4,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  border: Border.all(
                    color: colorScheme.primary
                        .withOpacityCompat(isDarkMode ? 0.2 : 0.15),
                    width: 1.5,
                  ),
                ),
              ),
              persistentExampleQuestions: false,
              enableAnimation: appState.enableAnimation,
            ),
          ],
        ),
      ),
    );
  }

  // Extract input options to a separate method for clarity
  InputOptions _buildInputOptions(ThemeData theme, bool isDarkMode) {
    // Create a more transparent background for the input field to blend with scaffold
    final textFieldBg = isDarkMode
        ? theme.colorScheme.surface.withOpacityCompat(0.7)
        : Colors.white.withOpacityCompat(0.7);

    return InputOptions(
      // Use our controller
      textController: _inputController,
      decoration: InputDecoration(
        hintText: 'Ask me anything...',
        hintStyle:
            TextStyle(color: isDarkMode ? Colors.white60 : Colors.black45),
        // Keep just enough styling to see the input field
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: textFieldBg,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
      textStyle: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
      sendButtonColor: theme.colorScheme.primary,

      // Better send button padding for alignment
      sendButtonPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      sendButtonIconSize: 24.0,

      // Remove all containers completely
      useOuterContainer: false,
      useOuterMaterial: false,
      useScaffoldBackground: false,

      // Configure keyboard to show Send button
      textInputAction: TextInputAction.send,

      // Handle keyboard Send button press
      onSubmitted: (_) => _handleKeyboardSend(),

      // Keep essential properties
      unfocusOnTapOutside: false,

      // Add bottom padding to position input properly without container
      positionedBottom: 16,
    );
  }

  // Handle sending message from keyboard action
  void _handleKeyboardSend() {
    if (_inputController.text.trim().isNotEmpty) {
      // Create the message
      final message = ChatMessage(
        text: _inputController.text,
        user: _currentUser,
        createdAt: DateTime.now(),
      );

      // Send the message
      _handleSendMessage(message);

      // Clear the input field
      _inputController.clear();

      // Hide keyboard
      FocusScope.of(context).unfocus();
    }
  }

  // Method to toggle welcome message visibility
  void _toggleWelcomeMessage() {
    setState(() {
      _welcomeMessageVisible = !_welcomeMessageVisible;

      if (_welcomeMessageVisible) {
        // Save current messages
        final currentMessages =
            List<ChatMessage>.from(_chatController.messages);

        // Clear messages (which resets welcome message state internally)
        _chatController.clearMessages();

        // Add back the saved messages
        for (final msg in currentMessages) {
          _chatController.addMessage(msg);
        }

        // Show welcome message
        _chatController.showWelcomeMessage = true;
      } else {
        // Hide welcome message
        _chatController.hideWelcomeMessage();
      }
    });
  }
}
