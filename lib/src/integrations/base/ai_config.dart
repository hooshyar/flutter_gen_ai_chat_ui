/// Base configuration for AI providers.
///
/// Extended by provider-specific config classes.
class AiConfig {
  /// The API key for authentication.
  ///
  /// ⚠️ SECURITY WARNING: Never hardcode your API key!
  ///
  /// ✅ Use environment variables:
  /// ```dart
  /// apiKey: const String.fromEnvironment('OPENAI_API_KEY')
  /// ```
  ///
  /// ✅ Or fetch from secure backend:
  /// ```dart
  /// final apiKey = await yourBackend.getSecureToken();
  /// ```
  final String apiKey;

  /// The model to use (e.g., 'gpt-4-turbo', 'claude-3-sonnet').
  final String model;

  /// System prompt to set the AI's behavior.
  ///
  /// Example: 'You are a helpful assistant specialized in Flutter development.'
  final String? systemPrompt;

  /// Temperature controls randomness (0.0 to 2.0).
  ///
  /// - 0.0: Deterministic, focused responses
  /// - 1.0: Balanced creativity and focus (default)
  /// - 2.0: Maximum creativity and randomness
  final double temperature;

  /// Maximum tokens in the response.
  ///
  /// Controls the length of AI responses.
  /// Set to null for provider default.
  final int? maxTokens;

  /// Custom timeout for API requests.
  ///
  /// If null, uses provider default (typically 30-60 seconds).
  final Duration? timeout;

  /// Creates an AI configuration.
  const AiConfig({
    required this.apiKey,
    required this.model,
    this.systemPrompt,
    this.temperature = 1.0,
    this.maxTokens,
    this.timeout,
  });

  /// Creates a copy with some fields replaced.
  AiConfig copyWith({
    String? apiKey,
    String? model,
    String? systemPrompt,
    double? temperature,
    int? maxTokens,
    Duration? timeout,
  }) {
    return AiConfig(
      apiKey: apiKey ?? this.apiKey,
      model: model ?? this.model,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      temperature: temperature ?? this.temperature,
      maxTokens: maxTokens ?? this.maxTokens,
      timeout: timeout ?? this.timeout,
    );
  }
}
