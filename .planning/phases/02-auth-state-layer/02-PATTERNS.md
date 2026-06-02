# Phase 2: Auth + State Layer - Pattern Map

**Mapped:** 2026-06-01
**Files analyzed:** 11 (8 new + 2 modified + 1 domain fix)
**Analogs found:** 11 / 11

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/routing/router_notifier.dart` | provider/notifier | event-driven | `lib/routing/router_notifier.dart` (self — replace) | exact |
| `lib/routing/app_router.dart` | config | request-response | `lib/routing/app_router.dart` (self — patch) | exact |
| `lib/core/providers/user_notifier.dart` | provider/notifier | request-response | `lib/core/persistence/shared_preferences_provider.dart` + `lib/features/auth/domain/user.dart` | role-match |
| `lib/core/providers/cart_notifier.dart` | provider/notifier | CRUD | `lib/features/shopping_list/domain/cart_item.dart` + sharedPrefsProvider | role-match |
| `lib/core/providers/favorites_notifier.dart` | provider/notifier | CRUD | `lib/features/shopping_list/domain/cart_item.dart` + sharedPrefsProvider | role-match |
| `lib/core/providers/coin_notifier.dart` | provider/notifier | CRUD | `lib/features/smart_coins/domain/coin_transaction.dart` + sharedPrefsProvider | role-match |
| `lib/core/data/mock_data.dart` | utility/data | batch | `lib/features/auth/domain/user.dart`, `lib/features/profile/domain/product.dart` | role-match |
| `lib/features/auth/presentation/login_screen.dart` | component | request-response | `lib/features/home/presentation/home_screen.dart` | role-match |
| `lib/features/smart_coins/domain/coin_transaction.dart` | model | transform | `lib/features/auth/domain/user.dart` | exact (fix WR-02) |
| `lib/features/profile/domain/product.dart` | model | transform | `lib/features/auth/domain/user.dart` | exact (fix WR-01 tags) |
| `test/providers/*_notifier_test.dart` (6 new test files) | test | request-response | `test/repositories/shared_prefs_test.dart` | role-match |

---

## Pattern Assignments

### `lib/routing/router_notifier.dart` (provider, event-driven) — MODIFY (fix CR-02)

**Analog:** `lib/routing/router_notifier.dart` lines 1–29 (current buggy version — replace entirely)

**Current buggy pattern** (lines 5–26):
```dart
// CURRENT — single-slot Listenable breaks contract (CR-02)
// AutoDisposeAsyncNotifier risks dispose before redirect fires (CR-03 side-effect)
class RouterNotifier extends AutoDisposeAsyncNotifier<void> implements Listenable {
  VoidCallback? _routerListener;         // single-slot: only ONE listener

  @override
  Future<void> build() async {
    listenSelf((_, __) => _routerListener?.call());
  }

  String? redirect(BuildContext context, GoRouterState state) {
    return null;  // guard inactive (Phase 1 placeholder)
  }

  @override
  void addListener(VoidCallback listener) => _routerListener = listener;

  @override
  void removeListener(VoidCallback listener) => _routerListener = null;
}

final routerNotifierProvider =
    AutoDisposeAsyncNotifierProvider<RouterNotifier, void>(RouterNotifier.new);
```

**Replacement imports pattern** — copy from current file lines 1–3, add `material.dart`:
```dart
import 'package:flutter/material.dart';   // ChangeNotifier lives here
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/providers/user_notifier.dart';  // new dependency
import 'app_routes.dart';                        // new dependency
```

**Fixed core pattern** — replace class + provider declaration entirely:
```dart
// Fix CR-02: ChangeNotifier mixin replaces single-slot Listenable
// Fix CR-03 (companion): remove AutoDispose — GoRouter must hold notifier alive
class RouterNotifier extends AsyncNotifier<void> with ChangeNotifier {
  @override
  Future<void> build() async {
    // Watches UserNotifier — Riverpod rebuilds this Notifier on user state change
    ref.watch(userNotifierProvider);
    // Propagate Notifier state change → GoRouter.refreshListenable
    listenSelf((_, __) => notifyListeners());
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final user = ref.read(userNotifierProvider);
    final isOnLogin = state.matchedLocation == AppRoutes.login;

    if (user == null) return AppRoutes.login;   // not authenticated → force /login
    if (isOnLogin) return AppRoutes.home;        // authenticated + on /login → go home
    return null;                                  // no redirect needed
  }
}

// No autoDispose — GoRouter holds a reference to this notifier for the app's lifetime
final routerNotifierProvider =
    AsyncNotifierProvider<RouterNotifier, void>(RouterNotifier.new);
```

---

### `lib/routing/app_router.dart` (config, request-response) — MODIFY (fix CR-03)

**Analog:** `lib/routing/app_router.dart` lines 28–38 (current buggy `goRouterProvider`)

**Current buggy pattern** (lines 28–38):
```dart
// CURRENT — ref.watch causes GoRouter recreation on every auth state change (CR-03)
final goRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider.notifier);  // BUG: watch not read
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.home,   // BUG: causes flash (Phase 2 pitfall 3)
    debugLogDiagnostics: true,         // BUG: should be kDebugMode-guarded
    ...
  );
});
```

**Fixed pattern** — replace only the `goRouterProvider` declaration (lines 28–99 body stays, only 3 lines change):
```dart
// Fix CR-03: ref.read (not ref.watch) — GoRouter is built ONCE
final goRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.read(routerNotifierProvider.notifier); // read, not watch
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.login,        // Phase 2: /login; redirect handles session
    debugLogDiagnostics: kDebugMode,         // guard with kDebugMode
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [ /* unchanged */ ],
  );
});
```

**Additional import needed** (add to existing imports block):
```dart
import 'package:flutter/foundation.dart' show kDebugMode;  // for kDebugMode guard
```

---

### `lib/core/providers/user_notifier.dart` (notifier, request-response) — NEW

**Analog:** `lib/core/persistence/shared_preferences_provider.dart` (import pattern) + `lib/features/auth/domain/user.dart` (model usage)

**Imports pattern** — modeled on how other files import providers and domain models:
```dart
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_data.dart';
import '../persistence/shared_preferences_provider.dart';
import '../../features/auth/domain/user.dart';
```

**Core NotifierProvider pattern** — based on CLAUDE.md constraints (NotifierProvider, not StateNotifierProvider):
```dart
class UserNotifier extends Notifier<User?> {
  static const _key = 'lista_smart_user';

