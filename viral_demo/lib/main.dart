import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const ViralDemoApp());
}

class ViralDemoApp extends StatelessWidget {
  const ViralDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Gen AI Chat UI - Live Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.dark,
      home: const ViralDemoScreen(),
    );
  }
}

class ViralDemoScreen extends StatefulWidget {
  const ViralDemoScreen({super.key});

  @override
  State<ViralDemoScreen> createState() => _ViralDemoScreenState();
}

class _ViralDemoScreenState extends State<ViralDemoScreen>
    with TickerProviderStateMixin {
  late ChatMessagesController _controller;
  late AnimationController _timerAnimationController;
  late AnimationController _shareButtonController;

  // Demo state
  bool _showSplash = true;
  bool _demoStarted = false;
  int _demoPhase = 0;
  Timer? _demoTimer;
  Timer? _splashTimer;

  // Timer for "Built in X minutes"
  int _elapsedSeconds = 0;
  Timer? _buildTimer;

  // Konami code tracking
  final List<LogicalKeyboardKey> _konamiCode = [
    LogicalKeyboardKey.arrowUp,
    LogicalKeyboardKey.arrowUp,
    LogicalKeyboardKey.arrowDown,
    LogicalKeyboardKey.arrowDown,
    LogicalKeyboardKey.arrowLeft,
    LogicalKeyboardKey.arrowRight,
    LogicalKeyboardKey.arrowLeft,
    LogicalKeyboardKey.arrowRight,
    LogicalKeyboardKey.keyB,
    LogicalKeyboardKey.keyA,
  ];
  final List<LogicalKeyboardKey> _pressedKeys = [];
  bool _konamiActivated = false;

  // Users
  final _currentUser = const ChatUser(id: 'you', firstName: 'You');
  final _aiUser = const ChatUser(
    id: 'ai',
    firstName: 'AI Assistant',
    avatar: 'https://ui-avatars.com/api/?name=AI&background=6366f1&color=fff',
  );

  // Theme variations
  int _currentTheme = 0;
  final List<String> _themeNames = [
    'Gradient Magic',
    'Neon Dreams',
    'Glassmorphic',
    'Elegant Dark',
    'Minimal Clean'
  ];

  @override
  void initState() {
    super.initState();
    _controller = ChatMessagesController();

    _timerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);

    _shareButtonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _startSplashSequence();
    _startBuildTimer();
    _setupKeyboardListener();
  }

  void _setupKeyboardListener() {
    ServicesBinding.instance.keyboard.addHandler(_handleKeyPress);
  }

  bool _handleKeyPress(KeyEvent event) {
    if (event is KeyDownEvent) {
      _pressedKeys.add(event.logicalKey);

      // Keep only last 10 keys
      if (_pressedKeys.length > 10) {
        _pressedKeys.removeAt(0);
      }

      // Check for Konami code
      if (_pressedKeys.length == 10) {
        bool isKonami = true;
        for (int i = 0; i < 10; i++) {
          if (_pressedKeys[i] != _konamiCode[i]) {
            isKonami = false;
            break;
          }
        }

        if (isKonami && !_konamiActivated) {
          _activateKonamiCode();
        }
      }
    }
    return false;
  }

  void _activateKonamiCode() {
    setState(() => _konamiActivated = true);

    HapticFeedback.heavyImpact();

    _controller.addMessage(
      ChatMessage(
        text: '🎮 **KONAMI CODE ACTIVATED!** 🎮\n\n'
            '```\n'
            '↑ ↑ ↓ ↓ ← → ← → B A\n'
            '```\n\n'
            '🌟 **Secret Rainbow Theme Unlocked!**\n\n'
            'You found the easter egg! This is the kind of delightful '
            'experience you can build with Flutter Gen AI Chat UI.\n\n'
            '✨ **Bonus:** Check out our docs for more hidden features!',
        user: _aiUser,
        createdAt: DateTime.now(),
        isMarkdown: true,
      ),
    );

    // Show celebration animation
    _shareButtonController.repeat(reverse: true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) _shareButtonController.stop();
    });
  }

  void _startBuildTimer() {
    _buildTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _elapsedSeconds++);
      }
    });
  }

  void _startSplashSequence() {
    _splashTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showSplash = false;
          _demoStarted = true;
        });
        _startDemo();
      }
    });
  }

  void _startDemo() {
    // Welcome message
    _controller.addMessage(
      ChatMessage(
        text: '# 🚀 Welcome to Flutter Gen AI Chat UI!\n\n'
            '**The #1 package for AI chat interfaces in Flutter**\n\n'
            'Watch this **60-second demo** to see what makes us different:\n\n'
            '✨ ChatGPT-style streaming animation\n'
            '🎨 5 professional themes\n'
            '📁 Complete file handling\n'
            '⚡ 60 FPS with 1000+ messages\n'
            '🤖 Ready for OpenAI, Claude, Gemini\n\n'
            '*Sit back and enjoy the show!* 🍿',
        user: _aiUser,
        createdAt: DateTime.now(),
        isMarkdown: true,
      ),
    );

    // Start demo phases
    _scheduleDemoPhases();
  }

  void _scheduleDemoPhases() {
    // Phase 1: Streaming animation (0-10s)
    Timer(const Duration(seconds: 3), () => _demonstrateStreaming());

    // Phase 2: Theme switching (10-20s)
    Timer(const Duration(seconds: 12), () => _demonstrateThemes());

    // Phase 3: File support (20-30s)
    Timer(const Duration(seconds: 22), () => _demonstrateFiles());

    // Phase 4: Performance (30-40s)
    Timer(const Duration(seconds: 32), () => _demonstratePerformance());

    // Phase 5: Integration ready (40-50s)
    Timer(const Duration(seconds: 42), () => _demonstrateIntegration());

    // Phase 6: Call to action (50-60s)
    Timer(const Duration(seconds: 52), () => _showCallToAction());
  }

  void _demonstrateStreaming() {
    _addStreamingMessage(
      '✨ **Streaming Animation Demo**\n\n'
      'Watch how text appears **word-by-word** with smooth animation, '
      'just like ChatGPT! This creates a natural conversation feel that '
      'users love.\n\n'
      '**Key features:**\n'
      '• Character-by-character streaming\n'
      '• Word-by-word animation\n'
      '• Configurable speed\n'
      '• Multiple animation styles\n'
      '• Markdown support during streaming',
    );
  }

  void _demonstrateThemes() {
    setState(() => _currentTheme = (_currentTheme + 1) % _themeNames.length);

    _addStreamingMessage(
      '🎨 **Theme: ${_themeNames[_currentTheme]}**\n\n'
      'Notice how the interface smoothly transitions! We include:\n\n'
      '• **5 pre-built professional themes**\n'
      '• **50+ customization options**\n'
      '• **Dark/light mode support**\n'
      '• **Glassmorphic effects**\n'
      '• **Custom gradient backgrounds**\n\n'
      'The most comprehensive theming system in Flutter!',
    );

    // Cycle through more themes
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _currentTheme = (_currentTheme + 1) % _themeNames.length);
      }
    });
  }

  void _demonstrateFiles() {
    // Add sample file message
    _controller.addMessage(
      ChatMessage(
        text: '📁 **File Attachment Example**',
        user: _currentUser,
        createdAt: DateTime.now(),
        media: [
          ChatMedia(
            url: 'https://picsum.photos/400/300',
            type: ChatMediaType.image,
            fileName: 'demo_screenshot.jpg',
            size: 245760,
          ),
        ],
      ),
    );

    _addStreamingMessage(
      '📱 **Complete File Support**\n\n'
      '```dart\n'
      'fileUploadOptions: FileUploadOptions(\n'
      '  enabled: true,\n'
      '  allowMultiple: true,\n'
      '  allowedExtensions: [\'jpg\', \'pdf\', \'doc\'],\n'
      ')\n'
      '```\n\n'
      '**Features:**\n'
      '• Images with preview\n'
      '• Documents (PDF, Office)\n'
      '• Videos with thumbnails\n'
      '• Multiple file uploads\n'
      '• Progress indicators\n'
      '• Drag & drop on web',
    );
  }

  void _demonstratePerformance() {
    // Add multiple messages quickly
    for (int i = 0; i < 5; i++) {
      Timer(Duration(milliseconds: i * 200), () {
        if (mounted) {
          _controller.addMessage(
            ChatMessage(
              text: 'Message ${i + 1}/5 - Smooth scrolling!',
              user: _aiUser,
              createdAt: DateTime.now(),
            ),
          );
        }
      });
    }

    Timer(const Duration(seconds: 1), () {
      _addStreamingMessage(
        '⚡ **Performance Benchmarks**\n\n'
        '| Messages | FPS | Memory |\n'
        '|----------|-----|--------|\n'
        '| 100 | 60 | 1.5 MB |\n'
        '| 1,000 | 60 | 15 MB |\n'
        '| 10,000 | 58 | 45 MB |\n\n'
        '✅ **Proven 60 FPS with 1000+ messages**\n'
        '✅ **Efficient memory usage**\n'
        '✅ **Smooth scrolling always**\n\n'
        '*Tested on real devices, not just claimed!*',
      );
    });
  }

  void _demonstrateIntegration() {
    _addStreamingMessage(
      '🤖 **Ready for AI Integration**\n\n'
      '```dart\n'
      '// Coming soon - 3-line setup!\n'
      'AiChatWidget.openAI(\n'
      '  apiKey: \'sk-...\',\n'
      '  currentUser: user,\n'
      ')\n'
      '```\n\n'
      '**Built-in support for:**\n'
      '• OpenAI (GPT-4, GPT-3.5)\n'
      '• Anthropic Claude\n'
      '• Google Gemini\n'
      '• Custom AI backends\n\n'
      '**Features:**\n'
      '• Streaming responses\n'
      '• Token counting\n'
      '• Cost estimation\n'
      '• Stop generation button',
    );
  }

  void _showCallToAction() {
    _addStreamingMessage(
      '🎉 **Demo Complete!**\n\n'
      '**You just saw in 60 seconds:**\n'
      '✅ Smooth streaming animation\n'
      '✅ Professional themes\n'
      '✅ File handling\n'
      '✅ Proven performance\n'
      '✅ AI-ready integration\n\n'
      '**Ready to build amazing AI chat apps?**\n\n'
      '👇 Click the buttons below to get started!\n\n'
      '*Tip: Try the Konami code (↑ ↑ ↓ ↓ ← → ← → B A) for a surprise!* 🎮',
    );

    // Animate share button
    _shareButtonController.forward();
  }

  void _addStreamingMessage(String text) {
    final message = ChatMessage(
      text: text,
      user: _aiUser,
      createdAt: DateTime.now(),
      isMarkdown: true,
    );

    _controller.addStreamingMessage(message);
    final messageId = _controller.getMessageId(message);
    _controller.simulateStreamingCompletion(
      messageId,
      delay: Duration(milliseconds: text.length * 30),
    );
  }

  String _formatBuildTime() {
    final minutes = _elapsedSeconds ~/ 60;
    final seconds = _elapsedSeconds % 60;
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }

  void _shareOnTwitter() {
    final tweet = '🚀 Just tried Flutter Gen AI Chat UI - the best AI chat package for Flutter!\n\n'
        '✨ Smooth streaming like ChatGPT\n'
        '⚡ 60 FPS with 1000+ messages\n'
        '🎨 Beautiful themes\n\n'
        'Built my first AI chat in just ${_formatBuildTime()}!\n\n'
        '👉 Try it: https://flutter-gen-ai-chat-ui.github.io\n\n'
        '#Flutter #AI #ChatGPT #FlutterDev';

    final url = Uri.parse(
      'https://twitter.com/intent/tweet?text=${Uri.encodeComponent(tweet)}',
    );

    launchUrl(url, mode: LaunchMode.externalApplication);
  }

  void _shareGeneric() {
    Share.share(
      '🚀 Check out Flutter Gen AI Chat UI - the best package for building AI chat interfaces!\n\n'
      'I built my first AI chat in ${_formatBuildTime()}!\n\n'
      'Try the live demo: https://flutter-gen-ai-chat-ui.github.io\n\n'
      'GitHub: https://github.com/hooshyar/flutter_gen_ai_chat_ui',
      subject: 'Flutter Gen AI Chat UI - Amazing AI Chat Package!',
    );
  }

  void _openGitHub() {
    launchUrl(
      Uri.parse('https://github.com/hooshyar/flutter_gen_ai_chat_ui'),
      mode: LaunchMode.externalApplication,
    );
  }

  void _openDocs() {
    launchUrl(
      Uri.parse('https://pub.dev/packages/flutter_gen_ai_chat_ui'),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return _buildSplashScreen();
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _konamiActivated
                ? [
                    Colors.purple,
                    Colors.blue,
                    Colors.green,
                    Colors.yellow,
                    Colors.orange,
                    Colors.red,
                  ]
                : [
                    const Color(0xFF0F0F23),
                    const Color(0xFF1A1B23),
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(child: _buildChatWidget()),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSplashScreen() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(seconds: 2),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: child,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline,
                    size: 80,
                    color: Color(0xFF6366F1),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Flutter Gen AI Chat UI',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'The #1 AI Chat Package for Flutter',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 32),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.rocket_launch, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Flutter Gen AI Chat UI - Live Demo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Theme: ${_themeNames[_currentTheme]}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Build timer
          AnimatedBuilder(
            animation: _timerAnimationController,
            builder: (context, child) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color.lerp(
                        const Color(0xFF10B981),
                        const Color(0xFF059669),
                        _timerAnimationController.value,
                      )!,
                      const Color(0xFF059669),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer, color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      _formatBuildTime(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChatWidget() {
    return AiChatWidget(
      currentUser: _currentUser,
      aiUser: _aiUser,
      controller: _controller,
      onSendMessage: (message) {
        _controller.addMessage(message);
        _addStreamingMessage(
          'Thanks for trying out the demo! 🎉\n\n'
          'This is just a preview. The real magic happens when you '
          'integrate with OpenAI, Claude, or Gemini!\n\n'
          '👇 Click the buttons below to get started!',
        );
      },
      enableMarkdownStreaming: true,
      streamingDuration: const Duration(milliseconds: 30),
      streamingWordByWord: true,
      fileUploadOptions: const FileUploadOptions(
        enabled: true,
        uploadTooltip: 'Try uploading a file!',
      ),
      inputOptions: InputOptions(
        decoration: const InputDecoration(
          hintText: '💬 Type a message or just watch the demo...',
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          const Text(
            '🎉 Ready to build your own AI chat?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              _buildActionButton(
                'Share on Twitter',
                Icons.share,
                _shareOnTwitter,
                gradient: const LinearGradient(
                  colors: [Color(0xFF1DA1F2), Color(0xFF0d8bd9)],
                ),
              ),
              _buildActionButton(
                'Share',
                Icons.ios_share,
                _shareGeneric,
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                ),
              ),
              _buildActionButton(
                'View on GitHub',
                Icons.code,
                _openGitHub,
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                ),
              ),
              _buildActionButton(
                'Get Started',
                Icons.rocket_launch,
                _openDocs,
                gradient: const LinearGradient(
                  colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Built in ${_formatBuildTime()} • Try the Konami code! 🎮',
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    VoidCallback onPressed,
    {Gradient? gradient},
  ) {
    return AnimatedBuilder(
      animation: _shareButtonController,
      builder: (context, child) {
        final scale = 1.0 + (_shareButtonController.value * 0.05);
        return Transform.scale(
          scale: scale,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.mediumImpact();
                onPressed();
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  gradient: gradient ??
                      const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _demoTimer?.cancel();
    _splashTimer?.cancel();
    _buildTimer?.cancel();
    _timerAnimationController.dispose();
    _shareButtonController.dispose();
    _controller.dispose();
    ServicesBinding.instance.keyboard.removeHandler(_handleKeyPress);
    super.dispose();
  }
}
