---
id: TASK-028
title: 'Real syntax highlighting + per-block copy/language label for code blocks (wire the dead enableSyntaxHighlighting knob)'
status: To Do
priority: medium
labels:
  - P1
  - feature
  - markdown
  - improvement-plan-2026-09
created_date: '2026-09-24'
---

## Description

AI answers are code-heavy. Today, `rich_message_content.dart` `_buildCodeBlock` renders
monospace text with a background, and `MarkdownContent.enableSyntaxHighlighting` and `codeTheme`
are accepted but never used. The README advertises highlighting anyway. Among Flutter packages, only
`flutter_ai_elements` (`AiCodeBlock`) ships this. It is a standard Vercel AI Elements component.

Candidate implementation: `highlight` 0.7.0 is already present in the transitive graph via
`gpt_markdown`, or use `re_highlight`. Check each package's latest stable version, SDK floor, and
wasm compatibility on pub.dev before choosing. The highlighter must work while the block streams in
and while the closing fence is still missing.

## Acceptance Criteria
- [ ] Fenced code blocks in AI messages are syntax-highlighted for at least dart, python, js/ts,
      json, bash, sql, kotlin, swift, and html/css. Theme colours follow light and dark mode and can
      be overridden through `codeTheme` or the theme extension.
- [ ] A header row on each block shows the language label and a Copy button (48dp tap target,
      semantics label, localisable text).
- [ ] Opt-out through the existing `enableSyntaxHighlighting: false`, which is now wired.
- [ ] Partial or unterminated fences during streaming render without throwing or flicker. Add a
      golden that captures a mid-stream code block.
- [ ] Benchmark: highlighting a 300-line block adds under 16ms per rebuild on the perf harness, or
      the result is cached per block.
- [ ] `flutter build web --wasm` still clean. pana 160/160. No floor bump, or a documented one.
