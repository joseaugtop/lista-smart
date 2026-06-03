# Phase 5: Price Registration + Profile - Research

**Researched:** 2026-06-02
**Domain:** Flutter widget patterns — PageView wizard, confetti animation, User model extension, SharedPreferences migration
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01** — PageView + PageController inside `ScannerScreen` (ConsumerStatefulWidget). 3 pages inline, no sub-routes. Back button goes to previous page via controller.
- **D-02** — Step 1: two buttons (QR Code / Camera), both trigger 2s overlay loading (blur + CircularProgressIndicator). Same pattern as ShoppingListScreen._compareWithLoading().
- **D-03** — `confetti: ^0.7.0` package. ConfettiController with `duration: Duration(seconds: 3)`. Fires automatically on Step 3 page entry via `_confettiController.play()` in initState of Page 2. No delay.
- **D-04** — Fixed mock receipt: "Bistek Supermercados", DateTime.now(), R$87.43, 3-4 products from MockData.products.
- **D-05** — After Step 3 "Voltar para Home": `context.go(AppRoutes.scanner)` + `_pageController.jumpToPage(0)`. Stays on Scanner tab, resets for next use.
- **D-06** — User model gains `String vehicleModel` (default 'Fiat Uno') + `double fuelEfficiency` (default 12.0). UserNotifier gets `updateProfile()`. ShoppingListScreen/PriceComparisonScreen migrate to read fuelEfficiency from `userNotifierProvider` with fallback to MockData.vehicle.
- **D-07** — SnackBar 'Perfil atualizado!' with `AppColors.primary` as backgroundColor after saving profile.
- **D-08** — ProfileScreen is Tab 4 (standard tab, already registered in router).
- **D-09** — "Notas escaneadas" = real count from coinProvider.state.transactions where description == 'Cadastro de nota fiscal'. Others mocked (buscas: 47, economia: R$342,00).

### Claude's Discretion

- Layout interno do ProfileScreen (scroll vs. SliverAppBar)
- Organização visual dos campos de edição (seções separadas por Card vs. lista contínua)
- Ícone representativo de cada stat de impacto

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PREG-01 | Step 1 — user chooses QR or Photo; both simulate 2s progress indicator | D-02 loading overlay pattern verified in ShoppingListScreen |
| PREG-02 | Step 2 — user sees mock receipt (supermarket, date, total, items) and confirms | D-04 mock data from MockData.products; DateFormat confirmed in StoreScreen |
| PREG-03 | Step 3 — confetti animation, +10 coins shown, return button | D-03 confetti API verified from pub.dev docs |
| PREG-04 | On confirm (step 2), coin balance += 10 and transaction recorded | coinProvider.addCoins() API confirmed in codebase |
| PROF-01 | User can view/edit name, email, address | updateProfile() in UserNotifier; TextEditingController pattern |
| PROF-02 | User can edit vehicleModel and fuelEfficiency; save via SharedPreferences | User model extension; UserNotifier persistence pattern confirmed |
| PROF-03 | Profile shows impact stats: searches, scans, estimated savings | coinProvider.state.transactions filter confirmed |
</phase_requirements>

---

## Summary

Phase 5 delivers two independent flows wired into existing infrastructure. The ScannerScreen wizard replaces a placeholder with a 3-page PageView; all state is local (`PageController`, `ConfettiController`, `bool _loading`). The ProfileScreen replaces a placeholder with a scrollable edit form that extends the existing `User` model with two new fields and adds `updateProfile()` to `UserNotifier`.

The `confetti: ^0.7.0` package is the only new external dependency. In Dart pub semver, `^0.7.0` resolves to `>=0.7.0 <0.8.0`, so version 0.7.0 is fetched exactly — not the breaking 0.8.0 release. The `ConfettiController` is a `ChangeNotifier` that owns its own ticker internally; no `SingleTickerProviderStateMixin` is needed on the host widget. It must be `dispose()`d manually in the widget's `dispose()` method.

The User model migration is additive: new fields carry defaults (`vehicleModel: ''`, `fuelEfficiency: 0.0` as fromJson fallbacks) so users with old SharedPreferences data (missing the new keys) deserialize without error. MockData.user does not need to change — the default values are supplied in fromJson. ShoppingListScreen currently reads `MockData.vehicle.fuelEfficiencyKmPerLiter` directly; that read is migrated to `ref.watch(userNotifierProvider)?.fuelEfficiency ?? MockData.vehicle.fuelEfficiencyKmPerLiter`.

