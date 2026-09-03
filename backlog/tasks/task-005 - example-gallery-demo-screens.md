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
      DONE this tick. Recording a GIF means actually running the app and capturing screen video,
      which needs either a real device/simulator session or browser-based capture — deferred rather
      than rushed with a fake/placeholder asset. The 5 static golden PNGs from task-003
      (`test/golden/goldens/*.png`) could serve as an interim static-screenshot substitute in the
      README if a full GIF pass doesn't happen soon; a future tick (or Hooshyar) should do the real
      GIF capture.
- [ ] Build the example app for web and deploy a live demo (GitHub Pages or existing static host) —
      NOT DONE this tick — deferred to keep this tick's scope to a completable unit (the demo
      screens). `flutter build web` itself needs no simulator/device (pure build), so this is
      actually safe to pick up in a future tick: build the example for web, add a GitHub Actions
      workflow to deploy `example/build/web` to GitHub Pages on push to `main`, link it from the
      README.
- [x] Update README with the gallery/demo links — added `Attachments` and `Voice Input` to the
      "🎮 Live Examples" list.
- [x] `flutter analyze` clean on example/ (`flutter analyze` — no `--fatal-infos` flag exists for
      that command variant used here, but zero issues found either way), `flutter test` green in
      `example/test/` (plain widget tests, no device needed). `example/integration_test/` was NOT
      run — it requires a real device/simulator per this project's own "don't run app on simulator"
      policy (see `ci.yml`'s comment); the new screens aren't referenced from integration_test/
      anyway (following the existing pattern where integration tests exercise the package's
      `AiChatWidget` API via `TestUtils`, not the example screens directly).

**Status:** IN PROGRESS — demo screens done; GIFs and live web deploy remain (see notes above).

**Notes:** Web deploy target choice (GitHub Pages vs other) is a judgment call — GitHub Pages via
Actions is the lowest-friction default since it's already GitHub-native and free; use that unless
a blocker appears.
