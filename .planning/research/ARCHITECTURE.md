# Architecture Research — Lista Smart

**Researched:** 2026-05-25
**Confidence:** HIGH (verified against riverpod.dev, codewithandrea.com, official go_router docs)

---

## Layer Structure

Lista Smart uses a **four-layer clean architecture** adapted for Flutter. Dependencies flow strictly inward: Presentation -> Application -> Domain <- Data. Nothing in Domain imports Flutter widgets or packages.

```
┌─────────────────────────────────────────────┐
│  PRESENTATION LAYER                          │
│  Screens, Widgets, ConsumerWidget/StatefulHook│
│  Reads: controllers via ref.watch            │
│  Writes: calls methods on Notifier           │
├─────────────────────────────────────────────┤
│  APPLICATION LAYER (optional, use for logic) │
│  Service classes, use-case orchestration     │
│  e.g. CartService, CoinService               │
├─────────────────────────────────────────────┤
│  DOMAIN LAYER (pure Dart)                    │
│  Entities, model classes, abstract repos     │
│  No Flutter imports, no Riverpod imports     │
├─────────────────────────────────────────────┤
│  DATA LAYER                                  │
│  Repository impls, LocalDataSource           │
│  SharedPreferences, JSON serialization       │
└─────────────────────────────────────────────┘
```

### Layer Responsibilities

| Layer        | Contains                                                         | May Import           |
|--------------|------------------------------------------------------------------|----------------------|
| Presentation | Screens, widgets, Notifier/AsyncNotifier controllers             | Domain, Application  |
| Application  | CartService, CoinService — orchestrate repos + cross-cutting ops | Domain, Data         |
| Domain       | User, CartItem, Product, CoinTransaction models; abstract repos  | Pure Dart only       |
| Data         | SharedPreferencesCartRepository, SessionRepository impl          | Domain, dart:convert |

For Lista Smart's scope (local persistence only, no remote API), the Application layer is thin and can be skipped for simple features. Introduce it only when a screen needs to coordinate more than one repository (e.g., buying from store debits coins AND updates cart).

---

## Provider Organization

### Principle: Feature-First Files, Global-First Scoping

Providers are **declared per feature** (co-located with their screen) but are **globally accessible** via Riverpod's container — there is no need for nested ProviderScope overrides in Lista Smart.

### Folder Structure

```
lib/
├── main.dart
├── app.dart                         # MaterialApp.router, ProviderScope root
│
├── core/
│   ├── router/
│   │   ├── app_router.dart          # goRouterProvider definition
│   │   └── app_routes.dart          # route name constants
│   ├── persistence/
│   │   └── shared_preferences_provider.dart  # sharedPreferencesProvider
│   └── theme/
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   └── session_repository.dart
│   │   ├── domain/
│   │   │   └── user.dart
│   │   └── presentation/
│   │       ├── login_screen.dart
│   │       └── auth_notifier.dart   # authNotifierProvider
│   │
│   ├── home/
│   │   └── presentation/
│   │       └── home_screen.dart
│   │
│   ├── shopping_list/
│   │   ├── data/
│   │   │   └── cart_repository.dart
│   │   ├── domain/
│   │   │   └── cart_item.dart
│   │   └── presentation/
│   │       ├── shopping_list_screen.dart
│   │       └── cart_notifier.dart   # cartNotifierProvider
│   │
│   ├── price_comparison/
│   │   └── presentation/
│   │       └── price_comparison_screen.dart
│   │
│   ├── store/
│   │   ├── data/
│   │   │   └── coin_transaction_repository.dart
│   │   ├── domain/
│   │   │   └── coin_transaction.dart
│   │   └── presentation/
│   │       ├── store_screen.dart
│   │       └── coin_notifier.dart   # coinNotifierProvider
│   │
│   ├── price_registration/
│   │   └── presentation/
│   │       └── price_registration_screen.dart
│   │
│   └── profile/
│       └── presentation/
│           └── profile_screen.dart
```

