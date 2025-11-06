/// Abstract interface for AI provider integrations.
///
/// Implement this interface to create custom AI integrations.
/// Built-in implementations: [OpenAIProvider], [ClaudeProvider]
abstract class AiProvider {
  /// Send a message and get a complete response.
  ///
  /// [message] - The user's message text
  /// [conversationHistory] - Optional list of previous messages for context
  ///
  /// Returns the AI's response text.
  ///
  /// Throws [AiProviderException] if the API call fails.
  Future<String> sendMessage(
    String message, {
    List<Map<String, String>>? conversationHistory,
  });

  /// Send a message and get a streaming response.
  ///
  /// [message] - The user's message text
  /// [conversationHistory] - Optional list of previous messages for context
  ///
  /// Returns a stream of text chunks as they arrive from the AI.
  /// The stream completes when the AI finishes generating.
  ///
  /// Throws [AiProviderException] if the API call fails.
  Stream<String> sendMessageStream(
    String message, {
    List<Map<String, String>>? conversationHistory,
  });

  /// Stop the current generation (if streaming).
  ///
  /// This cancels any ongoing streaming response.
  /// Has no effect if no generation is in progress.
  void stopGeneration();

  /// Dispose of any resources used by this provider.
  ///
  /// Call this when you're done using the provider to clean up
  /// network connections, subscriptions, etc.
  void dispose();
}

/// Exception thrown when an AI provider encounters an error.
class AiProviderException implements Exception {
  /// The error message.
  final String message;

  /// The underlying error, if any.
  final Object? error;

  /// Stack trace of the error, if available.
  final StackTrace? stackTrace;

  /// Creates an AI provider exception.
  const AiProviderException(
    this.message, {
    this.error,
    this.stackTrace,
  });

  @override
  String toString() {
    if (error != null) {
      return 'AiProviderException: $message\nCaused by: $error';
    }
    return 'AiProviderException: $message';
  }
}
