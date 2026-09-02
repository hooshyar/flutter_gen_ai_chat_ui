**Priority:** P1
**Component:** Test infra
**Origin:** Issue #41 Phase 1 (unchecked item)

**Acceptance criteria:**
- [ ] Add golden tests for: default bubble, welcome message, streaming message mid-stream, code
      block rendering, RTL (Arabic/Kurdish) layout.
- [ ] Wire into `flutter test --update-goldens` workflow; document regenerating goldens in CONTRIBUTING or README.
- [ ] CI runs golden tests on PRs.
- [ ] `flutter analyze` clean, `flutter test` green.
