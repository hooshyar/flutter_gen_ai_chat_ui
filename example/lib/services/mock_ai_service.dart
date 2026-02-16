import 'dart:async';
import 'dart:math';

/// Response style for mock AI responses.
enum ResponseStyle {
  /// Plain text only — no markdown, short replies.
  plain,

  /// Rich markdown — code blocks, headers, lists.
  markdown,

  /// Conversational — shorter, friendly, emoji-flavored.
  conversational,
}

/// Simple mock AI service for example apps.
///
/// Use [ResponseStyle] to get different response behaviors per example screen.
class ExampleAiService {
  ExampleAiService({this.style = ResponseStyle.markdown});

  final ResponseStyle style;
  final _random = Random();

  /// Generate a response with a simulated delay.
  Future<String> generateResponse(String query) async {
    await Future.delayed(Duration(milliseconds: 500 + _random.nextInt(1000)));

    switch (style) {
      case ResponseStyle.plain:
        return _plainResponse(query);
      case ResponseStyle.markdown:
        return _markdownResponse(query);
      case ResponseStyle.conversational:
        return _conversationalResponse(query);
    }
  }

  // --- Plain text (Basic example) ---
  String _plainResponse(String query) {
    final lower = query.toLowerCase();

    if (lower.contains('hello') || lower.contains('hi') || query.length < 10) {
      return 'Hi there! What would you like to know?';
    }
    if (lower.contains('flutter')) {
      return 'Flutter is Google\'s UI toolkit for building apps from a single '
          'codebase. It supports Android, iOS, web, and desktop. The key '
          'advantage is hot reload — you see changes instantly.';
    }
    if (lower.contains('dart')) {
      return 'Dart is the programming language behind Flutter. It\'s '
          'object-oriented, strongly typed, and supports both AOT and JIT '
          'compilation. The syntax is similar to Java or TypeScript.';
    }
    return 'That\'s an interesting question. In a real app, this is where '
        'your AI backend would provide a response. This is just a demo '
        'with plain text replies — no formatting.';
  }