**Primary recommendation:** Implement in two independent plans — Plan 01 covers domain/provider changes (User model, UserNotifier.updateProfile, pubspec), Plan 02 covers ScannerScreen wizard, Plan 03 covers ProfileScreen, and Plan 04 covers tests and migration of vehicle reads. Alternatively, Plan 01 can be domain + scanner, Plan 02 profile.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| 3-step scan wizard (pages, loading, confetti) | UI Widget (local state) | CoinNotifier (side effect on confirm) | No routing needed — PageView with local PageController; coin mutation is a one-time event handler |
| Mock receipt data | MockData (const) | — | Fully static; no provider needed |
| Coin award (+10) | CoinNotifier | UserNotifier (balance shadow) | addCoins() already exists; UserNotifier.coinBalance is a shadow only used at initial hydration |
| Profile editing (name, email, address, vehicle) | UserNotifier | SharedPreferences | updateProfile() mutates state and persists synchronously |
| Impact stats | CoinNotifier (scan count) + local constants | — | Scan count derived from transactions; other two are compile-time constants |
| Tab reset after step 3 | go_router (context.go) + PageController (jumpToPage) | — | D-05 decision; go to same route resets branch navigator to root, PageController resets visual position |

---

## Standard Stack

### Core (already in pubspec.yaml — no changes except confetti)

| Library | Resolved Version | Purpose | Status |
|---------|-----------------|---------|--------|
| flutter_riverpod | 2.6.1 (^2.5.1) | NotifierProvider, ConsumerStatefulWidget | Already installed |
| go_router | 14.8.1 (^14.0.0) | context.go(), AppRoutes constants | Already installed |
| shared_preferences | 2.5.5 (^2.2.0) | UserNotifier persistence | Already installed |
| intl | 0.19.0 (^0.19.0) | DateFormat('dd/MM/yyyy') for receipt date | Already installed |
| lucide_icons | 0.257.0 (^0.257.0) | LucideIcons.qrCode, .camera, .fileText, etc. | Already installed |

### New Dependency

| Library | Constraint | Resolved Version | Purpose | Why |
|---------|-----------|-----------------|---------|-----|
| confetti | ^0.7.0 | 0.7.0 (locked — ^0.7.0 < 0.8.0 in Dart semver) | ConfettiWidget + ConfettiController | D-03 locked decision |

**Installation:**
```
flutter pub add confetti:^0.7.0
```
Or directly in pubspec.yaml dependencies section:
```yaml
confetti: ^0.7.0
```

**Version verification:** [VERIFIED: pub.dev] — confetti 0.7.0 exists on pub.dev (published ~4 years ago). Current latest is 0.8.0 but Dart semver `^0.7.0` = `>=0.7.0 <0.8.0` so resolves to 0.7.0 exactly.

---

## Package Legitimacy Audit

> slopcheck was not available at research time. Manual verification performed via pub.dev and Dart pub cache inspection.

| Package | Registry | Age | Downloads | Source Repo | slopcheck | Disposition |
|---------|----------|-----|-----------|-------------|-----------|-------------|
| confetti | pub.dev | ~4 years (v0.7.0) | Listed on pub.dev with verified publisher (funwith.app) | github.com/funwithflutter/flutter_confetti | unavailable | Approved — legitimate, well-established Flutter package with MIT license |

**Packages removed due to slopcheck [SLOP] verdict:** none

**Packages flagged as suspicious [SUS]:** none

*slopcheck was unavailable at research time. The confetti package is tagged `[CITED: pub.dev/packages/confetti]` based on direct pub.dev verification of publisher identity, source repository, and 4-year publication history. The planner may add a `checkpoint:human-verify` before the pubspec install step if desired.*

---

## Architecture Patterns

### System Architecture Diagram

```
User action (tap button in Step 1)
        │
        ▼
_ScannerScreenState._startScan()
  setState(_loading = true)
  await Future.delayed(2s)          ← simulates camera/QR
  _pageController.nextPage()        ← advance to Step 2
  setState(_loading = false)
        │
        ▼ (Step 2 visible)
User taps "Confirmar e Ganhar Moedas"
  ref.read(coinProvider.notifier).addCoins(10, 'Cadastro de nota fiscal')
  _pageController.nextPage()        ← advance to Step 3

        │
        ▼ (Step 3 visible — _ConfettiPage.initState)
_confettiController.play()          ← fires immediately
        │
User taps "Voltar para Home"
  context.go(AppRoutes.scanner)     ← go_router resets branch navigator (same route)
  _pageController.jumpToPage(0)     ← PageController back to page 0 (visual reset)
```

```
ProfileScreen (Tab 4)
        │
        ▼
ref.watch(userNotifierProvider) → User?
  ├── initState: populate TextEditingControllers with user fields
  ├── build: render fields (name, email, address, vehicleModel, fuelEfficiency)
  └── onSave:
        ref.read(userNotifierProvider.notifier).updateProfile(
          name, email, address, vehicleModel, fuelEfficiency)
        ScaffoldMessenger.showSnackBar('Perfil atualizado!')
```

### Recommended Project Structure

No new folders required — all files fit existing feature structure:

