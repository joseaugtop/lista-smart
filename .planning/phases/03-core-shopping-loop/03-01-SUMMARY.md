# Plan 01 Summary — Domain Models + Core Providers

**Phase:** 03-core-shopping-loop  
**Plan:** 01  
**Status:** COMPLETE  
**Date:** 2026-06-02

---

## What Was Created

### Task 1 — Extend Domain Models + MockData

- **`lib/features/profile/domain/nutritional_info.dart`** (NEW)  
  Immutable value object with 7 fields (calories, protein, carbs, fat, fiber, sodium, servingSize), full fromJson/toJson.

- **`lib/features/profile/domain/product.dart`** (EXTENDED)  
  Added 4 optional fields with safe defaults: `ean = ''`, `subcategory = ''`, `department = ''`, `nutritionalInfo` (nullable). All 12 existing const MockData constructors compile unchanged.

- **`lib/core/data/mock_data.dart`** (EXTENDED)  
  Added `fuelPrice` (6.50), `vehicle` (Fiat Uno, 12.0 km/L), and `prices` map (all 12 product IDs × 4 supermarkets with distinct per-store prices). Supermarket keys match `supermarketDistances`: Bistek, Giassi, Angeloni, Atacadão.

### Task 2 — Core Providers + CartNotifier Extensions

- **`lib/core/providers/products_provider.dart`** (NEW) — `Provider<List<Product>>` over MockData
- **`lib/core/providers/prices_provider.dart`** (NEW) — `Provider<Map<String,Map<String,double>>>` over MockData
- **`lib/core/providers/vehicle_provider.dart`** (NEW) — `Provider<Vehicle>` over MockData
- **`lib/core/providers/search_query_notifier.dart`** (NEW) — `NotifierProvider<String>` with `update()`/`clear()`
- **`lib/core/providers/view_mode_notifier.dart`** (NEW) — `NotifierProvider<ViewMode>` enum (grid/list) with `setGrid()`/`setList()`
- **`lib/core/providers/fuel_toggle_notifier.dart`** (NEW) — `NotifierProvider<bool>` persisted to SharedPreferences key `lista_smart_fuel_toggle`, default `true`
- **`lib/core/providers/cart_notifier.dart`** (EXTENDED) — `incrementQuantity()` and `decrementQuantity()` added using spread-operator immutable updates; decrement removes item at quantity 1

### Task 3 — Derived Providers

- **`lib/core/providers/filtered_products_provider.dart`** (NEW)  
  Derived `Provider<List<Product>>` watching productsProvider + searchQueryProvider. Filters by name/brand/category, case-insensitive, returns full list on empty query.

- **`lib/core/providers/comparison_results_provider.dart`** (NEW)  
  Derived `Provider<List<SupermarketTotal>>` watching cart, prices, vehicle, fuelToggle. Computes per-supermarket productsCost from prices map (falls back to item.unitPrice), fuelCost = `(distanceKm * 2 / vehicle.fuelEfficiencyKmPerLiter) * fuelPrice` when toggle is on, then sorts ascending by totalCost. Contains `SupermarketTotal` immutable value class.

### Tests Created (13 new test files total for this plan)

- `test/providers/search_query_notifier_test.dart` — 4 tests
- `test/providers/view_mode_notifier_test.dart` — 3 tests
- `test/providers/fuel_toggle_notifier_test.dart` — 5 tests
- `test/providers/cart_notifier_quantity_test.dart` — 5 tests
- `test/providers/filtered_products_provider_test.dart` — 7 tests
- `test/providers/comparison_results_provider_test.dart` — 7 tests

---

## Key Decisions

1. **NutritionalInfo as optional field on Product** — `nutritionalInfo` is nullable with no default so `const` Product constructors in MockData need no changes.
2. **FuelToggleNotifier mirrors FavoritesNotifier** — uses `ref.watch(sharedPreferencesProvider)` in `build()` and `ref.read` in `toggle()`, consistent pattern.
3. **`prefer_const_declarations` lint** — `fuelPrice` and `distances` inside the provider lambda are `const` since they reference compile-time constants from MockData.
4. **`fuelEfficiencyKmPerLiter` field name** — confirmed from `vehicle.dart` before writing comparison provider; no field-name typo risk.

---

## Deviations from Plan

None. All files were created as specified. The only minor difference is adding type annotations (`const double`, `const`) inside the provider function body to satisfy the analyzer's `prefer_const_declarations` lint rule.

---

## Verification Results

```
flutter analyze lib/features/profile/domain/ lib/core/data/mock_data.dart lib/core/providers/
→ No issues found

flutter test (68 tests total)
→ All tests passed
```
