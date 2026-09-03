**Priority:** P1
**Component:** docs/AWARD-PLAN.md
**Origin:** GOAL item 7

**Acceptance criteria:**
- [x] Write `docs/AWARD-PLAN.md`: a ranked (value/effort) list of everything that would push this
      package toward Flutter Favorite / award-grade status, beyond what's already in this backlog.
- [x] Cross-reference existing backlog tasks (001-015+) rather than duplicating them.
- [x] Implement the genuinely cheap items directly (e.g. README badges, topics/keywords in
      pubspec for discoverability, LICENSE/FUNDING polish, CONTRIBUTING.md) as part of this task.
- [x] Keep it living — update as later tasks complete.

**Status:** DONE.

**Notes:**
- Ranked list (`docs/AWARD-PLAN.md`): time-sensitive shimmer dependency clock first, then
  release-next-version (task-018, best value/effort — real fixes already sitting unreleased),
  performance benchmarks (task-014 — README makes specific unverified perf claims with zero
  benchmark test anywhere to back them, a real credibility risk), doc-drift/SDK-matrix CI
  (task-012), then the medium/lower-value remaining tasks (009, 008, 011, 019, 007, 010).
- Re-checked the two pre-existing historical audit docs (`doc/ONBOARDING_AUDIT.md` iter-10,
  `doc/ROADMAP_UI.md`) instead of assuming they were still current: ONBOARDING_AUDIT.md's 5 queued
  items are now ALL independently resolved by later work (README structure, RTL section, example
  menu sync) — confirmed by direct inspection, not assumption. ROADMAP_UI.md is a much larger
  speculative UI-component roadmap, noted but not cross-checked line by line (out of scope).
- Ran `pana` for a current pub-score reading — came back 60/160, but the run was resource-contended
  (competing with a concurrent local `flutter test`) and every failing section's own error message
  says why: `Exceeded timeout of 0:02:00.000000` / `dart analyze timed out`. Independently
  re-verified `dart analyze --fatal-infos` (clean) and `dart doc .` (0 warnings, ~13s) immediately
  before and after — both contradict the pana failure messages. Documented this clearly in
  AWARD-PLAN.md rather than reporting the 60/160 number as real; flagged a clean re-run as a
  to-do. The ONE section pana did complete (dependencies) surfaced a genuine, already-tracked risk:
  `shimmer` was 13 days into its 30-day "up-to-date" grace window (task-006) — surfaced this with a
  concrete recommendation (inline a hand-rolled shimmer effect and drop the dependency) at the top
  of the plan.
- Cheap wins implemented directly: `.github/FUNDING.yml` (GitHub-native Sponsor button, distinct
  from pubspec's `funding:` which only affects pub.dev), `.github/ISSUE_TEMPLATE/bug_report.md` +
  `feature_request.md` (repo only had a custom showcase template before). LICENSE/CONTRIBUTING.md/
  pubspec topics/funding/homepage/etc. were all already present from earlier ticks — checked, no
  action needed.
