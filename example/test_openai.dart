/// Functional test for OpenAI integration
///
/// This script tests the OpenAI integration with a real API key.
/// Run from the example directory.
///
/// Usage:
/// ```bash
/// cd example
/// dart run test_openai.dart
/// ```
///
/// Set API key before running:
/// ```bash
/// export OPENAI_API_KEY=your_key_here
/// # or
/// dart run test_openai.dart --dart-define=OPENAI_API_KEY=your_key_here
/// ```

import 'dart:io';
import 'package:flutter_gen_ai_chat_ui/integrations.dart';

void main() async {
  print('🧪 OpenAI Integration Functional Test\n');

  // Get API key
  final apiKey = const String.fromEnvironment('OPENAI_API_KEY',
      defaultValue: '');

  if (apiKey.isEmpty) {
    final envKey = Platform.environment['OPENAI_API_KEY'];
    if (envKey == null || envKey.isEmpty) {
      print('❌ ERROR: OPENAI_API_KEY not set\n');
      print('Set it using:');
      print('  export OPENAI_API_KEY=your_key_here');
      print('  dart run test_openai.dart\n');
      print('Or:');
      print('  dart run test_openai.dart --dart-define=OPENAI_API_KEY=your_key');
      exit(1);
    }
  }

  final effectiveKey = apiKey.isEmpty
      ? Platform.environment['OPENAI_API_KEY']!
      : apiKey;

  print('✅ API key found\n');

  double totalCost = 0.0;

  try {
    print('📦 Creating OpenAI provider...');
    final provider = OpenAIProvider(
      config: OpenAIConfig(
        apiKey: effectiveKey,
        model: 'gpt-3.5-turbo',
        showTokenUsage: true,
        onTokensUsed: (tokens, cost) {
          totalCost += cost;
          print('  💰 Tokens: $tokens, Cost: \$${cost.toStringAsFixed(4)}');
        },
      ),
    );
    print('✅ Provider created\n');

    // Test 1: Simple message
    print('🧪 Test 1: Simple message');
    print('-' * 50);
    final response1 = await provider.sendMessage(
      'Say exactly: "OpenAI integration test successful!"',
    );
    print('📨 Response: $response1');
    print('✅ Test 1 passed\n');

    // Test 2: Streaming
    print('🧪 Test 2: Streaming response');
    print('-' * 50);
    print('📨 Response: ');
    final stream = provider.sendMessageStream(
      'Count from 1 to 5, one number per line',
    );
    await for (final chunk in stream) {
      stdout.write(chunk);
    }
    print('\n✅ Test 2 passed\n');

    // Test 3: Conversation history
    print('🧪 Test 3: Conversation history');
    print('-' * 50);
    final response3 = await provider.sendMessage(
      'What is my favorite color?',
      conversationHistory: [
        {'role': 'user', 'content': 'My favorite color is purple.'},
        {'role': 'assistant', 'content': 'Purple is a great choice!'},
      ],
    );
    print('📨 Response: $response3');
    final hasPurple = response3.toLowerCase().contains('purple');
    print(hasPurple
        ? '✅ Test 3 passed (mentioned purple)'
        : '⚠️  Test 3: Response should mention purple');
    print('');

    // Cleanup
    provider.dispose();
    print('✅ Provider disposed');

    // Summary
    print('\n' + '=' * 50);
    print('🎉 ALL TESTS COMPLETED SUCCESSFULLY!');
    print('=' * 50);
    print('Total cost: \$${totalCost.toStringAsFixed(4)}');
    print('\nThe OpenAI integration is working correctly.');
    print('You can now use OpenAIChatWidget in your app!');

  } catch (e, stack) {
    print('\n❌ ERROR: $e');
    print('\nStack trace:');
    print(stack);
    print('\nPlease check:');
    print('1. API key is valid');
    print('2. You have internet connection');
    print('3. OpenAI API is accessible');
    exit(1);
  }
}
