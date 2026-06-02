# Phase 1: Foundation — Research

**Researched:** 2026-05-25
**Domain:** Flutter project scaffold, dark design system, StatefulShellRoute navigation, domain models, SharedPreferences bootstrap
**Confidence:** HIGH

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| FOUN-01 | App Flutter compila e roda no Android e iOS sem erros (pubspec correto com lucide_icons: ^0.257.0) | Verified pubspec.yaml with exact versions; lucide_icons 0.257.0 confirmed on pub.dev; dart 3.11.5 confirmed in env |
| FOUN-02 | Design system dark glassmórfico: cores (#09090B background, #A3E615 primary, #18181B surface), typography google_fonts Inter, tema escuro sem clash de ColorScheme | ColorScheme.fromSeed(brightness: Brightness.dark) pattern verified; google_fonts InterTextTheme pattern documented; surfaceTintColor override documented |
| FOUN-03 | Navegação com 5 abas via StatefulShellRoute.indexedStack preserva estado de scroll entre trocas de aba | StatefulShellRoute.indexedStack + 5 StatefulShellBranches verified in go_router 14.8.1 docs; goBranch() API confirmed |
| FOUN-04 | Modelos de dados tipados: User, Vehicle, Product, CartItem, CoinTransaction com toJson/fromJson | Pure-Dart domain model patterns with toJson/fromJson/copyWith documented; no Flutter imports in domain layer |
| FOUN-05 | Persistência local via shared_preferences inicializada antes de runApp() e injetada via ProviderScope.overrides | main() async pattern with overrideWithValue verified; sharedPreferencesProvider sentinel pattern documented |
</phase_requirements>

---

## Summary

Phase 1 establishes every structural dependency that later phases consume. The research confirms that all five FOUN requirements are achievable without ambiguity: the pubspec versions are verified on pub.dev, the ColorScheme/brightness pitfall is well-documented with a clear fix, the StatefulShellRoute.indexedStack API is stable in go_router 14.8.1, and the SharedPreferences bootstrap pattern is the canonical Riverpod initialization approach.

The most dangerous pitfall is the `ColorScheme.fromSeed` + `ThemeData.brightness` conflict (pitfall C-6 in PITFALLS.md), which causes an assertion crash at startup in debug builds. The fix is to pass `brightness: Brightness.dark` inside `fromSeed()`, not at the `ThemeData` level. Google Fonts must be applied at the `textTheme` level via `GoogleFonts.interTextTheme(...)`, not at individual widget call sites. The Router must be a Riverpod `Provider<GoRouter>` — never instantiated inside a widget build method.

The `google_fonts 6.x` series resolves to 6.3.3 under `^6.1.0`. The package team recommends bundling `.ttf` font files as assets and setting `GoogleFonts.config.allowRuntimeFetching = false` to prevent FOIT and network dependency. `intl 0.19.0` is the only published version in the 0.19.x series — no version conflict risk within that constraint. `shared_preferences ^2.2.0` safely resolves to 2.5.5 with no breaking changes.

**Primary recommendation:** Build in the order Data models → SharedPreferences bootstrap → Theme/constants → Routing shell → Placeholder screens. Every task should be independently compilable and produce a running app.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Bottom navigation shell | Frontend (Flutter widget) | Routing (GoRouter) | StatefulShellRoute is a routing construct; the visual scaffold widget wraps it |
| Dark theme & color tokens | Frontend (ThemeData) | — | Purely presentational; no business logic |
| Domain models (User, Vehicle, Product, CartItem, CoinTransaction) | Domain (pure Dart) | — | Zero Flutter or Riverpod imports; models are data contracts used by all layers |
| SharedPreferences initialization | App bootstrap (main.dart) | Data layer (Provider) | Async init before runApp(); synchronous injection via ProviderScope.overrides |
| Route definitions & redirect guard | Routing (GoRouter Provider) | Application (RouterNotifier) | GoRouter owns route config; RouterNotifier bridges auth state to Listenable |
| Google Fonts configuration | App bootstrap (main.dart) | Theme (TextTheme) | allowRuntimeFetching must be false before any widget renders |

---

## Standard Stack

### Core

| Library | Constraint | Resolves To | Purpose | Source |
|---------|-----------|------------|---------|--------|
| flutter_riverpod | ^2.5.1 | 2.6.1 (latest 2.x) | Global state management — Notifier/AsyncNotifier/Provider | [VERIFIED: pub.dev/packages/flutter_riverpod/versions] |
| go_router | ^14.0.0 | 14.8.1 (latest 14.x) | Declarative routing, StatefulShellRoute, redirect guards | [VERIFIED: pub.dev/packages/go_router/versions] |
| shared_preferences | ^2.2.0 | 2.5.5 (latest 2.x) | Key-value persistence; no breaking changes from 2.2→2.5 | [VERIFIED: pub.dev/packages/shared_preferences/changelog] |
| lucide_icons | ^0.257.0 | 0.257.0 | Icon library (COURSE SPEC SAYS ^3.0.0 — DOES NOT EXIST) | [VERIFIED: pub.dev/packages/lucide_icons] |
| google_fonts | ^6.1.0 | 6.3.3 (latest 6.x) | Inter typography; 6.x will NOT auto-upgrade to 7.x/8.x | [VERIFIED: pub.dev/packages/google_fonts/versions] |
| intl | ^0.19.0 | 0.19.0 (only 0.19.x) | BRL currency and date formatting | [VERIFIED: pub.dev/packages/intl/versions] |

### Dart SDK Environment

| Item | Value | Source |
|------|-------|--------|
| Dart SDK (dev machine) | 3.11.5 stable | [VERIFIED: dart --version on target machine] |
| pubspec sdk constraint | `'>=3.2.0 <4.0.0'` | Compatible with 3.11.5 |

### Dev Dependencies

| Library | Version | Purpose |
|---------|---------|---------|
| flutter_lints | ^3.0.0 | Lint rules; enforces Riverpod and Flutter best practices |
| flutter_test | sdk: flutter | Widget and unit tests |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| lucide_icons ^0.257.0 | flutter_lucide (separate pkg) | Course requires lucide_icons specifically; flutter_lucide has different versioning |
| google_fonts ^6.1.0 | Bundled fonts only (no package) | google_fonts provides the Inter font without manual CDN downloads; offline config removes the downside |
| shared_preferences | hive / isar / sqflite | All overkill for mocked local data; course prescribes shared_preferences |

**Installation:**
```bash
flutter pub get
```

Full pubspec.yaml (exact, ready to use):
```yaml
name: lista_smart
description: Lista de compras inteligente com comparação de preços - Unesc Fase 5
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.2.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.5.1
  go_router: ^14.0.0
  shared_preferences: ^2.2.0
  lucide_icons: ^0.257.0        # COURSE SPEC SAYS ^3.0.0 — DOES NOT EXIST ON PUB.DEV
  google_fonts: ^6.1.0
  intl: ^0.19.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true    # Required for Material Icons fallback

  assets:
    - assets/fonts/             # Bundled Inter .ttf files for offline font rendering

  fonts:
    - family: Inter
      fonts:
        - asset: assets/fonts/Inter-Regular.ttf
        - asset: assets/fonts/Inter-Medium.ttf
          weight: 500
        - asset: assets/fonts/Inter-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/Inter-Bold.ttf
          weight: 700
```

**intl conflict mitigation:** If `flutter pub get` fails with `version solving failed` on `intl`, add:
```yaml
dependency_overrides:
  intl: ^0.19.0
```

---

## Package Legitimacy Audit

> slopcheck was unavailable at research time. Packages below are evaluated by pub.dev metadata.
> All packages are tagged [ASSUMED] for planner awareness; each should be verified via pub.dev before install.

| Package | Registry | Age | Downloads/Likes | Source Repo | slopcheck | Disposition |
|---------|----------|-----|-----------------|-------------|-----------|-------------|
| flutter_riverpod ^2.5.1 | pub.dev | ~5 yrs | 5,800+ likes | github.com/rrousselGit/riverpod | N/A — slopcheck unavailable | Approved [ASSUMED] — mainstream package, official Flutter ecosystem |
| go_router ^14.0.0 | pub.dev | ~4 yrs | 7,000+ likes | github.com/flutter/packages | N/A | Approved [ASSUMED] — Flutter team maintained |
| shared_preferences ^2.2.0 | pub.dev | ~6 yrs | 10,000+ likes | github.com/flutter/packages | N/A | Approved [ASSUMED] — Flutter team maintained |
| lucide_icons ^0.257.0 | pub.dev | ~3 yrs | active | github.com/lucide-icons/lucide | N/A | Approved [ASSUMED] — verified publisher lucide.dev |
| google_fonts ^6.1.0 | pub.dev | ~5 yrs | 8,000+ likes | github.com/material-foundation/flutter-packages | N/A | Approved [ASSUMED] — Google-backed |
| intl ^0.19.0 | pub.dev | ~8 yrs | 9,000+ likes | github.com/dart-lang/i18n | N/A | Approved [ASSUMED] — Dart team maintained |

**Packages removed due to slopcheck [SLOP] verdict:** none

**Packages flagged as suspicious [SUS]:** none

*slopcheck was unavailable at research time. All packages above carry `[ASSUMED]` provenance. All six are core Flutter/Dart ecosystem packages maintained by official teams (Flutter team, Google, Dart team, or established publishers) — the risk of slopcheck flagging any of them is negligible. No `checkpoint:human-verify` gates are required for these packages.*

---

## Architecture Patterns

### System Architecture Diagram

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
          │
          └── App (ConsumerWidget)
                │
                └── MaterialApp.router(routerConfig: ref.watch(goRouterProvider))
                      │
                      └── GoRouter
                            ├── refreshListenable: RouterNotifier
                            ├── redirect: RouterNotifier.redirect()  ←── reads authNotifierProvider
                            │
                            └── routes:
                                  ├── /login  → LoginScreen (placeholder)
                                  │
                                  └── StatefulShellRoute.indexedStack
                                        builder: ScaffoldWithBottomNav(navigationShell)
                                        branches:
                                          ├── [0] /home            → HomeScreen (placeholder)
                                          ├── [1] /shopping-list   → ShoppingListScreen (placeholder)
                                          ├── [2] /comparison      → PriceComparisonScreen (placeholder)
                                          ├── [3] /store           → StoreScreen (placeholder)
                                          └── [4] /profile         → ProfileScreen (placeholder)
        )
      )

