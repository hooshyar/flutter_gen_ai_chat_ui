import 'package:flutter/material.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';

/// Defines each example as a configuration object
enum ExampleType {
  basic,
  streaming,
  themes,
  files,
  complete,
}

class ExampleConfig {
  final String title;
  final String subtitle;
  final IconData icon;
  final ExampleType type;

  const ExampleConfig({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.type,
  });
}

const examples = [
  ExampleConfig(
    title: 'Basic Chat',
    subtitle: 'Simple send & receive',
    icon: Icons.chat_bubble_outline,
    type: ExampleType.basic,
  ),
  ExampleConfig(
    title: 'Streaming & Markdown',
    subtitle: 'Word-by-word, code blocks',
    icon: Icons.stream,
    type: ExampleType.streaming,
  ),
  ExampleConfig(
    title: 'Themes',
    subtitle: 'Multiple visual styles',
    icon: Icons.palette_outlined,
    type: ExampleType.themes,
  ),
  ExampleConfig(
    title: 'File Attachments',
    subtitle: 'Upload & preview files',
    icon: Icons.attach_file,
    type: ExampleType.files,
  ),
  ExampleConfig(
    title: 'Complete',
    subtitle: 'All features combined',
    icon: Icons.auto_awesome,
    type: ExampleType.complete,
  ),
];

/// Theme presets for the Themes example
enum ThemePreset {
  minimal,
  elegant,
  gradient,
  glassmorphic,
  neon,
}

extension ThemePresetLabel on ThemePreset {
  String get label {
    switch (this) {
      case ThemePreset.minimal:
        return 'Minimal';
      case ThemePreset.elegant:
        return 'Elegant';
      case ThemePreset.gradient:
        return 'Gradient';
      case ThemePreset.glassmorphic:
        return 'Glassmorphic';
      case ThemePreset.neon:
        return 'Neon';
    }
  }
}

/// Returns bubble style for a given theme preset
BubbleStyle getBubbleStyleForPreset(ThemePreset preset, bool isDark, BuildContext context) {
  switch (preset) {
    case ThemePreset.minimal:
      return BubbleStyle(
        userBubbleColor: isDark ? const Color(0xFF2D2D2D) : const Color(0xFFF0F0F0),
        aiBubbleColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        userBubbleTopLeftRadius: 16,
        userBubbleTopRightRadius: 16,
        aiBubbleTopLeftRadius: 16,
        aiBubbleTopRightRadius: 16,
        bottomLeftRadius: 16,
        bottomRightRadius: 16,
        enableShadow: false,
      );
    case ThemePreset.elegant:
      return BubbleStyle(
        userBubbleColor: isDark ? const Color(0xFF1B3A4B) : const Color(0xFFE8F0FE),
        aiBubbleColor: isDark ? const Color(0xFF2C2C3A) : const Color(0xFFFAFAFF),
        userBubbleTopLeftRadius: 20,
        userBubbleTopRightRadius: 4,
        aiBubbleTopLeftRadius: 4,
        aiBubbleTopRightRadius: 20,
        bottomLeftRadius: 20,
        bottomRightRadius: 20,
        enableShadow: true,
      );
    case ThemePreset.gradient:
      return BubbleStyle(
        userBubbleColor: const Color(0xFF6366F1),
        aiBubbleColor: isDark ? const Color(0xFF1E1E2E) : const Color(0xFFF8F8FF),
        userBubbleTopLeftRadius: 18,
        userBubbleTopRightRadius: 18,
        aiBubbleTopLeftRadius: 18,
        aiBubbleTopRightRadius: 18,
        bottomLeftRadius: 18,
        bottomRightRadius: 4,
        enableShadow: true,
      );
    case ThemePreset.glassmorphic:
      return BubbleStyle(
        userBubbleColor: isDark
            ? const Color(0xFF6366F1).withOpacity(0.3)
            : const Color(0xFF6366F1).withOpacity(0.15),
        aiBubbleColor: isDark
            ? Colors.white.withOpacity(0.08)
            : Colors.white.withOpacity(0.7),
        userBubbleTopLeftRadius: 24,
        userBubbleTopRightRadius: 24,
        aiBubbleTopLeftRadius: 24,
        aiBubbleTopRightRadius: 24,
        bottomLeftRadius: 24,
        bottomRightRadius: 24,
        enableShadow: false,
      );
    case ThemePreset.neon:
      return BubbleStyle(
        userBubbleColor: isDark ? const Color(0xFF0D0D1A) : const Color(0xFF1A1A2E),
        aiBubbleColor: isDark ? const Color(0xFF16213E) : const Color(0xFF0F3460),
        userBubbleTopLeftRadius: 12,
        userBubbleTopRightRadius: 12,
        aiBubbleTopLeftRadius: 12,
        aiBubbleTopRightRadius: 12,
        bottomLeftRadius: 12,
        bottomRightRadius: 12,
        enableShadow: true,
      );
  }
}

/// Mock responses keyed by example type
class MockResponses {
  static const basicResponses = [
    "Sure, I can help with that! What specifically would you like to know?",
    "That's a great question. Let me think about it for a moment.",
    "I'd be happy to assist. Could you provide a bit more context?",
    "Interesting point! Here's what I think about that.",
    "Good question! The short answer is yes, but there are some nuances.",
    "I understand what you're asking. Let me break it down for you.",
  ];

  static const markdownResponse = '''
## Here's what I found

There are a few approaches to consider:

1. **Direct approach** — straightforward but less flexible
2. **Abstraction layer** — more setup, better long-term
3. **Hybrid** — combine both as needed

### Code example

```dart
class Repository<T> {
  final DataSource<T> _source;
  
  Repository(this._source);
  
  Future<List<T>> getAll() async {
    return await _source.fetchAll();
  }
  
  Future<T?> getById(String id) async {
    return await _source.fetchById(id);
  }
}
```

> **Tip**: Start with the direct approach and refactor when complexity grows.

The key tradeoff is between *simplicity* and *flexibility*. For most projects, option 2 works well once you have more than 3-4 data models.
''';

  static const streamingResponses = [
    '''Let me walk you through this step by step.

### Setting up the project

First, you'll want to create a new directory and initialize it:

```bash
mkdir my_project && cd my_project
flutter create .
```

Then add your dependencies to `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.2
  http: ^1.2.0
```

### Key concepts

- **State management** is crucial for larger apps
- **Separation of concerns** keeps code maintainable  
- **Testing** should be part of your workflow from day one

Would you like me to elaborate on any of these?''',
    '''Here are the main differences:

| Aspect | StatelessWidget | StatefulWidget |
|--------|----------------|----------------|
| State | No mutable state | Has mutable state |
| Rebuild | Only when parent rebuilds | Can trigger own rebuilds |
| Use case | Static UI | Dynamic/interactive UI |

### When to use each

**StatelessWidget** — for UI that depends only on its configuration:
```dart
class Greeting extends StatelessWidget {
  final String name;
  const Greeting({required this.name});
  
  @override
  Widget build(BuildContext context) {
    return Text('Hello, \$name!');
  }
}
```

**StatefulWidget** — when the widget needs to track changes:
```dart
class Counter extends StatefulWidget {
  @override
  State<Counter> createState() => _CounterState();
}
```

Most of the time, prefer **StatelessWidget** + state management (Provider, Riverpod, etc.) over StatefulWidget.''',
  ];

  static const fileResponse =
      "I've received your file. In a real implementation, this would be processed by your backend. The chat UI supports images, documents, and other file types with preview thumbnails and progress indicators.";
}
