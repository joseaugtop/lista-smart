---
phase: 3
slug: core-shopping-loop
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-01
---

# Phase 3 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test (built-in, SDK bundled) |
| **Config file** | `pubspec.yaml` (flutter_test: sdk: flutter) |
| **Quick run command** | `flutter test` |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | ~5 seconds |

---

## Sampling Rate

- **After every task commit:** Run `flutter test`
- **After every plan wave:** Run `flutter test`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** ~5 seconds

---

## Per-Task Verification Map

| Req ID | Behavior | Test Type | Automated Command | File Exists | Status |
|--------|----------|-----------|-------------------|-------------|--------|
| HOME-02 | filteredProductsProvider filtra por query | unit | `flutter test test/providers/filtered_products_provider_test.dart` | ❌ Wave 0 | ⬜ pending |
| SHOP-02 | CartNotifier.incrementQuantity / decrementQuantity | unit | `flutter test test/providers/cart_notifier_test.dart` | ❌ Wave 0 | ⬜ pending |
| COMP-01/02/03 | comparisonResultsProvider ordena por totalCost, calcula fuel | unit | `flutter test test/providers/comparison_results_provider_test.dart` | ❌ Wave 0 | ⬜ pending |
| HOME-04 | favoritesProvider toggle | unit | `flutter test test/providers/favorites_notifier_test.dart` | ❌ Wave 0 | ⬜ pending |
| SHOP-04/D-07 | fuelToggleProvider persiste em SharedPrefs | unit | `flutter test test/providers/fuel_toggle_notifier_test.dart` | ❌ Wave 0 | ⬜ pending |
| HOME-01/03/07 | HomeScreen renderiza grid/list, navega para detail | widget | `flutter test test/features/home/home_screen_test.dart` | ❌ Wave 0 | ⬜ pending |
| SHOP-01..05 | ShoppingListScreen com cart cheio/vazio | widget | `flutter test test/features/shopping_list/shopping_list_screen_test.dart` | ❌ Wave 0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/providers/filtered_products_provider_test.dart` — cobre HOME-02
- [ ] `test/providers/cart_notifier_test.dart` — cobre SHOP-02 (métodos increment/decrement)
- [ ] `test/providers/comparison_results_provider_test.dart` — cobre COMP-01/02/03
- [ ] `test/providers/fuel_toggle_notifier_test.dart` — cobre SHOP-04/D-07
- [ ] `test/features/home/home_screen_test.dart` — cobre HOME-01/03/07
- [ ] `test/features/shopping_list/shopping_list_screen_test.dart` — cobre SHOP-01..05

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Scroll position preserved per tab | HOME-07 | StatefulShellRoute/IndexedStack behavior, not unit-testable | Scroll Home list down, switch to Lista tab, switch back — position preserved |
| Image.network fallback icon visible | HOME-03 | Requires network failure simulation | Disable WiFi, launch app — placeholder icon shows for all product images |
| Bottom sheet DraggableScrollable gestures | SHOP-05 | Flutter widget test não simula drag gestures confiável | Open nutritional info, drag sheet up/down — responds correctly |
| Swipe-to-dismiss cart item | SHOP-02 | Dismissible swipe in widget tests flaky | Add item to cart, swipe left on item — item removed |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 5s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
