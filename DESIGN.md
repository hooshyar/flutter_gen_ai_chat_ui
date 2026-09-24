# DESIGN.md: flutter_gen_ai_chat_ui

The committed design direction for the package's zero-config defaults and for the example app.
Read this before touching any visual default. If a change contradicts this file, change this file first, in the same PR.

---

## 1. Thesis

**The conversation is the interface: AI answers read like a well-set document, the user speaks in a quiet bubble, and one ink-black control does the talking.**

Design read: developer-facing UI kit whose output ships inside other people's AI products. The audience is the Flutter developer choosing a package in 5 seconds on pub.dev, and then their end users reading long, code-heavy answers. Language: calm, neutral, typographic, Linear-and-Claude restraint. Dials: `DESIGN_VARIANCE 4 / MOTION_INTENSITY 4 / VISUAL_DENSITY 4` for the package; `6 / 5 / 3` for the example home screen.

Three rules everything else follows:

1. **Prose over chrome.** AI messages have no card, no border, no shadow, no robot icon, no "Just now". The text is the product.
2. **Neutral by default, brand by opt-in.** Surfaces and text come from a fixed neutral ramp that looks right in any host app. The host's `ColorScheme.primary` is used only for links, focus rings and selection. Brand presets (`CustomThemeExtension.chatgpt()/claude()/gemini()`) and `BubbleStyle` keep full override power.
3. **Motion only shows where tokens arrive.** Streaming reveal, a live caret, a thinking shimmer, the send-to-stop morph. Nothing else moves on its own, and everything collapses to static under reduced motion.

---

## 2. References and what we borrow

| Reference | Borrow exactly this | Do not borrow |
|---|---|---|
| **claude.ai** | Bubble-less assistant prose on the canvas; user turn as a lightly raised, borderless rounded block; composer as one rounded box (radius 24) with a toolbar row *inside* it; in-place icon swap on copy (copy -> check) instead of a toast. | The cream/parchment palette and Styrene/Tiempos (proprietary; also the "warm paper" AI tell). |
| **ChatGPT** | Reading column of about 48rem (we use 760 logical px) with a composer allowed to be slightly wider (800); user bubble `#f4f4f4`-class grey, radius about 20, no border; circular ink send button that becomes a stop control in the same place; centred, low-decoration empty state with one plain greeting. | Raw text append with no reveal (we fade). Its green/black brand. |
| **Vercel AI Elements / v0** | The component vocabulary (Conversation, Message, PromptInput, Reasoning, CodeBlock, Actions, Suggestion, Shimmer, Loader); sans/mono split where mono is reserved for code, language labels and IDs; token-first theming with a 4px spacing scale; "Shimmer" as the canonical pre-first-token state. | shadcn default state (never ship defaults unstyled). |
| **Linear** | Few base tokens, everything else derived; 1px low-contrast hairlines instead of shadows; elevation expressed by surface steps, not blur; restrained 150-220ms motion with a decelerating curve. | Its indigo accent (that is the AI-purple family we are leaving). |
| **Raycast AI** | Single restrained accent over a neutral near-black; positive tracking (+0.1 to +0.2) on small dark-mode text so it does not look cramped; compact, keyboard-first composer (Enter sends, Shift+Enter newline, Esc stops). | Heavy backdrop blur on everything. |
| **Apple Messages** | Two-tier grouping rhythm: 4px between consecutive turns from the same sender, 24px when the sender changes; the tail corner (radius 6) only on the last bubble of a group; bubble radius 20; body at the platform body size. | Saturated blue bubbles (our user bubble is neutral). |
| **Vercel Streamdown** | Per-arrival fade of newly revealed text (~180ms ease-out) and a live caret while streaming, driven by real arrival, not a fixed timer. | Blur/scramble effects (decoration, not information). |

---

## 3. Colour tokens