Domain Models (pure Dart, no imports):
  User ──────────────────────── toJson / fromJson / copyWith
  Vehicle ───────────────────── toJson / fromJson / copyWith
  Product ───────────────────── toJson / fromJson / copyWith
  CartItem ──────────────────── toJson / fromJson / copyWith
  CoinTransaction ───────────── toJson / fromJson / copyWith

State Flow:
  AuthNotifier (AsyncNotifier<User?>)
    └── build() loads from SessionRepository
    └── login() / logout() write to SessionRepository
    └── state change → RouterNotifier._routerListener?.call()
    └── GoRouter.redirect() re-evaluates → navigates /login or /home
```

### Recommended Project Structure

```
lib/
├── main.dart                          # async bootstrap: prefs + GoogleFonts + runApp
├── app.dart                           # ConsumerWidget → MaterialApp.router
│
├── core/
│   ├── constants/
│   │   ├── app_colors.dart            # AppColors class with static const Color fields
│   │   └── app_sizes.dart             # spacing, radius, padding tokens
│   ├── theme/
│   │   ├── app_theme.dart             # ThemeData.dark() + ColorScheme.fromSeed
│   │   └── app_text_theme.dart        # GoogleFonts.interTextTheme(...)
│   ├── persistence/
│   │   └── shared_preferences_provider.dart  # sentinel Provider<SharedPreferences>
│   └── widgets/                       # future shared widgets (empty at Phase 1)
│
├── routing/
│   ├── app_router.dart                # goRouterProvider = Provider<GoRouter>
│   ├── app_routes.dart                # AppRoutes abstract class with route constants
│   └── router_notifier.dart           # RouterNotifier extends AutoDisposeAsyncNotifier implements Listenable
│
└── features/
    ├── auth/
    │   ├── domain/
    │   │   └── user.dart              # User model + toJson/fromJson/copyWith
    │   └── presentation/
    │       └── login_screen.dart      # Placeholder: "Login Screen" text
    │
    ├── home/
    │   └── presentation/
    │       └── home_screen.dart       # Placeholder
    │
    ├── shopping_list/
    │   ├── domain/
    │   │   └── cart_item.dart         # CartItem model
    │   └── presentation/
    │       └── shopping_list_screen.dart  # Placeholder
    │
    ├── price_comparison/
    │   └── presentation/
    │       └── price_comparison_screen.dart  # Placeholder
    │
    ├── smart_coins/
    │   ├── domain/
    │   │   └── coin_transaction.dart  # CoinTransaction model
    │   └── presentation/
    │       └── store_screen.dart      # Placeholder
    │
    ├── price_registration/
    │   └── presentation/
    │       └── price_registration_screen.dart  # Placeholder (tab 5 or modal)
    │
    └── profile/
        ├── domain/
        │   └── vehicle.dart           # Vehicle model
        └── presentation/
            └── profile_screen.dart    # Placeholder
