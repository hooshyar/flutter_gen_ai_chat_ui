# Improvement Plan — 2026-09

Research and planning pass done 2026-09-24 against `main` @ `fe07759` (v2.19.1). No library code
changed. This plan sits on top of `docs/AWARD-PLAN.md`, which records everything shipped up to
2.19.1; the new backlog tasks are `task-025` … `task-034`.

**Summary:** The quality work is done: 160/160 points, a clean analyzer, 458 tests, goldens, a
wasm build, and CI gates. The package now trails on features. Since mid-2025, AI-chat UX has settled
on a common set of parts: reasoning blocks, tool-call parts, regenerate/edit, syntax-highlighted
code, and streaming-safe a11y. We ship none of them. A Flutter package that copies that set
(`flutter_ai_elements`) appeared in August 2026, and Google's `genui` has 10× our downloads. We
also have two credibility bugs to fix first: Windows users cannot clone the repo (#43), and #42 was
re-reported unfixed three weeks ago with no reply.

---

## 1. Current state snapshot

### Metrics (pub.dev API, 2026-09-24)

| Metric | Value |
|---|---|
| Version | 2.19.1 (published 2026-09-03, no release since) |
| Pub points | **160 / 160** (pana report 2026-09-23: success) |
| Likes | 101 |
| Downloads (30d) | 3,477, up from ~1,943 on 2026-09-03 |
| Tags | wasm-ready, dart3-compatible, 6 platforms, has:screenshot, has:funding-link |
| Topics | ai, chat, llm, streaming, markdown |
| Publisher | dilacode.com |
| GitHub | 3 open issues (#41 roadmap, #42, #43), 0 open PRs |

### Code health

| Check | Result |
|---|---|
| `flutter analyze` (Flutter 3.47.5 / Dart 3.13.4) | **No issues found** (root + example) |
| `flutter test` | see §1.4 |
| Library size | 25,140 lines in `lib/`. The two largest files are `custom_chat_widget.dart` (2,131 lines) and `chat_messages_controller.dart` (1,768 lines) |
| Public exports | 55 files exported from `lib/flutter_gen_ai_chat_ui.dart` (a large API surface) |
| Semantics sites in `lib/` | ~11 (`Semantics(`/`semanticsLabel`), 0 `liveRegion` |

### 1.1 Toolchain

- Current Flutter stable: **3.47.5** (Dart **3.13.4**), released 2026-09-18.
- Package constraints: `sdk: ">=3.6.0 <4.0.0"`, `flutter: ">=3.35.0"`. The floor is honest and
  verified by the `sdk-matrix` CI floor leg (task-012). It is 12 minor versions behind stable. That
  is fine for reach, but it blocks `speech_to_text` 7.5 and `google_fonts` 8.2.x at the floor.

### 1.2 Dependencies: current constraint vs latest stable (pub.dev, 2026-09-24)

| Package | Kind | Constraint | Locked | Latest stable (date) | Latest's SDK floor | Action |
|---|---|---|---|---|---|---|
| clock | direct | ^1.1.2 | 1.1.2 | **1.1.3** (2026-08-28) | Dart ^3.4 | bump lower bound |
| flutter_markdown_plus | direct | ^1.0.3 | 1.0.12 | 1.0.12 (2026-07-10) | Flutter >=3.27.1 | raise lower bound to ^1.0.12 |
| google_fonts | direct | ^8.1.0 | 8.2.1 | 8.2.1 (2026-07-31) | **Flutter >=3.38** | keep ^8.1.0 (floor 3.35 still resolves 8.1.x) |
| flutter_streaming_text_markdown | direct | ^1.10.1 | 1.10.1 | 1.10.1 (2026-09-03) | Flutter >=3.10 | current |
| url_launcher | direct | ^6.3.1 | 6.3.2 | 6.3.2 (2025-07-10) | Flutter >=3.27 | raise lower bound |
| flutter_math_fork | direct | ^0.7.2 | 0.7.4 | 0.7.4 (2025-05-21) | Flutter >=3.0 | raise lower bound |
| flutter_lints | dev | ^6.0.0 | 6.0.0 | 6.0.0 (2025-05-27) | Dart ^3.8 | current |
| speech_to_text | dev | ^7.2.0 | 7.4.0 | **7.5.0** (2026-09-14) | **Flutter >=3.44** | `pub upgrade` locally. Dev-only, so the higher floor does not affect consumers |
| network_image_mock | dev | ^2.1.1 | 2.1.1 | 2.1.1 (**2022-06-28**) | Dart >=2.12 <3.0 | unmaintained; replace with `mocktail_image_network` or an in-repo `HttpOverrides` helper |
| provider | dev | ^6.1.2 | 6.1.5+1 | 6.1.5+1 (2025-08-19) | — | current |
| fake_async | dev | ^1.3.3 | 1.3.3 | 1.3.3 (2025-01-28) | — | current |
| example: flutter_lints | dev | **^3.0.1** | — | 6.0.0 | Dart ^3.8 | bump (example is not floor-constrained) |

`flutter pub outdated` also lists 19 locked transitives with newer resolvable versions: analyzer
10→14, `gpt_markdown` 1.2.1→1.3.0, `package_config` 2→3, `record_use` 0.6→1.1, and others. None are
direct, and `flutter pub upgrade` fixes them without touching the constraints.

### 1.3 Open issues / PRs

| # | Title | State | Notes |
|---|---|---|---|
| **#43** | Windows users cannot pull: invalid filenames in backlog task files | open since 2026-09-12, **no reply** | `task-023`/`task-024` filenames contain `"` and `:`. Blocks every Windows clone → **task-025** |
| **#42** | ScrollBehaviorConfig with long texts | open, **reporter's 2026-09-03 re-test unanswered** | Pin flickers (overshoots, then snaps back); after the stream ends the view jumps to the question. Reproduces on 2.19.1 → **task-026** |
| #41 | Roadmap tracker | open (owner) | Update with this plan's P0/P1 list |
| PRs | — | 0 open | Pattern: 4 of 7 external PRs merged. 3 were closed without merging, including avatar-widget (#26) and custom AI icon (#34). Both are customization asks that `customBubbleBuilder` / `aiUser.avatar` now cover, but the closures probably cost goodwill. |

**Recently closed issues (Feb–Jul 2026) show a pattern:** most reports are
*"parameter X does nothing"* (#30, #29, #28, #25, #40, #9, #38). The knob-sweep work (task-002)
fixed the ones known at the time. **This pass found another dead knob:**
`MarkdownContent.enableSyntaxHighlighting` / `codeTheme`. `_buildCodeBlock` ignores both, while
the README claims code highlighting is built in.

### 1.4 Test coverage

- **Suite size:** 70 test files and about 456 `test`/`testWidgets` cases. The last clean run
  recorded was 458/458 plus 8/8 in the example, on 2026-09-04.
- **No lcov number this pass.** `flutter test --coverage` hung at "loading" twice (about 20 minutes
  each) while 3 other `flutter test` jobs ran on the machine, in this repo and in
  flutter_streaming_text_markdown. Both runs were stopped. CI never collects coverage, so
  **no coverage number exists anywhere**. Fixed by task-034.
- **Static proxy:** 27 `lib/src` files (~6.9k of 25.1k lines) contain classes that no test
  references by name. The largest exported ones are `citation_chip.dart` (593 lines),
  `adaptive_ui_components.dart` (554), `action_result_widget.dart` (520),
  `rich_message_content.dart` (460), `ai_action_provider.dart` (446, the human-in-the-loop
  surface the README markets), `ai_context_provider.dart` (413), `ai_service.dart` (339),
  `headless_chat_controller.dart` (214), and `models/chat/citation.dart` (258). The tested core
  is strong: the controller, custom_chat_widget, streaming, scroll/pin, persistence, attachments,
  goldens, and perf.
- `glassmorphic_container.dart` exists twice (`utils/` and `widgets/`), and both copies are exported.

---

## 2. Competitor matrix (pub.dev API + READMEs/source, 2026-09-24)

### Adoption

| Package | Latest (date) | Likes | 30-day downloads | Points | Positioning |
|---|---|---|---|---|---|
| **flutter_gen_ai_chat_ui** | 2.19.1 (09-03) | 101 | 3,477 | **160** | AI-first chat UI |
| flutter_chat_ui (Flyer v2) | 2.12.0 (09-12) | **1,625** | **104,525** | 140 | General chat, category leader; AI streaming via `flyer_chat_text_stream_message` (2.8k downloads) |
| genui (Google) | 0.10.3 (09-12) | 195 | **34,773** | 130 | Generative UI / A2UI renderer (launched Nov 2025, shown at I/O 2026) |
| ag_ui | 0.3.0 (06-24) | 6 | 18,436 | 140 | AG-UI agent event protocol |
| flutter_ai_toolkit (Google) | 1.0.0 (2025-12-15) | 246 | 5,618 | 140 | firebase_ai chat; **no release in 9 months** |
| dash_chat_2 | 0.0.21 (**2024-06**) | 312 | 2,861 | 110 | Abandoned |
| chatview (Simform) | 3.1.0 (06-15) | 652 | 1,968 | 140 | Messenger-style, not AI |
| syncfusion_flutter_chat | 34.2.9 (09-22) | 58 | 1,384 | 150 | Chat + AI AssistView, commercial license |
| **flutter_ai_elements** | 0.3.0 (08-24) | 2 | 126 | 160 | **Closest conceptual rival**: port of Vercel AI Elements (parts model, reasoning, tools, code blocks, a11y, OpenAI/Anthropic/Gemini/MCP adapters) |

Also on pub.dev, each with fewer than 10 likes and fewer than 200 downloads/30d: ai_kit,
ai_assistant_ui, flutter_ai_chat_ui, flutter_ai_sdk_ui, ai_chat_kit, agent_ui_kit_providers, and
flutter_agentic_ui. The segment is crowded, but none of these is a threat yet. We rank at or near
the top of pub.dev search for "ai chat", "llm chat" and "chat ui streaming".

### Features (Y = built in, P = partial/DIY, N = none)

| Feature | **ours** | flutter_chat_ui v2 | flutter_ai_toolkit | genui | flutter_ai_elements | chatview |
|---|---|---|---|---|---|---|
| Token streaming | **Y** (word-by-word, markdown) | Y (separate package) | Y | Y | Y | N |
| Markdown | Y | Y | Y | Y | Y | N |
| **Code syntax highlighting** | **N** (dead knob, README claims Y) | N | N | N | **Y** | N |
| LaTeX | **Y (unique)** | N | N | N | N | N |
| **Reasoning / thinking block** | **N** | N | N | N | **Y** | N |
| **Tool-call parts (lifecycle UI)** | P (`AiActionProvider`, not inline message parts) | P | P | **Y** (core) | **Y** | N |
| Human-in-the-loop approval | Y | N | N | P | Y | N |
| Citations / sources | Y | N | N | N | Y | N |
| Rich inline widgets | Y (`ChatMessage.rich`, result renderers) | P | P | **Y** (A2UI catalog) | Y (`DataPart`) | N |
| Attachments | Y (lightbox, progress; host supplies the picker) | Y | **Y** (camera/gallery/file) | P | Y | Y |
| Voice input | P (button + status bar; STT supplied by the host) | N | **Y** (recorder) | N | Y | P |
| **Message actions (regenerate/edit/feedback/retry)** | P (copy only) | P | P (edit) | N | **Y** (+branching) | Y (edit/reply) |
| **Accessibility / streaming-safe semantics** | P | N | N | N | **Y** | N |
| RTL | **Y** | Y | N | N | P | P |
| Theming depth | **Deep** (+ brand presets) | Deep | Medium | Catalog | Medium | Deep |
| Pagination / persistence | Y / Y (hook) | **Y (two-sided)** / Y | N / Y | N | N | Y / N |
| Provider adapters | Cookbook snippets (4) | Gemini example | **firebase_ai** | Genkit/A2A | **OpenAI/Anthropic/Gemini/MCP** | Firebase |
| Headless controller | Y | Y | N | — | N | N |
| Pub points | **160** | 140 | 140 | 130 | 160 | 140 |

### Gaps that matter, ranked by user-visible impact

1. **Reasoning block.** Thinking models are the default in 2026, and we have nowhere to put that
   stream (→ task-029).
2. **Parts-based messages + tool-call lifecycle.** The Vercel `UIMessage.parts` model is now the
   shared vocabulary, and Anthropic content blocks and OpenAI Responses items map onto it
   (→ task-030).
3. **Code highlighting.** Our README says we have it, and we don't (→ task-028, task-027).
4. **Regenerate / edit / feedback / retry** (→ task-031).
5. **Streaming a11y** (→ task-032).
6. **Adapters / one-line binding.** Time-to-first-token for integrators (→ task-033).
7. **A2UI/genui interop.** Render genui `Surface`s inside our bubbles to ride Google's
   generative-UI push rather than compete with it (P2, §3).

---

## 3. Prioritized plan

Effort: **S** ≤ 1 day, **M** 2–4 days, **L** 1–2 weeks (agent-assisted).

### P0: this week (trust and correctness)

| # | Item | Why | Effort | Acceptance (summary) | Task |
|---|---|---|---|---|---|
| P0-1 | Rename the Windows-invalid backlog files + CI path guard | #43: every Windows user is blocked from cloning or pulling. Cheapest fix with the widest impact | S | Files `git mv`'d to slugs. A CI step fails on `<>:"\|?*`, trailing dots or spaces, and reserved names. #43 answered and closed | **task-025** |
| P0-2 | #42 round 2: pin flicker + post-stream jump | Our only active external reporter has waited 3 weeks, and the feature is documented as working | M | Tests fail on current main, then pass. The anchor offset stays monotonic while pinned. No offset change after stop. Patch release, and reply on #42 | **task-026** |
| P0-3 | README credibility pass | Unsourced testimonials with named people, a generic "featured apps" list, a false code-highlighting claim, and a stale comparison table. Any of these can cost a like or an adoption when someone checks | S | Unverifiable content removed. Comparison table re-verified and dated. Length ≤ 600 lines. Doc-drift CI green | **task-027** |
| P0-4 | Answer #41 with this plan | Keeps the public roadmap honest | S | Comment summarising P0/P1 with task links | (no task) |

### P1: next 4–6 weeks (feature parity with the 2026 AI-chat baseline)

| # | Item | Why | Effort | Acceptance (summary) | Task |
|---|---|---|---|---|---|
| P1-1 | Code-block syntax highlighting + copy/language header | Dead knob and a false claim. Code is the most common content in AI answers | M | Highlighting for ~10 languages. Copy button per block. Streaming-safe partial fences. Wasm clean. Under 16ms per rebuild | **task-028** |
| P1-2 | Reasoning / thinking block | Table stakes for thinking models. Answers #37. Supersedes task-007 | M | Model + controller API + collapsible `ReasoningBlock` ("Thought for Ns"), goldens, cookbook | **task-029** |
| P1-3 | Parts-based `ChatMessage.parts` + tool-call lifecycle UI | Converges with the Vercel/Anthropic/OpenAI shape and enables inline agent UIs. Supersedes task-010 | L | Design doc signed off. Additive sealed `MessagePart`. Tool cards per state with approval. Goldens unchanged when `parts` is null | **task-030** |
| P1-4 | Message actions: regenerate, edit-and-resend, feedback, retry | Every major assistant UI has them. Today users hand-roll them | M | Callback-gated buttons (off by default). Inline edit. Retry on error. Tests + demo | **task-031** |
| P1-5 | Streaming a11y + reduced motion | Flutter Favorite criterion and a rival's selling point. Current support is thin | M | Per-message semantics. One announcement per completed stream. Honors `disableAnimations`. Guideline tests | **task-032** |
| P1-6 | `controller.streamResponse(Stream)` + firebase_ai / AG-UI recipes | Cuts integration to one call. Feeds P1-2/P1-3 through typed stream events | M | Helper with error/cancel/dispose tests. Recipes rewritten. Sibling-package decision recorded | **task-033** |
| P1-7 | Dependency + test hygiene, coverage gate | Keeps 160/160 and the freshness promise. Makes coverage visible | S | Lower bounds raised. `network_image_mock` replaced. Example lints ^6. Coverage published in CI with a no-regression floor | **task-034** |

### P2: later / opportunistic

| # | Item | Why | Effort | Acceptance |
|---|---|---|---|---|
| P2-1 | genui / A2UI interop spike | genui has 34.7k downloads/30d and Google backing. Hosting A2UI surfaces inside our messages puts us in that ecosystem rather than against it | M | Example screen rendering a genui `Surface` inside `ChatMessage.rich`/a `DataPart`. Decide whether to ship a separate `..._genui` package |
| P2-2 | Split `custom_chat_widget.dart` (2.1k lines) and `chat_messages_controller.dart` (1.8k lines) | Maintainability. Most scroll bugs (#13, #42) live here | L | Pure refactor behind the existing tests and goldens. No public API change |
| P2-3 | API surface audit ahead of 3.0 | 55 exported files, including example agents, glassmorphic utils, and several overlapping theme systems. The deprecation backlog is growing | M | `doc/MIGRATION.md` 3.0 section listing removals. A `@Deprecated` pass. Keep 2.x additive |
| P2-4 | Demo GIFs / short video in README + pub screenshots of the reasoning/tool UIs once shipped | Screenshots drive installs. task-005 left GIFs undone | S | 3 GIFs (streaming, reasoning, tools) under 2 MB each. Pub `screenshots:` updated |
| P2-5 | Model selector + context/token meter components | Ship in AI Elements and `flutter_ai_elements`; useful for power-user apps | M | Two optional widgets, documented and themeable |
| P2-6 | Two-sided pagination / jump-to-message | Flyer v2.9 has it. Search-in-thread use cases | M | `loadNewer` + `scrollToMessage(id)` keep position stable when prepending/appending |
| P2-7 | Discoverability | Topics are capped at 5 and all current ones are good. The description is the main lever | S | Description mentions "reasoning, tool calls" once those ship. Link from the Flutter AI docs / awesome-flutter PRs. Submit to the Flutter Favorite nomination once P1 lands |
| P2-8 | Raise the Flutter floor to ≥3.38 at the next minor | Unlocks `google_fonts` 8.2 at the floor and newer APIs (`scrollCacheExtent`) | S | sdk-matrix floor leg green. CHANGELOG note |

### Pub score

Already 160/160. The risks to watch are the dependency-freshness points (any direct dep whose
latest requires a Flutter above our floor, as `shimmer` did) and new analyzer lints after Flutter
upgrades. Re-run `pana` after each release, as the AWARD-PLAN already requires.

---

## 4. New backlog tasks

| Task | Priority | Title |
|---|---|---|
| task-025 | P0 | Fix #43: Windows-invalid backlog filenames + CI guard |
| task-026 | P0 | #42 round 2: pin flicker and post-stream jump |
| task-027 | P0 | README credibility and accuracy pass |
| task-028 | P1 | Code-block syntax highlighting + copy (wire the dead knob) |
| task-029 | P1 | Reasoning / thinking block (supersedes task-007) |
| task-030 | P1 | Parts-based message model + tool-call lifecycle UI (supersedes task-010) |
| task-031 | P1 | Message actions: regenerate, edit, feedback, retry |
| task-032 | P1 | Streaming accessibility + reduced motion |
| task-033 | P1 | `streamResponse` binding helper + firebase_ai / AG-UI recipes |
| task-034 | P1 | Dependency + test hygiene, coverage gate |

Existing open tasks are not duplicated. task-007 and task-010 are folded into task-029 and
task-030; close them as superseded when those start. task-005 (demo GIFs) continues as P2-4.

## Sources

- pub.dev API: `/api/packages/<name>` and `/api/packages/<name>/score` for every package above,
  fetched 2026-09-24.
- Flutter releases JSON (`storage.googleapis.com/flutter_infra_release/releases/releases_macos.json`).
- GitHub: flyerhq/flutter_chat_ui, flutter/ai, flutter/genui, ananmouaz/flutter_ai
  (flutter_ai_elements), SimformSolutionsPvtLtd/chatview, SebastienBtr/Dash-Chat-2,
  syncfusion/flutter-widgets.
- Vercel AI Elements (github.com/vercel/ai-elements); Google Developers Blog on A2UI and MCP Apps;
  Flutter blog "New updates to A2UI and Flutter's GenUI package".
