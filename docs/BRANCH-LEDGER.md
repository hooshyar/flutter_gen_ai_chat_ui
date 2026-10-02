# Branch ledger (flutter_gen_ai_chat_ui)

Written 2026-10-02 during the fleet consolidation (Hooshyar: merge all work to main, keep nothing parked, lose nothing).

## State of main
- 2.20.0 is published and tagged (`v2.20.0`). Everything from the redesign (PR #44) and the 2026-09 improvement plan (PR #45) is on `main`.
- `agent/codeblock-_integration` was merged by PR #44 and was deleted (tip `2f4861a` is reachable from main).
- `gh-pages` is the generated web demo branch; it is deployed by CI and is not merged anywhere.

## Archive tags (kept, never deleted)
| Tag | What it holds | Decision |
|---|---|---|
| `archive/2026-10-02/agent/codeblock/hide` | old local branch with the `hide CodeBlockView` workaround for STM 1.10.1 | DROP: obsolete since STM 1.11.0 exports those names |
| `archive/2026-10-02/backup/wip-2026-10-02/development_flutter_gen_ai_chat_ui` | uncommitted `.claude/settings.local.json` only | DROP: local tool settings, now gitignored |
| `archive/2026-10-02/final-wip/development_flutter_gen_ai_chat_ui` | `.claude/agent-memory/dev-verify/*` notes about pana lower bounds and CI merge refs | DROP: agent scratch, folder now gitignored; the lessons are in the 2.20.0 changelog |

## Open backlog (not parked WIP, roadmap)
- task-026 (issue #42 round 2, scroll pin flicker): needs on-device verification and a patch release; Hooshyar to schedule.
- task-029 to 033 (reasoning block, message parts, message actions, stream helper): feature roadmap, no partial code exists.
- task-027 (README credibility), task-034 (coverage gate and deps hygiene), task-036 (example polish), task-037 (DotLoader recipe).

## Done in the consolidation pass
- task-025: Windows-invalid backlog filenames renamed, `portable-filenames` CI job added (issue #43).
- task-035: same-millisecond id collision fixed in the controller (tests in `test/controllers/id_collision_test.dart`), shipped as 2.20.1 once published.
- `.claude/settings.local.json` untracked, `.claude/agent-memory/` ignored.