### Provider Types — When to Use Which (Riverpod 3)

| Type                   | Use Case                                   | Lista Smart Example              |
|------------------------|--------------------------------------------|----------------------------------|
| `Provider`             | Immutable dependencies, repos, services    | `cartRepositoryProvider`         |
| `NotifierProvider`     | Sync mutable state with methods            | `cartNotifierProvider`, `favoritesNotifierProvider` |
| `AsyncNotifierProvider`| Async mutable state (loads + mutates)      | `authNotifierProvider` (session load) |
| `FutureProvider`       | Read-only async data, no mutations needed  | (not needed here)                |
| `StreamProvider`       | Continuous data streams                    | (not needed here)                |

**StateNotifier and StateNotifierProvider are deprecated as of Riverpod 3.** Use `Notifier` / `AsyncNotifier` exclusively in new code.

### Notifier Pattern (canonical form)

```dart
// cart_notifier.dart
class CartNotifier extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() {
    // build() is the constructor; ref is available as this.ref
    // Load initial state from repository synchronously
    return ref.read(cartRepositoryProvider).loadCart();
  }

  void addItem(CartItem item) {
    state = [...state, item];
    ref.read(cartRepositoryProvider).saveCart(state);
  }

  void removeItem(String productId) {
    state = state.where((i) => i.productId != productId).toList();
    ref.read(cartRepositoryProvider).saveCart(state);
  }
}

final cartNotifierProvider =
    NotifierProvider<CartNotifier, List<CartItem>>(CartNotifier.new);
```

### keepAlive Strategy

Use `@Riverpod(keepAlive: true)` (or the non-codegen equivalent) for:
- `sharedPreferencesProvider` — instantiated once at startup
- `authNotifierProvider` — user session must survive navigation
- `cartNotifierProvider` — cart must persist across screens
- `favoritesNotifierProvider` — favorites must persist across screens
- `coinNotifierProvider` — coin balance must persist across screens

Feature-specific UI state providers (e.g., search query, form state) should use the default `keepAlive: false` and dispose when the screen exits.

---

## go_router + Riverpod Auth Pattern

### The Challenge

GoRouter's `redirect` function and `refreshListenable` parameter need to be notified when Riverpod auth state changes. Because GoRouter uses the `Listenable` protocol (Flutter's `ChangeNotifier` world) and Riverpod providers are reactive but not `Listenable`, a bridge is required.

### Recommended Pattern: RouterNotifier

Create a `RouterNotifier` that extends `AutoDisposeAsyncNotifier` and `implements Listenable`. This class serves dual purpose: it IS the auth state notifier, and it IS the `Listenable` GoRouter watches.

```dart
// core/router/router_notifier.dart

class RouterNotifier extends AutoDisposeAsyncNotifier<void>
    implements Listenable {
  VoidCallback? _routerListener;

  @override
  Future<void> build() async {
    // Watch auth provider — any change to auth state triggers rebuild
    // which calls _routerListener, which triggers GoRouter redirect
    ref.watch(authNotifierProvider);
    ref.listenSelf((_, __) => _routerListener?.call());
  }

  @override
  void addListener(VoidCallback listener) {
    _routerListener = listener;
  }

  @override
  void removeListener(VoidCallback listener) {
    _routerListener = null;
  }

  // Redirect logic: called by GoRouter on every navigation event
  String? redirect(BuildContext context, GoRouterState state) {
    final authState = ref.read(authNotifierProvider);

    // While auth is loading, do not redirect — show current route
    if (authState.isLoading || authState.hasError) return null;

    final isAuthenticated = authState.valueOrNull != null;
    final isOnLoginPage = state.matchedLocation == AppRoutes.login;

    if (!isAuthenticated && !isOnLoginPage) return AppRoutes.login;
    if (isAuthenticated && isOnLoginPage) return AppRoutes.home;

    return null; // no redirect needed
  }
}

final routerNotifierProvider =
    AutoDisposeAsyncNotifierProvider<RouterNotifier, void>(
        RouterNotifier.new);
```

