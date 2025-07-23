import 'package:flutter/material.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';
import 'package:provider/provider.dart';

import '../../models/app_state.dart';
import '../../services/ai_service.dart';

/// A basic example showing the minimal implementation of Flutter Gen AI Chat UI.
/// This example demonstrates essential features with clean, well-documented code.
class BasicChatScreen extends StatefulWidget {
  const BasicChatScreen({super.key});

  @override
  State<BasicChatScreen> createState() => _BasicChatScreenState();
}

class _BasicChatScreenState extends State<BasicChatScreen> {
  // Create a controller to manage chat messages
  final _chatController = ChatMessagesController();

  // Mock AI service
  final _aiService = AiService();

  // Define users for the chat
  final _currentUser = const ChatUser(id: 'user123', firstName: 'You');
  final _aiUser = const ChatUser(id: 'ai123', firstName: 'AI Assistant');

  // Track loading state
  bool _isLoading = false;

  // Example questions for the welcome message
  final _exampleQuestions = [
    const ExampleQuestion(question: "What can you help me with?"),
    const ExampleQuestion(question: "Tell me about Flutter"),
    const ExampleQuestion(question: "How does this UI work?"),
    const ExampleQuestion(question: "Show me some examples"),
  ];

  @override
  void initState() {
    super.initState();

    // Instead of adding a welcome message directly to the chat,
    // we'll use the welcome message feature with example questions
    // The controller's showWelcomeMessage property controls this
    _chatController.showWelcomeMessage = true;

    // No initial messages added to chat
  }

  @override
  void dispose() {
    // Dispose the controller to avoid memory leaks
    _chatController.dispose();
    super.dispose();
  }

  /// Handle sending a user message and generating a response
  Future<void> _handleSendMessage(ChatMessage message) async {
    // Hide welcome message if it's currently shown
    if (_chatController.showWelcomeMessage) {
      _chatController.hideWelcomeMessage();
    }

    // Add the user's message to the chat
    _chatController.addMessage(message);

    // Set loading state to show typing indicator
    setState(() => _isLoading = true);

    try {
      // Simulate API call to generate response
      final response = await _aiService.generateResponse(message.text,
          includeCodeBlock: false);

      // Add the AI response to the chat
      _chatController.addMessage(
        ChatMessage(
          text: response.text,
          user: _aiUser,
          createdAt: DateTime.now(),
          isMarkdown: response.isMarkdown,
        ),
      );
    } finally {
      // Reset loading state
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get app state for theme and settings
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Basic Chat Example'),
        actions: [
          // Theme toggle button
          IconButton(
            icon: Icon(
              appState.themeMode == ThemeMode.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: appState.toggleTheme,
            tooltip: 'Toggle theme',
          ),
          // Reset conversation button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Clear all messages
              _chatController.clearMessages();
              // Show the welcome message again
              _chatController.showWelcomeMessage = true;
            },
            tooltip: 'Reset conversation',
          ),
        ],
      ),
      body: AiChatWidget(
        // Required parameters
        currentUser: _currentUser,
        aiUser: _aiUser,
        controller: _chatController,
        onSendMessage: _handleSendMessage,

        // Loading state
        loadingConfig: LoadingConfig(
          isLoading: _isLoading,
          loadingIndicator: const LoadingWidget(
            texts: [
              'Generating response...',
              'Thinking...',
              'Loading...',
              'Please wait...',
              'Loading...',
            ],
            shimmerBaseColor: Colors.grey,
            shimmerHighlightColor: Colors.black38,
          ),
        ),

        // Welcome message configuration
        welcomeMessageConfig: WelcomeMessageConfig(
          title: "Welcome to the AI Chat",
          titleStyle: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
          questionsSectionTitle: "Try asking these questions:",
          questionsSectionTitleStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.secondary,
          ),
          containerPadding: const EdgeInsets.all(24),
          questionsSectionPadding: const EdgeInsets.all(16),
          containerDecoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacityCompat(0.1),
                blurRadius: 10,
                spreadRadius: -5,
              ),
            ],
            border: Border.all(
              color:
                  Theme.of(context).colorScheme.primary.withOpacityCompat(0.2),
              width: 1.5,
            ),
          ),
        ),

        // Example questions to display in the welcome message with enhanced styling
        exampleQuestions: _exampleQuestions
            .map((q) => ExampleQuestion(
                  question: q.question,
                  config: ExampleQuestionConfig(
                    iconData: Icons.chat_bubble_outline_rounded,
                    textStyle: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    containerPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    iconColor: Theme.of(context).colorScheme.primary,
                  ),
                ))
            .toList(),

        // Input configuration
        inputOptions: InputOptions(
          containerPadding: const EdgeInsets.all(16),
          materialPadding: const EdgeInsets.all(16),
          minLines: 1,
          maxLines: 4,
          positionedBottom: 10,
          positionedLeft: 10,
          positionedRight: 10,
          unfocusOnTapOutside: false,
          sendOnEnter: true,
          textInputAction: TextInputAction.send,
          textController: _buildTextControllerWithEnterHandler(),
          decoration: const InputDecoration(
            hintText: 'Type a message...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(24)),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            filled: true,
          ),
        ),

        // Message styling
        messageOptions: MessageOptions(
          showUserName: true,
          bubbleStyle: BubbleStyle(
            userBubbleColor: Theme.of(context).colorScheme.primaryContainer,
            aiBubbleColor:
                Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
        ),

        // Enable animations based on app state
        enableAnimation: appState.enableAnimation,
      ),
    );
  }

  TextEditingController _buildTextControllerWithEnterHandler() {
    final controller = TextEditingController();
    controller.addListener(() {
      if (controller.text.endsWith('\n')) {
        controller.text = controller.text.trim();
        if (controller.text.isNotEmpty) {
          _handleSendMessage(ChatMessage(
            text: controller.text,
            user: _currentUser,
            createdAt: DateTime.now(),
          ));
          controller.clear();
        }
      }
    });
    return controller;
  }
}
