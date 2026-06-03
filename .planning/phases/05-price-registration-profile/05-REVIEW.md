---
phase: 05-price-registration-profile
reviewed: 2026-06-02T00:00:00Z
depth: standard
files_reviewed: 10
files_reviewed_list:
  - lib/core/constants/app_strings.dart
  - lib/core/data/mock_data.dart
  - lib/core/providers/user_notifier.dart
  - lib/features/auth/domain/user.dart
  - lib/features/price_registration/presentation/scanner_screen.dart
  - lib/features/profile/presentation/profile_screen.dart
  - test/features/profile/profile_screen_test.dart
  - test/features/scanner/scanner_screen_test.dart
  - test/providers/coin_notifier_test.dart
  - test/providers/user_notifier_test.dart
findings:
  critical: 3
  warning: 5
  info: 3
  total: 11
status: issues_found
---

# Phase 05: Code Review Report

**Reviewed:** 2026-06-02T00:00:00Z
**Depth:** standard
**Files Reviewed:** 10
**Status:** issues_found

## Summary

This phase delivers `ScannerScreen` (3-step receipt-scanning flow with coin award), `ProfileScreen` (editable profile + impact stats), `UserNotifier`, `CoinNotifier` (already reviewed in supporting files), and the `User` domain model. The overall architecture is sound: Notifier/NotifierProvider is used correctly, `ref.watch` stays in `build()`, and `withValues(alpha:)` is used throughout. No StateNotifier, no raw network calls, no hardcoded credentials.

Three blockers are present: a hardcoded `87.43` total that is mathematically wrong given the displayed line items; a `_ReceiptCard` that accesses `MockData.products` by raw index with no bounds guard; and a `spendCoins` guard in `UserNotifier` that allows the coin balance to go negative. Five warnings cover: an `initState` `ref.read` that silently shows stale data after a profile is persisted on a different container; hardcoded raw colour literals in `_Step3Widget`'s confetti list; a missing `PROF-02` test case; the coin-balance divergence between `userNotifierProvider` and `coinProvider`; and a `_save()` that accepts an empty-string name/email without any validation. Three info items round out the findings.

---

## Critical Issues

### CR-01: Hardcoded receipt total does not match displayed line items

**File:** `lib/features/price_registration/presentation/scanner_screen.dart:385`

**Issue:** `_brl.format(87.43)` is a hardcoded magic literal. The four line items shown from `MockData` sum to `5.49 + 6.99 + 8.99 + 9.49 = 30.96`, not `87.43`. The displayed total is factually wrong for every value of the mock data. Because the total is the primary data the user sees when deciding whether to confirm, this is a correctness failure visible on every scan. If the mock prices are ever adjusted (e.g. as part of a later phase), the total stays silently wrong.

**Fix:**
```dart
// In _ReceiptCard — compute total from _lineItems instead of hardcoding
static double get _total =>
    _lineItems.fold(0.0, (sum, item) => sum + item.$2);

// Then in build():
Text(
  _brl.format(_total),
  ...
),
```

---

### CR-02: `_ReceiptCard._lineItems` accesses `MockData.products` by raw index — brittle and unguarded

**File:** `lib/features/price_registration/presentation/scanner_screen.dart:303-308`

**Issue:** The four items are selected by positional index (`[0]`, `[3]`, `[9]`, `[11]`). `MockData.products` is a `const List` of 12 items, so the current indices are in range. However the list is ordered by hand in `mock_data.dart` and the comments only document which product is at each position. If any product is inserted, removed, or reordered (e.g., adding an item in category ordering during a later phase), these indices silently point to the wrong products — or throw a `RangeError` at runtime if the list shrinks below 12 entries. There is no compile-time check and no runtime guard.

**Fix:**
```dart
// Look up by product id instead of positional index
static Product _byId(String id) =>
    MockData.products.firstWhere((p) => p.id == id);

static final _lineItems = [
  (_byId('p01').name, _byId('p01').averagePrice), // Leite Integral
  (_byId('p04').name, _byId('p04').averagePrice), // Banana Prata
  (_byId('p10').name, _byId('p10').averagePrice), // Pão de Forma
  (_byId('p12').name, _byId('p12').averagePrice), // Feijão Carioca
];
```
`firstWhere` will throw a `StateError` early if the id disappears from mock data, making the failure loud rather than silent.

---

### CR-03: `UserNotifier.spendCoins` allows the balance to go negative

**File:** `lib/core/providers/user_notifier.dart:35-41`

**Issue:** `spendCoins` subtracts `amount` from `current.coinBalance` without verifying that the result is non-negative:

```dart
void spendCoins(int amount) {
  final current = state;
  if (current == null) return;
  final updated = current.copyWith(coinBalance: current.coinBalance - amount);
  state = updated;
  _persist(updated);
}
```

