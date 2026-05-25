---
phase: 1
slug: foundation
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-25
---

# Phase 1 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Flutter test (built-in) |
| **Config file** | pubspec.yaml (flutter_test dependency) |
| **Quick run command** | `flutter analyze` |
| **Full suite command** | `flutter test && flutter analyze` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `flutter analyze`
- **After every plan wave:** Run `flutter test && flutter analyze`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| pubspec setup | 01 | 1 | FOUN-01 | — | N/A | manual | `flutter pub get` exits 0 | ❌ W0 | ⬜ pending |
| theme setup | 01 | 1 | FOUN-02 | — | N/A | manual | `flutter analyze` exits 0 | ❌ W0 | ⬜ pending |
| nav shell | 01 | 2 | FOUN-03 | — | N/A | manual | App shows 5 tabs on device | ❌ W0 | ⬜ pending |
| domain models | 01 | 1 | FOUN-04 | — | N/A | unit | `flutter test test/models/` exits 0 | ❌ W0 | ⬜ pending |
| shared_prefs | 01 | 1 | FOUN-05 | — | N/A | unit | `flutter test test/repositories/` exits 0 | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/models/models_test.dart` — unit tests for User, Vehicle, Product, CartItem, CoinTransaction toJson/fromJson round-trip
- [ ] `test/repositories/shared_prefs_test.dart` — stub for SharedPreferences provider injection

*Flutter analyze covers compilation and static analysis for FOUN-01, FOUN-02, FOUN-03.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| 5-tab nav preserves scroll state | FOUN-03 | Requires running app on device/simulator | Open app, scroll in tab 1, switch to tab 2, switch back — scroll position preserved |
| Dark theme renders correctly on device | FOUN-02 | Visual check needed | Launch on dark-mode device; verify #09090B bg, #A3E615 primary, Inter font |
| lucide_icons resolves correctly | FOUN-01 | Pub resolution check | `flutter pub get` exits 0 with lucide_icons ^0.257.0 |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
