**Priority:** P2
**Component:** Web/wasm compatibility
**Origin:** GOAL item 4 (wasm-ready)

**Acceptance criteria:**
- [ ] Run `flutter build web --wasm` on the example app; fix any incompatible APIs (e.g. `dart:html`
      direct usage, `dart:js` legacy interop) found in lib/src/.
- [ ] Add a CI job building web/wasm so regressions are caught.
- [ ] Document wasm support status in README.