A caller passing `amount > current.coinBalance` produces a negative `coinBalance`, which is persisted to SharedPreferences and restored on the next app launch. `CoinNotifier.spendCoins` has the correct guard (`if (state.balance < amount) return;`) but `UserNotifier.spendCoins` does not. The two notifiers independently track balance for different purposes (the User domain object carries the balance for display; `CoinNotifier` manages the authoritative balance). Any caller using the UserNotifier path directly can corrupt the persisted value.

**Fix:**
```dart
void spendCoins(int amount) {
  final current = state;
  if (current == null) return;
  if (amount <= 0 || current.coinBalance < amount) return; // guard added
  final updated = current.copyWith(coinBalance: current.coinBalance - amount);
  state = updated;
  _persist(updated);
}
```

---

## Warnings

### WR-01: `ProfileScreen.initState` reads `userNotifierProvider` via `ref.read` — shows stale data if provider state was updated after first load

**File:** `lib/features/profile/presentation/profile_screen.dart:29`

**Issue:** The five `TextEditingController`s are initialised once in `initState` using `ref.read(userNotifierProvider)`. If the user's profile is updated elsewhere (or if the provider rebuilds due to SharedPreferences changes), the form fields will not reflect the new state — they were set once at construction time and are never refreshed. More concretely: if the user saves the profile, navigates away, then navigates back to the screen, `initState` fires again and will show the values from `ref.read` at that moment — which is correct for a fresh screen instance. However if the same widget instance is retained while the provider updates (e.g., bottom nav tab switch without disposal), the controllers silently hold stale text.

Additionally, `ref.read` in `initState` is listed as a CLAUDE.md anti-pattern ("Do not call `ref.watch` inside `initState`"). The note refers to `ref.watch`, but the underlying intent is that provider reads in `initState` are unreliable for reactive data. The correct pattern for seeding controllers from provider state is to read in `initState` with `ref.read` (acceptable as a one-time seed) while watching the provider in `build()` for display-only data — which is partially done. The real issue is there is no mechanism to re-seed controllers if the same state object's provider value changes while the widget stays alive.

**Fix:** This is low-risk for the current navigation pattern (each tab creates a new widget instance). Document the assumption with a comment, or add a `ref.listen` in `initState` that resets the controllers when the user provider emits a new non-null value:
```dart
// In initState, after the initial seed:
ref.listenManual(userNotifierProvider, (_, next) {
  if (next == null) return;
  _nameCtrl.text = next.name;
  _emailCtrl.text = next.email;
  _addressCtrl.text = next.address;
  _vehicleCtrl.text = next.vehicleModel.isNotEmpty
      ? next.vehicleModel
      : MockData.vehicle.model;
  _efficiencyCtrl.text = next.fuelEfficiency != 0.0
      ? next.fuelEfficiency.toString()
      : MockData.vehicle.fuelEfficiencyKmPerLiter.toString();
});
```

---

### WR-02: `_ProfileScreen._save()` accepts empty string for required fields (name, email) — persists invalid user state

**File:** `lib/features/profile/presentation/profile_screen.dart:55-70`

**Issue:** `_save()` calls `_nameCtrl.text.trim()` and passes the result directly to `updateProfile` without any validation. An empty name or email is persisted to SharedPreferences and becomes the new user state. Downstream widgets that display `user?.name ?? ''` will render a blank avatar and an empty name label with no error feedback.

**Fix:** Add validation before calling `updateProfile`:
```dart
void _save() {
  final name = _nameCtrl.text.trim();
  final email = _emailCtrl.text.trim();
  if (name.isEmpty || email.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Nome e e-mail são obrigatórios.')),
    );
    return;
  }
  // ... rest of save
}
```
Alternatively use a `Form` + `TextFormField` with `validator` callbacks so the form's `validate()` method blocks save automatically.

---

### WR-03: Coin balance state divergence between `UserNotifier` and `CoinNotifier` — no synchronisation

**File:** `lib/core/providers/user_notifier.dart:38` and `lib/core/providers/coin_notifier.dart:48`

**Issue:** `User.coinBalance` and `CoinState.balance` are two independent integers stored in two separate SharedPreferences keys (`lista_smart_user` JSON field vs `lista_smart_coins_balance`). `CoinNotifier.build()` seeds from `user?.coinBalance` only when no persisted balance key exists. After any `addCoins` or `spendCoins` call, the two values diverge: `CoinNotifier` persists the authoritative balance under its own key, while `User.coinBalance` remains frozen at the login-time value (`750`) unless explicitly updated via `UserNotifier.spendCoins`. Any widget that reads `userNotifierProvider` for display (e.g., a coin balance badge) will show `750` forever while `coinProvider.balance` correctly reflects the running total.