Neutral ramp is zinc-based (cool-neutral, not cream, not lavender). One accent. `ink` is the primary-action colour and is deliberately *not* the accent: a black send disc reads as "the one thing to press" on any brand.

All ratios below are WCAG 2.x contrast, computed (script: scratchpad `contrast.py`).

### Light

| Token | Hex | Use | Contrast checks |
|---|---|---|---|
| `canvas` | `#FBFBFA` | Example app scaffold. Package leaves chat background transparent. | |
| `surface` | `#FFFFFF` | Floating controls (scroll-to-bottom), menus | |
| `surfaceSunken` | `#F3F3F1` | Composer fill, prompt tiles on hover | |
| `userBubble` | `#EFEFEC` | User message fill | textPrimary 15.38 |
| `border` | `#E4E4E2` | Hairlines, tile borders, code border (decorative) | 1.23 vs canvas (decorative only) |
| `borderStrong` | `#85858D` | Focused composer outline, input boundaries | 3.54 vs canvas, 3.29 vs surfaceSunken (passes 1.4.11) |
| `textPrimary` | `#18181B` | Body, headings | 17.11 canvas, 15.95 sunken |
| `textSecondary` | `#52525B` | Descriptions, blockquote text, placeholders | 7.47 canvas, 6.71 userBubble |
| `textTertiary` | `#6B6B73` | Timestamps, code language label, captions | 5.10 canvas, 4.58 userBubble, 4.54 inlineCodeBg |
| `accent` | `#2450D6` (example app); package uses host `colorScheme.primary` | Links, focus ring, text selection | 6.35 canvas, 5.71 userBubble |
| `onAccent` | `#FFFFFF` | Text on accent fills | 6.58 |
| `ink` | `#18181B` | Send button fill, primary buttons | 17.11 vs canvas |
| `onInk` | `#FBFBFA` | Icon on send button | 17.11 |
| `danger` | `#C4321C` | Errors, destructive | 5.31 canvas, 4.77 userBubble |
| `inlineCodeBg` | `#EEEEEB` | Inline `code` chip | textPrimary 15.24 |
| `codeBg` | `#F6F6F4` | Fenced code block | see syntax table |
| `codeBorder` | `#E4E4E2` | Fenced code block border | |
| `shadow` | `#18181B` at 6% / 8% | Floating elements only | |

### Dark

| Token | Hex | Contrast checks |
|---|---|---|
| `canvas` | `#111113` | |
| `surface` | `#18181B` | |
| `surfaceSunken` | `#1C1C1F` | |
| `userBubble` | `#26262A` | textPrimary 12.89 |
| `border` | `#2A2A2F` | decorative |
| `borderStrong` | `#6A6A72` | 3.52 canvas, 3.17 sunken |
| `textPrimary` | `#EDEDEF` | 16.13 canvas, 12.89 userBubble |
| `textSecondary` | `#A8A8B0` | 7.99 canvas, 6.38 userBubble |
| `textTertiary` | `#8C8C94` | 5.65 canvas, 4.52 userBubble |
| `accent` | `#8AA8FF` (example); package: host `colorScheme.primary` | 8.20 canvas, 6.55 userBubble |
| `onAccent` | `#111113` | 8.20 |
| `ink` | `#EDEDEF` | 16.13 vs canvas |
| `onInk` | `#111113` | 16.13 |
| `danger` | `#FF7A66` | 7.39 canvas |
| `inlineCodeBg` | `#232327` | textPrimary 13.39 |
| `codeBg` | `#161618` | |
| `codeBorder` | `#2A2A2F` | |
| `shadow` | none; use a 1px `border` plus `rgba(255,255,255,0.06)` top highlight | |

### Code block syntax palette (GitHub-derived, two fixes)

