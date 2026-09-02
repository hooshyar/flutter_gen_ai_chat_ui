# Contributing

## Running tests

```bash
flutter test
```

## Golden (screenshot-diff) tests

`test/golden/chat_golden_test.dart` pins the visual appearance of the core
chat surfaces (default bubble, welcome message, a mid-stream response, a
markdown code block, and RTL layout) against saved baseline images in
`test/golden/goldens/`.

These are meaningful **only when run locally on macOS**. Font rendering
differs too much across operating systems for a pixel-perfect comparison in
CI, so `test/flutter_test_config.dart` swaps in an always-passing comparator
on non-macOS platforms — the tests still execute there (catching crashes),
but the image comparison itself is a no-op.

After an intentional visual change, regenerate the baselines on a Mac:

```bash
flutter test --update-goldens test/golden/chat_golden_test.dart
```

Then look at the diffs in `git diff` / the updated PNGs in
`test/golden/goldens/` before committing — a golden update should always be
reviewed like any other code change, not accepted blindly.

## Before submitting a change

```bash
dart format .
dart analyze --fatal-infos
flutter test
```

And for `example/`:

```bash
cd example && flutter analyze --fatal-infos
```
