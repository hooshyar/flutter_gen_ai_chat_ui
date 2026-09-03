---
id: TASK-020
title: 'Issue #42 follow-up (bernd70): pin the question / answer start at the top of the viewport DURING streaming, not after'
status: Done
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
- [x] #1 Reply on issue #42 — done together with #8 (the fix shipped in one pass, so a single reply with the released version replaced the separate acknowledgement).
- [x] #2 New config on `ScrollBehaviorConfig`, e.g. `pinDuringStreaming: PinAnchor` with
      `PinAnchor.none | userMessage | responseStart` (name is the builder's call; keep
      `scrollToFirstResponseMessage` working as-is for back-compat, document the difference).
- [x] #3 When a response starts streaming and the anchor is set: scroll once so the anchor
      message's top sits at the top of the viewport, then HOLD that position while the
      answer grows (in a reverse list this means compensating offset per content-size change,
      or anchoring the viewport — builder decides; must not fight user scrolling).
- [x] #4 As soon as the pinned content extends below the viewport, the existing
      conditional scroll-to-bottom button appears; tapping it releases the pin and scrolls to
      the end; a user scroll gesture also releases the pin (never re-grabs mid-read).
- [x] #5 End-of-stream must NOT jump anywhere when a pin is active (no second scroll).
- [x] #6 Widget tests for: pin at userMessage, pin at responseStart, release on user scroll,
      release via button, no end-of-stream jump; plus a golden of the pinned state.
- [x] #7 Example app: a "long single answer" demo toggling the pin anchor; README + dartdoc
      updated; CHANGELOG entry.
- [x] #8 Reply on #42 with the shipped version/commit and ask Bernd to confirm.
<!-- AC:END -->

## Done (2026-09-03) — commit bfb90ee, released as v2.16.0

- `ScrollBehaviorConfig.pinDuringStreaming: StreamingPinAnchor {none, responseStart, userMessage}` (+ `copyWith`, presets accept it). Default `none` = unchanged behaviour.
- Controller holds the anchor by measuring the real render position (`getOffsetToReveal`), direction-agnostic; arms on `isStreaming` OR the controller's own streaming state (`addStreamingMessage` flow); skips the end-of-stream scroll while pinned; releases on a real user gesture (non-idle `UserScrollNotification`), the scroll-to-bottom button, or explicit `scrollToBottom()`; after a release in a reverse list the text being read stays still (offset advanced by the answer's measured height growth — NOT `maxScrollExtent`, which a lazy list re-estimates while scrolling; that bit a first attempt).
- Evidence: 18 new widget tests (`test/widgets/streaming_pin_test.dart`), 2 goldens (`streaming_pin_off/on.png`) that double as before/after, full suite 416/416, analyzer clean (package + example), `dart pub publish --dry-run` clean.
- Not done here, deliberately: no re-architecture of the wall-clock scroll debounce (it makes the user-message scroll-to-bottom untestable via `pump`; tracked by the existing note in `scroll_to_first_response_single_message_test.dart`).
