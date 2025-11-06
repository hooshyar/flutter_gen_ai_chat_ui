import 'package:flutter/material.dart';
import '../../controllers/chat_messages_controller.dart';
import '../../models/chat/models.dart';
import '../../models/example_question.dart';
import '../../widgets/ai_chat_widget.dart';
import 'openai_config.dart';
import 'openai_provider.dart';

/// Pre-configured chat widget for OpenAI integration.
///
/// This widget provides a complete chat interface with built-in OpenAI integration.
/// It handles message streaming, error handling, and conversation management automatically.
///
/// ⚠️ **SECURITY WARNING**: Never hardcode your API key!
///
/// ✅ Use environment variables:
/// ```dart
/// OpenAIChatWidget(
///   apiKey: const String.fromEnvironment('OPENAI_API_KEY'),
///   currentUser: ChatUser(id: 'user', firstName: 'You'),
/// )
/// ```
///
/// ✅ Or fetch from secure backend:
/// ```dart
/// final apiKey = await yourBackend.getSecureToken();
/// OpenAIChatWidget(
///   apiKey: apiKey,
///   currentUser: user,
/// )
/// ```
///
/// Example with configuration:
/// ```dart
/// OpenAIChatWidget(
///   apiKey: const String.fromEnvironment('OPENAI_API_KEY'),
///   model: 'gpt-4-turbo',
///   currentUser: ChatUser(id: 'user', firstName: 'You'),
///   systemPrompt: 'You are a helpful Flutter development assistant.',
///   temperature: 0.7,
///   showTokenUsage: true,
///   onTokensUsed: (tokens, cost) {
///     print('Used $tokens tokens, estimated cost: \$${cost.toStringAsFixed(4)}');
///   },
///   welcomeMessage: 'Ask me anything about Flutter!',
///   exampleQuestions: [
///     ExampleQuestion(question: 'How do I use State Management?'),
///     ExampleQuestion(question: 'Explain Flutter widgets'),
///   ],
/// )
/// ```
class OpenAIChatWidget extends StatefulWidget {
  /// OpenAI API key.
  ///
  /// ⚠️ NEVER hardcode this! Use environment variables or secure backend.
  final String apiKey;

  /// OpenAI model to use.
  ///
  /// Popular options:
  /// - 'gpt-4-turbo': Latest GPT-4 Turbo with 128K context
  /// - 'gpt-4': Standard GPT-4 with 8K context
  /// - 'gpt-3.5-turbo': Fast and cost-effective (default)
  final String model;

  /// The current user sending messages.
  final ChatUser currentUser;

  /// The AI user (optional, defaults to 'AI Assistant').
  final ChatUser? aiUser;

  /// System prompt to control AI behavior.
  ///
  /// Example: 'You are a helpful assistant specialized in Flutter development.'
  final String? systemPrompt;

  /// Temperature controls randomness (0.0 to 2.0).
  ///
  /// - 0.0: Deterministic, focused responses
  /// - 1.0: Balanced (default)
  /// - 2.0: Maximum creativity
  final double temperature;

  /// Maximum tokens in AI response.
  final int? maxTokens;

  /// OpenAI organization ID (optional).
  final String? organization;

  /// Whether to print token usage to console.
  final bool showTokenUsage;

  /// Callback when tokens are used.
  ///
  /// Receives: (tokens, estimatedCost)
  final void Function(int tokens, double estimatedCost)? onTokensUsed;

  /// Welcome message shown at start.
  final String? welcomeMessage;

  /// Example questions shown to user.
  final List<ExampleQuestion>? exampleQuestions;

  /// Callback when an error occurs.
  final void Function(Object error)? onError;

  /// Maximum width of the chat interface.
  final double? maxWidth;

  /// Custom chat controller (optional).
  ///
  /// If not provided, a controller is created automatically.
  final ChatMessagesController? controller;

