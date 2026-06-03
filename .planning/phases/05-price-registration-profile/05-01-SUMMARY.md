---
phase: 05-price-registration-profile
plan: "01"
subsystem: price-registration
tags: [scanner, confetti, coin-award, widget-tests, preg-01, preg-02, preg-03, preg-04]
dependency_graph:
  requires: []
  provides:
    - ScannerScreen 3-page PageView wizard (PREG-01..04)
    - AppStrings.scanReceiptDescription shared constant
    - confetti 0.7.0 dependency
    - PREG-01/02/03 widget tests
    - PREG-04 coin-description unit test
  affects:
    - lib/core/constants/app_strings.dart (new)
    - lib/features/price_registration/presentation/scanner_screen.dart (replaced)
    - test/features/scanner/scanner_screen_test.dart (new)
    - test/providers/coin_notifier_test.dart (extended)
    - pubspec.yaml (new dep)
tech_stack:
  added:
    - confetti: ^0.7.0 (ConfettiWidget + ConfettiController, locked to 0.7.0 via semver)
  patterns:
    - ConsumerStatefulWidget with PageController + ConfettiController + bool _loading
    - Loading overlay: Stack → if (_loading) Container.withValues(alpha:0.6)
    - PopScope(canPop:false, onPopInvokedWithResult) for wizard back-button
    - NeverScrollableScrollPhysics on PageView (programmatic navigation only)
    - addPostFrameCallback for ConfettiController.play() (A3 mitigation)
    - Controller ownership: only _ScannerScreenState disposes ConfettiController
    - BRL format with replaceAll(' ', ' ') for test-finder compatibility
key_files:
  created:
    - lib/core/constants/app_strings.dart
    - test/features/scanner/scanner_screen_test.dart
  modified:
    - pubspec.yaml
    - pubspec.lock
    - lib/features/price_registration/presentation/scanner_screen.dart
    - test/providers/coin_notifier_test.dart
decisions:
  - "confetti ^0.7.0 locked via Dart semver — resolves to exactly 0.7.0, not 0.8.0"
  - "_returnHome() = jumpToPage(0) only (A4 mitigation) — context.go() omitted as no-op risk"
  - "ConfettiController owned by _ScannerScreenState, passed to _Step3Widget as ref (no child dispose)"
  - "BRL total uses .replaceAll(non-breaking-space, space) to normalize for find.text() in tests"
  - "addPostFrameCallback for play() ensures ConfettiWidget is laid out before animation fires (A3 mitigation)"
metrics:
  duration: "~30 minutes"
  completed_date: "2026-06-03"
  tasks_completed: 4
  tasks_total: 4
  files_created: 2
  files_modified: 4
---

# Phase 05 Plan 01: ScannerScreen + Confetti + Tests Summary

**One-liner:** 3-step receipt-registration PageView wizard with 2s loading overlay, Bistek mock receipt, +10 coin award via `addCoins(10, AppStrings.scanReceiptDescription)`, and ConfettiWidget celebration via `addPostFrameCallback`.

## What Was Built

### Task 1: confetti dependency + AppStrings constant
- Added `confetti: ^0.7.0` to `pubspec.yaml` (resolves to 0.7.0 exactly, blocking 0.8.0 breaking API)
- Created `lib/core/constants/app_strings.dart` with `abstract class AppStrings { static const String scanReceiptDescription = 'Cadastro de nota fiscal'; }`
- Single source of truth shared between ScannerScreen coin award and future ProfileScreen scan-count filter

### Task 2: Wave 0 test stubs + PREG-04
- Extended `test/providers/coin_notifier_test.dart` with PREG-04 test that verifies `addCoins(10, AppStrings.scanReceiptDescription)` records correct description and amount — passes GREEN immediately against existing `addCoins()`
- Created `test/features/scanner/scanner_screen_test.dart` with 3 PREG stubs (skip:true) using `UncontrolledProviderScope` + logged-in user helper pattern from `store_screen_test.dart`

### Task 3: ScannerScreen Steps 1 + 2
- Replaced placeholder `StatelessWidget` with `ConsumerStatefulWidget` PageView wizard
- Step 1: two glassmorphic `_MethodCard` widgets (QR Code / Camera) both calling `_startScan()`
- `_startScan()` async: `setState(_loading=true)` → `Future.delayed(2s)` → `if (!mounted) return` → `setState(_loading=false)` → `nextPage()`
- Loading overlay: `Stack → if (_loading) Container(color: Colors.black.withValues(alpha:0.6))`
- Step 2: scrollable `_ReceiptCard` (glassmorphic): Bistek header, today's date via `DateFormat`, 4 MockData products, total `R$ 87,43` via `_brl.format(87.43).replaceAll(' ',' ')`, `ElevatedButton` "Confirmar e Ganhar Moedas"
- `_confirmReceipt()`: calls `ref.read(coinProvider.notifier).addCoins(10, AppStrings.scanReceiptDescription)` then `nextPage()`

