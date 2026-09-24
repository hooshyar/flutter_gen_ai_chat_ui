import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'shell/app_theme.dart';
import 'examples/basic_chat.dart';
import 'examples/streaming_chat.dart';
import 'examples/themed_chat.dart';
import 'examples/actions_chat.dart';
import 'examples/rich_widgets_chat.dart';
import 'examples/rtl_chat.dart';
import 'examples/attachments_chat.dart';
import 'examples/voice_chat.dart';

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
  // Follows the system theme until the in-app toggle is used; from then on
  // the manual choice overrides it for the rest of the session.
  ThemeMode _themeMode = ThemeMode.system;

  void _toggleTheme() {
    setState(() {
      final isCurrentlyDark = _themeMode == ThemeMode.dark ||
          (_themeMode == ThemeMode.system &&
              WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                  Brightness.dark);
      _themeMode = isCurrentlyDark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Gen AI Chat UI',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: AppTheme.light().copyWith(
        pageTransitionsTheme: _fastPageTransitions,
      ),
      darkTheme: AppTheme.dark().copyWith(
        pageTransitionsTheme: _fastPageTransitions,
      ),
      home: HomeScreen(onToggleTheme: _toggleTheme),
      routes: {
        '/basic': (_) => BasicChatExample(onToggleTheme: _toggleTheme),
        '/streaming': (_) => StreamingChatExample(onToggleTheme: _toggleTheme),
        '/themed': (_) => ThemedChatExample(onToggleTheme: _toggleTheme),
        '/actions': (_) => ActionsChatExample(onToggleTheme: _toggleTheme),
        '/rich-widgets': (_) =>
            RichWidgetsChatExample(onToggleTheme: _toggleTheme),
        '/rtl': (_) => RtlChatExample(onToggleTheme: _toggleTheme),
        '/attachments': (_) =>
            AttachmentsChatExample(onToggleTheme: _toggleTheme),
        '/voice': (_) => VoiceChatExample(onToggleTheme: _toggleTheme),
      },
    );
  }
}