**Fix:** Either designate one as the single source of truth, or keep them synchronised. The minimal fix is to have `CoinNotifier._persist()` also call `ref.read(userNotifierProvider.notifier).spendCoins`/`addCoins` to keep the User domain object in sync — but that creates a circular dependency. A cleaner approach: remove `coinBalance` from the `User` domain model and let all coin display widgets read from `coinProvider` exclusively.

---

### WR-04: Raw hex colour literals used inside `_Step3Widget` confetti colours

**File:** `lib/features/price_registration/presentation/scanner_screen.dart:530-533`

**Issue:** The confetti colour list contains three raw `Color` literals (`0xFFF97316`, `0xFFEC4899`, `0xFFEAB308`) that are not sourced from `AppColors`. Project convention (CLAUDE.md) requires `AppColors` tokens only — no raw color literals.

**Fix:**
```dart
// Add to AppColors:
static const Color accent1 = Color(0xFFF97316); // orange
static const Color accent2 = Color(0xFFEC4899); // pink
static const Color accent3 = Color(0xFFEAB308); // yellow

// In scanner_screen.dart:
colors: const [
  AppColors.primary,
  AppColors.accent1,
  AppColors.accent2,
  AppColors.accent3,
],
```

---

### WR-05: Missing test case PROF-02 (save profile and verify persistence)

**File:** `test/features/profile/profile_screen_test.dart`

**Issue:** The test file covers PROF-01 (pre-filled fields) and PROF-03 (impact stats), but there is no PROF-02 test. A PROF-02 test should exercise the save flow: edit a field, tap "Salvar Alterações", and verify the provider state and/or the snackbar. Without it, the `_save()` code path — including the `updateProfile` notifier call and the snackbar display — has no widget-level test coverage. Given that `_save()` also has the WR-02 input-validation gap, this absence leaves a known bug path unguarded by automated tests.

**Fix:** Add a PROF-02 widget test:
```dart
testWidgets(
  'PROF-02: save button calls updateProfile and shows snackbar',
  (tester) async {
    final container = await _makeContainer();
    await _pumpScreen(tester, container);

    await tester.enterText(find.widgetWithText(TextFormField, 'Nome completo'), 'Nova Pessoa');
    await tester.tap(find.text('Salvar Alterações'));
    await tester.pump();

    expect(find.text('Perfil atualizado!'), findsOneWidget);
    expect(container.read(userNotifierProvider)?.name, equals('Nova Pessoa'));
  },
);
```

---

## Info

### IN-01: `_MethodCard` uses raw magic number `100` for height

**File:** `lib/features/price_registration/presentation/scanner_screen.dart:201`

**Issue:** `height: 100` is a raw pixel value with no token. Project convention requires `AppSizes` tokens or named constants for all spacing/sizing values.

**Fix:** Either add a dedicated token to `AppSizes` (e.g., `static const double cardHeightMethod = 100.0;`) or compose it from existing tokens (`AppSizes.spacingL * 4 = 96.0` is close but not identical). Prefer a named constant.

---

### IN-02: `OutlinedButton` padding `14` is a raw magic number

**File:** `lib/features/price_registration/presentation/scanner_screen.dart:500`

**Issue:** `const EdgeInsets.symmetric(vertical: 14)` uses a raw value not present in `AppSizes`. `AppSizes.spacingS = 8` and `AppSizes.spacingM = 16` bracket it; 14 appears to be an intentional intermediate value, but it should be named.

**Fix:** Use `AppSizes.spacingM` (16) for consistency with the other buttons on the same screen, or add `AppSizes.spacingML = 14.0` if the intermediate size is intentional.

---

### IN-03: `_ImpactSection` hard-codes "buscas efetuadas" (47) and "economia estimada" (R$ 342) as static strings

**File:** `lib/features/profile/presentation/profile_screen.dart:392-403`

**Issue:** The two rightmost stat chips in `_ImpactSection` display completely hardcoded values (`'47'` and `'R\$ 342'`) that are never derived from any provider or mock data source. A future phase will likely want these to reflect real or computed mock state. The hardcoded strings will need to be refactored at that point, and their current provenance will not be obvious to the next developer.

**Fix:** At minimum, extract them as named constants in `MockData` or a dedicated mock-stats class, and add a brief comment noting they are placeholder values:
```dart
// mock_data.dart
static const int mockSearchCount = 47;
static const String mockEstimatedSavings = 'R\$ 342';
```
This does not change runtime behaviour but makes the mock nature explicit and co-locates all mock data in one file.

---

_Reviewed: 2026-06-02T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