  @override
  User? build() {
    // ref.watch in build() is correct — re-reads prefs if provider changes
    final prefs = ref.watch(sharedPreferencesProvider);
    final json = prefs.getString(_key);
    if (json == null) return null;
    try {
      return User.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      return null; // corrupted data → null session (safe fallback)
    }
  }

  void login() {
    final user = MockData.user;
    state = user;
    _persist(user);
  }

  void logout() {
    state = null;
    ref.read(sharedPreferencesProvider).remove(_key);
  }

  void _persist(User user) {
    ref.read(sharedPreferencesProvider)  // ref.read in mutation — never ref.watch
        .setString(_key, jsonEncode(user.toJson()));
  }
}

// Top-level declaration — never inside class or function (CLAUDE.md)
final userNotifierProvider = NotifierProvider<UserNotifier, User?>(UserNotifier.new);
```

**Key reference:** `lib/features/auth/domain/user.dart` lines 19–33 — `User.fromJson` / `User.toJson` already implemented; use directly, do not reimplement.

---

### `lib/core/providers/cart_notifier.dart` (notifier, CRUD) — NEW

**Analog:** `lib/features/shopping_list/domain/cart_item.dart` (model with toJson/fromJson) + sharedPrefsProvider pattern from `user_notifier.dart`

**Model reference** (`lib/features/shopping_list/domain/cart_item.dart` lines 1–55):
```dart
// CartItem.fromJson and toJson already exist — use them directly
factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
      productId: json['productId'] as String,
      // ... all fields cast and typed
    );
