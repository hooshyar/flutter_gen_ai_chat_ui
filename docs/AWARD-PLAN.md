# Award Plan — path to Flutter Favorite / award-grade

Living document (task-016, GOAL item 7). Ranks what's left to make
`flutter_gen_ai_chat_ui` the go-to Flutter AI chat package, by value/effort,
cross-referencing the task backlog in `backlog/tasks/` rather than duplicating
it — each item below links to its backlog task file where one exists. Update
this file as tasks complete or new opportunities surface; don't let it go
stale the way the historical audits below did.

## Snapshot as of 2026-09-03 (v2.16.2)

- 100 likes, ~1,943 downloads/30d, 0 open PRs, 2 open issues (#41 roadmap
  tracker, #42 — pin feature shipped, awaiting reporter confirmation on
  2.16.2 after a same-day pin regression was found and fixed in 2.16.1).
- **`task-018` (cut the next release) is done — v2.16.2 published.** The
  previously-ranked #2 item here shipped: `CustomThemeExtension` fix, the
  dartdoc completion, wasm verification, this plan + repo polish, and the
  022-024 visual-QA fixes all reached pub.dev in one release. Also the
  first release to go out entirely through `task-017`'s GitHub Actions
  OIDC auto-publish — no manual `dart pub publish` step.
- **Confirmed 160/160 pub points** — a fresh, uncontended `pana` run
  against v2.16.2 (not the earlier resource-contended 60/160 reading this
  file used to warn about — that number was never real; superseded here).
  Full breakdown: 30/30 file conventions, 10/10 dartdoc, 10/10
  example+screenshots, 20/20 all-6-platforms, 50/50 static analysis, 10/10
  up-to-date deps (shimmer's warning below is still just a warning, not a
  deduction yet), 10/10 latest SDK, 20/20 downgrade compatibility. This is
  the number to protect going forward — re-run `pana --no-warning .` after
  any future release to confirm it's still holding.
- 426 package tests + 8 example tests green, `dart analyze --fatal-infos`
  clean (root + example), `dart format --set-exit-if-changed` clean,
  `dart pub publish --dry-run` clean, `flutter build web --wasm` clean.

## Time-sensitive (do first, small effort)

