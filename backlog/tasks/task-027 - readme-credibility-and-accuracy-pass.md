---
id: TASK-027
title: 'README credibility pass: remove unverifiable testimonials/featured apps, fix false claims, trim stale sections'
status: To Do
priority: high
labels:
  - P0
  - docs
  - discoverability
  - improvement-plan-2026-09
created_date: '2026-09-24'
---

## Description

The README is 1,039 lines and contains content that can hurt trust once a reader checks it:

- `### What Developers Say`: three testimonials credited to named people ("Sarah Chen", "Ahmed
  Hassan", "Maria Rodriguez"). They have no source.
- `### Featured Apps Using This Package`: five generic, unlinked claims, for example "SaaS company
  with 10K+ daily conversations" and "HIPAA-compliant patient communication".
- `## Why this package?` says "Markdown + code highlight in messages: Built-in". There is no syntax
  highlighter, and `MarkdownContent.enableSyntaxHighlighting` is a dead knob. See task-028.
- `## Recent Updates (v2.4.2+)` is stale: the current version is 2.19.1.
- The intro pitches "team chat, social messaging" and so dilutes the AI-chat positioning that search
  ranking rewards.
- The comparison table omits `flutter_ai_toolkit`, `genui`, and the actively maintained Flyer v2
  AI streaming package (`flyer_chat_text_stream_message`). Its `flutter_chat_ui: No streaming` row
  is now inaccurate.

## Acceptance Criteria
- [ ] Remove the testimonials and the featured-apps list. Replace them with a "Built with" section
      that links only to verifiable apps or repos (Parezar, if Hooshyar approves), or with a
      showcase-issue-template link.
- [ ] Correct every row of the comparison table against the live competitor READMEs, dated
      2026-09. Add `flutter_ai_toolkit` and `genui` columns, or a short note.
- [ ] Replace "Recent Updates (v2.4.2+)" with a link to CHANGELOG.
- [ ] Rewrite the first paragraph to lead with LLM/AI chat: streaming, reasoning, tools, LaTeX.
      Keep the `pubspec.yaml` description in sync (60-180 chars).
- [ ] Target length is 600 lines or fewer. Move deep configuration reference into `doc/`, or rely
      on the dartdoc, and link to it.
- [ ] `tool/check_doc_drift.dart` still passes. pana keeps 160/160.
