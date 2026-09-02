**Priority:** P2
**Component:** CI (.github/workflows)
**Origin:** Issue #41 Phase 1 + Phase 2 (unchecked items)

**Acceptance criteria:**
- [ ] Add a CI check that flags README/cookbook code snippets that no longer compile/match the
      current public API (doc/code drift).
- [ ] Add a CI SDK matrix job testing against the documented Dart/Flutter floor version and latest
      stable — note in the workflow why a min *dev* SDK may need to be pinned higher than the
      consumer floor (flutter_lints forcing dev Dart ≥3.8 vs. floor 3.6, per #41 notes) — resolve or
      document the discrepancy.
- [ ] CI green.
