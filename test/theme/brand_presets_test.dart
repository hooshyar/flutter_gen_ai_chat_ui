// Tests for the brand theme presets (ChatGPT / Claude / Gemini), added 2.15.0
// to back the README's "ChatGPT/Claude/Gemini ready" claim with one-liners.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';

void main() {
  test('each brand preset is fully populated in light and dark', () {
    final presets = <CustomThemeExtension>[
      CustomThemeExtension.chatgpt(),
      CustomThemeExtension.chatgpt(dark: true),
      CustomThemeExtension.claude(),
      CustomThemeExtension.claude(dark: true),
      CustomThemeExtension.gemini(),
      CustomThemeExtension.gemini(dark: true),
    ];

    for (final p in presets) {
      expect(p.chatBackground, isNotNull);
      expect(p.messageBubbleColor, isNotNull);
      expect(p.userBubbleColor, isNotNull);
      expect(p.messageTextColor, isNotNull);
      expect(p.sendButtonColor, isNotNull);
      expect(p.sendButtonIconColor, isNotNull);
    }
  });

  test('light and dark variants differ', () {
    expect(CustomThemeExtension.chatgpt().chatBackground,
        isNot(CustomThemeExtension.chatgpt(dark: true).chatBackground));
    expect(CustomThemeExtension.gemini().userBubbleColor,
        isNot(CustomThemeExtension.gemini(dark: true).userBubbleColor));
  });

  test('brands are visually distinct (accent colors differ)', () {
    final accents = {
      CustomThemeExtension.chatgpt().sendButtonColor,
      CustomThemeExtension.claude().sendButtonColor,
      CustomThemeExtension.gemini().sendButtonColor,
    };
    expect(accents.length, 3);
  });

  testWidgets('a preset applies through ThemeData.extensions', (tester) async {
    final controller = ChatMessagesController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: [CustomThemeExtension.claude()],
        ),
        home: Scaffold(
          body: AiChatWidget(
            currentUser: const ChatUser(id: 'u', firstName: 'U'),
            aiUser: const ChatUser(id: 'ai', firstName: 'AI'),
            controller: controller,
            onSendMessage: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();

    final ext = Theme.of(tester.element(find.byType(AiChatWidget)))
        .extension<CustomThemeExtension>();
    expect(ext, isNotNull);
    expect(ext!.sendButtonColor, const Color(0xFFD97757));
  });
}
