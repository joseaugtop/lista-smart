# Plan 01 — CoinLevel System + ShoppingListScreen Migration

**Status:** COMPLETE
**Date:** 2026-06-02

## What Was Built

### Task 1: CoinLevel system + spendCoins in CoinNotifier

File: `lib/core/providers/coin_notifier.dart`

- Added `enum CoinLevel { bronze, prata, ouro }` before `CoinState`
- Added `coinLevelOf(int balance) → CoinLevel` — thresholds: 500 = prata, 1500 = ouro
- Added `coinLevelProgress(int balance) → double` — normalized 0.0–1.0 progress within current level
- Added `void spendCoins(int amount, String description)` to `CoinNotifier`:
  - Guards: `amount <= 0` and `balance < amount` are no-ops
  - Records a `CoinTransaction` with negative `amount`
  - Prepends to `state.transactions`, decrements `state.balance`, persists

### Task 2: ShoppingListScreen migration + spendCoins tests

File: `lib/features/shopping_list/presentation/shopping_list_screen.dart`

- Added import for `coin_notifier.dart`
- Removed `userNotifierProvider` import and usage (was only used for coin balance — now fully replaced)
- `build()` now watches `coinProvider` for `coinBalance`
- `_compareWithLoading()` now reads `coinProvider.balance` for the balance check and calls `coinProvider.notifier.spendCoins(_comparisonCoinCost, 'Comparação de supermercados')`

File: `test/providers/coin_notifier_test.dart`

- Added `group('spendCoins', ...)` with 2 new tests:
  - `spendCoins() decrements balance and records negative transaction`
  - `spendCoins() is no-op when balance insufficient`

## Verification Results

- `flutter analyze` — 0 errors (only pre-existing prefer_const info hints)
- `flutter test test/providers/coin_notifier_test.dart` — 8/8 passed (6 existing + 2 new)
- `flutter test` — 84/84 passed (full suite green)