```dart
// core/router/app_router.dart

final goRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider.notifier);

  return GoRouter(
    initialLocation: AppRoutes.login,
    navigatorKey: _rootNavigatorKey,
    debugLogDiagnostics: true,
    refreshListenable: notifier,  // GoRouter re-evaluates redirect when notifier fires
    redirect: notifier.redirect,
    routes: _buildRoutes(),
  );
});
```

### App Entry Point

```dart
// app.dart
class App extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    return MaterialApp.router(routerConfig: router);
  }
}

// main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
```

### Route Name Constants

```dart
// core/router/app_routes.dart
abstract class AppRoutes {
  static const login = '/login';
  static const home = '/home';
  static const shoppingList = '/shopping-list';
  static const priceComparison = '/price-comparison';
  static const store = '/store';
  static const priceRegistration = '/price-registration';
  static const profile = '/profile';
}
```

---

## Data Layer (shared_preferences)

### Pattern: Abstract Repository + SharedPreferences Implementation

The data layer wraps SharedPreferences behind an abstract interface in the Domain layer. The concrete implementation lives in Data. Riverpod provides the concrete impl via a Provider that depends on `sharedPreferencesProvider`.

```
Domain:   abstract class CartRepository { ... }
Data:     class SharedPrefsCartRepository implements CartRepository { ... }
Provider: cartRepositoryProvider = Provider((ref) =>
            SharedPrefsCartRepository(ref.read(sharedPreferencesProvider)))
```

### Bootstrap: SharedPreferences Provider

SharedPreferences requires an async `getInstance()` call at startup. Initialize it before `runApp()` and inject via ProviderScope override — this avoids async loading inside every provider.

```dart
// core/persistence/shared_preferences_provider.dart
final sharedPreferencesProvider =
    Provider<SharedPreferences>((_) => throw UnimplementedError());
// Overridden in main.dart with the real instance
```

### Example: Cart Repository

```dart
// features/shopping_list/domain/cart_repository.dart
abstract class CartRepository {
  List<CartItem> loadCart();
  Future<void> saveCart(List<CartItem> items);
  Future<void> clearCart();
}

// features/shopping_list/data/cart_repository.dart
class SharedPrefsCartRepository implements CartRepository {
  SharedPrefsCartRepository(this._prefs);
  final SharedPreferences _prefs;
  static const _key = 'cart_items';

  @override
  List<CartItem> loadCart() {
    final raw = _prefs.getString(_key);
    if (raw == null) return [];
    final List<dynamic> decoded = jsonDecode(raw);
    return decoded.map((e) => CartItem.fromJson(e)).toList();
  }

  @override
  Future<void> saveCart(List<CartItem> items) async {
    final encoded = jsonEncode(items.map((e) => e.toJson()).toList());
    await _prefs.setString(_key, encoded);
  }

  @override
  Future<void> clearCart() => _prefs.remove(_key);
}

final cartRepositoryProvider = Provider<CartRepository>((ref) {
  return SharedPrefsCartRepository(ref.read(sharedPreferencesProvider));
});
```

### Persistence Key Strategy

| State              | Key                   | Format        |
|--------------------|-----------------------|---------------|
| Cart items         | `cart_items`          | JSON array    |
| Favorites          | `favorite_product_ids`| JSON array    |
| Session (user)     | `session_user`        | JSON object   |
| Coin transactions  | `coin_transactions`   | JSON array    |

### Session Repository (Auth)

Auth state is the most critical local persistence. The session repo reads user data on startup and writes on login/logout. The `authNotifierProvider` calls `build()` which reads from the session repo — this is where the async initialization happens.

