# Phase 5: Price Registration + Profile - Pattern Map

**Mapped:** 2026-06-02
**Files analyzed:** 9 (5 create, 4 modify)
**Analogs found:** 9 / 9

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/features/price_registration/presentation/scanner_screen.dart` | component (wizard) | event-driven | `lib/features/shopping_list/presentation/shopping_list_screen.dart` | exact |
| `lib/features/profile/presentation/profile_screen.dart` | component (form) | CRUD | `lib/features/auth/presentation/login_screen.dart` | exact |
| `lib/features/auth/domain/user.dart` | model | transform | `lib/features/auth/domain/user.dart` (self — extend) | self |
| `lib/core/providers/user_notifier.dart` | provider/notifier | CRUD | `lib/core/providers/coin_notifier.dart` | exact |
| `lib/core/data/mock_data.dart` | config/data | batch | `lib/core/data/mock_data.dart` (self — extend) | self |
| `pubspec.yaml` | config | — | `pubspec.yaml` (self — add dep) | self |
| `test/providers/user_notifier_test.dart` | test | CRUD | `test/providers/user_notifier_test.dart` (self — extend) | self |
| `test/features/scanner/scanner_screen_test.dart` | test | event-driven | `test/features/smart_coins/store_screen_test.dart` | role-match |
| `test/features/profile/profile_screen_test.dart` | test | CRUD | `test/features/smart_coins/store_screen_test.dart` | role-match |

---

## Pattern Assignments

### `lib/features/price_registration/presentation/scanner_screen.dart` (component/wizard, event-driven)

**Analog:** `lib/features/shopping_list/presentation/shopping_list_screen.dart`

**Imports pattern** (lines 1-12):
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/providers/coin_notifier.dart';
import '../../../routing/app_routes.dart';
```
Add `import 'package:confetti/confetti.dart';` for the confetti package.

**ConsumerStatefulWidget declaration pattern** (shopping_list_screen.dart lines 18-26):
```dart
class ShoppingListScreen extends ConsumerStatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  ConsumerState<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends ConsumerState<ShoppingListScreen> {
  bool _loadingComparison = false;
  // ...
}
```
For ScannerScreen, the state class needs three local fields instead of one:
```dart
class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  late final PageController _pageController;
  late final ConfettiController _confettiController;
  bool _loading = false;
```

**initState/dispose pattern** (shopping_list_screen.dart has no controllers to init — use login_screen.dart lines 21-29 as the dispose model):
```dart
// login_screen.dart lines 21-29
@override
void dispose() {
  _emailController.dispose();
  _passwordController.dispose();
  super.dispose();
}
```
For ScannerScreen:
```dart
@override
void initState() {
  super.initState();
  _pageController = PageController();
  _confettiController = ConfettiController(duration: const Duration(seconds: 3));
}

@override
void dispose() {
  _pageController.dispose();
  _confettiController.dispose();
  super.dispose();
}
```

**Loading overlay pattern** (shopping_list_screen.dart lines 382-425 — exact source of truth):
```dart
// shopping_list_screen.dart lines 123-125 — outer Stack wrapping Scaffold
return Stack(
  children: [
    Scaffold(
      backgroundColor: AppColors.background,
      // ...body content...
    ),
    // Loading overlay — lines 382-425
    if (_loadingComparison)
      Container(
        color: Colors.black.withValues(alpha: 0.6),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(AppSizes.spacingL),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSizes.radiusL),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: AppColors.primary),
                // ...label...
              ],
            ),
          ),
        ),
      ),
  ],
);
```
For ScannerScreen, simplify to a plain centered spinner (no dialog box):
```dart
if (_loading)
  Container(
    color: Colors.black.withValues(alpha: 0.6),
    child: const Center(
      child: CircularProgressIndicator(color: AppColors.primary),
    ),
  ),
```

