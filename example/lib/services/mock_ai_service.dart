import 'dart:async';
import 'dart:math';

/// Simple mock AI service for example apps.
class MockAiService {
  final _random = Random();

  /// Generate a response with a simulated delay.
  Future<String> generateResponse(String query) async {
    await Future.delayed(Duration(milliseconds: 500 + _random.nextInt(1000)));

    final lower = query.toLowerCase();

    if (lower.contains('hello') || lower.contains('hi') || query.length < 10) {
      return "Hello! I'm your AI assistant. How can I help you today?";
    }

    if (lower.contains('flutter') || lower.contains('dart')) {
      return '# Flutter\n\n'
          'Flutter is Google\'s UI toolkit for building natively compiled '
          'applications from a single codebase.\n\n'
          '## Key Features\n'
          '- **Hot Reload**: Quickly experiment and build UIs\n'
          '- **Expressive UI**: Beautiful widgets out of the box\n'
          '- **Native Performance**: Compiles to native code\n';
    }

    if (lower.contains('code') || lower.contains('example')) {
      return '# Code Example\n\n'
          '```dart\n'
          'class MyWidget extends StatelessWidget {\n'
          '  @override\n'
          '  Widget build(BuildContext context) {\n'
          '    return const Text(\'Hello, World!\');\n'
          '  }\n'
          '}\n'
          '```\n';
    }

    if (lower.contains('help') || lower.contains('what can you')) {
      return '# How I Can Help\n\n'
          '1. **Answer questions** about Flutter and Dart\n'
          '2. **Show code examples** with syntax highlighting\n'
          '3. **Demonstrate markdown** rendering in chat\n'
          '4. **Explain features** of this chat UI package\n';
    }

    return "Thanks for your message! I'm a demo assistant showcasing the "
        "Flutter Gen AI Chat UI package. Try asking about Flutter, "
        "code examples, or what I can help with.";
  }

  /// Stream a response word by word.
  Stream<String> streamResponse(String query) async* {
    final response = await generateResponse(query);
    final words = response.split(' ');
    var accumulated = '';

    for (final word in words) {
      accumulated += (accumulated.isEmpty ? '' : ' ') + word;
      yield accumulated;
      await Future.delayed(Duration(milliseconds: 20 + _random.nextInt(60)));
    }
  }
}
