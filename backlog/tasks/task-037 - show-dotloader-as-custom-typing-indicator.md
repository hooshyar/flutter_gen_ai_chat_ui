---
id: TASK-037
title: 'Document and demo DotLoader as a custom typing indicator'
status: To Do
priority: low
labels:
  - docs
  - example
  - cross-promotion
created_date: '2026-10-02'
---

## Description

Cross-repo follow-up of flutter_dot_loader TASK-005 (shipped in dot_loader 1.1.0, which has an inline, text-height `DotLoader` and the `DotLoader.thinking()` preset). Show it as an optional custom typing indicator, with no hard dependency.

## Acceptance Criteria
- [ ] README or cookbook recipe: use `flutter_dot_loader`'s `DotLoader.thinking()` through the existing typing-indicator builder (`typingIndicatorBuilder` or equivalent), clearly marked optional.
- [ ] One example screen or a toggle in the Themes demo that swaps the indicator, in the example app only (the example may depend on `flutter_dot_loader`, the package may not).
- [ ] pana stays 160/160 and the package `pubspec.yaml` gains no new dependency.
