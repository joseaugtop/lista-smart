# Stack Research — Lista Smart

**Project:** Lista Smart (Flutter shopping/price comparison app)
**Researched:** 2026-05-25
**Scope:** Prescribed academic stack — no alternatives evaluated, patterns and integration quality assessed

---

## Recommended Stack

| Package | Pinned Version | Latest Stable | Purpose | Notes |
|---------|---------------|---------------|---------|-------|
| flutter_riverpod | ^2.5.1 | 3.3.1 (3.x branch) | Global state management | Course-prescribed. 2.x branch latest is 2.6.1. Pinning ^2.5.1 resolves to 2.6.x — intentional. Do NOT upgrade to 3.x (breaking API). |
| go_router | ^14.0.0 | 17.2.3 | Declarative routing with redirect support | Course-prescribed. ^14.0.0 resolves to 14.x. Latest is 17.x but 14.x is stable and fully functional for this scope. Do NOT upgrade to 15+ without migration guide review. |
| shared_preferences | ^2.2.0 | 2.x (maintained) | Local key-value persistence | Sufficient for cart, favorites, session. No SQL needed — all data is mocked. |
| lucide_icons | ^3.0.0 | 0.257.0 | Icon system | WARNING: version mismatch — see Version Compatibility Notes. |
| google_fonts | ^6.1.0 | 8.x | Typography (Inter/Poppins) | 6.x is stable. Disable runtime HTTP fetching — see integration notes. |
| intl | ^0.19.0 | 0.19.x | Date/number formatting (BRL currency) | Pin to ^0.19.0. Flutter SDK ships its own intl; version must match. |

---

## Integration Patterns

### 1. App Entry Point — ProviderScope + SharedPreferences Init

Use the legacy `ProviderScope` overrides pattern (simpler for academic project, avoids async splash complexity):

```dart
// main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sharedPreferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const ListaSmartApp(),
    ),
  );
}

// providers/shared_preferences_provider.dart
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (_) => throw UnimplementedError('Override in main()'),
);
```

**Why this over FutureProvider pattern:** FutureProvider with appStartupProvider is better for production retry logic but adds a loading-screen layer that is unnecessary when all data is mocked and SharedPreferences never fails in practice.

---

### 2. Riverpod Provider Types — Which to Use

| Use Case | Provider Type | Rationale |
|----------|--------------|-----------|
| Read-only derived data (product list from mock) | `Provider<T>` | No side effects, pure computation |
| Simple sync mutable state (cart items, favorites) | `NotifierProvider<T, S>` | Modern API, replaces deprecated StateNotifier |
| Async state (simulated camera flow, coin award) | `AsyncNotifierProvider<T, S>` | Handles loading/error states ergonomically |
| Shared preferences access | `Provider<SharedPreferences>` | Overridden at startup, synchronous after init |
| User session (auth simulation) | `NotifierProvider<UserNotifier, UserState>` | Notifier implements Listenable for go_router |

**Critical:** Do NOT use `StateNotifierProvider`. It is deprecated in 2.x and removed conceptually in 3.x. Use `NotifierProvider` + `Notifier` class instead.

---

### 3. go_router + Riverpod — Router Provider Pattern

The `GoRouter` instance must live inside a `Provider` so Riverpod manages its lifecycle. The `redirect` callback reads auth state. For this app (simulated login), `UserNotifier` implements `Listenable` so go_router can react to auth changes without rebuilding the entire router:

```dart
// features/auth/user_notifier.dart
class UserNotifier extends Notifier<UserState> implements Listenable {
  VoidCallback? _routerListener;

  @override
  UserState build() => const UserState.unauthenticated();

  void login(String email) {
    state = UserState.authenticated(mockUser);
    _routerListener?.call(); // notify go_router
  }

  void logout() {
    state = const UserState.unauthenticated();
    _routerListener?.call();
  }

  @override
  void addListener(VoidCallback listener) => _routerListener = listener;

  @override
  void removeListener(VoidCallback listener) => _routerListener = null;
}

// routing/app_router.dart
final appRouterProvider = Provider<GoRouter>((ref) {
  final userNotifier = ref.read(userNotifierProvider.notifier);

  return GoRouter(
    refreshListenable: userNotifier,
    initialLocation: '/login',
    redirect: (context, state) {
      final isAuthenticated = userNotifier.state.isAuthenticated;
      final onLogin = state.matchedLocation == '/login';

      if (!isAuthenticated && !onLogin) return '/login';
      if (isAuthenticated && onLogin) return '/home';
      return null; // no redirect
    },
    routes: $appRoutes, // defined in routes file
  );
});
```

