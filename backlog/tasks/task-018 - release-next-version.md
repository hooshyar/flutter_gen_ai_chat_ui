**Priority:** P1
**Component:** Release
**Origin:** GOAL item 6

**Problem:** Once task-001 (fix #42) and a meaningful slice of the roadmap items above are done,
cut the next release.

**Acceptance criteria:**
- [ ] `flutter analyze` clean, `flutter test` green, `dart pub publish --dry-run` passes.
- [ ] Bump `version:` in pubspec.yaml + README install snippet.
- [ ] CHANGELOG.md entry (Added/Changed/Fixed/Notes, zero-breaking-change note if applicable).
- [ ] Tag `vX.Y.Z` and push — confirm CI publish succeeds (see task-017 gate) or fall back to
      local `dart pub publish` if automated publishing still isn't enabled.
- [ ] Verify the pub.dev package page reflects the new version and pana score.
- [ ] Reply/close relevant GitHub issues (#42 at minimum) referencing the released version.

**Notes:** Re-run this task for each subsequent release as the backlog above gets worked through —
don't treat it as one-and-done.
