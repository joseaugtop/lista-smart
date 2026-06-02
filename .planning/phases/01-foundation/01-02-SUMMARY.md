---
phase: 01-foundation
plan: 02
subsystem: routing
tags: [flutter, dart, go_router, riverpod, navigation, walking-skeleton]
dependency_graph:
  requires:
    - 01-01 (appTheme, AppColors, sharedPreferencesProvider, domain models)
  provides:
    - main.dart async bootstrap with ProviderScope overrides
    - App ConsumerWidget root (MaterialApp.router)
    - goRouterProvider (Provider<GoRouter> with StatefulShellRoute.indexedStack)
    - RouterNotifier (AutoDisposeAsyncNotifier<void> implements Listenable)
    - AppRoutes string constants (6 routes)
    - 6 placeholder screens (login + 5 tabs)
  affects:
    - All subsequent phases (routing layer is consumed by every feature)
    - Phase 02 Plan 01 (auth notifier will be wired into RouterNotifier.redirect)
tech_stack:
  added: []
  patterns:
    - Provider<GoRouter> declared at top-level (not inside widget build)
    - StatefulShellRoute.indexedStack with 5 branches (preserves scroll/state per tab)
    - RouterNotifier.listenSelf() called directly on Notifier (avoids deprecated ref.listenSelf)
    - GlobalKey<NavigatorState> declared as top-level constants (prevents Multiple GlobalKey crash)
    - NavigationBar (Material 3) with AppColors.background and primary indicator tint
    - main.dart async bootstrap: GoogleFonts + Intl + SharedPreferences before runApp
key_files:
  created:
    - lib/main.dart
    - lib/app.dart
    - lib/routing/app_routes.dart
    - lib/routing/router_notifier.dart
    - lib/routing/app_router.dart
    - lib/features/auth/presentation/login_screen.dart
    - lib/features/home/presentation/home_screen.dart
    - lib/features/shopping_list/presentation/shopping_list_screen.dart
    - lib/features/price_comparison/presentation/price_comparison_screen.dart
    - lib/features/smart_coins/presentation/store_screen.dart
    - lib/features/price_registration/presentation/price_registration_screen.dart
    - lib/features/profile/presentation/profile_screen.dart
  modified: []
decisions:
  - RouterNotifier.listenSelf() called directly (self method on Notifier) instead of ref.listenSelf (deprecated in Riverpod 2.6.x)
  - PriceRegistrationScreen created but not wired into GoRouter branches — it is a modal/flow added in Phase 2, not a bottom nav tab
  - NavigationBar (Material 3) used instead of BottomNavigationBar for visual consistency with dark theme
  - All 5 lucide icon names verified in pub cache (home, shoppingCart, barChart2, store, user — all exist in 0.257.0)
metrics:
  duration_minutes: 5
  completed: 2026-06-01
  tasks_completed: 3
  tasks_total: 3
  checkpoint_pending: false
  files_created: 12
  tests_passing: 9
  tests_total: 9
---

# Phase 01 Plan 02: Navigation Shell + Bootstrap Summary

GoRouter as Riverpod Provider with StatefulShellRoute.indexedStack wired to async SharedPreferences bootstrap — walking skeleton is architecturally complete pending device verification.

**Status: COMPLETE — All 3 tasks done. Human verified on Motorola Edge 50 Fusion (Android). Fix: initialLocation changed from /login to /home (no auth guard in Phase 1).**

## What Was Built

### Task 1: Routing layer — commit 876f6d8

- **lib/routing/app_routes.dart** — AppRoutes abstract class with 6 static const String routes
- **lib/routing/router_notifier.dart** — RouterNotifier extends AutoDisposeAsyncNotifier<void> implements Listenable; `redirect()` returns null unconditionally (Phase 1 — no auth guard); `listenSelf()` called directly on the Notifier instance (avoids deprecated `ref.listenSelf`)
- **lib/routing/app_router.dart** — `goRouterProvider = Provider<GoRouter>` with `StatefulShellRoute.indexedStack`, 5 branches, 6 GlobalKey<NavigatorState> as top-level constants; `ScaffoldWithBottomNav` widget with NavigationBar (Material 3); `refreshListenable: notifier` + `redirect: notifier.redirect`
- **6 placeholder screens** — LoginScreen, HomeScreen (CustomScrollView + SliverList 30 items for scroll preservation test), ShoppingListScreen, PriceComparisonScreen, StoreScreen, PriceRegistrationScreen (modal, not wired to nav), ProfileScreen
- Icon names verified in pub cache: `LucideIcons.home`, `LucideIcons.shoppingCart`, `LucideIcons.barChart2`, `LucideIcons.store`, `LucideIcons.user` — all confirmed present in lucide_icons-0.257.0

### Task 2: main.dart + app.dart bootstrap — commit ffa715a

