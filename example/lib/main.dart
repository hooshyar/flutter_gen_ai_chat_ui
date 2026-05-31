import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'examples/basic_chat.dart';
import 'examples/streaming_chat.dart';
import 'examples/themed_chat.dart';
import 'examples/actions_chat.dart';
import 'examples/rich_widgets_chat.dart';
import 'examples/rtl_chat.dart';

void main() {
  runApp(const ExampleApp());
}

/// Snappy, uniform page transitions across platforms. The default per-platform
/// builders (notably the slow horizontal slide on web/desktop) made navigating
/// between demos feel sluggish; a short fade reads as instant.
const _fastPageTransitions = PageTransitionsTheme(
  builders: {
    TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
    TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
    TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
    TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
    TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
    TargetPlatform.fuchsia: FadeUpwardsPageTransitionsBuilder(),
  },
);

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
        pageTransitionsTheme: _fastPageTransitions,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: const Color(0xFF6366F1),
        useMaterial3: true,
        brightness: Brightness.dark,
        pageTransitionsTheme: _fastPageTransitions,
      ),
      home: HomeScreen(onToggleTheme: _toggleTheme),
      routes: {
        '/basic': (_) => const BasicChatExample(),
        '/streaming': (_) => const StreamingChatExample(),
        '/themed': (_) => const ThemedChatExample(),
        '/actions': (_) => const ActionsChatExample(),
        '/rich-widgets': (_) => const RichWidgetsChatExample(),
        '/rtl': (_) => const RtlChatExample(),
      },
    );
  }
}
