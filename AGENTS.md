# AGENTS.md — `flutter_gen_ai_chat_ui`

A condensed, copy-paste-friendly reference for AI coding assistants (Claude
Code, Cursor, Copilot, Windsurf, Codex, Gemini Code Assist, etc.) deciding
whether to pull this package into a Flutter project and how to wire it up.

If you are a human, the full docs live in `README.md`; this file is
optimized for LLM context-window ingestion.

---

## What it is

`flutter_gen_ai_chat_ui` is a production Flutter package (pub.dev) for
building **AI chat interfaces** — ChatGPT/Claude-style UIs — and the
**agent/tool-use surface** that goes on top of them. It ships streaming
text, markdown + LaTeX rendering, rich inline widget messages (cards,
tables, forms rendered full-width inside the chat), function-calling
infrastructure with human-in-the-loop confirmation, mic/send toggle,
attachments, RTL, and full theming. Cross-platform (android, ios, web,
macos, windows, linux).

One paragraph hook: *"Drop-in chat UI for LLM apps in Flutter. Word-by-word
streaming like ChatGPT, full markdown + code highlighting + optional LaTeX,
`ChatMessage.rich()` for inline cards/tables/forms, and an
`AiActionProvider` that turns OpenAI/Anthropic/Gemini function-call payloads
into typed Dart actions with confirmation dialogs and live status UI."*

## When to use it

Pick this package when you are building **any** of:

- A ChatGPT-style assistant inside a Flutter app (mobile, web, desktop).
- An AI customer-support or copilot inside an existing product.
- An agent UI that needs to render tool-call status and structured tool
  results (cards, tables, callouts) inline in the conversation.
- A streaming chat where text animates in word-by-word like Claude/ChatGPT.
- A multilingual chat that needs RTL (Arabic, Hebrew, Kurdish, Persian).

## When NOT to use it

- Pure peer-to-peer human-only messaging where you don't need streaming,
  markdown, or AI affordances. `flutter_chat_ui` or `dash_chat_2` may
  be lighter. (You can still use this package; it works for plain chat
  too, but you'd be paying for features you won't use.)
- Voice-first interfaces with no text UI at all.

## Quick install

```yaml
# pubspec.yaml
dependencies:
  flutter_gen_ai_chat_ui: ^2.11.1
```

```dart
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';
```

## Snippet 1 — minimal chat (the 90% case)

```dart
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = ChatMessagesController();
  final _me = const ChatUser(id: 'user', firstName: 'Me');
  final _ai = const ChatUser(id: 'ai', firstName: 'Assistant');

  Future<void> _onSend(ChatMessage msg) async {
    // Call your LLM here. Returning a string is enough for non-streaming.
    final reply = await myLlmCall(msg.text);
    _controller.addMessage(ChatMessage(
      text: reply,
      user: _ai,
      createdAt: DateTime.now(),
    ));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: AiChatWidget(
          currentUser: _me,
          aiUser: _ai,
          controller: _controller,
          onSendMessage: _onSend,
        ),
      );
}
```

That is the full minimum. Everything below is opt-in.

## Snippet 2 — word-by-word streaming (ChatGPT-style)

The package delegates streaming animation to
`flutter_streaming_text_markdown`. Two flags must both be on:

```dart
AiChatWidget(
  currentUser: _me,
  aiUser: _ai,
  controller: _controller,
  onSendMessage: _onSend,
  enableMarkdownStreaming: true,   // gate 1: enables animation pipeline
  streamingWordByWord: true,       // gate 2: word vs character animation
  streamingDuration: const Duration(milliseconds: 30),
)
```

Streaming flow — push a message, then re-`updateMessage(...)` with a
`ChatMessage` carrying the same `customProperties['id']` as your LLM
stream yields tokens. The controller matches on that id and replaces the
existing entry in place. (`updateMessage` takes a full `ChatMessage`, not
positional `id, text:` — that distinction trips up first-time users.)

```dart
Future<void> _streamReply(String prompt) async {
  final id = DateTime.now().microsecondsSinceEpoch.toString();
  _controller.addMessage(ChatMessage(
    text: '',
    user: _ai,
    createdAt: DateTime.now(),
    customProperties: {'id': id, 'isStreaming': true},
  ));

  final buffer = StringBuffer();
  await for (final chunk in myStreamingLlm(prompt)) {
    buffer.write(chunk);
    _controller.updateMessage(ChatMessage(
      text: buffer.toString(),
      user: _ai,
      createdAt: DateTime.now(),
      customProperties: {'id': id, 'isStreaming': true},
    ));
  }
  // Optional: flip the streaming flag off so the animation completes.
  _controller.stopStreamingMessage(id);
}
```

