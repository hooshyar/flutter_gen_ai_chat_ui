---
id: TASK-025
title: 'Fix #43: rename backlog files with Windows-invalid characters and add a CI guard'
status: To Do
priority: high
labels:
  - P0
  - github-issue-43
  - improvement-plan-2026-09
created_date: '2026-09-24'
---

## Description

GitHub issue #43 (@BenjaminKobjolke, 2026-09-12): Windows users cannot `git pull`/clone `main`.
Two tracked paths contain `"` and `:`, which Windows reserves:

- `backlog/tasks/task-023 - Attachments and Voice Input demos reply with a canned "switch themes" message that does not fit the screen.md`
- `backlog/tasks/task-024 - Rich Widgets: "Add to Cart" on the product card gives no feedback.md`

Every Windows contributor is blocked, and so is any Windows consumer who uses a git dependency.
This is the cheapest high-impact fix in the plan. See docs/IMPROVEMENT-PLAN-2026-09.md (P0-1).

## Acceptance Criteria
- [ ] `git mv` both files to slug names (e.g. `task-023 - attachments-voice-canned-reply.md`,
      `task-024 - rich-widgets-add-to-cart-feedback.md`). Frontmatter `title:` is unchanged.
- [ ] Add a CI step (in `ci.yml`, analyze job) that fails when any tracked path contains
      `<>:"\|?*`, a trailing space or dot, or a reserved name (CON, PRN, AUX, NUL, COM1-9, LPT1-9).
      For example: `git ls-files | grep -E '[<>:"\\|?*]|[ .]$'` returns non-zero.
- [ ] Update the conductor/backlog tooling note so new task filenames are slugified. The backlog CLI
      titles with quotes and colons produced these names.
- [ ] Reply on #43 and close it once merged to main.