```dart
class AuthNotifier extends AsyncNotifier<User?> {
  @override
  Future<User?> build() async {
    // Load session from SharedPrefs on app start
    return ref.read(sessionRepositoryProvider).loadUser();
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    // validate credentials...
    final user = User(email: email, ...);
    await ref.read(sessionRepositoryProvider).saveUser(user);
    state = AsyncData(user);
  }

  Future<void> logout() async {
    await ref.read(sessionRepositoryProvider).clearUser();
    state = const AsyncData(null);
  }
}
```

---

## State Flow Diagram

```
User Action (e.g., tap "Add to Cart")
        │
        ▼
   Screen Widget (ConsumerWidget)
   ref.read(cartNotifierProvider.notifier).addItem(item)
        │
        ▼
   CartNotifier.addItem()
   ├── state = [...state, item]       ← triggers rebuild of watchers
   └── ref.read(cartRepositoryProvider).saveCart(state)
                │
                ▼
         SharedPrefsCartRepository.saveCart()
                │
                ▼
         SharedPreferences.setString('cart_items', encoded)

─────────────────────────────────────────────

Auth Change Flow:
   AuthNotifier.login() / logout()
        │
        ├── state = AsyncData(user) or AsyncData(null)
        │
        ▼
   RouterNotifier (watches authNotifierProvider)
        │
        ▼
   _routerListener?.call()          ← notifies GoRouter
        │
        ▼
   GoRouter.redirect()              ← evaluates redirect
        │
        ▼
   Navigate to /home or /login

─────────────────────────────────────────────

Screen reads flow:
   ShoppingListScreen
   ref.watch(cartNotifierProvider)   ← reactive, rebuilds on state change
        │
        ▼
   CartNotifier.state (List<CartItem>)
   (already in memory, loaded from SharedPrefs in build())
```

---

## Build Order

Build bottom-up: Data layer first, then Domain, then Providers, then Screens. This order ensures every dependency is ready before its consumer.

### Phase 1 — Foundation (no UI)
1. `SharedPreferences` bootstrap in `main.dart` + `sharedPreferencesProvider`
2. All Domain models (`User`, `CartItem`, `Product`, `CoinTransaction`) with `toJson`/`fromJson`
3. Abstract repository interfaces in Domain

### Phase 2 — Data Layer
4. `SessionRepository` + `SharedPrefsSessionRepository`
5. `CartRepository` + `SharedPrefsCartRepository`
6. `FavoritesRepository` + `SharedPrefsFavoritesRepository`
7. `CoinTransactionRepository` + `SharedPrefsCoinTransactionRepository`

### Phase 3 — Providers & State
8. `authNotifierProvider` + `AuthNotifier` (AsyncNotifier)
9. `cartNotifierProvider` + `CartNotifier`
10. `favoritesNotifierProvider` + `FavoritesNotifier`
11. `coinNotifierProvider` + `CoinNotifier`

### Phase 4 — Navigation Shell
12. `AppRoutes` constants
13. `RouterNotifier` + `goRouterProvider`
14. `App` widget wiring `MaterialApp.router`

### Phase 5 — Screens (in dependency order)
15. `LoginScreen` — depends only on `authNotifierProvider`
16. `HomeScreen` — depends on `authNotifierProvider`, `cartNotifierProvider`
17. `ShoppingListScreen` — depends on `cartNotifierProvider`, `favoritesNotifierProvider`
18. `PriceComparisonScreen` — depends on `cartNotifierProvider`
19. `PriceRegistrationScreen` — standalone form
20. `StoreScreen` — depends on `coinNotifierProvider`
21. `ProfileScreen` — depends on `authNotifierProvider`, `coinNotifierProvider`

**Rationale:** Building models first means you can write and test repositories without a UI. Providers built before screens means each screen gets a working data layer from the first render. Navigation shell built before screens means route guards work from the start — no screen is ever accidentally accessible without auth.

---

## Component Boundaries

