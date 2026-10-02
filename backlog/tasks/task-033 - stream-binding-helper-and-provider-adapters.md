---
id: TASK-033
title: 'One-line stream binding (controller.streamResponse) + firebase_ai / AG-UI adapter examples'
status: To Do
priority: medium
labels:
  - P1
  - dx
  - integrations
  - improvement-plan-2026-09
created_date: '2026-09-24'
---

## Description

task-011 added four copy-paste provider snippets. Each still hand-rolls add → update → stop →
error → cancel. Competitors differ: `flutter_ai_toolkit` ships a `LlmProvider` interface (with
firebase_ai), `dartantic_chat` ships dartantic_ai, and `flutter_ai_elements` ships
OpenAI/Anthropic/Gemini/MCP adapters. Time-to-first-streamed-token is the metric users judge a chat
kit by.

## Acceptance Criteria
- [ ] Add `ChatMessagesController.streamResponse(Stream<String> tokens, {ChatUser user, ...})` in
      core (no new deps). It creates the streaming message, appends chunks, completes it, maps
      errors to `hasError`/`errorMessage`, and cancels the subscription when the Stop button is
      pressed. Also add a variant that accepts `Stream<ChatStreamEvent>` (text / reasoning /
      tool-call deltas) so it can feed task-029 and task-030.
- [ ] Tests: normal completion, error mid-stream, stop/cancel (the subscription is cancelled), and
      dispose during a stream (no leaked timers).
- [ ] Cookbook: rewrite the 4 existing provider recipes to use it, and add `firebase_ai`
      (`generateContentStream`) and AG-UI (`ag_ui` package) recipes. Verify every API against the
      current pub.dev docs.
- [ ] Decision doc (in the plan or `doc/`): whether to publish thin sibling packages
      (`flutter_gen_ai_chat_ui_firebase`, `..._openai`) for discoverability. Hooshyar decides.
- [ ] The README Quick Start uses the helper and fits in about 20 lines.