Light on `#F6F6F4`: base `#24292F` 13.54 · keyword `#CF222E` 4.95 · string `#0A3069` 11.84 · number `#0550AE` 7.02 · type `#953800` 6.82 · function `#8250DF` 4.66 · **comment `#656D76` 4.85** (was `#6E7781` = 4.27 on `#F6F8FA`, an AA fail) · **annotation `#8A5C00`** (was `#9A6700` = 4.50, too close to the line) · punctuation `#57606A` 5.91.

Dark on `#161618`: base `#E6EDF3` 15.29 · keyword `#FF7B72` 7.17 · string `#A5D6FF` 11.76 · function `#D2A8FF` 9.28 · annotation `#7EE787` 11.76 · comment `#8B949E` 5.88 (unchanged hues otherwise).

### Colour rules

- One accent per surface. No per-feature colours (the home screen's green/amber/violet/pink/cyan/teal tiles go).
- No lavender-tinted surfaces. The package must not read `colorScheme.surface*` for bubble or composer fills (M3 seed tinting is where the purple cast came from).
- Never pure `#000000` / `#FFFFFF` for canvas. `#FFFFFF` is allowed for `surface` (raised) in light only.
- `CustomThemeExtension` values, when present, override the matching token. `BubbleStyle` / `MessageOptions` / `InputOptions` values override both. Order: explicit option > `CustomThemeExtension` > `ChatTokens` default.

---

## 4. Typography

**Package default: inherit the host's font** (`Theme.of(context).textTheme`), and set only size, height, weight and tracking. A UI kit that forces a font on its host is a bad citizen, and `google_fonts` fetches at runtime. Code always uses the bundled **JetBrains Mono** (`CodeBlockTheme.monoFontFamily`, package `flutter_gen_ai_chat_ui`).

**Example app font: Geist** (`GoogleFonts.geistTextTheme`, available in google_fonts 8.2.1) for UI, **JetBrains Mono** (bundled) for code, **Vazirmatn** (`GoogleFonts.vazirmatn`) for the RTL demo (Arabic and Sorani Kurdish, far better UI rhythm than Noto Sans Arabic).

### Scale (logical px)

| Role | Size / line height | Weight | Tracking | Where |
|---|---|---|---|---|
| `display` | 28 / 34 (32 / 38 at width >= 840) | 600 | -0.4 | Empty-state greeting |
| `h1` (markdown `#`) | 20 / 28 | 600 | -0.2 | |
| `h2` (`##`) | 17.5 / 26 | 600 | -0.1 | |
| `h3`-`h6` | 16 / 24 | 600 | 0 | |
| `body` | 16 / 25 (height 1.56) | 400 | 0 (dark: +0.1) | AI prose, user bubble |
| `bodyStrong` | 16 / 25 | 600 | 0 | markdown `**strong**` |
| `label` | 14 / 20 | 500 | 0 | Prompt tiles, buttons, chips |
| `caption` | 12 / 16 | 400 | +0.1 | Timestamps, action labels, helper text |
| `mono` | 13.5 / 20 (height 1.48) | 400 | 0 | Fenced code |
| `monoInline` | 0.9 em of surrounding text | 400 | 0 | Inline `code` |
| `monoLabel` | 12 / 16 | 400 | +0.2 | Code language label |

Markdown rhythm: paragraph gap 12; heading margin top 20 (first child 0), bottom 8; list item gap 4, list indent 20, bullet `textSecondary`; blockquote: 3px left rule in `border` (dark: `borderStrong`), 12 left padding, text in `textSecondary`, no fill; tables: header row weight 600 on `surfaceSunken`, cells padded 8x12, 1px `border` hairlines horizontal only, horizontally scrollable when wider than the column; `hr`: 1px `border`, 24 vertical margin; links: `accent`, underline on hover only (web/desktop), always underlined when `MediaQuery.highContrast`.

Hierarchy is carried by weight and colour, not raw size: the largest thing in a chat is a 20px heading.

---

## 5. Spacing and radius

**Spacing scale (4px base):** `2, 4, 8, 12, 16, 20, 24, 32, 48, 64`.

| Rhythm | Value |
|---|---|
| Same-sender consecutive turns | 4 |
| Sender change | 24 |
| AI message to its action row | 8 |
| Message list horizontal padding | 16 (phone), 24 (>= 600) |
| Message list bottom padding above composer | 16 |
| User bubble inner padding | 10 vertical, 16 horizontal |
| Composer inner padding | 12 top, 8 bottom, 16 start, 8 end |
| Reading column max width | 760 |
| Composer max width | 800 |
| User bubble max width | 80% of the column, cap 560 |

**Radius scale:** `4` (inline code), `8` (tooltips, small buttons), `12` (code blocks, prompt tiles, rich result cards, attachments), `20` (user bubble), `24` (composer), `full` (send/stop button, scroll-to-bottom, suggestion pills). Tail corner on the last bubble of a user group: `6` on the trailing-bottom corner (bottom-right LTR, bottom-left RTL).

Shape rule: containers are 12, the two "voice" surfaces (user bubble 20, composer 24) are softer, anything you press that is round is full. Nothing else.

---

## 6. Elevation and borders

- **Level 0 (flat):** all messages, code blocks, prompt tiles. Separation by space and a 1px `border` where needed. No `BoxShadow` on any message, ever. `BubbleStyle.defaultStyle.enableShadow` becomes `false`.
- **Level 1 (resting on content):** composer. Light: `surfaceSunken` fill + 1px `border`; focused: 1px `borderStrong` plus a 3px outer ring of `accent` at 18% alpha. Dark: same with dark tokens. No shadow.
- **Level 2 (floating over scrolling content):** scroll-to-bottom button, menus. Light: `surface` fill, 1px `border`, shadow `0 1 2 rgba(24,24,27,0.06)` + `0 4 12 rgba(24,24,27,0.08)`. Dark: `surface` fill, 1px `border`, inner top highlight `rgba(255,255,255,0.06)`, no shadow.
- Borders are always 1px (logical). Never 0.5.
- No glassmorphism in defaults. `InputOptions.glassmorphic()` stays as an opt-in preset.

---

## 7. Motion

Durations are tokens; do not write raw `Duration(milliseconds: ...)` in widgets. Curves: enter `Cubic(0.2, 0, 0, 1)` (emphasized decelerate), exit `Cubic(0.4, 0, 1, 1)`, move `Cubic(0.2, 0, 0, 1)`. Exits run at about 70% of the matching enter.

| Token | Duration | Used by |
|---|---|---|
| `press` | 100ms | Button scale 1.0 -> 0.96 on press |
| `fast` | 150ms | Hover fills, icon swaps (copy -> check), action row opacity |
| `base` | 220ms | Message appear, scroll button show/hide, send <-> stop morph (160ms) |
| `slow` | 320ms | Empty state exit, scroll-to-bottom `animateTo` |
| `streamFade` | 180ms | Opacity 0 -> 1 on newly revealed streamed text |
| `caretPulse` | 900ms | Live caret opacity 0.35 <-> 1.0, repeating, while streaming |
| `thinkingSweep` | 1600ms | Shimmer highlight across the "Thinking" label, linear, repeating |

Choreography:

- **New user message:** fade 0 -> 1 and translate Y 8 -> 0 over `base`, enter curve. Origin: the composer (it rises out of it).
- **AI turn:** no entrance animation for the container. The first thing visible is the thinking row; the first token replaces it with a `fast` cross-fade.
- **Streaming:** the existing reveal ticker (50ms, catch-up factor 0.16) stays. Add the live caret after the revealed text while `isRevealing`, and fade in the newest revealed run over `streamFade` when `streamingFadeInEnabled` (default becomes `true`).
- **Stream end:** caret fades out over `fast`; the action row fades in over `fast` after a 120ms delay.
- **Send -> stop:** same 36px disc; icon cross-fades `arrow_upward_rounded` -> 12px rounded square over 160ms; no size change.
- **Reduced motion** (`MediaQuery.disableAnimationsOf(context)` is true): every token resolves to `Duration.zero`; caret is a static dot; the thinking label is static text plus three static dots; streaming reveal still happens (it is information) but without fade; `animateTo` becomes `jumpTo`.

---

## 8. Component specs (package defaults)

Unless stated, "default" means: no `BubbleStyle`, no `CustomThemeExtension`, no explicit option passed.

### 8.1 Message layout

Two layouts, chosen per AI message by a new additive option `MessageOptions.aiMessageLayout` (`AiMessageLayout.document | AiMessageLayout.bubble`, nullable):

- `null` resolves to **`bubble`** if the consumer set any of `bubbleStyle.aiBubbleColor`, `messageOptions.decoration`/`effectiveDecoration`, or a `CustomThemeExtension.messageBubbleColor`; otherwise **`document`**. Existing customised apps keep their bubbles.

**Document (new default) AI message**
- No container decoration. Content starts at the reading column's start edge, spans the full column width (max 760).
- No name row, no avatar (the `showUserName` default becomes `null`, resolving to `false` in document layout and `true` in bubble layout; an explicit `true` still shows a name row: caption, `textSecondary`, plus avatar if a builder is given).
- Text: `body`, `textPrimary`. Markdown per section 4.
- Action row below (see 8.8). Timestamp lives in the action row, not under the text.

**User message**
- Right-aligned in LTR (`AlignmentDirectional.centerEnd`, so it mirrors in RTL).
- Fill `userBubble`, radius 20 all corners, trailing-bottom corner 6 on the last bubble of a consecutive group. No border, no shadow, no name, no timestamp inside the bubble (time is available via tooltip/long-press semantics label).
- Padding 10x16, text `body` `textPrimary`. Max width 80% of the column, cap 560. Width comes from `LayoutBuilder` constraints, never `MediaQuery.size` (current code measures the screen, so bubbles overshoot a constrained column; also delete the 115px text-measurement fudge).

**Bubble layout (opt-in / legacy-compatible)**
- Same as today's structure, restyled: AI fill `surface` (light) / `surfaceSunken` (dark), 1px `border`, no shadow, radius 20 with 6 on the leading-top corner. Name row: caption, `textSecondary`, never `Colors.blue[700]`.

**Grouping:** 4px between consecutive same-sender turns, 24px on sender change (compute from the previous item in the list builder; respects reverse order).

### 8.2 Markdown typography
As section 4. The stylesheet is built once per theme brightness, from `ChatTokens` + host `textTheme`. `MessageOptions.markdownStyleSheet` still wins wholesale.
Inline code: `monoInline`, fill `inlineCodeBg`, radius 4 (via `code` style `backgroundColor`; Flutter cannot round inline spans, accept square), color `textPrimary`.

### 8.3 Code blocks
- Container: `codeBg`, 1px `codeBorder`, radius 12, vertical margin 12 (8 when first/last child).
- Header: 44px tall (so the copy control gets a full 44x44 hit area without overlapping code), 12 start padding, 0 end. Language label `monoLabel` `textTertiary`, lowercase. Copy: icon button, 16px icon, 44x44, `textTertiary` -> `textPrimary` on hover; icon swaps copy -> check for 1500ms with a `fast` cross-fade; tooltip "Copy code" / "Copied".
- 1px `codeBorder` divider between header and code.
- Code: `mono`, padding 14 vertical 16 horizontal, horizontal scroll, no wrap, no line numbers. Right-edge 24px fade mask when content overflows horizontally.
- In the markdown path, the stylesheet `codeblockDecoration` must come from the resolved `CodeBlockTheme` (bg, border, radius 12) and `codeblockPadding` must be `EdgeInsets.zero` (today the code gets 14 from the stylesheet plus 12 from `CodeBlockView`, and the stylesheet colours ignore `CodeBlockTheme` entirely).
- Always LTR, even in RTL chats (already true).

### 8.4 Composer (input)
- One object: a rounded rectangle, radius 24, fill `surfaceSunken`, 1px `border`; focused: `borderStrong` + 3px `accent` ring at 18%. The text field has no own border or fill (`InputBorder.none`).
- Layout: text field on top (min 1 line, max 8 lines, `body` style, hint `textSecondary` "Message..."), bottom row inside the box: leading slot (attach, toolbar builder, mic) and the send button at the trailing end. When there is no leading content, the send button sits inline at the trailing end of the single-line field (vertically centred on the first line).
- Max width 800, centred; 16 side margin on phones; bottom padding 12 + safe area.
- Keyboard: Enter sends, Shift+Enter newline (desktop/web), Esc triggers `onCancelGenerating` while generating.
- Placeholder default copy: "Message..." (no ellipsis character, three dots).

### 8.5 Send / stop button
- 36x36 visual disc inside a 44x44 hit area, full radius.
- Enabled: fill `ink`, icon `Icons.arrow_upward_rounded` 20px `onInk`.
- Empty input: fill `ink` at 12% alpha (light) / 16% (dark), icon `textTertiary`, not tappable, semantics "Send message, disabled".
- Generating: same disc, fill `ink`, icon a 12x12 square radius 3 in `onInk`, tooltip "Stop generating". Morph per section 7.
- Press: scale 0.96 over `press`.
- Back-compat: `InputOptions.sendButtonIcon` default changes from `Icons.send` to `Icons.arrow_upward_rounded`; any explicitly passed `sendButtonIcon`, `sendButtonColor`, `sendButtonBuilder`, `sendOrMicBuilder`, `cancelButtonBuilder` is honoured exactly as today.

### 8.6 Welcome / empty state
- No card, no container shadow, no emoji, no "Try asking:" label.
- Vertically placed at 38% of the available height (optical centre), inside the reading column, start-aligned text.
- Greeting: `display`, `textPrimary`, max 2 lines. Optional subtitle: `body`, `textSecondary`, max 2 lines.
- Prompt tiles below (24 gap): up to 4. Width >= 600: 2-column grid, 8 gap. Narrower: single column. Tile: 1px `border`, radius 12, padding 14x16, `label` `textPrimary`, optional second line `caption` `textSecondary`. No leading chat icon, no trailing chevron. Hover/pressed: fill `surfaceSunken` over `fast`. Tap sends the prompt.
- Exit: fades out over `slow` when the first message is sent.
- `WelcomeMessageConfig.containerDecoration`, `builder`, `titleStyle`, per-question `config` all still override.
- `persistentExampleQuestions` default stays as is, but when on it renders as a single horizontally scrolling row of pills (height 36, radius full, 1px `border`), never a fixed-height panel that clips its third item.

### 8.7 Thinking / loading state
- Pre-first-token (loading with no text yet): a row at the AI message position: the word "Thinking" in `label` `textSecondary`, with a `ShaderMask` highlight band (`textPrimary`) sweeping start-to-end over `thinkingSweep`. No grey pill, no dots.
- Typing indicator for multi-user typing keeps the three dots, but dots are `textTertiary`, 6px, on no background.
- `ChatMessage.loading()` placeholder: three skeleton bars 10px tall, radius 5, widths 100% / 72% / 46%, 8 gap, fill `surfaceSunken` with a `thinkingSweep` shimmer. Optional caption above in `caption` `textTertiary`.
- Pagination loading: 16px `CircularProgressIndicator(strokeWidth: 2)` in `textTertiary`, no text.
- Fix: nothing in this area may use `Colors.grey[...]`; all from tokens.

### 8.8 Message actions
- Row under each completed AI message, 8 above, height 32, start-aligned: copy, (optional) regenerate, (optional) thumbs up/down via existing builders, then timestamp in `caption` `textTertiary` at the end of the row.
- Icon buttons 16px icon, 32x32 visual, 44x44 hit, `textTertiary`, hover `textPrimary` + `surfaceSunken` fill radius 8.
- Visibility: on hover-capable platforms the row is at opacity 0 and fades to 1 on message hover or keyboard focus (`fast`); always visible on the latest AI message and on touch platforms.
- Copy: icon swaps to check for 1500ms, no SnackBar. `onCopy` callback still fires. `showCopyButton` default becomes `true`.
- Hidden while the message is streaming.

### 8.9 Streaming reveal
- Keep the reveal ticker and fence withholding.
- Live caret: an 8x8 circle in `textPrimary` rendered after the revealed content (as a trailing widget below the last block, start-aligned, 4 top), pulsing per `caretPulse`. Removed on stream end.
- `streamingFadeInEnabled` default `true`, duration `streamFade`, curve enter.
- Reduced motion: no fade, static caret.

### 8.10 Scroll-to-bottom
- 36px disc, level-2 elevation, icon `Icons.arrow_downward_rounded` 18px `textPrimary`, 44x44 hit area.
- Position: horizontally centred on the reading column, 12 above the composer's top edge (not bottom-right over code).
- Show when more than 200px from the bottom; scale 0.9 -> 1 + fade over `base`.
- Tap: `animateTo` over `slow` with the move curve (jump under reduced motion). While streaming with a pin released, show a small `accent` 6px dot on the disc to signal new content below.

### 8.11 Dark mode
- Same structure, dark token column. Never invert per section. Code blocks switch with brightness unless a `codeBlockTheme` is given.
- Dark body text gets +0.1 tracking.

### 8.12 RTL
- Every alignment and padding is directional (`AlignmentDirectional`, `EdgeInsetsDirectional`). User messages go to the end edge (left in RTL). Tail corner mirrors. Action row mirrors. Code blocks stay LTR.
- Per-message direction detection (existing) stays; a message whose detected direction differs from the ambient direction still aligns to its sender's edge but sets its own text direction.

### 8.13 Accessibility floor
- Hit targets 44x44 minimum for every icon control.
- Every icon-only control has a tooltip and a semantics label.
- Contrast per section 3; no information by colour alone (disabled send also changes icon colour and semantics).
- `MediaQuery.textScaler` respected up to 2.0 without clipping: no fixed heights on text containers.
- Reduced motion per section 7.

---

## 9. Example app shell

Purpose: sell the package in 5 seconds, then let each demo prove one thing with defaults showing.

### Theme
- `ThemeData(useMaterial3: true)` built from the token table: explicit `ColorScheme` (primary `accent`, surface `canvas`, onSurface `textPrimary`, outline `border`, outlineVariant `border`), `scaffoldBackgroundColor: canvas`, `surfaceTintColor` transparent everywhere, `textTheme: GoogleFonts.geistTextTheme(...)`. No `colorSchemeSeed`.
- Theme mode: follows the system on first load, manual toggle persists for the session.

### Home screen
- **Width >= 1024 (split hero):** 12-column grid, max width 1200, 32 gutter.
  - Left, columns 1-5: package name in `monoLabel` `textSecondary`; headline in 40/44 Geist 600, -0.8 tracking, 2 lines max: "Chat UI for Flutter AI apps"; subtext `body` `textSecondary`, <= 20 words: "Streaming markdown, highlighted code, RTL and tool results. One widget, zero config, fully themeable."; install block: `flutter pub add flutter_gen_ai_chat_ui` in `mono` on `codeBg`, radius 12, with copy button; one secondary text link "GitHub".
  - Right, columns 6-12: a **live** `AiChatWidget` with package defaults in a framed panel (radius 16, 1px `border`, height 560), which auto-plays one scripted exchange on first load (user asks for a debounce helper in Dart; AI streams a short answer with a code block). The composer is live; typing sends to the mock service.
  - Below the hero (48 gap): the demo index.
- **Width < 1024:** single column: name, headline (32/36), subtext, install block, live panel at height 440, then the demo index.
- **Demo index:** grouped, not 8 equal cards. Groups: "Core" (Streaming, Basic, Themes), "Agents" (Actions, Rich results), "Input" (Attachments, Voice), "Global" (RTL). Group title in `label` `textSecondary`. Rows: name `label` `textPrimary` + one-line description `caption` `textSecondary`, 12 vertical padding, 1px `border` divider between rows, trailing arrow only on hover. 2 groups per row at >= 840, 1 per row below.
- Remove: version pill, "Recommended" badge, the 8 rainbow icon tiles, the pub.dev footer string (link lives in the top bar).

### Demo scaffold (shared by every demo)
- Top bar 56 high: back to home (leading), demo title `label` 600, trailing: theme toggle, "Source" icon button opening the demo's file on GitHub. `scrolledUnderElevation: 0`, 1px bottom `border` only when content is scrolled under it.
- Width >= 1100: persistent 240px sidebar listing all demos by group (current one with `surfaceSunken` fill, radius 8); the chat sits in the remaining space with the package's 760 column.
- Phone: no sidebar; back returns home.
- Page transition: fade over `base` (keep the existing fast transitions).

### Per-demo job (one feature each, defaults visible)
- **Basic:** zero styling. The only arguments are the required ones plus example questions. This is the proof screen.
- **Streaming:** code blocks, highlighting toggle, pin mode. Styling code removed; it uses defaults.
- **Themes:** a segmented control switching Default / ChatGPT / Claude / Gemini brand presets (existing `CustomThemeExtension` factories) and light/dark. Replaces hand-rolled Ocean/Sunset.
- **Actions:** tool calls render as a `json` code block then a result card (existing slice 5B content).
- **Rich results:** result cards use tokens (radius 12, 1px `border`, no shadow); product image placeholder becomes a neutral `surfaceSunken` tile, not a grey laptop icon.
- **RTL:** Vazirmatn, mirrored layout, Arabic plus one Sorani prompt.
- **Attachments / Voice:** unchanged behaviour, default styling.
- Demo copy: no emoji in titles, no em dashes, plain sentences.

---

## 10. Anti-patterns (do not ship)

1. Cards around AI messages. Borders plus shadows around prose.
2. Robot icons, "Bot"/"Copilot" name labels, and "Just now" under every message by default.
3. Hardcoded `Colors.blue[700]`, `Colors.grey[200]`, `Colors.grey[800]` or any `Colors.*` shade in a default path. Tokens only.
4. Reading `MediaQuery.size` for bubble widths. Use `LayoutBuilder`.
5. Material seed purple/indigo as the default accent; lavender-tinted `surface*` fills for chat surfaces.
6. SnackBars for copy feedback.
7. Chat-bubble icons and chevrons on suggestion rows; emoji in greetings.
8. Fixed-height panels that clip content (the persistent questions strip).
9. A floating button parked over code in the bottom-right.
10. Raw `Duration(milliseconds: ...)` in widgets, and any animation that ignores `MediaQuery.disableAnimationsOf`.
11. `Alignment.centerRight` / `EdgeInsets.only(left: ...)` in message layout (breaks RTL).
12. More than one accent colour on a screen; rainbow category colours on the home screen.
13. Exported theme classes that no widget reads. `AdvancedChatTheme`, `ChatTypography`, `ChatAnimationPresets`, `ChatThemeBuilder`, `BubbleTheme`, `PlatformThemeVariants` are currently not consumed by any rendering widget; do not add to them. Mark them in docs as "not applied by AiChatWidget" until they are wired or deprecated in a future major.
14. Demo screens that re-skin the package with 80 lines of colours, hiding what the defaults look like.
15. Em dashes and AI filler copy in demo strings ("seamless", "elevate").
