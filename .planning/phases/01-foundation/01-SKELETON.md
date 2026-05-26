---
phase: 01-foundation
skeleton_version: 1
created: 2026-05-25
status: draft
---

# Walking Skeleton — Lista Smart

## What This Skeleton Defines

The Walking Skeleton for Lista Smart is the thinnest possible end-to-end Flutter app that compiles, runs on Android/iOS, and demonstrates every structural layer the subsequent phases will build on. No feature logic is implemented. Every architectural decision recorded here is final — later phases build on top of this structure without renegotiating it.

---

## The Thinnest Slice

After Phase 1 completes, a real user can:

1. Launch the app on Android or iOS.
2. See the app background (`#09090B`) and Inter typography rendered correctly.
3. See a login placeholder screen (not gated yet — auth guard is Phase 2).
4. Navigate between 5 tabs via the bottom navigation bar.
5. See each tab's placeholder screen with the correct tab name.
6. Switch tabs and switch back — the previous tab's scroll state is preserved (demonstrated by a scrollable list in the Home placeholder).
7. Write a string to SharedPreferences and read it back via the provider.

That is all. There is no real feature logic.

---

## Architectural Decisions (Non-Negotiable from Phase 2 Onward)

### Framework
- **Flutter** (cross-platform, Android + iOS only — no web, no desktop)
- **Dart SDK:** `>=3.2.0 <4.0.0` (resolves to 3.11.5 on dev machine)

### State Management
- **flutter_riverpod `^2.5.1`** (resolves to 2.6.x)
- Provider types: `Provider<T>` for read-only, `NotifierProvider` for sync mutable state, `AsyncNotifierProvider` for async state
- `StateNotifierProvider` is forbidden — deprecated in 2.x

### Routing
- **go_router `^14.0.0`** (resolves to 14.8.x)
- Router is a **Riverpod `Provider<GoRouter>`** — never instantiated inside a widget `build()` method
- Tab navigation: **`StatefulShellRoute.indexedStack`** with 5 `StatefulShellBranch` entries (one per tab)
- Auth guard: **`RouterNotifier`** implements `Listenable`; wired to `GoRouter.refreshListenable`
- `ShellRoute` (without `Stateful`) is forbidden for tab navigation — it loses tab state

### Persistence
- **shared_preferences `^2.2.0`** (resolves to 2.5.x)
- Initialized via `await SharedPreferences.getInstance()` **before** `runApp()` in `main()`
- Injected via `ProviderScope.overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]`
- The sentinel provider throws `UnimplementedError` if accidentally accessed without override

### Design System
- Dark mode only (no toggle — fixed by course requirement)
- Background: `Color(0xFF09090B)`
- Primary (verde-limão): `Color(0xFFA3E615)`
- Surface: `Color(0xFF18181B)`
- Surface Elevated: `Color(0xFF27272A)`
- Success: `Color(0xFF22C55E)`
- Error: `Color(0xFFEF4444)`
- Text Main: `Color(0xFFFAFAFA)`
- Text Secondary: `Color(0xFFA1A1AA)`
- Typography: **google_fonts `^6.1.0`** → Inter, applied via `GoogleFonts.interTextTheme(base)` at `ThemeData.textTheme` — never per-widget
- `GoogleFonts.config.allowRuntimeFetching = false` set before `runApp()` — fonts bundled as `.ttf` assets
- `surfaceTintColor: Colors.transparent` on `CardTheme` and `AppBarTheme` to suppress Material3 elevation tint

### Icons
- **lucide_icons `^0.257.0`** — this is the only published version; `^3.0.0` does not exist on pub.dev

### Internationalisation
- **intl `^0.19.0`** for BRL currency and `pt_BR` date formatting
- `Intl.defaultLocale = 'pt_BR'` set in `main()` before `runApp()`

---

## Directory Layout

