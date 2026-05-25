# Features Research — Lista Smart

**Domain:** Mobile shopping list + supermarket price comparison + gamified loyalty
**Researched:** 2026-05-25
**Research mode:** Ecosystem — UX/feature expectations for shopping list and price comparison apps

---

## Table Stakes (Must Have)

Features users expect in 2025. If missing, the app feels broken or unfinished even in an academic demo.

### 1. Instant List Editing — No Friction Add/Remove

**Why expected:** Grocery list apps live or die by how fast you can tap "add" and move on. Any extra tap feels like a bug.

**Must work:**
- FAB opens an add-item bottom sheet or inline field immediately
- Tapping a list item checks it off with a visual strike-through or fade
- Swipe-to-delete with a red background leave-behind icon (users expect this muscle memory from iOS/Android defaults)
- Quantity control is inline — stepper right on the list tile, not on a separate screen

**Flutter implementation:** `Dismissible` widget for swipe-delete. `flutter_slidable` (pub.dev) for richer swipe actions (edit left, delete right). `CheckboxListTile` or custom `ListTile` with checkbox for check-off. Inline quantity with `Row` containing `-` `[n]` `+` buttons.

**Complexity:** Low

---

### 2. Persistent State Across Sessions

**Why expected:** Users expect to close and reopen the app and find their list exactly where they left it. Loss of list data on app restart is a critical trust failure.

**Must work:**
- Cart items survive app kill
- User preferences (vehicle config, profile) persist
- Smart Coins balance persists

**Flutter implementation:** `shared_preferences` for simple key-value (coins, user profile). `sqflite` or `hive` for list items if the data model is relational. For an academic project with mocked data, `hive` with typed adapters is the lowest-friction choice.

**Complexity:** Low–Medium (Hive setup is straightforward; sqflite requires more boilerplate)

---

### 3. Search/Filter on Home and List Screens

**Why expected:** When a product grid or list exceeds ~10 items, users immediately look for a search bar. Its absence feels like a broken feature rather than a design choice.

**Must work:**
- Search bar on home (product grid) filters results as the user types
- Shopping list has a filter or search if the list grows long
- Empty state shown when no results match (not a blank screen)

**Flutter implementation:** `TextField` with `onChanged` that filters a local `List<Product>` in state. `AnimatedList` or a filtered `ListView.builder`. Empty state as a `Column` with an icon and message, not a null widget.

**Complexity:** Low

---

### 4. Visual Price Winner Highlight in Comparison Screen

**Why expected:** The core promise of a price comparison app is "tell me which store is cheapest." If the UI doesn't visually call this out, users have to do the math themselves — the app has failed its job.

**Must work:**
- Cheapest store for each product is highlighted (green badge, checkmark, "Melhor Preço" label)
- Total cart cost per store is shown prominently
- Price difference expressed in currency ("R$ 4,20 mais barato") not just percentage

**Flutter implementation:** `DataTable` is too rigid for mobile — use a horizontal-scrollable `Row` of `Card` widgets, one per store, with a `Container` decoration change (border/background) for the winner. Alternatively a `ListView` of `ProductComparisonTile` rows with colored dots per store.

**Complexity:** Medium

---

### 5. Form Validation with Inline Feedback

**Why expected:** Every form in the app (login, price registration, profile edit, vehicle config) must validate inline. A submit-then-fail pattern feels like a 2010 web app.

**Must work:**
- Email format validated on unfocus (not on submit)
- Password minimum length shown as helper text before the user even tries to submit
- Vehicle fuel efficiency field rejects non-numeric input immediately
- Error messages appear adjacent to the field, not in a SnackBar

**Flutter implementation:** `Form` + `GlobalKey<FormState>` + `TextFormField` with `validator` callbacks. Use `autovalidateMode: AutovalidateMode.onUserInteraction` for inline validation without pre-emptive errors on first render.

**Complexity:** Low

---

### 6. Loading States and Skeleton Screens

**Why expected:** Even with mocked local data, transitions between screens need micro-feedback. A blank flash between screens or an unstyled grey box looks unfinished.

**Must work:**
- Any screen that "loads" data (even from local state) shows a brief shimmer or loading indicator
- Price comparison screen shows a skeleton while "calculating" even if it's a 300ms artificial delay
- Empty states have illustrations, not blank screens

**Flutter implementation:** `shimmer` package (pub.dev) for skeleton cards. `CircularProgressIndicator` inside a `FutureBuilder` for anything async. Empty states use `Column` with an SVG asset and a CTA button.

**Complexity:** Low

---

### 7. Bottom Navigation — 4–5 Primary Destinations