**Async handler with mounted guard** (shopping_list_screen.dart lines 56-78 — `_compareWithLoading()`):
```dart
Future<void> _compareWithLoading() async {
  setState(() => _loadingComparison = true);
  ref.read(coinProvider.notifier).spendCoins(_comparisonCoinCost, '...');
  await Future<void>.delayed(const Duration(milliseconds: 1600));

  if (!mounted) return;  // <-- MANDATORY after every await
  setState(() => _loadingComparison = false);
  context.push(AppRoutes.comparisonResult);
}
```
Copy this pattern directly for `_startScan()`:
```dart
Future<void> _startScan() async {
  setState(() => _loading = true);
  await Future<void>.delayed(const Duration(seconds: 2));
  if (!mounted) return;
  setState(() => _loading = false);
  _pageController.nextPage(
    duration: const Duration(milliseconds: 300),
    curve: Curves.easeInOut,
  );
}
```

**ref.read in handler (not build)** (shopping_list_screen.dart line 57, 72):
```dart
// In handler — ref.read only:
final coinBalance = ref.read(coinProvider).balance;
ref.read(coinProvider.notifier).spendCoins(...);

// In build() — ref.watch only:
final cart = ref.watch(cartProvider);
final coinBalance = ref.watch(coinProvider).balance;
```

**Glassmorphic card pattern** (shopping_list_screen.dart lines 177-187, store_screen.dart lines 57-63):
```dart
Container(
  decoration: BoxDecoration(
    color: AppColors.surface.withValues(alpha: 0.7),
    borderRadius: BorderRadius.circular(AppSizes.radiusXL),
    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
  ),
  padding: const EdgeInsets.all(AppSizes.spacingL),
  child: /* ... */,
)
```

**TweenAnimationBuilder scale pattern** (store_screen.dart lines 126-139 — for the coin icon animation in Step 3):
```dart
TweenAnimationBuilder<double>(
  tween: Tween(begin: 0.0, end: progress),
  duration: const Duration(milliseconds: 600),
  curve: Curves.easeOut,
  builder: (_, value, __) => /* ... */,
)
```
Adapt for scale: `tween: Tween(begin: 0.5, end: 1.0)` wrapping the coin icon.

---

### `lib/features/profile/presentation/profile_screen.dart` (component/form, CRUD)

**Analog:** `lib/features/auth/presentation/login_screen.dart`

**Imports pattern** (login_screen.dart lines 1-10):
```dart
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/providers/user_notifier.dart';
```
ProfileScreen also needs:
```dart
import '../../../core/providers/coin_notifier.dart';
import '../../../core/data/mock_data.dart';
```

**ConsumerStatefulWidget + TextEditingController pattern** (login_screen.dart lines 11-29):
```dart
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
```
ProfileScreen uses `late final` + `initState` init (because initial text comes from state):
```dart
class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _vehicleCtrl;
  late final TextEditingController _efficiencyCtrl;

  @override
  void initState() {
    super.initState();
    final user = ref.read(userNotifierProvider); // synchronous read — safe in initState
    _nameCtrl = TextEditingController(text: user?.name ?? '');
    _emailCtrl = TextEditingController(text: user?.email ?? '');
    _addressCtrl = TextEditingController(text: user?.address ?? '');
    _vehicleCtrl = TextEditingController(
      text: user?.vehicleModel.isNotEmpty == true
          ? user!.vehicleModel
          : MockData.vehicle.model,
    );
    _efficiencyCtrl = TextEditingController(
      text: user?.fuelEfficiency != 0.0
          ? user!.fuelEfficiency.toString()
          : MockData.vehicle.fuelEfficiencyKmPerLiter.toString(),
    );
  }
```

**TextField styling pattern** (login_screen.dart lines 112-132 — email field):
```dart
TextFormField(
  controller: _emailController,
  keyboardType: TextInputType.emailAddress,
  style: const TextStyle(color: AppColors.textMain),
  decoration: InputDecoration(
    hintText: 'seu@email.com',
    hintStyle: const TextStyle(color: AppColors.textSecondary),
    prefixIcon: const Icon(LucideIcons.mail, color: AppColors.textSecondary),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSizes.radiusM),
    ),
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

**FilledButton pattern** (login_screen.dart lines 179-194):
```dart
SizedBox(
  width: double.infinity,
  child: FilledButton(
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
),
```

**SnackBar pattern** (store_screen.dart lines 292-295 — `_PackageCard.build()`):
```dart
ScaffoldMessenger.of(context).showSnackBar(SnackBar(
  content: Text('+${coins + bonus} moedas adicionadas!'),
  backgroundColor: AppColors.success,
));
```
For ProfileScreen, use `AppColors.primary` per D-07:
```dart
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
    content: Text('Perfil atualizado!'),
    backgroundColor: AppColors.primary,
  ),
);
```

**Impact stats derived from coinProvider** (store_screen.dart lines 36-41):
```dart
final state = ref.watch(coinProvider);
final recent = state.transactions.take(10).toList();
```
For ProfileScreen scan count:
```dart
final coinState = ref.watch(coinProvider);
final scannedCount = coinState.transactions
    .where((tx) => tx.description == 'Cadastro de nota fiscal')
    .length;
