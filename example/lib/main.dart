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

/// Normalizes a route name pushed by the platform (e.g. a browser URL hash
/// change on web) so it can be looked up in the demo route table: strips any
/// query string and fragment, drops trailing slashes (but keeps "/"),
/// lower-cases, and ensures a leading "/".
String _normalizeRouteName(String? name) {
  var normalized = (name == null || name.isEmpty) ? '/' : name;
  final queryIndex = normalized.indexOf('?');
  if (queryIndex >= 0) {
    normalized = normalized.substring(0, queryIndex);
  }
  final fragmentIndex = normalized.indexOf('#');
  if (fragmentIndex >= 0) {
    normalized = normalized.substring(0, fragmentIndex);
  }
  normalized = normalized.toLowerCase();
  if (!normalized.startsWith('/')) {
    normalized = '/$normalized';
  }
  while (normalized.length > 1 && normalized.endsWith('/')) {
    normalized = normalized.substring(0, normalized.length - 1);
  }
  return normalized;
}

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
    final routes = <String, WidgetBuilder>{
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
    };
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
      routes: routes,
      // On web the browser pushes raw URL paths (any case, trailing slash,
      // query string); normalize before looking them up in the route table.
      onGenerateRoute: (settings) {
        final name = _normalizeRouteName(settings.name);
        final builder = routes[name];
        if (builder == null) {
          return null;
        }
        return MaterialPageRoute<void>(
          builder: builder,
          settings: RouteSettings(
            name: name,
            arguments: settings.arguments,
          ),
        );
      },
      // Unknown paths land on home instead of throwing from _onUnknownRoute.
      onUnknownRoute: (settings) => MaterialPageRoute<void>(
        builder: (_) => HomeScreen(onToggleTheme: _toggleTheme),
        settings: settings,
      ),
    );
  }
}
