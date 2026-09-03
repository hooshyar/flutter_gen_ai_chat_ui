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
- [Match ChatGPT / Claude / Gemini styling](#match-chatgpt--claude--gemini-styling)
- [Localize & support RTL](#localize--support-rtl)
- [Wire up a real LLM provider (OpenAI, Anthropic, Gemini, Ollama)](#wire-up-a-real-llm-provider-openai-anthropic-gemini-ollama)
- [Persist a long-running thread across app restarts](#persist-a-long-running-thread-across-app-restarts)

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

Attach media to a message via `ChatMessage.media` — pass a `List<ChatMedia>`
to send several files in one message, each rendered by `MessageAttachment`:

```dart
controller.addMessage(ChatMessage(
  text: 'Here you go',
  user: aiUser,
  createdAt: DateTime.now(),
  media: const [
    ChatMedia(url: 'https://…/photo1.png'),
    ChatMedia(url: 'https://…/photo2.png'),
    ChatMedia(url: 'https://…/report.pdf', type: ChatMediaType.document, fileName: 'report.pdf'),
  ],
));
```

### Built-in image lightbox (task-008)

For a tap-to-preview image viewer (pinch-zoom, swipe between every image in
the message) with zero custom code, turn on `enableAttachmentLightbox`:

```dart
AiChatWidget(
  // …
  messageOptions: const MessageOptions(
    enableImageTaps: true,           // required — taps are opt-in
    enableAttachmentLightbox: true,  // opens the built-in AttachmentLightbox
  ),
);
```

An explicit `MessageOptions.onMediaTap` always overrides the built-in
lightbox, so existing custom tap handlers keep working unchanged. You can
also invoke the lightbox directly (e.g. from your own
`fileDisplayBuilder`): `AttachmentLightbox.show(context, images: [...], initialIndex: 0)`.

For full control over rendering instead, use
`FileUploadOptions.fileDisplayBuilder`:

```dart
AiChatWidget(
  // …
  fileUploadOptions: FileUploadOptions(
    fileDisplayBuilder: (context, media) => GestureDetector(
      onTap: () => AttachmentLightbox.show(context, images: [media]),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(media.url, fit: BoxFit.cover),
      ),
    ),
  ),
);
```

### Per-file upload progress (task-008)

While a file is uploading, set `ChatMedia.uploadProgress` (0.0-1.0) — every
attachment type renders a progress overlay automatically, no extra config:

```dart
const id = 'attachment-1';
controller.addMessage(ChatMessage(
  text: '',
  user: currentUser,
  createdAt: DateTime.now(),
  media: const [ChatMedia(url: localFilePath, uploadProgress: 0.0)],
  customProperties: const {'id': id},
));

await for (final sent in myUploader.upload(localFilePath)) {
  controller.updateMessage(ChatMessage(
    text: '',
    user: currentUser,
    createdAt: DateTime.now(),
    media: [ChatMedia(url: sent.remoteUrlOrLocalPath, uploadProgress: sent.fraction)],
    customProperties: const {'id': id},
  ));
}
// Final update: uploadProgress: 1.0 (or omit it) once the real remote URL is known.
```

---

## Match ChatGPT / Claude / Gemini styling

One-liner brand presets. Attach a `CustomThemeExtension` preset to your
`ThemeData.extensions`:

```dart
MaterialApp(
  theme: ThemeData(extensions: [CustomThemeExtension.chatgpt()]),
  darkTheme: ThemeData.dark().copyWith(
    extensions: [CustomThemeExtension.chatgpt(dark: true)],
  ),
  home: const ChatScreen(),
);
```

Available: `CustomThemeExtension.chatgpt()`, `.claude()`, `.gemini()` — each
takes an optional `dark: true`. Tweak any preset with `.copyWith(...)`.

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

---

## Wire up a real LLM provider (OpenAI, Anthropic, Gemini, Ollama)

This package has no opinion on where your responses come from — it just needs
you to call `controller.addMessage(...)` once and `controller.updateMessage(...)`
per chunk, exactly like [the streaming recipe above](#stream-a-response-word-by-word).
These snippets use `package:http` directly (not each vendor's official SDK) so
this package's core dependencies stay light — copy the parsing loop into your
own service class and add whichever SDK you actually want, if any. Never
hardcode an API key; read it from an environment variable or your platform's
secret storage.

All four follow the same shape: send a request with `"stream": true`, read the
response body as a stream of newline-delimited chunks, decode each one,
extract the incremental text, and feed it to `updateMessage`.

### OpenAI (Chat Completions)

```dart
Future<void> streamFromOpenAi(ChatMessage userMessage) async {
  final request = http.Request(
    'POST',
    Uri.parse('https://api.openai.com/v1/chat/completions'),
  )
    ..headers.addAll({
      'Authorization': 'Bearer $openAiApiKey',
      'Content-Type': 'application/json',
    })
    ..body = jsonEncode({
      'model': 'gpt-5.6-terra', // check platform.openai.com/docs/models for the current one
      'messages': [
        {'role': 'user', 'content': userMessage.text}
      ],
      'stream': true,
    });

  const id = 'reply';
  controller.addMessage(ChatMessage(
    text: '', user: aiUser, createdAt: DateTime.now(),
    customProperties: const {'id': id},
  ));

  final buffer = StringBuffer();
  final response = await http.Client().send(request);
  await for (final line in response.stream.transform(utf8.decoder).transform(const LineSplitter())) {
    if (!line.startsWith('data: ') || line == 'data: [DONE]') continue;
    final delta = jsonDecode(line.substring(6))['choices'][0]['delta']['content'] as String?;
    if (delta == null) continue;
    buffer.write(delta);
    controller.updateMessage(ChatMessage(
      text: buffer.toString(), user: aiUser, createdAt: DateTime.now(),
      customProperties: const {'id': id},
    ));
  }
}
```

### Anthropic (Messages API)

```dart
Future<void> streamFromAnthropic(ChatMessage userMessage) async {
  final request = http.Request('POST', Uri.parse('https://api.anthropic.com/v1/messages'))
    ..headers.addAll({
      'x-api-key': anthropicApiKey,
      'anthropic-version': '2023-06-01',
      'Content-Type': 'application/json',
    })
    ..body = jsonEncode({
      'model': 'claude-sonnet-5', // check platform.claude.com/docs for the current one
      'max_tokens': 1024,
      'messages': [
        {'role': 'user', 'content': userMessage.text}
      ],
      'stream': true,
    });

  const id = 'reply';
  controller.addMessage(ChatMessage(
    text: '', user: aiUser, createdAt: DateTime.now(),
    customProperties: const {'id': id},
  ));

  final buffer = StringBuffer();
  final response = await http.Client().send(request);
  await for (final line in response.stream.transform(utf8.decoder).transform(const LineSplitter())) {
    if (!line.startsWith('data: ')) continue;
    final event = jsonDecode(line.substring(6));
    if (event['type'] != 'content_block_delta') continue;
    buffer.write(event['delta']['text'] as String);
    controller.updateMessage(ChatMessage(
      text: buffer.toString(), user: aiUser, createdAt: DateTime.now(),
      customProperties: const {'id': id},
    ));
  }
}
```

### Google Gemini (`streamGenerateContent`)

```dart
Future<void> streamFromGemini(ChatMessage userMessage) async {
  final uri = Uri.parse(
    'https://generativelanguage.googleapis.com/v1beta/models/'
    // check ai.google.dev/gemini-api/docs/models for the current model name
    'gemini-2.5-flash:streamGenerateContent?alt=sse&key=$geminiApiKey',
  );
  final request = http.Request('POST', uri)
    ..headers['Content-Type'] = 'application/json'
    ..body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': userMessage.text}
          ]
        }
      ],
    });

  const id = 'reply';
  controller.addMessage(ChatMessage(
    text: '', user: aiUser, createdAt: DateTime.now(),
    customProperties: const {'id': id},
  ));

  final buffer = StringBuffer();
  final response = await http.Client().send(request);
  await for (final line in response.stream.transform(utf8.decoder).transform(const LineSplitter())) {
    if (!line.startsWith('data: ')) continue;
    final delta = jsonDecode(line.substring(6))['candidates'][0]['content']['parts'][0]['text'] as String?;
    if (delta == null) continue;
    buffer.write(delta);
    controller.updateMessage(ChatMessage(
      text: buffer.toString(), user: aiUser, createdAt: DateTime.now(),
      customProperties: const {'id': id},
    ));
  }
}
```

### Ollama (local models, no API key)

Ollama's `/api/chat` streams newline-delimited JSON (not SSE) — one JSON
object per line, with a final `"done": true` line:

```dart
Future<void> streamFromOllama(ChatMessage userMessage) async {
  final request = http.Request('POST', Uri.parse('http://localhost:11434/api/chat'))
    ..body = jsonEncode({
      'model': 'llama3.2', // whatever you've pulled via `ollama pull <model>`
      'messages': [
        {'role': 'user', 'content': userMessage.text}
      ],
    });

  const id = 'reply';
  controller.addMessage(ChatMessage(
    text: '', user: aiUser, createdAt: DateTime.now(),
    customProperties: const {'id': id},
  ));

  final buffer = StringBuffer();
  final response = await http.Client().send(request);
  await for (final line in response.stream.transform(utf8.decoder).transform(const LineSplitter())) {
    if (line.isEmpty) continue;
    final chunk = jsonDecode(line);
    buffer.write(chunk['message']['content'] as String);
    controller.updateMessage(ChatMessage(
      text: buffer.toString(), user: aiUser, createdAt: DateTime.now(),
      customProperties: const {'id': id},
    ));
    if (chunk['done'] == true) break;
  }
}
```

All four assume `import 'dart:convert';` and `import 'package:http/http.dart' as http;`
at the top of the file, plus the `aiUser`/`controller` from your existing chat
screen. Wrap the `send`/decode loop in a `try`/`catch` and call
`controller.updateMessage(...)` with `hasError: true` on failure — see
[`ChatMessage.hasError`](../../lib/src/models/chat/chat_message.dart) — the
snippets above omit that for brevity.

---

## Persist a long-running thread across app restarts

`ChatMessagesController` accepts an optional `persistence` hook so a thread
survives an app restart — the package doesn't pick a storage backend, you
implement `ChatPersistence` with whatever you already use
(`shared_preferences`, `sqflite`, `Hive`, a REST API):

```dart
class MyChatPersistence implements ChatPersistence {
  @override
  Future<List<ChatMessage>> loadMessages() async {
    final raw = prefs.getString('chat_history');
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((m) => ChatMessage(
              text: m['text'],
              user: m['userId'] == 'me' ? currentUser : aiUser,
              createdAt: DateTime.parse(m['createdAt']),
              customProperties: {'id': m['id']},
            ))
        .toList();
  }

  @override
  Future<void> saveMessages(List<ChatMessage> messages) async {
    final raw = jsonEncode(messages
        .map((m) => {
              'text': m.text,
              'userId': m.user.id == currentUser.id ? 'me' : 'ai',
              'createdAt': m.createdAt.toIso8601String(),
              'id': m.customProperties?['id'],
            })
        .toList());
    await prefs.setString('chat_history', raw);
  }
}

final controller = ChatMessagesController(
  persistence: MyChatPersistence(),
);

@override
void initState() {
  super.initState();
  controller.restoreFromPersistence(); // populates `controller.messages`
}
```

`saveMessages` runs automatically after `addMessage`/`updateMessage`/
`clearMessages`, debounced by `persistDebounce` (500ms by default) so a
word-by-word streamed reply triggers one save after it finishes, not one
per chunk. Pass `autoPersist: false` to disable the automatic save entirely
and call `controller.persistNow()` yourself instead — e.g. only on app
backgrounding via `WidgetsBindingObserver.didChangeAppLifecycleState`.
`loadMessages`/`saveMessages` receive/return the package's real
`ChatMessage` objects, so `customProperties['id']` round-trips correctly
for streaming and rich-widget messages that key off it.

For pagination on top of persistence (loading only the most recent N
messages, then lazily fetching older ones as the user scrolls up), see
`PaginationConfig` (`enabled`, `autoLoadOnScroll`, `distanceToTriggerLoadPixels`)
and `ChatMessagesController.loadMore` — `persistence` only covers
save/restore of what's currently in memory, it isn't itself a pagination
mechanism.
