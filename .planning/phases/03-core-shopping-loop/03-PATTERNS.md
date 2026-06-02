# Phase 3: Core Shopping Loop — Pattern Map

**Mapped:** 2026-06-01
**Files analyzed:** 22 new/modified files
**Analogs found:** 18 / 22

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/features/profile/domain/product.dart` | model | transform | `lib/features/auth/domain/user.dart` | exact |
| `lib/features/profile/domain/nutritional_info.dart` | model | transform | `lib/features/profile/domain/vehicle.dart` | exact |
| `lib/core/data/mock_data.dart` | config | batch | `lib/core/data/mock_data.dart` (existing structure) | self |
| `lib/core/providers/products_provider.dart` | provider | request-response | `lib/core/providers/cart_notifier.dart` (provider decl pattern) | role-match |
| `lib/core/providers/prices_provider.dart` | provider | request-response | `lib/core/providers/cart_notifier.dart` | role-match |
| `lib/core/providers/vehicle_provider.dart` | provider | request-response | `lib/core/providers/cart_notifier.dart` | role-match |
| `lib/core/providers/search_query_notifier.dart` | provider | event-driven | `lib/core/providers/favorites_notifier.dart` | role-match |
| `lib/core/providers/view_mode_notifier.dart` | provider | event-driven | `lib/core/providers/favorites_notifier.dart` | role-match |
| `lib/core/providers/fuel_toggle_notifier.dart` | provider | event-driven | `lib/core/providers/favorites_notifier.dart` | exact |
| `lib/core/providers/filtered_products_provider.dart` | provider | transform | `lib/core/providers/cart_notifier.dart` (derived pattern) | role-match |
| `lib/core/providers/comparison_results_provider.dart` | provider | transform | `lib/core/providers/cart_notifier.dart` + `favorites_notifier.dart` | role-match |
| `lib/routing/app_routes.dart` | config | — | `lib/routing/app_routes.dart` (existing) | self |
| `lib/routing/app_router.dart` | config | request-response | `lib/routing/app_router.dart` (existing) | self |
| `lib/features/home/presentation/home_screen.dart` | component | request-response | `lib/features/auth/presentation/login_screen.dart` | role-match |
| `lib/features/home/presentation/product_card_grid.dart` | component | request-response | `lib/features/auth/presentation/login_screen.dart` | role-match |
| `lib/features/home/presentation/product_card_list.dart` | component | request-response | `lib/features/auth/presentation/login_screen.dart` | role-match |
| `lib/features/home/presentation/product_detail_screen.dart` | component | request-response | `lib/features/auth/presentation/login_screen.dart` | exact |
| `lib/features/home/presentation/nutritional_info_bottom_sheet.dart` | component | request-response | `lib/features/auth/presentation/login_screen.dart` | role-match |
| `lib/features/shopping_list/presentation/shopping_list_screen.dart` | component | CRUD | `lib/features/auth/presentation/login_screen.dart` | role-match |
| `lib/features/price_comparison/presentation/price_comparison_screen.dart` | component | request-response | `lib/features/auth/presentation/login_screen.dart` | role-match |
| `lib/routing/app_routes.dart` | config | — | `lib/routing/app_routes.dart` (existing) | self |

---

## Pattern Assignments

### `lib/features/profile/domain/product.dart` (model, extend)

**Analog:** `lib/features/auth/domain/user.dart` and `lib/features/profile/domain/vehicle.dart`

**Current model pattern** (`lib/features/profile/domain/product.dart` lines 1–61 — full file):
```dart
import 'package:flutter/foundation.dart' show immutable;

@immutable
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.imageUrl,
    required this.averagePrice,
    required this.tags,
  });

  final String id;
  final String name;
  final String brand;
  final String category;
  final String imageUrl;
  final double averagePrice;
  final List<String> tags;

  factory Product.fromJson(Map<String, dynamic> json) => Product( ... );
  Map<String, dynamic> toJson() => { ... };
  Product copyWith({ ... }) => Product( ... );
}
```

**Extension strategy — add fields with defaults to avoid breaking 12 MockData constructors:**
```dart
// NEW fields — all have defaults so existing MockData.products const constructors compile unchanged
final String ean;           // default: ''
final String subcategory;   // default: ''
final String department;    // default: ''
final NutritionalInfo? nutritionalInfo;  // nullable — null means no data