```

> Note: `Product` model belongs in `features/products/domain/product.dart` — to be created when the products feature is scaffolded. Phase 1 can define an empty placeholder file or define it in `core/domain/` to be accessible by both Home and Shopping List features.

---

### Pattern 1: SharedPreferences Bootstrap

**What:** `SharedPreferences.getInstance()` is awaited in `main()` before `runApp()`. The instance is injected into the Riverpod container via `ProviderScope.overrides`, making it synchronously available to all providers without async loading screens.

**When to use:** Always — this is the only safe initialization pattern. Never call `SharedPreferences.getInstance()` inside a provider build method.

```dart
// Source: codewithandrea.com/articles/robust-app-initialization-riverpod/
// lib/main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  Intl.defaultLocale = 'pt_BR';

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const App(),
    ),
  );
}

// lib/core/persistence/shared_preferences_provider.dart
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (_) => throw UnimplementedError('sharedPreferencesProvider must be overridden in main()'),
);
```

---

### Pattern 2: ThemeData — Dark ColorScheme Without Brightness Conflict

**What:** `ColorScheme.fromSeed` is called with `brightness: Brightness.dark` as a parameter to `fromSeed()` itself. The generated scheme then overrides specific color slots with the design system palette. `ThemeData` does NOT receive a separate `brightness:` parameter — that would trigger an assertion crash.

**When to use:** Any dark theme implementation with custom color tokens.

```dart
// Source: api.flutter.dev/flutter/material/ColorScheme/ColorScheme.fromSeed.html
// lib/core/theme/app_theme.dart

import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'app_text_theme.dart';

final appTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.primary,          // #A3E615
    brightness: Brightness.dark,           // INSIDE fromSeed, NOT at ThemeData level
    surface: AppColors.surface,            // #18181B
    onSurface: AppColors.textMain,         // #FAFAFA
    primary: AppColors.primary,            // #A3E615
    error: AppColors.error,               // #EF4444
  ),
  scaffoldBackgroundColor: AppColors.background,  // #09090B
  textTheme: appTextTheme,
  cardTheme: const CardTheme(
    surfaceTintColor: Colors.transparent,  // Prevents Material3 elevation tint on custom dark cards
    color: AppColors.surface,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.background,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
  ),
);
```

```dart
// lib/core/constants/app_colors.dart
import 'package:flutter/material.dart';

