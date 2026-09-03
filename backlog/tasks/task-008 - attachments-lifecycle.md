**Priority:** P2
**Component:** MessageAttachment / result rendering
**Origin:** Issue #41 Phase 3 (unchecked item), builds on #40

**Acceptance criteria:**
- [x] Built-in lightbox/preview for image attachments.
- [x] Multi-file attachment support with per-file progress indicators.
- [x] Additive only — must not change existing `MessageAttachment`/`fileDisplayBuilder` behavior.
- [x] Tests for lightbox open/close, multi-file selection, progress state transitions.
- [x] Document in README/cookbook.

## Done (2026-09-03)

**Multi-file rendering already existed** — `custom_chat_widget.dart` already maps every entry in
`ChatMessage.media` to its own `MessageAttachment`, confirmed by reading the code rather than
assumed. The genuinely missing pieces were the lightbox and progress indicators:

- **`AttachmentLightbox`** (`lib/src/widgets/attachment_lightbox.dart`) — a full-screen
  `PageView`-based preview with `InteractiveViewer` pinch-zoom, a page indicator when there's more
  than one image, a filename caption, and both a close button and tap-outside-to-dismiss. Wired via
  2 new `MessageAttachment` params (`enableBuiltInLightbox`, `siblingMedia`) and 1 new
  `MessageOptions` field (`enableAttachmentLightbox`), all defaulted off/unset — an explicit
  `onMediaTap` always takes precedence, so no existing consumer's tap behavior changes.
- **`ChatMedia.uploadProgress`** (nullable `double`, 0.0-1.0) — `MessageAttachment` now renders a
  generic percentage overlay (works for every attachment type, not just images) whenever it's set
  and below 1.0, via a single wrapping check in `build()` rather than per-type builder changes.
- 15 new tests across `test/widgets/attachment_lightbox_test.dart` (open/close/swipe/dismiss) and
  `test/widgets/message_attachment_test.dart` (lightbox opt-in precedence, sibling-gallery
  filtering, progress overlay transitions, one full `AiChatWidget` end-to-end wiring test).
  Documented in `doc/cookbook/README.md`'s attachments recipe (updated the pre-existing, now
  slightly stale "roll your own lightbox" advice to point at the new built-in one) and linked from
  README's feature list.

458/458 tests green (443 + 15), `analyze --fatal-infos` clean (root + example), `dart format`
clean, `dart pub publish --dry-run` clean.

**Status:** DONE.
