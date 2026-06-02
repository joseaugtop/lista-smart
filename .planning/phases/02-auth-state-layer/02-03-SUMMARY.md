# Plan 02-03 Summary — CartNotifier, FavoritesNotifier, CoinNotifier + WR-02 Fix

**Status:** COMPLETE  
**Date:** 2026-06-01  
**Tests:** 37/37 pass | `flutter analyze lib/` — No issues found

---

## What Was Done

### 1. WR-02 Fix — `coin_transaction.dart` line 25
Changed `DateTime.parse(...)` to `DateTime.tryParse(...) ?? DateTime.fromMillisecondsSinceEpoch(0)`.  
This prevents a `FormatException` crash when persisted JSON contains a malformed or missing `createdAt` string.

### 2. `lib/core/providers/cart_notifier.dart` (new)
- `CartNotifier extends Notifier<List<CartItem>>`
- Hydrates from `SharedPreferences` key `lista_smart_cart` (JSON-encoded list)
- `addItem()` — deduplicates by `productId`, increments quantity if already present
- `removeItem(productId)` — filters out matching entry
- `clear()` — empties list
- `_persist()` — writes full list to SharedPreferences after every mutation
- `cartProvider = NotifierProvider<CartNotifier, List<CartItem>>`

### 3. `lib/core/providers/favorites_notifier.dart` (new)
- `FavoritesNotifier extends Notifier<List<String>>`
- Hydrates from `SharedPreferences.getStringList('lista_smart_favorites')`
- `toggle(productId)` — adds if absent, removes if present; persists via `setStringList`
- `isFavorite(productId)` — pure read, no provider involved
- `favoritesProvider = NotifierProvider<FavoritesNotifier, List<String>>`

### 4. `lib/core/providers/coin_notifier.dart` (new)
- `@immutable CoinState` — holds `balance: int` and `transactions: List<CoinTransaction>`
- `CoinNotifier extends Notifier<CoinState>`
- `build()` — reads balance from `SharedPreferences` falling back to `user?.coinBalance ?? 0`; reads transaction list from JSON falling back to `MockData.initialTransactions`
- `addCoins(amount, description)` — prepends new `CoinTransaction`, increments balance, persists both
- `coinProvider = NotifierProvider<CoinNotifier, CoinState>`

### 5. Tests Created (3 files, 16 new tests)
- `test/providers/cart_notifier_test.dart` — 6 tests (empty build, addItem dedup, removeItem, clear, hydration, corrupted JSON)
- `test/providers/favorites_notifier_test.dart` — 4 tests (empty build, toggle add/remove, isFavorite, hydration)
- `test/providers/coin_notifier_test.dart` — 6 tests (WR-02 parse valid, WR-02 parse invalid no-throw, balance from user, addCoins, hydration, corrupted tx JSON fallback)

### 6. Incidental Fix — `home_screen.dart`
Added missing `const` to `SliverAppBar` constructor (pre-existing `prefer_const_constructors` info that blocked `flutter analyze lib/` exit 0).

---

## Acceptance Criteria Verification

| Criterion | Result |
|-----------|--------|
| `DateTime.tryParse` in coin_transaction.dart | PASS |
| `DateTime.parse(` NOT in coin_transaction.dart | PASS |
| `class CartNotifier extends Notifier<List<CartItem>>` | PASS |
| `class FavoritesNotifier extends Notifier<List<String>>` | PASS |
| `getStringList` and `setStringList` in favorites_notifier.dart | PASS |
| `StateNotifierProvider` NOT in any new file | PASS |
| `class CoinNotifier extends Notifier<CoinState>` | PASS |
| `@immutable` class CoinState | PASS |
| `user?.coinBalance` in coin_notifier.dart | PASS |
| `MockData.initialTransactions` in coin_notifier.dart | PASS |
| `NotifierProvider<CoinNotifier, CoinState>` | PASS |
| `flutter analyze lib/` exits 0 | PASS |
| Full `flutter test test/ --no-pub` 37/37 | PASS |

---

## Patterns Established

- All state notifiers follow `ref.watch` in `build()` only; `ref.read` in mutation methods.
- SharedPreferences hydration is done synchronously in `build()` via the sentinel provider override.
- Corrupted JSON always falls back gracefully (empty list or mock data) — no rethrow.
- `CoinTransaction` does not implement `==`/`hashCode` — test equality via `.id` field, not object identity.