| Component               | Owns                                | Reads (via ref.watch)                      | Must NOT touch                |
|-------------------------|-------------------------------------|--------------------------------------------|-------------------------------|
| `LoginScreen`           | Login form UI, validation errors    | `authNotifierProvider`                     | Cart, coins, navigation logic |
| `HomeScreen`            | Feature navigation cards, summary   | `authNotifierProvider`, `cartNotifierProvider` | Routing decisions         |
| `ShoppingListScreen`    | Cart list, item management          | `cartNotifierProvider`, `favoritesNotifierProvider` | Auth, coins            |
| `PriceComparisonScreen` | Product price table                 | `cartNotifierProvider`                     | Auth, persistence directly    |
| `PriceRegistrationScreen`| Form inputs                        | (minimal, posts to a local store)          | Routing, auth                 |
| `StoreScreen`           | Coin balance, purchasable items     | `coinNotifierProvider`, `authNotifierProvider` | Cart                    |
| `ProfileScreen`         | User info display, logout           | `authNotifierProvider`, `coinNotifierProvider` | Cart, favorites         |
| `CartNotifier`          | Cart state, persistence             | `cartRepositoryProvider`                   | UI widgets, routing           |
| `AuthNotifier`          | Session state, login/logout         | `sessionRepositoryProvider`                | UI widgets, GoRouter          |
| `RouterNotifier`        | Redirect logic bridge               | `authNotifierProvider`                     | Business logic, repos         |
| `GoRouter`              | Route definitions, guards           | Provided by `goRouterProvider`             | State directly                |
| Repositories            | Read/write SharedPreferences        | `sharedPreferencesProvider`                | Notifiers, UI                 |

### Cross-Cutting Rules

- Screens never import repository classes directly — always go through a Notifier
- Notifiers never import other Notifiers directly — use `ref.read(otherProvider)` if coordination is needed
- Domain models are imported everywhere (they are pure Dart data classes)
- `GoRouter` is created inside a Provider, never at top-level, to ensure `ref` access
- `SharedPreferences` instance is injected at startup via ProviderScope override, never fetched inside a provider using `await SharedPreferences.getInstance()`

---

## Sources

- [Flutter App Architecture with Riverpod: An Introduction — codewithandrea.com](https://codewithandrea.com/articles/flutter-app-architecture-riverpod-introduction/)
- [Flutter Repository Pattern — codewithandrea.com](https://codewithandrea.com/articles/flutter-repository-pattern/)
- [Riverpod: From StateNotifier Migration Guide — riverpod.dev](https://riverpod.dev/docs/migration/from_state_notifier)
- [Handling Authentication State With go_router and Riverpod — q.agency](https://q.agency/blog/handling-authentication-state-with-go_router-and-riverpod/)
- [Guarding Routes in Flutter with GoRouter and Riverpod — dinkomarinac.dev](https://dinkomarinac.dev/guarding-routes-in-flutter-with-gorouter-and-riverpod)
- [Flutter Firebase Auth with Riverpod 2.5 and GoRouter — Medium/Jakob Prossinger](https://medium.com/@jakob.prossinger/flutter-firebase-authentication-with-riverpod-2-5-and-gorouter-0311ad23550b)
- [Riverpod Folder Structure | Clean Architecture — dbestech.com](https://www.dbestech.com/tutorials/riverpod-folder-structure-clean-architecture)
- [Best Folder Structure for Flutter App with Riverpod — Medium/DevStudio](https://medium.com/devstudio/best-folder-structure-for-flutter-app-with-riverpod-ba72ceb780b3)
- [Riverpod Data Caching and Providers Lifecycle — codewithandrea.com](https://codewithandrea.com/articles/flutter-riverpod-data-caching-providers-lifecycle/)
- [Flutter Riverpod 3 Complete Migration Guide — flutterstudio.dev](https://flutterstudio.dev/blog/flutter-riverpod-3-complete-migration-guide.html)