**Why expected:** Material 3 bottom navigation is the standard primary navigation pattern for mobile apps with multiple top-level sections. Users expect thumb-reachable primary navigation.

**Must work:**
- NavigationBar (Material 3 `NavigationBar`, not deprecated `BottomNavigationBar`) with 4–5 destinations
- Active destination highlighted with pill indicator (M3 default)
- No nested bottom navs — all primary screens are top-level

**Suggested destinations:** Home, Lista (cart), Comparar, Smart Coins, Perfil

**Flutter implementation:** `NavigationBar` with `NavigationDestination` children. State managed at the root `Scaffold` level with `IndexedStack` to preserve scroll position across tab switches.

**Complexity:** Low

---

### 8. Profile Screen — Vehicle Configuration That Actually Drives the Travel Cost Feature

**Why expected:** If the app advertises travel cost calculation, the vehicle config input cannot be buried or feel like an afterthought. Users expect to configure it once and have it propagate everywhere.

**Must work:**
- Vehicle brand/model (or just fuel efficiency in L/100km)
- Fuel price input (manual, since data is mocked)
- Changes immediately update travel cost estimates in the cart screen

**Flutter implementation:** `DropdownButtonFormField` for vehicle type. `TextFormField` with `inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]` for numeric fields. State propagated via Provider or Riverpod.

**Complexity:** Medium (the connection between profile config and cart cost toggle is the tricky part)

---

## Differentiators (Demo Wow Factor)

Features that go beyond user expectation and will impress an academic evaluator. These are compelling because they are coherent, not because they are complex.

### 1. Three-Step Price Registration Flow with Celebration Screen

**Why compelling:** The "scan → confirm → celebrate" flow is a concrete, demonstrable user journey that shows product thinking. The celebrate step (confetti + coin award animation) creates a memorable "aha" moment during the demo that no amount of code explanation replicates.

**What makes it impressive:**
- Step indicator (1 / 2 / 3) so the evaluator understands the flow at a glance
- Barcode scan step with camera preview (even if mocked — a fake "scan" with a pre-filled result is fine for academic context)
- Celebration screen with animated coin counter incrementing and confetti burst

**Flutter implementation:** `confetti` package (pub.dev) on the celebration screen. `lottie` package (pub.dev) for coin-spin or star-burst animation using a free LottieFiles JSON. Stepper UI with `Step` widgets or a custom `PageView` with a progress indicator.

**Complexity:** Medium

---

### 2. Travel Cost Toggle in Cart — "Is It Worth Driving?"

**Why compelling:** This is genuinely novel in the grocery app space. It reframes price comparison from "which store is cheapest?" to "which store is cheapest *after* I account for gas?" This is a real user problem that competitors don't solve. It's also visually demonstrable in seconds during a demo.

**What makes it impressive:**
- Toggle switch on the cart/comparison screen: "Incluir custo de deslocamento"
- When toggled on, each store's total updates to include fuel cost (distance × vehicle efficiency × fuel price)
- The cheapest winner can flip when travel cost is included — this is the "wow" moment

**What to avoid:** Don't use real GPS or map APIs — hardcode distances between a fixed "home" location and each supermarket. The academic context makes this completely acceptable.

**Flutter implementation:** `Switch.adaptive` on the comparison card. Distance values hardcoded per store in a constant file. Cost formula: `(distance_km / efficiency_kmpl) * fuel_price_per_liter`. Provider updates total display reactively when toggle changes.

**Complexity:** Medium

---

### 3. Smart Coins Level Progress Bar with Visual Tier System

**Why compelling:** Level progress (Bronze → Silver → Gold) with a visible progress bar is a UX pattern users recognize from apps like iFood, Rappi, and Nubank. It signals "this app rewards loyalty." A filled progress bar that's 70% full during a demo is more compelling than a balance number.

**What makes it impressive:**
- Level badge (icon + tier name) next to user avatar on the profile and coins screens
- Animated progress bar (`TweenAnimationBuilder` on level progress) that fills when coins are earned
- Next tier reward shown below the bar ("Faltam 120 moedas para Prata")

**Flutter implementation:** `LinearProgressIndicator` with a custom `ValueListenableBuilder` or `TweenAnimationBuilder` for smooth fill animation. Level data modeled as an enum with thresholds. Store screen shows "packages" as `GridView` of purchasable reward cards.

**Complexity:** Medium

---

### 4. Receipt Submission Flow Driving Actual Data

**Why compelling:** The receipt scan is the data flywheel mechanic — users submit prices, prices improve, users earn coins. Even mocked, presenting this feedback loop coherently (submit receipt → prices updated → coins earned) tells a product story that demonstrates systems thinking.

