---
phase: 05-price-registration-profile
plan: "02"
subsystem: profile
tags: [user-model, profile-screen, vehicle, impact-stats, persistence]
dependency_graph:
  requires: ["05-01"]
  provides: ["ProfileScreen", "User.vehicleModel", "User.fuelEfficiency", "UserNotifier.updateProfile"]
  affects: ["lib/features/auth/domain/user.dart", "lib/core/providers/user_notifier.dart", "lib/features/profile/presentation/profile_screen.dart"]
tech_stack:
  added: []
  patterns:
    - ConsumerStatefulWidget with TextEditingControllers initialized in initState via ref.read
    - Migration-safe fromJson using (as String?) and (as num?)?.toDouble()
    - SliverAppBar with FlexibleSpaceBar for expandable avatar header
    - Impact stats: derived from coinProvider.transactions filter + mocked values
key_files:
  created:
    - lib/features/profile/presentation/profile_screen.dart
    - test/features/profile/profile_screen_test.dart
  modified:
    - lib/features/auth/domain/user.dart
    - lib/core/data/mock_data.dart
    - lib/core/providers/user_notifier.dart
    - test/providers/user_notifier_test.dart
decisions:
  - "User.fromJson uses (as num?) cast for fuelEfficiency — prevents crash on legacy SharedPreferences data"
  - "MockData.user defaults match MockData.vehicle: vehicleModel Fiat Uno, fuelEfficiency 12.0"
  - "scannedCount derived from coinProvider.transactions filtered by AppStrings.scanReceiptDescription"
  - "SnackBar backgroundColor: AppColors.primary for save confirmation (D-07)"
metrics:
  duration: "~25 min"
  completed_date: "2026-06-03"
  tasks_completed: 3
  tasks_total: 3
  files_created: 2
  files_modified: 4
---

# Phase 05 Plan 02: ProfileScreen Vertical Slice Summary

**One-liner:** Editable ProfileScreen with migration-safe User model (vehicleModel + fuelEfficiency), UserNotifier.updateProfile persistence, and impact stats derived from coin transaction history.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Extend User model + MockData + UserNotifier.updateProfile + provider tests | 9368967 | user.dart, mock_data.dart, user_notifier.dart, user_notifier_test.dart |
| 2 | Wave 0 — profile widget-test stubs (PROF-01, PROF-03) | 04f6f44 | profile_screen_test.dart (new) |
| 3 | Build ProfileScreen and un-skip PROF tests | 6fc051e | profile_screen.dart, profile_screen_test.dart |

## What Was Built

**User model extension (PROF-02):**
- Added `vehicleModel: String` (default `''`) and `fuelEfficiency: double` (default `0.0`) to `User` constructor, `fromJson`, `toJson`, `copyWith`
- `fromJson` uses `(json['vehicleModel'] as String?) ?? ''` and `(json['fuelEfficiency'] as num?)?.toDouble() ?? 0.0` for migration safety (Pitfall 3)
- `MockData.user` updated with `vehicleModel: 'Fiat Uno'` and `fuelEfficiency: 12.0`

**UserNotifier.updateProfile (PROF-02):**
- Named-parameter method: `name`, `email`, `address`, `vehicleModel`, `fuelEfficiency`
- Guards on null state, uses `copyWith` + `_persist` (same pattern as `spendCoins`)

**ProfileScreen (PROF-01, PROF-02, PROF-03):**
- `ConsumerStatefulWidget` with 5 `TextEditingController`s initialized in `initState` via `ref.read(userNotifierProvider)`
- Vehicle fields fall back to `MockData.vehicle.model` / `MockData.vehicle.fuelEfficiencyKmPerLiter` when user fields are empty/zero
- `CustomScrollView` with pinned `SliverAppBar` (expandedHeight 160): `CircleAvatar` with user initials, name, email
- 3 glassmorphic sections: `Dados Pessoais` (name/email/address), `Veículo` (model/efficiency), `Impacto Social` (3 stat chips)
- Impact stats: `scannedCount` derived from `ref.watch(coinProvider).transactions.where(AppStrings.scanReceiptDescription)`, `47` buscas and `R$ 342` economia mocked
- Save button calls `updateProfile()` then `ScaffoldMessenger.showSnackBar('Perfil atualizado!')` with `AppColors.primary`
- All color uses via `withValues(alpha:)` — no `withOpacity()`

**Tests:**
- 4 new provider tests in `user_notifier_test.dart`: updateProfile updates fields, persists, no-op on null, legacy JSON migration
- 2 widget tests in `profile_screen_test.dart`: PROF-01 (field labels pre-filled), PROF-03 (scan count + mocked stats)
- Full suite: 102 tests passing (up from 96)

## Deviations from Plan

**1. [Rule 1 - Bug] Missing User import in user_notifier_test.dart**
- **Found during:** Task 1 — test compilation
- **Issue:** `User.fromJson` call in legacy JSON test produced `Undefined name 'User'` because the test file only imported `lista_smart/core/providers/user_notifier.dart`
- **Fix:** Added `import 'package:lista_smart/features/auth/domain/user.dart'`
- **Files modified:** test/providers/user_notifier_test.dart
- **Commit:** 9368967 (same commit — inline fix)

## Threat Surface Scan

No new network endpoints, auth paths, or trust boundary changes introduced. All data remains local. T-05-04 mitigated via `double.tryParse() ?? 0.0` on save. T-05-05 mitigated via nullable casts in `User.fromJson`.

## Known Stubs

None — all impact stats are documented as intentionally mocked (D-09 from CONTEXT.md). `scannedCount` is derived from real data. The `47` and `R$ 342` values are design-time constants, not stubs blocking the plan's goal.

## Self-Check: PASSED

- [x] lib/features/profile/presentation/profile_screen.dart exists
- [x] lib/features/auth/domain/user.dart contains vehicleModel + fuelEfficiency
- [x] lib/core/providers/user_notifier.dart contains updateProfile
- [x] test/features/profile/profile_screen_test.dart exists
- [x] Commits 9368967, 04f6f44, 6fc051e verified in git log
- [x] flutter analyze lib/features/profile/presentation/profile_screen.dart — 0 issues
- [x] flutter test — 102 tests passing, 0 skipped
- [x] No withOpacity in profile_screen.dart
- [x] No skip:true in profile_screen_test.dart
