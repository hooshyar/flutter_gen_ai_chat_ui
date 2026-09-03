**Priority:** P1
**Component:** example/ app
**Origin:** Issue #41 Phase 2 (unchecked item) + GOAL item 4 (demo GIFs + live web demo)

**Acceptance criteria:**
- [x] Add a demo screen per major feature to `example/`: streaming, markdown/code blocks, RTL,
      theming/dark mode, agent/actions (#35), rich widget messages, voice input, attachments.
      Streaming/markdown/RTL/theming/actions/rich-widgets already existed
      (`basic_chat.dart`/`streaming_chat.dart`/`rtl_chat.dart`/`themed_chat.dart`/`actions_chat.dart`/
      `rich_widgets_chat.dart`). Added the two that were genuinely missing this tick:
      `attachments_chat.dart` (`FileUploadOptions` + attached-file rendering) and `voice_chat.dart`
      (`InputOptions.sendOrMicBuilder` + the package's `VoiceSendButton`). Both simulate the
      platform-specific half (real file picking / real speech recognition) since the package
      deliberately doesn't bundle either — consistent with `FileUploadOptions.onFilesSelected`'s own
      "the developer implements the actual file selection" design. Registered in `main.dart`'s routes
      and added to the home gallery card list. Added real widget tests for both
      (`example/test/attachments_chat_test.dart`, `example/test/voice_chat_test.dart`) plus replaced
      the placeholder no-op `example/test/widget_test.dart` with a real home-gallery smoke test.
- [ ] Capture short GIFs of the key flows for README (streaming, theming, RTL, agent actions) — NOT
      DONE. Recording a GIF means actually running the app and capturing screen video; checked for a
      `gif_creator`-style browser recording tool this tick and none is available in this session
      (only static screenshots via the browser tool). The live web demo (now up to date and linked
      from the README) makes it easy for anyone — including Hooshyar — to see these flows directly
      without a GIF; still worth doing properly in a future tick/session that has recording tooling.
      The 5 static golden PNGs from task-003 (`test/golden/goldens/*.png`) remain a viable interim
      static-screenshot substitute if a full GIF pass doesn't happen soon.
- [x] Build the example app for web and deploy a live demo (GitHub Pages or existing static host) —
      DONE. Discovered GitHub Pages was ALREADY enabled on this repo (`gh-pages` branch,
      `https://hooshyar.github.io/flutter_gen_ai_chat_ui/`) from a one-off manual deploy on
      2026-02-16 — stale (pre-2.15.0, missing the newer example screens) with no automation behind
      it. Added `.github/workflows/deploy-web-demo.yml` (builds `example/` for web with the correct
      `--base-href` and pushes to `gh-pages` via `peaceiris/actions-gh-pages` on every push to `main`
      touching the package/example, kept the existing branch-based Pages method rather than switching
      Pages' source setting). Also did an immediate manual redeploy so the demo is current right now
      rather than waiting for the next qualifying push, and dropped stray
      `example/.dart_tool/flutter_build` cache files the original manual deploy had accidentally
      committed. VERIFIED LIVE: navigated the actual deployed site with the browser tool, confirmed
      the home gallery renders (including the new Attachments/Voice Input cards), and both new demo
      screens work end-to-end in the browser (attach → PDF chip renders + AI acknowledges it; mic tap
      → simulated listening → recognized text fills the input).
- [x] Update README with the gallery/demo links — added `Attachments` and `Voice Input` to the
      "🎮 Live Examples" list, plus a link to the live web demo at the top of that section.
- [x] `flutter analyze` clean on example/ (`flutter analyze` — no `--fatal-infos` flag exists for
      that command variant used here, but zero issues found either way), `flutter test` green in
      `example/test/` (plain widget tests, no device needed). `example/integration_test/` was NOT
      run — it requires a real device/simulator per this project's own "don't run app on simulator"
      policy (see `ci.yml`'s comment); the new screens aren't referenced from integration_test/
      anyway (following the existing pattern where integration tests exercise the package's
      `AiChatWidget` API via `TestUtils`, not the example screens directly).

**Status:** IN PROGRESS — demo screens + live web deploy done and verified; only GIF capture remains
(needs recording tooling not available in this session).

**Notes:** Web deploy target choice (GitHub Pages vs other) is a judgment call — GitHub Pages via
Actions is the lowest-friction default since it's already GitHub-native and free; use that unless
a blocker appears.