**What makes it impressive:** The celebrated screen after submission shows both the coins earned AND a message like "Você ajudou 47 usuários a economizar!" (mocked number). This mimics real social-proof mechanics from apps like Waze and Citizen.

**Flutter implementation:** Static counter in shared state. After submission confirmation, increment a `savedUsersCount` mock variable and display it on the celebration screen.

**Complexity:** Low (the "wow" is in the copy and animation, not the logic)

---

### 5. Impact Stats on Profile Screen

**Why compelling:** "Total economizado: R$ 284,50" and "Preços registrados: 12" are vanity metrics that feel rewarding to a user and demonstrate product completeness to an evaluator. They show the app tracks user history, even if that history is mocked.

**What makes it impressive:** Animated number counters on first load (`CountUp`-style animation or `TweenAnimationBuilder`). Segmented into "este mês" vs "total" to imply historical data depth.

**Flutter implementation:** `TweenAnimationBuilder<double>` animating from 0 to the target value, with `toStringAsFixed(2)` formatting. Values stored in `hive` and accumulated across sessions.

**Complexity:** Low

---

## Anti-Features (Skip These)

Things that look good on paper but add complexity without academic evaluation value.

### 1. Real Camera Barcode Scanning

**Why skip:** Integrating `mobile_scanner` or `barcode_scan2` for real barcode reading adds platform-specific setup (Android manifest permissions, iOS Info.plist), physical device testing requirements, and fragile camera lifecycle management. The academic evaluator will not scan a real product. A mock scan (button tap populates product fields from a hardcoded list) delivers 100% of the demo value at 5% of the complexity.

**Instead:** Simulate the scan with a loading animation followed by a pre-filled form. Add a tooltip: "Simulação — em produção, a câmera seria ativada aqui."

---

### 2. Real GPS / Maps Integration

**Why skip:** Google Maps SDK, permission handling, location services across iOS/Android, and calculating real distances to real stores adds weeks of integration complexity. The travel cost feature works perfectly with hardcoded distances (e.g., Bistek = 2.3 km, Giassi = 4.1 km, Angeloni = 5.8 km from a fixed home point).

**Instead:** Use constants. The formula is the differentiator, not the mapping.

---

### 3. Network / API Calls

**Why skip:** The spec explicitly calls for mocked/local data. Any real API introduces async failure modes, CORS issues, API key management, and network-dependent demo reliability. A demo that fails because of Wi-Fi is a disaster.

**Instead:** All data in `hive` or in-memory singletons. Use realistic fake data (real product names, real store names, plausible prices for SC region).

---

### 4. Push Notifications

**Why skip:** Push notification setup requires FCM, platform-specific registration, and background app entitlements. It cannot be demonstrated in a classroom demo without a live server. Zero academic value.

**Instead:** In-app notifications using `SnackBar` or a `Banner` widget for coin awards.

---

### 5. Social Features / Sharing

**Why skip:** Leaderboards, friend comparisons, or share-to-social features require multi-user state and server infrastructure. Scope creep with no evaluable return in a single-user academic demo.

**Instead:** The "você ajudou 47 usuários" copy on the celebration screen implies social without requiring it.

---

### 6. Onboarding Carousel

**Why skip:** Multi-screen onboarding flows are a pattern that testers routinely skip by swiping fast. They delay the evaluator reaching the actual app. For an academic demo, the app should open directly to a compelling login screen or, after first login, directly to the home dashboard.

**Instead:** A single well-designed login screen with clear value propositions stated in subtext is sufficient.

---

### 7. Dark Mode Toggle

**Why skip:** Supporting both light and dark mode requires auditing every custom color, every asset, and every shadow across every screen. `ThemeData` with `ThemeMode.system` is free, but custom components often break. Pick one theme and execute it well.

**Instead:** Choose light mode. Use M3 color seeds (`ColorScheme.fromSeed`) for consistent theming with minimal effort.

---

## UX Patterns to Follow

Specific Flutter patterns matched to each major screen in the spec.

### Login Screen

- **Pattern:** Centered card on a full-bleed background gradient. Logo at top, form below, CTA button at bottom.
- **Validation:** `AutovalidateMode.onUserInteraction` — validate on blur, not on submit.
- **Button state:** Disable submit button when form is invalid using `Form.of(context)?.validate()`. Show `CircularProgressIndicator` inside button for the 1–2s fake auth delay.
- **Widget stack:** `Scaffold` → `Stack` (gradient bg + centered `Card`) → `Form` → `Column` of `TextFormField` + `ElevatedButton`.
- **Pitfall to avoid:** Don't use `AlertDialog` for error feedback — use inline `TextFormField` error strings.

