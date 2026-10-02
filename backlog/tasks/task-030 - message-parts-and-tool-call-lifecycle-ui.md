---
id: TASK-030
title: 'Parts-based message model + tool-call lifecycle UI (pending/running/result/error, approval) (supersedes task-010)'
status: To Do
priority: medium
labels:
  - P1
  - feature
  - agents
  - improvement-plan-2026-09
created_date: '2026-09-24'
---

## Description

The ecosystem has converged on a parts-based message model: the Vercel AI SDK `UIMessage.parts`
(text, reasoning, tool-*, source, file, data-*). `flutter_ai_elements` copies it explicitly.
Anthropic `content` blocks and OpenAI Responses `output` items map 1:1 onto it.

Our `ChatMessage` is a single `text` plus `customProperties`. Tool calls live in a separate
`AiActionProvider`/`ActionController` surface and have no per-message part, so an assistant turn
cannot interleave "text → tool call (running) → tool result → more text" inline.

This task supersedes task-010 (agent renderer polish). Close task-010 as superseded.

## Acceptance Criteria
- [ ] Design doc in `doc/` covering `MessagePart` (sealed class): `TextPart`, `ReasoningPart`
      (shared with task-029), `ToolCallPart` (id, name, args, state: pending | running |
      awaitingApproval | success | error, result), `SourcePart` (reuses `Citation`), `FilePart`
      (reuses `ChatMedia`), and `DataPart` (typed payload → `ResultRendererRegistry`).
      Get Hooshyar's sign-off before implementing.
- [ ] Additive: `ChatMessage.parts` is optional. When it is null, rendering is identical to today
      (goldens unchanged). `text` stays the source of truth for text-only messages.
- [ ] Default renderers: a collapsible tool card with name, status chip, args and result JSON, and a
      spinner or error state; a group view for consecutive tool calls; and approve/deny buttons for
      `awaitingApproval` that are wired to the existing human-in-the-loop confirmation.
- [ ] Controller helpers: `upsertPart(messageId, part)` / `updateToolCall(messageId, callId, ...)`,
      with streaming-safe updates.
- [ ] A widget test per tool state, one golden per state, and a dark-mode golden.
- [ ] Cookbook: map Anthropic `tool_use`/`tool_result` and OpenAI Responses `function_call` items
      to parts.