```

---

### `lib/features/auth/domain/user.dart` (model, transform) — MODIFY

**Analog:** Self (extend the existing pattern)

**Existing fromJson pattern** (user.dart lines 19-25 — nullable read with fallback):
```dart
factory User.fromJson(Map<String, dynamic> json) => User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      address: json['address'] as String? ?? '',       // nullable String? with fallback
      coinBalance: json['coinBalance'] as int? ?? 0,   // nullable int? with fallback
    );
```
Apply the same nullable-cast-with-fallback pattern for new fields:
```dart
vehicleModel: json['vehicleModel'] as String? ?? '',
fuelEfficiency: (json['fuelEfficiency'] as num?)?.toDouble() ?? 0.0,
```
Note: `fuelEfficiency` requires `as num?` (not `as double?`) because JSON numbers may decode as `int` when they lack a decimal point; `.toDouble()` normalizes.

**Existing toJson pattern** (user.dart lines 27-33):
```dart
Map<String, dynamic> toJson() => {
      'id': id,
      'name': name,
      'email': email,
      'address': address,
      'coinBalance': coinBalance,
    };
```
Add two entries: `'vehicleModel': vehicleModel,` and `'fuelEfficiency': fuelEfficiency,`.

**Existing copyWith pattern** (user.dart lines 35-48):
```dart
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
```
Add `String? vehicleModel` and `double? fuelEfficiency` parameters with the same `?? this.field` pattern.

---

### `lib/core/providers/user_notifier.dart` (provider/notifier, CRUD) — MODIFY

**Analog:** `lib/core/providers/coin_notifier.dart` (same Notifier pattern, same `_persist()` call)

**Existing mutating method pattern** (user_notifier.dart lines 35-41 — `spendCoins()`):
```dart
void spendCoins(int amount) {
  final current = state;
  if (current == null) return;           // null guard — user must be logged in
  final updated = current.copyWith(coinBalance: current.coinBalance - amount);
  state = updated;
  _persist(updated);
}
```
Copy this pattern for `updateProfile()`:
```dart
void updateProfile({
  required String name,
  required String email,
  required String address,
  required String vehicleModel,
  required double fuelEfficiency,
}) {
  final current = state;
  if (current == null) return;
  final updated = current.copyWith(
    name: name,
    email: email,
    address: address,
    vehicleModel: vehicleModel,
    fuelEfficiency: fuelEfficiency,
  );
  state = updated;
  _persist(updated);
}
```

**_persist() method** (user_notifier.dart lines 43-45):
```dart
void _persist(User user) {
  ref.read(sharedPreferencesProvider).setString(_key, jsonEncode(user.toJson()));
}
```
No change needed — `user.toJson()` will automatically include the new fields once the model is extended.

---

### `lib/core/data/mock_data.dart` (config/data) — MODIFY

**Analog:** Self (add vehicle defaults to MockData.user)

**Existing MockData.user constant** (mock_data.dart lines 8-14):
```dart
static const User user = User(
  id: 'jose_augusto_001',
  name: 'José Augusto',
  email: 'jose.rocha@zorte.com.br',
  address: 'Criciúma, SC',
  coinBalance: 750,
);
```
After User model is extended, update to include vehicle defaults:
```dart
static const User user = User(
  id: 'jose_augusto_001',
  name: 'José Augusto',
  email: 'jose.rocha@zorte.com.br',
  address: 'Criciúma, SC',
  coinBalance: 750,
  vehicleModel: 'Fiat Uno',    // NEW — matches MockData.vehicle.model
  fuelEfficiency: 12.0,        // NEW — matches MockData.vehicle.fuelEfficiencyKmPerLiter
);
```

---

### `pubspec.yaml` (config) — MODIFY

Add under `dependencies:` section, following the existing package alphabetical/grouping convention:
```yaml
confetti: ^0.7.0
```

---

### `test/providers/user_notifier_test.dart` (test, CRUD) — MODIFY

**Analog:** Self (extend existing test group)

**Existing test structure** (user_notifier_test.dart lines 10-20 — container setup):
```dart
void main() {
  group('UserNotifier', () {
    test('build() returns null when no session persisted', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      expect(container.read(userNotifierProvider), isNull);
    });
```
Add new tests inside the same `group('UserNotifier', ...)` block:
```dart
test('updateProfile() updates all fields in state', () async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);

  container.read(userNotifierProvider.notifier).login();
  container.read(userNotifierProvider.notifier).updateProfile(
    name: 'Novo Nome',
    email: 'novo@email.com',
    address: 'Novo Endereço',
    vehicleModel: 'Honda Civic',
    fuelEfficiency: 14.5,
  );

  final user = container.read(userNotifierProvider);
  expect(user!.name, equals('Novo Nome'));
  expect(user.vehicleModel, equals('Honda Civic'));
  expect(user.fuelEfficiency, equals(14.5));
});