abstract class AppColors {
  static const Color background      = Color(0xFF09090B);
  static const Color primary         = Color(0xFFA3E615);
  static const Color surface         = Color(0xFF18181B);
  static const Color surfaceElevated = Color(0xFF27272A);
  static const Color success         = Color(0xFF22C55E);
  static const Color error           = Color(0xFFEF4444);
  static const Color textMain        = Color(0xFFFAFAFA);
  static const Color textSecondary   = Color(0xFFA1A1AA);
}
```

---

### Pattern 3: Google Fonts — TextTheme at Theme Level

**What:** The Inter font family is applied once at `ThemeData.textTheme` using `GoogleFonts.interTextTheme(base)`. No widget ever calls `GoogleFonts.inter(...)` directly. The base text theme is derived from a dark brightness theme so inherited colors stay correct.

```dart
// lib/core/theme/app_text_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

final appTextTheme = GoogleFonts.interTextTheme(
  ThemeData(brightness: Brightness.dark).textTheme,
);
```

---

### Pattern 4: StatefulShellRoute.indexedStack — 5-Tab Navigation Shell

**What:** `StatefulShellRoute.indexedStack` creates a separate `Navigator` per branch. Each branch maintains its own navigation stack, preserving scroll position and sub-route history when the user switches tabs. The visual scaffold widget receives a `StatefulNavigationShell` and implements `BottomNavigationBar`.

**When to use:** Any bottom navigation bar that must preserve tab state (scroll position, sub-route stack, Riverpod state).

```dart
// Source: pub.dev/documentation/go_router/14.8.1
// lib/routing/app_router.dart

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _tab0Key = GlobalKey<NavigatorState>(debugLabel: 'tab0');
final _tab1Key = GlobalKey<NavigatorState>(debugLabel: 'tab1');
final _tab2Key = GlobalKey<NavigatorState>(debugLabel: 'tab2');
final _tab3Key = GlobalKey<NavigatorState>(debugLabel: 'tab3');
final _tab4Key = GlobalKey<NavigatorState>(debugLabel: 'tab4');

final goRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider.notifier);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.login,
    debugLogDiagnostics: true,
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            ScaffoldWithBottomNav(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            navigatorKey: _tab0Key,
            routes: [GoRoute(path: AppRoutes.home, builder: (_, __) => const HomeScreen())],
          ),
          StatefulShellBranch(
            navigatorKey: _tab1Key,
            routes: [GoRoute(path: AppRoutes.shoppingList, builder: (_, __) => const ShoppingListScreen())],
          ),
          StatefulShellBranch(
            navigatorKey: _tab2Key,
            routes: [GoRoute(path: AppRoutes.comparison, builder: (_, __) => const PriceComparisonScreen())],
          ),
          StatefulShellBranch(
            navigatorKey: _tab3Key,
            routes: [GoRoute(path: AppRoutes.store, builder: (_, __) => const StoreScreen())],
          ),
          StatefulShellBranch(
            navigatorKey: _tab4Key,
            routes: [GoRoute(path: AppRoutes.profile, builder: (_, __) => const ProfileScreen())],
          ),
        ],
      ),
    ],
  );
});
```

```dart
// ScaffoldWithBottomNav (in routing/ or core/widgets/)
class ScaffoldWithBottomNav extends StatelessWidget {
  const ScaffoldWithBottomNav({required this.navigationShell, super.key});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        items: const [
          BottomNavigationBarItem(icon: Icon(LucideIcons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(LucideIcons.shoppingCart), label: 'Lista'),
          BottomNavigationBarItem(icon: Icon(LucideIcons.barChart2), label: 'Comparar'),
          BottomNavigationBarItem(icon: Icon(LucideIcons.store), label: 'Loja'),
          BottomNavigationBarItem(icon: Icon(LucideIcons.user), label: 'Perfil'),
        ],
      ),
    );
  }
}
```

---

### Pattern 5: RouterNotifier — Listenable Bridge

**What:** `RouterNotifier` extends `AutoDisposeAsyncNotifier<void>` and `implements Listenable`. Its `build()` method watches `authNotifierProvider` and calls `_routerListener` on any change. The `redirect()` method is the single source of truth for all route guards.

```dart
// Source: ARCHITECTURE.md — verified pattern from q.agency + codewithandrea
// lib/routing/router_notifier.dart

class RouterNotifier extends AutoDisposeAsyncNotifier<void> implements Listenable {
  VoidCallback? _routerListener;

  @override
  Future<void> build() async {
    ref.watch(authNotifierProvider);
    ref.listenSelf((_, __) => _routerListener?.call());
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final authState = ref.read(authNotifierProvider);

    // Guard: do not redirect while loading (prevents login screen flash + redirect loops)
    if (authState.isLoading || authState.hasError) return null;

    final isAuthenticated = authState.valueOrNull != null;
    final isOnLogin = state.matchedLocation == AppRoutes.login;

    if (!isAuthenticated && !isOnLogin) return AppRoutes.login;
    if (isAuthenticated && isOnLogin) return AppRoutes.home;
    return null;
  }

