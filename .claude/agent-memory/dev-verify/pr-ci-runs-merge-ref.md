---
name: pr-ci-runs-merge-ref
description: PR CI (pull_request event) dry-runs the merge with current main, so a clean local branch dry-run can pass while CI fails after main moves
metadata:
  type: feedback
---

A green `dart pub publish --dry-run` on the branch worktree does not prove the PR's CI will be green. pull_request CI builds `refs/pull/N/merge`, so anything newly merged to main ends up in the package too, for example a top-level `docs/` dir triggering the "Rename docs to doc" warning (flutter_streaming_text_markdown PR #18, 2026-10-02, after PR #19 landed).

**Why:** round-2 verify of stm 1.11.0 had a 0-warning local dry-run but red CI, caused only by main gaining `docs/` + `backlog/`.

**How to apply:** for pre-publish gates, also check `git fetch origin main` for new commits since the merge-base. Reproduce on `git merge-tree --write-tree origin/main HEAD` + `commit-tree` in a scratch worktree, then remove it. Always wait for the PR CI result on the exact head SHA. Related: [[flutter-tooling-churn-and-pana]].
