import 'package:flutter/material.dart';

/// Home screen with a simple list of examples.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onToggleTheme});

  final VoidCallback onToggleTheme;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat UI Examples'),
        actions: [
          IconButton(
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: onToggleTheme,
          ),
        ],
      ),
      body: ListView(
        children: const [
          _ExampleTile(
            title: 'Basic Chat',
            subtitle: 'Bare minimum — no streaming, no markdown, no extras',
            route: '/basic',
          ),
          _ExampleTile(
            title: 'Streaming + Markdown',
            subtitle: 'Real-time streaming with code blocks and rich text',
            route: '/streaming',
          ),
          _ExampleTile(
            title: 'Custom Themes',
            subtitle: 'Switch between Ocean, Sunset, and Default styles',
            route: '/themed',
          ),
        ],
      ),
    );
  }
}

class _ExampleTile extends StatelessWidget {
  const _ExampleTile({
    required this.title,
    required this.subtitle,
    required this.route,
  });

  final String title;
  final String subtitle;
  final String route;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.pushNamed(context, route),
    );
  }
}
