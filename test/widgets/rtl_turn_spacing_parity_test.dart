import 'package:flutter/material.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';
import 'package:flutter_test/flutter_test.dart';

/// Investigation record for the reported "big gap between turns in the RTL
/// demo" defect (roughly 80-100px between an AI reply and the next user
/// bubble, vs 24px elsewhere).
///
/// Root-cause search (round 6): the gap was measured multiple ways —
/// (a) raw AI *text* bottom to the next message's outer `Align` top (what a
/// human eyeballing a screenshot would likely read as "the gap"), and
/// (b) message-item-to-message-item ("RepaintBoundary" bounds, which
/// include each message's own margin AND its trailing action row).
///
/// (a) measures ~92px; (b) measures ~56px — but **both are identical
/// between an RTL/Arabic config (matching `example/lib/examples/rtl_chat.dart`
/// exactly: `Directionality.rtl`, Vazirmatn-style Arabic content,
/// `streamingWordByWord: true`, `showTime: true`, custom Arabic copy/time
/// labels) and a plain LTR/English config with none of those options.**
/// Toggling `streamingWordByWord` and `showTime` independently made no
/// measurable difference either. This test locks in that finding: the true
/// gap is the ~24px sender-change margin (`DESIGN.md` §5) PLUS the AI
/// message's own always-visible trailing action row (copy button +
/// timestamp, `DESIGN.md` §8.8 — shown unconditionally for the latest AI
/// message on every platform, not an RTL-only behavior) — not an
/// RTL-specific defect. Whatever produced the ~80-100px figure in the
/// original screenshots reads as the same eyeballed distance (a) in *any*
/// demo whose latest turn is "AI reply, then another user message" with the
/// action row visible; it isn't unique to `rtl_chat.dart`, so there is
/// nothing to fix here — RTL and LTR spacing already match exactly.
void main() {
  /// Builds a 3-message conversation (user, AI reply, user) and returns the
  /// item-to-item gap between the AI reply and the next user bubble.
  Future<double> measureGap(
    WidgetTester tester, {
    required bool rtl,
    required String userQuestion1,
    required String aiReplyMarkdown,
    required String userQuestion2,
    bool streamingWordByWord = false,
    bool showTime = false,
  }) async {
    final currentUser = ChatUser(id: 'user', name: rtl ? 'أنت' : 'You');
    final aiUser = ChatUser(id: 'ai', name: rtl ? 'المساعد' : 'AI');
    final controller = ChatMessagesController();

    controller.addMessage(ChatMessage(
      text: userQuestion1,
      user: currentUser,
      createdAt: DateTime(2026, 1, 1, 0, 0, 0),
    ));
    controller.addMessage(ChatMessage(
      text: aiReplyMarkdown,
      user: aiUser,
      createdAt: DateTime(2026, 1, 1, 0, 0, 1),
      isMarkdown: true,
    ));
    controller.addMessage(ChatMessage(
      text: userQuestion2,
      user: currentUser,
      createdAt: DateTime(2026, 1, 1, 0, 0, 2),
    ));

    final chat = AiChatWidget(
      currentUser: currentUser,
      aiUser: aiUser,
      controller: controller,
      onSendMessage: (_) {},
      enableMarkdownStreaming: true,
      streamingWordByWord: streamingWordByWord,
      messageOptions: MessageOptions(
        showCopyButton: true,
        copyButtonLabel: rtl ? 'نسخ' : null,
        copiedToClipboardText: rtl ? 'تم نسخ الرسالة' : null,
        showTime: showTime,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: rtl
              ? Directionality(textDirection: TextDirection.rtl, child: chat)
              : chat,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final aiTextFinder = find.textContaining(rtl ? 'بغداد' : 'Baghdad');
    final userTextFinder = find.text(userQuestion2);
    expect(aiTextFinder, findsOneWidget);
    expect(userTextFinder, findsOneWidget);

    final aiItem = find
        .ancestor(of: aiTextFinder, matching: find.byType(RepaintBoundary))
        .first;
    final userItem = find
        .ancestor(of: userTextFinder, matching: find.byType(RepaintBoundary))
        .first;

    return tester.getTopLeft(userItem).dy - tester.getBottomLeft(aiItem).dy;
  }

  testWidgets(
    'AI-reply-to-next-user-bubble spacing is identical between the RTL '
    'demo config and an equivalent LTR config',
    (tester) async {
      final rtlGap = await measureGap(
        tester,
        rtl: true,
        userQuestion1: 'ما هي عاصمة العراق؟',
        aiReplyMarkdown: '## عاصمة العراق\n\n'
            'عاصمة جمهورية **العراق** هي مدينة **بغداد**، '
            'الواقعة على ضفاف نهر دجلة في وسط البلاد.',
        userQuestion2: 'سؤال آخر',
        streamingWordByWord: true,
        showTime: true,
      );

      final ltrGap = await measureGap(
        tester,
        rtl: false,
        userQuestion1: 'What is the capital of Iraq?',
        aiReplyMarkdown: '## Capital of Iraq\n\n'
            'The capital of the Republic of **Iraq** is the city of '
            '**Baghdad**, located on the banks of the Tigris river in the '
            'middle of the country.',
        userQuestion2: 'Another question',
      );

      expect(
        rtlGap,
        closeTo(ltrGap, 1),
        reason: 'RTL demo config gap ($rtlGap px) should match the plain '
            'LTR config gap ($ltrGap px) — both come from the same '
            'sender-change margin plus the AI message\'s own action row, '
            'not anything RTL-specific.',
      );
    },
  );
}