```
lista_smart/
├── pubspec.yaml
├── assets/
│   └── fonts/
│       ├── Inter-Regular.ttf
│       ├── Inter-Medium.ttf
│       ├── Inter-SemiBold.ttf
│       └── Inter-Bold.ttf
├── lib/
│   ├── main.dart                            # async bootstrap
│   ├── app.dart                             # ConsumerWidget → MaterialApp.router
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_colors.dart              # AppColors — static const Color fields
│   │   │   └── app_sizes.dart               # spacing/radius tokens
│   │   ├── theme/
│   │   │   ├── app_theme.dart               # ThemeData (dark, fromSeed with brightness inside)
│   │   │   └── app_text_theme.dart          # GoogleFonts.interTextTheme
│   │   └── persistence/
│   │       └── shared_preferences_provider.dart  # sentinel Provider<SharedPreferences>
│   ├── routing/
│   │   ├── app_router.dart                  # goRouterProvider = Provider<GoRouter>
│   │   ├── app_routes.dart                  # AppRoutes string constants
│   │   └── router_notifier.dart             # RouterNotifier (AutoDisposeAsyncNotifier + Listenable)
│   └── features/
│       ├── auth/
│       │   ├── domain/user.dart             # User model
│       │   └── presentation/login_screen.dart
│       ├── home/
│       │   ├── domain/                      # (empty — Product model lives in products/)
│       │   └── presentation/home_screen.dart
│       ├── shopping_list/
│       │   ├── domain/cart_item.dart        # CartItem model
│       │   └── presentation/shopping_list_screen.dart
│       ├── price_comparison/
│       │   └── presentation/price_comparison_screen.dart
│       ├── smart_coins/
│       │   ├── domain/coin_transaction.dart # CoinTransaction model
│       │   └── presentation/store_screen.dart
│       ├── price_registration/
│       │   └── presentation/price_registration_screen.dart
│       └── profile/
│           ├── domain/
│           │   ├── vehicle.dart             # Vehicle model
│           │   └── product.dart             # Product model (shared)
│           └── presentation/profile_screen.dart
└── test/
    ├── models/
    │   └── models_test.dart                 # FOUN-04 round-trip tests
    └── repositories/
        └── shared_prefs_test.dart           # FOUN-05 provider injection test
```

---

## Bootstrap Sequence

```
main() async
  │
  ├── WidgetsFlutterBinding.ensureInitialized()
  ├── GoogleFonts.config.allowRuntimeFetching = false
  ├── Intl.defaultLocale = 'pt_BR'
  ├── prefs = await SharedPreferences.getInstance()
  │
  └── runApp(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]
          child: App()  ← ConsumerWidget
        )
      )
            │
            └── MaterialApp.router(routerConfig: ref.watch(goRouterProvider))
                  │
                  └── GoRouter
                        ├── refreshListenable: RouterNotifier
                        ├── redirect: RouterNotifier.redirect  (Phase 1: always null)
                        └── routes:
                              ├── /login  → LoginScreen (placeholder)
                              └── StatefulShellRoute.indexedStack
                                    builder: ScaffoldWithBottomNav(navigationShell)
                                    branches:
                                      [0] /home           → HomeScreen
                                      [1] /shopping-list  → ShoppingListScreen
                                      [2] /comparison     → PriceComparisonScreen
                                      [3] /store          → StoreScreen
                                      [4] /profile        → ProfileScreen
```

---

## Real Read/Write Demonstrated

**SharedPreferences write/read** is exercised in `test/repositories/shared_prefs_test.dart`:

```dart
// The test overrides sharedPreferencesProvider with a mock instance and
// verifies that the provider returns the same instance injected at startup.
// This proves the ProviderScope.overrides pattern works end-to-end.
```

---

## Real UI Interaction Demonstrated

**Tab switching with state preservation** is demonstrated by `HomeScreen` containing a `ListView` with enough items to scroll. The test at `test/routing/navigation_shell_test.dart` (optional but recommended for FOUN-03) pumps the `ScaffoldWithBottomNav` widget and verifies that:
1. All 5 `BottomNavigationBarItem` labels are present in the widget tree.
2. Tapping tab index 1 changes `currentIndex` to 1.

---

## Constraints on Future Phases

| Constraint | Enforced By | Consequence if Violated |
|---|---|---|
| GoRouter as Provider, never in build() | CLAUDE.md + plan pitfall list | "Multiple widgets used the same GlobalKey" crash |
| `StatefulShellRoute.indexedStack` for tabs | Plan + skeleton | Scroll state lost on every tab switch |
| `brightness:` inside `fromSeed()` only | Plan + skeleton | Assertion crash in debug builds on startup |
| `NotifierProvider` / `AsyncNotifierProvider` only | CLAUDE.md | Compile error after Riverpod 3.x; subtle bugs in 2.x |
| `sharedPreferencesProvider` always overridden before runApp | Plan + skeleton | `UnimplementedError` on first provider read |
| `lucide_icons: ^0.257.0` (never ^3.0.0) | Plan + skeleton | `flutter pub get` version-solving failure |
| Inter font served from bundled .ttf only | Plan + skeleton | FOIT on cold start; fails offline |

---

## What is NOT in the Skeleton

These items belong to later phases and must not appear in Phase 1 deliverables:

- Real auth logic (Phase 2)
- RouterNotifier redirect guard active (Phase 2 — Phase 1 installs the notifier but `redirect()` always returns `null`)
- Any product/cart/coin data (Phase 3–5)
- Actual UI design for any screen (Phase 3–5)
- SharedPreferences persistence of cart/favorites (Phase 3)
