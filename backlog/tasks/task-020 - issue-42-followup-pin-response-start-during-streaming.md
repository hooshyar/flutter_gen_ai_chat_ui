---
id: TASK-020
title: 'Issue #42 follow-up (bernd70): pin the question / answer start at the top of the viewport DURING streaming, not after'
status: To Do
priority: high
labels:
  - P1
  - github-issue-42
  - scroll
created_date: '2026-09-03'
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
bernd70 tested the task-001 fix (7022038 / c51d1cd) and replied on
https://github.com/hooshyar/flutter_gen_ai_chat_ui/issues/42 at 2026-09-02 21:50 UTC
(no reply from us yet — reply FIRST, before building, so he knows it was heard):

> The long AI answer fully scrolls to the end and when it is finished it jumps to the start.
> This is not the behaviour I expected or wished for. I would prefer a pinning approach:
> 1. I hit Go on my question
> 2. The AI starts answering and the screen starts scrolling
> 3. Now my question or the start of the AI's answer (should be definable) should NOT scroll
>    out of the viewport. The conditional scroll-to-bottom button appears
> 4. Now I can read the answer and scroll to the end at my reading speed

Root cause of the observed behaviour (verified 2026-09-03 in
`lib/src/controllers/chat_messages_controller.dart`):
- while `isStreaming == true` the controller only calls `notifyListeners()` (no scroll);
  because the list is `reverse: true` with offset 0, the growing answer keeps the BOTTOM
  visible, i.e. the answer start scrolls away — this is step 2/3 failing.
- only at end-of-stream does the `scrollToFirstResponseMessage` branch call
  `forceScrollToFirstMessageInChain` — that is the "jumps to the start when finished".
So task-001 fixed the *targeting* of the end-of-stream jump (real bug), but the feature
Bernd wants is a **streaming-time pin**, which does not exist yet.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Reply on issue #42 acknowledging the pinning request and outlining the plan (before code).
- [ ] #2 New config on `ScrollBehaviorConfig`, e.g. `pinDuringStreaming: PinAnchor` with
      `PinAnchor.none | userMessage | responseStart` (name is the builder's call; keep
      `scrollToFirstResponseMessage` working as-is for back-compat, document the difference).
- [ ] #3 When a response starts streaming and the anchor is set: scroll once so the anchor
      message's top sits at the top of the viewport, then HOLD that position while the
      answer grows (in a reverse list this means compensating offset per content-size change,
      or anchoring the viewport — builder decides; must not fight user scrolling).
- [ ] #4 As soon as the pinned content extends below the viewport, the existing
      conditional scroll-to-bottom button appears; tapping it releases the pin and scrolls to
      the end; a user scroll gesture also releases the pin (never re-grabs mid-read).
- [ ] #5 End-of-stream must NOT jump anywhere when a pin is active (no second scroll).
- [ ] #6 Widget tests for: pin at userMessage, pin at responseStart, release on user scroll,
      release via button, no end-of-stream jump; plus a golden of the pinned state.
- [ ] #7 Example app: a "long single answer" demo toggling the pin anchor; README + dartdoc
      updated; CHANGELOG entry.
- [ ] #8 Reply on #42 with the shipped version/commit and ask Bernd to confirm.
<!-- AC:END -->