---

### Home Dashboard

- **Pattern:** `CustomScrollView` with a `SliverAppBar` (collapses on scroll) + search bar that sticks below the collapsed app bar + `SliverGrid` for product cards.
- **Grid:** `SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2)` for portrait. Each product card is a `Card` with `InkWell`, product image (placeholder `ColoredBox` for mocked data), name, and cheapest price badge.
- **FAB:** `FloatingActionButton.extended` with "Adicionar à Lista" label. Anchored bottom-right. Expands to form on tap.
- **Search:** `TextField` in the `SliverPersistentHeader` that filters the product list reactively.
- **Empty state:** Full-screen `Column` with illustration asset and "Nenhum produto encontrado" + a "Limpar busca" text button.

---

### Shopping List / Cart Screen

- **Pattern:** `ListView.builder` of dismissible `ListTile`-based items. Sticky `BottomSheet`-style summary bar pinned to bottom showing total + travel cost toggle.
- **Item tile:** Custom `ListTile` with leading `Checkbox`, title product name, subtitle category, trailing quantity stepper (`-` `[n]` `+`). Checked items visually dimmed (`Opacity(0.4)`) and struck through (`TextDecoration.lineThrough`).
- **Swipe to delete:** `Dismissible` with red background and `Icons.delete_outline` icon. `onDismissed` removes from list and shows `SnackBar` with "Desfazer" action.
- **Travel cost toggle:** `SwitchListTile.adaptive` inside the bottom summary card. When toggled, `AnimatedSwitcher` transitions the total amount text.
- **Pitfall to avoid:** Don't use `StatefulWidget` per item for checked state — lift checked state into the parent list model.

---

### Price Comparison Screen

- **Pattern:** Top tab row (one tab per store: Bistek | Giassi | Angeloni | Comparar Todos). "Comparar Todos" tab is the main view.
- **Comparison view:** `ListView` of product rows. Each row shows the product name + price at each store as colored chips. Cheapest price chip uses `ThemeData`'s `primaryColor` fill; others use outline style.
- **Store total bar:** Sticky `Card` at the top showing total basket cost per store. Winner store card is elevated with a "Melhor Preço" `Badge` overlay.
- **Mobile-responsive table:** Avoid `DataTable` — it overflows on small screens. Use a `Row` of `Expanded` `Column` widgets per store, each listing prices vertically.
- **Travel cost:** If toggled in cart, update store totals here too. Shared state via Provider.

---

### Smart Coins Store Screen

- **Pattern:** `CustomScrollView` with:
  - `SliverToBoxAdapter` for balance hero (large coin icon + animated balance counter + level progress bar)
  - `SliverToBoxAdapter` for tier card (current level badge + next level threshold + progress bar)
  - `SliverGrid` for reward packages (e.g., "Pacote Bronze — 100 moedas", "Vale Desconto — 250 moedas")
  - `SliverList` for transaction history at the bottom
- **Balance hero:** `TweenAnimationBuilder` on first mount, counting up to current balance.
- **Progress bar:** `LinearProgressIndicator` in a `ClipRRect` with `BorderRadius.circular(8)` for rounded ends.
- **Packages:** `Card` with `ElevatedButton` that triggers a confirmation `AlertDialog` before deducting coins.
- **Transaction history:** `ListTile` with leading colored dot (green = earned, red = spent), title description, trailing amount with sign.

---

### Price Registration Flow (3-step)

- **Pattern:** `PageView` (not a `Stepper` — PageView gives full-screen transitions) with a custom step indicator row at the top.
- **Step 1 — Scan:** Centered phone illustration, "Simular Leitura" `ElevatedButton`. On tap: show `CircularProgressIndicator` for 1.5s, then navigate to step 2 with product pre-filled.
- **Step 2 — Confirm:** `Form` with product name, store `DropdownButtonFormField`, price `TextFormField`, date. "Confirmar" button validates and advances to step 3.
- **Step 3 — Celebrate:** `ConfettiWidget` blasting from top-center. Coin counter animating from previous balance to new balance. "Você ganhou +10 moedas!" text with `ScaleTransition`. "Voltar ao início" button navigates home.
- **Back navigation:** Custom back button on steps 1 and 2. Step 3 has no back — only "Done."

---

### Profile Screen

