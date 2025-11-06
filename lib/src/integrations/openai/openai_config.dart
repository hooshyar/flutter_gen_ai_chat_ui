import '../base/ai_config.dart';

/// Configuration for OpenAI provider.
class OpenAIConfig extends AiConfig {
  /// OpenAI organization ID (optional).
  final String? organization;

  /// Whether to show token usage in responses.
  final bool showTokenUsage;

  /// Callback when tokens are used.
  ///
  /// Called after each API response with token count and estimated cost.
  final void Function(int tokens, double estimatedCost)? onTokensUsed;

  /// Creates an OpenAI configuration.
  ///
  /// [apiKey] - Your OpenAI API key (required).
  /// ⚠️ Never hardcode this! Use environment variables or secure backend.
  ///
  /// [model] - The OpenAI model to use.
  /// Popular options:
  /// - 'gpt-4-turbo': Latest GPT-4 Turbo (128K context)
  /// - 'gpt-4': Standard GPT-4 (8K context)
  /// - 'gpt-3.5-turbo': Fast and cost-effective
  ///
  /// [systemPrompt] - Sets the AI's behavior and personality.
  ///
  /// [temperature] - Controls randomness (0.0 to 2.0, default 1.0).
  ///
  /// [maxTokens] - Maximum length of response.
  ///
  /// [organization] - Your OpenAI organization ID (if applicable).
  ///
  /// [showTokenUsage] - Whether to print token usage to console.
  ///
  /// [onTokensUsed] - Callback for tracking token usage and costs.
  const OpenAIConfig({
    required super.apiKey,
    super.model = 'gpt-3.5-turbo',
    super.systemPrompt,
    super.temperature = 1.0,
    super.maxTokens,
    super.timeout,
    this.organization,
    this.showTokenUsage = false,
    this.onTokensUsed,
  });

  @override
  OpenAIConfig copyWith({
    String? apiKey,
    String? model,
    String? systemPrompt,
    double? temperature,
    int? maxTokens,
    Duration? timeout,
    String? organization,
    bool? showTokenUsage,
    void Function(int, double)? onTokensUsed,
  }) {
    return OpenAIConfig(
      apiKey: apiKey ?? this.apiKey,
      model: model ?? this.model,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      temperature: temperature ?? this.temperature,
      maxTokens: maxTokens ?? this.maxTokens,
      timeout: timeout ?? this.timeout,
      organization: organization ?? this.organization,
      showTokenUsage: showTokenUsage ?? this.showTokenUsage,
      onTokensUsed: onTokensUsed ?? this.onTokensUsed,
    );
  }
}
