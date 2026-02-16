import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';

import 'example_configs.dart';
import 'sidebar.dart';

class ShowcaseApp extends StatefulWidget {
  const ShowcaseApp({super.key});

  @override
  State<ShowcaseApp> createState() => _ShowcaseAppState();
}

class _ShowcaseAppState extends State<ShowcaseApp> {
  int _selectedIndex = 0;
  bool _isDark = false;

  // Each example gets its own controller so state persists when switching
  final Map<int, ChatMessagesController> _controllers = {};
  final _random = Random();

  final _currentUser = const ChatUser(
    id: 'user',
    firstName: 'You',
  );
  final _aiUser = const ChatUser(
    id: 'ai',
    firstName: 'Assistant',
  );

  bool _isLoading = false;

  // Theme preset for themes example
  ThemePreset _themePreset = ThemePreset.minimal;

  ChatMessagesController get _controller {
    return _controllers.putIfAbsent(_selectedIndex, () {
      final c = ChatMessagesController();
      return c;
    });
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _selectExample(int index) {
    setState(() {
      _selectedIndex = index;
      _isLoading = false;
    });
  }

  Future<void> _handleSend(ChatMessage message) async {
    if (_isLoading) return;

    final controller = _controller;
    controller.addMessage(message);
    setState(() => _isLoading = true);

    final type = examples[_selectedIndex].type;
    final delay = 400 + _random.nextInt(600);
    await Future.delayed(Duration(milliseconds: delay));

    String responseText;
    bool isMarkdown = false;
    bool shouldStream = false;

    switch (type) {
      case ExampleType.basic:
        final responses = MockResponses.basicResponses;
        responseText = responses[_random.nextInt(responses.length)];
        break;

      case ExampleType.streaming:
        final responses = MockResponses.streamingResponses;
        responseText = responses[_random.nextInt(responses.length)];
        isMarkdown = true;
        shouldStream = true;
        break;

      case ExampleType.themes:
        responseText = "That looks great with the ${_themePreset.label} theme! Try switching to a different style to see how the bubbles change.";
        break;

      case ExampleType.files:
        responseText = MockResponses.fileResponse;
        break;

      case ExampleType.complete:
        responseText = MockResponses.markdownResponse;
        isMarkdown = true;
        shouldStream = true;
        break;
    }

    setState(() => _isLoading = false);

    if (shouldStream) {
      // Stream word by word
      final messageId = 'ai_${DateTime.now().millisecondsSinceEpoch}';
      final words = responseText.split(' ');
      var accumulated = '';

      for (int i = 0; i < words.length; i++) {
        accumulated += (i == 0 ? '' : ' ') + words[i];
        final msg = ChatMessage(
          text: accumulated,
          user: _aiUser,
          createdAt: DateTime.now(),
          isMarkdown: isMarkdown,
          customProperties: {
            'id': messageId,
            'isStreaming': i < words.length - 1,
          },
        );
        if (i == 0) {
          controller.addMessage(msg);
        } else {
          controller.updateMessage(msg);
        }
        await Future.delayed(Duration(milliseconds: 30 + _random.nextInt(50)));
        if (!mounted) return;
      }
    } else {
      controller.addMessage(ChatMessage(
        text: responseText,
        user: _aiUser,
        createdAt: DateTime.now(),
        isMarkdown: isMarkdown,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = _isDark ? ThemeData.dark(useMaterial3: true) : ThemeData(useMaterial3: true);
    final effectiveTheme = theme.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.indigo,
        brightness: _isDark ? Brightness.dark : Brightness.light,
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: effectiveTheme,
      home: Builder(builder: (context) {
        final isWide = MediaQuery.of(context).size.width > 700;
        return Scaffold(
          backgroundColor: _isDark ? const Color(0xFF1A1A1A) : Colors.white,
          body: isWide
              ? Row(
                  children: [
                    ShowcaseSidebar(
                      selectedIndex: _selectedIndex,
                      onSelect: _selectExample,
                      isDark: _isDark,
                      onToggleTheme: () => setState(() => _isDark = !_isDark),
                    ),
                    Expanded(child: _buildMainArea(context)),
                  ],
                )
              : _buildMainArea(context),
          bottomNavigationBar: isWide
              ? null
              : ShowcaseBottomNav(
                  selectedIndex: _selectedIndex,
                  onSelect: _selectExample,
                ),
        );
      }),
    );
  }

  Widget _buildMainArea(BuildContext context) {
    final isDark = _isDark;
    final type = examples[_selectedIndex].type;
    final isWide = MediaQuery.of(context).size.width > 700;

    // Mobile top bar
    final topBar = !isWide
        ? AppBar(
            title: Text(examples[_selectedIndex].title),
            elevation: 0,
            actions: [
              IconButton(
                icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
                onPressed: () => setState(() => _isDark = !_isDark),
              ),
            ],
          )
        : null;

    // Theme picker for themes example
    Widget? themePickerBar;
    if (type == ExampleType.themes) {
      themePickerBar = Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF222222) : const Color(0xFFF5F5F5),
          border: Border(
            bottom: BorderSide(
              color: isDark ? const Color(0xFF333333) : const Color(0xFFE0E0E0),
            ),
          ),
        ),
        child: Row(
          children: [
            Text(
              'Theme:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(width: 12),
            ...ThemePreset.values.map((preset) {
              final isActive = preset == _themePreset;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(preset.label, style: const TextStyle(fontSize: 12)),
                  selected: isActive,
                  onSelected: (_) => setState(() => _themePreset = preset),
                  visualDensity: VisualDensity.compact,
                ),
              );
            }),
          ],
        ),
      );
    }

