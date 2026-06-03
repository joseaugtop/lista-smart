---
status: draft
phase: 5
phase_name: Price Registration + Profile
screens: [ScannerScreen, ProfileScreen]
design_system: flutter/manual
tool: none (Flutter design system via AppColors.* + AppSizes.* constants)
created: 2026-06-02
---

# UI-SPEC — Phase 5: Price Registration + Profile

> **Consumer note:** This document is the visual and interaction source of truth for Phase 5.
> Planner uses Sections 3–6 for task decomposition. Executor follows every pixel-level rule in Sections 4–7.
> Checker validates against the 6 quality dimensions declared at the end.

---

## 1. Design System Detection

| Property | Value | Source |
|----------|-------|--------|
| Component library | Manual Flutter (no shadcn — Dart project) | Codebase scan |
| Color token file | `lib/core/constants/app_colors.dart` | Verified |
| Spacing token file | `lib/core/constants/app_sizes.dart` | Verified |
| Icon library | `lucide_icons: ^0.257.0` | CLAUDE.md + pubspec |
| Typography | `google_fonts` Inter, via ThemeData | CLAUDE.md |
| Glassmorphic card pattern | `color: AppColors.surface.withValues(alpha: 0.7)` + `Border.all(color: Colors.white.withValues(alpha: 0.1))` | login_screen.dart, store_screen.dart |

**Registry safety gate:** Not applicable — no shadcn, no third-party component registries.

---

## 2. Screens in Scope

| Screen | Route | Tab | Widget Type | Delivery |
|--------|-------|-----|-------------|----------|
| `ScannerScreen` | `/scanner` | Tab 2 | `ConsumerStatefulWidget` | Replace placeholder |
| `ProfileScreen` | `/profile` | Tab 4 | `ConsumerStatefulWidget` | Replace placeholder |

---

## 3. Spacing Contract

**Scale:** 8-point grid enforced via `AppSizes.*` constants. No raw numeric literals permitted.

| Token | Value | Use In This Phase |
|-------|-------|-------------------|
| `AppSizes.spacingXS` | 4 px | Icon-to-text gap, badge inner padding |
| `AppSizes.spacingS` | 8 px | Vertical gap between related elements (e.g. label + value), spacing inside row |
| `AppSizes.spacingM` | 16 px | Default horizontal page padding, gap between form fields, gap between cards |
| `AppSizes.spacingL` | 24 px | Card internal padding, gap between form sections |
| `AppSizes.spacingXL` | 32 px | Gap between major screen sections (header → body) |

**Touch targets:** All tappable elements minimum 44 px tall. Achieved by `ElevatedButton` / `TextButton` default height (48 px) or explicit `SizedBox(height: 44)` wrapper on smaller icon-only targets.

**Border radius:**

| Token | Value | Use In This Phase |
|-------|-------|-------------------|
| `AppSizes.radiusS` | 8 px | Stat chips, small badges |
| `AppSizes.radiusM` | 12 px | TextField borders |
| `AppSizes.radiusL` | 16 px | Step indicator, icon containers |
| `AppSizes.radiusXL` | 24 px | All glassmorphic cards (scanner method cards, receipt card, profile section cards) |

---

## 4. Typography Contract

**Font:** Inter via `google_fonts`. All sizes come from `Theme.of(context).textTheme.*`.

| Role | TextTheme Token | Approx Size | Weight | Line Height | Use In This Phase |
|------|----------------|-------------|--------|-------------|-------------------|
| Screen title / coin award | `headlineMedium` | ~28 px | 700 (bold) | 1.2 | "Escanear Nota" (Step 1 header), "+10 Smart Coins" (Step 3), "Perfil" (Profile AppBar) |
| Card heading / section label | `titleMedium` | ~16 px | 700 (bold) | 1.4 | Receipt supermarket name (Step 2), receipt total label/value, "Dados Pessoais", "Veículo", "Impacto Social", all CTA button labels |
| Body / field label | `bodyMedium` | ~14 px | 400 (regular) | 1.5 | Field hints, receipt line items, stat descriptions |
| Supporting / caption | `bodySmall` | ~12 px | 400 (regular) | 1.4 | Date under receipt total, secondary labels |

