// RTL Chat - Arabic / Sorani Kurdish streaming with auto bidi rendering.
//
// What this screen demonstrates:
//
//   1. Wrapping the chat in `Directionality(textDirection: TextDirection.rtl)`
//      so the input row, send button, and scroll mirror to the right edge.
//      Bubble columns keep fixed sides (user right, AI left) - it is the
//      per-message direction detection in point 2 that adapts each bubble's
//      text.
//   2. Per-message bidirectional rendering - the package auto-detects the
//      text direction of every message from its content (Arabic/Kurdic
//      chars -> RTL bubble, English chars -> LTR bubble) so a mixed
//      conversation lays out correctly without any extra config.
//   3. Word-by-word streaming on Arabic/Sorani prose, and `Vazirmatn`
//      (DESIGN.md 3) as the text theme for far better Arabic/Kurdish
//      rhythm than the default font.
//
// Real apps usually wrap the whole MaterialApp in a Directionality based on
// the user's locale rather than per-screen. The wrap here is just to keep
// the example self-contained.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';
import 'package:google_fonts/google_fonts.dart';

import '../shell/demo_scaffold.dart';

class RtlChatExample extends StatefulWidget {
  const RtlChatExample({super.key, required this.onToggleTheme});

  final VoidCallback onToggleTheme;

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
    // Finalize whatever the previous stream left open before starting a new
    // one - cancelling the subscription alone doesn't close the message, so
    // without this a fast second send leaves the prior reply stuck with a
    // permanent caret and no Copy button.
    final prevId = _currentStreamingId;
    if (prevId != null) {
      _controller.stopStreamingMessage(prevId);
    }
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

    // The AI bubble is only added once the first chunk arrives - until then
    // the LoadingWidget alone signals that a reply is being generated.
    var receivedFirstChunk = false;
    _streamSub = _streamResponse(message.text).listen(
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
  Stream<String> _streamResponse(String query) async* {
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
    } else if (query.contains('پایتەخت') || query.contains('کوردستان')) {
      // Sorani Kurdish prompt: "What is the capital of Kurdistan Region?"
      reply = '## پایتەختی هەرێمی کوردستان\n\n'
          'پایتەختی هەرێمی کوردستان شاری **هەولێر**ە، کە یەکێکە لە '
          'کۆنترین شارە ژیراوەکانی جیهان و ماوەیەکی زیاتر لە هەشت '
          'هەزار ساڵە ژیانی تێدا بەردەوامە.';
    } else if (query.contains('قصيدة') || query.contains('اكتب')) {
      reply = '## قصيدة قصيرة\n\n'
          '> في صمتِ الليلِ تكلّمتُ مع النجمِ،\n'
          '> فقال: لا تخفْ، فالفجرُ قريب.\n'
          '> قلتُ: ومن لي بالصبرِ حتى أراهُ؟\n'
          '> فهمسَ: قلبٌ صادقٌ، ودربٌ طويل.\n\n'
          '_تمّت._';
    } else if (query.contains('كود') || lower.contains('dart')) {
      // Code fences stay LTR inside the RTL bubble - CodeBlockView forces
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
      // Mixed-direction reply - package auto-detects per-message direction
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
    final baseTheme = Theme.of(context);

    // The home page promises a "mirrored layout" for this demo, so the whole
    // scaffold - sidebar, top bar, back arrow, trailing actions - mirrors to
    // RTL, not just the chat surface. A real app would normally drive this
    // from the active locale at the MaterialApp root rather than per-screen;
    // wrapping the scaffold here keeps the example self-contained.
    return Directionality(
      textDirection: TextDirection.rtl,
      child: DemoScaffold(
        title: 'RTL',
        route: '/rtl',
        isDark: isDark,
        onToggleTheme: widget.onToggleTheme,
        body: Theme(
          data: baseTheme.copyWith(
            textTheme: GoogleFonts.vazirmatnTextTheme(baseTheme.textTheme),
          ),
          child: AiChatWidget(
            currentUser: _currentUser,
            aiUser: _aiUser,
            controller: _controller,
            onSendMessage: _onSendMessage,
            enableMarkdownStreaming: true,
            streamingWordByWord: true,
            // The fixed-height persistent strip clips the last chip row and
            // covers the top of the message list.
            persistentExampleQuestions: false,
            // Surfaces a stop button in the input while generating; tapping
            // it cancels the stream and finalizes the partial message.
            onCancelGenerating: _onCancelGenerating,
            // The default "Message..." hint reverses to "...Message" once
            // the composer sits in an RTL context - give this demo a
            // localized, direction-correct hint instead.
            inputOptions: const InputOptions(
              decoration: InputDecoration(
                hintText: 'اكتب رسالة...',
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsetsDirectional.fromSTEB(16, 12, 8, 12),
              ),
            ),
            loadingConfig: LoadingConfig(
              isLoading: _isLoading,
              loadingIndicator: const LoadingWidget(
                texts: ['جارٍ التفكير...', 'لحظة من فضلك...'],
              ),
            ),
            welcomeMessageConfig: const WelcomeMessageConfig(
              title: 'أهلاً وسهلاً',
              questionsSectionTitle: 'جرّب أن تسأل:',
            ),
            exampleQuestions: const [
              ExampleQuestion(question: 'ما هي عاصمة العراق؟'),
              ExampleQuestion(question: 'پایتەختی هەرێمی کوردستان کوێیە؟'),
              ExampleQuestion(question: 'اكتب لي قصيدة قصيرة'),
              // U+200E LRM markers on both ends keep this Latin question's
              // trailing "?" from being pulled to the visual start inside
              // an RTL chip (a single leading LRM isn't enough - the "?" at
              // the edge of the string still picks up the RTL paragraph
              // direction without one after it too).
              ExampleQuestion(question: '‎What is Flutter?‎'),
              // Arabic answer containing a ```dart block - the code stays
              // LTR inside the RTL bubble.
              ExampleQuestion(question: 'أرني مثالاً على كود Dart'),
            ],
            // No `timeFormat` here: setting one, combined with `showTime`,
            // also opts the user bubble into a timestamp (an explicit
            // formatter is read as "yes, render this somewhere") - the
            // English demos never show a user timestamp, so this stays on
            // the package's default AI-only formatting to match them.
            messageOptions: const MessageOptions(
              showCopyButton: true,
              copyButtonLabel: 'نسخ',
              copiedToClipboardText: 'تم نسخ الرسالة',
              showTime: true,
            ),
          ),
        ),
      ),
    );
  }
}
