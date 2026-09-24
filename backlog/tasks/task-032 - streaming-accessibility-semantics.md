---
id: TASK-032
title: 'Accessibility depth: message semantics, streaming live-region announcements, reduced motion'
status: To Do
priority: medium
labels:
  - P1
  - accessibility
  - improvement-plan-2026-09
created_date: '2026-09-24'
---

## Description

task-004 fixed tap targets, but the widget tree has only about 11 `Semantics`/`semanticsLabel`
sites across `lib/`. It has no `liveRegion` and no per-message semantics ("Assistant said: …, 2:14
PM"). Streaming text either spams TalkBack/VoiceOver with a re-announcement per token or announces
nothing. Streaming animations ignore `MediaQuery.disableAnimations`.
`flutter_ai_elements` markets streaming-safe semantics as a differentiator. Accessibility is also a
Flutter Favorite criterion.

## Acceptance Criteria
- [ ] Each message is one semantics node with a role-prefixed label (sender, text, time, and
      attachment count). Decorative avatars and timestamps are excluded or merged.
- [ ] Streaming produces one polite announcement when a message completes, not one per chunk, via
      `SemanticsService.announce` or a debounced live region. Opt-out through
      `accessibilityConfig`.
- [ ] Word-by-word and fade animations are disabled when `MediaQuery.disableAnimationsOf(context)`
      is true, and the text renders immediately.
- [ ] The composer has a logical focus order (attach → text field → mic/send). The scroll-to-bottom
      and stop buttons are labelled.
- [ ] Tests use `tester.ensureSemantics()`, `meetsGuideline(labeledTapTargetGuideline)`,
      `textContrastGuideline` on the default light and dark themes, and a test that verifies a
      single announcement per streamed message.
- [ ] Manual VoiceOver pass on an iOS simulator, documented in `doc/ACCESSIBILITY.md`.