// Add to constructor:
this.ean = '',
this.subcategory = '',
this.department = '',
this.nutritionalInfo,
```

**Pattern rule (from `lib/features/auth/domain/user.dart` lines 9–10):** Optional fields use `this.field = defaultValue` in the constructor — no need for `required`. Example: `this.address = ''`, `this.coinBalance = 0`.

**copyWith pattern** (`lib/features/auth/domain/user.dart` lines 35–48):
```dart
Product copyWith({
  String? id,
  String? name,
  // ... all existing fields ...
  String? ean,
  String? subcategory,
  String? department,
  NutritionalInfo? nutritionalInfo,
}) =>
    Product(
      id: id ?? this.id,
      // ... all existing fields ...
      ean: ean ?? this.ean,
      subcategory: subcategory ?? this.subcategory,
      department: department ?? this.department,
      nutritionalInfo: nutritionalInfo ?? this.nutritionalInfo,
    );
```

---

### `lib/features/profile/domain/nutritional_info.dart` (model, new)

**Analog:** `lib/features/profile/domain/vehicle.dart` (lines 1–39 — full file)

**Imports pattern** (line 1):
```dart
import 'package:flutter/foundation.dart' show immutable;
```

**Model structure** — copy Vehicle's immutable pattern exactly:
```dart
@immutable
class NutritionalInfo {
  const NutritionalInfo({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.sodium,
    required this.servingSize,
  });

  final double calories;   // kcal per 100g
  final double protein;    // g
  final double carbs;      // g
  final double fat;        // g
  final double fiber;      // g
  final double sodium;     // mg
  final String servingSize; // e.g. '200ml'

  factory NutritionalInfo.fromJson(Map<String, dynamic> json) => NutritionalInfo(
        calories: (json['calories'] as num).toDouble(),
        protein: (json['protein'] as num).toDouble(),
        carbs: (json['carbs'] as num).toDouble(),
        fat: (json['fat'] as num).toDouble(),
        fiber: (json['fiber'] as num).toDouble(),
        sodium: (json['sodium'] as num).toDouble(),
        servingSize: json['servingSize'] as String,
      );