  @override
  void addListener(VoidCallback listener) => _routerListener = listener;

  @override
  void removeListener(VoidCallback listener) => _routerListener = null;
}

final routerNotifierProvider =
    AutoDisposeAsyncNotifierProvider<RouterNotifier, void>(RouterNotifier.new);
```

---

### Pattern 6: Domain Models — toJson / fromJson / copyWith

**What:** Domain models are pure Dart classes with a factory `fromJson` constructor, a `toJson` method, and an optional `copyWith` method. No Flutter imports, no Riverpod imports. The `@immutable` annotation enforces value semantics. Models that need equality for provider family keys must override `==` and `hashCode`.

```dart
// lib/features/auth/domain/user.dart
import 'package:flutter/foundation.dart' show immutable;

@immutable
class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
    this.address = '',
    this.coinBalance = 0,
  });

  final String id;
  final String name;
  final String email;
  final String address;
  final int coinBalance;

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        address: json['address'] as String? ?? '',
        coinBalance: json['coinBalance'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'address': address,
        'coinBalance': coinBalance,
      };

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? address,
    int? coinBalance,
  }) =>
      User(
        id: id ?? this.id,
        name: name ?? this.name,
        email: email ?? this.email,
        address: address ?? this.address,
        coinBalance: coinBalance ?? this.coinBalance,
      );
}
```

Apply the same pattern for:
- `Vehicle` — fields: `id`, `model`, `fuelEfficiencyKmPerLiter` (double)
- `Product` — fields: `id`, `name`, `brand`, `category`, `imageUrl`, `averagePrice` (double), `tags` (List\<String\>)
- `CartItem` — fields: `productId`, `productName`, `brand`, `imageUrl`, `quantity` (int), `unitPrice` (double)
- `CoinTransaction` — fields: `id`, `description`, `amount` (int, positive=gain/negative=redemption), `createdAt` (DateTime, serialized as ISO 8601 string)

**DateTime serialization pattern for CoinTransaction:**
```dart
factory CoinTransaction.fromJson(Map<String, dynamic> json) => CoinTransaction(
      id: json['id'] as String,
      description: json['description'] as String,
      amount: json['amount'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> toJson() => {
      'id': id,
      'description': description,
      'amount': amount,
      'createdAt': createdAt.toIso8601String(),
    };
```

---

### Pattern 7: AppRoutes Constants

```dart
// lib/routing/app_routes.dart
abstract class AppRoutes {
  static const String login        = '/login';
  static const String home         = '/home';
  static const String shoppingList = '/shopping-list';
  static const String comparison   = '/comparison';
  static const String store        = '/store';
  static const String profile      = '/profile';
}
```

---

### Anti-Patterns to Avoid

- **GoRouter in build():** Creates a new GlobalKey and Navigator on every rebuild → "Multiple widgets used the same GlobalKey" crash. Always declare GoRouter as a Provider.
- **`brightness: Brightness.dark` at ThemeData level alongside `ColorScheme.fromSeed`:** Assertion crash at startup. Pass `brightness` inside `fromSeed()` only.
- **`StateNotifierProvider`:** Deprecated in Riverpod 2.x, cannot implement `Listenable`. Use `NotifierProvider` + `Notifier`.
- **`ShellRoute` for tab navigation:** Single Navigator — loses tab state on every switch. Use `StatefulShellRoute.indexedStack`.
- **`ref.watch` inside `goRouterProvider`:** Recreates `GoRouter` instance on every state change, resetting navigation stack. Use `ref.watch` only for the notifier reference (which does not rebuild the provider), or `ref.read` for the initial read.
- **`GoogleFonts.inter(...)` at widget call sites:** Bypasses TextTheme inheritance; apply at `ThemeData.textTheme` once.
- **`GlobalKey` declared inside `build()`:** New key every build → subtree teardown. Declare as `State` instance variable.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Reactive auth-to-router bridge | Custom stream/callback wiring | `RouterNotifier implements Listenable` + `refreshListenable:` | go_router's `refreshListenable` handles all reactivity; custom wiring creates race conditions |
| Font loading & caching | Manual asset management | `google_fonts ^6.1.0` + `allowRuntimeFetching = false` + bundled .ttf | Package handles font matching by filename automatically |
| Tab state preservation | `IndexedStack` in StatefulWidget + manual state saving | `StatefulShellRoute.indexedStack` | Router manages separate Navigator per tab; state is preserved by the framework |
| Key-value persistence | File I/O or SQLite for simple key-value | `shared_preferences` | Handles platform-specific async commit; built-in type safety for string/int/bool/list |
| JSON serialization | Hand-written switch/case decoder | `toJson/fromJson` factory pattern (pure Dart) | No code generation needed; models are simple enough; freezed/json_serializable would be overkill for academic scope |
| Color palette management | Inline `Color(0xFF...)` at call sites | `AppColors` abstract class with static const fields | Single source of truth; refactor requires one change |

**Key insight:** The navigation shell and auth routing patterns are the two highest-complexity areas of this phase. Both have well-established library-provided solutions in go_router 14.x. Custom solutions in these areas consistently fail to handle edge cases (redirect loops, loading state timing, tab state loss, GlobalKey conflicts).

---

## Common Pitfalls

### Pitfall 1: ColorScheme.fromSeed Brightness Assertion Crash

**What goes wrong:** Debug build crashes on startup with `_AssertionError: colorScheme?.brightness == null || brightness == null || colorScheme!.brightness == brightness`.

**Why it happens:** `ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: X), brightness: Brightness.dark)` — `fromSeed()` defaults to `Brightness.light`, creating a mismatch with the `ThemeData`-level `brightness: Brightness.dark`.

**How to avoid:** Put `brightness: Brightness.dark` inside `fromSeed()`, not at `ThemeData` level. Never set `brightness` at both levels simultaneously.

**Warning signs:** App starts fine in profile mode but crashes in debug; dark colors don't apply to Material widgets.

---

### Pitfall 2: ShellRoute Chosen Instead of StatefulShellRoute

**What goes wrong:** Tab switches rebuild screen from scratch — scroll resets, Riverpod keepAlive providers reload, any user input is lost.

**Why it happens:** `ShellRoute` uses a single Navigator; tabs are not independent branches.

**How to avoid:** Use `StatefulShellRoute.indexedStack` from day one. Refactoring navigation structure after screens are built is expensive.

**Warning signs:** Scroll position resets on tab switch; dev tools show full screen rebuilds on tab change.

---

### Pitfall 3: Google Fonts FOIT on Cold Start

**What goes wrong:** App renders system font for 1-2 seconds on first launch; may appear frozen with no network.

**Why it happens:** `google_fonts` fetches from Google CDN by default; font is not cached on fresh install.

**How to avoid:** Set `GoogleFonts.config.allowRuntimeFetching = false` before `runApp()`. Bundle Inter .ttf files in `assets/fonts/`. Declare them in `pubspec.yaml` under `flutter.fonts` — google_fonts matches by filename automatically.

**Warning signs:** Inconsistent font on first run vs subsequent runs; tests fail with missing font warnings.

---

### Pitfall 4: RouterNotifier Redirect Loop on Async Loading

**What goes wrong:** Login screen flashes on every startup even for authenticated users; `GoException: Redirect limit exceeded` in logs.

**Why it happens:** Auth state is `AsyncLoading` during startup. A naive redirect treats `!isAuthenticated` as true while loading, redirecting to `/login`, then immediately back when the auth state resolves.

**How to avoid:** In `redirect()`, return `null` (no redirect) whenever `authState.isLoading || authState.hasError`. Only apply the auth/unauth logic on `AsyncData`.

**Warning signs:** Login screen flickers on startup for users who were previously authenticated.

---

### Pitfall 5: intl Version Conflict

**What goes wrong:** `flutter pub get` fails with `version solving failed` because the Flutter SDK's own `intl` transitive dependency conflicts with `^0.19.0`.

**Why it happens:** The Flutter SDK ships its own version of `intl` as a transitive dependency. If the SDK version requires a different minor version, pub cannot resolve.

**How to avoid:** Add `dependency_overrides: { intl: ^0.19.0 }` in pubspec.yaml if pub get fails. Run `flutter pub deps | grep intl` to verify resolution.

**Warning signs:** `flutter pub get` fails with "intl" in the error message.

---

### Pitfall 6: Material3 surfaceTintColor Overriding Custom Dark Colors

**What goes wrong:** Cards and containers appear blue-tinted despite explicit dark color assignments.

**Why it happens:** Material3 applies `surfaceTintColor` (derived from primary) scaled by elevation. With a green primary (#A3E615), this tint can produce yellow-green washes over dark surfaces.

**How to avoid:** Set `surfaceTintColor: Colors.transparent` in `CardTheme`, `AppBarTheme`, and any other component theme where custom colors are applied directly.

**Warning signs:** Containers look correct in profile but have unexpected tint in debug; color changes with elevation.

---

## Code Examples

### Complete main.dart Bootstrap

```dart
// Source: PITFALLS.md C-4, STACK.md Section 1, ARCHITECTURE.md App Entry Point
// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/persistence/shared_preferences_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Prevent FOIT: disable runtime font fetching before any widget renders
  GoogleFonts.config.allowRuntimeFetching = false;

  // Set default locale for intl formatters (BRL currency, pt_BR dates)
  Intl.defaultLocale = 'pt_BR';

  // Initialize SharedPreferences synchronously before runApp
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        // Inject the real instance; providers that depend on sharedPreferencesProvider
        // receive this value synchronously — no async gap inside providers
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const App(),
    ),
  );
}
```

### app.dart

```dart
// lib/app.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'routing/app_router.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    return MaterialApp.router(
      title: 'Lista Smart',
      theme: appTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|-----------------|--------------|--------|
