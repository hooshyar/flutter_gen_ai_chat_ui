# Developer Onboarding Audit — Iteration 10

A walk-through of the package as a Flutter developer encountering it for
the first time via pub.dev. Each section captures the friction observed,
labels it, and either applies the fix in this iter or queues it for a
follow-up.

Labels:

- `[FIXED]` — corrected in this iteration.
- `[QUEUED]` — small enough to defer, large enough to need its own work
  budget. A one-paragraph follow-up is included for the next iter.
- `[NOT A PROBLEM]` — checked, no issue.

---

## 1. Discovery surface (`pubspec.yaml` + first 40 lines of `README.md`)

**What I see in 30 seconds.**

`pubspec.yaml` description nails the elevator pitch: *"AI chat UI for
Flutter. Streaming text, markdown, LaTeX, rich inline widgets,
function-calling/agent surface, RTL, theming. ChatGPT/Claude/Gemini
ready."* Topics include `ai`, `chat`, `llm`, `streaming`, `agent`,
`markdown`, `rtl`. Platforms list all six. Homepage, repository,
issue tracker, and documentation links are present.

`README.md` opens with seven badges, a one-sentence positioning line,
and a Table of Contents. The first screenshot pair (dark mode + GIF
demo) is above the fold.

- *What does this package do?* — Yes, the description and intro line
  answer this within 5 seconds.
- *When should I use it vs alternatives?* — Partly. The README does have
  a `Why Choose This Package?` section and `Works Great With` block, but
  no comparison table near the top. `AGENTS.md` has a competitor matrix
  that the README does not. **[QUEUED]** — pull the AGENTS.md comparison
  table (or a trimmed version) into the README so first-skim readers see
  the differentiator without scrolling to the agent section.
- *What is the simplest hello-world install?* — Yes, but the Install
  section is at line 120 and the Quick Start is at line 159 — past the
  "Performance & Features" wall of text. **[QUEUED]** — promote
  Install + Quick Start above Features so the first thing after the
  hero image is "here is how to use it". Industry-standard pub.dev
  README layout.

## 2. Install + quickstart compile check

The `^2.11.1` version in the install snippet matches `pubspec.yaml`
exactly. `flutter pub get` then a quickstart copy compiles against the
actual public API:

- `ChatMessagesController()` — `[NOT A PROBLEM]` exported, default
  constructor, `ChangeNotifier` semantics as documented.
- `ChatUser(id: ..., firstName: ...)` — `[NOT A PROBLEM]` the constructor
  accepts `firstName` and folds it into `name`.
- `AiChatWidget` parameters: `currentUser`, `aiUser`, `controller`,
  `onSendMessage`, `loadingConfig: LoadingConfig(...)`, `inputOptions:
  InputOptions(...)`, `welcomeMessageConfig: WelcomeMessageConfig(...)`,
  `exampleQuestions: [ExampleQuestion(...)]` — all verified to exist and
  match the snippet. `[NOT A PROBLEM]`
- `ChatMessage(text:, user:, createdAt:)` — `createdAt` is required;
  the snippet supplies it. `[NOT A PROBLEM]`

The quickstart is missing a `MaterialApp` wrapper and `import
'package:flutter/material.dart';` — but it is correctly framed as a
*screen widget* embedded in a `Scaffold`, which is conventional. A new
user would already have a `MaterialApp` from `flutter create`.
`[NOT A PROBLEM]`

## 3. Streaming example trace

The README does not contain an end-to-end streaming code example —
only a flag reference (`enableMarkdownStreaming`, `streamingWordByWord`,
`streamingDuration`) inside the `Optional Parameters` block. The full
push-then-`updateMessage` pattern lives only in:

- `AGENTS.md` Snippet 2 (the AI-assistant reference file).
- The class-level dartdoc on `ChatMessagesController`.

**[QUEUED]** — promote a complete streaming snippet into the README, in
its own H2 section right after the Quick Start. New users searching for
"how do I stream tokens in" should not need to open AGENTS.md or read
the controller's dartdoc to find the answer. The dartdoc version is
correct (uses a `ChatMessage` argument to `updateMessage`, sets
`isStreaming: true`, calls `stopStreamingMessage`) — copy from there.