```
lib/
├── features/auth/domain/
│   └── user.dart                   ← ADD vehicleModel, fuelEfficiency fields
├── core/providers/
│   └── user_notifier.dart          ← ADD updateProfile() method
├── features/price_registration/presentation/
│   └── scanner_screen.dart         ← REPLACE placeholder with PageView wizard
└── features/profile/presentation/
    └── profile_screen.dart         ← REPLACE placeholder with full screen

test/
├── providers/
│   └── user_notifier_test.dart     ← ADD updateProfile tests
└── features/
    ├── scanner/
    │   └── scanner_screen_test.dart  ← NEW — Step 1 buttons, loading, step navigation
    └── profile/
        └── profile_screen_test.dart  ← NEW — fields render, save triggers SnackBar
```

---

### Pattern 1: ConsumerStatefulWidget with Multiple Controllers

ScannerScreen needs three pieces of local state: `PageController`, `ConfettiController`, `bool _loading`. The established pattern from ShoppingListScreen applies directly.

```dart
// Source: [VERIFIED: codebase — lib/features/shopping_list/presentation/shopping_list_screen.dart]
class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  late final PageController _pageController;
  late final ConfettiController _confettiController;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  // ...
}
```

**Key rule:** Both controllers are initialized in `initState` and disposed in `dispose`. The `ConfettiController` does NOT require a `TickerProvider`/`vsync` from the host widget — it manages its own ticker internally. [VERIFIED: pub.dev/documentation/confetti/latest/confetti/ConfettiController-class.html]

---

### Pattern 2: PageView Navigation (3-step wizard)

```dart
// Source: [ASSUMED — Flutter SDK PageView API, standard pattern]
PageView(
  controller: _pageController,
  physics: const NeverScrollableScrollPhysics(), // User cannot swipe — only programmatic
  children: [
    _Step1Widget(onNext: _startScan),
    _Step2Widget(onConfirm: _confirmReceipt),
    _Step3Widget(
      confettiController: _confettiController,
      onDone: _returnHome,
    ),
  ],
)
```

Navigate between pages:
```dart
// Go to next page
_pageController.nextPage(
  duration: const Duration(milliseconds: 300),
  curve: Curves.easeInOut,
);

// Jump without animation (for reset)
_pageController.jumpToPage(0);
```

**Back button behavior:** Override `PopScope` (Flutter 3.x replacement for `WillPopScope`) at the `Scaffold` level to intercept system back and call `_pageController.previousPage()` if `_pageController.page > 0`, otherwise `pop()` normally.

```dart
// Source: [ASSUMED — Flutter SDK PopScope, standard wizard pattern]
PopScope(
  canPop: false,
  onPopInvokedWithResult: (didPop, result) {
    if (didPop) return;
    final page = _pageController.page?.round() ?? 0;
    if (page > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      context.pop();
    }
  },
  child: Scaffold(...),
)
```

---

### Pattern 3: ConfettiWidget Placement

```dart
// Source: [CITED: pub.dev/packages/confetti]
// Position at top-center of Stack; BlastDirectionality.explosive fires in all directions
Stack(
  alignment: Alignment.topCenter,
  children: [
    // main content
    _Step3Content(...),
    // confetti overlay — always rendered, fires when controller.play() is called
    ConfettiWidget(
      confettiController: _confettiController,
      blastDirectionality: BlastDirectionality.explosive,
      numberOfParticles: 20,
      gravity: 0.3,
      colors: const [
        AppColors.primary,
        Color(0xFFF97316), // orange
        Color(0xFFEC4899), // pink
        Color(0xFFEAB308), // yellow
      ],
    ),
  ],
)
```

**When to call play():** The `ConfettiController.play()` is called when Step 3 becomes visible. Since `_Step3Widget` receives the controller as a parameter, call `play()` inside `_Step3Widget.initState()`:

```dart
// Source: [CITED: pub.dev/packages/confetti — "play() triggers animation"]
class _Step3Widget extends StatefulWidget {
  const _Step3Widget({required this.controller, required this.onDone});
  final ConfettiController controller;
  final VoidCallback onDone;

  @override
  State<_Step3Widget> createState() => _Step3WidgetState();
}

class _Step3WidgetState extends State<_Step3Widget> {
  @override
  void initState() {
    super.initState();
    widget.controller.play(); // fires immediately on page entry
  }
  // NOTE: do NOT dispose the controller here — it's owned by _ScannerScreenState
  // ...
}
```

**Critical ownership rule:** The controller is created and disposed by `_ScannerScreenState`. `_Step3Widget` only calls `play()` — it does NOT call `dispose()`. Disposing the passed-in controller from a child would cause a use-after-free crash when the parent's `dispose()` also calls it.

---

### Pattern 4: Loading Overlay (D-02 — replication of ShoppingListScreen)

