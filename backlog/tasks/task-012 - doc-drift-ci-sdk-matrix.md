**Priority:** P2
**Component:** CI (.github/workflows)
**Origin:** Issue #41 Phase 1 + Phase 2 (unchecked items)

**Acceptance criteria:**
- [x] Add a CI check that flags README/cookbook code snippets that no longer compile/match the
      current public API (doc/code drift).
- [x] Add a CI SDK matrix job testing against the documented Dart/Flutter floor version and latest
      stable — note in the workflow why a min *dev* SDK may need to be pinned higher than the
      consumer floor (flutter_lints forcing dev Dart ≥3.8 vs. floor 3.6, per #41 notes) — resolve or
      document the discrepancy.
- [x] CI green.

## Done (2026-09-03)

- **Doc-drift check**: `tool/check_doc_drift.dart` (no external deps, dart:io + RegExp) extracts
  every ```dart fence from README.md and AGENTS.md, finds `ClassName.member(...)` call sites against
  classes actually defined in `lib/`, and verifies each resolves to a real `factory`/`const` named
  constructor OR a `static` member (covers both preset builders like `CustomThemeExtension.chatgpt()`
  and cross-type accessors like `AiActionProvider.of(context)`) declared inside that class's own
  brace-balanced body — not just "the substring appears anywhere in lib/", which would also match
  stale mentions inside doc comments. Verified it actually has teeth by injecting a fake stale
  reference locally and confirming it fails (then reverted). 101 real call sites checked, 0 false
  positives after two rounds of tuning (initial version flagged 7 real static-method presets and 1
  `.of(context)` accessor as false positives — fixed by widening the resolution check, not by
  weakening it into an unreliable "contains anywhere" fallback). Wired as a new step in
  `analyze-format-test`.
- **SDK matrix**: new `sdk-matrix` job, 2 legs — floor (Flutter 3.27.0, confirmed via the Flutter
  releases API to bundle Dart 3.6.0, exactly matching this package's declared floor) and latest
  stable. **Resolved (not just documented) the #41 dev/consumer floor discrepancy**: the floor leg
  runs `example/`'s own `flutter pub get` + `flutter test`, not the root package's — the root's
  `flutter_lints: ^6.0.0` dev_dependency needs Dart `^3.8.0` (confirmed via pub.dev API) and would
  fail to resolve at the floor, but that's contributor tooling a real consumer never touches (pub
  ignores a dependency's own dev_dependencies); `example/` depends on this package as a normal
  dependency and pins its own `flutter_lints: ^3.0.1` (needs only Dart `^3.0.0`), so it's the
  accurate, honest proxy for what a real consumer experiences at the floor. Side benefit:
  `example/test/` (8 tests) now runs in CI for the first time — previously only ever run locally.
- `actionlint` clean on the modified workflow. 434/434 root tests + 8/8 example tests green locally,
  both `analyze --fatal-infos` clean, `dart format` clean.

**Status:** DONE.