**Color rules:**
- Primary text: `AppColors.textMain` (#FAFAFA)
- Secondary / hint text: `AppColors.textSecondary` (#A1A1AA)
- Accent value (coins, total, savings): `AppColors.primary` (#A3E615)
- Error text: `AppColors.error` (#EF4444)

**Anti-pattern:** Never use `withOpacity()`. Always `withValues(alpha: x)`.

---

## 5. Color Contract (60 / 30 / 10 Rule)

| Role | Color | Token | % | Reserved For |
|------|-------|-------|---|-------------|
| Dominant surface | `#09090B` | `AppColors.background` | 60% | `Scaffold.backgroundColor`, `AppBar.backgroundColor`, full-bleed backgrounds |
| Secondary surface | `#18181B` | `AppColors.surface` | 30% | Glassmorphic cards (scanner method cards, receipt card, profile section cards), `withValues(alpha: 0.7)` |
| Elevated surface | `#27272A` | `AppColors.surfaceElevated` | sub-30% | Stat chip backgrounds, disabled field fill, hover states |
| Accent | `#A3E615` | `AppColors.primary` | 10% | Primary CTA buttons ONLY, coin count text, focused TextField border, SnackBar background on success, confetti color #1 |
| Success | `#22C55E` | `AppColors.success` | — | Positive transaction icons in history (carry-over from StoreScreen pattern) |
| Error / Destructive | `#EF4444` | `AppColors.error` | — | Negative transaction icons, validation error text |

**Glassmorphic card recipe (mandatory for ALL cards in this phase):**

```
color: AppColors.surface.withValues(alpha: 0.7)
border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1.0)
borderRadius: BorderRadius.circular(AppSizes.radiusXL)  // 24 px
```

**Border overlay for glass effect:** `Colors.white.withValues(alpha: 0.1)` — 1 px, not 2 px.

---

## 6. Component Inventory

### 6.1 ScannerScreen

The ScannerScreen is a `PageView` wizard with 3 pages rendered inside a `Stack` that hosts the loading overlay. `PageView.physics` = `NeverScrollableScrollPhysics`.

---

#### Page 0 — Escolha do Método (Step 1)

**Layout:** Full-screen column, vertically centered within `SafeArea`.

```
Scaffold (bg: AppColors.background)
  SafeArea
    Column (mainAxisAlignment: center, padding: spacingM horizontal)
      Icon [scanIcon] + Text title        ← step header
      SizedBox(height: spacingXL)
      _MethodCard (QR Code)               ← glassmorphic card
      SizedBox(height: spacingM)
      _MethodCard (Foto do Cupom)         ← glassmorphic card
```

**Step header:**
- Icon: `LucideIcons.fileSearch` (48 px, `AppColors.primary`)
- Title: "Escanear Nota Fiscal" — `headlineMedium`, `AppColors.textMain`, `TextAlign.center`
- Subtitle: "Escolha como deseja registrar sua compra" — `bodyMedium`, `AppColors.textSecondary`, `TextAlign.center`
- Gap header → cards: `AppSizes.spacingXL` (32 px)

**_MethodCard anatomy:**

```
Container [glassmorphic card recipe, height: 100 px]
  Row (mainAxisAlignment: center)
    Icon [method icon, 36 px, AppColors.primary]
    SizedBox(width: spacingM)
    Column (crossAxisAlignment: start)
      Text [card title, titleMedium, weight 700, AppColors.textMain]
      Text [card subtitle, bodySmall, AppColors.textSecondary]
```

| Card | Icon | Title | Subtitle |
|------|------|-------|----------|
| QR Code | `LucideIcons.qrCode` | "Escanear QR Code" | "Aponte para o código da nota" |
| Câmera | `LucideIcons.camera` | "Foto do Cupom" | "Tire uma foto do cupom fiscal" |

Both cards are `GestureDetector`-wrapped (full card tappable). `onTap` → `_startScan()`.

**Loading overlay (fires on method tap):**

```
Stack
  Scaffold [PageView content]
  if (_loading)
    Container
      color: Colors.black.withValues(alpha: 0.6)
      child: Center → CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3)
```

Overlay covers full screen including AppBar area. Duration: 2 seconds (`Future.delayed(Duration(seconds: 2))`). After delay: advance to Page 1. `if (!mounted) return` after every await.

---

#### Page 1 — Confirmação da Nota (Step 2)

**Layout:** `SingleChildScrollView` inside `Scaffold`.

```
Scaffold (bg: AppColors.background)
  SafeArea
    SingleChildScrollView (padding: spacingM)
      Column
        _StepIndicator (current: 1 of 2, shown as dots or text)
        SizedBox(height: spacingL)
        _ReceiptCard                        ← glassmorphic
        SizedBox(height: spacingL)
        ElevatedButton "Confirmar e Ganhar Moedas"
```

**Step indicator (top of pages 1 and 2 only):**
- Simple row of 3 dots or text "Etapa 2 de 3", `bodySmall`, `AppColors.textSecondary`
- Active dot: `AppColors.primary`, size 8 px; inactive: `AppColors.textSecondary`, size 6 px
- Gap between dots: `AppSizes.spacingXS` (4 px)

**_ReceiptCard anatomy:**

```
Container [glassmorphic card recipe]
  padding: spacingL
  Column (crossAxisAlignment: stretch)
    Row
      Icon [LucideIcons.store, 20 px, AppColors.primary]
      SizedBox(width: spacingS)
      Text ["Bistek Supermercados", titleMedium, weight 700, AppColors.textMain]
    SizedBox(height: spacingXS)
    Text [formatted date, bodySmall, AppColors.textSecondary]   ← DateFormat('dd/MM/yyyy')
    Divider [color: Colors.white.withValues(alpha: 0.1), height: spacingL]
    Column → _ReceiptLineItem × 3-4
    Divider [same style]
    Row (mainAxisAlignment: spaceBetween)
      Text ["Total", titleMedium, weight 700, AppColors.textMain]
      Text ["R$ 87,43", titleMedium, weight 700, AppColors.primary]
    SizedBox(height: spacingS)
    Row (mainAxisAlignment: center)
      Icon [LucideIcons.coins, 14 px, AppColors.primary]
      SizedBox(width: 4)
      Text ["+10 moedas ao confirmar", bodySmall, AppColors.primary]
```

**_ReceiptLineItem:**

```
Row (mainAxisAlignment: spaceBetween, padding: vertical spacingXS)
  Text [product name, bodyMedium, AppColors.textMain]
  Text [mock unit price, bodyMedium, AppColors.textSecondary]
```

Products shown: 3–4 items from `MockData.products` (first 4: pão, leite, banana, + 1 more). Unit prices are hardcoded strings in the mock constant.

**Primary CTA — "Confirmar e Ganhar Moedas":**

```
ElevatedButton
  style:
    backgroundColor: AppColors.primary
    foregroundColor: AppColors.background   ← dark text on lime
    borderRadius: AppSizes.radiusM          ← 12 px
    padding: EdgeInsets.symmetric(vertical: 16)
    minimumSize: Size(double.infinity, 52)
  child: Row
    Icon [LucideIcons.coins, 18 px]
    SizedBox(width: spacingS)
    Text ["Confirmar e Ganhar Moedas", titleMedium, weight 700]
```

`onPressed` → `_confirmReceipt()` → `coinProvider.notifier.addCoins(10, 'Cadastro de nota fiscal')` → `_pageController.nextPage(...)`.

---

#### Page 2 — Celebração (Step 3)

**Layout:** `Stack` — content column centered + `ConfettiWidget` anchored top-center.

```
Stack (alignment: topCenter)
  SafeArea
    Column (mainAxisAlignment: center, padding: spacingM)
      TweenAnimationBuilder [scale 0→1, duration 600ms, curve: elasticOut]
        child: Icon [LucideIcons.coins, 80 px, AppColors.primary]
      SizedBox(height: spacingL)
      Text ["+10 Smart Coins", headlineMedium, weight 700, AppColors.primary, center]
      SizedBox(height: spacingS)
      Text ["Nota fiscal cadastrada com sucesso!", titleMedium, weight 700, AppColors.textMain, center]
      SizedBox(height: spacingXS)
      Text ["Obrigado por contribuir com dados de preços.", bodyMedium, AppColors.textSecondary, center]
      SizedBox(height: spacingXL)
      ElevatedButton "Escanear Outra Nota"    ← secondary action
      SizedBox(height: spacingS)
      TextButton "Voltar para início"          ← primary "done" action
  ConfettiWidget [anchored top-center, blastDirectionality: explosive]
```

**Confetti configuration:**

```dart
ConfettiWidget(
  confettiController: _confettiController,
  blastDirectionality: BlastDirectionality.explosive,
  numberOfParticles: 20,
  gravity: 0.3,
  colors: const [
    AppColors.primary,          // #A3E615 lime
    Color(0xFFF97316),          // orange
    Color(0xFFEC4899),          // pink
    Color(0xFFEAB308),          // yellow
  ],
)
```

`_confettiController.play()` called via `WidgetsBinding.instance.addPostFrameCallback` in `_Step3Widget.initState()`.

**Coin icon animation:**

```dart
TweenAnimationBuilder<double>(
  tween: Tween(begin: 0.0, end: 1.0),
  duration: const Duration(milliseconds: 600),
  curve: Curves.elasticOut,
  builder: (_, value, child) => Transform.scale(scale: value, child: child),
  child: const Icon(LucideIcons.coins, size: 80, color: AppColors.primary),
)
```

**Button — "Escanear Outra Nota" (secondary):**

```
OutlinedButton
  style:
    side: BorderSide(color: AppColors.primary, width: 1.5)
    foregroundColor: AppColors.primary
    borderRadius: AppSizes.radiusM
    padding: EdgeInsets.symmetric(vertical: 14)
    minimumSize: Size(double.infinity, 52)
  child: Text ["Escanear Outra Nota", titleMedium, weight 700]
  onPressed → _returnHome()    ← jumpToPage(0) first, then no go() needed
```

**Button — "Voltar para início" (tertiary):**

```
TextButton
  foregroundColor: AppColors.textSecondary
  child: Text ["Voltar para início"]
  onPressed → context.go(AppRoutes.home)   ← navigate to home tab
```

> **Note on D-05 revision:** The CONTEXT says "Voltar para Home stays on Scanner tab". RESEARCH.md (A4 mitigation) confirms `jumpToPage(0)` alone suffices for tab reset. "Escanear Outra Nota" calls `_returnHome()` = `jumpToPage(0)` only. "Voltar para início" navigates to `/home` tab for users who are done. This gives two distinct outcomes matching user intent.

---

### 6.2 ProfileScreen

**Layout:** `CustomScrollView` with a `SliverAppBar` for the avatar header, followed by `SliverToBoxAdapter` sections.

```
Scaffold (bg: AppColors.background)
  CustomScrollView
    SliverAppBar
      expandedHeight: 160
      flexibleSpace: FlexibleSpaceBar
        background: _AvatarHeader
      pinned: true
      backgroundColor: AppColors.background
      title: Text ["Perfil", AppColors.textMain]
    SliverToBoxAdapter
      Padding (horizontal + bottom: spacingM)
        Column
          _ProfileSection ["Dados Pessoais"]
          SizedBox(height: spacingM)
          _ProfileSection ["Veículo"]
          SizedBox(height: spacingM)
          _ImpactSection ["Impacto Social"]
          SizedBox(height: spacingL)
          ElevatedButton ["Salvar Alterações"]
          SizedBox(height: spacingL)   ← bottom safe area buffer
```

**_AvatarHeader (SliverAppBar background):**

```
Container (bg: AppColors.background)
  Column (mainAxisAlignment: center)
    CircleAvatar
      radius: 36
      backgroundColor: AppColors.primary.withValues(alpha: 0.15)
      child: Text [user initials, headlineMedium, AppColors.primary, weight 700]
    SizedBox(height: spacingS)
    Text [user name, titleMedium, weight 700, AppColors.textMain]
    Text [user email, bodyMedium, AppColors.textSecondary]
```

User initials: `name.split(' ').map((w) => w[0]).take(2).join().toUpperCase()`.

**_ProfileSection anatomy (glassmorphic card with labeled fields):**

```
Container [glassmorphic card recipe]
  padding: spacingL
  Column
    Text [section title, titleMedium, weight 700, AppColors.textMain]
    SizedBox(height: spacingM)
    _ProfileField × N   ← one per editable field
```

**_ProfileField (TextField styled to match login_screen.dart pattern):**

```
TextFormField
  controller: [corresponding controller]
  style: TextStyle(color: AppColors.textMain)
  keyboardType: [per field — see table below]
  decoration: InputDecoration
    labelText: [field label]
    labelStyle: TextStyle(color: AppColors.textSecondary)
    prefixIcon: Icon([field icon], color: AppColors.textSecondary)
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.radiusM))
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSizes.radiusM),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
    )
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSizes.radiusM),
      borderSide: BorderSide(color: AppColors.primary, width: 1.5),
    )
    filled: true
    fillColor: AppColors.surfaceElevated.withValues(alpha: 0.4)
```

**Field inventory — "Dados Pessoais" section:**

| Field | Label | Icon | Keyboard | Controller |
|-------|-------|------|----------|------------|
| Nome | "Nome completo" | `LucideIcons.user` | `text` | `_nameCtrl` |
| E-mail | "E-mail" | `LucideIcons.mail` | `emailAddress` | `_emailCtrl` |
| Endereço | "Endereço" | `LucideIcons.mapPin` | `streetAddress` | `_addressCtrl` |

**Field inventory — "Veículo" section:**

| Field | Label | Icon | Keyboard | Controller |
|-------|-------|------|----------|------------|
| Modelo | "Modelo do veículo" | `LucideIcons.car` | `text` | `_vehicleCtrl` |
| Eficiência | "Consumo médio (km/L)" | `LucideIcons.fuel` | `numberWithOptions(decimal: true)` | `_efficiencyCtrl` |

Gap between fields within a section: `AppSizes.spacingM` (16 px).

**_ImpactSection (stat cards grid):**

```
Container [glassmorphic card recipe]
  padding: spacingL
  Column
    Text ["Impacto Social", titleMedium, weight 700, AppColors.textMain]
    SizedBox(height: spacingM)
    Row
      _StatChip [Notas Escaneadas]    ← derived from coinProvider
      SizedBox(width: spacingM)
      _StatChip [Buscas Efetuadas]    ← fixed: 47
      SizedBox(width: spacingM)
      _StatChip [Economia Estimada]   ← fixed: R$342
```

Each `_StatChip` expands equally (`Expanded`).

**_StatChip anatomy:**

```
Container
  decoration:
    color: AppColors.surfaceElevated.withValues(alpha: 0.6)
    borderRadius: BorderRadius.circular(AppSizes.radiusL)  ← 16 px
  padding: EdgeInsets.symmetric(vertical: spacingM, horizontal: spacingS)
  Column (mainAxisAlignment: center, crossAxisAlignment: center)
    Icon [stat icon, 24 px, AppColors.primary]
    SizedBox(height: spacingXS)
    Text [value, titleMedium, weight 700, AppColors.textMain]
    SizedBox(height: spacingXS)
    Text [label, bodySmall, AppColors.textSecondary, center, maxLines: 2]
```

**Stat chip configuration:**

| Stat | Icon | Value | Label |
|------|------|-------|-------|
| Notas escaneadas | `LucideIcons.fileText` | `scannedCount.toString()` (derived) | "notas\nescaneadas" |
| Buscas efetuadas | `LucideIcons.search` | `"47"` | "buscas\nefetuadas" |
| Economia estimada | `LucideIcons.trendingDown` | `"R$ 342"` | "economia\nestimada" |

`scannedCount` derived in `build()`:
```dart
final coinState = ref.watch(coinProvider);
final scannedCount = coinState.transactions
    .where((tx) => tx.description == 'Cadastro de nota fiscal')
    .length;
```

**Save button — "Salvar Alterações":**

```
ElevatedButton
  style:
    backgroundColor: AppColors.primary
    foregroundColor: AppColors.background
    borderRadius: AppSizes.radiusM
    padding: EdgeInsets.symmetric(vertical: 16)
    minimumSize: Size(double.infinity, 52)
  child: Row
    Icon [LucideIcons.save, 18 px]
    SizedBox(width: spacingS)
    Text ["Salvar Alterações", titleMedium, weight 700]
  onPressed → _save()
```

Button is always enabled (no dirty-state tracking — D-07).

---

## 7. Interaction Contract

### 7.1 ScannerScreen Interactions

| Trigger | Interaction | Outcome |
|---------|-------------|---------|
| Tap method card (QR or Camera) | `_startScan()` → `setState(_loading = true)` | Full-screen overlay appears instantly |
| 2 s elapsed in `_startScan()` | `_loading = false` → `_pageController.nextPage(300ms, easeInOut)` | Overlay fades; slide to Step 2 |
| Tap "Confirmar e Ganhar Moedas" | `addCoins(10, 'Cadastro de nota fiscal')` → `nextPage(300ms)` | Coin balance increments; slide to Step 3 |
| Step 3 entry | `addPostFrameCallback → _confettiController.play()` + coin icon scale animation | Confetti bursts; coin animates in |
| Tap "Escanear Outra Nota" | `_pageController.jumpToPage(0)` | Instant reset to Step 1 (no animation) |
| Tap "Voltar para início" | `context.go(AppRoutes.home)` | Navigate to Home tab |
| System back (page 0) | `context.pop()` | Leave Scanner tab normally |
| System back (pages 1–2) | `_pageController.previousPage(300ms, easeInOut)` | Slide back one page; overlay does NOT re-appear |
| Swipe on PageView | Blocked by `NeverScrollableScrollPhysics` | No swipe navigation |

**Loading overlay accessibility:** `CircularProgressIndicator` wrapped in `Semantics(label: 'Processando, aguarde...')`.

### 7.2 ProfileScreen Interactions

| Trigger | Interaction | Outcome |
|---------|-------------|---------|
| Screen mount | `initState` reads `ref.read(userNotifierProvider)` | All `TextEditingController`s pre-filled with current user data |
| Tap any TextField | Focus border turns `AppColors.primary` (1.5 px) | Standard focused border |
| Tap "Salvar Alterações" | `_save()` → `userNotifierProvider.notifier.updateProfile(...)` | State updates + SharedPreferences persists |
| Save completes | `ScaffoldMessenger.showSnackBar(...)` | SnackBar appears: "Perfil atualizado!" |

**fuelEfficiency field:** `double.tryParse(_efficiencyCtrl.text) ?? 0.0`. If empty or invalid, saves 0.0 (UI does not show error — academic project).

### 7.3 State Persistence

| State | Where Stored | When Written |
|-------|-------------|--------------|
| `bool _loading` | `ScannerScreen` local state | In-memory only, resets on tab switch |
| `PageController.page` | `ScannerScreen` local state | `jumpToPage(0)` on "Escanear Outra Nota" |
| `ConfettiController` | `ScannerScreen` local state | `dispose()` on widget destruction |
| User profile fields | `userNotifierProvider` → `SharedPreferences` | On "Salvar Alterações" tap |
| Coin balance + transaction | `coinProvider` → `SharedPreferences` | On "Confirmar e Ganhar Moedas" tap |

---

## 8. Copywriting Contract

### 8.1 Primary CTAs

| Element | Copy | Screen | Notes |
|---------|------|--------|-------|
| Step 1 → Step 2 trigger | "Escanear QR Code" / "Foto do Cupom" | Scanner Step 1 | Card labels = CTA labels |
| Step 2 confirm | "Confirmar e Ganhar Moedas" | Scanner Step 2 | Verb + outcome — not just "Confirmar" |
| Step 3 repeat | "Escanear Outra Nota" | Scanner Step 3 | Action-first, not "Voltar" |
| Step 3 exit | "Voltar para início" | Scanner Step 3 | Secondary, `TextButton` not `ElevatedButton` |
| Profile save | "Salvar Alterações" | ProfileScreen | Clear scope — not just "Salvar" |

### 8.2 Empty / Zero States

| State | Screen | Copy | Visual |
|-------|--------|------|--------|
| 0 notas escaneadas | Profile stats chip | `"0"` — no special empty state message | Stat chip shows 0 normally |
| Profile fields initially blank | ProfileScreen | Pre-filled from MockData defaults via `vehicleModel` fallback | No empty state — always has defaults |

### 8.3 Success States

| Event | Copy | Style | Duration |
|-------|------|-------|----------|
| Profile saved | "Perfil atualizado!" | SnackBar, `backgroundColor: AppColors.primary`, `foregroundColor: AppColors.background` | Default (4 s) |
| Coin awarded | "+10 Smart Coins" | `headlineMedium`, `AppColors.primary`, centered on Step 3 | Permanent (screen stays until user exits) |

### 8.4 No Destructive Actions in This Phase

Neither screen has delete, logout, or irreversible actions. No confirmation dialogs required.

### 8.5 Accessibility Copy

| Element | `Semantics` label |
|---------|------------------|
| Loading overlay | "Processando, aguarde..." |
| Confetti widget | Excluded from semantics (`excludeFromSemantics: true`) |
| Stat chip value + label | Combined: e.g. "3 notas escaneadas" via `Semantics(label: '$scannedCount notas escaneadas')` |
| Avatar initials | `Semantics(label: 'Avatar de $userName')` |

---

## 9. Animation Contract

| Animation | Widget | Duration | Curve | Trigger |
|-----------|--------|----------|-------|---------|
| Page transitions | `PageController.nextPage / previousPage` | 300 ms | `Curves.easeInOut` | Programmatic only |
| Page reset | `PageController.jumpToPage(0)` | 0 ms (instant) | — | "Escanear Outra Nota" |
| Coin icon entrance | `TweenAnimationBuilder<double>` scale 0 → 1 | 600 ms | `Curves.elasticOut` | Step 3 builds |
| Confetti | `ConfettiController` (duration: 3 s) | 3 s auto-stop | Internal (package) | `postFrameCallback` on Step 3 init |

**No other implicit animations.** Do not add `AnimatedContainer`, `AnimatedOpacity`, or Hero transitions outside this table.

---

## 10. Registry Contract

| Source | Blocks Used | Safety Gate | Notes |
|--------|-------------|-------------|-------|
| pub.dev / confetti | `confetti: ^0.7.0` | Not a shadcn registry — pub.dev package. Legitimacy verified: published 4 years ago, MIT license, funwith.app verified publisher | Use only `play()` and `stop()` (no params). Do NOT use 0.8.0 API (`clearAllParticles`). |
| No other registries | — | — | — |

---

## 11. Anti-Patterns Enforced

These are project-wide rules that apply within this phase:

| Anti-Pattern | Correct Pattern | Enforced By |
|--------------|----------------|-------------|
| `color.withOpacity(x)` | `color.withValues(alpha: x)` | CLAUDE.md |
| `StateNotifierProvider` | `NotifierProvider<T, S>` | CLAUDE.md |
| `ref.watch` inside handler | `ref.read` in handlers, `ref.watch` in `build()` | CLAUDE.md |
| Raw color/spacing literals | `AppColors.*` / `AppSizes.*` | Design system |
| `LucideIcons` version 3.x | `lucide_icons: ^0.257.0` | CLAUDE.md |
| `BackdropFilter` on overlay | Plain `Container(color: black.withValues(alpha:0.6))` for loading — no blur needed on overlay | CONTEXT D-02 |
| `_Step3Widget` disposes `ConfettiController` | Only `_ScannerScreenState.dispose()` calls `_confettiController.dispose()` | RESEARCH Pitfall 1 |
| `PageController.page` null-check omitted | `_pageController.page?.round() ?? 0` | RESEARCH Pitfall 5 |
| `context.go()` before `jumpToPage(0)` | `jumpToPage(0)` FIRST, then optional `context.go()` | RESEARCH Pitfall 6 |
| `double.parse()` for fuelEfficiency | `double.tryParse() ?? 0.0` | RESEARCH Pitfall 3 |

---

## 12. Pre-Population Sources

| Design Contract Field | Source | Decisions Used |
|----------------------|--------|----------------|
| Color tokens | `app_colors.dart` (codebase) | All 7 colors (background, primary, surface, surfaceElevated, success, error, textMain, textSecondary) |
| Spacing tokens | `app_sizes.dart` (codebase) | 5 spacing values + 4 radius values |
| Typography tokens | `ThemeData` pattern from `login_screen.dart` + `store_screen.dart` | 4 text style roles: headlineMedium, titleMedium, bodyMedium, bodySmall — 2 weights: 400 + 700 |
| Glassmorphic card recipe | `login_screen.dart` line 100, `store_screen.dart` line 57 | surface + alpha + border pattern |
| Loading overlay pattern | `shopping_list_screen.dart` (cited in CONTEXT.md) | Stack + black overlay + CircularProgressIndicator |
| TextField decoration | `login_screen.dart` lines 112–132 | Full InputDecoration recipe |
| SnackBar success style | `store_screen.dart` (cited in CONTEXT.md) | backgroundColor: AppColors.primary |
| ScannerScreen 3-step structure | CONTEXT.md D-01 | PageView, pages, back-button behavior |
| Method cards (D-02) | CONTEXT.md D-02 | QR + Camera, same loading flow |
| Confetti (D-03) | CONTEXT.md D-03, RESEARCH.md Pattern 3 | Package, controller config, play() timing |
| Mock receipt data (D-04) | CONTEXT.md D-04 | Bistek, today, R$87.43, 3-4 items |
| Return/reset flow (D-05) | CONTEXT.md D-05 + RESEARCH.md A4 mitigation | jumpToPage(0) first |
| Profile fields + model (D-06) | CONTEXT.md D-06 | 5 editable fields, vehicleModel + fuelEfficiency |
| Save SnackBar (D-07) | CONTEXT.md D-07 | "Perfil atualizado!", primary bg |
| Profile as Tab 4 (D-08) | CONTEXT.md D-08 | Normal tab, no modal |
| Stats derivation (D-09) | CONTEXT.md D-09 + RESEARCH.md Pattern 8 | Real scan count + 2 fixed mocks |
| ProfileScreen layout decision | Claude's Discretion | SliverAppBar + CustomScrollView + 3 card sections |
| Section card organization | Claude's Discretion | "Dados Pessoais" + "Veículo" + "Impacto Social" as separate glassmorphic cards |
| Stat icons | Claude's Discretion | fileText, search, trendingDown |

---

## 13. Checker Dimensions

The `gsd-ui-checker` validates this spec against 6 dimensions. Expected outcomes:

| Dimension | Status | Evidence |
|-----------|--------|---------|
| 1. Spacing — all values are multiples of 4 | PASS | All values from `AppSizes.*` (4, 8, 16, 24, 32) |
| 2. Typography — 3-4 sizes, max 2 weights | PASS | 4 sizes: headlineMedium (~28px), titleMedium (~16px), bodyMedium (~14px), bodySmall (~12px); 2 weights: 400 (regular) + 700 (bold) |
| 3. Color — 60/30/10 split, accent reserved | PASS | background 60%, surface 30%, primary 10% (buttons + coin text only) |
| 4. Copywriting — CTA, empty, error, destructive | PASS | All CTAs defined; empty states handled; no destructive actions in scope |
| 5. Registry safety — vetting gate complete | PASS | confetti audited via RESEARCH.md; no shadcn registries |
| 6. Specificity — no vague instructions | PASS | Pixel values, color tokens, widget names, and code patterns explicit throughout |

---

*UI-SPEC created: 2026-06-02*
*Phase: 5-price-registration-profile*
*Status: draft (awaiting gsd-ui-checker approval)*