```dart
// Source: [VERIFIED: codebase — lib/features/shopping_list/presentation/shopping_list_screen.dart:383-420]
// Exact same pattern: Stack → if (_loading) Container(color: Colors.black.withValues(alpha:0.6))
Stack(
  children: [
    Scaffold(backgroundColor: AppColors.background, body: PageView(...)),
    if (_loading)
      Container(
        color: Colors.black.withValues(alpha: 0.6),
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
  ],
)
```

**2-second delay:**
```dart
Future<void> _startScan() async {
  setState(() => _loading = true);
  await Future<void>.delayed(const Duration(seconds: 2));
  if (!mounted) return; // REQUIRED — widget may be disposed during await
  setState(() => _loading = false);
  _pageController.nextPage(
    duration: const Duration(milliseconds: 300),
    curve: Curves.easeInOut,
  );
}
```

`if (!mounted) return;` after every `await` is mandatory — this is established throughout the codebase (see ShoppingListScreen line 75).

---

### Pattern 5: User Model Extension + SharedPreferences Migration

**User.dart changes:**

```dart
// Source: [VERIFIED: codebase — lib/features/auth/domain/user.dart]
// Add two fields with defaults in constructor AND in fromJson fallback
@immutable
class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
    this.address = '',
    this.coinBalance = 0,
    this.vehicleModel = '',      // NEW — empty string as default
    this.fuelEfficiency = 0.0,  // NEW — 0.0 means "not set"
  });

  // ... existing fields ...
  final String vehicleModel;
  final double fuelEfficiency;

  factory User.fromJson(Map<String, dynamic> json) => User(
    // ... existing fields ...
    vehicleModel: json['vehicleModel'] as String? ?? '',       // nullable read with fallback
    fuelEfficiency: (json['fuelEfficiency'] as num?)?.toDouble() ?? 0.0,
  );

  Map<String, dynamic> toJson() => {
    // ... existing fields ...
    'vehicleModel': vehicleModel,
    'fuelEfficiency': fuelEfficiency,
  };

  User copyWith({
    // ... existing params ...
    String? vehicleModel,
    double? fuelEfficiency,
  }) => User(
    // ... existing ...
    vehicleModel: vehicleModel ?? this.vehicleModel,
    fuelEfficiency: fuelEfficiency ?? this.fuelEfficiency,
  );
}
```

**Migration strategy for existing SharedPreferences data:**

Users with old persisted JSON (missing `vehicleModel` and `fuelEfficiency` keys) are handled entirely by the `?? ''` and `?? 0.0` fallbacks in `fromJson`. No explicit migration step is needed — the next time `updateProfile()` is called, the full new JSON (including these fields) is written. Until then, the defaults are used in memory.

The fallback for fuelEfficiency in the UI: `user.fuelEfficiency == 0.0 ? MockData.vehicle.fuelEfficiencyKmPerLiter : user.fuelEfficiency`. This handles the "never updated profile" case.

---

### Pattern 6: UserNotifier.updateProfile()

```dart
// Source: [VERIFIED: codebase — lib/core/providers/user_notifier.dart]
// Pattern: same as login() — mutate state, call _persist()
void updateProfile({
  required String name,
  required String email,
  required String address,
  required String vehicleModel,
  required double fuelEfficiency,
}) {
  final current = state;
  if (current == null) return; // guard — user must be logged in
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

**ProfileScreen calls it:**
```dart
// Source: [ASSUMED — standard Riverpod handler pattern for this codebase]
// In a button onPressed (NOT in build, NOT using ref.watch):
ref.read(userNotifierProvider.notifier).updateProfile(
  name: _nameController.text.trim(),
  email: _emailController.text.trim(),
  address: _addressController.text.trim(),
  vehicleModel: _vehicleModelController.text.trim(),
  fuelEfficiency: double.tryParse(_fuelEfficiencyController.text) ?? 0.0,
);
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
    content: Text('Perfil atualizado!'),
    backgroundColor: AppColors.primary,
  ),
);
```

---

### Pattern 7: Tab Reset After Step 3 (D-05)

```dart
// Source: [VERIFIED: codebase — lib/routing/app_routes.dart, lib/routing/app_router.dart]
// context.go() navigates to the branch root — if already on /scanner, it re-navigates to /scanner
// which triggers StatefulShellRoute to show the scanner branch root fresh
void _returnHome() {
  // Order matters: jump page BEFORE go, so the reset is instant for next visit
  _pageController.jumpToPage(0);
  context.go(AppRoutes.scanner); // '/scanner'
}
```

**Why `context.go` not `context.pop`:** `context.pop()` would return to wherever we navigated from (potentially a different tab). `context.go('/scanner')` always puts us on tab 2 root. Since `ScannerScreen` is the root of branch 2, going to its route reloads the branch root but `StatefulShellRoute.indexedStack` PRESERVES the widget state (including PageController). Therefore `jumpToPage(0)` must be called BEFORE `context.go` to ensure the controller is at page 0 when the branch is next displayed.

**Important nuance:** `StatefulShellRoute.indexedStack` keeps the branch widget alive even when switching tabs. After `_pageController.jumpToPage(0)`, the PageView immediately resets visually. `context.go(AppRoutes.scanner)` then switches the active tab to tab 2, showing the already-reset wizard.

---

### Pattern 8: Impact Stats Derived from CoinNotifier

```dart
// Source: [VERIFIED: codebase — lib/core/providers/coin_notifier.dart]
// In ProfileScreen build():
final coinState = ref.watch(coinProvider);
final scannedCount = coinState.transactions
    .where((tx) => tx.description == 'Cadastro de nota fiscal')
    .length;