Map<String, dynamic> toJson() => { 'productId': productId, ... };
CartItem copyWith({...}) => CartItem(...);  // immutable update pattern
```

**Imports pattern**:
```dart
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../persistence/shared_preferences_provider.dart';
import '../../features/shopping_list/domain/cart_item.dart';
```

**Core CRUD pattern**:
```dart
class CartNotifier extends Notifier<List<CartItem>> {
  static const _key = 'lista_smart_cart';

  @override
  List<CartItem> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => CartItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  void addItem(CartItem item) {
    final idx = state.indexWhere((e) => e.productId == item.productId);
    if (idx >= 0) {
      state = [
        ...state.sublist(0, idx),
        state[idx].copyWith(quantity: state[idx].quantity + 1),
        ...state.sublist(idx + 1),
      ];
    } else {
      state = [...state, item];
    }
    _persist();
  }

  void removeItem(String productId) {
    state = state.where((e) => e.productId != productId).toList();
    _persist();
  }

  void clear() {
    state = [];
    _persist();
  }

  void _persist() {
    ref.read(sharedPreferencesProvider)
        .setString(_key, jsonEncode(state.map((e) => e.toJson()).toList()));
  }
}

final cartProvider = NotifierProvider<CartNotifier, List<CartItem>>(CartNotifier.new);
```

---

### `lib/core/providers/favorites_notifier.dart` (notifier, CRUD) — NEW

**Analog:** Same pattern as `cart_notifier.dart` but simpler — `List<String>` (productIds), use `getStringList`/`setStringList` instead of JSON encode.

**Imports pattern**:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../persistence/shared_preferences_provider.dart';
```

**Core pattern** — note `getStringList`/`setStringList` (no JSON encode needed for `List<String>`):
```dart
class FavoritesNotifier extends Notifier<List<String>> {
  static const _key = 'lista_smart_favorites';

  @override
  List<String> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getStringList(_key) ?? [];
  }

  void toggle(String productId) {
    if (state.contains(productId)) {
      state = state.where((id) => id != productId).toList();
    } else {
      state = [...state, productId];
    }
    ref.read(sharedPreferencesProvider).setStringList(_key, state);
  }

  bool isFavorite(String productId) => state.contains(productId);
}

final favoritesProvider =
    NotifierProvider<FavoritesNotifier, List<String>>(FavoritesNotifier.new);
```

---

### `lib/core/providers/coin_notifier.dart` (notifier, CRUD) — NEW

**Analog:** `lib/features/smart_coins/domain/coin_transaction.dart` (model) + cart_notifier pattern for persistence

**Model reference** (`lib/features/smart_coins/domain/coin_transaction.dart` lines 20–26, WR-02 fix needed):
```dart
// CURRENT — DateTime.parse throws on corrupt data (WR-02)
createdAt: DateTime.parse(json['createdAt'] as String),

// FIXED — use in CoinNotifier, and fix domain file too (see domain fix section below)
createdAt: DateTime.tryParse(json['createdAt'] as String)
    ?? DateTime.fromMillisecondsSinceEpoch(0),
```

**Imports pattern**:
```dart
import 'dart:convert';

import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_data.dart';
import '../persistence/shared_preferences_provider.dart';
import '../../features/smart_coins/domain/coin_transaction.dart';
import '../providers/user_notifier.dart';
```

**CoinState value object** — `@immutable` pattern from `lib/features/auth/domain/user.dart` lines 1–2:
```dart
@immutable
class CoinState {
  const CoinState({required this.balance, required this.transactions});
  final int balance;
  final List<CoinTransaction> transactions;

  CoinState copyWith({int? balance, List<CoinTransaction>? transactions}) =>
      CoinState(
        balance: balance ?? this.balance,
        transactions: transactions ?? this.transactions,
      );
}
```

