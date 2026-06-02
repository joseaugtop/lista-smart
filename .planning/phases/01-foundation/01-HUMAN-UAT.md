---
status: partial
phase: 01-foundation
source: [01-VERIFICATION.md]
started: 2026-06-01
updated: 2026-06-01
---

## Current Test

[awaiting human confirmation of 2 items]

## Tests

### 1. Inter font renders (not system Roboto fallback)
expected: Text in the app renders with Inter font (clean, geometric, distinct from Android's default Roboto). Inter has a characteristic "a" (double-story) and distinct number forms. If fonts are placeholders (12 bytes), text will look like Roboto.
result: [pending]

### 2. Scroll preservation between tabs
expected: On the Home tab, scroll to item 15+, switch to any other tab, switch back to Home — the list stays at item 15 (not reset to top). Confirms StatefulShellRoute.indexedStack is working.
result: [pending]

## Summary

total: 2
passed: 0
issues: 0
pending: 2
skipped: 0
blocked: 0

## Gaps