// Other stats are const:
const searchCount = 47;
const estimatedSavings = 342.0; // BRL
```

The string `'Cadastro de nota fiscal'` must match exactly what is passed to `addCoins()` in ScannerScreen Step 2 (D-04). These two uses must be consistent — recommend a shared constant.

---

### Anti-Patterns to Avoid

- **`withOpacity()`** — enforced project-wide. Always `withValues(alpha: x)`.
- **`StateNotifierProvider`** — use `NotifierProvider<T, S>` only.
- **`ref.watch` in handlers** — `ref.read` in button `onPressed`, `ref.watch` only in `build()`.
- **Disposing a passed-in controller from a child widget** — `_Step3Widget` must NOT dispose the `ConfettiController`.
- **`PageController` without `NeverScrollableScrollPhysics`** — without this, user can swipe between pages manually, bypassing the loading simulation and coin award.
- **`double.parse()` instead of `double.tryParse()`** — parse errors on empty/invalid fuelEfficiency text would throw; use `tryParse` with fallback.
- **Calling `play()` multiple times without checking state** — if the user navigates back from Step 3 then forward again, `play()` will be called again. Since `ConfettiController` is not re-created (it's owned by the parent and persists), calling `play()` again re-fires the animation, which is acceptable behaviour for this use case.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Confetti animation | Custom particle system with AnimationController | `confetti: ^0.7.0` | Physics-correct particle simulation; custom is 200+ lines with poor visual quality |
| Coin award logic | Inline state mutation in ScannerScreen | `ref.read(coinProvider.notifier).addCoins()` | Already implemented, persisted, tested |
| Date formatting | Manual string concatenation | `DateFormat('dd/MM/yyyy', 'pt_BR').format(DateTime.now())` | intl already in pubspec |
| BRL currency formatting | `'R\$ ${value.toStringAsFixed(2)}'` | `NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(value)` | intl already in pubspec; handles edge cases |
| Profile persistence | Direct prefs.setString in widget | `ref.read(userNotifierProvider.notifier).updateProfile()` | Centralized state + automatic persistence via existing _persist() |

---

## Common Pitfalls

### Pitfall 1: ConfettiController Disposed Twice
**What goes wrong:** `_Step3Widget` disposes the controller it received; then `_ScannerScreenState.dispose()` also disposes it — Flutter throws "ChangeNotifier was used after being disposed".
**Why it happens:** Caller passes controller to child; child follows "owns what it creates" instinct incorrectly.
**How to avoid:** Only the creator disposes. `_Step3Widget` only calls `play()`. No `dispose()` call in child.
**Warning signs:** `FlutterError: A ChangeNotifier was used after being disposed.` in debug console.

### Pitfall 2: `mounted` Check Missing After `await`
**What goes wrong:** User navigates away during the 2s loading delay. `setState()` is called on a disposed widget — throws `setState() called after dispose()`.
**Why it happens:** Async gap between `await Future.delayed(...)` and `setState(...)`.
**How to avoid:** `if (!mounted) return;` immediately after every `await`. Already established pattern in ShoppingListScreen line 75.
**Warning signs:** Exception mentioning `setState() called after dispose()`.

### Pitfall 3: SharedPreferences Migration — Double Parse of fuelEfficiency
**What goes wrong:** Old JSON has no `fuelEfficiency` key; `(json['fuelEfficiency'] as num).toDouble()` throws a `Null check operator used on a null value` / cast error.
**Why it happens:** Missing `?` on the cast (forgetting nullable read).
**How to avoid:** `(json['fuelEfficiency'] as num?)?.toDouble() ?? 0.0` — nullable cast with fallback.
**Warning signs:** App crashes on launch after update for users with existing sessions.

### Pitfall 4: Stale TextEditingControllers on Profile Load
**What goes wrong:** `ProfileScreen` is a `ConsumerStatefulWidget`; `initState` runs once. If the user logs in AFTER the ProfileScreen is first built (unlikely in this flow but possible), the controllers are never updated.
**Why it happens:** `initState` runs before the first `build()` — if `userNotifierProvider` is `null` at that point, controllers are empty.
**How to avoid:** Initialize controllers in `initState` using `ref.read(userNotifierProvider)` which is synchronous. Since login always precedes profile access in this app, the user is guaranteed to be non-null at ProfileScreen mount time.
**Warning signs:** Empty text fields in ProfileScreen despite user having saved data.

### Pitfall 5: PageController.page Returns null Before First Layout
**What goes wrong:** Accessing `_pageController.page` before the PageView has laid out returns null, causing null-check crash in `PopScope`.
**Why it happens:** `page` property is only populated after the first frame.
**How to avoid:** `_pageController.page?.round() ?? 0` — null-safe read with fallback to 0.

### Pitfall 6: context.go() Before jumpToPage(0) Loses Reset
**What goes wrong:** If `context.go(AppRoutes.scanner)` is called first, the route navigation happens; since `StatefulShellRoute` preserves widget state, the `PageController` still points to page 2. On next entry the user sees the celebration page.
**Why it happens:** Navigation happens immediately synchronously; `jumpToPage(0)` after `context.go()` would target a widget that is being re-rendered.
**How to avoid:** Always `_pageController.jumpToPage(0)` FIRST, then `context.go(AppRoutes.scanner)`.

### Pitfall 7: `^0.7.0` confetti version — API differences from 0.8.0
**What goes wrong:** Developer reads 0.8.0 docs which mention `stop({bool clearAllParticles})` — this parameter does not exist in 0.7.0.
**Why it happens:** pub.dev shows 0.8.0 docs by default.
**How to avoid:** Use only `play()` and `stop()` without parameters (0.7.0 API). The 0.7.0 `ConfettiController` constructor takes only `duration`.
**Warning signs:** `Too many positional arguments` or `Named parameter not found` compile error on `stop(clearAllParticles: true)`.

---

## Code Examples

### Complete ScannerScreen Skeleton

```dart
// Source: synthesized from [VERIFIED: codebase patterns] + [CITED: pub.dev/packages/confetti]
class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});
  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  late final PageController _pageController;
  late final ConfettiController _confettiController;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

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

  void _confirmReceipt() {
    ref.read(coinProvider.notifier).addCoins(10, 'Cadastro de nota fiscal');
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _returnHome() {
    _pageController.jumpToPage(0); // reset FIRST
    context.go(AppRoutes.scanner); // then navigate
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final page = _pageController.page?.round() ?? 0;
        if (page > 0) {
          _pageController.previousPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        } else {
          context.pop();
        }
      },
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: AppColors.background,
            body: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _Step1(onNext: _startScan),
                _Step2(onConfirm: _confirmReceipt),
                _Step3(
                  confettiController: _confettiController,
                  onDone: _returnHome,
                ),
              ],
            ),
          ),
          if (_loading)
            Container(
              color: Colors.black.withValues(alpha: 0.6),
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }
}
```

### ProfileScreen Skeleton — TextEditingController Init

```dart
// Source: [VERIFIED: codebase — lib/features/auth/presentation/login_screen.dart — same ConsumerStatefulWidget + TextEditingController pattern]
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _vehicleCtrl;
  late final TextEditingController _efficiencyCtrl;

  @override
  void initState() {
    super.initState();
    final user = ref.read(userNotifierProvider); // synchronous — user is guaranteed logged in
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

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _vehicleCtrl.dispose();
    _efficiencyCtrl.dispose();
    super.dispose();
  }

  void _save() {
    ref.read(userNotifierProvider.notifier).updateProfile(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      vehicleModel: _vehicleCtrl.text.trim(),
      fuelEfficiency: double.tryParse(_efficiencyCtrl.text) ?? 0.0,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Perfil atualizado!'),
        backgroundColor: AppColors.primary,
      ),
    );
  }
}
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `WillPopScope` | `PopScope` with `onPopInvokedWithResult` | Flutter 3.12 | WillPopScope deprecated; use PopScope with 2-param callback |
| `stop(clearAllParticles: true)` | `stop()` (no params in 0.7.0) | confetti 0.8.0 | Using 0.7.0 — param not available |
| `StateNotifierProvider` | `NotifierProvider<T, S>` | Riverpod 2.0 | Project enforces this — StateNotifier is deprecated |

