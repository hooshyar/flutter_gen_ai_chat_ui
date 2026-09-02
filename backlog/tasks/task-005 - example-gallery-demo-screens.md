**Priority:** P1
**Component:** example/ app
**Origin:** Issue #41 Phase 2 (unchecked item) + GOAL item 4 (demo GIFs + live web demo)

**Acceptance criteria:**
- [ ] Add a demo screen per major feature to `example/`: streaming, markdown/code blocks, RTL,
      theming/dark mode, agent/actions (#35), rich widget messages, voice input, attachments.
- [ ] Capture short GIFs of the key flows for README (streaming, theming, RTL, agent actions).
- [ ] Build the example app for web and deploy a live demo (GitHub Pages or existing static host) —
      link it from README.
- [ ] Update README with the gallery/demo links.
- [ ] `flutter analyze` clean on example/, `flutter test` on example/integration_test if present.

**Notes:** Web deploy target choice (GitHub Pages vs other) is a judgment call — GitHub Pages via
Actions is the lowest-friction default since it's already GitHub-native and free; use that unless
a blocker appears.
