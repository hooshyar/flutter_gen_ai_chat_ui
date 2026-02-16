import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';
import '../example_configs.dart';
class ThemesExample extends StatefulWidget {
  final bool isDark;
  const ThemesExample({super.key, required this.isDark});

  @override
  State<ThemesExample> createState() => _ThemesExampleState();
}

class _ThemesExampleState extends State<ThemesExample> {
  final _controller = ChatMessagesController();
  final _random = Random();
  bool _isLoading = false;
  ThemePreset _themePreset = ThemePreset.minimal;

  static const _currentUser = ChatUser(id: 'user', firstName: 'You');
  static const _aiUser = ChatUser(id: 'ai', firstName: 'Assistant');

  @override
  void initState() {
    super.initState();
    _controller.addMessage(ChatMessage(
      text: "Send a message, then try switching themes above to see how the bubbles change.",
      user: _aiUser,
      createdAt: DateTime.now(),
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSend(ChatMessage message) async {
    if (_isLoading) return;
    _controller.addMessage(message);
    setState(() => _isLoading = true);

    await Future.delayed(Duration(milliseconds: 400 + _random.nextInt(600)));

    _controller.addMessage(ChatMessage(
      text:
          "That looks great with the **${_themePreset.label}** theme! Try switching to a different style to see how the bubbles, shadows, and border radius change.",
      user: _aiUser,
      createdAt: DateTime.now(),
      isMarkdown: true,
    ));
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final bubbleStyle = getBubbleStyleForPreset(_themePreset, isDark, context);
    final isNeon = _themePreset == ThemePreset.neon;

    return Column(
      children: [
        // Theme picker bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF222222) : const Color(0xFFF5F5F5),
            border: Border(
              bottom: BorderSide(
                color:
                    isDark ? const Color(0xFF333333) : const Color(0xFFE0E0E0),
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
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ThemePreset.values.map((preset) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(preset.label,
                              style: const TextStyle(fontSize: 12)),
                          selected: preset == _themePreset,
                          onSelected: (_) =>
                              setState(() => _themePreset = preset),
                          visualDensity: VisualDensity.compact,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: AiChatWidget(
            currentUser: _currentUser,
            aiUser: _aiUser,
            controller: _controller,
            onSendMessage: _handleSend,
            maxWidth: 700,
            welcomeMessageConfig: const WelcomeMessageConfig(
              title: '🎨 Theme Showcase',
              questionsSectionTitle: 'Pick a theme above, then try:',
            ),
            exampleQuestions: const [
              ExampleQuestion(question: 'Show me this theme'),
              ExampleQuestion(question: 'What makes this style unique?'),
            ],
            loadingConfig: LoadingConfig(
              isLoading: _isLoading,
              loadingIndicator: LoadingWidget(
                texts: const ['Thinking...'],
                shimmerBaseColor: isDark ? Colors.grey[700] : Colors.grey[300],
                shimmerHighlightColor:
                    isDark ? Colors.grey[600] : Colors.grey[100],
              ),
            ),
            inputOptions: InputOptions(
              unfocusOnTapOutside: false,
              sendOnEnter: true,
              maxLines: 4,
              minLines: 1,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFD0D0D0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFD0D0D0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: isDark ? Colors.indigoAccent : Colors.indigo, width: 1.5),
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF262626) : const Color(0xFFF8F8F8),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              textStyle: TextStyle(fontSize: 14, color: isDark ? Colors.white : Colors.black87),
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
              containerMargin:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              bubbleStyle: bubbleStyle,
              userTextColor: isNeon ? Colors.white : (isDark ? Colors.white : Colors.black87),
              aiTextColor: isNeon ? Colors.white : (isDark ? Colors.white : Colors.black87),
              textStyle: const TextStyle(fontSize: 14, height: 1.5),
            ),
            enableAnimation: true,
          ),
        ),
      ],
    );
  }
}
