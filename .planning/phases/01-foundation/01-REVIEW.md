---
phase: 01-foundation
reviewed: 2026-06-01T00:00:00Z
depth: standard
files_reviewed: 25
files_reviewed_list:
  - lib/app.dart
  - lib/core/constants/app_colors.dart
  - lib/core/constants/app_sizes.dart
  - lib/core/persistence/shared_preferences_provider.dart
  - lib/core/theme/app_text_theme.dart
  - lib/core/theme/app_theme.dart
  - lib/features/auth/domain/user.dart
  - lib/features/auth/presentation/login_screen.dart
  - lib/features/home/presentation/home_screen.dart
  - lib/features/price_comparison/presentation/price_comparison_screen.dart
  - lib/features/price_registration/presentation/price_registration_screen.dart
  - lib/features/profile/domain/product.dart
  - lib/features/profile/domain/vehicle.dart
  - lib/features/profile/presentation/profile_screen.dart
  - lib/features/shopping_list/domain/cart_item.dart
  - lib/features/shopping_list/presentation/shopping_list_screen.dart
  - lib/features/smart_coins/domain/coin_transaction.dart
  - lib/features/smart_coins/presentation/store_screen.dart
  - lib/main.dart
  - lib/routing/app_router.dart
  - lib/routing/app_routes.dart
  - lib/routing/router_notifier.dart
  - pubspec.yaml
  - test/models/models_test.dart
  - test/repositories/shared_prefs_test.dart
findings:
  critical: 3
  warning: 4
  info: 2
  total: 9
status: issues_found
---

# Phase 01: Code Review Report

**Reviewed:** 2026-06-01T00:00:00Z
**Depth:** standard
**Files Reviewed:** 25
**Status:** issues_found

## Summary

Reviewed the complete walking skeleton for Phase 1: routing infrastructure, domain models, theme system, persistence bootstrap, and tests. The architecture is broadly sound — the ProviderScope/SharedPreferences init pattern, feature-first folder structure, and StatefulShellRoute setup are all correct. Three critical issues were found that will cause runtime crashes or compile failures as written; they must be resolved before Phase 2 builds on this foundation.

---

## Critical Issues

### CR-01: `intl` package used in `main.dart` but absent from `pubspec.yaml`

**File:** `lib/main.dart:4`
**Issue:** `main.dart` imports `package:intl/intl.dart` and calls `Intl.defaultLocale = 'pt_BR'`. The `intl` package is not declared as a direct dependency in `pubspec.yaml`. Flutter's SDK ships `intl` as a transitive dependency, but relying on transitive resolution is unreliable — `flutter pub upgrade` or a Flutter SDK update can change or drop the transitive version, causing `version solving failed` or a compile error. On a clean `flutter pub get` in CI or on a different machine this can silently resolve to a different `intl` version and break BRL formatting.

**Fix:** Add `intl` explicitly to `pubspec.yaml` dependencies (as already recommended in CLAUDE.md):
```yaml
dependencies:
  intl: ^0.19.0
```

---

### CR-02: `RouterNotifier.addListener` overwrites previous listener — single-slot `Listenable` breaks the contract

**File:** `lib/routing/router_notifier.dart:22-25`
**Issue:** The `Listenable` contract (used by `GoRouter.refreshListenable`) requires supporting an arbitrary number of listeners. The current implementation stores only one:

```dart
@override
void addListener(VoidCallback listener) => _routerListener = listener;

@override
void removeListener(VoidCallback listener) => _routerListener = null;
```

Two defects:
1. Each call to `addListener` silently replaces the previous listener. If GoRouter or any other consumer calls `addListener` twice (e.g., during a hot reload, widget tree rebuild, or GoRouter internal re-registration), the first listener is dropped and route refreshes stop firing.
2. `removeListener` nulls the slot unconditionally regardless of which `listener` is passed. Removing listener B will also erase listener A if A was registered after B.

This is a latent crash-class bug: navigation guards will stop responding to auth state changes in Phase 2 the moment the widget tree rebuilds and GoRouter re-subscribes.

**Fix:** Use a standard `ChangeNotifier` mixin or a proper listener list:
```dart
class RouterNotifier extends AutoDisposeAsyncNotifier<void>
    with ChangeNotifier {

  @override
  Future<void> build() async {
    listenSelf((_, __) => notifyListeners());
  }

  String? redirect(BuildContext context, GoRouterState state) {
    return null;
  }
}
```
`ChangeNotifier` implements `Listenable` with a proper multi-listener list and handles all edge cases including duplicate add/remove. This is the pattern documented in the official Riverpod + go_router guides referenced in CLAUDE.md.

---

### CR-03: `ref.watch` used inside `Provider<GoRouter>` — violates CLAUDE.md constraint and recreates router on state changes

**File:** `lib/routing/app_router.dart:31`
**Issue:** `goRouterProvider` is a non-disposing `Provider<GoRouter>`. Inside it, `ref.watch(routerNotifierProvider.notifier)` is called. CLAUDE.md explicitly prohibits: "Do not use `ref.watch` inside a `Provider` to create GoRouter." When `routerNotifierProvider`'s state changes (e.g., its async `build()` completes or re-runs), Riverpod will invalidate `goRouterProvider` and recreate the entire `GoRouter` instance — new `GlobalKey`s fire, the navigation stack resets, and any in-flight navigation is aborted.