    // File upload bar for files example
    Widget? fileBar;
    if (type == ExampleType.files) {
      fileBar = Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF222222) : const Color(0xFFF5F5F5),
          border: Border(
            bottom: BorderSide(
              color: isDark ? const Color(0xFF333333) : const Color(0xFFE0E0E0),
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 14, color: isDark ? Colors.white54 : Colors.black45),
            const SizedBox(width: 8),
            Text(
              'File attachments are mocked in this demo',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
          ],
        ),
      );
    }

    // Build chat widget with appropriate config
    final bubbleStyle = type == ExampleType.themes
        ? getBubbleStyleForPreset(_themePreset, isDark, context)
        : BubbleStyle(
            userBubbleColor: isDark ? const Color(0xFF2D2D3D) : const Color(0xFFEEEEFF),
            aiBubbleColor: isDark ? const Color(0xFF262626) : const Color(0xFFF8F8FA),
            userBubbleTopLeftRadius: 16,
            userBubbleTopRightRadius: 16,
            aiBubbleTopLeftRadius: 16,
            aiBubbleTopRightRadius: 16,
            bottomLeftRadius: 16,
            bottomRightRadius: 16,
            enableShadow: false,
          );

    final chatWidget = AiChatWidget(
      currentUser: _currentUser,
      aiUser: _aiUser,
      controller: _controller,
      onSendMessage: _handleSend,
      maxWidth: 700,
      loadingConfig: LoadingConfig(
        isLoading: _isLoading,
        loadingIndicator: LoadingWidget(
          texts: const ['Thinking...'],
          shimmerBaseColor: isDark ? Colors.grey[700] : Colors.grey[300],
          shimmerHighlightColor: isDark ? Colors.grey[600] : Colors.grey[100],
        ),
      ),
      inputOptions: InputOptions(
        unfocusOnTapOutside: false,
        sendOnEnter: true,
        maxLines: 6,
        minLines: 1,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: InputDecoration(
          hintText: 'Type a message...',
          hintStyle: TextStyle(
            color: isDark ? Colors.white38 : Colors.black38,
            fontSize: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFD0D0D0),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFD0D0D0),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDark ? Colors.indigoAccent : Colors.indigo,
              width: 1.5,
            ),
          ),
          filled: true,
          fillColor: isDark ? const Color(0xFF262626) : const Color(0xFFF8F8F8),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        textStyle: TextStyle(
          fontSize: 14,
          color: isDark ? Colors.white : Colors.black87,
        ),
        sendButtonBuilder: (onSend) => Padding(
          padding: const EdgeInsets.only(left: 8),
          child: IconButton(
            onPressed: onSend,
            icon: const Icon(Icons.send_rounded, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ),
      messageOptions: MessageOptions(
        showUserName: false,
        showTime: true,
        showCopyButton: true,
        containerMargin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        bubbleStyle: bubbleStyle,
        userTextColor: _themePreset == ThemePreset.neon && type == ExampleType.themes
            ? Colors.white
            : (isDark ? Colors.white : Colors.black87),
        aiTextColor: _themePreset == ThemePreset.neon && type == ExampleType.themes
            ? Colors.white
            : (isDark ? Colors.white : Colors.black87),
        textStyle: const TextStyle(fontSize: 14, height: 1.5),
      ),
      enableAnimation: true,
      streamingDuration: const Duration(milliseconds: 30),
    );

    return Column(
      children: [
        if (topBar != null) PreferredSize(preferredSize: const Size.fromHeight(56), child: topBar),
        if (themePickerBar != null) themePickerBar,
        if (fileBar != null) fileBar,
        Expanded(child: chatWidget),
      ],
    );
  }
}