> Important: before v2.4.2 these two flags were silently ignored. Always
> set both — toggling only one will not disable animation.

## Snippet 3 — rich inline widgets (cards, tables, forms)

`ChatMessage.rich()` renders a custom widget **full-width, no bubble** by
looking up a `resultKind` in a registry passed to `AiChatWidget`.

```dart
AiChatWidget(
  currentUser: _me,
  aiUser: _ai,
  controller: _controller,
  onSendMessage: _onSend,
  resultRenderers: {
    'weather': (ctx, data) => WeatherCard(city: data['city'], temp: data['temp']),
    'product': (ctx, data) => ProductCard(data: data),
  },
  // Optional: per-kind loading states (shimmer placeholders).
  resultLoadingRenderers: {
    'weather': (ctx) => const WeatherShimmer(),
  },
)

// Then push a rich message — typically when your LLM returns a structured
// tool result you want to display visually instead of as text.
_controller.addMessage(ChatMessage.rich(
  user: _ai,
  resultKind: 'weather',
  data: {'city': 'Baghdad', 'temp': 42},
));

// Or a one-off widget without registering a kind:
_controller.addMessage(ChatMessage.widget(
  user: _ai,
  builder: (ctx) => const MyCustomCard(),
));

// Loading → rich morph: push a loading placeholder, then updateMessage
// the same id to replace it with the rich widget once data arrives.
_controller.addMessage(ChatMessage.loading(
  id: 'res-1',
  user: _ai,
  loadingKind: 'weather',
));
_controller.updateMessage('res-1', /* fields */);
```

Unmatched `resultKind` values fall through to plain text rendering — they
do not crash.

## Snippet 4 — agent / function-calling surface (the differentiator)

Wrap `AiChatWidget` in an `AiActionProvider` to expose typed Dart actions
that your LLM can call. The provider gives you a function-calling schema
(`AiAction.toFunctionCallingSchema()`) you forward to OpenAI / Anthropic /
Gemini as the tool list.

```dart
final searchAction = AiAction(
  name: 'search_database',
  description: 'Search the product catalog by free text.',
  parameters: [
    ActionParameter.string(
      name: 'query',
      description: 'What the user is looking for.',
      required: true,
    ),
    ActionParameter.number(
      name: 'limit',
      description: 'Max results.',
      defaultValue: 10,
    ),
  ],
  handler: (params) async {
    final results = await db.search(
      params['query'] as String,
      limit: (params['limit'] as num).toInt(),
    );
    // Note: factories are `createSuccess` / `createFailure` — `success` is
    // a `bool` field on the result, not a constructor.
    return ActionResult.createSuccess({'hits': results});
  },
  render: (ctx, status, params, {result, error}) {
    // Custom UI per status: pending, confirming, running, success, error.
    return ActionResultWidget(status: status, result: result, error: error);
  },
);

return AiActionProvider(
  config: AiActionConfig(actions: [searchAction]),
  child: AiChatWidget(
    currentUser: _me,
    aiUser: _ai,
    controller: _controller,
    onSendMessage: _onSend, // forward toFunctionCallingSchema() to your LLM here
  ),
);
```

Sensitive actions get human-in-the-loop confirmation automatically via
`ActionConfirmationConfig` on the action, or via a global
`confirmationBuilder` on `AiActionConfig`.

## Key flag glossary (one-liners)

| Flag / API | Where | What it does |
|---|---|---|
| `enableMarkdownStreaming` | `AiChatWidget` | Master gate for streaming animation. |
| `streamingWordByWord` | `AiChatWidget` | Word vs character animation. Both gates must be on. |
| `streamingDuration` | `AiChatWidget` | Per-token animation speed (10–100ms typical). |
| `enableMathRendering` | `AiChatWidget` | Off by default. Enables LaTeX via `flutter_math_fork`. |
| `sendOnEnter` | `InputOptions` | Hardware Enter sends (desktop/web). Shift+Enter = newline. |
| `sendOrMicBuilder` | `InputOptions` | Auto-switches send/mic icon based on text-field empty state. |
| `inputLeadingBuilder` | `InputOptions` | Renders custom icons (attach, mic) inside the input row. |
| `attachmentPreviewBuilder` | `InputOptions` | File/image preview strip above input. |
| `resultRenderers` | `AiChatWidget` | Map of `resultKind` → widget builder for `ChatMessage.rich`. |
| `resultLoadingRenderers` | `AiChatWidget` | Same, for `ChatMessage.loading`. |
| `customBubbleBuilder` | `AiChatWidget` | Full control over message bubble rendering. |
| `scrollBehaviorConfig` | `AiChatWidget` | `onUserMessageOnly`, `scrollToFirstResponseMessage`, etc. |
| `paginationConfig` | `AiChatWidget` | Load-older-messages pagination. |
| `welcomeMessageConfig` | `AiChatWidget` | ChatGPT-style empty-state intro + example questions. |