**Deprecated/outdated:**
- `withOpacity()`: deprecated in Flutter 3.x for Colors — project enforces `withValues(alpha:)` instead
- `confetti 0.8.0 API`: do not use `stop(clearAllParticles:)` or `particleStatsCallback` — not in 0.7.0

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `PageView` with `NeverScrollableScrollPhysics` is the correct way to prevent swipe-navigation in this wizard | Pattern 2 | Low — if physics allow swipe, user bypasses loading simulation; fixable with one-line change |
| A2 | `PopScope` (not `WillPopScope`) is appropriate for Flutter 3.32.x in use | Pattern 2 | Low — WillPopScope still works but shows deprecation warning; PopScope is the correct API since Flutter 3.12 |
| A3 | `_confettiController.play()` called from `_Step3WidgetState.initState()` fires correctly | Pattern 3 | Medium — initState fires before first frame; if ConfettiWidget hasn't laid out yet, play() may be a no-op. Alternative: call from `WidgetsBinding.instance.addPostFrameCallback`. Recommend postFrameCallback to be safe. |
| A4 | The `context.go('/scanner')` call while already on `/scanner` branch resets the branch navigator root correctly in go_router 14.x | Pattern 7 | Medium — if go_router 14.x does NOT re-push the same route (it may be a no-op when already at that location), `jumpToPage(0)` alone handles the reset. The tab selector already correctly stays on tab 2 since `StatefulShellRoute` preserves which branch is active. The `jumpToPage(0)` is the essential part; `context.go` may be redundant. |