  Map<String, dynamic> toJson() => {
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'fiber': fiber,
        'sodium': sodium,
        'servingSize': servingSize,
      };
}
```

**Vehicle analog** (`lib/features/profile/domain/vehicle.dart` lines 15–19) shows double field fromJson pattern:
```dart
fuelEfficiencyKmPerLiter: (json['fuelEfficiencyKmPerLiter'] as num).toDouble(),
```
Apply the same `(json['field'] as num).toDouble()` cast to all double fields in NutritionalInfo.

---

### `lib/core/data/mock_data.dart` (config, extend)

**Analog:** `lib/core/data/mock_data.dart` (existing structure — self)

**Existing import pattern** (`lib/core/data/mock_data.dart` lines 1–3):
```dart
import '../../features/auth/domain/user.dart';
import '../../features/profile/domain/product.dart';
import '../../features/smart_coins/domain/coin_transaction.dart';
```

**Add these imports:**
```dart
import '../../features/profile/domain/vehicle.dart';
```

**Existing static const pattern** (`lib/core/data/mock_data.dart` lines 6–12):
```dart
abstract class MockData {
  static const User user = User( ... );
  static const List<Product> products = [ ... ];
  static const Map<String, double> supermarketDistances = { ... };
```

**Add these new statics (same style):**
```dart
// Fuel price — R$/L, fixed in Phase 3
static const double fuelPrice = 6.50;

// Default vehicle — fuelEfficiencyKmPerLiter is the correct field name (NOT fuelEfficiency)
static const Vehicle vehicle = Vehicle(
  id: 'vehicle_default',
  model: 'Fiat Uno',
  fuelEfficiencyKmPerLiter: 12.0,
);

// Prices: productId → supermarket → price (R$)
static const Map<String, Map<String, double>> prices = {
  'p01': {'Bistek': 5.29, 'Giassi': 5.49, 'Angeloni': 5.69, 'Atacadão': 4.99},
  'p02': {'Bistek': 37.90, 'Giassi': 39.90, 'Angeloni': 41.50, 'Atacadão': 35.80},
  // ... one entry per product id p01–p12
};
```

**CRITICAL — existing products list** (`lib/core/data/mock_data.dart` lines 14–127): The 12 `const Product(...)` constructors must NOT be broken. New fields `ean`, `subcategory`, `department`, `nutritionalInfo` must all have defaults in the `Product` constructor so these 12 calls compile without modification.

---

### `lib/core/providers/products_provider.dart` (provider, read-only)

**Analog:** `lib/core/providers/cart_notifier.dart` (provider declaration pattern, line 54)

**Full file pattern:**
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_data.dart';
import '../../features/profile/domain/product.dart';

final productsProvider = Provider<List<Product>>((ref) {
  return MockData.products;
});
```

**Import path convention** (from `lib/core/providers/cart_notifier.dart` lines 1–7): use relative imports with `../` and `../../features/`.

---

### `lib/core/providers/prices_provider.dart` (provider, read-only)

**Analog:** Same `Provider<T>` declaration as `products_provider.dart` above.

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_data.dart';

final pricesProvider = Provider<Map<String, Map<String, double>>>((ref) {
  return MockData.prices;
});
```

---

### `lib/core/providers/vehicle_provider.dart` (provider, read-only)

**Analog:** Same `Provider<T>` pattern.

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_data.dart';
import '../../features/profile/domain/vehicle.dart';

final vehicleProvider = Provider<Vehicle>((ref) {
  return MockData.vehicle;
});
```

---

### `lib/core/providers/search_query_notifier.dart` (provider, event-driven)

**Analog:** `lib/core/providers/favorites_notifier.dart` (lines 1–27 — full file)

**Notifier declaration pattern** (`lib/core/providers/favorites_notifier.dart` lines 5–27):
```dart
class FavoritesNotifier extends Notifier<List<String>> {
  static const _key = 'lista_smart_favorites';

  @override
  List<String> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getStringList(_key) ?? [];
  }

  void toggle(String productId) { ... }
}

final favoritesProvider =
    NotifierProvider<FavoritesNotifier, List<String>>(FavoritesNotifier.new);
```

**SearchQueryNotifier** — same Notifier skeleton, simpler state (no SharedPrefs):
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void update(String query) => state = query;
  void clear() => state = '';
}

final searchQueryProvider =
    NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);
```

---

### `lib/core/providers/view_mode_notifier.dart` (provider, event-driven)

**Analog:** `lib/core/providers/favorites_notifier.dart` — same Notifier pattern, no SharedPrefs.

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ViewMode { grid, list }

class ViewModeNotifier extends Notifier<ViewMode> {
  @override
  ViewMode build() => ViewMode.grid;

  void setGrid() => state = ViewMode.grid;
  void setList() => state = ViewMode.list;
}

final viewModeProvider =
    NotifierProvider<ViewModeNotifier, ViewMode>(ViewModeNotifier.new);
```

---

### `lib/core/providers/fuel_toggle_notifier.dart` (provider, event-driven + SharedPrefs)

**Analog:** `lib/core/providers/favorites_notifier.dart` (lines 1–27 — full file) — exact match. FuelToggle is a bool persisted in SharedPrefs; Favorites is a List<String> persisted in SharedPrefs.

