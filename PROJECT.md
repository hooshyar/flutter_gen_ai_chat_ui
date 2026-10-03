---
name: Flutter Gen AI Chat UI
client: Datacode (open source)
status: active
owner: Hooshyar
team: [Hooshyar]
stack: [Flutter, Dart, flutter_streaming_text_markdown, flutter_markdown_plus]
repo: hooshyar/flutter_gen_ai_chat_ui
prod: https://pub.dev/packages/flutter_gen_ai_chat_ui
updated: 2026-10-03
---

# Flutter Gen AI Chat UI

## Intent
Chat UI kit for AI apps on Flutter: streaming markdown with syntax-highlighted code, LaTeX, rich inline widgets, an agent and function-calling surface, RTL and theming. Streaming text comes from flutter_streaming_text_markdown. It is published on pub.dev for Flutter developers (and vendored in the Parezar mobile app). Standing goal (conductor NOTES.md, 2026-09-02): award-grade quality, 160/160 pub points, issues and PRs answered, dependencies on latest stable, releases cut.

## Current focus
- Issue #42 round 2 (task-026): `pinDuringStreaming` overshoots and snaps back, and the view jumps to the question after the stream ends. Needs on-device verification and a patch release.
- Release 2.20.1: the same-millisecond id collision fix (task-035) is on main but unreleased (pubspec is still 2.20.0). Replying to and closing issue #43 (Windows-invalid backlog filenames, fixed with a CI guard) needs Hooshyar.
- Roadmap, all To Do (tasks 029 to 033): reasoning block, message parts with tool-call lifecycle UI, message actions (regenerate, edit, feedback, retry), `controller.streamResponse` plus provider adapters, streaming accessibility.
- Hygiene, To Do: README credibility pass (027), dependency lower bounds and a CI coverage gate (034), example polish (036), DotLoader as a custom typing indicator recipe (037).

## Not doing
- Per DESIGN.md: no card, border, shadow or robot icon on AI messages by default, no brand-colored defaults (neutral by default, brand by opt-in), and no motion except streaming reveal, caret, thinking shimmer and the send-to-stop morph.
- Breaking the public API without a deprecation period; prefer additive changes (CLAUDE.md).

## How to run and verify
- From the repo root, not example/: `flutter pub get`, `flutter analyze`, `dart analyze --fatal-infos`, `flutter test`, `dart format --output=none --set-exit-if-changed .` (also inside example/; CI gates on it), `dart pub publish --dry-run`.
- Example integration tests: `cd example && flutter pub get && flutter test integration_test/`. The performance benchmarks are wall-clock sensitive: do not run them beside other heavy Flutter processes.
- Live demo: https://hooshyar.github.io/flutter_gen_ai_chat_ui/ (gh-pages, redeployed by deploy-web-demo.yml on pushes to main that touch example/, lib/ or pubspec.yaml).
- Release: a `vX.Y.Z` tag triggers publish.yml (pub.dev OIDC). It failed on the 2026-10-02 tags ("publishing from github is not enabled", task-017), so 2.20.0 went out by local `dart pub publish` from a clean clone. TODO: confirm whether automated publishing is enabled now.

## Decisions
- 2026-10-02: the 2.20.0 redesign changed the default look (document-style AI messages, new composer) with zero API breaks; DESIGN.md is the source of truth and is changed first, in the same PR.
- 2026-09-03: Flutter floor raised to 3.35.0 (google_fonts binds it) while the Dart `sdk` stays >=3.6.0 to avoid a forced reformat; re-run the sdk-matrix floor leg before changing either bound (task-012).