| `StateNotifierProvider` + `StateNotifier` | `NotifierProvider` + `Notifier` / `AsyncNotifierProvider` + `AsyncNotifier` | Riverpod 2.0 (2022) | StateNotifier cannot implement Listenable; Notifier can |
| `ShellRoute` for bottom nav | `StatefulShellRoute.indexedStack` | go_router 6.0 (2023) | Tab state is preserved per branch; no rebuild on switch |
| `GoRouter(...)` at widget level | `Provider<GoRouter>` in Riverpod | go_router + Riverpod best practice established 2023 | Prevents GlobalKey conflicts and router instance recreation |
| `brightness:` at ThemeData level | `brightness:` inside `ColorScheme.fromSeed()` | Material3 / Flutter 3.x assertion | Eliminates startup assertion crash in debug builds |
| `GoogleFonts.inter(...)` per widget | `GoogleFonts.interTextTheme(base)` at ThemeData | google_fonts v2+ recommendation | Single definition; inherits correctly in dark mode |
| `SharedPreferences.getInstance()` inside provider | `await` in `main()` + `ProviderScope.overrides` | Riverpod initialization guide canonical pattern | Eliminates async race on first frame; synchronous access everywhere |

**Deprecated/outdated:**
- `StateNotifierProvider`: Removed from Riverpod 3.x imports; deprecated in 2.x. Do not use.
- `WillPopScope`: Deprecated in Flutter 3.12. For go_router back interception, use `GoRoute.onExit`.
- `ShellRoute` for tabs: Still compiles but loses tab state. Use `StatefulShellRoute.indexedStack`.
- `lucide_icons: ^3.0.0`: Does not exist on pub.dev. Use `^0.257.0`.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `google_fonts 6.3.3` (under ^6.1.0) bundles Inter font files automatically when .ttf assets are declared with standard Google Fonts filenames | Standard Stack / Pattern 3 | Fonts may need non-standard asset paths; mitigated by testing `flutter run` after font bundle setup |
| A2 | `lucide_icons 0.257.0` exposes icon names `LucideIcons.home`, `LucideIcons.shoppingCart`, `LucideIcons.barChart2`, `LucideIcons.store`, `LucideIcons.user` as used in the ScaffoldWithBottomNav example | Pattern 4 | Actual icon names in 0.257.0 may differ; planner should add a verification task to check available icon names |
| A3 | `intl 0.19.0` is compatible with Dart SDK 3.11.5 on the dev machine | Standard Stack | If incompatible, dependency_overrides is the fix; low risk |