**Imports pattern** (`lib/core/providers/favorites_notifier.dart` lines 1–3):
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../persistence/shared_preferences_provider.dart';
```

**build() pattern with SharedPrefs** (`lib/core/providers/favorites_notifier.dart` lines 9–12):
```dart
@override
List<String> build() {
  final prefs = ref.watch(sharedPreferencesProvider);
  return prefs.getStringList(_key) ?? [];
}
```

**Persist-on-write pattern** (`lib/core/providers/favorites_notifier.dart` lines 14–20):
```dart
void toggle(String productId) {
  // ... compute new state ...
  ref.read(sharedPreferencesProvider).setStringList(_key, state);
}
```

**FuelToggleNotifier — apply same pattern:**
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../persistence/shared_preferences_provider.dart';

class FuelToggleNotifier extends Notifier<bool> {
  static const _key = 'lista_smart_fuel_toggle';

  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool(_key) ?? true;  // default: enabled
  }

  void toggle() {
    state = !state;
    ref.read(sharedPreferencesProvider).setBool(_key, state);
  }
}

final fuelToggleProvider =
    NotifierProvider<FuelToggleNotifier, bool>(FuelToggleNotifier.new);
```

---

### `lib/core/providers/filtered_products_provider.dart` (provider, transform/derived)

**Analog:** No exact analog — derived `Provider<T>` that watches two other providers. Closest pattern is the `Provider<GoRouter>` in `lib/routing/app_router.dart` (lines 29–100) which uses `ref.read` on another provider inside a `Provider`.

**Key difference:** `filteredProductsProvider` uses `ref.watch` (not `ref.read`) so it rebuilds when either dependency changes.

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/profile/domain/product.dart';
import 'products_provider.dart';
import 'search_query_notifier.dart';