`AGENTS.md` Snippet 2 had a load-bearing bug: it called
`_controller.updateMessage(id, text: buffer.toString())`. The actual
signature is `void updateMessage(ChatMessage message)`. **[FIXED]** —
rewrote the snippet to construct a `ChatMessage` with the same
`customProperties['id']` and `isStreaming: true`, ending with
`stopStreamingMessage(id)`. Matches the canonical pattern in the
controller's dartdoc.

Flag semantics — both `enableMarkdownStreaming` AND `streamingWordByWord`
must be on for word-by-word animation; AGENTS.md documents this as
"Gate 1 / Gate 2", README labels it on the relevant lines, and the
gotchas list in AGENTS.md repeats it. `[NOT A PROBLEM]`

## 4. Agent / function-calling example trace

README's AI Actions section (line 490+) shows the full
`AiActionProvider` + `AiAction` + `AiActionHook.of(context)` flow.
Verified against `lib/src/widgets/ai_action_provider.dart` and
`lib/src/models/ai_action.dart`:

- `AiActionProvider(config: AiActionConfig(actions: [...]))` — matches.
- `AiAction(name:, description:, parameters:, handler:, render:,
  confirmationConfig:)` — all real fields. The handler signature is
  `(Map<String, dynamic> params) → Future<ActionResult>`, which matches
  the snippet exactly.
- `ActionParameter.number`, `ActionParameter.string` — both exist.
- `ActionResult.createSuccess(data)`, `ActionResult.createFailure(err)`
  — matches the README usage.
- `AiActionProvider.of(context)` returns `ActionController` with an
  `events: Stream<ActionEvent>` getter and `getActionsForFunctionCalling`
  / `handleFunctionCall` methods — all present and matching the README.
- `AiActionHook.of(context).executeAction(name, params)` — exists.

**Friction found in `AGENTS.md` Snippet 4:**

- `ActionParameter.integer(...)` — does not exist. The actual API has
  `string`, `number`, `boolean`, `object`, `array`, `objectArray`,
  `objectWithAttributes`. **[FIXED]** — changed to `ActionParameter.number(...)`
  with a `(num).toInt()` cast at the handler call site.
- `ActionResult.success(data: ...)` — `success` is a `bool` field on
  the result, not a constructor. The factory is `createSuccess`.
  **[FIXED]** — replaced with `ActionResult.createSuccess({...})`.
- Same bugs lived in the class-level dartdoc of
  `lib/src/widgets/ai_action_provider.dart` (the example for
  `AiActionProvider` itself). `handler: (args, _)` also used a two-arg
  signature that no longer exists. **[FIXED]** — corrected the dartdoc
  to use `ActionParameter.number`, `ActionResult.createSuccess`, and the
  one-arg `(params)` handler signature.

## 5. RTL claim

`pubspec.yaml` lists `rtl` as a topic. The description, the README
Features list, and `AGENTS.md` differentiator table all advertise RTL
support. Yet:

- `README.md` contains zero RTL code examples — only the bullet "RTL
  language support for global applications".
- `example/lib/examples/` contains zero files exercising
  `Directionality(textDirection: TextDirection.rtl, ...)` or any
  Arabic/Hebrew/Persian/Kurdish strings.

This is a top-line differentiator with no surface area for a new user
to verify. **[QUEUED]** — add a `## RTL` section to the README with a
4–6 line snippet wrapping `AiChatWidget` in `Directionality.rtl` and a
sample Arabic message; add a `rtl_chat.dart` example screen that the
home screen lists alongside the existing five examples. The
`flutter_streaming_text_markdown` 1.7.0 RTL/Arabic word-splitting fix
(landed in the iter-9 dep bump) is now reachable — a working example
showing it in action is the natural follow-up.

## 6. Example app