1. **`shimmer` dependency clock.** Held at `^3.0.0` since task-006
   (`shimmer` 4.0.0 needs Flutter `>=3.44.0`/Dart `^3.12.0`, above this
   package's declared floor). Pana: *"When shimmer is 30 days old, this
   package will no longer be awarded points in this category"* — it was
   13 days old at today's check, so **roughly 2.5 weeks of runway left**.
   Decide before it lapses: (a) raise the SDK floor to 3.44 (a real
   breaking-ish change — check how many consumers that actually excludes
   first), (b) replace `shimmer` with a hand-rolled shimmer effect (it's a
   small, well-understood animation — genuinely low effort to inline and
   removes the dependency entirely), or (c) accept the score hit as a
   documented tradeoff. Leaning toward (b): removes a dependency AND the
   recurring SDK-floor tension for good, for less code than it sounds.

## High value / low-medium effort

2. ~~**Cut the next release (`task-018`).**~~ **DONE (2026-09-03) — shipped as v2.16.2.** Bundled
   the `CustomThemeExtension` fix, dartdoc completion, deprecations, wasm CI guard, this plan, and
   the 022-024 visual-QA fixes. Re-run this same item (next release) whenever `[Unreleased]`
   accumulates real value again — see `task-018`'s own note that it's not one-and-done.
3. **Performance benchmarks (`task-014`).** The README's "Performance &
   Features" section makes specific, unverified claims — *"60 FPS with
   1000+ messages"*, *"Startup Time: <100ms initialization"*, *"Optimized
   for large conversations (10K+ messages)"* — and **zero benchmark test
   exists anywhere in the repo** to back any of them (confirmed via
   `grep -rl benchmark test/ example/` returning nothing). For a package
   actively positioning itself for "award-grade" status, shipped marketing
   claims with no test backing them is a real credibility risk if anyone
   ever benchmarks it and gets a different number. Add a timed harness
   (`flutter test` with a stopwatch, or `benchmark_harness`) building/
   scrolling a `ChatMessagesController` with 500–2000+ messages, record the
   actual numbers, and either confirm the README claims or correct them.
4. **Doc-drift + SDK-matrix CI (`task-012`).** The historical
   `doc/ONBOARDING_AUDIT.md` (iteration 10, now otherwise fully resolved —
   see below) found that hand-written example snippets in `AGENTS.md` and
   in class-level dartdoc had drifted from the actual public API (calling
   methods/factories that didn't exist) — a first-contact bug for anyone
   copy-pasting from the docs. That was fixed by hand that one time; a CI
   check that *compiles* README/cookbook snippets against the current API
   (or at minimum greps for a few known-fragile signatures) turns "caught
   eventually by a manual audit" into "caught automatically on the next
   drift." Bundle with the SDK-matrix half of the task (documented floor
   vs. latest stable, resolving the `flutter_lints`-forces-higher-dev-SDK
   note from #41).

## Medium value / medium effort

5. **Long-thread persistence + lazy pagination (`task-009`, issue #13).**
   Real, requested feature gap — an opt-in lazy-load-older-messages API
   plus a storage-agnostic persistence hook. Higher effort than most items
   here because it's new API surface, not a wire-up fix; pairs naturally
   with item 3's benchmark work (validate it actually helps).
6. **Attachments lightbox + multi-file (`task-008`).** Real, visible
   feature gap for a "complete file support" claim already in the README.
7. **Provider integration examples (`task-011`).** Low code effort (examples
   only, explicitly keep heavy SDKs out of `lib/`), decent value — backs
   the "Works Great With: OpenAI, Anthropic Claude, Google Gemini..." claim
   with copy-pasteable ~10-line snippets instead of just a bullet list.
8. **Scroll-debounce wall-clock flakiness (`task-019`).** Not a released bug
   (never shipped), but a recurring source of flaky local test runs under
   concurrent machine load. Needs either an injectable clock or a redesign
   of the debounce mechanism — worth doing before it causes a false CI
   failure someone has to re-run and shrug at.

## Lower value / niche, or genuinely optional polish

9. **Composite thinking→answer message API (`task-007`).** Currently a
   documented cookbook recipe using existing primitives
   (`ChatMessage.loading` → `updateMessage` → streamed text); a first-class
   helper is a convenience wrapper, not a capability gap. Fine to leave as
   a cookbook recipe indefinitely unless users specifically ask for the
   wrapper.
10. **Agent/tool-call renderer polish (`task-010`).** The agent surface is
    opt-in and already functional; this is visual polish on default
    renderers for users who don't supply their own `resultRenderers`. Real
    but narrow audience.

## Already-strong, keep as-is (don't rebuild these)

- **Streaming, markdown, RTL, theming, accessibility, dartdoc, goldens,
  wasm, CI gates** — all separately audited and fixed across
  `task-001`–`task-006`, `task-013`, `task-015`, `task-020`, `task-021`,
  and `task-002`'s two completed rounds. See `CHANGELOG.md`'s
  `[Unreleased]`/`2.16.0` sections for the itemized list; don't re-audit
  these from scratch without a specific new report or regression.

## Historical audits — status check

Two older documents in `doc/` (`ONBOARDING_AUDIT.md` iteration 10,
`ROADMAP_UI.md`) predate this backlog and were re-checked while writing
this plan rather than assumed current:

- **`doc/ONBOARDING_AUDIT.md`'s 5 queued items are now ALL resolved**,
  independently of this plan: README already leads with Install → Quick
  Start → the differentiator comparison table (`## Why this package?`) →
  a full end-to-end streaming snippet (`## Streaming AI responses`),
  ahead of the Features wall of text. An `## RTL & Bidirectional
  Languages` section exists with a working `rtl_chat.dart` example
  registered in the example gallery. The README's "Live Examples" list
  matches the actual 8 registered routes exactly (verified by diffing
  the bullet list against `example/lib/main.dart`'s routes). No action
  needed — this file is now purely historical; a future cleanup could
  archive or delete it rather than leave it looking like an open list.
- **`doc/ROADMAP_UI.md`** is a much larger, more speculative UI-component
  roadmap (sidecar panels, command palettes, parameter-form builders,
  etc.) from an earlier phase of the project. Not cross-checked
  line-by-line here — it reads as aspirational/exploratory rather than a
  committed backlog, and overlaps only loosely with the current
  `backlog/tasks/` decomposition. Worth a dedicated pass if UI-surface
  expansion becomes a priority, but out of scope for this plan.
- **`docs/issues-review/ISSUES.md`** is a complete historical dossier of
  every GitHub issue ever filed (mostly closed) — a reference, not a task
  list. Nothing actionable found there beyond what `#41`/`#42` already
  track live.

## Cheap wins implemented as part of this task (2026-09-03)

Per this task's own acceptance criteria ("implement the genuinely cheap
items directly"):

- Added `.github/FUNDING.yml` (GitHub-native Sponsor button on the repo
  page — distinct from `pubspec.yaml`'s `funding:` field, which only
  affects the pub.dev listing, not GitHub's UI). Pointed at the same
  `github.com/sponsors/hooshyar` already in `pubspec.yaml`.
- Added `.github/ISSUE_TEMPLATE/bug_report.md` and `feature_request.md` —
  the repo previously had only a custom "App Showcase" template and no
  standard bug/feature templates.
- Checked and left as-is (already done in earlier ticks, no action
  needed): `LICENSE` (MIT, present), `CONTRIBUTING.md` (present, covers
  tests/goldens/pre-submit checklist), `pubspec.yaml` `topics`/`funding`/
  `homepage`/`repository`/`issue_tracker`/`documentation`/`screenshots`
  (all present and populated).
