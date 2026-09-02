**Priority:** P1
**Component:** pubspec.yaml
**Origin:** GOAL item 5 + item 4 (flutter_streaming_text_markdown pin)

**Acceptance criteria:**
- [ ] Run `flutter pub outdated` (repo root and `example/`), record findings.
- [ ] Check pub.dev for `flutter_streaming_text_markdown`'s actual latest stable (a sibling session
      is upgrading it) — pin to that version once available; do not guess from memory.
- [ ] Upgrade all other deps to latest stable where safe; verify `flutter analyze` + `flutter test`
      stay green after each bump.
- [ ] Re-run `dart pub publish --dry-run` and pana score check after upgrading.
- [ ] Note in CHANGELOG.md.
