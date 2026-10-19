# Flutter Gen AI Chat UI

[![pub package](https://img.shields.io/pub/v/flutter_gen_ai_chat_ui.svg)](https://pub.dev/packages/flutter_gen_ai_chat_ui)
[![pub points](https://img.shields.io/pub/points/flutter_gen_ai_chat_ui)](https://pub.dev/packages/flutter_gen_ai_chat_ui/score)
[![pub likes](https://img.shields.io/pub/likes/flutter_gen_ai_chat_ui)](https://pub.dev/packages/flutter_gen_ai_chat_ui/score)
[![CI](https://github.com/hooshyar/flutter_gen_ai_chat_ui/actions/workflows/ci.yml/badge.svg)](https://github.com/hooshyar/flutter_gen_ai_chat_ui/actions/workflows/ci.yml)

A Flutter chat UI kit for AI apps. Stream ChatGPT, Claude or Gemini replies as live markdown with syntax-highlighted code and LaTeX, render tool calls and rich inline widgets, and get RTL, theming and accessibility out of the box. It works with any backend: you bring the model call, the widget handles the conversation UI.

<p align="center">
  <img src="https://raw.githubusercontent.com/hooshyar/flutter_gen_ai_chat_ui/main/doc/demo/demo.gif" alt="The example app: streaming markdown with syntax-highlighted code, theme presets and RTL" width="720">
</p>

▶️ **[Try the live web demo](https://hooshyar.github.io/flutter_gen_ai_chat_ui/)** · [full-quality video](https://github.com/hooshyar/flutter_gen_ai_chat_ui/raw/main/doc/demo/demo.mp4)

## Installation

Add this to your package's pubspec.yaml file:

```yaml
dependencies:
  flutter_gen_ai_chat_ui: ^2.22.0
```

Then run:

```bash
flutter pub get
```

> 📖 **New:** task-focused [**Cookbook**](doc/cookbook/README.md) — streaming, stop-generating, thinking→answer, custom bubbles, attachments, localization/RTL.

## Quick Start

This complete app streams AI replies into a chat. Paste it into `lib/main.dart` and run it; no API key needed:

<!-- quickstart:start -->
```dart
import 'package:flutter/material.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';

void main() => runApp(const MaterialApp(home: ChatScreen()));

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = ChatMessagesController();
  static const _user = ChatUser(id: 'user', name: 'You');
  static const _ai = ChatUser(id: 'ai', name: 'Assistant');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AiChatWidget(
        currentUser: _user,
        aiUser: _ai,
        controller: _controller,
        onSendMessage: (message) {
          _controller.addMessage(message);
          // Swap fakeLlmReply() for your model's token stream.
          _controller.streamResponse(fakeLlmReply(message.text), user: _ai);
        },
        welcomeMessageConfig: const WelcomeMessageConfig(
          title: 'Ask me anything',
        ),
      ),
    );
  }
}

/// Stands in for an LLM: streams a markdown reply one word at a time.
Stream<String> fakeLlmReply(String prompt) async* {
  final reply = 'You asked: *$prompt*\n\n'
      'This reply **streams in** word by word, with `inline code` '
      'and a list:\n\n'
      '- markdown renders as it arrives\n'
      '- the reply closes when the stream ends\n';
  for (final token in RegExp(r'\S+\s*').allMatches(reply)) {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    yield token[0]!;
  }
}
```
<!-- quickstart:end -->

The whole integration is `onSendMessage`: add the user's message, then hand the reply stream to `controller.streamResponse`. To use a real model, replace `fakeLlmReply()` with a `Stream<String>` of your model's tokens; [Streaming AI responses](#streaming-ai-responses) covers stop buttons, errors and provider streams.

## Contents
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Why this package?](#why-this-package)
- [Streaming AI responses](#streaming-ai-responses)
- [Live Examples](#-live-examples)
- [Features](#features)
- [Performance & Features](#-performance--features)
- [Works Great With](#-works-great-with)
- [RTL & Bidirectional Languages](#rtl--bidirectional-languages)
- [Configuration Options](#configuration-options)
- [AI Actions System](#-ai-actions-system)
- [Community & Support](#community--support)

## Why this package?

Three Flutter chat UI packages dominate searches: `flutter_gen_ai_chat_ui`, `flutter_chat_ui`, and `dash_chat_2`. They target different shapes of app. If you have an LLM in the loop, this package was designed for that shape.

| Concern | `flutter_gen_ai_chat_ui` | `flutter_chat_ui` | `dash_chat_2` |
|---|---|---|---|
| Word-by-word streaming animation | Built-in | No | No |
| Markdown + code highlight in messages | Built-in (highlighter + copy button, no extra dep) | Manual | Manual |
| LaTeX / math rendering | Opt-in flag | No | No |
| Rich inline widget messages (full-width, no bubble) | `ChatMessage.rich()` | Custom bubble only | No |
| AI tool-use / function-calling UI | `AiActionProvider` | No | No |
| Human-in-the-loop confirmation | Built-in | No | No |
| Mic/send toggle (ChatGPT-style) | `sendOrMicBuilder` | No | No |
| RTL out of the box | Yes | Partial | Partial |
| AI welcome screen + example questions | Built-in | No | No |
| Cross-platform incl. desktop hardware Enter | All 6 | All 6 | Mobile-focused |

For general-purpose peer-to-peer chat with no AI features, `flutter_chat_ui` is a lighter choice. The features above are this package's reason to exist.

## Streaming AI responses

`ChatMessagesController.streamResponse` streams a reply into the chat in one call. Give it a `Stream<String>` of token deltas (what OpenAI, Anthropic and Gemini streams deliver) and the AI user:

```dart
final response = controller.streamResponse(
  myLlm.streamReply(prompt), // Stream<String>
  user: aiUser,
);
```

- The reply appears with the first text, updates as chunks arrive, and is marked complete when the stream closes.
- If each event is the whole text so far rather than a delta, pass `accumulated: true`.
- If the stream reports an error, the text received so far stays, the reply is closed, and `onError` is called.
- The returned `ChatResponseStream` has `cancel()` and a `done` future that completes with the final message.

A stop button wires `cancel()` to `onCancelGenerating`:

```dart
ChatResponseStream? _reply;
bool _isGenerating = false;

void _onSend(ChatMessage message) {
  controller.addMessage(message);
  final reply = controller.streamResponse(llm.streamReply(message.text), user: aiUser);
  setState(() {
    _reply = reply;
    _isGenerating = true;
  });
  reply.done.whenComplete(() {
    if (mounted) setState(() => _isGenerating = false);
  });
}

// In AiChatWidget(...):
//   onSendMessage: _onSend,
//   loadingConfig: LoadingConfig(isLoading: _isGenerating),
//   onCancelGenerating: () => _reply?.cancel(),
```

To turn an OpenAI-compatible or Anthropic server-sent-events response into a `Stream<String>`, see the [SSE bridges](https://pub.dev/packages/flutter_streaming_text_markdown#bridging-openai--anthropic-sse-to-streamstring) in `flutter_streaming_text_markdown`, which renders the replies here.

The reveal animation is controlled by `enableMarkdownStreaming` (master switch) and `streamingWordByWord` (word or character reveal).

### Driving a stream by hand

`streamResponse` is a wrapper around three controller calls you can also use directly, for example when replies arrive over a WebSocket you manage yourself: `addStreamingMessage` with a message carrying a stable `customProperties['id']`, `updateMessage` with the same id as text arrives, and `stopStreamingMessage(id)` at the end.

> **Note:** when you add several messages for the same user back to back without an explicit `id` (e.g. a tool-call message immediately followed by a result card), give each one an explicit id. `ChatMessagesController` builds an id from the user id and `createdAt`'s millisecond timestamp when none is given, so two id-less messages added in the same millisecond can land on the same generated id and be treated as the same message. This can happen on any platform, and it is more likely on web, where `DateTime.now()` only has millisecond resolution. Pass `ChatMessage(customProperties: {'id': 'my-id'})` or `ChatMessage.rich(id: 'my-id')` to keep them distinct.

Full runnable screen: [`example/lib/examples/streaming_chat.dart`](https://github.com/hooshyar/flutter_gen_ai_chat_ui/blob/main/example/lib/examples/streaming_chat.dart).

## 🎮 Live Examples

**[Try the live web demo →](https://hooshyar.github.io/flutter_gen_ai_chat_ui/)** — no install needed, runs the actual example app in your browser. Redeployed automatically on every push to `main` that touches the package or the example app (see `.github/workflows/deploy-web-demo.yml`).

The example app has one screen per feature:
- **Basic**: only the required arguments, replies streamed with `streamResponse`
- **Streaming**: word-by-word reveal with syntax-highlighted code blocks
- **Themes**: brand presets, light and dark
- **Layout**: single-row or stacked composer, attach button position, welcome and copy-button options
- **Actions**: tool calls rendered as code, then a result card
- **Rich results**: weather, product and chart cards inline
- **Attachments**: file upload button and attached-file rendering (`FileUploadOptions`)
- **Voice**: mic/send toggle with the `VoiceSendButton` widget (`InputOptions.sendOrMicBuilder`)
- **RTL**: Arabic and Sorani Kurdish, mirrored layout

To run the example app:
```bash
cd example/
flutter run
```

## Features

### Core Features
- 🎨 Dark/light mode with adaptive theming
- 💫 Word-by-word streaming with animations (like ChatGPT and Claude)
- 📝 Enhanced markdown support: fenced code blocks get built-in syntax highlighting (Dart, JS/TS, Python, Java, Kotlin, Swift, Go, Rust, C/C++/C#, JSON, YAML, Bash, SQL, HTML/XML) in a bundled monospace font
- 🎤 Optional speech-to-text integration
- 📱 Responsive layout with customizable width
- 🌐 RTL language support for global applications
- ⚡ High performance message handling for large conversations
- 📊 Improved pagination support for message history

### AI-Specific Features
- 👋 Customizable welcome message similar to ChatGPT and other AI assistants
- ❓ Example questions component for user guidance
- 💬 Persistent example questions for better user experience
- 🔄 AI typing indicators like modern chatbot interfaces
- 📜 Streaming markdown rendering for code and rich content

### 🚀 **NEW: Rich Widget Messages**
- 🧩 **`ChatMessage.rich()`** - Render custom widgets (cards, forms, charts) inline in chat — full-width, no bubble
- 🎯 **Result Renderer Registry** - Register builders by type, AI responses auto-render matching widgets
- 🔧 **`ChatMessage.widget()`** - One-off inline widgets without a registry
- 📦 **Zero Config Fallback** - Unmatched types fall through to text rendering gracefully

### 🎤 **Input Customization**
- 🎙️ **`sendOrMicBuilder`** - Mic/send toggle that auto-switches based on text field empty state (ChatGPT-style)
- 📎 **`inputLeadingBuilder`** - Icons inside the input row, left of text field (attach, mic, etc.)
- 🖼️ **`attachmentPreviewBuilder`** - File/image preview strip above the input area
- ⬇️ **Safe area support** - Input respects device home indicator on all paths

### ⏳ **Streaming Loading States**
- 💫 **`ChatMessage.loading()`** - Shimmer placeholder that morphs into rich widget via `controller.updateMessage()`
- 🏷️ **`loadingKind`** - Per-kind custom loading widgets (e.g., contract spinner, lawyer search animation)
- 🎨 **`resultLoadingRenderers`** - Register custom loading UIs per widget type

### AI Actions System
- ⚡ **Function Calling Support** - AI can execute predefined actions with parameters
- 🎨 **Generative UI** - Actions render custom widgets showing execution status
- ✋ **Human-in-the-Loop** - Automatic confirmation dialogs for sensitive operations
- 📊 **Real-time Status** - Live updates of action execution progress with animations
- 🛡️ **Type-Safe Parameters** - Full validation system with custom validators
- 🎯 **Event Streaming** - Track action lifecycle with comprehensive event system
- 🔧 **Error Handling** - Rich error management with user-friendly feedback

### UI Components
- 💬 Customizable message bubbles with modern design options
- 🎨 **Custom Bubble Builder** for complete message styling control
- ⌨️ Multiple input field styles (minimal, glassmorphic, custom)
- 🔄 Loading indicators with shimmer effects
- ⬇️ Smart scroll management for chat history
- 🎨 Enhanced theme customization to match your brand
- 📝 Code blocks with syntax highlighting, per-block copy button, and horizontal scroll for long lines

## ⚡ Performance & Features

### Key Capabilities
- **✨ Unique Streaming Text**: Word-by-word animations like ChatGPT and Claude
- **📁 Complete File Support**: Multi-format, multi-file attachments (images, documents, videos) with a built-in image lightbox and per-file upload progress — see the [attachments cookbook recipe](doc/cookbook/README.md#customize-how-attachments-are-displayed)
- **📝 Advanced Markdown**: Full support: fenced code blocks render in a bundled monospace font (JetBrains Mono, OFL) with built-in lightweight syntax highlighting, light/dark themes, a per-block copy button, horizontal scrolling, and LTR code inside RTL chats
- **🚀 Lazy rendering**: Messages are built on demand, so long conversations stay smooth
- **🎨 Extensive Theming**: Complete customization to match your brand
- **📱 Cross-Platform**: Works on all Flutter-supported platforms
- **🔗 Backend Agnostic**: Compatible with any API or service
- **⚡ Real-time Ready**: Built-in support for live updates
- **💾 Persistable Threads**: Opt-in `ChatPersistence` hook to restore/save a long-running conversation across app restarts — see the [persistence cookbook recipe](doc/cookbook/README.md#persist-a-long-running-thread-across-app-restarts)

### Web / WebAssembly

Builds and runs cleanly under Flutter's `--wasm` web compile target (`flutter build web --wasm`) — no `dart:html`/`dart:js` legacy interop or other wasm-incompatible APIs in this package. CI builds the example app with `--wasm` on every push so a regression is caught immediately (`.github/workflows/ci.yml`, `wasm-build` job).

## 🌟 Works Great With
- **AI Services**: OpenAI, Anthropic Claude, Google Gemini, Llama, Mistral — see the [cookbook's provider-wiring recipes](doc/cookbook/README.md#wire-up-a-real-llm-provider-openai-anthropic-gemini-ollama) for copy-pasteable streaming snippets (OpenAI, Anthropic, Gemini, Ollama)
- **Backends**: Firebase, Supabase, REST APIs, WebSockets, GraphQL
- **Use Cases**: Customer support, AI assistants, team chat, social messaging
- **Industries**: SaaS, E-commerce, Healthcare, Education, Gaming

## RTL & Bidirectional Languages

The package ships first-class support for right-to-left scripts (Arabic, Hebrew, Persian, Urdu, Kurdish) — no extra dependency, no extra widget.

- **Locale-aware layout** — wrap the chat in `Directionality(textDirection: TextDirection.rtl, ...)` (or rely on your app's `Localizations`) and every surface mirrors: input row, send button, scroll, bubble alignment, copy button.
- **Per-message bidi auto-detect** — each bubble's `TextDirection` is inferred from its content (Arabic chars → RTL, ASCII → LTR), so mixed conversations render correctly in a single thread without per-message config.
- **Arabic word-splitting for streaming** — word-by-word streaming animates by whole Arabic words, not by code points (powered by `flutter_streaming_text_markdown` 1.7.0+).
- **Markdown still works**: headings, code blocks, blockquotes, tables all render bidi-correctly inside RTL bubbles (code itself stays LTR).

Minimal RTL setup:

```dart
Directionality(
  textDirection: TextDirection.rtl,
  child: AiChatWidget(
    currentUser: ChatUser(id: 'user', name: 'أنت'),
    aiUser: ChatUser(id: 'ai', name: 'المساعد'),
    controller: controller,
    onSendMessage: handleSend,
    enableMarkdownStreaming: true,
    exampleQuestions: const [
      ExampleQuestion(question: 'ما هي عاصمة العراق؟'),
      ExampleQuestion(question: 'اكتب لي قصيدة قصيرة'),
    ],
  ),
)
```

Full working screen with streaming Arabic markdown and example questions: [`example/lib/examples/rtl_chat.dart`](https://github.com/hooshyar/flutter_gen_ai_chat_ui/blob/main/example/lib/examples/rtl_chat.dart).

## Configuration Options

### AiChatWidget Parameters

#### Required Parameters
```dart
AiChatWidget(
  // Required parameters
  currentUser: ChatUser(...),  // The current user
  aiUser: ChatUser(...),       // The AI assistant
  controller: ChatMessagesController(),  // Message controller
  onSendMessage: (message) {   // Message handler
    // Handle user messages here
  },
  
  // ... optional parameters
)
```

#### Optional Parameters

```dart
AiChatWidget(
  // ... required parameters
  
  // Message display options
  messages: [],                // Optional list of messages (if not using controller)
  messageOptions: MessageOptions(...),  // Message bubble styling
  messageListOptions: MessageListOptions(...),  // Message list behavior
  
  // Input field customization
  inputOptions: InputOptions(...),  // Input field styling and behavior
  readOnly: false,             // Whether the chat is read-only
  
  // AI-specific features
  exampleQuestions: [          // Suggested questions for users
    ExampleQuestion(question: 'What is AI?'),
  ],
  persistentExampleQuestions: true,  // Keep questions visible after welcome
  enableAnimation: true,       // Enable message animations
  enableMarkdownStreaming: true,  // Enable streaming text (FIXED in v2.4.2+)
  streamingWordByWord: false,     // Control word-by-word vs character animation  
  streamingDuration: Duration(milliseconds: 30),  // Stream speed
  welcomeMessageConfig: WelcomeMessageConfig(...),  // Welcome message styling
  
  // Loading states
  loadingConfig: LoadingConfig(  // Loading configuration
    isLoading: false,
    showCenteredIndicator: true,
  ),
  
  // Pagination
  paginationConfig: PaginationConfig(  // Pagination configuration
    enabled: true,
    reverseOrder: true,  // Newest messages at bottom
  ),
  
  // Layout
  maxWidth: 800,             // Maximum width
  padding: EdgeInsets.all(16),  // Overall padding
  
  // Scroll behavior
  scrollBehaviorConfig: ScrollBehaviorConfig(
    // Control auto-scrolling behavior
    autoScrollBehavior: AutoScrollBehavior.onUserMessageOnly,
    // Scroll to first message of a response instead of the last (for long responses)
    scrollToFirstResponseMessage: true,
    // Hold the start of a streaming answer at the top of the viewport (2.16.0+)
    pinDuringStreaming: StreamingPinAnchor.responseStart,
  ),
  
  // Custom bubble styling lives in messageOptions. Use `bubbleBuilder` to wrap
  // the default bubble, or `customBubbleBuilder` (3-arg) to replace it entirely.
  messageOptions: MessageOptions(
    bubbleBuilder: (context, message, isCurrentUser, defaultBubble) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: defaultBubble, // wrap the default, or return your own UI
      );
    },
  ),
)
```

### Input Field Customization

The package offers multiple ways to style the input field.

#### Composer layout

Since 2.20 the composer is stacked by default: when an attach button or other leading content is present, the text field gets its own row and the attach and send buttons sit in a row below it. For the one-row composer of earlier versions, use `ComposerLayout.singleRow`. `FileUploadOptions.buttonPosition` puts the attach button before the field (`leading`, the default) or next to the send button (`trailing`):

```dart
AiChatWidget(
  // ... required parameters
  inputOptions: const InputOptions(
    composerLayout: ComposerLayout.singleRow, // [attach] field [send]
  ),
  fileUploadOptions: FileUploadOptions(
    onFilesSelected: (files) { /* pick and upload */ },
    buttonPosition: AttachmentButtonPosition.trailing, // field [attach] [send]
  ),
)
```

The welcome screen has matching options. `WelcomeMessageConfig(centerVertically: true)` centres the greeting in the empty chat. `singleColumnQuestions: true` stacks the suggestions one per row at full width instead of a two-column grid on wide screens.

#### Default Input

```dart
InputOptions(
  // Basic properties
  sendOnEnter: true,
  
  // Focus behavior (NEW in v2.4.2+)
  autofocus: true,          // Automatically focus the input field
  focusNode: myFocusNode,   // Custom focus node for external control
  
  // Styling
  textStyle: TextStyle(...),
  decoration: InputDecoration(...),
)
```

#### Minimal Input

```dart
InputOptions.minimal(
  hintText: 'Ask a question...',
  textColor: Colors.black,
  hintColor: Colors.grey,
  backgroundColor: Colors.white,
  borderRadius: 24.0,
  autofocus: true,        // Available in factory constructors too
  focusNode: myFocusNode, // Custom focus node support
)
```

#### Glassmorphic (Frosted Glass) Input

```dart
InputOptions.glassmorphic(
  colors: [Colors.blue.withOpacityCompat(0.2), Colors.purple.withOpacityCompat(0.2)],
  borderRadius: 24.0,
  blurStrength: 10.0,
  hintText: 'Ask me anything...',
  textColor: Colors.white,
  autofocus: false,       // Control autofocus behavior
  focusNode: myFocusNode, // Optional custom focus node
)
```

#### Custom Input

```dart
InputOptions.custom(
  decoration: yourCustomDecoration,
  textStyle: yourCustomTextStyle,
  sendButtonBuilder: (onSend) => CustomSendButton(onSend: onSend),
)
```

#### Always-Visible Send Button Without Focus Issues (version 2.0.4+)

The send button is now hardcoded to always be visible by design, regardless of text content. This removes the need for an explicit setting and ensures a consistent experience across the package.

By default:
- The send button is always shown regardless of text input
- Focus is maintained when tapping outside the input field
- The keyboard's send button is disabled by default to prevent focus issues on mobile

```dart
// Configure input options to ensure a consistent typing experience
InputOptions(
  // Prevent losing focus when tapping outside
  unfocusOnTapOutside: false,
  
  // Use newline for Enter key to prevent keyboard focus issues on mobile.
  // Hardware Enter on desktop/web still sends — see "Enter key behavior" below.
  textInputAction: TextInputAction.newline,
)
```

#### Enter key behavior (version 2.11.1+)

With `sendOnEnter: true` (the default), pressing Enter on a hardware keyboard sends the message. This works on macOS, Windows, Linux, web, and on iOS/Android devices with an attached physical keyboard.

- **Enter** — sends the current message.
- **Shift+Enter** — inserts a newline (ChatGPT/Claude style).
- **Numpad Enter** — sends.
- During CJK / IME composition, Enter commits the composition instead of sending.
- Set `sendOnEnter: false` to disable; Enter then always inserts a newline.

#### Stop / cancel generating (version 2.12.0+)

Provide an `onCancelGenerating` callback and the send button automatically turns into a **stop button** whenever `loadingConfig.isLoading` is `true`. The package doesn't run the generation itself, so the callback is where you cancel your own stream / HTTP request.

```dart
StreamSubscription<String>? _streamSub;
String? _currentId;
bool _isLoading = false;

AiChatWidget(
  // ...
  loadingConfig: LoadingConfig(isLoading: _isLoading),
  onCancelGenerating: () {
    _streamSub?.cancel();                       // stop your own work
    if (_currentId != null) {
      _controller.stopStreamingMessage(_currentId!); // finalize the partial bubble
    }
    setState(() => _isLoading = false);
  },
)
```

- The stop button only appears when `onCancelGenerating != null` **and** `isLoading == true`. Otherwise the normal send button is shown.
- Send-on-Enter (hardware and soft keyboard) is suppressed while the stop button is visible, so users can't queue a new message behind the in-flight one.
- Customize the button with `InputOptions(stopButtonIcon: ..., stopButtonColor: ...)`, or replace it entirely with `InputOptions(cancelButtonBuilder: (onCancel) => ...)`.

See `example/lib/examples/streaming_chat.dart` for a full working implementation.

### Scroll Behavior Configuration

Control how the chat widget scrolls when new messages are added:

```dart
// Default configuration with manual parameters
ScrollBehaviorConfig(
  // When to auto-scroll (one of: always, onNewMessage, onUserMessageOnly, never)
  autoScrollBehavior: AutoScrollBehavior.onUserMessageOnly,
  
  // Fix for long responses: scroll to first message of response instead of the last message
  // This prevents the top part of long AI responses from being pushed out of view
  scrollToFirstResponseMessage: true,
  
  // Customize animation
  scrollAnimationDuration: Duration(milliseconds: 300),
  scrollAnimationCurve: Curves.easeOut,

  // 2.16.0+: hold the start of the answer (or the user's question) at the top
  // of the viewport WHILE the answer streams — see the use case below
  pinDuringStreaming: StreamingPinAnchor.responseStart,
)

// Or use convenient preset configurations:
ScrollBehaviorConfig.smooth() // Smooth easeInOutCubic curve
ScrollBehaviorConfig.bouncy() // Bouncy elasticOut curve
ScrollBehaviorConfig.fast()   // Quick scrolling with minimal animation
ScrollBehaviorConfig.decelerate() // Starts fast, slows down
ScrollBehaviorConfig.accelerate() // Starts slow, speeds up
```

#### Use Case: Preventing Long Responses from Auto-Scrolling

When an AI returns a long response in multiple parts, scrollToFirstResponseMessage ensures users see the beginning of the response rather than being automatically scrolled to the end. This is crucial for readability, especially with complex information.

**For optimal scroll behavior with long responses:**
1. Mark the first message in a response with `'isStartOfResponse': true`
2. Link related messages in a chain using a shared `'responseId'` property
3. Set `scrollToFirstResponseMessage: true` in your configuration

#### Use Case: Reading a Long Answer While It Streams (`pinDuringStreaming`)

`scrollToFirstResponseMessage` acts once the answer has *finished*. For a single long
answer that is still streaming, the classic behaviour is that the bottom of the list
keeps following the new text, so the beginning scrolls out of view and you have to
wait for the end to start reading. `pinDuringStreaming` (2.16.0+) fixes that:

```dart
ScrollBehaviorConfig(
  // responseStart: hold the first line of the answer at the top of the viewport
  // userMessage:   hold your own question there instead, so Q and A read together
  pinDuringStreaming: StreamingPinAnchor.responseStart,
)
```

What the reader sees:

1. They send a question and the list scrolls to it as usual.
2. The answer starts streaming and the list follows it — *until* the anchor (the
   start of the answer, or the question) reaches the top of the viewport.
3. From then on the anchor is held there; new text arrives below the fold and the
   scroll-to-bottom button appears.
4. Any scroll gesture, or a tap on the scroll-to-bottom button, hands control back
   to the reader for the rest of that answer. In a reverse (newest-at-bottom) list the
   text they are reading also stays still while more chunks arrive, instead of being
   pushed upwards.
5. When the stream ends nothing jumps — the reader stays where they are.

The default is `StreamingPinAnchor.none` (unchanged behaviour). The pin arms whenever a
message streams: `addMessage`/`updateMessage` with `'isStreaming': true`, or
`addStreamingMessage` + `updateMessage` + `stopStreamingMessage`.

### Message Bubble Customization

```dart
MessageOptions(
  // Basic options
  showTime: true,
  showUserName: true,

  // Timestamp styling. `timeTextStyle` applies to both bubbles; the per-bubble
  // overrides (2.12.0+) take precedence when set — handy when a colored user
  // bubble makes the shared timestamp hard to read.
  timeTextStyle: const TextStyle(fontSize: 11, color: Colors.grey),
  userTimeTextStyle: const TextStyle(fontSize: 11, color: Colors.white70),
  aiTimeTextStyle: const TextStyle(fontSize: 11, color: Colors.black45),

  // Styling
  bubbleStyle: BubbleStyle(
    userBubbleColor: Colors.blue.withOpacityCompat(0.1),
    aiBubbleColor: Colors.white,
    userNameColor: Colors.blue.shade700,
    aiNameColor: Colors.purple.shade700,
    bottomLeftRadius: 22,
    bottomRightRadius: 22,
    enableShadow: true,
  ),
)
```

### Code Blocks & Syntax Highlighting

Fenced code blocks render through a built-in `CodeBlockView`: a header with the language label and a copy button, above horizontally-scrollable highlighted code. Highlighting is a lightweight pure-Dart tokenizer (no extra dependency) covering Dart, JavaScript/TypeScript, Python, Java, Kotlin, Swift, Go, Rust, C/C++/C#, JSON, YAML, Bash, SQL, and HTML/XML (other tags fall back to a generic tokenizer). Light and dark palettes follow the ambient brightness, code uses the bundled JetBrains Mono font on all platforms including web, and blocks stay LTR inside RTL chats.

```dart
AiChatWidget(
  // ... required parameters
  messageOptions: MessageOptions(
    enableSyntaxHighlighting: true,        // default; false renders plain mono text
    codeBlockTheme: CodeBlockTheme.dark(), // or your own CodeBlockTheme(...)
    showCodeBlockCopyButton: true,         // default; false hides the copy icon
  ),
)
```

To restyle the copy button (icon, colour, size, a text label), pass `codeBlockCopyButtonBuilder`. It receives whether the code was just copied and the callback that copies it:

```dart
MessageOptions(
  codeBlockCopyButtonBuilder: (context, copied, onCopy) => TextButton.icon(
    onPressed: onCopy,
    icon: Icon(copied ? Icons.check : Icons.copy_all, size: 14),
    label: Text(copied ? 'Copied' : 'Copy'),
  ),
)
```

`CodeBlockView` and `CodeBlockMarkdownBuilder` take the same builder as `copyButtonBuilder`.

### Custom Bubble Builder

Create completely custom message bubbles with full control over styling and behavior:

```dart
AiChatWidget(
  // ... other parameters
  messageOptions: MessageOptions(
    // Wrapper approach: enhance the default bubble (e.g. add a report button).
    // `bubbleBuilder` hands you the fully-styled default bubble to wrap.
    bubbleBuilder: (context, message, isCurrentUser, defaultBubble) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: defaultBubble,
      );
    },

    // Full-replacement approach (3-arg): rebuild the bubble from scratch.
    // customBubbleBuilder: (context, message, isCurrentUser) =>
    //     MyCustomBubble(message: message, isCurrentUser: isCurrentUser),
  ),
)
```

### Brand Theme Presets

Apply a `ChatGPT`/`Claude`/`Gemini`-style look with one line, via a `CustomThemeExtension` on your app's `ThemeData` — no need to set colors on every individual `AiChatWidget`:

```dart
MaterialApp(
  theme: ThemeData(
    extensions: [CustomThemeExtension.chatgpt()], // or .claude() / .gemini()
  ),
  // For dark mode: CustomThemeExtension.chatgpt(dark: true)
  home: MyChatScreen(),
)
```

Two more presets derive their colors from your app's existing `ColorScheme` instead of a fixed brand palette — handy when you want a theme-consistent look without picking your own bubble colors:

```dart
CustomThemeExtension.modern(Theme.of(context).colorScheme)  // richer surfaces
CustomThemeExtension.minimal(Theme.of(context).colorScheme) // flat, low-contrast
```

`CustomThemeExtension` sets `chatBackground`, `messageBubbleColor`/`userBubbleColor`/`messageTextColor`, `inputBackgroundColor`/`inputBorderColor`/`inputTextColor`/`hintTextColor`, and `sendButtonColor`/`backToBottomButtonColor` — all consulted only when the more specific `BubbleStyle`/`MessageOptions`/`InputOptions` value is left unset, so any explicit per-widget color you already set keeps winning. Build a fully custom one with `CustomThemeExtension(chatBackground: ..., messageBubbleColor: ..., ...)`.

## 🚀 AI Actions System

**Transform your chat into a powerful AI agent platform!** The AI Actions System allows your AI to execute real functions, display rich results, and maintain human oversight - taking your chat beyond simple text exchanges.

### ⚡ Quick Start with AI Actions

```dart
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';

class MyAiChat extends StatefulWidget {
  @override
  _MyAiChatState createState() => _MyAiChatState();
}

class _MyAiChatState extends State<MyAiChat> {
  late ChatMessagesController _controller;
  
  @override
  Widget build(BuildContext context) {
    return AiActionProvider(
      config: AiActionConfig(
        actions: [
          // Define what your AI can do
          AiAction(
            name: 'calculate',
            description: 'Perform mathematical calculations',
            parameters: [
              ActionParameter.number(name: 'a', description: 'First number', required: true),
              ActionParameter.number(name: 'b', description: 'Second number', required: true),
              ActionParameter.string(
                name: 'operation', 
                description: 'Math operation',
                required: true,
                enumValues: ['add', 'subtract', 'multiply', 'divide']
              ),
            ],
            handler: (params) async {
              final a = params['a'] as num;
              final b = params['b'] as num;
              final op = params['operation'] as String;
              
              double result;
              switch (op) {
                case 'add': result = a + b; break;
                case 'subtract': result = a - b; break;
                case 'multiply': result = a * b; break;
                case 'divide': result = a / b; break;
                default: throw 'Unknown operation';
              }
              
              return ActionResult.createSuccess({
                'result': result,
                'equation': '$a $op $b = $result'
              });
            },
            // Custom UI for results
            render: (context, status, params, {result, error}) {
              if (status == ActionStatus.completed && result?.data != null) {
                return Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      result!.data['equation'],
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              }
              return SizedBox.shrink();
            },
          ),
        ],
      ),
      child: AiChatWidget(
        // Your existing chat configuration
        currentUser: currentUser,
        aiUser: aiUser,
        controller: _controller,
        onSendMessage: _handleMessage,
      ),
    );
  }
  
  void _handleMessage(ChatMessage message) {
    // Add user message
    _controller.addMessage(message);
    
    // Simulate AI deciding to use an action
    if (message.text.contains('calculate')) {
      _executeCalculation(message.text);
    }
  }
  
  void _executeCalculation(String userMessage) async {
    final actionHook = AiActionHook.of(context);
    
    // AI parses user message and calls action
    final result = await actionHook.executeAction('calculate', {
      'a': 15,
      'b': 3,
      'operation': 'multiply'
    });
    
    // Add AI response with result
    _controller.addMessage(ChatMessage(
      text: result.success ? 
        'I calculated that for you: ${result.data['equation']}' : 
        'Sorry, calculation failed: ${result.error}',
      user: aiUser,
      createdAt: DateTime.now(),
    ));
  }
}
```

### 🎨 Action Features

#### **1. Function Calling with Validation**
```dart
AiAction(
  name: 'send_email',
  description: 'Send an email to a contact',
  parameters: [
    ActionParameter.string(
      name: 'to',
      description: 'Recipient email address',
      required: true,
      validator: (email) => email.contains('@'),  // Custom validation
    ),
    ActionParameter.string(
      name: 'subject',
      description: 'Email subject',
      required: true,
    ),
    ActionParameter.string(
      name: 'priority',
      description: 'Email priority level',
      enumValues: ['low', 'normal', 'high'],  // Constrained options
      defaultValue: 'normal',
    ),
  ],
  handler: (params) async {
    // Your email sending logic
    await sendEmailService(params);
    return ActionResult.createSuccess({'sent': true});
  },
)
```

#### **2. Human-in-the-Loop Confirmations**
```dart
AiAction(
  name: 'delete_file',
  description: 'Delete a file from storage',
  parameters: [...],
  confirmationConfig: ActionConfirmationConfig(
    title: 'Delete File',
    message: 'This action cannot be undone. Continue?',
    required: true,  // Always ask for confirmation
  ),
  handler: (params) async {
    // Only executed after user confirms
    await deleteFile(params['filename']);
    return ActionResult.createSuccess();
  },
)
```

#### **3. Real-time Status Updates**
```dart
AiAction(
  name: 'generate_report',
  description: 'Generate a comprehensive report',
  render: (context, status, params, {result, error}) {
    switch (status) {
      case ActionStatus.executing:
        return Card(
          child: Row(children: [
            CircularProgressIndicator(),
            Text('Generating report...'),
          ]),
        );
      case ActionStatus.completed:
        return ReportWidget(data: result!.data);
      case ActionStatus.failed:
        return ErrorWidget(error: error!);
      default:
        return SizedBox.shrink();
    }
  },
  handler: (params) async {
    // Long-running operation with progress updates
    return await generateComplexReport(params);
  },
)
```

#### **4. Event Streaming & Monitoring**
```dart
class MyAiChat extends StatefulWidget {
  @override
  _MyAiChatState createState() => _MyAiChatState();
}

class _MyAiChatState extends State<MyAiChat> {
  late StreamSubscription<ActionEvent> _actionSubscription;
  
  @override
  void initState() {
    super.initState();
    
    // Listen to all action events
    _actionSubscription = AiActionProvider.of(context).events.listen((event) {
      switch (event.type) {
        case ActionEventType.started:
          print('Action ${event.actionName} started');
          break;
        case ActionEventType.completed:
          print('Action ${event.actionName} completed: ${event.result?.data}');
          break;
        case ActionEventType.failed:
          print('Action ${event.actionName} failed: ${event.error}');
          break;
      }
    });
  }
  
  @override
  void dispose() {
    _actionSubscription.cancel();
    super.dispose();
  }
}
```

### 💡 Integration with AI Providers

#### **OpenAI Function Calling**
```dart
// Convert actions to OpenAI function format
final actionHook = AiActionHook.of(context);
final functions = actionHook.getActionsForFunctionCalling();

// Send to OpenAI with functions
final response = await openAI.createChatCompletion(
  messages: messages,
  functions: functions,
  functionCall: 'auto',
);

// Execute function if AI wants to call one
if (response.functionCall != null) {
  final result = await actionHook.handleFunctionCall(
    response.functionCall.name,
    json.decode(response.functionCall.arguments),
  );
}
```

#### **Custom AI Integration**
```dart
void _processAIMessage(String userMessage) async {
  // Your AI logic decides which action to call
  if (_shouldCalculate(userMessage)) {
    final actionHook = AiActionHook.of(context);
    
    // Extract parameters from user message
    final params = _parseCalculationParams(userMessage);
    
    // Execute action
    final result = await actionHook.executeAction('calculate', params);
    
    // Show result in chat
    _controller.addMessage(ChatMessage(
      text: 'Result: ${result.data}',
      user: aiUser,
      createdAt: DateTime.now(),
    ));
  }
}
```

### 🛡️ Security & Best Practices

- **Parameter Validation**: All inputs are validated before execution
- **User Confirmation**: Sensitive actions require explicit user approval  
- **Error Isolation**: Failed actions don't crash your app
- **Timeout Protection**: Long-running actions can be cancelled
- **Type Safety**: Full Dart type checking for all parameters
- **Event Auditing**: Complete log of all action executions

### 📚 Examples Included

The package includes complete working examples:
- **Weather Actions** - API calls with rich UI display
- **Calculator Actions** - Mathematical operations with validation
- **Unit Converter** - Type conversions with error handling
- **AI Integration** - Pattern matching and function calling

Run the example app to see AI Actions in action:
```bash
cd example/
flutter run
```

---

## Community & Support

- **🐛 [Issue Tracker](https://github.com/hooshyar/flutter_gen_ai_chat_ui/issues)**: report bugs and request features
- **📝 [Changelog](CHANGELOG.md)**: what changed in each release
- **⭐ [Star on GitHub](https://github.com/hooshyar/flutter_gen_ai_chat_ui)**: show your support

Built something with this package? Open an issue with a link and a screenshot, and it can be listed here.

---

**Made with ❤️ by the Flutter community** | **Star ⭐ this repo if it helped you!**