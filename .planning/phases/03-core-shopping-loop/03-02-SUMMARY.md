# Phase 03 Plan 02 — Home UI Slice

**Status:** COMPLETE  
**Date:** 2026-06-02

## What Was Created

### Task 1: Routing Extension + ScannerScreen

- `lib/routing/app_routes.dart` — Added `scanner`, `productDetailPattern`, `comparisonResult` constants and `productDetailPath()` helper.
- `lib/features/price_registration/presentation/scanner_screen.dart` — New placeholder screen with `LucideIcons.scanLine` icon.
- `lib/routing/app_router.dart` — Modified:
  - Tab0 (Home): added subroute `product/:productId` → `ProductDetailScreen`
  - Tab1 (ShoppingList): added subroute `comparison` → `PriceComparisonScreen` (moved from top-level tab)
  - Tab2: replaced `/comparison` with `/scanner` → `ScannerScreen`; NavigationDestination updated to `LucideIcons.scanLine` / "Scanner"

### Task 2: HomeScreen Redesign + Card Widgets + Widget Tests

- `lib/features/home/presentation/home_screen.dart` — Full redesign as `ConsumerStatefulWidget`:
  - Pinned SliverAppBar with initials avatar (navigates to profile) and grid/list toggle icons
  - Pinned sticky search bar via `SliverPersistentHeader` + `_StickySearchBarDelegate`
  - Grid view (2-column, `childAspectRatio: 0.72`) and list view driven by `viewModeProvider`
  - Empty state message when search query yields no results
  - FAB → `context.go(AppRoutes.scanner)`
- `lib/features/home/presentation/product_card_grid.dart` — `ConsumerWidget` with glassmorphic card, image/placeholder, BRL price, star favorite toggle, onTap navigates to product detail.
- `lib/features/home/presentation/product_card_list.dart` — Horizontal `Row` layout variant with 64×64 image, name/brand/price column, star toggle.
- `test/features/home/home_screen_test.dart` — 6 widget tests covering HOME-01 (toggle icons present, switching modes), HOME-03 (products render), HOME-07 (GestureDetector on cards), search empty-state, and FAB presence.

### Task 3: ProductDetailScreen + NutritionalInfoBottomSheet

- `lib/features/home/presentation/product_detail_screen.dart` — `ConsumerWidget` with:
  - 200px product image with placeholder
  - Metadata rows for department/category/subcategory/EAN (skip if empty)
  - Per-supermarket price table with lowest price highlighted (`AppColors.primary` bg at 10% alpha + primary text)
  - FilledButton "Adicionar ao Carrinho" → `cartProvider.notifier.addItem()` + SnackBar
  - OutlinedButton "Ver Tabela Nutricional" → `showModalBottomSheet` (disabled if `nutritionalInfo == null`)
- `lib/features/home/presentation/nutritional_info_bottom_sheet.dart` — `DraggableScrollableSheet` (initial: 0.5, max: 0.85, min: 0.3) with `scrollController` passed to `ListView`; shows 6 nutrients + servingSize; "Fechar Tabela" TextButton → `Navigator.pop`.

## Key Decisions

- `ConsumerStatefulWidget` used for `HomeScreen` to manage `TextEditingController` lifecycle; `ref` accessed as field (not build parameter — that's `ConsumerWidget` pattern).
- Subroutes use relative paths (`product/:productId`, `comparison`) without leading `/` as required by GoRouter's nested route spec.
- `withValues(alpha:)` used throughout — no `withOpacity()` calls.
- All colors/spacing use `AppColors.*` / `AppSizes.*` constants — no literals.
- `context.push()` for product detail subroute; `context.go()` for scanner FAB (tab-level navigation).
- `favoritesProvider.select((favs) => favs.contains(product.id))` for fine-grained rebuild on card widgets.

## Verification Results

- `flutter analyze lib/routing/ lib/features/price_registration/ lib/features/home/presentation/` → **No issues found**
- `flutter test test/features/home/home_screen_test.dart` → **6/6 passed**
- `flutter test` → **74/74 passed** (all pre-existing tests continue green)