test('updateProfile() persists new fields to SharedPreferences', () async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);

  container.read(userNotifierProvider.notifier).login();
  container.read(userNotifierProvider.notifier).updateProfile(
    name: 'X', email: 'x@x.com', address: '', vehicleModel: 'Gol', fuelEfficiency: 11.0,
  );

  // Simulate restart — new container reads from same prefs
  final container2 = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(container2.dispose);

  final user2 = container2.read(userNotifierProvider);
  expect(user2!.vehicleModel, equals('Gol'));
  expect(user2.fuelEfficiency, equals(11.0));
});

test('updateProfile() is no-op when user is null', () async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);

  // Not logged in — state is null
  container.read(userNotifierProvider.notifier).updateProfile(
    name: 'X', email: 'x@x.com', address: '', vehicleModel: '', fuelEfficiency: 0,
  );

  expect(container.read(userNotifierProvider), isNull); // still null
});
```

---

### `test/features/scanner/scanner_screen_test.dart` (test, event-driven) — CREATE

**Analog:** `test/features/smart_coins/store_screen_test.dart`

**Test file structure** (store_screen_test.dart lines 1-34 — helpers + setUpAll):
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lista_smart/core/persistence/shared_preferences_provider.dart';
import 'package:lista_smart/core/providers/coin_notifier.dart';
import 'package:lista_smart/features/smart_coins/presentation/store_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _makeContainer({int balance = 0}) async {
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
  ]);
  addTearDown(container.dispose);
  if (balance > 0) {
    container.read(coinProvider.notifier).addCoins(balance, 'seed');
  }
  return container;
}

Future<void> _pumpScreen(WidgetTester tester, ProviderContainer container) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: StoreScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    WidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });
  // tests...
}
```
For scanner_screen_test.dart, adapt with `userNotifierProvider` override (ScannerScreen needs user logged in for coin provider):
```dart
import 'package:lista_smart/features/price_registration/presentation/scanner_screen.dart';
// ...
// Wave 0 tests use skip: true — they define the requirement before implementation
testWidgets('PREG-01: Step 1 renders QR Code and Camera buttons', (tester) async {
  // ...
}, skip: true);
```

---

### `test/features/profile/profile_screen_test.dart` (test, CRUD) — CREATE

**Analog:** `test/features/smart_coins/store_screen_test.dart`

**Widget test pump pattern** (store_screen_test.dart lines 26-34):
```dart
Future<void> _pumpScreen(WidgetTester tester, ProviderContainer container) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: StoreScreen()),
    ),
  );
  await tester.pumpAndSettle();
}
```
For ProfileScreen, the container must provide both `sharedPreferencesProvider` and have user logged in:
```dart
Future<ProviderContainer> _makeContainer() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
  ]);
  addTearDown(container.dispose);
  container.read(userNotifierProvider.notifier).login();
  return container;
}
```

---

## Shared Patterns

