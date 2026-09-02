**Priority:** P1
**Component:** pub.dev package admin
**Gate:** ask-Hooshyar

**Problem:** Per issue #41's comment history, the OIDC tag-publish CI workflow authenticates fine
but pub.dev rejects it with "publishing from github is not enabled" — this is a one-time toggle on
pub.dev → package admin → Automated publishing (tag pattern `v{{version}}`) that only the account
owner can flip. The 2.15.0 release had to go out via local `dart pub publish` as a workaround.

**Acceptance criteria:**
- [ ] Confirm with Hooshyar that pub.dev automated publishing is (or isn't) enabled yet for this
      package (he may have already done this outside of any session).
- [ ] If not enabled, this task stays a gated ask — do NOT attempt to bypass by publishing locally
      as the default path going forward; local publish is the fallback, not the target state.
- [ ] Once enabled, verify by tagging a real release and confirming CI-driven publish succeeds.

**Notes:** This blocks the "release: bump version, CHANGELOG, tag so CI publishes" goal item from
being truly hands-off. Until resolved, releases still need a manual `dart pub publish` step.