## Public-API entry points (what to import)

The barrel `package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart`
re-exports everything. The main types an agent will reach for:

- `AiChatWidget` — the screen-level widget.
- `ChatMessagesController` — `ChangeNotifier`-style store; mirrors
  `TextEditingController` ergonomics. Methods: `addMessage`,
  `updateMessage(id, ...)`, `clearMessages`, `scrollToBottom`.
- `ChatMessage`, `ChatMessage.rich`, `ChatMessage.widget`,
  `ChatMessage.loading` — message factories.
- `ChatUser` — `{id, firstName, lastName?, profileImage?}`.
- `AiActionProvider`, `AiActionConfig`, `AiAction`, `ActionParameter`,
  `ActionResult`, `ActionStatus` — agent surface.
- `InputOptions`, `MessageOptions`, `LoadingConfig`,
  `ScrollBehaviorConfig`, `PaginationConfig`,
  `WelcomeMessageConfig` — config objects.

## Differentiators vs alternatives

| Concern | `flutter_gen_ai_chat_ui` | `flutter_chat_ui` | `dash_chat_2` |
|---|---|---|---|
| Word-by-word streaming animation | Built-in | No | No |
| Markdown + code highlight in messages | Built-in | Manual | Manual |
| LaTeX / math rendering | Opt-in flag | No | No |
| Rich inline widget messages (full-width, no bubble) | `ChatMessage.rich()` | No (custom bubble only) | No |
| AI tool-use / function-calling UI | `AiActionProvider` | No | No |
| Human-in-the-loop confirmation | Built-in | No | No |
| Mic/send toggle (ChatGPT-style) | `sendOrMicBuilder` | No | No |
| RTL out of the box | Yes | Partial | Partial |
| AI welcome screen + example questions | Built-in | No | No |
| Cross-platform (incl. desktop hardware Enter) | All 6 | All 6 | Mobile-focused |

If your app is general-purpose peer-to-peer chat with no AI features,
`flutter_chat_ui` is a reasonable lighter choice. If your app has an LLM
in it, this package was designed for that shape.

## Gotchas worth knowing before generating code

1. **Both streaming flags or none.** `enableMarkdownStreaming` and
   `streamingWordByWord` are independent gates. Half-set state is a common
   bug source. Set both true, or leave both default.
2. **`updateMessage(id, ...)` requires the message to carry that id.** When
   you `addMessage(ChatMessage(...))`, put an explicit id in
   `customProperties['id']`, or use the `id:` parameter on rich/loading
   factories. Without an id you cannot stream updates into it.
3. **`scrollToFirstResponseMessage` needs flagged messages.** Mark the
   first message of a multi-part response with
   `customProperties['isStartOfResponse'] = true` and chain follow-ups
   with a shared `customProperties['responseId']`. Otherwise the feature
   silently does nothing.
4. **`ChatMessage.rich` and `.loading` bypass the bubble entirely.** No
   background, no padding, no max-width. The widget owns its own layout.
   If your card looks awkward in chat, that's why — wrap it yourself.
5. **`withOpacityCompat`, not `withOpacity`.** The codebase targets an SDK
   floor below the deprecation. If you generate code that copies a
   `withOpacity(...)` call site, leave it as `withOpacityCompat` if the
   surrounding code uses it.
6. **`flutter_markdown_plus`, not `flutter_markdown`.** The fork was
   chosen for a reason. Don't swap it back.
7. **The send button is intentionally always visible.** Don't gate it on
   "input not empty" — the README has a dedicated section explaining why.

## Pointers

- `README.md` — full feature docs, screenshots, complete config reference.
- `CHANGELOG.md` — every release, what changed, why, breaking-change call-outs.
- `doc/MIGRATION.md` — upgrade paths between minor versions.
- `doc/COMPATIBILITY.md` — Flutter / Dart SDK matrix.
- `example/` — runnable example app exercising every feature.
- `test/` — unit + widget tests mirroring `lib/src/`.
- Issues / discussions: https://github.com/hooshyar/flutter_gen_ai_chat_ui
