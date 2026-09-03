import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';

/// Regression coverage for a real bug found during the task-002 knob sweep:
/// `Theme.of(context).extension<CustomThemeExtension>()` was never called
/// ANYWHERE in the widget tree, so setting a `CustomThemeExtension` (including
/// the README-advertised `.chatgpt()`/`.claude()`/`.gemini()` brand presets)
/// had zero visual effect — the existing `brand_presets_test.dart` only
/// checked that the extension round-tripped through `ThemeData`, not that
/// anything actually read it back out. These tests render the real widget
/// tree and assert the theme's colors actually show up.
void main() {
  const testUser = ChatUser(id: 'user', name: 'You');
  const aiUser = ChatUser(id: 'ai', name: 'Assistant');

  const ext = CustomThemeExtension(
    chatBackground: Color(0xFF111111),
    messageBubbleColor: Color(0xFF222222),
    userBubbleColor: Color(0xFF333333),
    messageTextColor: Color(0xFF444444),
    inputBackgroundColor: Color(0xFF555555),
    inputBorderColor: Color(0xFF666666),
    inputTextColor: Color(0xFF777777),
    hintTextColor: Color(0xFF888888),
    backToBottomButtonColor: Color(0xFF999999),
    sendButtonColor: Color(0xFFAAAAAA),
    sendButtonIconColor: Color(0xFFBBBBBB),
  );

  Widget wrap(Widget child) {
    return MaterialApp(
      theme: ThemeData(extensions: const [ext]),
      home: Material(child: child),
    );
  }

  bool hasBubbleWithColor(Color color) {
    return find
        .byWidgetPredicate((w) =>
            w is Container &&
            w.decoration is BoxDecoration &&
            (w.decoration! as BoxDecoration).color == color)
        .evaluate()
        .isNotEmpty;
  }

  testWidgets('chatBackground colors the overall chat surface',
      (tester) async {
    final controller = ChatMessagesController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(wrap(
      AiChatWidget(
        currentUser: testUser,
        aiUser: aiUser,
        controller: controller,
        onSendMessage: (_) async {},
      ),
    ));
    await tester.pump();

    final container = tester.widget<Container>(find
        .ancestor(
          of: find.byType(CustomChatWidget),
          matching: find.byType(Container),
        )
        .first);
    expect(container.color, ext.chatBackground);
  });

  testWidgets(
      'messageBubbleColor / userBubbleColor / messageTextColor apply to '
      'rendered bubbles', (tester) async {
    final controller = ChatMessagesController(
      initialMessages: [
        ChatMessage(
          text: 'Hi from the user',
          user: testUser,
          createdAt: DateTime.now(),
        ),
        ChatMessage(
          text: 'Hi from the AI',
          user: aiUser,
          createdAt: DateTime.now(),
        ),
      ],
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(wrap(
      AiChatWidget(
        currentUser: testUser,
        aiUser: aiUser,
        controller: controller,
        onSendMessage: (_) async {},
        enableMarkdownStreaming: false,
      ),
    ));
    await tester.pumpAndSettle();

    expect(hasBubbleWithColor(ext.userBubbleColor!), isTrue,
        reason: 'user bubble should use CustomThemeExtension.userBubbleColor');
    expect(hasBubbleWithColor(ext.messageBubbleColor!), isTrue,
        reason:
            'AI bubble should use CustomThemeExtension.messageBubbleColor');

    final userText = tester.widget<Text>(find.text('Hi from the user'));
    final aiText = tester.widget<Text>(find.text('Hi from the AI'));
    expect(userText.style?.color, ext.messageTextColor);
    expect(aiText.style?.color, ext.messageTextColor);
  });

  testWidgets(
      'explicit BubbleStyle/MessageOptions colors still take precedence '
      'over the theme extension', (tester) async {
    final controller = ChatMessagesController(
      initialMessages: [
        ChatMessage(
          text: 'Explicit color',
          user: testUser,
          createdAt: DateTime.now(),
        ),
      ],
    );
    addTearDown(controller.dispose);

    const explicitUserBubble = Color(0xFFFF00FF);
    const explicitUserText = Color(0xFF00FF00);

    await tester.pumpWidget(wrap(
      AiChatWidget(
        currentUser: testUser,
        aiUser: aiUser,
        controller: controller,
        onSendMessage: (_) async {},
        enableMarkdownStreaming: false,
        messageOptions: const MessageOptions(
          userTextColor: explicitUserText,
          bubbleStyle: BubbleStyle(userBubbleColor: explicitUserBubble),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(hasBubbleWithColor(explicitUserBubble), isTrue);
    expect(hasBubbleWithColor(ext.userBubbleColor!), isFalse);

    final text = tester.widget<Text>(find.text('Explicit color'));
    expect(text.style?.color, explicitUserText);
  });

  testWidgets('sendButtonColor applies to the default send button icon',
      (tester) async {
    final controller = ChatMessagesController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(wrap(
      AiChatWidget(
        currentUser: testUser,
        aiUser: aiUser,
        controller: controller,
        onSendMessage: (_) async {},
      ),
    ));
    await tester.pump();

    final icon = tester.widget<Icon>(find.byIcon(Icons.send));
    expect(icon.color, ext.sendButtonColor);
  });

  testWidgets('inputBackgroundColor/inputTextColor apply to the text field '
      'when no explicit decoration/style is set', (tester) async {
    final controller = ChatMessagesController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(wrap(
      AiChatWidget(
        currentUser: testUser,
        aiUser: aiUser,
        controller: controller,
        onSendMessage: (_) async {},
      ),
    ));
    await tester.pump();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.decoration?.fillColor, ext.inputBackgroundColor);
    expect(field.decoration?.filled, isTrue);
    expect(field.style?.color, ext.inputTextColor);
    expect(field.decoration?.hintStyle?.color, ext.hintTextColor);
  });

  testWidgets(
      'an explicit InputOptions.decoration/textStyle still takes '
      'precedence over the theme extension', (tester) async {
    final controller = ChatMessagesController();
    addTearDown(controller.dispose);

    const explicitStyle = TextStyle(color: Color(0xFF123456));

    await tester.pumpWidget(wrap(
      AiChatWidget(
        currentUser: testUser,
        aiUser: aiUser,
        controller: controller,
        onSendMessage: (_) async {},
        inputOptions: const InputOptions(
          textStyle: explicitStyle,
          decoration: InputDecoration(hintText: 'Type...'),
        ),
      ),
    ));
    await tester.pump();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.style?.color, explicitStyle.color);
    expect(field.decoration?.fillColor, isNull);
  });
}