**Why `ref.read` not `ref.watch` for the notifier:** The router itself is created once. `ref.watch` inside a `Provider` would recreate the `GoRouter` instance on every state change — this causes navigator stack resets. Use `ref.read` to get the notifier reference; the `refreshListenable` handles reactivity.

**Why implement `Listenable` on `Notifier` not `ChangeNotifier`:** `StateNotifier` cannot implement `Listenable`. The modern `Notifier` class can, and the Q Agency pattern (2024) confirms this is the canonical approach. No wrapper class needed.

---

### 4. Riverpod Consumer Patterns in Widgets

Prefer `ConsumerWidget` over `StatelessWidget + Consumer` — cleaner and avoids extra nesting:

```dart
// Correct
class ProductCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);
    return ...;
  }
}

// Avoid — unnecessary Consumer nesting
class ProductCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) { ... },
    );
  }
}
```

Use `ConsumerStatefulWidget` only when the widget genuinely needs a `State` (animation controllers, `TextEditingController`, lifecycle methods).

---

### 5. google_fonts Integration

Disable runtime HTTP fetching to ensure the app works fully offline (required since all data is mocked and there is no network dependency):

```dart
// main.dart — before runApp
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  // ...
}
```

Define a shared text theme to avoid re-instantiating font objects per widget:

```dart
// theme/app_text_theme.dart
final appTextTheme = TextTheme(
  displayLarge: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w700),
  bodyMedium: GoogleFonts.inter(fontSize: 14),
  labelLarge: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
  // ...
);
```

---

### 6. intl — Brazilian Real Formatting

```dart
// utils/formatters.dart
import 'package:intl/intl.dart';

final brlFormatter = NumberFormat.simpleCurrency(locale: 'pt_BR');

String formatCurrency(double value) => brlFormatter.format(value);
// Output: "R$ 12,50"
```

Ensure `Intl.defaultLocale` is set at app startup if using date formatting:

```dart
Intl.defaultLocale = 'pt_BR';
```

---

## Folder Structure

Feature-first organization is the current consensus for Riverpod apps (endorsed by codewithandrea.com and riverpod.dev architecture guides). Features map to business domains, not screens.

```
lib/
├── main.dart                        # ProviderScope, GoogleFonts config
├── app.dart                         # MaterialApp.router wired to appRouterProvider
│
├── core/                            # Cross-feature infrastructure
│   ├── constants/
│   │   ├── app_colors.dart          # #09090B, #A3E615, #18181B palette
│   │   └── app_sizes.dart
│   ├── theme/
│   │   ├── app_theme.dart           # ThemeData (dark)
│   │   └── app_text_theme.dart      # GoogleFonts text theme
│   ├── providers/
│   │   └── shared_preferences_provider.dart
│   └── widgets/                     # Reusable components (AppButton, AppCard)
│
├── routing/
│   ├── app_router.dart              # appRouterProvider, GoRouter config
│   └── app_routes.dart              # Route constants / GoRouteData definitions
│
├── features/
│   ├── auth/
│   │   ├── domain/
│   │   │   └── user_model.dart
│   │   ├── data/
│   │   │   └── mock_user_repository.dart
│   │   ├── application/
│   │   │   └── user_notifier.dart   # Implements Listenable for go_router
│   │   └── presentation/
│   │       └── login_screen.dart
│   │
│   ├── products/
│   │   ├── domain/
│   │   │   └── product_model.dart
│   │   ├── data/
│   │   │   └── mock_products_repository.dart
│   │   ├── application/
│   │   │   ├── products_provider.dart
│   │   │   └── favorites_notifier.dart
│   │   └── presentation/
│   │       ├── home_screen.dart
│   │       └── product_card.dart
│   │
│   ├── shopping_list/
│   │   ├── domain/
│   │   │   └── cart_item_model.dart
│   │   ├── data/
│   │   │   └── cart_repository.dart  # Persists via SharedPreferences
│   │   ├── application/
│   │   │   └── cart_notifier.dart
│   │   └── presentation/
│   │       └── shopping_list_screen.dart
│   │
│   ├── price_comparison/
│   │   ├── domain/
│   │   │   └── supermarket_price_model.dart
│   │   ├── data/
│   │   │   └── mock_prices_repository.dart
│   │   ├── application/
│   │   │   └── price_comparison_provider.dart
│   │   └── presentation/
│   │       └── price_comparison_screen.dart
│   │
│   ├── smart_coins/
│   │   ├── domain/
│   │   │   └── coin_transaction_model.dart
│   │   ├── data/
│   │   │   └── mock_coins_repository.dart
│   │   ├── application/
│   │   │   └── coins_notifier.dart
│   │   └── presentation/
│   │       ├── coins_store_screen.dart
│   │       └── price_submission_flow/   # 3-step flow screens
│   │
│   └── profile/
│       ├── domain/
│       │   └── vehicle_model.dart
│       ├── application/
│       │   └── profile_notifier.dart
│       └── presentation/
│           └── profile_screen.dart
```

