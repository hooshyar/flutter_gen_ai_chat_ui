# flutter_gen_ai_chat_ui examples

Short recipes for the common cases. To see everything running (streaming,
code blocks, theme presets, RTL, attachments, voice, AI actions), open the
[live web demo](https://hooshyar.github.io/flutter_gen_ai_chat_ui/) or run
this app with `flutter pub get && flutter run` from this folder. Each screen
lives in [`lib/examples/`](lib/examples/).

```dart
import 'package:flutter/material.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';
```

## A complete chat screen

```dart
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = ChatMessagesController();
  final _user = const ChatUser(id: 'user', firstName: 'You');
  final _ai = const ChatUser(id: 'ai', firstName: 'Assistant');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onSend(ChatMessage message) async {
    _controller.addMessage(message); // show the user's message

    // A new id per reply, then grow the message as chunks arrive.
    final id = 'reply-${DateTime.now().microsecondsSinceEpoch}';
    _controller.addMessage(ChatMessage(
      text: '',
      user: _ai,
      createdAt: DateTime.now(),
      isMarkdown: true,
      customProperties: {'id': id},
    ));

    final buffer = StringBuffer();
    await for (final chunk in myLlm.stream(message.text)) {
      buffer.write(chunk);
      _controller.updateMessage(ChatMessage(
        text: buffer.toString(),
        user: _ai,
        createdAt: DateTime.now(),
        isMarkdown: true,
        customProperties: {'id': id},
      ));
    }
    _controller.stopStreamingMessage(id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AiChatWidget(
        currentUser: _user,
        aiUser: _ai,
        controller: _controller,
        onSendMessage: _onSend,
        enableMarkdownStreaming: true,
        welcomeMessageConfig: const WelcomeMessageConfig(
          title: 'How can I help?',
        ),
        exampleQuestions: const [
          ExampleQuestion(question: 'Explain this error message'),
          ExampleQuestion(question: 'Write a unit test for my function'),
        ],
      ),
    );
  }
}
```

`myLlm.stream` stands for your provider call: OpenAI, Anthropic, Gemini,
Ollama or your own backend. The
[cookbook](https://github.com/hooshyar/flutter_gen_ai_chat_ui/blob/main/doc/cookbook/README.md)
has copy-paste streaming bridges for each.

## Attachments in a one-row composer

```dart
AiChatWidget(
  // ...
  inputOptions: const InputOptions(
    composerLayout: ComposerLayout.singleRow,
  ),
  fileUploadOptions: FileUploadOptions(
    onFilesSelected: (files) { /* pick and upload */ },
    buttonPosition: AttachmentButtonPosition.trailing,
  ),
)
```

## Code blocks

Fenced code is syntax-highlighted, with a copy button. Restyle the button:

```dart
MessageOptions(
  codeBlockCopyButtonBuilder: (context, copied, onCopy) => IconButton(
    onPressed: onCopy,
    icon: Icon(copied ? Icons.check : Icons.copy_all, size: 16),
  ),
)
```

## Brand themes and RTL

```dart
MaterialApp(
  theme: ThemeData(extensions: [CustomThemeExtension.chatgpt()]),
  home: const Directionality(
    textDirection: TextDirection.rtl, // Arabic, Farsi, Kurdish, Hebrew...
    child: ChatScreen(),
  ),
)
```

## Rich widget messages

Render a full-width card instead of a text bubble, for example a tool
result:

```dart
_controller.addMessage(ChatMessage.rich(
  user: _ai,
  id: 'weather-1',
  resultKind: 'weather',
  data: {'city': 'Lisbon', 'tempC': 24},
));

AiChatWidget(
  // ...
  resultRenderers: {
    'weather': (context, data) => Text('${data['city']}: ${data['tempC']}°C'),
  },
)
```
