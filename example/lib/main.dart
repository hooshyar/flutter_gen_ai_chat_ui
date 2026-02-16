import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'examples/basic_chat.dart';
import 'examples/streaming_chat.dart';
import 'examples/themed_chat.dart';

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Gen AI Chat UI',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF6366F1),
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: const Color(0xFF6366F1),
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: HomeScreen(onToggleTheme: _toggleTheme),
      routes: {
        '/basic': (_) => const BasicChatExample(),
        '/streaming': (_) => const StreamingChatExample(),
        '/themed': (_) => const ThemedChatExample(),
      },
    );
  }
}