### `withValues(alpha:)` — Never `withOpacity()`
**Source:** Enforced project-wide — shopping_list_screen.dart lines 139, 180, 385, 393; store_screen.dart lines 60, 97; login_screen.dart lines 64, 71, 104, 125, 160
**Apply to:** Every `Color` opacity call in all new files
```dart
// CORRECT:
AppColors.surface.withValues(alpha: 0.7)
Colors.black.withValues(alpha: 0.6)
Colors.white.withValues(alpha: 0.1)
AppColors.primary.withValues(alpha: 0.12)

// WRONG (never use):
AppColors.surface.withOpacity(0.7)
```

### `ref.read` in handlers, `ref.watch` in build
**Source:** shopping_list_screen.dart lines 57 (read in handler), 82-85 (watch in build)
**Apply to:** All button handlers in ScannerScreen and ProfileScreen
```dart
// In build() — declarative:
final coinState = ref.watch(coinProvider);
final user = ref.watch(userNotifierProvider);

// In onPressed / async handlers — imperative:
ref.read(coinProvider.notifier).addCoins(10, 'Cadastro de nota fiscal');
ref.read(userNotifierProvider.notifier).updateProfile(...);
```

### `if (!mounted) return;` after every `await`
**Source:** shopping_list_screen.dart line 75
**Apply to:** `_startScan()` in ScannerScreen; `_save()` in ProfileScreen before SnackBar
```dart
await Future<void>.delayed(const Duration(seconds: 2));
if (!mounted) return;  // mandatory — widget may be disposed during delay
setState(() => _loading = false);
```

### `NotifierProvider<T, S>` declaration
**Source:** user_notifier.dart line 48, coin_notifier.dart line 108
**Apply to:** No new providers this phase — existing providers only modified
```dart
final userNotifierProvider = NotifierProvider<UserNotifier, User?>(UserNotifier.new);
final coinProvider = NotifierProvider<CoinNotifier, CoinState>(CoinNotifier.new);
```

### DateFormat for dates
**Source:** store_screen.dart line 224 (history dates)
**Apply to:** Step 2 receipt date display in ScannerScreen
```dart
DateFormat('dd/MM/yyyy').format(tx.createdAt)
// For receipt: DateFormat('dd/MM/yyyy', 'pt_BR').format(DateTime.now())
```

### NumberFormat for BRL currency
**Source:** shopping_list_screen.dart line 14
**Apply to:** Receipt total in ScannerScreen Step 2; savings stat in ProfileScreen
```dart
final _brl = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$', decimalDigits: 2);
_brl.format(87.43) // → "R$ 87,43"
```

### Glassmorphic card decoration
**Source:** shopping_list_screen.dart lines 177-187; store_screen.dart lines 57-63; login_screen.dart lines 99-107
**Apply to:** Step 1 method cards, Step 2 receipt card in ScannerScreen; section cards in ProfileScreen
```dart
BoxDecoration(
  color: AppColors.surface.withValues(alpha: 0.7),
  borderRadius: BorderRadius.circular(AppSizes.radiusXL),
  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
)
```

### ProviderContainer test setup with SharedPreferences mock
**Source:** user_notifier_test.dart lines 12-19; store_screen_test.dart lines 13-23
**Apply to:** All new test files
```dart
SharedPreferences.setMockInitialValues({});
final prefs = await SharedPreferences.getInstance();
final container = ProviderContainer(
  overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
);
addTearDown(container.dispose);
```

### UncontrolledProviderScope for widget tests
**Source:** store_screen_test.dart lines 26-34
**Apply to:** scanner_screen_test.dart, profile_screen_test.dart
```dart
await tester.pumpWidget(
  UncontrolledProviderScope(
    container: container,
    child: const MaterialApp(home: TargetScreen()),
  ),
);
await tester.pumpAndSettle();
```

---

## No Analog Found

All files have codebase analogs. No file requires RESEARCH.md patterns as the sole reference.

---

## Metadata

**Analog search scope:** `lib/features/`, `lib/core/`, `test/`
**Files scanned:** 9 source files read in full
**Key anti-patterns confirmed in codebase:**
- `withOpacity()` is absent — `withValues(alpha:)` used everywhere
- `StateNotifierProvider` is absent — `NotifierProvider` only
- `ref.watch` in handlers is absent — `ref.read` in all event handlers

**Pattern extraction date:** 2026-06-02