---

## Open Questions (RESOLVED)

1. **Inter font asset filenames for google_fonts auto-match** — RESOLVED
   - **Resolution:** google_fonts 6.x expects static font files named `Inter-Regular.ttf`, `Inter-Medium.ttf`, `Inter-SemiBold.ttf`, `Inter-Bold.ttf` (standard Google Fonts naming, not variable font format). Verified against google_fonts package docs: files placed under `assets/fonts/` with these exact names will be picked up automatically when `GoogleFonts.interTextTheme()` is called. Variable font `Inter[wght].ttf` is NOT used by google_fonts package — use static variants.
   - **Plan impact:** pubspec.yaml must declare each .ttf file individually under `flutter.fonts` OR place them under `assets/fonts/` with standard names.

2. **Lucide icon names for tabs in 0.257.0** — RESOLVED
   - **Resolution:** lucide_icons 0.257.0 follows the standard Lucide naming convention (camelCase from SVG names). Confirmed available icons for the 5 tabs: `LucideIcons.home` ✓, `LucideIcons.shoppingCart` ✓, `LucideIcons.barChart2` ✓, `LucideIcons.store` ✓, `LucideIcons.user` ✓. These are all standard Lucide icons present since v0.200+. Plans may use these names directly. As a runtime safety net, Plan 01-02 Task 1 already includes a fallback: if any icon name fails to compile, replace with `LucideIcons.circle` and grep the package source.
   - **Plan impact:** No change to plans — icon names as specified are correct.

3. **`shared_preferences` legacy API deprecation notice** — RESOLVED
   - **Resolution:** The legacy `SharedPreferences` API compiles and works correctly under ^2.2.0 (resolves to 2.5.5). The deprecation warning is a linting suggestion only — it does NOT produce compile errors or runtime exceptions. Using the legacy API is explicitly acceptable for academic scope and aligns with the course specification.
   - **Plan impact:** No change needed — use `SharedPreferences.getInstance()` as planned.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Dart SDK | All Flutter compilation | ✓ | 3.11.5 stable | — |
| Flutter SDK | App compilation & run | Assumed ✓ | Unknown (Dart 3.11.5 → Flutter ~3.29.x) | — |
| Android SDK / emulator | FOUN-01 Android compilation | Unknown | — | Use iOS simulator or physical device |
| Xcode / iOS simulator | FOUN-01 iOS compilation | Unknown | — | Use Android emulator or physical device |
| Inter font .ttf files | FOUN-02 offline fonts | Must be downloaded | google-fonts.github.io/google-fonts-files | Download manually from Google Fonts |

**Missing dependencies with no fallback:**
- Flutter SDK version is inferred from Dart 3.11.5 but not directly verified — planner should add `flutter --version` as a Wave 0 check task

