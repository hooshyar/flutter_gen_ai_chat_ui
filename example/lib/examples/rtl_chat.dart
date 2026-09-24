// RTL Chat — Arabic / Kurdish / Hebrew streaming with auto bidi rendering.
//
// What this screen demonstrates:
//
//   1. Wrapping the chat in `Directionality(textDirection: TextDirection.rtl)`
//      so the input row, send button, and scroll mirror to the right edge.
//      Bubble columns keep fixed sides (user right, AI left) — it is the
//      per-message direction detection in point 2 that adapts each bubble's
//      text.
//   2. Per-message bidirectional rendering — the package auto-detects the
//      text direction of every message from its content (Arabic chars →
//      RTL bubble, English chars → LTR bubble) so a mixed conversation
//      lays out correctly without any extra config.
//   3. Word-by-word streaming on Arabic prose. `flutter_streaming_text_markdown`
//      1.7.0 (shipped with package 2.11.x) fixed Arabic word-splitting so the
//      stream animates by whole words, not by code points.
//
// Real apps usually wrap the whole MaterialApp in a Directionality based on
// the user's locale rather than per-screen. The wrap here is just to keep
// the example self-contained.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';

class RtlChatExample extends StatefulWidget {
  const RtlChatExample({super.key});

  @override
  State<RtlChatExample> createState() => _RtlChatExampleState();
}

class _RtlChatExampleState extends State<RtlChatExample> {
  final _controller = ChatMessagesController();
  bool _isLoading = false;
  StreamSubscription<String>? _streamSub;
  String? _currentStreamingId;

  static const _currentUser = ChatUser(id: 'user', name: 'أنت');
  static const _aiUser = ChatUser(id: 'ai', name: 'المساعد');

  void _onSendMessage(ChatMessage message) {
    _controller.addMessage(message);
    _streamSub?.cancel();
    setState(() => _isLoading = true);

    final messageId = 'ai_${DateTime.now().millisecondsSinceEpoch}';
    _currentStreamingId = messageId;
    final aiMessage = ChatMessage(
      text: '',
      user: _aiUser,
      createdAt: DateTime.now(),
      isMarkdown: true,
      customProperties: {'id': messageId},
    );

    // The AI bubble is only added once the first chunk arrives — until then
    // the LoadingWidget alone signals that a reply is being generated.
    var receivedFirstChunk = false;
    _streamSub = _streamArabicResponse(message.text).listen(
      (accumulated) {
        if (!mounted) return;
        if (receivedFirstChunk) {
          _controller.updateMessage(aiMessage.copyWith(text: accumulated));
        } else {
          receivedFirstChunk = true;
          _controller
              .addStreamingMessage(aiMessage.copyWith(text: accumulated));
        }
      },
      onDone: () {
        if (!mounted) return;
        _controller.stopStreamingMessage(messageId);
        setState(() => _isLoading = false);
      },
      onError: (_) {
        if (!mounted) return;
        _controller.stopStreamingMessage(messageId);
        setState(() => _isLoading = false);
      },
    );
  }

  // Cancels the in-flight response. Wired to AiChatWidget.onCancelGenerating,
  // which surfaces a stop button in the input while _isLoading is true.
  void _onCancelGenerating() {
    _streamSub?.cancel();
    _streamSub = null;
    final id = _currentStreamingId;
    if (id != null) {
      _controller.stopStreamingMessage(id);
    }
    setState(() => _isLoading = false);
  }

