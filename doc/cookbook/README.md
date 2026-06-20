# Cookbook

Task-focused recipes for `flutter_gen_ai_chat_ui`. Each one is distilled from a
real question in the issue tracker. All snippets use the current public API
(v2.15.0+).

- [Stream a response word-by-word](#stream-a-response-word-by-word)
- [Add a stop-generating button](#add-a-stop-generating-button)
- [Show a "thinking" bubble, then the answer](#show-a-thinking-bubble-then-the-answer)
- [Keep a persistent welcome / suggested questions](#keep-a-persistent-welcome--suggested-questions)
- [Customize the message bubble](#customize-the-message-bubble)
- [Customize how attachments are displayed](#customize-how-attachments-are-displayed)
- [Localize & support RTL](#localize--support-rtl)

The mental model: you own a `ChatMessagesController` (like a
`TextEditingController`). You `addMessage(...)` to append, and
`updateMessage(...)` (matching by `customProperties['id']`) to mutate a message
in place — that's how streaming and the loading→answer morph work.

---

## Stream a response word-by-word

Add an empty AI message with an id, then update it with the accumulated text as
chunks arrive. Enable the streaming flags on the widget.

```dart
AiChatWidget(
  currentUser: currentUser,
  aiUser: aiUser,
  controller: controller,
  onSendMessage: _handleSend,
  enableMarkdownStreaming: true, // animate markdown as it streams
  streamingWordByWord: true,     // reveal word-by-word (not char-by-char)
);

Future<void> _handleSend(ChatMessage message) async {
  const id = 'reply';
  controller.addMessage(ChatMessage(
    text: '',
    user: aiUser,
    createdAt: DateTime.now(),
    isMarkdown: true,
    customProperties: const {'id': id},
  ));

  final buffer = StringBuffer();
  await for (final chunk in myLlm.stream(message.text)) {
    buffer.write(chunk);
    controller.updateMessage(ChatMessage(
      text: buffer.toString(),
      user: aiUser,
      createdAt: DateTime.now(),
      isMarkdown: true,
      customProperties: const {'id': id},
    ));
  }
}
```

> To turn animation **off** entirely, set both `enableMarkdownStreaming: false`
> and `streamingWordByWord: false`.

---

## Add a stop-generating button

Provide `onCancelGenerating`. While `loadingConfig.isLoading` is true, the send
button is automatically replaced by a stop button; tapping it calls your
callback (cancel your stream/HTTP there).

```dart
AiChatWidget(
  currentUser: currentUser,
  aiUser: aiUser,
  controller: controller,
  onSendMessage: _handleSend,
  loadingConfig: LoadingConfig(isLoading: _isGenerating),
  onCancelGenerating: () => _streamSubscription?.cancel(),
  // Optional: customize the stop button
  inputOptions: const InputOptions(stopButtonIcon: Icons.stop_circle),
);
```

---

## Show a "thinking" bubble, then the answer

Add a `ChatMessage.loading(...)` with an id, then replace it in place — either
with streamed text (as above) or a rich widget via `ChatMessage.rich`.

```dart
const id = 'response-42';

// 1. Thinking placeholder
controller.addMessage(ChatMessage.loading(
  user: aiUser,
  id: id,
  text: 'Thinking…',
));

// 2a. Replace with a streamed text answer …
controller.updateMessage(ChatMessage(
  text: answer,
  user: aiUser,
  createdAt: DateTime.now(),
  isMarkdown: true,
  customProperties: const {'id': id},
));

// 2b. … or with a registered rich widget
controller.updateMessage(ChatMessage.rich(
  user: aiUser,
  id: id,
  resultKind: 'weather',
  data: {'city': 'Baghdad', 'temp': 42},
));
```

Register rich renderers on the widget:

```dart
AiChatWidget(
  // …
  resultRenderers: {
    'weather': (context, data) => WeatherCard(data: data),
  },
);
```

---

## Keep a persistent welcome / suggested questions

By default the welcome state disappears after the first message. Use
`exampleQuestions` + `persistentExampleQuestionsTitle` to keep suggestions
visible, and `WelcomeMessageConfig.centerVertically` to center the empty state.

```dart
AiChatWidget(
  // …
  welcomeMessageConfig: const WelcomeMessageConfig(centerVertically: true),
  persistentExampleQuestionsTitle: 'Suggested Questions',
  exampleQuestions: const [
    ExampleQuestion(question: 'Summarize this document'),
    ExampleQuestion(question: 'Draft a reply'),
  ],
);
```

---

## Customize the message bubble

`MessageOptions` has two builders:

- **`bubbleBuilder`** — *wrap* the default bubble (keep package styling, add
  chrome like a feedback/report button). You receive `defaultBubble`.
- **`customBubbleBuilder`** — *replace* the bubble entirely (3 args).

```dart
AiChatWidget(
  // …
  messageOptions: MessageOptions(
    bubbleBuilder: (context, message, isCurrentUser, defaultBubble) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        defaultBubble,
        if (!isCurrentUser)
          IconButton(
            icon: const Icon(Icons.flag_outlined, size: 16),
            onPressed: () => _report(message),
          ),
      ],
    ),
  ),
);
```

---

## Customize how attachments are displayed

Attach media to a message via `ChatMessage.media`, and control rendering with
`FileUploadOptions.fileDisplayBuilder` (e.g. tap-to-enlarge, custom radius).

```dart
AiChatWidget(
  // …
  fileUploadOptions: FileUploadOptions(
    fileDisplayBuilder: (context, media) => GestureDetector(
      onTap: () => _openLightbox(media.url),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(media.url, fit: BoxFit.cover),
      ),
    ),
  ),
);

// A message with an image attachment:
controller.addMessage(ChatMessage(
  text: 'Here you go',
  user: aiUser,
  createdAt: DateTime.now(),
  media: const [ChatMedia(url: 'https://…/photo.png')],
));
```

---

## Localize & support RTL

The package detects RTL from message text automatically. The user-facing
strings are localizable:

```dart
AiChatWidget(
  // …
  persistentExampleQuestionsTitle: 'الأسئلة المقترحة',
  inputOptions: const InputOptions(sendButtonTooltip: 'إرسال'),
  messageOptions: const MessageOptions(
    copyButtonLabel: 'نسخ',
    copiedToClipboardText: 'تم نسخ الرسالة',
    // Different timestamp styles for user vs AI bubbles:
    userTimeTextStyle: TextStyle(color: Colors.white70, fontSize: 11),
    aiTimeTextStyle: TextStyle(color: Colors.black54, fontSize: 11),
  ),
);
```