Additionally, `routerNotifierProvider` is `autoDispose`. If Riverpod decides to dispose it (e.g., during low-memory conditions before Phase 2 adds persistent watchers), the notifier reference held by `GoRouter.refreshListenable` becomes a stale pointer to a disposed object.

**Fix:** Use `ref.read` to get the notifier once at construction time (GoRouter holds the reference for its lifetime):
```dart
final goRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.read(routerNotifierProvider.notifier);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: true,
    refreshListenable: notifier,
    redirect: notifier.redirect,
    // ...
  );
});
```
Also consider removing `autoDispose` from `routerNotifierProvider` since GoRouter needs it alive for the app lifetime:
```dart
final routerNotifierProvider =
    AsyncNotifierProvider<RouterNotifier, void>(RouterNotifier.new);
```

---

## Warnings

### WR-01: `Product.tags` is a mutable `List<String>` on an `@immutable` class — deep mutability leak

**File:** `lib/features/profile/domain/product.dart:22`
**Issue:** `Product` is annotated `@immutable` and all fields are `final`, but `tags` is typed `List<String>`. Callers can mutate the list in place (`product.tags.add('x')`) bypassing the immutability contract. `fromJson` compounds this: `.cast<String>()` returns a lazy view of the original JSON list, not a copy — the caller retains a reference to the same backing list. `copyWith` also passes `tags` through without copying, so two `Product` instances can share the same list.

**Fix:** Store an unmodifiable copy in the constructor and in `fromJson`:
```dart
// In constructor body / copyWith:
tags: List<String>.unmodifiable(tags ?? this.tags),

// In fromJson:
tags: List<String>.unmodifiable(
  (json['tags'] as List<dynamic>).cast<String>(),
),
```

---

### WR-02: `CoinTransaction.fromJson` calls `DateTime.parse` without guarding `FormatException`

**File:** `lib/features/smart_coins/domain/coin_transaction.dart:25`
**Issue:** `DateTime.parse(json['createdAt'] as String)` throws an uncaught `FormatException` if the stored string is malformed (e.g., corrupted SharedPreferences data, manual edit, or a future serialization bug). All other `fromJson` methods use safe casts (`as String`, `as int?`) but none of them guard against format errors in string parsing. Because this data persists to SharedPreferences, a single bad write would permanently crash the app on startup.

**Fix:**
```dart
createdAt: DateTime.tryParse(json['createdAt'] as String) ??
    DateTime.fromMillisecondsSinceEpoch(0),
```
Or re-throw with context:
```dart
createdAt: () {
  final raw = json['createdAt'] as String;
  final dt = DateTime.tryParse(raw);
  if (dt == null) throw FormatException('Invalid createdAt: $raw');
  return dt;
}(),
```

---

### WR-03: `debugLogDiagnostics: true` left enabled in `goRouterProvider`

**File:** `lib/routing/app_router.dart:36`
**Issue:** `debugLogDiagnostics: true` causes GoRouter to print every route transition to the debug console. This is appropriate during development but should not be unconditionally enabled — it ships to production in release builds and can expose navigation path structure in logs. It also pollutes test output.

**Fix:** Guard behind the `kDebugMode` constant:
```dart
debugLogDiagnostics: kDebugMode,
```
Add `import 'package:flutter/foundation.dart';` if not already present.

---

### WR-04: `app_text_theme.dart` constructs a throw-away `ThemeData` to extract its `textTheme`

**File:** `lib/core/theme/app_text_theme.dart:4`
**Issue:** `ThemeData(brightness: Brightness.dark).textTheme` creates a complete `ThemeData` object — including ColorScheme generation and all sub-themes — solely to access the default dark text theme that is then immediately discarded. This is fragile: if Flutter changes the default dark `TextTheme` in a future SDK version, the behavior of `GoogleFonts.interTextTheme(...)` changes silently because the base is implicit. It also allocates an entire `ThemeData` at startup for no reason.

**Fix:** Pass an explicit base or use the empty `TextTheme()` which `GoogleFonts.interTextTheme` handles correctly:
```dart
final appTextTheme = GoogleFonts.interTextTheme(
  const TextTheme(), // explicit empty base; google_fonts fills all styles
);
```
If dark-mode default colors from the base text theme are required, document that explicitly.

---

## Info

### IN-01: `CartItem` has no computed `totalPrice` getter — callers must re-implement `quantity * unitPrice`

**File:** `lib/features/shopping_list/domain/cart_item.dart`
**Issue:** Every screen that displays a cart total will independently compute `item.quantity * item.unitPrice`. This is dead-weight duplication and a source of inconsistency (e.g., one screen rounds, another truncates). The domain model is the correct owner of this derived value.

**Fix:**
```dart
double get totalPrice => quantity * unitPrice;
```

---

### IN-02: `AppRoutes` uses `abstract class` where `final class` or a plain class with a private constructor would be more idiomatic

**File:** `lib/routing/app_routes.dart:1`
**Issue:** `abstract class AppRoutes` can technically be extended (a concrete subclass can be instantiated). The intent is a static constants namespace. Using `abstract` for this purpose is a Dart anti-pattern — it leaks the ability to extend and is semantically misleading. `AppSizes` and `AppColors` have the same issue.

**Fix:**
```dart
final class AppRoutes {
  AppRoutes._(); // private constructor prevents instantiation
  static const String login = '/login';
  // ...
}
```
Or use a plain `class` with a private constructor. Apply the same fix to `AppSizes` and `AppColors`.

---

_Reviewed: 2026-06-01T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
