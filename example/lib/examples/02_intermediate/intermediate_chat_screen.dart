import 'package:flutter/material.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';
import 'package:provider/provider.dart';

import '../../models/app_state.dart';
import '../../services/ai_service.dart';

/// Intermediate example of Flutter Gen AI Chat UI demonstrating streaming text responses
/// and additional customization options.
class IntermediateChatScreen extends StatefulWidget {
  const IntermediateChatScreen({super.key});

  @override
  State<IntermediateChatScreen> createState() => _IntermediateChatScreenState();
}

class _IntermediateChatScreenState extends State<IntermediateChatScreen> {
  // Chat controller to manage messages
  final _chatController = ChatMessagesController();

  // Service to generate AI responses (removed unused field)
  // final _aiService = AiService();

  // User definitions
  final _currentUser = const ChatUser(id: 'user123', firstName: 'You');
  final _aiUser = const ChatUser(
    id: 'ai123',
    firstName: 'AI Assistant',
    avatar: 'https://ui-avatars.com/api/?name=AI&background=6366f1&color=fff',
  );

  // Streaming state management
  bool _isGenerating = false;
  String _currentText = '';
  bool _useStreaming = true;

  // Example questions
  final _exampleQuestions = [
    const ExampleQuestion(question: "What can you help me with?"),
    const ExampleQuestion(question: "Show me a code example"),
    const ExampleQuestion(question: "How does streaming text work?"),
    const ExampleQuestion(question: "Tell me about markdown support"),
  ];