**Core notifier pattern**:
```dart
class CoinNotifier extends Notifier<CoinState> {
  static const _balanceKey = 'lista_smart_coins_balance';
  static const _txKey = 'lista_smart_coins_tx';

  @override
  CoinState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final user = ref.watch(userNotifierProvider);  // fallback for initial coinBalance

    final balance = prefs.getInt(_balanceKey) ?? user?.coinBalance ?? 0;

    final rawTx = prefs.getString(_txKey);
    List<CoinTransaction> transactions;
    if (rawTx != null) {
      try {
        final list = jsonDecode(rawTx) as List<dynamic>;
        transactions = list
            .map((e) => CoinTransaction.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        transactions = MockData.initialTransactions;
      }
    } else {
      transactions = MockData.initialTransactions;
    }

    return CoinState(balance: balance, transactions: transactions);
  }

  void addCoins(int amount, String description) {
    final tx = CoinTransaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      description: description,
      amount: amount,
      createdAt: DateTime.now(),
    );
    state = state.copyWith(
      balance: state.balance + amount,
      transactions: [tx, ...state.transactions],
    );
    _persist();
  }

  void _persist() {
    final prefs = ref.read(sharedPreferencesProvider);
    prefs.setInt(_balanceKey, state.balance);
    prefs.setString(
      _txKey,
      jsonEncode(state.transactions.map((t) => t.toJson()).toList()),
    );
  }
}

final coinProvider = NotifierProvider<CoinNotifier, CoinState>(CoinNotifier.new);
```

---

### `lib/core/data/mock_data.dart` (utility, batch) — NEW

**Analog:** `lib/features/auth/domain/user.dart` (User model), `lib/features/profile/domain/product.dart` (Product model), `lib/features/smart_coins/domain/coin_transaction.dart` (CoinTransaction model)

**Imports pattern** — imports all domain models this file instantiates:
```dart
import '../../features/auth/domain/user.dart';
import '../../features/profile/domain/product.dart';
import '../../features/smart_coins/domain/coin_transaction.dart';
```

**Core pattern** — `abstract class` with `static const` fields (no instantiation):
```dart
abstract class MockData {
  // User — const because User constructor is const (lib/features/auth/domain/user.dart line 6)
  static const User user = User(
    id: 'jose_augusto_001',
    name: 'José Augusto',
    email: 'jose.rocha@zorte.com.br',
    address: 'Criciúma, SC',
    coinBalance: 750,  // D-14: starts at Prata tier
  );

  // Products — const List with const Product instances
  // Product constructor is const (lib/features/profile/domain/product.dart line 6)
  static const List<Product> products = [ /* 10-15 items, 4 categories */ ];

  // Supermarket distances — plain Map<String, double> (no model in Phase 2)
  static const Map<String, double> supermarketDistances = {
    'Bistek': 2.3,
    'Giassi': 3.7,
    'Angeloni': 4.1,
    'Atacadão': 6.8,
  };

  // Transactions — getter (NOT const) because DateTime is not const in Dart
  static List<CoinTransaction> get initialTransactions => [ /* 2 bootstrap txns */ ];
}
```

**Product list pattern** — copy `Product` constructor signature from `lib/features/profile/domain/product.dart` lines 6–13:
```dart
// Each Product entry:
Product(
  id: 'p01',
  name: 'Leite Integral',
  brand: 'Tirol',
  category: 'Laticínios',
  imageUrl: '',
  averagePrice: 5.49,
  tags: ['laticínio', 'bebida'],  // WR-01 note: List<String> in const context is fine
),
```

---

### `lib/features/auth/presentation/login_screen.dart` (component, request-response) — REPLACE

**Analog:** `lib/features/home/presentation/home_screen.dart` (Scaffold + AppColors pattern) + routing pattern from `lib/routing/app_router.dart`

