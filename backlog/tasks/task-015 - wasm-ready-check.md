**Priority:** P2
**Component:** Web/wasm compatibility
**Origin:** GOAL item 4 (wasm-ready)

**Acceptance criteria:**
- [x] Run `flutter build web --wasm` on the example app; fix any incompatible APIs (e.g. `dart:html`
      direct usage, `dart:js` legacy interop) found in lib/src/.
- [x] Add a CI job building web/wasm so regressions are caught.
- [x] Document wasm support status in README.

**Status:** DONE.

**Notes:**
- `flutter build web --wasm --release` (from `example/`) succeeded on the first try, zero source
  changes needed — the package doesn't use `dart:html`/`dart:js` legacy interop, `dart:mirrors`, or
  any other wasm-incompatible API. Confirmed the build genuinely produced and used
  `main.dart.wasm` (not a silent JS fallback): served `example/build/web` locally and checked
  network requests in a real browser — `main.dart.wasm` and CanvasKit's `skwasm.wasm` both loaded
  with 200s.
- Went further than "does it compile": actually exercised the running wasm build end-to-end
  (navigated the example app, opened the Streaming + Markdown demo, sent a message, watched the
  markdown response stream in) — zero console errors, correct rendering. A page can compile under
  dart2wasm but still fail at runtime for some API shapes, so this was worth the extra few minutes
  over a bare build check.
- Added the `wasm-build` job to `.github/workflows/ci.yml` (builds `example/` with `--wasm --release`
  on every push/PR to `main`) so a future dependency or code change that reintroduces an incompatible
  API fails CI immediately rather than being discovered only when a consumer tries it themselves.
- Documented in README under a new "Web / WebAssembly" subsection (in the Performance & Features
  section).
- `dart analyze --fatal-infos` clean, `flutter test` 425/425 green (no test changes needed — this
  task added CI/docs, not package code).