final filteredProductsProvider = Provider<List<Product>>((ref) {
  final products = ref.watch(productsProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase().trim();
  if (query.isEmpty) return products;
  return products.where((p) {
    return p.name.toLowerCase().contains(query) ||
           p.brand.toLowerCase().contains(query) ||
           p.category.toLowerCase().contains(query);
  }).toList();
});
```

---

### `lib/core/providers/comparison_results_provider.dart` (provider, transform/derived)

**Analog:** `lib/core/providers/cart_notifier.dart` (import structure) + `lib/core/providers/favorites_notifier.dart` (Notifier pattern). This is a complex derived `Provider<List<SupermarketTotal>>`.

**Imports pattern** — follow cart_notifier.dart's multi-import style (`lib/core/providers/cart_notifier.dart` lines 1–7):
```dart
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../persistence/shared_preferences_provider.dart';
import '../../features/shopping_list/domain/cart_item.dart';
```

**Full pattern for comparison_results_provider.dart:**
```dart
import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_data.dart';
import 'cart_notifier.dart';
import 'fuel_toggle_notifier.dart';
import 'prices_provider.dart';
import 'vehicle_provider.dart';

@immutable
class SupermarketTotal {
  const SupermarketTotal({
    required this.supermarket,
    required this.productsCost,
    required this.fuelCost,
    required this.distanceKm,
    required this.totalCost,
  });
  final String supermarket;
  final double productsCost;
  final double fuelCost;
  final double distanceKm;
  final double totalCost;
}

final comparisonResultsProvider = Provider<List<SupermarketTotal>>((ref) {
  final cart = ref.watch(cartProvider);
  final prices = ref.watch(pricesProvider);
  final vehicle = ref.watch(vehicleProvider);
  final fuelToggle = ref.watch(fuelToggleProvider);

  const fuelPrice = MockData.fuelPrice;
  final distances = MockData.supermarketDistances;

  return distances.entries.map((entry) {
    final supermarket = entry.key;
    final distanceKm = entry.value;

    final productsCost = cart.fold<double>(0.0, (sum, item) {
      final price = prices[item.productId]?[supermarket] ?? item.unitPrice;
      return sum + price * item.quantity;
    });

    // CRITICAL: use vehicle.fuelEfficiencyKmPerLiter (not fuelEfficiency)
    final fuelCost = fuelToggle
        ? (distanceKm * 2 / vehicle.fuelEfficiencyKmPerLiter) * fuelPrice
        : 0.0;

    return SupermarketTotal(
      supermarket: supermarket,
      productsCost: productsCost,
      fuelCost: fuelCost,
      distanceKm: distanceKm,
      totalCost: productsCost + fuelCost,
    );
  }).toList()
    ..sort((a, b) => a.totalCost.compareTo(b.totalCost));
});
```

---

### `lib/routing/app_routes.dart` (config, extend)

**Analog:** `lib/routing/app_routes.dart` (existing, lines 1–8 — full file)

**Existing pattern:**
```dart
abstract class AppRoutes {
  static const String login = '/login';
  static const String home = '/home';
  static const String shoppingList = '/shopping-list';
  static const String comparison = '/comparison';
  static const String store = '/store';
  static const String profile = '/profile';
}
```

**Add new constants (same style):**
```dart
// Subroutes — full absolute paths for use with context.push()
static const String productDetail = '/home/product/:productId';  // pattern string
static const String scanner = '/scanner';
static const String comparisonResult = '/shopping-list/comparison';

// Helper to build concrete product detail path
static String productDetailPath(String productId) =>
    '/home/product/$productId';
```

**CRITICAL:** Do NOT change the value of `shoppingList` — it is `'/shopping-list'`, not `'/lista'`. The comparison subroute will be `'/shopping-list/comparison'`.

---

### `lib/routing/app_router.dart` (config, modify)

**Analog:** `lib/routing/app_router.dart` (existing, lines 1–149 — full file)

**Existing StatefulShellBranch pattern** (lines 51–58):
```dart
StatefulShellBranch(
  navigatorKey: _tab0Key,
  routes: [
    GoRoute(
      path: AppRoutes.home,
      builder: (_, __) => const HomeScreen(),
    ),
  ],
),
```

**Modified tab0 with subroute** — add `routes:` list inside the GoRoute:
```dart
StatefulShellBranch(
  navigatorKey: _tab0Key,
  routes: [
    GoRoute(
      path: AppRoutes.home,
      builder: (_, __) => const HomeScreen(),
      routes: [
        GoRoute(
          path: 'product/:productId',  // RELATIVE — no leading /
          builder: (context, state) {
            final productId = state.pathParameters['productId']!;
            return ProductDetailScreen(productId: productId);
          },
        ),
      ],
    ),
  ],
),
```

**Modified tab1 with subroute:**
```dart
StatefulShellBranch(
  navigatorKey: _tab1Key,
  routes: [
    GoRoute(
      path: AppRoutes.shoppingList,  // '/shopping-list'
      builder: (_, __) => const ShoppingListScreen(),
      routes: [
        GoRoute(
          path: 'comparison',  // RELATIVE — resolves to '/shopping-list/comparison'
          builder: (_, __) => const PriceComparisonScreen(),
        ),
      ],
    ),
  ],
),
```

**Modified tab2 (Scanner placeholder)** — replace PriceComparisonScreen with ScannerScreen stub:
```dart
StatefulShellBranch(
  navigatorKey: _tab2Key,
  routes: [
    GoRoute(
      path: AppRoutes.scanner,  // '/scanner' — new constant
      builder: (_, __) => const ScannerScreen(),
    ),
  ],
),
```

**NavigationDestination update** (lines 124–146) — tab2 label and icon:
```dart
NavigationDestination(
  icon: Icon(LucideIcons.scanLine),  // was: LucideIcons.barChart2
  label: 'Scanner',                  // was: 'Comparar'
),
```

**Existing `withValues(alpha:)` pattern** (line 118 — must be preserved in all new code):
```dart
indicatorColor: AppColors.primary.withValues(alpha: 0.2),
```

---

### `lib/features/home/presentation/home_screen.dart` (component, major redesign)

**Analog:** `lib/features/auth/presentation/login_screen.dart` (lines 1–207 — full file)

**ConsumerStatefulWidget pattern** (`lib/features/auth/presentation/login_screen.dart` lines 11–16):
```dart
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}
```

**ConsumerState with dispose** (lines 18–29):
```dart
class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
```

**ref.read in event handler** (line 34 — NEVER ref.watch in handlers):
```dart
ref.read(userNotifierProvider.notifier).login();
```

**Scaffold + backgroundColor pattern** (line 40):
```dart
return Scaffold(
  backgroundColor: AppColors.background,
  body: ...
```

**HomeScreen structure** — use `ConsumerWidget` (not ConsumerStatefulWidget) since HomeScreen has no local mutable state; the TextField for search should be managed with a local `TextEditingController` via ConsumerStatefulWidget:

```dart
// Imports pattern for HomeScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/providers/filtered_products_provider.dart';
import '../../../core/providers/search_query_notifier.dart';
import '../../../core/providers/view_mode_notifier.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  // ...
}
```

**FilledButton style** (lines 181–196 — the canonical button pattern in this project):
```dart
FilledButton(
  onPressed: _handleLogin,
  style: FilledButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.background,
    padding: const EdgeInsets.symmetric(vertical: AppSizes.spacingM),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSizes.radiusL),
    ),
  ),
  child: const Text('Avançar'),
),
```

**TextFormField style** (lines 112–131 — text field with border decoration):
```dart
TextFormField(
  controller: _emailController,
  style: const TextStyle(color: AppColors.textMain),
  decoration: InputDecoration(
    hintStyle: const TextStyle(color: AppColors.textSecondary),
    prefixIcon: const Icon(LucideIcons.mail, color: AppColors.textSecondary),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSizes.radiusM),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSizes.radiusM),
      borderSide: const BorderSide(color: AppColors.primary),
    ),
  ),
),
```

**Glassmorphic card pattern** (lines 98–107):
```dart
Container(
  decoration: BoxDecoration(
    color: AppColors.surface.withValues(alpha: 0.7),
    borderRadius: BorderRadius.circular(AppSizes.radiusXL),
    border: Border.all(
      color: Colors.white.withValues(alpha: 0.1),
      width: 1.0,
    ),
  ),
  padding: const EdgeInsets.all(AppSizes.spacingL),
```

---

### `lib/features/home/presentation/product_card_grid.dart` (component, new)

**Analog:** `lib/features/auth/presentation/login_screen.dart` — ConsumerWidget pattern

**This should be a `ConsumerWidget`** (no local mutable state):
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/providers/favorites_notifier.dart';
import '../../../routing/app_routes.dart';
import '../../profile/domain/product.dart';

class ProductCardGrid extends ConsumerWidget {
  const ProductCardGrid({required this.product, super.key});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFav = ref.watch(favoritesProvider.select(
      (favs) => favs.contains(product.id),
    ));
    // ...
  }
}
```

**Card surface pattern** (from `lib/features/auth/presentation/login_screen.dart` lines 98–107):
Use `AppColors.surface` background + `Colors.white.withValues(alpha: 0.1)` border + `AppSizes.radiusXL` radius.

**Tap navigation** — `context.push(AppRoutes.productDetailPath(product.id))` (use `push` not `go` for sub-routes).

---

### `lib/features/home/presentation/product_card_list.dart` (component, new)

**Analog:** Same as `product_card_grid.dart` above — `ConsumerWidget` with same imports and favorites pattern. Difference is layout: horizontal `Row` instead of vertical `Column`.

---

### `lib/features/home/presentation/product_detail_screen.dart` (component, new)

**Analog:** `lib/features/auth/presentation/login_screen.dart` — `ConsumerStatefulWidget` pattern (needs local state for bottom sheet trigger).

**Route parameter access** — the `productId` is passed as a constructor param (not read from router state inside the widget):
```dart
class ProductDetailScreen extends ConsumerWidget {
  const ProductDetailScreen({required this.productId, super.key});

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider);
    final product = products.firstWhere((p) => p.id == productId);
    final prices = ref.watch(pricesProvider);
    final productPrices = prices[productId] ?? {};
    // ...
  }
}
```

**showModalBottomSheet pattern** — trigger from button `onPressed` using `ref.read` (not `ref.watch`).

**"Adicionar ao Carrinho" action** — use `ref.read(cartProvider.notifier).addItem(...)` in onPressed.

---

### `lib/features/home/presentation/nutritional_info_bottom_sheet.dart` (component, new)

**Analog:** `lib/features/auth/presentation/login_screen.dart` — simple widget, but can be `StatelessWidget` since it receives data as constructor params.

**No analog exists in codebase for bottom sheets** — use RESEARCH.md Pattern 11 (DraggableScrollableSheet).

---

### `lib/features/shopping_list/presentation/shopping_list_screen.dart` (component, major)

**Analog:** `lib/features/auth/presentation/login_screen.dart` — `ConsumerWidget` or `ConsumerStatefulWidget` (needs AlertDialog for clear confirmation).

**Imports pattern:**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/providers/cart_notifier.dart';
import '../../../core/providers/fuel_toggle_notifier.dart';
import '../../../routing/app_routes.dart';
```

**AlertDialog for clear confirmation** — trigger with `showDialog` in a button `onPressed` (ref.read context):
```dart
await showDialog<bool>(
  context: context,
  builder: (ctx) => AlertDialog(
    backgroundColor: AppColors.surface,
    title: const Text('Limpar lista?', style: TextStyle(color: AppColors.textMain)),
    actions: [
      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
      FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Limpar')),
    ],
  ),
);
```

**"Comparar" button** — fixed at bottom, visible only when cart is non-empty:
```dart
// In Scaffold's bottomNavigationBar or a persistent bottom widget
if (cart.isNotEmpty)
  FilledButton(
    onPressed: () => context.push(AppRoutes.comparisonResult),
    // use context.push (not go) — subroute within same tab
    child: const Text('Comparar Preços'),
  ),
```

---

### `lib/features/price_comparison/presentation/price_comparison_screen.dart` (component, new)

**Analog:** `lib/features/auth/presentation/login_screen.dart` — `ConsumerWidget` (read-only display).

**Imports pattern:**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/providers/comparison_results_provider.dart';
import '../../../core/providers/fuel_toggle_notifier.dart';
```

**Best-price highlight** — the first item in `comparisonResults` (sorted ascending by `totalCost`) is the cheapest. Highlight with `AppColors.primary` border:
```dart
final results = ref.watch(comparisonResultsProvider);
// results[0] is cheapest — already sorted by comparisonResultsProvider
final isLowest = index == 0;

Container(
  decoration: BoxDecoration(
    border: Border.all(
      color: isLowest ? AppColors.primary : Colors.white.withValues(alpha: 0.1),
      width: isLowest ? 2.0 : 1.0,
    ),
    borderRadius: BorderRadius.circular(AppSizes.radiusL),
    color: AppColors.surface,
  ),
```

---

## Shared Patterns

### Immutable Model
**Source:** `lib/features/auth/domain/user.dart` (lines 1–2) and `lib/features/profile/domain/vehicle.dart` (line 1)
**Apply to:** All new domain model files (`NutritionalInfo`)
```dart
import 'package:flutter/foundation.dart' show immutable;

@immutable
class MyModel {
  const MyModel({ ... });
```

### Notifier + SharedPreferences Persistence
**Source:** `lib/core/providers/favorites_notifier.dart` (lines 1–27, full file)
**Apply to:** `fuel_toggle_notifier.dart`

Pattern: `ref.watch(sharedPreferencesProvider)` in `build()` to load initial state; `ref.read(sharedPreferencesProvider).setXxx()` in mutation methods.

### Notifier Without Persistence
**Source:** `lib/core/providers/favorites_notifier.dart` (Notifier class structure only)
**Apply to:** `search_query_notifier.dart`, `view_mode_notifier.dart`

Pattern: Same `class Foo extends Notifier<T>` structure + `final fooProvider = NotifierProvider<FooNotifier, T>(FooNotifier.new);` declaration.

### Immutable State Update (List)
**Source:** `lib/core/providers/cart_notifier.dart` (lines 25–36)
**Apply to:** `CartNotifier.incrementQuantity`, `CartNotifier.decrementQuantity` (new methods)
```dart
// Spread operator pattern — never mutate state directly
state = [
  ...state.sublist(0, idx),
  state[idx].copyWith(quantity: state[idx].quantity + 1),
  ...state.sublist(idx + 1),
];
_persist();
```

### Alpha Opacity (NOT withOpacity)
**Source:** `lib/routing/app_router.dart` (line 118), `lib/features/auth/presentation/login_screen.dart` (lines 51, 105, 124)
**Apply to:** ALL new widgets — any color with transparency
```dart
// CORRECT:
AppColors.primary.withValues(alpha: 0.2)
Colors.white.withValues(alpha: 0.1)

// FORBIDDEN:
AppColors.primary.withOpacity(0.2)  // deprecated
```

### ref.watch vs ref.read Rule
**Source:** `lib/features/auth/presentation/login_screen.dart` (line 34 vs build method)
**Apply to:** ALL new ConsumerWidget and ConsumerStatefulWidget files

- `ref.watch(provider)` — only inside `build()` method
- `ref.read(provider)` — only inside event handlers (`onPressed`, `onChanged`, etc.)

### BRL Currency Formatting
**Source:** RESEARCH.md Pattern 12 (no existing analog in codebase — use intl package)
**Apply to:** `shopping_list_screen.dart`, `price_comparison_screen.dart`
```dart
import 'package:intl/intl.dart';

final _brl = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$', decimalDigits: 2);
// Usage: _brl.format(4.99) → 'R$ 4,99'
```

### Scaffold backgroundColor
**Source:** Every screen in the project (e.g., `lib/features/home/presentation/home_screen.dart` line 14)
**Apply to:** All new screens
```dart
return Scaffold(
  backgroundColor: AppColors.background,
  body: ...
);
```

### context.push vs context.go
**Source:** RESEARCH.md Pitfall 5 (no existing analog — first use of push in this phase)
**Apply to:** All navigation calls in new screens

- `context.go(route)` — tab-level navigation (FAB to Scanner, between main routes)
- `context.push(route)` — sub-route navigation (Home → ProductDetail, ShoppingList → Comparison)

---

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `lib/features/home/presentation/nutritional_info_bottom_sheet.dart` | component | request-response | No bottom sheet or modal exists in codebase yet — use RESEARCH.md Pattern 11 (DraggableScrollableSheet) |
| `lib/features/home/presentation/product_card_grid.dart` | component | request-response | No card grid widget exists in codebase — pattern derived from login_screen.dart Card/Container conventions |
| `lib/features/home/presentation/product_card_list.dart` | component | request-response | Same as above |

---

## Metadata

**Analog search scope:** `lib/core/providers/`, `lib/features/`, `lib/routing/`, `lib/core/data/`, `lib/core/constants/`
**Files scanned:** 16
**Pattern extraction date:** 2026-06-01

### Critical Field Name Warning
`Vehicle.fuelEfficiencyKmPerLiter` is the real field name (`lib/features/profile/domain/vehicle.dart` line 8). CONTEXT.md D-05 and RESEARCH.md Pitfall 3 both note the inconsistency. Every reference to this field in `comparison_results_provider.dart` and `vehicle_provider.dart` MUST use `fuelEfficiencyKmPerLiter`.

### Router Path Warning
The `comparison` subroute inside tab1's GoRoute must use `path: 'comparison'` (no leading `/`). See RESEARCH.md Pitfall 1. The existing `AppRoutes.comparison = '/comparison'` is for the OLD tab2 root route; the new constant should be `AppRoutes.comparisonResult = '/shopping-list/comparison'`.

### MockData Breaking Change Risk
The 12 `const Product(...)` constructors in `lib/core/data/mock_data.dart` (lines 15–127) must continue to compile. All new `Product` fields (`ean`, `subcategory`, `department`, `nutritionalInfo`) MUST have default values in the constructor. See RESEARCH.md Pitfall 4.