**A3 Mitigation (recommended):**
```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) widget.controller.play();
  });
}
```
This ensures the widget is fully laid out before play() is invoked.

**A4 Mitigation:** The essential operation is `_pageController.jumpToPage(0)`. The `context.go(AppRoutes.scanner)` can be omitted since `StatefulShellRoute.indexedStack` preserves the branch root widget state. The user is already on tab 2 — no navigation is actually needed. Simpler implementation:
```dart
void _returnHome() {
  _pageController.jumpToPage(0); // that's all that's needed
}
```
The D-05 decision says "Voltar para Home stays on Scanner tab" — since the user IS on Scanner tab, `jumpToPage(0)` alone satisfies this. `context.go` is optional and may be a no-op anyway.

---

## Open Questions (RESOLVED)

1. **`context.go('/scanner')` no-op concern (A4)**
   - What we know: go_router 14.x `context.go()` to the current branch root may or may not trigger a widget rebuild
   - What's unclear: Whether it refreshes the branch or is a silent no-op
   - Recommendation: Implement `_returnHome()` as `_pageController.jumpToPage(0)` only, with no go() call. Simpler, safer, achieves D-05 intent. If the planner disagrees, add `context.go(AppRoutes.scanner)` — worst case is a redundant navigation that still works.
   - **RESOLVED:** Plans implement `_returnHome()` as `_pageController.jumpToPage(0)` only (stays on Scanner tab, satisfies D-05 strict reading). "Voltar para início" TextButton uses `context.go(AppRoutes.home)` per CONTEXT.md specifics section two-button design. A4 mitigation fully adopted.

2. **confetti 0.7.0 exact API for `stop()`**
   - What we know: 0.7.0 exists; 0.8.0 adds `clearAllParticles` param to stop()
   - What's unclear: Whether 0.7.0 stop() exists at all or if the controller simply times out
   - Recommendation: Rely on `duration: Duration(seconds: 3)` auto-stop only; don't call stop() manually. This is safe regardless of version.
   - **RESOLVED:** Plans do not call `stop()` anywhere. ConfettiController auto-stops via `duration: Duration(seconds: 3)`. Only `play()` is called (via `addPostFrameCallback`).

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter SDK | All | ✓ | 3.32.7 | — |
| Dart SDK | All | ✓ | 3.8.1 | — |
| confetti (pub.dev) | PREG-03 | Needs `flutter pub get` | 0.7.0 (to be fetched) | — |
| Android/iOS emulator | Manual UAT | — | — | Human test on device |

**Missing dependencies with no fallback:** None — confetti will be fetched on `flutter pub get`.
**Missing dependencies with fallback:** None.

---

## Validation Architecture

> `workflow.nyquist_validation: true` — included.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | flutter_test (built-in Flutter SDK) |
| Config file | none — uses standard flutter test runner |
| Quick run command | `flutter test test/providers/user_notifier_test.dart` |
| Full suite command | `flutter test --no-pub` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PREG-01 | Step 1 renders two buttons (QR + Camera) | widget | `flutter test test/features/scanner/scanner_screen_test.dart -x` | ❌ Wave 0 |
| PREG-02 | Step 2 shows receipt fields (supermarket, date, total) | widget | `flutter test test/features/scanner/scanner_screen_test.dart -x` | ❌ Wave 0 |
| PREG-03 | Step 3 shows ConfettiWidget + coin count text | widget | `flutter test test/features/scanner/scanner_screen_test.dart -x` | ❌ Wave 0 |
| PREG-04 | Confirming step 2 calls addCoins(10, 'Cadastro de nota fiscal') | unit/provider | `flutter test test/providers/coin_notifier_test.dart` | ✅ (existing test covers addCoins; new test for description match) |
| PROF-01 | Profile shows name/email/address fields pre-filled | widget | `flutter test test/features/profile/profile_screen_test.dart -x` | ❌ Wave 0 |
| PROF-02 | Tapping save calls updateProfile() and persists to SharedPreferences | unit | `flutter test test/providers/user_notifier_test.dart` | ✅ (file exists; new test for updateProfile() needed) |
| PROF-03 | Stats section shows scan count derived from transactions | widget | `flutter test test/features/profile/profile_screen_test.dart -x` | ❌ Wave 0 |

