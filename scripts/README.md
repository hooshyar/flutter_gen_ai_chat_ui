# Package Validation Scripts

This directory contains scripts to validate the package's pub.dev score and overall health.

## Scripts

### `validate_pub_score.sh` — Comprehensive Validation

Full validation covering all aspects of pub.dev scoring:
- ✅ Dependencies check and updates
- ✅ Static analysis (dart analyze)
- ✅ Code formatting (dart format)
- ✅ Test execution with coverage
- ✅ Documentation generation (dartdoc)
- ✅ Pub.dev score (pana)
- ✅ Package structure verification

**Usage:**
```bash
./scripts/validate_pub_score.sh
```

**Requirements:**
- Flutter SDK installed
- pana installed: `dart pub global activate pana`

**Output:**
- Detailed report with pass/fail for each phase
- Overall score and recommendations
- Exit code 0 for success, 1 for failures

---

### `quick_check.sh` — Fast Pre-Validation

Quick sanity checks before full validation:
- Static analysis
- Formatting check
- Test execution

**Usage:**
```bash
./scripts/quick_check.sh
```

**When to use:**
- Before committing changes
- During development for rapid feedback
- As a pre-validation check

---

## Typical Workflow

### 1. Development Cycle
```bash
# Make changes...

# Quick check
./scripts/quick_check.sh

# If passes, commit
git add .
git commit -m "feat: your changes"
```

### 2. Pre-Release Validation
```bash
# Full validation before publishing
./scripts/validate_pub_score.sh

# Review output
# Fix any issues
# Run again until 160/160

# Publish
flutter pub publish --dry-run
flutter pub publish
```

### 3. CI/CD Integration

Add to `.github/workflows/ci.yml`:
```yaml
- name: Validate Package
  run: ./scripts/validate_pub_score.sh
```

---

## Troubleshooting

### "pana not found"
```bash
dart pub global activate pana
export PATH="$PATH":"$HOME/.pub-cache/bin"
```

### "Flutter not found"
Ensure Flutter is in your PATH:
```bash
export PATH="$PATH:/path/to/flutter/bin"
```

### Dependencies outdated
```bash
flutter pub outdated
flutter pub upgrade
```

### Format issues
```bash
dart format .
```

### Analysis issues
```bash
dart analyze
dart fix --apply  # Auto-fix some issues
```

---

## Score Interpretation

| Score | Status | Action |
|-------|--------|--------|
| 160/160 | Perfect! | Ready to publish |
| 150-159 | Excellent | Minor improvements possible |
| 140-149 | Good | Address warnings |
| <140 | Needs work | Fix errors first |

---

## Additional Resources

- [Pub.dev Scoring](https://pub.dev/help/scoring)
- [Package Layout Conventions](https://dart.dev/tools/pub/package-layout)
- [Effective Dart: Documentation](https://dart.dev/guides/language/effective-dart/documentation)
- [pana Package](https://pub.dev/packages/pana)