- **lib/main.dart** — async bootstrap: `WidgetsFlutterBinding.ensureInitialized()` → `GoogleFonts.config.allowRuntimeFetching = false` → `Intl.defaultLocale = 'pt_BR'` → `await SharedPreferences.getInstance()` → `runApp(ProviderScope(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]))`
- **lib/app.dart** — `App extends ConsumerWidget`; `ref.watch(goRouterProvider)` in `build()`; `MaterialApp.router(theme: appTheme, routerConfig: router, debugShowCheckedModeBanner: false)` — no `darkTheme:` or `themeMode:` (theme is already dark)

## Verification Results

| Check | Result |
|-------|--------|
| `flutter analyze lib/routing/ lib/features/` | No issues found |
| `flutter analyze lib/main.dart lib/app.dart` | No issues found |
| `flutter analyze lib/` | No issues found |
| `flutter test test/` (via P:\ subst drive) | 9/9 passed |
| `StatefulShellRoute.indexedStack` in app_router.dart | Confirmed (line 46) |
| `implements Listenable` in router_notifier.dart | Confirmed |
| `AutoDisposeAsyncNotifier` in router_notifier.dart | Confirmed |
| `redirect returns null` in router_notifier.dart | Confirmed |
| `CustomScrollView` + `SliverList` in home_screen.dart | Confirmed |
| `sharedPreferencesProvider.overrideWithValue` in main.dart | Confirmed |
| No `darkTheme:` / `themeMode:` in app.dart | Confirmed |
| All 5 lucide icon names verified | home, shoppingCart, barChart2, store, user |

### Task 3: COMPLETE — checkpoint:human-verify approved

- Platform: Motorola Edge 50 Fusion (Android, physical device)
- App launched: dark background #09090B confirmed
- Fix applied during verification: `initialLocation` changed from `AppRoutes.login` to `AppRoutes.home` — executor had set login as initial location but Phase 1 has no auth guard, so app was stuck on LoginScreen without bottom nav
- Fix commit: 58c576d
- Human approved after fix

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Removed deprecated ref.listenSelf in favor of Notifier.listenSelf**
- **Found during:** Task 1 — `flutter analyze` reported `deprecated_member_use` on `ref.listenSelf`
- **Issue:** `Ref.listenSelf` is deprecated in Riverpod 2.6.x with message "Will be removed in 3.0. Use Notifier.listenSelf instead"
- **Fix:** Changed `ref.listenSelf((_, __) => ...)` to `listenSelf((_, __) => ...)` — calling the method directly on the AutoDisposeAsyncNotifier instance
- **Files modified:** `lib/routing/router_notifier.dart`
- **Commit:** 876f6d8

**2. [Rule 1 - Bug] Removed unused import for PriceRegistrationScreen from app_router.dart**
- **Found during:** Task 1 — `flutter analyze` reported `unused_import`
- **Issue:** Plan listed `price_registration_screen.dart` in app_router.dart imports but the screen is not a bottom nav branch — it is a modal/flow added in Phase 2
- **Fix:** Replaced import with a comment explaining deferred wiring
- **Files modified:** `lib/routing/app_router.dart`
- **Commit:** 876f6d8

**3. [Rule 1 - Bug] Removed redundant foundation.dart import from router_notifier.dart**
- **Found during:** Task 1 — `flutter analyze` reported `unnecessary_import` (all used elements also provided by material.dart)
- **Fix:** Removed `import 'package:flutter/foundation.dart'`; VoidCallback is available via material.dart
- **Files modified:** `lib/routing/router_notifier.dart`
- **Commit:** 876f6d8

## Known Stubs

| Stub | File | Reason |
|------|------|--------|
| 5 placeholder screens show only text | login, shopping_list, price_comparison, store, profile screens | Phase 1 walking skeleton — full UI wired in Phase 2+ |
| PriceRegistrationScreen not wired to GoRouter | lib/features/price_registration/presentation/price_registration_screen.dart | This is a modal/flow, not a nav tab — Phase 2 will add the route |
| Placeholder Inter TTF files (12 bytes each) | assets/fonts/Inter-*.ttf | Inherited from Plan 01 — developer must replace with real Inter static font files |

## Threat Surface Scan

No new network endpoints, auth paths, or schema changes introduced in Plan 02. All routing is local/declarative. RouterNotifier.redirect returns null unconditionally — intentional per T-02-01 (accepted, Phase 1).

## Self-Check: PASSED

| Item | Status |
|------|--------|
| lib/main.dart | FOUND |
| lib/app.dart | FOUND |
| lib/routing/app_routes.dart | FOUND |
| lib/routing/router_notifier.dart | FOUND |
| lib/routing/app_router.dart | FOUND |
| lib/features/auth/presentation/login_screen.dart | FOUND |
| lib/features/home/presentation/home_screen.dart | FOUND |
| lib/features/shopping_list/presentation/shopping_list_screen.dart | FOUND |
| lib/features/price_comparison/presentation/price_comparison_screen.dart | FOUND |
| lib/features/smart_coins/presentation/store_screen.dart | FOUND |
| lib/features/price_registration/presentation/price_registration_screen.dart | FOUND |
| lib/features/profile/presentation/profile_screen.dart | FOUND |
| commit 876f6d8 | FOUND |
| commit ffa715a | FOUND |