- **Pattern:** `ListView` with sections separated by `Divider` and section header `ListTile`s (grey text, no interaction).
- **Avatar:** `CircleAvatar` with initials as fallback. Tapping opens an `AlertDialog` for name edit (keep it simple).
- **Vehicle section:** `ListTile`-based form rows that open `ModalBottomSheet` editors. Values shown as `subtitle` on the tile.
- **Impact stats:** `Row` of `Card` widgets, each showing an animated number counter + label. Use `TweenAnimationBuilder`.
- **Logout:** Destructive `TextButton` in red at the bottom with a confirmation `AlertDialog`. Clears state and navigates to login.

---

## Feature Complexity Matrix

| Feature | Complexity | Priority | Implementation Notes |
|---|---|---|---|
| Login screen (simulated auth) | Low | P0 | Form + GlobalKey + fake 1.5s delay |
| Home dashboard grid + search | Medium | P0 | SliverAppBar + SliverGrid + filter state |
| FAB → add item flow | Low | P0 | BottomSheet or inline TextField |
| Shopping list with check-off | Low | P0 | Dismissible + CheckboxListTile |
| Inline quantity stepper | Low | P0 | Row with IconButton and Text |
| Persistent state (Hive) | Medium | P0 | Hive boxes for cart, coins, profile |
| Price comparison screen | Medium | P0 | Custom row layout, winner highlight |
| Travel cost toggle | Medium | P1 | Switch + formula + Provider reactivity |
| Smart Coins balance + level bar | Medium | P1 | TweenAnimationBuilder + LinearProgressIndicator |
| Smart Coins store (packages) | Low | P1 | GridView + AlertDialog confirmation |
| Transaction history | Low | P1 | ListView with signed amounts |
| Price registration step 1 (mock scan) | Low | P1 | Fake loading + pre-filled fields |
| Price registration step 2 (confirm form) | Low | P1 | Standard form validation |
| Price registration step 3 (celebrate) | Medium | P1 | confetti package + TweenAnimationBuilder |
| Profile edit (name, vehicle) | Medium | P1 | ModalBottomSheet editors + Provider |
| Impact stats animated counters | Low | P2 | TweenAnimationBuilder on mount |
| Bottom NavigationBar | Low | P0 | NavigationBar + IndexedStack |
| Empty states (all screens) | Low | P1 | Column with asset + CTA |
| Skeleton loading shimmer | Low | P2 | shimmer package |
| Real barcode scanning | High | SKIP | Unnecessary for academic context |
| GPS / real store distances | High | SKIP | Hardcode distances |
| Push notifications | High | SKIP | No server, no value |
| Dark mode | Medium | SKIP | Pick one theme, execute well |
| Social features / leaderboard | Very High | SKIP | Multi-user state not feasible |
| Onboarding carousel | Low | SKIP | Delays evaluator reaching the app |

---

## Sources

- [Baymard Institute — Ecommerce Mobile App UX Trends](https://baymard.com/blog/mobile-app-ux-trends)
- [Shopping list app recurring items UX analysis — Medium/DesignTalks](https://medium.com/@design_talks/a-shopping-list-app-that-keeps-track-of-regular-purchases-ab1590f8bec4)
- [Grocery Price Comparison App Guide 2025 — Octal Software](https://www.octalsoftware.com/blog/grocery-price-comparison-app)
- [7 Best Grocery Price Comparison Apps 2026 — GroceriesTracker](https://groceriestracker.com/blog/best-grocery-price-comparison-apps-2026)
- [Flutter Dismissible — Official Cookbook](https://docs.flutter.dev/cookbook/gestures/dismissible)
- [flutter_slidable — pub.dev](https://pub.dev/packages/flutter_slidable)
- [confetti — pub.dev](https://pub.dev/packages/confetti)
- [Lottie Animations in Flutter — DianApps](https://dianapps.com/blog/lottie-animations-in-flutter-learn-easy-integration-strategies)
- [Material 3 NavigationBar + NavigationDrawer — Medium](https://binoo11.medium.com/material-3-bottomnavigation-and-navigationdrawer-flutter-428e00d80435)
- [NavigationBar class — Flutter API docs](https://api.flutter.dev/flutter/material/NavigationBar-class.html)
- [Mobile App Gamification — UXCam](https://uxcam.com/blog/gamification-examples-app-best-practices/)
- [Loyalty UX checklist — Voucherify](https://www.voucherify.io/blog/loyalty-programs-ux-and-ui-best-practices)
- [Building a shopping cart in Flutter — LogRocket](https://blog.logrocket.com/building-shopping-cart-flutter/)
- [Pricing Plans UX — Smart Interface Design Patterns](https://smart-interface-design-patterns.com/articles/pricing-plans/)
- [Forms and Validation in Flutter — Medium](https://medium.com/swlh/forms-and-validation-in-flutter-login-ui-f2e7db4e00c9)