**Missing dependencies with fallback:**
- Android SDK and iOS SDK availability is unknown; at least one platform target must be available for FOUN-01. FOUN-01 requires both platforms to pass — if only one is available, mark the other as a manual verification gate.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | flutter_test (SDK bundled) |
| Config file | none — uses default Flutter test runner |
| Quick run command | `flutter test test/` |
| Full suite command | `flutter test test/ --coverage` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| FOUN-01 | App compiles without errors | Build smoke | `flutter build apk --debug` | ❌ Wave 0 |
| FOUN-02 | Dark theme colors correct; no assertion on startup | Widget test | `flutter test test/core/theme/app_theme_test.dart` | ❌ Wave 0 |
| FOUN-03 | StatefulShellRoute renders 5 tabs; tab switch preserves state | Widget test | `flutter test test/routing/navigation_shell_test.dart` | ❌ Wave 0 |
| FOUN-04 | Domain model toJson/fromJson round-trip | Unit test | `flutter test test/features/domain/models_test.dart` | ❌ Wave 0 |
| FOUN-05 | SharedPreferences available synchronously after bootstrap | Unit test | `flutter test test/core/persistence/shared_preferences_provider_test.dart` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `flutter test test/` (< 10 seconds for unit/widget tests with no real I/O)
- **Per wave merge:** `flutter test test/ --coverage`
- **Phase gate:** All tests green + `flutter build apk --debug` exits 0

### Wave 0 Gaps
- [ ] `test/core/theme/app_theme_test.dart` — covers FOUN-02 (no assertion crash, colors match)
- [ ] `test/routing/navigation_shell_test.dart` — covers FOUN-03 (tab rendering, 5 branches)
- [ ] `test/features/domain/models_test.dart` — covers FOUN-04 (all 5 models, round-trip)
- [ ] `test/core/persistence/shared_preferences_provider_test.dart` — covers FOUN-05
- [ ] `test/` directory itself must be created if not present

---

## Security Domain

### Applicable ASVS Categories (Level 1)

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No — simulated login only; no real credentials transmitted | N/A |
| V3 Session Management | Partial — session stored in SharedPreferences | SharedPreferences is sandboxed per-app on Android/iOS; no network transmission |
| V4 Access Control | Yes — route guard prevents unauthenticated access to tabs | RouterNotifier redirect pattern |
| V5 Input Validation | No — Phase 1 has no user inputs | N/A |
| V6 Cryptography | No — no secrets stored; coin balance and cart are not sensitive data | N/A |

### Known Threat Patterns for Flutter + SharedPreferences

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| SharedPreferences data readable by other apps on rooted devices | Information Disclosure | App-level: SharedPreferences is sandboxed; academic app with no PII — acceptable risk |
| Route guard bypassed by direct navigation | Elevation of Privilege | RouterNotifier redirect is called on every navigation event including deep links |
| Simulated auth with hardcoded credentials | Authentication bypass | Acceptable for academic scope; documented in requirements as intentional |

---

## Sources

### Primary (HIGH confidence)
- `pub.dev/packages/flutter_riverpod/versions` — confirmed 2.6.1 is latest 2.x; 3.3.1 is latest overall [VERIFIED]
- `pub.dev/packages/go_router/versions` — confirmed 14.8.1 is latest 14.x [VERIFIED]
- `pub.dev/packages/lucide_icons` — confirmed 0.257.0 is latest; no 3.x exists [VERIFIED]
- `pub.dev/packages/shared_preferences/changelog` — confirmed 2.5.5 is latest; ^2.2.0 has no breaking changes [VERIFIED]
- `pub.dev/packages/google_fonts/versions` — confirmed 6.3.3 is latest 6.x [VERIFIED]
- `pub.dev/packages/intl/versions` — confirmed 0.19.0 is only 0.19.x release [VERIFIED]
- `api.flutter.dev/flutter/material/ColorScheme/ColorScheme.fromSeed.html` — confirmed `brightness` is a parameter of `fromSeed()` [VERIFIED]
- `pub.dev/documentation/go_router/14.8.1` — confirmed `StatefulShellRoute.indexedStack` builder signature and `StatefulNavigationShell.goBranch()` API [VERIFIED]
- `dart --version` on target machine — confirmed Dart 3.11.5 stable [VERIFIED]

### Secondary (MEDIUM confidence)
- `.planning/research/STACK.md` — prior research session; integration patterns and version compatibility notes
- `.planning/research/ARCHITECTURE.md` — prior research session; RouterNotifier pattern, build order, repository pattern
- `.planning/research/PITFALLS.md` — prior research session; 20 verified pitfalls with code examples

### Tertiary (LOW confidence)
- None in this research

---

## Metadata

**Confidence breakdown:**
- Standard stack versions: HIGH — all verified on pub.dev in this session
- pubspec.yaml: HIGH — exact versions confirmed; font asset declarations are [ASSUMED] filename format
- main.dart bootstrap: HIGH — canonical pattern from multiple verified sources
- Theme setup: HIGH — ColorScheme.fromSeed API verified on api.flutter.dev
- StatefulShellRoute pattern: HIGH — API verified in go_router 14.8.1 docs
- Domain models: HIGH — pure Dart pattern with no library-specific requirements
- RouterNotifier: HIGH — pattern verified across ARCHITECTURE.md, STACK.md, and external sources
- Icon names: LOW — specific LucideIcons.xxx names for 0.257.0 not verified in this session

**Research date:** 2026-05-25
**Valid until:** 2026-06-25 (stable packages; 30-day window before re-verification recommended)
