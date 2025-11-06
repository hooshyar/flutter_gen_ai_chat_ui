import 'dart:async';
import 'package:dart_openai/dart_openai.dart';
import '../base/ai_provider.dart';
import 'openai_config.dart';

/// OpenAI provider implementation.
///
/// Provides integration with OpenAI's GPT models including GPT-4, GPT-3.5-turbo, etc.
///
/// Example usage:
/// ```dart
/// final provider = OpenAIProvider(
///   config: OpenAIConfig(
///     apiKey: const String.fromEnvironment('OPENAI_API_KEY'),
///     model: 'gpt-4-turbo',
///   ),
/// );
///
/// // Send message
/// final response = await provider.sendMessage('Hello!');
///
/// // Or stream response
/// final stream = provider.sendMessageStream('Tell me a story');
/// await for (final chunk in stream) {
///   print(chunk);
/// }
/// ```
class OpenAIProvider implements AiProvider {
  /// The configuration for this provider.
  final OpenAIConfig config;

  StreamSubscription? _currentSubscription;
  StreamController<String>? _currentStreamController;

  /// Creates an OpenAI provider with the given configuration.
  OpenAIProvider({required this.config}) {
    // Initialize the OpenAI client with API key
    OpenAI.apiKey = config.apiKey;

    // Set organization if provided
    if (config.organization != null) {
      OpenAI.organization = config.organization;
    }

    // Set timeout if provided
    if (config.timeout != null) {
      OpenAI.requestsTimeOut = config.timeout!;
    }
  }

  @override
  Future<String> sendMessage(
    String message, {
    List<Map<String, String>>? conversationHistory,
  }) async {
    try {
      // Build messages list
      final messages = _buildMessages(message, conversationHistory);

      // Create chat completion
      final chatCompletion = await OpenAI.instance.chat.create(
        model: config.model,
        messages: messages,
        temperature: config.temperature,
        maxTokens: config.maxTokens,
      );

      // Extract response
      final response = chatCompletion.choices.first.message.content?.first.text ?? '';

      // Handle token usage
      if (chatCompletion.usage != null) {
        final totalTokens = chatCompletion.usage!.totalTokens ?? 0;
        final estimatedCost = _estimateCost(totalTokens, config.model);

        if (config.showTokenUsage) {
          print('OpenAI: Used $totalTokens tokens (≈\$$estimatedCost)');
        }

        config.onTokensUsed?.call(totalTokens, estimatedCost);
      }

      return response;
    } on RequestFailedException catch (e) {
      throw AiProviderException(
        'OpenAI API request failed: ${e.message}',
        error: e,
        stackTrace: e.stackTrace,
      );
    } catch (e, stackTrace) {
      throw AiProviderException(
        'Unexpected error calling OpenAI API',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Stream<String> sendMessageStream(
    String message, {
    List<Map<String, String>>? conversationHistory,
  }) {
    // Create a new stream controller
    _currentStreamController = StreamController<String>();

    // Build messages list
    final messages = _buildMessages(message, conversationHistory);

    // Start streaming in the background
    _startStreaming(messages);

    return _currentStreamController!.stream;
  }

  Future<void> _startStreaming(
    List<OpenAIChatCompletionChoiceMessageModel> messages,
  ) async {
    try {
      // Create streaming chat completion
      final stream = OpenAI.instance.chat.createStream(
        model: config.model,
        messages: messages,
        temperature: config.temperature,
        maxTokens: config.maxTokens,
      );

      // Subscribe to the stream
      _currentSubscription = stream.listen(
        (chatStreamEvent) {
          // Extract the delta (new text chunk)
          final delta = chatStreamEvent.choices.first.delta.content?.first.text;
          if (delta != null && delta.isNotEmpty) {
            _currentStreamController?.add(delta);
          }
        },
        onDone: () {
          _currentStreamController?.close();
          _currentSubscription = null;
          _currentStreamController = null;
        },
        onError: (error, stackTrace) {
          _currentStreamController?.addError(
            AiProviderException(
              'Error during OpenAI streaming',
              error: error,
              stackTrace: stackTrace,
            ),
          );
          _currentStreamController?.close();
          _currentSubscription = null;
          _currentStreamController = null;
        },
        cancelOnError: true,
      );
    } catch (e, stackTrace) {
      _currentStreamController?.addError(
        AiProviderException(
          'Failed to start OpenAI streaming',
          error: e,
          stackTrace: stackTrace,
        ),
      );
      _currentStreamController?.close();
    }
  }

  @override
  void stopGeneration() {
    _currentSubscription?.cancel();
    _currentStreamController?.close();
    _currentSubscription = null;
    _currentStreamController = null;
  }

  @override
  void dispose() {
    stopGeneration();
  }

  /// Builds the messages list for OpenAI API.
  List<OpenAIChatCompletionChoiceMessageModel> _buildMessages(
    String message,
    List<Map<String, String>>? conversationHistory,
  ) {
    final messages = <OpenAIChatCompletionChoiceMessageModel>[];

    // Add system prompt if provided
    if (config.systemPrompt != null) {
      messages.add(
        OpenAIChatCompletionChoiceMessageModel(
          role: OpenAIChatMessageRole.system,
          content: [
            OpenAIChatCompletionChoiceMessageContentItemModel.text(
              config.systemPrompt!,
            ),
          ],
        ),
      );
    }

    // Add conversation history if provided
    if (conversationHistory != null) {
      for (final msg in conversationHistory) {
        final role = msg['role'] == 'user'
            ? OpenAIChatMessageRole.user
            : OpenAIChatMessageRole.assistant;
        final content = msg['content'] ?? '';

        messages.add(
          OpenAIChatCompletionChoiceMessageModel(
            role: role,
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.text(content),
            ],
          ),
        );
      }
    }

    // Add current message
    messages.add(
      OpenAIChatCompletionChoiceMessageModel(
        role: OpenAIChatMessageRole.user,
        content: [
          OpenAIChatCompletionChoiceMessageContentItemModel.text(message),
        ],
      ),
    );

    return messages;
  }

  /// Estimates the cost based on tokens and model.
  ///
  /// Prices as of 2024 (approximate, check OpenAI pricing for exact rates):
  /// - GPT-4 Turbo: $0.01/1K input, $0.03/1K output
  /// - GPT-4: $0.03/1K input, $0.06/1K output
  /// - GPT-3.5 Turbo: $0.0015/1K input, $0.002/1K output
  double _estimateCost(int tokens, String model) {
    // Simplified cost estimation (average of input/output)
    if (model.contains('gpt-4-turbo')) {
      return (tokens / 1000) * 0.02; // Average of $0.01 input + $0.03 output
    } else if (model.contains('gpt-4')) {
      return (tokens / 1000) * 0.045; // Average of $0.03 input + $0.06 output
    } else if (model.contains('gpt-3.5-turbo')) {
      return (tokens / 1000) * 0.00175; // Average of $0.0015 input + $0.002 output
    }

    // Default estimate for unknown models
    return (tokens / 1000) * 0.02;
  }
}