  /// Mock streaming response. Picks a canned reply based on the query, then
  /// yields it word-by-word so the streaming animation has something to chew.
  Stream<String> _streamArabicResponse(String query) async* {
    await Future<void>.delayed(const Duration(milliseconds: 400));

    final lower = query.toLowerCase();
    String reply;

    if (query.contains('عاصمة') || query.contains('العراق')) {
      reply = '## عاصمة العراق\n\n'
          'عاصمة جمهورية **العراق** هي مدينة **بغداد**، '
          'الواقعة على ضفاف نهر دجلة في وسط البلاد. '
          'تأسست في القرن الثامن الميلادي على يد الخليفة العباسي '
          'أبي جعفر المنصور، وكانت في عصرها الذهبي مركزًا للعلم '
          'والثقافة في العالم الإسلامي.';
    } else if (query.contains('قصيدة') || query.contains('اكتب')) {
      reply = '## قصيدة قصيرة\n\n'
          '> في صمتِ الليلِ تكلّمتُ مع النجمِ،\n'
          '> فقال: لا تخفْ، فالفجرُ قريب.\n'
          '> قلتُ: ومن لي بالصبرِ حتى أراهُ؟\n'
          '> فهمسَ: قلبٌ صادقٌ، ودربٌ طويل.\n\n'
          '_تمّت._';
    } else if (query.contains('كود') || lower.contains('dart')) {
      // Code fences stay LTR inside the RTL bubble — CodeBlockView forces
      // TextDirection.ltr on the block itself, so nothing extra is needed.
      reply = '## مثال بلغة Dart\n\n'
          'إليك دالة بسيطة بلغة **Dart**. لاحظ أن الكتلة البرمجية تبقى '
          'باتجاه اليسار إلى اليمين حتى داخل فقاعة عربية:\n\n'
          '```dart\n'
          'int add(int a, int b) => a + b;\n'
          '\n'
          'void main() {\n'
          '  print(add(2, 3)); // 5\n'
          '}\n'
          '```\n\n'
          'النص العربي يعود إلى اتجاهه الطبيعي بعد انتهاء الكود.';
    } else if (query.contains('Flutter') ||
        lower.contains('flutter') ||
        lower.contains('what')) {
      // Mixed-direction reply — package auto-detects per-message direction
      // so this bubble will render as LTR even though the surrounding UI
      // is RTL.
      reply = '**Flutter** is Google\'s cross-platform UI toolkit. '
          'It compiles to native code on Android, iOS, web, '
          'macOS, Windows and Linux from a single Dart codebase.';
    } else {
      reply = 'سؤال رائع! في تطبيق حقيقي، سيقوم نموذج اللغة الخاص بك '
          '(مثل **GPT** أو **Claude** أو **Gemini**) بإنشاء رد هنا. '
          'هذا مجرد عرض توضيحي يوضّح كيف تتدفّق الكلمات العربية '
          'كلمةً كلمة، مع دعم كامل للـ markdown.';
    }

    final words = reply.split(' ');
    var accumulated = '';
    for (final word in words) {
      accumulated += (accumulated.isEmpty ? '' : ' ') + word;
      yield accumulated;
      await Future<void>.delayed(const Duration(milliseconds: 22));
    }
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Wrap the screen in RTL Directionality. In a real app, drive this
    // from your locale (e.g. `Directionality(textDirection: Localizations.of(...))`).
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('RTL Chat (عربي)')),
        body: AiChatWidget(
          maxWidth: 720,
          currentUser: _currentUser,
          aiUser: _aiUser,
          controller: _controller,
          onSendMessage: _onSendMessage,
          enableMarkdownStreaming: true,
          streamingWordByWord: true,
          // The fixed-height persistent strip clips the last chip row and
          // covers the top of the message list.
          persistentExampleQuestions: false,
          // Surfaces a stop button in the input while generating; tapping it
          // cancels the stream and finalizes the partial message.
          onCancelGenerating: _onCancelGenerating,
          loadingConfig: LoadingConfig(
            isLoading: _isLoading,
            loadingIndicator: LoadingWidget(
              texts: const ['جارٍ التفكير...', 'لحظة من فضلك...'],
              textStyle: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
              ),
              shimmerBaseColor: isDark ? Colors.white38 : Colors.black45,
              shimmerHighlightColor: isDark ? Colors.white : Colors.black87,
            ),
          ),
          welcomeMessageConfig: WelcomeMessageConfig(
            centerVertically: true,
            title: 'أهلاً وسهلاً 👋',
            titleStyle: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black87,
            ),
            containerDecoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A2A3A) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color:
                    isDark ? const Color(0xFF2A2A3A) : const Color(0xFFE5E7EB),
              ),
            ),
            questionsSectionTitle: 'جرّب أن تسأل:',
            questionsSectionTitleStyle: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
          exampleQuestions: const [
            ExampleQuestion(question: 'ما هي عاصمة العراق؟'),
            ExampleQuestion(question: 'اكتب لي قصيدة قصيرة'),
            // U+200E LRM keeps this Latin question's trailing "?" on the
            // correct side inside an RTL chip.
            ExampleQuestion(question: '‎What is Flutter?'),
            // Arabic answer containing a ```dart block — the code stays
            // LTR inside the RTL bubble.
            ExampleQuestion(question: 'أرني مثالاً على كود Dart'),
          ],
          inputOptions: InputOptions(
            decoration: InputDecoration(
              hintText: 'اكتب رسالتك...',
              hintStyle: TextStyle(
                color: isDark ? Colors.white38 : Colors.black38,
                fontSize: 15,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor:
                  isDark ? const Color(0xFF2A2A3A) : const Color(0xFFF2F2F7),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            sendButtonIcon: Icons.arrow_upward_rounded,
            sendButtonColor: const Color(0xFF6366F1),
            sendButtonIconSize: 20,
            sendButtonPadding: const EdgeInsets.all(6),
            textStyle: TextStyle(
              fontSize: 15,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          messageOptions: MessageOptions(
            showCopyButton: true,
            copyButtonLabel: 'نسخ',
            copiedToClipboardText: 'تم نسخ الرسالة',
            showTime: true,
            // Localized relative timestamp instead of the default "Just now".
            timeFormat: (dt) {
              final mins = DateTime.now().difference(dt).inMinutes;
              if (mins < 1) return 'الآن';
              if (mins < 60) return 'قبل $mins دقيقة';
              final hrs = mins ~/ 60;
              return 'قبل $hrs ساعة';
            },
            bubbleStyle: BubbleStyle(
              userBubbleColor:
                  isDark ? const Color(0xFF4338CA) : const Color(0xFF6366F1),
              aiBubbleColor:
                  isDark ? const Color(0xFF2A2A3A) : const Color(0xFFF5F5FF),
              // White on the coloured user bubble; light indigo keeps the
              // AI name legible on dark AI bubbles.
              userNameColor: Colors.white70,
              aiNameColor: isDark ? Colors.white70 : const Color(0xFF6366F1),
              userBubbleTopLeftRadius: 18,
              userBubbleTopRightRadius: 18,
              aiBubbleTopLeftRadius: 18,
              aiBubbleTopRightRadius: 18,
              bottomLeftRadius: 18,
              bottomRightRadius: 4,
            ),
            userTextColor: Colors.white,
            aiTextColor:
                isDark ? Colors.white.withValues(alpha: 0.95) : Colors.black87,
            userTimeTextStyle: const TextStyle(
              fontSize: 11,
              letterSpacing: 0.1,
              color: Colors.white70,
            ),
          ),
        ),
      ),
    );
  }
}