  /// Creates an OpenAI chat widget.
  const OpenAIChatWidget({
    super.key,
    required this.apiKey,
    required this.currentUser,
    this.model = 'gpt-3.5-turbo',
    this.aiUser,
    this.systemPrompt,
    this.temperature = 1.0,
    this.maxTokens,
    this.organization,
    this.showTokenUsage = false,
    this.onTokensUsed,
    this.welcomeMessage,
    this.exampleQuestions,
    this.onError,
    this.maxWidth,
    this.controller,
  });

  @override
  State<OpenAIChatWidget> createState() => _OpenAIChatWidgetState();
}

class _OpenAIChatWidgetState extends State<OpenAIChatWidget> {
  late final ChatMessagesController _controller;
  late final OpenAIProvider _provider;
  late final ChatUser _aiUser;

  bool _isWaitingForResponse = false;

  @override
  void initState() {
    super.initState();

    // Initialize controller
    _controller = widget.controller ?? ChatMessagesController();

    // Initialize AI user
    _aiUser = widget.aiUser ??
        const ChatUser(
          id: 'ai',
          firstName: 'AI Assistant',
        );

    // Initialize OpenAI provider
    _provider = OpenAIProvider(
      config: OpenAIConfig(
        apiKey: widget.apiKey,
        model: widget.model,
        systemPrompt: widget.systemPrompt,
        temperature: widget.temperature,
        maxTokens: widget.maxTokens,
        organization: widget.organization,
        showTokenUsage: widget.showTokenUsage,
        onTokensUsed: widget.onTokensUsed,
      ),
    );
  }

  @override
  void dispose() {
    _provider.dispose();
    // Only dispose controller if we created it
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  Future<void> _handleMessage(ChatMessage message) async {
    // Add user message to chat
    _controller.addMessage(message);

    // Prevent multiple concurrent requests
    if (_isWaitingForResponse) return;
    setState(() => _isWaitingForResponse = true);

    try {
      // Build conversation history
      final history = _buildConversationHistory();

      // Create AI message placeholder
      final aiMessage = ChatMessage(
        text: '',
        user: _aiUser,
        createdAt: DateTime.now(),
        isMarkdown: true,
      );

      // Add placeholder and start streaming
      _controller.addStreamingMessage(aiMessage);
      final messageId = _controller.getMessageId(aiMessage);

      // Stream response from OpenAI
      final stream = _provider.sendMessageStream(
        message.text,
        conversationHistory: history,
      );

      String fullResponse = '';

      await for (final chunk in stream) {
        fullResponse += chunk;
        _controller.updateMessage(messageId, fullResponse);
      }

      // Mark streaming complete
      _controller.stopStreamingMessage(messageId);
    } catch (error) {
      // Handle error
      widget.onError?.call(error);

      // Show error message in chat
      _controller.addMessage(
        ChatMessage(
          text: '❌ Error: ${error.toString()}',
          user: _aiUser,
          createdAt: DateTime.now(),
        ),
      );
    } finally {
      setState(() => _isWaitingForResponse = false);
    }
  }

  /// Builds conversation history for context.
  List<Map<String, String>> _buildConversationHistory() {
    final history = <Map<String, String>>[];

    // Get recent messages (last 10 for context)
    final messages = _controller.messages.take(10).toList();

    for (final msg in messages.reversed) {
      final role = msg.user.id == widget.currentUser.id ? 'user' : 'assistant';
      history.add({
        'role': role,
        'content': msg.text,
      });
    }

    return history;
  }

  @override
  Widget build(BuildContext context) {
    return AiChatWidget(
      currentUser: widget.currentUser,
      aiUser: _aiUser,
      controller: _controller,
      onSendMessage: _handleMessage,
      enableMarkdownStreaming: true,
      streamingWordByWord: true,
      maxWidth: widget.maxWidth,
      welcomeMessageConfig: widget.welcomeMessage != null
          ? WelcomeMessageConfig(
              title: widget.welcomeMessage!,
            )
          : null,
      exampleQuestions: widget.exampleQuestions ?? [],
      readOnly: _isWaitingForResponse,
    );
  }
}