  // --- Rich markdown (Streaming example) ---
  String _markdownResponse(String query) {
    final lower = query.toLowerCase();

    if (lower.contains('singleton')) {
      return '# Singleton Pattern in Dart\n\n'
          'A singleton ensures only one instance of a class exists.\n\n'
          '```dart\n'
          'class AppConfig {\n'
          '  static final AppConfig _instance = AppConfig._internal();\n'
          '  factory AppConfig() => _instance;\n'
          '  AppConfig._internal();\n'
          '\n'
          '  String apiUrl = \'https://api.example.com\';\n'
          '  bool debugMode = false;\n'
          '}\n'
          '\n'
          '// Usage:\n'
          'final config = AppConfig();\n'
          'config.debugMode = true;\n'
          '```\n\n'
          '> **Tip:** Use singletons sparingly. For most cases, dependency '
          'injection with `Provider` or `Riverpod` is more testable.\n';
    }

    if (lower.contains('async') || lower.contains('await')) {
      return '# Async/Await in Dart\n\n'
          'Dart uses `Future` for async operations and `Stream` for '
          'sequences of async events.\n\n'
          '## Future Example\n'
          '```dart\n'
          'Future<String> fetchUser() async {\n'
          '  final response = await http.get(\n'
          '    Uri.parse(\'https://api.example.com/user\'),\n'
          '  );\n'
          '  return response.body;\n'
          '}\n'
          '```\n\n'
          '## Error Handling\n'
          '```dart\n'
          'try {\n'
          '  final user = await fetchUser();\n'
          '  print(user);\n'
          '} on SocketException {\n'
          '  print(\'No internet\');\n'
          '} catch (e) {\n'
          '  print(\'Error: \$e\');\n'
          '}\n'
          '```\n\n'
          '**Key rules:**\n'
          '- Mark functions `async` to use `await`\n'
          '- `await` pauses execution until the `Future` completes\n'
          '- Always handle errors with `try/catch`\n';
    }

    if (lower.contains('stateless') || lower.contains('stateful')) {
      return '# StatelessWidget vs StatefulWidget\n\n'
          '| | StatelessWidget | StatefulWidget |\n'
          '|---|---|---|\n'
          '| **State** | Immutable | Mutable via `setState` |\n'
          '| **Rebuilds** | Only when parent rebuilds | Also on `setState` |\n'
          '| **Use case** | Static UI, display data | Forms, animations, dynamic UI |\n\n'
          '## StatelessWidget\n'
          '```dart\n'
          'class Greeting extends StatelessWidget {\n'
          '  const Greeting({super.key, required this.name});\n'
          '  final String name;\n\n'
          '  @override\n'
          '  Widget build(BuildContext context) {\n'
          '    return Text(\'Hello, \$name!\');\n'
          '  }\n'
          '}\n'
          '```\n\n'
          '## StatefulWidget\n'
          '```dart\n'
          'class Counter extends StatefulWidget {\n'
          '  const Counter({super.key});\n\n'
          '  @override\n'
          '  State<Counter> createState() => _CounterState();\n'
          '}\n\n'
          'class _CounterState extends State<Counter> {\n'
          '  int _count = 0;\n\n'
          '  @override\n'
          '  Widget build(BuildContext context) {\n'
          '    return TextButton(\n'
          '      onPressed: () => setState(() => _count++),\n'
          '      child: Text(\'Count: \$_count\'),\n'
          '    );\n'
          '  }\n'
          '}\n'
          '```\n\n'
          '> **Rule of thumb:** Start with `StatelessWidget`. Only use '
          '`StatefulWidget` when you need local mutable state.\n';
    }

    if (lower.contains('hello') || lower.contains('hi') || query.length < 10) {
      return '# Hey there! 👋\n\n'
          'I\'m a code assistant demo. Try asking me about:\n\n'
          '- **Dart patterns** — singletons, factories, builders\n'
          '- **Flutter widgets** — stateless vs stateful\n'
          '- **Async programming** — futures, streams, isolates\n';
    }

    return '# Great Question\n\n'
        'In a production app, this is where your LLM backend (GPT, Claude, '
        'Gemini, etc.) would generate a response.\n\n'
        'This demo shows how **markdown rendering** works in the chat:\n\n'
        '- **Bold** and *italic* text\n'
        '- `inline code` and code blocks\n'
        '- Headers, lists, and tables\n'
        '- > Blockquotes like this\n\n'
        '```dart\n'
        'print(\'Streaming + markdown = great DX\');\n'
        '```\n';
  }

  // --- Conversational (Themed example) ---
  String _conversationalResponse(String query) {
    final lower = query.toLowerCase();

    if (lower.contains('long')) {
      return 'Sure! Here\'s a longer reply so you can see how the bubble '
          'styles handle multi-line content. Notice how the border radius, '
          'colors, and spacing all change when you switch themes. The Ocean '
          'theme uses rounded bubbles with cool blue tones. The Sunset theme '
          'goes for sharp corners and warm orange hues. And Default is the '
          'out-of-the-box Material style. Each theme also changes the input '
          'field — check the hint text and border shape! Try typing a few '
          'messages in each theme to get a feel for the differences. The '
          'bubble colors, text contrast, and overall vibe should feel '
          'distinct across all three. 🎨';
    }

    if (lower.contains('theme')) {
      return 'Themes are configured through MessageOptions and InputOptions '
          'on AiChatWidget. BubbleStyle controls colors and border radii. '
          'You can change them at runtime — just call setState with new '
          'options and the UI updates instantly. Try switching themes above! ✨';
    }

    if (lower.contains('hello') || lower.contains('hi') || query.length < 10) {
      return 'Hey! 👋 I\'m Aria, your design playground assistant. '
          'Switch the theme selector above and then chat with me to see '
          'how the bubbles change!';
    }

    return 'Nice message! Try switching between the Ocean 🌊, Sunset 🌅, '
        'and Default themes above to see how this chat looks in different '
        'styles. Each theme changes bubble colors, border radii, and input '
        'decoration.';
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
