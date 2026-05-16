# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

`flutter_gen_ai_chat_ui` is a published Flutter package providing a chat UI kit for AI applications. It is a library — not an app — and the `example/` directory exists primarily as a manual smoke-test harness and as documentation for consumers.

- Package version: see `pubspec.yaml` (currently 2.11.0). Most architecture-significant changes ship as minor versions and are documented in `CHANGELOG.md`.
- SDK floor: Dart `>=2.19.0 <4.0.0`, Flutter `>=3.7.0`. Be careful before using newer language features.
- Platforms: android, ios, linux, macos, web, windows. Platform-specific code is rare; assume cross-platform unless touching `example/<platform>/`.

## Common Commands

```bash
# Install package deps (run from repo root, NOT from example/)
flutter pub get

# Static analysis — must be clean before publishing
flutter analyze
dart analyze --fatal-infos

# Format
dart format .

# Run all tests
flutter test

# Run a single test file
flutter test test/controllers/chat_messages_controller_test.dart

# Run a single test by name
flutter test test/controllers/chat_messages_controller_test.dart --plain-name "adds message"

# Integration tests live under example/integration_test (driver tests against the example app)
cd example && flutter test integration_test/

# Pre-publish dry run — must succeed before tagging a release
dart pub publish --dry-run
```

The example app has its own `pubspec.yaml` and `pubspec.lock`; running `flutter pub get` inside `example/` is a separate step from the package's own `pub get`.

## Architecture

### Two parallel surfaces: classic chat + agent platform

The package has grown beyond a chat UI into two overlapping surfaces, and code is organized accordingly. Knowing which surface a feature belongs to is the first thing to figure out before editing.

1. **Classic chat surface** — `AiChatWidget` + `ChatMessagesController` + `ChatMessage`. Messages are text/markdown bubbles, possibly streaming. This is what most consumers use.
2. **Agent / actions surface** — `AiActionProvider` + `ActionController` + `AgentOrchestrator` + agent models under `lib/src/agents/`. Lets the AI execute typed functions (with parameter validation, human-in-the-loop confirmation, and per-status custom rendering) and coordinate multiple agents. Lives alongside the classic surface and is opt-in: wrap `AiChatWidget` in an `AiActionProvider` to enable.

Both surfaces share the same widget tree, the same controller pattern, and the same `ChatMessage` model — but the agent surface adds its own controllers and providers under `lib/src/controllers/` (`action_controller.dart`, `agent_orchestrator.dart`, `ai_context_controller.dart`, `headless_chat_controller.dart`) and `lib/src/providers/`.

### Layer map

- `lib/src/widgets/` — `AiChatWidget` (the entry point; large file, comprehensive config) wraps `CustomChatWidget` (rendering primitives). `ChatInput` is the input row; it became stateful in 2.11 to power the mic/send toggle. `result/` and `voice/` subfolders hold action-result rendering and voice-input widgets.
- `lib/src/controllers/` — `ChatMessagesController` is the central message store and is what most consumers touch. The other controllers compose with it for the agent surface.
- `lib/src/models/` — Data classes. `chat/` subfolder holds `ChatMessage` and friends. `ai_action.dart` and `ai_agent.dart` define the agent surface's parameter, result, status, and event types. Most models are immutable; mutate via `copyWith`.
- `lib/src/providers/` — InheritedWidget-based providers that bridge the action system to the widget tree (`AiActionProvider`, `AiActionHook.of(context)`).
- `lib/src/agents/` — Agent definitions and orchestration helpers.
- `lib/src/services/` — Cross-cutting services (e.g., context tracking) that don't belong to any single widget.
- `lib/src/theme/` — `CustomThemeExtension` for typed theme access. Always read theme via `Theme.of(context).extension<...>()` rather than hard-coded colors.
- `lib/src/utils/` — Color helpers (note `withOpacityCompat` — used instead of `withOpacity` to support both old and new SDKs), locale helpers for RTL, glassmorphic container math.

### Streaming animation

Word-by-word streaming is delegated to the `flutter_streaming_text_markdown` package, gated by `enableMarkdownStreaming` and `streamingWordByWord`. Bug history: prior to 2.4.2 these flags were ignored. When changing streaming behavior, verify both flags actually disable animation as documented.

### Rich widget messages (2.9+)

`ChatMessage.rich(resultKind: ..., data: ...)` and `ChatMessage.loading(loadingKind: ...)` render full-width custom widgets via the `ResultRendererRegistry` passed through `AiChatWidget(resultRenderers: {...}, resultLoadingRenderers: {...})`. Detection is by `customProperties['resultKind']` / `['isLoading']` on the message. Rich messages **bypass the bubble decoration entirely** — no background, no padding, no max-width clamp — so renderers must own their own layout. When unmatched, they fall through to text rendering (don't crash on missing kinds).

### State management contract

`ChatMessagesController` is patterned on `TextEditingController` — it's a `ChangeNotifier`, owned by the consumer, and lives across rebuilds. `addMessage`, `updateMessage(id, ...)`, `clearMessages`, `scrollToBottom`. For streaming, the typical flow is: add a message with an id, then call `updateMessage` repeatedly with accumulated text. The same flow drives the loading→rich-widget morph (`ChatMessage.loading(...)` → `ChatMessage.rich(...)` via `updateMessage`).

`scrollToFirstResponseMessage` (in `ScrollBehaviorConfig`) requires that the first message of a multi-part response is marked with `customProperties['isStartOfResponse'] = true` and chained via a shared `customProperties['responseId']`. Without those flags it silently does nothing.

## Working in this repo

### Backwards compatibility

This is a published package on pub.dev. Breaking the public API forces a major version bump and migration work for consumers. Strongly prefer additive changes (new optional parameters, new factory constructors). If you must break something, leave the old API in place with `@Deprecated(...)` for at least one minor version, document the migration in `doc/MIGRATION.md`, and update `CHANGELOG.md`. Recent minor versions (2.7→2.11) are all zero-breaking-change releases — match that bar.

### Tests

Unit/widget tests live in `test/`, mirroring `lib/src/` structure. Driver-style integration tests live under `example/integration_test/` because they need a running app. New features should land with tests in both places when the feature has both internal logic (unit) and visible UI behavior (integration). The recent CHANGELOG entries explicitly count tests added — that's the project norm.

### Releasing

1. `flutter analyze` clean and `flutter test` green.
2. Bump `version:` in `pubspec.yaml` and the install snippet in `README.md`.
3. Add a `CHANGELOG.md` entry following the existing format (date, "Added/Changed/Fixed/Notes" sections, and an explicit zero-breaking-change note when applicable).
4. `dart pub publish --dry-run` must pass.
5. Tag and publish.

### Things that aren't obvious from grep

- `withOpacityCompat` exists because `withOpacity` was deprecated in newer Flutter versions but the SDK floor still supports the old API. Don't replace it with `withOpacity` even if your IDE suggests it.
- Math/LaTeX rendering (`flutter_math_fork`) is gated behind `enableMathRendering` on `AiChatWidget` — disabled by default to keep the cold path light.
- `flutter_markdown_plus` (a fork of `flutter_markdown`) is used instead of the official package. Don't switch back without checking why the fork was chosen.
- The send button is intentionally always visible regardless of input contents (decision documented in README "Always-Visible Send Button" section). Don't add an "is empty" gate without re-reading that section.
