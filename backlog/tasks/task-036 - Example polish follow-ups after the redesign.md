---
id: TASK-036
title: 'Example polish follow-ups after the redesign'
status: To Do
priority: low
labels:
  - example
  - polish
  - design
created_date: '2026-09-25'
---

## Description

These came from the final screenshot pass on the redesign branch (PR #44, verified at 45ae642). None of them block the release.

- **Actions:** the echoed user bubble drops the leading "/" ("calculate 42 * 7"). The gap between the tool-call JSON block and the result card is about 90px; tighten it to the 24px rhythm.
- **RTL demo:** the "View source" (open-in-new) icon gets mirrored. External-link icons usually shouldn't flip, so use `matchTextDirection: false` or a non-directional icon.
- **Phone:** long code lines clip at the block's right edge, and nothing shows the block scrolls sideways. Consider a visible scrollbar, or the existing right-edge fade on narrow widths too.
- **Themes demo:** the ChatGPT and Claude presets look nearly the same apart from accent and tint. Consider making the presets more distinct in the package.
- **Cold-start URL with a trailing slash** (e.g. /Streaming/): Flutter's initial-route splitting pushes Streaming twice.