### Task 4: ScannerScreen Step 3 + un-skip PREG tests
- Step 3 `_Step3Widget(StatefulWidget)` receives `ConfettiController` from parent (no dispose in child — Pitfall 1 avoided)
- `initState` registers `addPostFrameCallback(() { if (mounted) widget.controller.play(); })` (A3 mitigation)
- `TweenAnimationBuilder<double>` scale animation (0→1, 600ms, elasticOut) on `LucideIcons.coins` 80px
- "+10 Smart Coins" headline, success text, "Escanear Outra Nota" (OutlinedButton → jumpToPage(0)), "Voltar para início" (TextButton → context.go(AppRoutes.home))
- `ConfettiWidget` with 20 particles, explosive blast, colors: primary/orange/pink/yellow
- Removed `skip: true` from all 3 PREG tests — all pass GREEN

## Test Results

| Test | Status | Notes |
|------|--------|-------|
| PREG-01: Step 1 renders QR Code and Camera method cards | PASS | |
| PREG-02: Step 2 shows receipt fields and confirm button | PASS | |
| PREG-03: Step 3 shows ConfettiWidget and +10 Smart Coins | PASS | |
| PREG-04: addCoins records scan description | PASS | |
| Full suite (96 tests) | ALL PASS | 0 regressions |
| flutter analyze scanner_screen.dart | 0 issues | |
| flutter analyze lib/ | 9 pre-existing infos | Not in scope — pre-existing files |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] BRL formatter non-breaking space in total amount**
- **Found during:** Task 4 PREG-02 test execution
- **Issue:** `NumberFormat.currency(locale:'pt_BR')` inserts ` ` (non-breaking space) between `R$` and the number; `find.text('R$ 87,43')` uses regular space and found 0 widgets
- **Fix:** Added `.replaceAll(' ', ' ')` to the formatted total string in `_ReceiptCard`; this normalizes the output for test-finder while keeping the formatter pattern per plan spec
- **Files modified:** `lib/features/price_registration/presentation/scanner_screen.dart`
- **Commit:** included in `feat(05-01): implement ScannerScreen Steps 1 and 2`

**2. [Rule 1 - Bug] _ReceiptCard constructor not const**
- **Found during:** Task 3 flutter analyze
- **Issue:** `prefer_const_constructors_in_immutables` — `_ReceiptCard()` not declared `const`
- **Fix:** Changed `_ReceiptCard()` constructor to `const _ReceiptCard()` and usage site to `const _ReceiptCard()`
- **Files modified:** `lib/features/price_registration/presentation/scanner_screen.dart`
- **Commit:** same task 3 commit

## Known Stubs

None — all MockData receipt content is intentionally hardcoded mock data, not stubs blocking the plan goal.

## Deferred Items

Pre-existing `info` lints in `home_screen.dart` and `shopping_list_screen.dart` (9 `prefer_const_constructors` infos) are out-of-scope for this plan. Logged to `deferred-items.md`.

## Threat Flags

No new network surface, auth bypass vectors, or trust boundary changes introduced. confetti package supply chain risk accepted per STRIDE register T-05-01 (audited, funwith.app verified publisher, MIT, 4yr history). T-05-02 (double-dispose) and T-05-03 (setState after dispose) mitigated by ownership pattern and `if (!mounted) return`.

## Self-Check: PASSED

- [x] `lib/core/constants/app_strings.dart` exists
- [x] `lib/features/price_registration/presentation/scanner_screen.dart` is the full wizard (not placeholder)
- [x] `test/features/scanner/scanner_screen_test.dart` exists
- [x] `test/providers/coin_notifier_test.dart` has PREG-04 test
- [x] Commits: cf5669d (task 1), 047a47f (task 2), 1ce7786 (task 3), a12d64a (task 4)
- [x] `flutter test --no-pub`: 96 tests, all passed
- [x] `flutter analyze scanner_screen.dart`: 0 issues
- [x] No `withOpacity` in scanner_screen.dart
- [x] `addCoins(10, AppStrings.scanReceiptDescription)` present in scanner_screen.dart
- [x] No `skip: true` in scanner_screen_test.dart