**Note on confetti in widget tests:** `ConfettiWidget` creates an `AnimationController` internally. In flutter_test, `fake_async` controls time — confetti animations won't cause flake but the widget must be pumpable without a real ticker. Standard `WidgetTester.pump()` works fine; confetti particles won't render in test but the widget tree is valid.

### Sampling Rate

- **Per task commit:** `flutter test test/providers/user_notifier_test.dart --no-pub`
- **Per wave merge:** `flutter test --no-pub`
- **Phase gate:** Full suite green (currently 92 tests) before `/gsd-verify-work`

### Wave 0 Gaps

- [ ] `test/features/scanner/scanner_screen_test.dart` — covers PREG-01, PREG-02, PREG-03
- [ ] `test/features/profile/profile_screen_test.dart` — covers PROF-01, PROF-03
- [ ] New test cases in `test/providers/user_notifier_test.dart` — covers PROF-02 (updateProfile persistence)

---

## Security Domain

> `security_enforcement: true`, `security_asvs_level: 1`

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | No auth change in this phase |
| V3 Session Management | no | Session unchanged |
| V4 Access Control | no | No new access control surface |
| V5 Input Validation | yes (low risk) | Profile fields are free-text; no SQL/network — only SharedPreferences. Risk: very low. Trim whitespace on save. `double.tryParse()` for numeric field. |
| V6 Cryptography | no | No crypto in this phase |

### Known Threat Patterns for Flutter local-only app

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Invalid fuelEfficiency input (NaN, negative) | Tampering | `double.tryParse()` with fallback to 0.0; planner may add range validation (>0) |
| SharedPreferences key collision (typo in key name) | Tampering | Use named constant for the user key — already `static const _key = 'lista_smart_user'` in UserNotifier |

**Security verdict:** This phase adds no network surface, no auth bypass vectors, no new cryptographic operations. ASVS Level 1 is trivially satisfied by the existing architecture.

---

## Sources

### Primary (HIGH confidence)
- [VERIFIED: codebase] `lib/features/shopping_list/presentation/shopping_list_screen.dart` — loading overlay pattern, ConsumerStatefulWidget, `if (!mounted) return`, Stack pattern
- [VERIFIED: codebase] `lib/core/providers/coin_notifier.dart` — addCoins() API, CoinState.transactions
- [VERIFIED: codebase] `lib/core/providers/user_notifier.dart` — NotifierProvider pattern, _persist() pattern
- [VERIFIED: codebase] `lib/features/auth/domain/user.dart` — User model, fromJson/toJson/copyWith
- [VERIFIED: codebase] `lib/routing/app_router.dart` — StatefulShellRoute.indexedStack, route paths
- [VERIFIED: codebase] `lib/routing/app_routes.dart` — AppRoutes.scanner = '/scanner'
- [VERIFIED: codebase] `lib/core/data/mock_data.dart` — products list, vehicle defaults
- [VERIFIED: codebase] `dart pub cache list` — confirmed confetti not yet installed; all other deps verified
- [CITED: pub.dev/packages/confetti] — ConfettiController API, ConfettiWidget parameters, 0.7.0 vs 0.8.0 changelog
- [CITED: pub.dev/documentation/confetti/latest/confetti/ConfettiController-class.html] — no vsync required; extends ChangeNotifier
- [CITED: dart.dev/tools/pub/dependencies#caret-syntax] — `^0.7.0` = `>=0.7.0 <0.8.0`

### Secondary (MEDIUM confidence)
- [CITED: pub.dev/packages/confetti/changelog] — 0.8.0 adds `clearAllParticles` param, breaking internal changes; 0.7.0 API is simpler

### Tertiary (LOW confidence — marked ASSUMED in code examples)
- Flutter SDK PageView + NeverScrollableScrollPhysics pattern (well-known, not independently verified this session)
- PopScope usage pattern for wizard back-button interception

---

## Metadata

**Confidence breakdown:**
- confetti package API: HIGH (verified from pub.dev official docs + changelog)
- confetti version constraint behavior: HIGH (verified from dart.dev caret syntax docs)
- PageView/PageController patterns: MEDIUM-HIGH (standard Flutter; not re-verified against current SDK docs this session but extremely stable API)
- User model extension + migration: HIGH (directly read the fromJson implementation; migration strategy is mechanically derivable)
- Tab reset behavior (context.go no-op risk): MEDIUM (flagged as A4; recommend simpler jumpToPage-only implementation)
- confetti play() timing (postFrameCallback): MEDIUM (flagged as A3; mitigation provided)

**Research date:** 2026-06-02
**Valid until:** 2026-07-02 (stable domain — Flutter widget APIs and confetti 0.7.0 are frozen)
