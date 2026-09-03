# Award Plan — path to Flutter Favorite / award-grade

Living document (task-016, GOAL item 7). Ranks what's left to make
`flutter_gen_ai_chat_ui` the go-to Flutter AI chat package, by value/effort,
cross-referencing the task backlog in `backlog/tasks/` rather than duplicating
it — each item below links to its backlog task file where one exists. Update
this file as tasks complete or new opportunities surface; don't let it go
stale the way the historical audits below did.

## Snapshot as of 2026-09-03 (v2.18.0)

- 0 open PRs, 2 open issues (#41 roadmap tracker — kept current, see its
  latest comment; #42 — pin feature shipped, awaiting reporter
  confirmation).
- **`task-018` (cut the next release) done again — v2.18.0 published**, a
  minor release for the one substantial item unreleased since v2.17.1:
  the opt-in `ChatPersistence` hook for long-running threads (task-009),
  plus the `scrollThreshold` deprecation. Minor bump (not patch) since
  `ChatPersistence` is genuinely new public API surface. Zero breaking
  changes. Task-018's own note that release-cutting isn't one-and-done
  held again — this file's job is to keep flagging when enough has
  accumulated to justify the next one.
- **Confirmed 160/160 pub points** — a fresh, uncontended `pana` run
  against v2.18.0. This is the number to protect going forward — re-run
  `pana --no-warning .` after any future release to confirm it's still
  holding.
- 443 package tests + 8 example tests green, `dart analyze
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

5. ~~**Long-thread persistence + lazy pagination (`task-009`, issue #13).**~~
   **DONE (2026-09-03).** The lazy-pagination half already existed
   (`loadMore`/`PaginationConfig`, genuinely wired to a scroll listener —
   confirmed by reading the code, not assumed) and is covered by task-014's
   benchmark suite. Added the genuinely new part: `ChatPersistence`, a
   storage-agnostic `loadMessages`/`saveMessages` hook wired into
   `ChatMessagesController` (`persistence`, `autoPersist`,
   `persistDebounce`, `restoreFromPersistence()`, `persistNow()`), debounced
   via a properly tracked-and-cancelled `Timer` (applying task-019's own
   lesson from earlier this session). Also deprecated the confirmed-dead
   `PaginationConfig.scrollThreshold`, closing a loose end open since
   task-002.
6. ~~**Attachments lightbox + multi-file (`task-008`).**~~ **DONE
   (2026-09-03).** Multi-file rendering already existed (confirmed by
   reading the code); added the missing pieces — a new `AttachmentLightbox`
   widget (pinch-zoom, swipe-between-images, opt-in via
   `MessageOptions.enableAttachmentLightbox`) and `ChatMedia.uploadProgress`
   (a generic per-file progress overlay, any attachment type). Both are
   additive/defaulted-off; an explicit `onMediaTap` always wins. 15 new
   tests.
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
