---
id: TASK-029
title: 'First-class reasoning/thinking block: collapsible, streaming, "Thought for Ns" (supersedes task-007)'
status: To Do
priority: medium
labels:
  - P1
  - feature
  - github-issue-37
  - improvement-plan-2026-09
created_date: '2026-09-24'
---

## Description

Thinking models (Claude extended thinking, OpenAI o-series/Responses reasoning summaries, Gemini
thinking) are now the default, and every leading AI-chat kit ships a reasoning component:
Vercel AI Elements `Reasoning`, assistant-ui, and `flutter_ai_elements` (`AiReasoning`,
`AiChainOfThought`). We have none. `lib/` only uses "reasoning" for agent routing. Issue #37
("Thinking bubble.. and Response") asked for this, and task-007 only proposed a
loading→answer wrapper.

This task supersedes task-007. Close task-007 as "superseded by TASK-029" when this starts.

## Acceptance Criteria
- [ ] Additive model support on `ChatMessage`, for example `reasoning` (String?) plus
      `reasoningDuration`/`isReasoning`, or a `ReasoningPart` if task-030 lands first. JSON
      round-trips it.
- [ ] Controller API: `appendReasoning(id, chunk)` / `endReasoning(id)`, or the equivalent, which
      streams into the block independently of the answer text.
- [ ] Default `ReasoningBlock` widget. It auto-expands while thinking, shows a shimmer "Thinking…"
      label, collapses to "Thought for Ns" when the answer starts, and can be tapped to expand. It
      is themeable and RTL-safe, and has a `reasoningBuilder` override.
- [ ] Widget tests: streaming → collapsed transition, expand/collapse, RTL, and semantics
      (expanded state announced). Add goldens for the expanded and collapsed states.
- [ ] Add a cookbook recipe for Anthropic `thinking_delta` and OpenAI reasoning summary deltas, plus
      an example-app demo.
- [ ] Zero breaking changes. Reply on #37.
