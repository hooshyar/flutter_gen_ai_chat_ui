import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';
import '../example_configs.dart';

class FilesExample extends StatefulWidget {
  final bool isDark;
  const FilesExample({super.key, required this.isDark});

  @override
  State<FilesExample> createState() => _FilesExampleState();
}

class _FilesExampleState extends State<FilesExample> {
  final _controller = ChatMessagesController();
  final _random = Random();
  bool _isLoading = false;

  static const _currentUser = ChatUser(id: 'user', firstName: 'You');
  static const _aiUser = ChatUser(id: 'ai', firstName: 'Atlas');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSend(ChatMessage message) async {
    if (_isLoading) return;
    _controller.addMessage(message);
    setState(() => _isLoading = true);

    await Future.delayed(Duration(milliseconds: 500 + _random.nextInt(500)));

    _controller.addMessage(ChatMessage(
      text: MockResponses.fileResponse,
      user: _aiUser,
      createdAt: DateTime.now(),
      isMarkdown: true,
    ));
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    // Files: Slack-inspired — flat design, sharp corners, left border accent
    return Column(
      children: [
        // Info banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1D21) : const Color(0xFFFFF8E1),
            border: Border(
              bottom: BorderSide(
                color: isDark ? const Color(0xFF333333) : const Color(0xFFFFE082),
              ),
              left: BorderSide(
                color: const Color(0xFFFFB300),
                width: 3,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.attach_file_rounded,
                  size: 16,
                  color: isDark ? Colors.amber[300] : Colors.amber[800]),
              const SizedBox(width: 8),
              Text(
                'File attachments are simulated in this demo',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.amber[300] : Colors.amber[900],
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
            maxWidth: 720,
            welcomeMessageConfig: WelcomeMessageConfig(
              title: 'Atlas File Assistant',
              titleStyle: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black87,
              ),
              questionsSectionTitle: 'Try these:',
            ),
            exampleQuestions: [
              ExampleQuestion(
                question: 'What file types are supported?',
      
              ),
              ExampleQuestion(
                question: 'How do uploads work?',
      
              ),
            ],
            loadingConfig: LoadingConfig(
              isLoading: _isLoading,
              typingIndicatorColor: const Color(0xFF4A154B),
              loadingIndicator: LoadingWidget(
                texts: const ['Processing...'],
                shimmerBaseColor: isDark ? Colors.grey[800] : Colors.grey[200],
                shimmerHighlightColor: isDark ? Colors.grey[700] : Colors.grey[50],
              ),
            ),
            inputOptions: InputOptions(
              unfocusOnTapOutside: false,
              sendOnEnter: true,
              maxLines: 4,
              minLines: 1,
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: InputDecoration(
                hintText: 'Message Atlas...',
                hintStyle: TextStyle(
                  color: isDark ? Colors.white30 : Colors.black26,
                  fontSize: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF555555) : const Color(0xFFCCCCCC),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF555555) : const Color(0xFFCCCCCC),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFF4A154B),
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF222529) : Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              textStyle: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white : Colors.black87,
              ),
              sendButtonBuilder: (onSend) => Padding(
                padding: const EdgeInsets.only(left: 6),
                child: IconButton(
                  onPressed: onSend,
                  icon: const Icon(Icons.send_rounded, size: 18),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF4A154B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.all(10),
                  ),
                ),
              ),
            ),
            messageOptions: MessageOptions(
              showUserName: true,
              showTime: true,
              showCopyButton: true,
              containerMargin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              bubbleStyle: BubbleStyle(
                userBubbleColor: isDark ? const Color(0xFF1264A3) : const Color(0xFFE8F5FE),
                aiBubbleColor: isDark ? const Color(0xFF1A1D21) : const Color(0xFFF8F8F8),
                userBubbleTopLeftRadius: 4,
                userBubbleTopRightRadius: 4,
                aiBubbleTopLeftRadius: 4,
                aiBubbleTopRightRadius: 4,
                bottomLeftRadius: 4,
                bottomRightRadius: 4,
                enableShadow: false,
              ),
              userTextColor: isDark ? Colors.white : const Color(0xFF1D1C1D),
              aiTextColor: isDark ? Colors.white : const Color(0xFF1D1C1D),
              textStyle: const TextStyle(fontSize: 14, height: 1.5),
            ),
            enableAnimation: true,
          ),
        ),
      ],
    );
  }
}