**Rule:** No cross-feature imports at the `presentation/` layer. Features communicate via shared providers in `application/` or domain models in `domain/`. The `core/` directory holds anything truly shared (theme, base widgets, cross-cutting providers).

---

## Version Compatibility Notes

### CRITICAL — lucide_icons version mismatch

The course spec pins `lucide_icons: ^3.0.0` but pub.dev shows the latest published version is **0.257.0**. The `^3.0.0` constraint will **fail to resolve** — there is no 3.x release on pub.dev.

**Likely explanation:** The spec may have confused `lucide_icons` (versioned 0.x on pub.dev) with a related package like `flutter_lucide` (separate package, different versioning), or the spec was written speculatively.

**Resolution:** Use `lucide_icons: ^0.257.0` in pubspec.yaml. The API is identical (`LucideIcons.iconName`). Confirm with the course instructor if the exact version constraint matters for grading. If `^3.0.0` is enforced literally, the project will not compile.

---

### flutter_riverpod 2.5.1 vs current 3.x

- Course pins `^2.5.1` which resolves to the latest 2.x release (2.6.1 as of 2024-10-22)
- Riverpod 3.0.0 was released 2025-09-10 with breaking API changes (Ref changes, legacy providers moved, AsyncValue parameter changes)
- **Do NOT upgrade to 3.x** — the prescribed API (`Notifier`, `AsyncNotifier`, `Provider`, `ConsumerWidget`) works identically in 2.5.x and 2.6.x
- The `StateNotifierProvider` is deprecated in 2.x — avoid it even though it still compiles

---

### go_router 14.x vs current 17.x

- `^14.0.0` resolves to the 14.x series (latest in that series: ~14.8.x)
- Breaking change in 14.0: `GoRouteData.onExit` now takes 2 parameters (`BuildContext`, `GoRouterState`)
- Versions 15-17 introduced additional changes not covered by the ^14 constraint
- **Do NOT upgrade** — 14.x is stable and sufficient for all required navigation patterns (nested routes, redirects, shell routes for bottom nav)

---

### intl version alignment

- `intl: ^0.19.0` must match the version bundled with the Flutter SDK's own `intl` dependency
- Flutter 3.16+ bundles intl 0.18.x/0.19.x — a mismatch causes `version solving failed`
- Run `flutter pub deps` after setup to verify intl version is consistent across the dependency graph
- If there is a conflict: override with `dependency_overrides:` in pubspec.yaml (acceptable for academic project)

---

### google_fonts 6.1.0

- Latest is 8.x but 6.x is stable
- The `^6.1.0` constraint will NOT upgrade to 7.x or 8.x — safe and intentional
- 6.x has no known breaking issues with Flutter 3.x

---

## What NOT to Do

### 1. Do not use `StateNotifierProvider`
**Why:** Deprecated in Riverpod 2.x, removed from main imports in 3.x. It cannot implement `Listenable` (prevents clean go_router integration). Use `NotifierProvider` with `Notifier` class.

### 2. Do not use `ref.watch` inside a `Provider` to create GoRouter
**Why:** Every state change that triggers the provider re-evaluation destroys and recreates the `GoRouter` instance, resetting the entire navigation stack. Create the router once with `ref.read` for the notifier reference; use `refreshListenable` for reactivity.