**Current placeholder** (lines 1–20 — replace entirely):
```dart
// CURRENT: StatelessWidget placeholder with no UI
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(child: Text('Login', ...)),
    );
  }
}
```

**Imports pattern** — extends home_screen pattern with Riverpod + Lucide + dart:ui for BackdropFilter:
```dart
import 'dart:ui';  // ImageFilter.blur

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/providers/user_notifier.dart';
```

**ConsumerStatefulWidget pattern** — required because has local state (`_isLoading`, `_isPasswordVisible`) AND uses ref:
```dart
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  // Controllers — ephemeral UI state, NOT in Riverpod (CLAUDE.md)
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    // ref.read in event handler — NEVER ref.watch (CLAUDE.md)
    ref.read(userNotifierProvider.notifier).login();
    // Guard setState — widget may be disposed after redirect
    if (mounted) setState(() => _isLoading = false);
  }
  // ...
}
```

**Scaffold + Stack layout** — extend from `home_screen.dart` Scaffold pattern (line 11):
```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: AppColors.background,  // #09090B — same as all screens
    body: Stack(
      children: [
        // Layer 1: Blobs (positioned, no blur yet)
        // Layer 2: BackdropFilter over blobs (full coverage)
        // Layer 3: Centered login card
      ],
    ),
  );
}
```

**Glassmorphic card** — `AppColors.surface` + `AppSizes` tokens (from `app_colors.dart` + `app_sizes.dart`):
```dart
Container(
  decoration: BoxDecoration(
    color: AppColors.surface.withValues(alpha: 0.7),        // withValues not withOpacity (Flutter 3.27+)
    borderRadius: BorderRadius.circular(AppSizes.radiusXL), // 24.0
    border: Border.all(
      color: Colors.white.withValues(alpha: 0.1),
      width: 1.0,
    ),
  ),
  padding: const EdgeInsets.all(AppSizes.spacingL), // 24.0
)
```

**TextFormField with LucideIcons** — icon constants from `lucide_icons` (verified in pub-cache):
```dart
TextFormField(
  controller: _emailController,
  decoration: InputDecoration(
    hintText: 'seu@email.com',
    hintStyle: const TextStyle(color: AppColors.textSecondary),
    prefixIcon: const Icon(LucideIcons.mail, color: AppColors.textSecondary),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.radiusM)),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSizes.radiusM),
      borderSide: const BorderSide(color: AppColors.primary),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSizes.radiusM),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
    ),
  ),
)
```

**Password field toggle** — `LucideIcons.eye` / `LucideIcons.eyeOff` suffix (D-03):
```dart
TextFormField(
  controller: _passwordController,
  obscureText: !_isPasswordVisible,
  decoration: InputDecoration(
    prefixIcon: const Icon(LucideIcons.lock, color: AppColors.textSecondary),
    suffixIcon: IconButton(
      icon: Icon(
        _isPasswordVisible ? LucideIcons.eyeOff : LucideIcons.eye,
        color: AppColors.textSecondary,
      ),
      onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
    ),
    // ... same border pattern as email field
  ),
)
```

**FilledButton + loading state** — Material 3, `AppColors.primary` background (D-04):
```dart
_isLoading
    ? const SizedBox(
        height: 48,
        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      )
    : SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: _handleLogin,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.background,  // dark text on lime green
            padding: const EdgeInsets.symmetric(vertical: AppSizes.spacingM),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusL), // 16.0
            ),
          ),
          child: const Text('Avançar'),
        ),
      )
```

**BackdropFilter layout order** — CRITICAL: filter applies to layers BELOW it in Stack:
```dart
Stack(
  children: [
    // 1. Blobs BELOW filter
    Positioned(top: -80, right: -60,
      child: ClipOval(child: Container(
        width: 300, height: 300,
        color: AppColors.primary.withValues(alpha: 0.25),
      ))),
    Positioned(bottom: -60, left: -80,
      child: ClipOval(child: Container(
        width: 220, height: 220,
        color: AppColors.primary.withValues(alpha: 0.15),
      ))),
    // 2. BackdropFilter ABOVE blobs — blurs everything below
    Positioned.fill(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
        child: Container(color: Colors.transparent),  // child required by Flutter
      ),
    ),
    // 3. Login card ABOVE filter — not blurred
    Center(child: SingleChildScrollView(child: /* card */)),
  ],
)
```

