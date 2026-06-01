---
phase: 01-foundation
plan: 01
subsystem: core
tags: [flutter, dart, design-system, domain-models, riverpod, shared-preferences, tdd]
dependency_graph:
  requires: []
  provides:
    - pubspec.yaml with all 6 packages resolved
    - AppColors (8 design-system color tokens)
    - AppSizes (spacing + radius tokens)
    - appTextTheme (GoogleFonts.interTextTheme)
    - appTheme (dark ThemeData without brightness crash)
    - sharedPreferencesProvider (sentinel)
    - User, Vehicle, Product, CartItem, CoinTransaction (domain models)
  affects:
    - Phase 01 Plan 02 (navigation shell imports appTheme, goRouterProvider needs sharedPreferencesProvider)
    - All subsequent phases (domain models are data contracts consumed by every feature)
tech_stack:
  added:
    - flutter_riverpod 2.6.1 (^2.5.1)
    - go_router 14.8.1 (^14.0.0)
    - shared_preferences 2.5.5 (^2.2.0)
    - lucide_icons 0.257.0 (^0.257.0)
    - google_fonts 6.3.3 (^6.1.0)
    - intl 0.19.0 (^0.19.0)
  patterns:
    - TDD (RED/GREEN) for domain models and provider tests
    - ColorScheme.fromSeed with brightness inside fromSeed (avoids assertion crash)
    - GoogleFonts.interTextTheme at ThemeData level (not per-widget)
    - Pure-Dart domain models with @immutable + toJson/fromJson/copyWith
    - Sentinel Provider<SharedPreferences> overridden in main() via ProviderScope
key_files:
  created:
    - pubspec.yaml
    - pubspec.lock
    - assets/fonts/Inter-Regular.ttf (placeholder — needs real font)
    - assets/fonts/Inter-Medium.ttf (placeholder — needs real font)
    - assets/fonts/Inter-SemiBold.ttf (placeholder — needs real font)
    - assets/fonts/Inter-Bold.ttf (placeholder — needs real font)
    - lib/core/constants/app_colors.dart
    - lib/core/constants/app_sizes.dart
    - lib/core/theme/app_text_theme.dart
    - lib/core/theme/app_theme.dart
    - lib/core/persistence/shared_preferences_provider.dart
    - lib/features/auth/domain/user.dart
    - lib/features/profile/domain/vehicle.dart
    - lib/features/profile/domain/product.dart
    - lib/features/shopping_list/domain/cart_item.dart
    - lib/features/smart_coins/domain/coin_transaction.dart
    - test/models/models_test.dart
    - test/repositories/shared_prefs_test.dart
    - .gitignore
  modified: []
decisions:
  - lucide_icons pinned to ^0.257.0 (^3.0.0 does not exist on pub.dev)
  - CardTheme changed to CardThemeData (Flutter 3.41.9 API change — auto-fixed)
  - Inter fonts are placeholder stubs (12-byte TTF stub); developer must replace with real Inter .ttf files from Google Fonts before running on device
  - Tests run via PowerShell from P: subst drive to work around Windows path-with-spaces bug in Flutter native assets hook
metrics:
  duration_minutes: 15
  completed: 2026-06-01
  tasks_completed: 2
  files_created: 19
  tests_passing: 9
  tests_total: 9
---

# Phase 01 Plan 01: pubspec + design system + domain models Summary

Foundation layer established: pubspec resolves, dark design system compiles, all 5 domain models pass round-trip serialization tests, SharedPreferences sentinel provider with UnimplementedError guard.

## What Was Built

### Task 1: pubspec.yaml + design system constants + theme

- **pubspec.yaml** with all 6 packages at correct versions: `lucide_icons 0.257.0`, `flutter_riverpod 2.6.1`, `go_router 14.8.1`, `google_fonts 6.3.3`, `shared_preferences 2.5.5`, `intl 0.19.0`
- **AppColors** — 8 static const Color fields: background `#09090B`, primary `#A3E615`, surface `#18181B`, surfaceElevated `#27272A`, success `#22C55E`, error `#EF4444`, textMain `#FAFAFA`, textSecondary `#A1A1AA`
- **AppSizes** — spacing tokens (XS=4, S=8, M=16, L=24, XL=32) and radius tokens (S=8, M=12, L=16, XL=24)
- **appTextTheme** — `GoogleFonts.interTextTheme(ThemeData(brightness: Brightness.dark).textTheme)`
- **appTheme** — dark ThemeData with `brightness: Brightness.dark` inside `ColorScheme.fromSeed()`, `surfaceTintColor: Colors.transparent` on both CardThemeData and AppBarTheme, `scaffoldBackgroundColor: AppColors.background`
- **Inter font placeholder stubs** — 12-byte binary TTF placeholders; developer must replace with real Inter static font files

### Task 2: Domain models + SharedPreferences sentinel + unit tests (TDD)

