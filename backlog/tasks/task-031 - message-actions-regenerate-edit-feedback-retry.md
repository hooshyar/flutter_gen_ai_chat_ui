---
id: TASK-031
title: 'Built-in message actions: regenerate, edit-and-resend, thumbs feedback, retry-on-error'
status: To Do
priority: medium
labels:
  - P1
  - feature
  - improvement-plan-2026-09
created_date: '2026-09-24'
---

## Description

Today only `showCopyButton`/`onCopy` exist. The `MessageOptions` docs tell consumers to build
feedback buttons themselves with a bubble builder. ChatGPT, Claude, and Gemini UIs, Vercel AI
Elements `Actions`/`Branch`, `flutter_ai_toolkit` (edit last prompt), and `flutter_ai_elements`
(actions, branch, retry) all ship these. `ChatMessage.hasError` exists, but it has no built-in retry
affordance.

## Acceptance Criteria
- [ ] `MessageOptions` gains opt-in flags and callbacks: `onRegenerate(ChatMessage)`,
      `onEditUserMessage(ChatMessage, String newText)`, `onFeedback(ChatMessage,
      MessageFeedback.up|down)`, and `onRetry(ChatMessage)`. Each button appears only when its
      callback is set, so default rendering is unchanged.
- [ ] The action row sits under AI messages (hover-reveal on desktop/web, always visible on mobile),
      is hidden while a message is streaming, and uses 48dp tap targets with semantics labels.
      Labels are localisable.
- [ ] Edit mode swaps the user bubble for an inline text field with Save and Cancel. On Save, the
      consumer decides whether to truncate later messages. Provide a `controller.truncateAfter(id)`
      helper.
- [ ] An error bubble shows `errorMessage` and a Retry button when `onRetry` is set.
- [ ] Optional: a version switcher ("< 2/3 >") for regenerated answers via
      `ChatMessage.alternatives`. It may be split into a follow-up task.
- [ ] Widget tests for each action, plus an example-app demo and README/cookbook docs.
