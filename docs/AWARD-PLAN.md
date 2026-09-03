# Award Plan — path to Flutter Favorite / award-grade

Living document (task-016, GOAL item 7). Ranks what's left to make
`flutter_gen_ai_chat_ui` the go-to Flutter AI chat package, by value/effort,
cross-referencing the task backlog in `backlog/tasks/` rather than duplicating
it — each item below links to its backlog task file where one exists. Update
this file as tasks complete or new opportunities surface; don't let it go
stale the way the historical audits below did.

## Snapshot as of 2026-09-03 (v2.17.0)

- 0 open PRs, 2 open issues (#41 roadmap tracker — kept current, see its
  latest comment; #42 — pin feature shipped, awaiting reporter
  confirmation).
- **`task-018` (cut the next release) done again — v2.17.0 published.**
  Bundled everything unreleased since 2.16.2: the corrected Flutter floor
  (`>=3.35.0`, see task-012), the `shimmer` dependency removal, the new
  performance-benchmark suite (task-014), and the doc-drift + SDK-matrix
  CI checks (task-012). Zero breaking changes for anyone who could
  previously build the package. Task-018's own note that release-cutting
  isn't one-and-done held again — this file's job is to keep flagging
  when enough has accumulated to justify the next one.
- **Confirmed 160/160 pub points** — a fresh, uncontended `pana` run
  against v2.17.0. Full breakdown: 30/30 file conventions, 10/10 dartdoc,
  10/10 example+screenshots, 20/20 all-6-platforms, 50/50 static
  analysis, 10/10 up-to-date deps (the `shimmer` dependency-freshness
  warning that used to sit here is gone — the dependency itself was
  removed), 10/10 latest SDK, 20/20 downgrade compatibility. This is the
  number to protect going forward — re-run `pana --no-warning .` after
  any future release to confirm it's still holding.
- 434 package tests + 8 example tests green (the example suite now also
  runs in CI, not just locally — see task-012), `dart analyze
  --fatal-infos` clean (root + example), `dart format
  --set-exit-if-changed` clean,
  `dart pub publish --dry-run` clean, `flutter build web --wasm` clean.

## Time-sensitive (do first, small effort)

1. ~~**`shimmer` dependency clock.**~~ **DONE (2026-09-03).** Replaced the
   package's one usage site (`LoadingWidget`'s shimmering loading text) with
   a small hand-rolled `ShaderMask` + `AnimationController` sweep and removed
   the `shimmer` dependency entirely (option (b) from this item's original
   analysis). No public API changes, 426 tests still green. Permanently
   removes both the pana dependency-freshness risk and the recurring
   SDK-floor tension — nothing to revisit here going forward.

## High value / low-medium effort

2. ~~**Cut the next release (`task-018`).**~~ **DONE (2026-09-03) — shipped as v2.16.2.** Bundled
   the `CustomThemeExtension` fix, dartdoc completion, deprecations, wasm CI guard, this plan, and
   the 022-024 visual-QA fixes. Re-run this same item (next release) whenever `[Unreleased]`
   accumulates real value again — see `task-018`'s own note that it's not one-and-done.
3. ~~**Performance benchmarks (`task-014`).**~~ **DONE (2026-09-03).** Added
   `test/performance/message_list_benchmark_test.dart` (8 tests) timing
   `ChatMessagesController` build/append/streaming-update paths at
   500-2000 messages and `AiChatWidget`'s initial render + scroll at 1000
   messages. Real numbers recorded in `CHANGELOG.md`. Confirmed the message
   list already uses a lazy `ListView.builder` and quantified (but didn't
   need to fix) a small, real O(n) `indexWhere` cost in `updateMessage` for
   chronological order — too small in absolute terms (single-digit ms for
   100 streaming updates over 2000 messages) to be a real bottleneck. No
   follow-up task filed.
4. ~~**Doc-drift + SDK-matrix CI (`task-012`).**~~ **DONE (2026-09-03).**
   Added `tool/check_doc_drift.dart` (wired into CI) — checks every
   `ClassName.member(...)` call site in README.md/AGENTS.md's ```dart
   fences against real factory/named/static members in `lib/`. Added a
   `sdk-matrix` CI job (floor vs. latest stable), resolving (not just
   documenting) the `flutter_lints`-forces-higher-dev-SDK discrepancy from
   #41 by testing the floor through `example/` (a real consumer) rather
   than the root package (whose dev-only `flutter_lints` pin genuinely
   can't resolve at the floor, which is fine — consumers never touch a
   dependency's dev_dependencies). **The floor leg immediately found a
   real bug, twice in a row**: the documented Flutter floor (`3.27.0`) had
   never actually resolved — first `flutter_streaming_text_markdown` needs
   `characters >=1.4.0` (unavailable below Flutter `3.29.0`), then, after
   fixing that, `google_fonts ^8.1.0`'s own floor (`flutter >=3.35.0`)
   turned out to be the real binding constraint. CI running only on
   `stable` had silently masked a floor that was wrong this whole time.
   Corrected to `flutter: ">=3.35.0"` (Dart `sdk:` stays at `3.6.0`
   deliberately, to avoid Dart 3.7's formatter-style cliff).

## Medium value / medium effort

5. **Long-thread persistence + lazy pagination (`task-009`, issue #13).**
   Real, requested feature gap — an opt-in lazy-load-older-messages API
   plus a storage-agnostic persistence hook. Higher effort than most items
   here because it's new API surface, not a wire-up fix; pairs naturally
   with item 3's benchmark work (validate it actually helps).
6. **Attachments lightbox + multi-file (`task-008`).** Real, visible
   feature gap for a "complete file support" claim already in the README.
7. ~~**Provider integration examples (`task-011`).**~~ **DONE (2026-09-03).**
   Added 4 copy-pasteable streaming snippets (OpenAI, Anthropic, Gemini,
   Ollama) to `doc/cookbook/README.md`, using `package:http` directly —
   no vendor SDK added to `lib/` or `example/`. Each provider's current
   wire format was verified via web search before writing (not assumed
   from memory); Gemini's endpoint in particular needed a second,
   corroborating check after an initial search surfaced an unfamiliar
   alternate API that didn't hold up under scrutiny.
8. ~~**Scroll-debounce wall-clock flakiness (`task-019`).**~~ **DONE
   (2026-09-03).** Injected `package:clock` into the 3 debounce call sites
   (zero behavior change — defaults to real wall-clock time). A first
   attempt at the alternative fix (an always-armed boolean+Timer flag)
   empirically made things worse (100+ new failures) before being reverted
   — recorded in the CHANGELOG so it isn't retried blind. Added 2 tests
   using a fake clock to force the race on demand.

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