`example/lib/main.dart` registers five routes:
`/basic`, `/streaming`, `/themed`, `/actions`, `/rich`. Each
corresponds to a file in `example/lib/examples/`. The README mentions
`cd example/ && flutter run` and lists Basic Chat, Streaming Text, File
Attachments, Custom Themes, Advanced Features — but the actual example
screens are Basic, Streaming, Themed, Actions, Rich Widgets. The README
list is partially stale: "File Attachments" is not in the menu (the
package supports attachments, but no dedicated example exists), and
"Advanced Features" is a vague name not in the menu. **[QUEUED]** —
sync the README example list to match the actual menu and rename the
README "Live Examples" bullets to the actual screen names.

`flutter analyze example/` baseline before this iter: 9 issues
(3× `withOpacity` deprecation, 5× `prefer_const_constructors`,
1× `prefer_const_literals_to_create_immutables`), all in
`example/lib/examples/rich_widgets_chat.dart`. None were warnings or
errors, but a new user copying from the example file would inherit
deprecation warnings and would see linter chatter in their IDE.
**[FIXED]** — replaced all `withOpacity(x)` with `withOpacityCompat(x)`
(matching the package convention documented in CLAUDE.md), `const`-ified
the renderer map and the `_Bar` widgets. `flutter analyze example/` now
returns "No issues found!".

## 7. AGENTS.md consistency after 8 iters

After this iter's fixes (sections 3 and 4 above), `AGENTS.md` snippets
match the current public API. The fixed items were drift from
iter-1's authoring relative to the package's actual factory shapes —
likely there from the start, but only caught now during the developer
journey walkthrough. The gotchas list at the bottom (`withOpacityCompat`,
both streaming flags, ChatMessage.rich bypasses the bubble, etc.)
remains accurate. `[FIXED]` (entire file pass complete).

---

## Friction summary

| # | Category | Severity | Status |
|---|---|---|---|
| 1.1 | Differentiator table missing from README top | Low | QUEUED |
| 1.2 | Install + Quick Start buried below features | Low | QUEUED |
| 2 | Quickstart compile check | — | NOT A PROBLEM |
| 3 | `AGENTS.md` `updateMessage(id, text:)` does not compile | High | FIXED |
| 3.b | README missing end-to-end streaming snippet | Medium | QUEUED |
| 4.a | `AGENTS.md` `ActionParameter.integer` does not exist | High | FIXED |
| 4.b | `AGENTS.md` `ActionResult.success(data:)` does not exist | High | FIXED |
| 4.c | `ai_action_provider.dart` dartdoc has same API bugs + wrong handler arity | High | FIXED |
| 5 | RTL advertised, zero code example anywhere | Medium | QUEUED |
| 6.a | README example list out of sync with actual menu | Low | QUEUED |
| 6.b | 9 lints in `example/lib/examples/rich_widgets_chat.dart` | Low | FIXED |
| 7 | `AGENTS.md` consistency overall | — | FIXED |

**Totals: 6 FIXED, 5 QUEUED, 1 NOT A PROBLEM.**

The four `[FIXED]` items in categories 3 and 4 are the load-bearing
ones — they are first-contact API claims that did not compile against
the package they describe. A Flutter developer trying either snippet
would have hit `The named parameter 'data' isn't defined` or
`The method 'integer' isn't defined for the type 'ActionParameter'` on
their first paste, and that is the worst possible onboarding
impression for an AI-positioned package.

## Queued items for iter 11+

1. **README structure pass.** Move Install + Quick Start above
   Features, pull the AGENTS.md differentiator table into the README
   near the top, and add a dedicated `## Streaming tokens` H2 section
   with the canonical addMessage → updateMessage(ChatMessage) flow.
   Single PR-sized.
2. **RTL example.** New file
   `example/lib/examples/rtl_chat.dart`, registered in `main.dart` and
   the home screen, demonstrating `Directionality.rtl`, an Arabic
   `ExampleQuestion`, and an Arabic streaming reply. README gets a
   matching `## RTL` section with a 4–6 line snippet. Single
   PR-sized.
3. **Example menu sync.** Update the README "Live Examples" bullets to
   match the actual five screens registered in `example/lib/main.dart`.
   Trivial.