RED -> GREEN TDD cycle:
- **9 unit tests** written first (RED), all passed after implementation (GREEN)
- **sharedPreferencesProvider** — `Provider<SharedPreferences>` that throws `UnimplementedError` without override
- **User** — id, name, email, address (default ''), coinBalance (default 0)
- **Vehicle** — id, model, fuelEfficiencyKmPerLiter (double)
- **Product** — id, name, brand, category, imageUrl, averagePrice, tags (List<String>)
- **CartItem** — flat model: productId, productName, brand, imageUrl, quantity, unitPrice (no Product reference — intentional decoupling)
- **CoinTransaction** — id, description, amount (int, positive=gain/negative=redemption), createdAt (DateTime serialized as ISO 8601)

## Verification Results

| Check | Result |
|-------|--------|
| `flutter pub get` | Exit 0 — 68 dependencies resolved |
| `lucide_icons` in pubspec.lock | 0.257.0 (correct) |
| `flutter analyze lib/core/` | No issues found |
| `flutter analyze lib/features/ lib/core/persistence/` | No issues found |
| `flutter analyze lib/` | No issues found |
| `flutter test test/models/` | 7/7 passed |
| `flutter test test/repositories/` | 2/2 passed |
| Total tests | 9/9 passed |
| `brightness: Brightness.dark` placement | Inside `fromSeed()` — correct |
| `surfaceTintColor: Colors.transparent` count | 2 (CardThemeData + AppBarTheme) |
| No `material.dart` imports in domain models | Confirmed — only `foundation.dart` |
| `intl` dependency_overrides needed | No — intl 0.19.0 resolved without conflict |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] CardTheme -> CardThemeData API change in Flutter 3.41.9**
- **Found during:** Task 1 — `flutter analyze lib/core/` showed `argument_type_not_assignable`
- **Issue:** Plan referenced `CardTheme(...)` but Flutter 3.41.9 requires `CardThemeData(...)` for the `ThemeData.cardTheme` parameter type
- **Fix:** Changed `const CardTheme(...)` to `const CardThemeData(...)` in `lib/core/theme/app_theme.dart`
- **Files modified:** `lib/core/theme/app_theme.dart`
- **Commit:** 78c15e9

**2. [Rule 3 - Blocking Issue] Windows path-with-spaces breaks flutter test native assets hook**
- **Found during:** Task 2 — `flutter test` failed with "Building native assets for package:objective_c failed" because the Dart SDK is at `C:\Users\Jose Augusto\flutter\...` (unquoted path passed to cmd.exe subprocess)
- **Issue:** Flutter 3.41.9 native assets hook for `objective_c` (transitive via `path_provider_foundation`) invokes `dart compile kernel` without quoting the SDK path; Windows treats the space in "Jose Augusto" as argument separator
- **Fix:** Created `C:\flutter` junction pointing to `C:\Users\Jose Augusto\flutter` via `New-Item -ItemType Junction`; ran tests via PowerShell script from a `subst P:` virtual drive to eliminate spaces in cwd. Helper scripts excluded from git via .gitignore.
- **Commits:** 78c15e9, 2f7cef1

**3. [Rule 2 - Missing critical] Inter font files are placeholder stubs**
- **Found during:** Task 1 — downloading Inter .ttf from Google Fonts was not possible in the execution environment
- **Issue:** Real TTF files required for correct Inter font rendering; placeholder 12-byte stubs cause fonts to fall back to system font at runtime
- **Action required:** Developer must replace `assets/fonts/Inter-*.ttf` with real Inter static font files from https://fonts.google.com/specimen/Inter (static subset: Regular/400, Medium/500, SemiBold/600, Bold/700)

## Known Stubs

| Stub | File | Reason |
|------|------|--------|
| Placeholder Inter TTF files (12 bytes each) | `assets/fonts/Inter-Regular.ttf`, `assets/fonts/Inter-Medium.ttf`, `assets/fonts/Inter-SemiBold.ttf`, `assets/fonts/Inter-Bold.ttf` | Network download unavailable in execution environment; developer must replace with real Inter static font files before running on device |

## TDD Gate Compliance

- RED gate: `test(01-01)` commit `b7313ba` — 9 failing tests written before implementation
- GREEN gate: `feat(01-01)` commit `fa4c43e` — all 9 tests pass after implementation

## Self-Check: PASSED

All created files verified to exist on disk. All 4 commits verified in git log.

| Item | Status |
|------|--------|
| pubspec.yaml | FOUND |
| pubspec.lock | FOUND |
| lib/core/constants/app_colors.dart | FOUND |
| lib/core/constants/app_sizes.dart | FOUND |
| lib/core/theme/app_text_theme.dart | FOUND |
| lib/core/theme/app_theme.dart | FOUND |
| lib/core/persistence/shared_preferences_provider.dart | FOUND |
| lib/features/auth/domain/user.dart | FOUND |
| lib/features/profile/domain/vehicle.dart | FOUND |
| lib/features/profile/domain/product.dart | FOUND |
| lib/features/shopping_list/domain/cart_item.dart | FOUND |
| lib/features/smart_coins/domain/coin_transaction.dart | FOUND |
| test/models/models_test.dart | FOUND |
| test/repositories/shared_prefs_test.dart | FOUND |
| .gitignore | FOUND |
| commit 78c15e9 | FOUND |
| commit b7313ba | FOUND |
| commit fa4c43e | FOUND |
| commit 2f7cef1 | FOUND |
