import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen_ai_chat_ui/integrations.dart';

/// Tests for OpenAI integration.
///
/// Note: These tests use mock data and don't call the real OpenAI API.
/// For integration tests with real API, see integration_test/ directory.
void main() {
  group('OpenAIProvider', () {
    test('creates provider with valid config', () {
      expect(
        () => OpenAIProvider(
          config: const OpenAIConfig(
            apiKey: 'test-key',
            model: 'gpt-3.5-turbo',
          ),
        ),
        returnsNormally,
      );
    });

    test('config has correct defaults', () {
      const config = OpenAIConfig(
        apiKey: 'test-key',
      );

      expect(config.apiKey, 'test-key');
      expect(config.model, 'gpt-3.5-turbo');
      expect(config.temperature, 1.0);
      expect(config.maxTokens, null);
      expect(config.systemPrompt, null);
      expect(config.showTokenUsage, false);
    });

    test('config copyWith works correctly', () {
      const config1 = OpenAIConfig(
        apiKey: 'key1',
        model: 'gpt-3.5-turbo',
        temperature: 0.5,
      );

      final config2 = config1.copyWith(
        model: 'gpt-4',
        temperature: 0.8,
      );

      expect(config2.apiKey, 'key1'); // Unchanged
      expect(config2.model, 'gpt-4'); // Changed
      expect(config2.temperature, 0.8); // Changed
    });

    test('provider implements AiProvider interface', () {
      final provider = OpenAIProvider(
        config: const OpenAIConfig(
          apiKey: 'test-key',
        ),
      );

      expect(provider, isA<AiProvider>());
      provider.dispose();
    });

    test('provider dispose works without error', () {
      final provider = OpenAIProvider(
        config: const OpenAIConfig(
          apiKey: 'test-key',
        ),
      );

      expect(() => provider.dispose(), returnsNormally);
    });

    test('stopGeneration can be called safely', () {
      final provider = OpenAIProvider(
        config: const OpenAIConfig(
          apiKey: 'test-key',
        ),
      );

      // Should not throw even if no generation is in progress
      expect(() => provider.stopGeneration(), returnsNormally);

      provider.dispose();
    });
  });

  group('AiProviderException', () {
    test('creates exception with message', () {
      const exception = AiProviderException('Test error');

      expect(exception.message, 'Test error');
      expect(exception.error, null);
      expect(exception.stackTrace, null);
    });

    test('creates exception with error and stack trace', () {
      final error = Exception('Original error');
      final stackTrace = StackTrace.current;

      final exception = AiProviderException(
        'Test error',
        error: error,
        stackTrace: stackTrace,
      );

      expect(exception.message, 'Test error');
      expect(exception.error, error);
      expect(exception.stackTrace, stackTrace);
    });

    test('toString includes error if provided', () {
      final error = Exception('Original error');
      final exception = AiProviderException(
        'Test error',
        error: error,
      );

      final string = exception.toString();
      expect(string, contains('Test error'));
      expect(string, contains('Original error'));
    });
  });

  group('AiConfig', () {
    test('creates config with required fields', () {
      const config = AiConfig(
        apiKey: 'test-key',
        model: 'gpt-3.5-turbo',
      );

      expect(config.apiKey, 'test-key');
      expect(config.model, 'gpt-3.5-turbo');
      expect(config.temperature, 1.0);
    });

    test('accepts optional parameters', () {
      const config = AiConfig(
        apiKey: 'test-key',
        model: 'gpt-4',
        systemPrompt: 'You are helpful',
        temperature: 0.5,
        maxTokens: 500,
        timeout: Duration(seconds: 30),
      );

      expect(config.systemPrompt, 'You are helpful');
      expect(config.temperature, 0.5);
      expect(config.maxTokens, 500);
      expect(config.timeout, const Duration(seconds: 30));
    });

    test('copyWith creates new instance with changes', () {
      const config1 = AiConfig(
        apiKey: 'key1',
        model: 'model1',
      );

      final config2 = config1.copyWith(
        apiKey: 'key2',
        temperature: 0.7,
      );

      expect(config1.apiKey, 'key1');
      expect(config2.apiKey, 'key2');
      expect(config2.model, 'model1'); // Unchanged
      expect(config2.temperature, 0.7); // Changed
    });
  });
}

/// Note about integration testing:
///
/// To test with real OpenAI API, create an integration test:
///
/// ```dart
/// @Tags(['integration'])
/// testWidgets('OpenAI real API integration', (tester) async {
///   final apiKey = const String.fromEnvironment('OPENAI_API_KEY');
///
///   if (apiKey.isEmpty) {
///     skip('Requires OPENAI_API_KEY environment variable');
///   }
///
///   final provider = OpenAIProvider(
///     config: OpenAIConfig(
///       apiKey: apiKey,
///       model: 'gpt-3.5-turbo',
///     ),
///   );
///
///   final response = await provider.sendMessage('Hello!');
///   expect(response, isNotEmpty);
///
///   provider.dispose();
/// });
/// ```
///
/// Run integration tests with:
/// ```
/// flutter test --dart-define=OPENAI_API_KEY=your_key_here --tags=integration
/// ```