### 3. Do not create providers inside widget classes or functions
**Why:** Riverpod requires providers to be top-level `final` variables. Providers created dynamically (inside classes, as instance members, inside build methods) cause memory leaks and break the provider graph. They also prevent riverpod_lint from analyzing them.

### 4. Do not use `google_fonts` without disabling HTTP fetching
**Why:** In an offline academic app, allowing runtime font fetching introduces network dependency, causes test flakiness, and can produce visual inconsistency if fonts are partially cached. Set `GoogleFonts.config.allowRuntimeFetching = false` at startup.

### 5. Do not store ephemeral UI state (hover, form focus, animation progress) in Riverpod providers
**Why:** Riverpod is for shared application state. Ephemeral widget-local state should use `StatefulWidget` or `flutter_hooks`. Putting it in providers creates unnecessary provider rebuilds and pollutes the provider graph.

### 6. Do not use `context.read<T>()` (inherited widget pattern) — use `ref.read(provider)`
**Why:** This project uses Riverpod, not Provider package. Mixing `BuildContext.read` (from the `provider` package) with `WidgetRef.read` (Riverpod) causes confusion and potential conflicts if both packages end up in the graph as transitive dependencies.

### 7. Do not call `ref.watch` inside `initState`, `dispose`, or event handlers
**Why:** `ref.watch` is only valid inside `build` methods (or Riverpod provider bodies). Use `ref.read` in event handlers; use `ref.listen` in `build` for side-effect reactions (showing snackbars, navigation after an action completes).

### 8. Do not skip the `Listenable` implementation on `UserNotifier`
**Why:** go_router's `refreshListenable` only accepts `Listenable` objects. Without it, auth state changes (login/logout) will not trigger route redirects. The router will show stale routes until the next manual navigation.

---

## pubspec.yaml Setup

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
  lucide_icons: ^0.257.0      # NOTE: course spec says ^3.0.0 — does not exist, use this
  google_fonts: ^6.1.0
  intl: ^0.19.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true  # Required for Material Icons fallback
```

---

## Confidence

| Area | Level | Reason |
|------|-------|--------|
| Riverpod 2.5.x patterns (Notifier, ConsumerWidget) | HIGH | Verified against riverpod.dev official docs and Context7 (3735+ code snippets) |
| go_router 14.x redirect + refreshListenable | HIGH | Verified against pub.dev changelog and multiple 2024 integration guides |
| Riverpod + go_router Listenable pattern | HIGH | Confirmed by Q Agency (2024), codewithandrea, official Riverpod discussions |
| SharedPreferences ProviderScope override | HIGH | Verified against official codewithandrea.com Riverpod initialization guide |
| lucide_icons version mismatch | HIGH | Directly verified on pub.dev — no 3.x version exists |
| google_fonts offline config | HIGH | Documented on pub.dev package page and multiple production guides |
| Folder structure recommendation | MEDIUM | Feature-first is the consensus recommendation; the specific split chosen here is opinionated for this project's domain |
| intl version conflict risk | MEDIUM | Documented pattern, specific Flutter SDK version in student's environment unknown |

---

## Sources

- [Riverpod Official Do's and Don'ts](https://riverpod.dev/docs/root/do_dont)
- [go_router pub.dev package page](https://pub.dev/packages/go_router)
- [flutter_riverpod changelog](https://pub.dev/packages/flutter_riverpod/changelog)
- [Handling Authentication State with go_router and Riverpod — Q Agency](https://q.agency/blog/handling-authentication-state-with-go_router-and-riverpod/)
- [Flutter App Architecture with Riverpod: Feature-first structure — codewithandrea.com](https://codewithandrea.com/articles/flutter-project-structure/)
- [Robust App Initialization with Riverpod — codewithandrea.com](https://codewithandrea.com/articles/robust-app-initialization-riverpod/)
- [Migrating from StateNotifier — Riverpod docs](https://riverpod.dev/docs/migration/from_state_notifier)
- [lucide_icons on pub.dev](https://pub.dev/packages/lucide_icons)
- [google_fonts on pub.dev](https://pub.dev/packages/google_fonts)