  @override
  void initState() {
    super.initState();

    // Add welcome message
    _chatController.addMessage(
      ChatMessage(
        text: '# Welcome to the Intermediate Example! 👋\n\n'
            'This example demonstrates more advanced features:\n\n'
            '- **Markdown formatting** with rich text\n'
            '- **Streaming responses** with typing animation\n'
            '- **File uploads** for images and documents\n\n'
            'Try sending a message or uploading a file!',
        user: _aiUser,
        createdAt: DateTime.now(),
        isMarkdown: true,
      ),
    );
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  /// Handle uploading files - this is just a UI demo
  void _handleFileUpload(List<Object> files) {
    // For demonstration, we'll simulate a file upload with a mock response
    // In a real app, you would process the files and upload them to your backend

    // Show demo file message from the user
    final message = ChatMessage(
      text: 'I\'ve attached a file for you.',
      user: _currentUser,
      createdAt: DateTime.now(),
      // Add a mock file attachment
      media: [
        ChatMedia(
          url: 'https://www.example.com/document.pdf',
          type: ChatMediaType.document,
          fileName: 'document.pdf',
          size: 1024 * 1024 * 2, // 2MB
          extension: 'pdf',
        ),
      ],
    );

    _chatController.addMessage(message);

    // Simulate AI response about the file
    setState(() => _isGenerating = true);

    Future.delayed(const Duration(seconds: 1), () {
      final aiResponse = ChatMessage(
        text:
            'I\'ve received your PDF file. It appears to be 2MB in size. Would you like me to analyze it for you?',
        user: _aiUser,
        createdAt: DateTime.now(),
        // Add a reference to the same file
        media: [
          ChatMedia(
            url: 'https://www.example.com/document.pdf',
            type: ChatMediaType.document,
            fileName: 'document.pdf',
            size: 1024 * 1024 * 2, // 2MB
            extension: 'pdf',
          ),
        ],
      );

      _chatController.addMessage(aiResponse);
      setState(() => _isGenerating = false);
    });
  }

  /// Handle sending a message and generating a streaming response
  Future<void> _handleSendMessage(ChatMessage message) async {
    // Reset streaming state
    setState(() {
      _currentText = '';
      _isGenerating = true;
    });

    // Simulate AI processing time
    await Future.delayed(const Duration(milliseconds: 300));

    if (_useStreaming) {
      // Create an empty message to update incrementally
      final aiMessage = ChatMessage(
        text: '',
        user: _aiUser,
        createdAt: DateTime.now(),
        isMarkdown: true,
      );

      // Add the empty message to the chat
      _chatController.addMessage(aiMessage);

      // Generate a response word by word
      final words = _generateResponse(message.text).split(' ');
      String accumulatedText = '';

      for (var i = 0; i < words.length; i++) {
        // Simulate typing latency
        await Future.delayed(const Duration(milliseconds: 50));

        // Append the next word
        accumulatedText = accumulatedText + (i > 0 ? ' ' : '') + words[i];

        // Update state and message
        setState(() => _currentText = accumulatedText);

        _chatController.updateMessage(
          aiMessage.copyWith(text: accumulatedText),
        );
      }
    } else {
      // Just add the complete response
      final response = _generateResponse(message.text);

      _chatController.addMessage(
        ChatMessage(
          text: response,
          user: _aiUser,
          createdAt: DateTime.now(),
          isMarkdown: true,
        ),
      );
    }

    setState(() => _isGenerating = false);
  }

  // Generate a markdown response based on the user's input
  String _generateResponse(String input) {
    // Simple response generation for demonstration
    var lowercaseInput = input.toLowerCase();
    if (lowercaseInput.contains('hello') ||
        lowercaseInput.contains('hi') ||
        lowercaseInput.contains('hey')) {
      return "# Hello there! 👋\n\nGreat to meet you. I'm an AI assistant ready to help with:\n\n- Answering questions\n- Generating content\n- Providing information\n\nWhat can I help you with today?";
    } else if (lowercaseInput.contains('markdown')) {
      return "# Markdown Support\n\nThis chat UI supports rich markdown formatting, including:\n\n## Headings\n\n### And sub-headings\n\n**Bold text** and *italic text*\n\n- Bullet points\n- In a list\n\n1. Numbered lists\n2. Are also supported\n\n```dart\n// Code blocks with syntax highlighting\nvoid main() {\n  print('Hello, World!');\n}\n```\n\n> Blockquotes for important information\n\nTry it yourself!";
    } else if (lowercaseInput.contains('streaming') ||
        lowercaseInput.contains('typing')) {
      return "# Streaming Text\n\nThe chat UI supports streaming responses word by word, creating a realistic typing effect. This is done by:\n\n1. Creating an empty message\n2. Continuously updating it with new words\n3. Using the `updateMessage` method\n\nThis creates a natural conversational feel and lets users start reading responses as they're being generated.";
    } else if (lowercaseInput.contains('upload') ||
        lowercaseInput.contains('file') ||
        lowercaseInput.contains('image') ||
        lowercaseInput.contains('document')) {
      return "# File Upload Support\n\nThis chat UI supports file attachments like:\n\n- Images (PNG, JPEG, GIF)\n- Documents (PDF, DOC, XLS)\n- Audio files\n- Video files\n\nThe UI provides default display components for each file type, with customization options for:\n\n- Custom file previews\n- File size limits\n- Allowed file types\n- Custom upload buttons\n\nThe actual file processing is handled by your app code.";
    } else {
      return "Thanks for your message! This is a demonstration of markdown formatting in the chat UI.\n\n```dart\n// Here's some example code\nclass Example {\n  final String name;\n  \n  Example(this.name);\n  \n  void greet() {\n    print('Hello, \$name!');\n  }\n}\n```\n\nYou can customize the appearance of these messages using the `MessageOptions` class.";
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Intermediate Example'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Theme toggle
          IconButton(
            icon: Icon(
              appState.themeMode == ThemeMode.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: appState.toggleTheme,
            tooltip: 'Toggle theme',
          ),
          // Streaming toggle
          IconButton(
            icon: Icon(
              appState.isStreaming ? Icons.autorenew : Icons.text_fields,
            ),
            onPressed: appState.toggleStreaming,
            tooltip: 'Toggle streaming',
          ),
          // Reset conversation
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _chatController.clearMessages();
              // Re-add welcome message
              _chatController.addMessage(
                ChatMessage(
                  text: '# Welcome to the Intermediate Example! 👋\n\n'
                      'This example demonstrates more advanced features:\n\n'
                      '- **Markdown formatting** with rich text\n'
                      '- **Streaming responses** with typing animation\n'
                      '- **File uploads** for images and documents\n\n'
                      'Try sending a message or uploading a file!',
                  user: _aiUser,
                  createdAt: DateTime.now(),
                  isMarkdown: true,
                ),
              );
            },
            tooltip: 'Reset conversation',
          ),
          // Toggle for streaming mode
          Row(
            children: [
              const Text('Stream'),
              Switch(
                value: _useStreaming,
                onChanged: (value) {
                  setState(() => _useStreaming = value);
                },
              ),
            ],
          ),
        ],
      ),
      body: AiChatWidget(
        // Required parameters
        currentUser: _currentUser,
        aiUser: _aiUser,
        controller: _chatController,
        onSendMessage: _handleSendMessage,

        // Max width constraint from app state
        maxWidth: appState.chatMaxWidth,

        // Loading configuration
        loadingConfig: LoadingConfig(
          isLoading: _isGenerating,
          loadingIndicator:
              _isGenerating ? _buildCustomLoadingIndicator(colorScheme) : null,
        ),

        // Enable streaming markdown rendering
        enableMarkdownStreaming: appState.isStreaming,
        streamingDuration: const Duration(milliseconds: 10),

        // Welcome message config
        welcomeMessageConfig: WelcomeMessageConfig(
          title: "Interactive AI Chat Example",
          questionsSectionTitle: "Try asking:",
          containerDecoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.primaryContainer,
                colorScheme.primary.withOpacityCompat(0.1 * 255),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.primary.withOpacityCompat(0.3 * 255),
              width: 1.5,
            ),
          ),
        ),

        // Example questions
        exampleQuestions: _exampleQuestions,
        persistentExampleQuestions: appState.persistentExampleQuestions,

        // Input customization
        inputOptions: InputOptions(
          unfocusOnTapOutside: false,
          margin: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
          sendOnEnter: true,
          sendButtonPadding: const EdgeInsets.only(right: 8),
          sendButtonIconSize: 24,
          decoration: InputDecoration(
            hintText: 'Ask anything...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest
                .withOpacityCompat(0.8 * 255),

            // suffixIcon: const Icon(Icons.send_rounded),
          ),
        ),

        // Message customization
        messageOptions: MessageOptions(
          showUserName: true,
          showTime: true,
          timeFormat: (dateTime) => '${dateTime.hour}:${dateTime.minute}',
          bubbleStyle: BubbleStyle(
            userBubbleColor: colorScheme.primaryContainer,
            aiBubbleColor: colorScheme.surfaceContainerHighest,
          ),
        ),

        // Animation settings
        enableAnimation: appState.enableAnimation,

        // Add file upload support
        fileUploadOptions: FileUploadOptions(
          enabled: true,
          uploadIconColor: Theme.of(context).colorScheme.primary,
          onFilesSelected: _handleFileUpload,
          uploadTooltip: 'Upload files',
        ),
      ),
    );
  }

  /// Custom typing indicator with blinking dots
  Widget _buildCustomLoadingIndicator(ColorScheme colorScheme) {
    return LoadingWidget(
      texts: [
        "Generating response...",
        "Thinking...",
        "Loading...",
        "Please wait...",
        "Loading data...",
        "Processing...",
        "Please wait...",
      ],
      shimmerBaseColor: colorScheme.primary,
      shimmerHighlightColor: colorScheme.primaryContainer,
    );
  }

  /// Blinking animation for typing indicator dots
  Widget _buildBlinkingDot({required Duration duration}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.4, end: 1.0),
      duration: duration,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: child,
        );
      },
      child: Container(),
      onEnd: () {
        setState(() {}); // Trigger rebuild to restart animation
      },
    );
  }
}