---

### `lib/features/smart_coins/domain/coin_transaction.dart` (model, transform) — MODIFY (fix WR-02)

**Analog:** `lib/features/auth/domain/user.dart` lines 19–25 — safe `fromJson` with null coalescing

**Current bug** (line 25):
```dart
// CURRENT — throws FormatException on corrupt SharedPreferences data (WR-02)
createdAt: DateTime.parse(json['createdAt'] as String),
```

**Fix** — change one line, keep everything else identical:
```dart
// FIXED — DateTime.tryParse with safe fallback
createdAt: DateTime.tryParse(json['createdAt'] as String)
    ?? DateTime.fromMillisecondsSinceEpoch(0),
```

---

### `lib/features/profile/domain/product.dart` (model, transform) — MODIFY (fix WR-01)

**Context:** WR-01 flags `List<String> tags` field in `@immutable` class. The `copyWith` and `toJson` already use `List<String>.from(tags)` for safe copying (line 41). The `fromJson` already does `.cast<String>()` (line 30). The class itself is sound for Phase 2 `const` usage in `MockData`. No structural change required — WR-01 was pre-fixed in Phase 1 via `List<String>.from(tags)` in `toJson`.

**Verification** (lines 33–41 — already correct):
```dart
// Already immutable-safe in toJson
Map<String, dynamic> toJson() => {
  // ...
  'tags': List<String>.from(tags),  // defensive copy — WR-01 resolved
};
```

**Decision:** No change needed to `product.dart` — WR-01 is already mitigated. Planner should note this as a verify-only task, not a code change.

---

### Test files — `test/providers/*_notifier_test.dart` and `test/routing/router_notifier_test.dart` and `test/widgets/login_screen_test.dart` (test, request-response) — NEW

**Analog:** `test/repositories/shared_prefs_test.dart` (ProviderContainer + override pattern) + `test/models/models_test.dart` (group/test structure)

**Test import pattern** (`test/repositories/shared_prefs_test.dart` lines 1–5):
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lista_smart/core/persistence/shared_preferences_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
```

**ProviderContainer + SharedPreferences override pattern** (`test/repositories/shared_prefs_test.dart` lines 18–27):
```dart
test('description', () async {
  SharedPreferences.setMockInitialValues({});   // reset to empty each test
  final prefs = await SharedPreferences.getInstance();

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
  );
  addTearDown(container.dispose);  // always dispose ProviderContainer

  // Act
  container.read(someNotifierProvider.notifier).someMethod();

  // Assert
  expect(container.read(someNotifierProvider), /* expected */);
});
```

**group/test structure** (from `test/models/models_test.dart` lines 8–11):
```dart
void main() {
  group('UserNotifier', () {
    test('build() returns null when no session persisted', () async { ... });
    test('login() sets state to MockData.user', () async { ... });
    test('login() persists user to SharedPreferences', () async { ... });
    test('logout() clears state and removes key', () async { ... });
  });
}
```

**Widget test pattern** — for `login_screen_test.dart`, use `pumpWidget` with `ProviderScope`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lista_smart/features/auth/presentation/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ...

testWidgets('renders email field, password field, Avançar button', (tester) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const MaterialApp(home: LoginScreen()),
    ),
  );

  expect(find.text('Avançar'), findsOneWidget);
  // ...
});
```

---

## Shared Patterns

