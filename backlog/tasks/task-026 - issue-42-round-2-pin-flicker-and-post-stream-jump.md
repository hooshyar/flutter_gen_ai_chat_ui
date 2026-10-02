---
id: TASK-026
title: 'Issue #42 round 2: pinDuringStreaming overshoots and snaps back (flicker), and jumps to the question after the stream ends'
status: To Do
priority: high
labels:
  - P0
  - github-issue-42
  - scroll
  - improvement-plan-2026-09
created_date: '2026-09-24'
---

## Description

@bernd70 re-tested on 2.16.2 and 2.19.1 (comment on 2026-09-03T13:29Z, still unanswered) using
`pinDuringStreaming: StreamingPinAnchor.responseStart`:

1. **Flicker.** The list scrolls a few pixels past the pin target, then snaps back. This happens on
   every chunk. It still happens with `autoScrollBehavior: AutoScrollBehavior.never`.
2. **Post-stream jump.** After the message completes, the view scrolls back to the start of the
   *question* rather than holding on the response start. This contradicts the documented behaviour
   ("When the stream ends nothing jumps").

task-020 (Done) shipped the pin. This task reopens it. The earlier memory notes that programmatic
scrolls never emit a non-idle `UserScrollNotification`. Likely suspects:
- a per-chunk "follow" scroll that runs before the pin correction in the same frame;
- the `forceScrollToFirstMessageInChain` or `scrollToFirstResponseMessage` end-of-stream path,
  which still fires when a pin is active.

## Acceptance Criteria
- [ ] Reproduce both symptoms in a widget test with the reporter's shape: one short question plus
      one very long streamed answer, `reverse: true`, and the `addStreamingMessage` →
      `updateMessage` → `stopStreamingMessage` flow. The tests must fail on current `main`.
- [ ] Flicker: while pinned, the anchor's top offset is monotonic. Record the offset after every
      frame and assert that it never exceeds the target, then returns to it.
- [ ] Post-stream: after `stopStreamingMessage`, the scroll offset is unchanged (within 1px) for
      both `responseStart` and `userMessage`.
- [ ] The behaviour holds with every `AutoScrollBehavior` value.
- [ ] Verify manually in the example "Streaming + Markdown" screen (pin picker) on an iOS simulator
      and on web, and attach screenshots or a GIF.
- [ ] Ship a patch release. Reply on #42 with the version, and ask the reporter to confirm before
      closing.
