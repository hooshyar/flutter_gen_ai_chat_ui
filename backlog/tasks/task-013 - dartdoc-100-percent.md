**Priority:** P1
**Component:** Doc comments across lib/src/
**Origin:** GOAL item 4 (100% dartdoc)

**Acceptance criteria:**
- [ ] Run `dart doc` (or pana's doc-coverage check) to find undocumented public API members.
- [ ] Add concise dartdoc comments (what + why-non-obvious, no restating the name) to every public
      class/method/property missing one.
- [ ] Verify pana's documentation score component improves/stays maxed.
- [ ] `dart analyze --fatal-infos` clean.