### SharedPreferences Injection
**Source:** `lib/core/persistence/shared_preferences_provider.dart` lines 1–8
**Apply to:** All new Notifier files (`user_notifier.dart`, `cart_notifier.dart`, `favorites_notifier.dart`, `coin_notifier.dart`)
```dart
// Access in Notifier.build() — ref.watch (reactive):
final prefs = ref.watch(sharedPreferencesProvider);

// Access in mutation methods — ref.read (non-reactive):
ref.read(sharedPreferencesProvider).setString(_key, value);
```

### NotifierProvider Declaration
**Source:** CLAUDE.md constraint — "Never use StateNotifierProvider"
**Apply to:** All 4 new Notifier files
```dart
// Pattern: top-level, outside any class or function
final someProvider = NotifierProvider<SomeNotifier, SomeState>(SomeNotifier.new);
// NOT: AutoDisposeNotifierProvider (unless explicitly needed)
// NOT: StateNotifierProvider (deprecated, prohibited)
```

### Immutable Domain Model
**Source:** `lib/features/auth/domain/user.dart` lines 1–2, `lib/features/shopping_list/domain/cart_item.dart` lines 1–2
**Apply to:** `CoinState` in `coin_notifier.dart`
```dart
import 'package:flutter/foundation.dart' show immutable;

@immutable
class SomeState {
  const SomeState({required this.field});
  final Type field;
  SomeState copyWith({Type? field}) => SomeState(field: field ?? this.field);
}
```

### Color Tokens (withValues not withOpacity)
**Source:** `lib/routing/app_router.dart` line 117 — `AppColors.primary.withValues(alpha: 0.2)`
**Apply to:** `login_screen.dart` blob colors, card decoration
```dart
// Correct (Flutter 3.27+):
AppColors.primary.withValues(alpha: 0.25)
Colors.white.withValues(alpha: 0.1)
// Wrong (deprecated):
AppColors.primary.withOpacity(0.25)
```

### Import Path Convention
**Source:** All existing files use relative imports (not package imports within `lib/`)
**Apply to:** All new files
```dart
// Correct — relative imports within lib/:
import '../persistence/shared_preferences_provider.dart';
import '../../features/auth/domain/user.dart';
// Wrong for internal files:
import 'package:lista_smart/core/persistence/shared_preferences_provider.dart';
```

### ref.read vs ref.watch Discipline
**Source:** CLAUDE.md "Do not call ref.watch inside initState, dispose, or event handlers"
**Apply to:** All Notifier mutation methods and LoginScreen `_handleLogin()`
```dart
// In Notifier.build() — watch is correct:
final prefs = ref.watch(sharedPreferencesProvider);

// In mutation methods (_persist, login, logout, addItem, etc.) — read only:
ref.read(sharedPreferencesProvider).setString(_key, value);

// In widget event handler — read only:
ref.read(userNotifierProvider.notifier).login();
```

---

## No Analog Found

All files in this phase have close analogs or are self-referencing modifications. No files require falling back to RESEARCH.md patterns exclusively.

---

## Metadata

**Analog search scope:** `lib/` (all 21 dart files), `test/` (3 test files)
**Files scanned:** 21 source + 3 test = 24 total
**Pattern extraction date:** 2026-06-01

**Codebase state summary:**
- Notifier pattern: no existing `NotifierProvider` in codebase yet — `RouterNotifier` uses `AutoDisposeAsyncNotifier` (to be replaced). Phase 2 introduces the first `Notifier<T>` instances.
- All domain models (`User`, `Product`, `CartItem`, `CoinTransaction`, `Vehicle`) exist with `toJson`/`fromJson`/`copyWith` — ready for Notifier consumption.
- `SharedPreferences` sentinel provider pattern established in Phase 1 — all new Notifiers follow it.
- `AppColors`, `AppSizes`, `appTheme` fully configured — `LoginScreen` consumes without changes to theme.
- Test infrastructure: `ProviderContainer` + `SharedPreferences.setMockInitialValues` pattern established in `test/repositories/shared_prefs_test.dart` — all new provider tests copy this pattern.
