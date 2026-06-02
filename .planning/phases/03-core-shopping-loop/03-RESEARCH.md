# Phase 3: Core Shopping Loop — Research

**Researched:** 2026-06-01
**Domain:** Flutter UI (Slivers, Riverpod derived providers, go_router subroutes, SharedPreferences)
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01** — `MockData.prices` usa `Map<String, Map<String, double>>` (productId → supermarket → price)
- **D-02** — Comparação inclui Bistek, Giassi, Angeloni e Atacadão (todos os 4)
- **D-03** — Comparação calcula custo total do carrinho inteiro (não produto individual). Fórmula: `totalCost = Σ(price[productId][supermarket] * qty) + fuelCost`; `fuelCost = (distance * 2 / fuelEfficiency) * fuelPrice`
- **D-04** — Tab 3 renomeado de "Comparar" para "Scanner" (placeholder). `PriceComparisonScreen` acessível via botão fixo no rodapé de `ShoppingListScreen` quando `cart.isNotEmpty`
- **D-05** — Veículo padrão: `Vehicle(model: 'Fiat Uno', fuelEfficiency: 12.0)` — campo correto é `fuelEfficiencyKmPerLiter` (já existe no model)
- **D-06** — `MockData.fuelPrice = 6.50` (R$/L), constante em Phase 3
- **D-07** — Toggle combustível persiste via SharedPreferences. Provider: `NotifierProvider<FuelToggleNotifier, bool>`. Key: `'lista_smart_fuel_toggle'`, default `true`
- **D-08** — Tap no card da Home → `/home/product/:productId` subrota
- **D-09** — `ProductDetailScreen` exibe preços de todos os 4 supermercados; destaca o menor preço
- **D-10** — `Product` ganha `ean`, `subcategory`, `department`, `NutritionalInfo`
- **D-11** — `Image.network` com `errorBuilder` retornando `LucideIcons.packageOpen` + texto. Sem novo pacote
- **D-12** — Campo de busca sempre visível via `SliverPersistentHeader(pinned: true)`. `searchQueryProvider` filtra reativamente sem debounce
- **D-13** — SliverAppBar: leading = badge iniciais do usuário, title = "Home", actions = [layoutGrid, list toggles]
- **D-14** — FAB `LucideIcons.scanLine` navega para tab Scanner (índice 2)

### Claude's Discretion

Nenhuma área de discrição declarada no CONTEXT.md. Todas as decisões estão locked.

### Deferred Ideas (OUT OF SCOPE)

- Preço de combustível editável pelo usuário → Phase 5 (Perfil)
- Dados de veículo editáveis → Phase 5 (Perfil)
- Integração real de scanner → Phase 4
- Animações de celebração → Phase 4
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| HOME-01 | Alternância grid/lista de produtos | `viewModeProvider` (NotifierProvider), `SliverGrid` vs `SliverList` |
| HOME-02 | Busca com filtro reativo no header | `searchQueryProvider` + `filteredProductsProvider` (Provider derivado) |
| HOME-03 | Cards exibem imagem, marca, nome, tag e preço médio | `ProductCardGrid` / `ProductCardList` widgets com `Image.network` |
| HOME-04 | Favoritar/desfavoritar com botão estrela dinâmico | `favoritesProvider` (já existe); `LucideIcons.star` toggle |
| HOME-05 | FAB navega para Scanner tab | `navigationShell.goBranch(2)` via `StatefulShellRoute` |
| HOME-06 | Badge de iniciais navega para `/profile` | `context.push(AppRoutes.profile)` no leading do SliverAppBar |
| HOME-07 | Tap no card → ProductDetailScreen (mobile) | `context.push('/home/product/$id')` via subrota de `/home` |
| SHOP-01 | Ver itens do carrinho com nome, marca, imagem | `cartProvider` com `CartItem` existente |
| SHOP-02 | Controle +/- de quantidade inline | `CartNotifier.incrementItem` / `decrementItem` (novos métodos) |
| SHOP-03 | Remover item individualmente | `CartNotifier.removeItem` (já existe); ícone X |
| SHOP-04 | Switch "Considerar Custo de Deslocamento" | `fuelToggleProvider` com SharedPrefs |
| SHOP-05 | Limpar carrinho com confirmação AlertDialog | `CartNotifier.clear()` (já existe) + `showDialog` |
| COMP-01 | Ver preços em pelo menos 3 supermercados (mock) | `comparisonResultsProvider` derivado de `pricesProvider` |
| COMP-02 | Menor preço visualmente destacado | card com `border: AppColors.primary`, badge "Melhor opção" |
| COMP-03 | Cada linha: preço + distância + combustível = total | `SupermarketTotal` model com campos `productsCost`, `fuelCost`, `distanceKm`, `totalCost` |
</phase_requirements>

---

## Summary

Esta fase implementa o loop central de compras do Lista Smart. O trabalho se divide em três camadas: extensões de model/dados (Product + NutritionalInfo + MockData), novos providers Riverpod (8 providers derivados), e 4 telas (HomeScreen redesign + ProductDetailScreen + ShoppingListScreen + PriceComparisonScreen) mais 1 bottom sheet.

A infraestrutura de roteamento existente (StatefulShellRoute.indexedStack com 5 tabs) já está configurada corretamente para preservar scroll por tab. O que precisa mudar é: (1) adicionar subrota `/home/product/:productId` dentro do branch tab0, (2) adicionar subrota `/lista/comparison` dentro do branch tab1 (que atualmente aponta para `/shopping-list`), e (3) renomear tab2 de "Comparar" para "Scanner". Não é preciso refatorar a estrutura do router.

A Vehicle model já existe em `lib/features/profile/domain/vehicle.dart` com campo `fuelEfficiencyKmPerLiter` (CONTEXT.md D-05 usa `fuelEfficiency` como nome de campo — o executor deve usar o nome real do model existente). MockData não tem `prices`, `fuelPrice`, nem `vehicle` — esses campos precisam ser adicionados inteiramente. O Product model atual em `lib/features/profile/domain/product.dart` não tem `ean`, `subcategory`, `department`, nem `nutritionalInfo` — precisam ser adicionados (breaking change requer atualizar MockData.products também).

**Primary recommendation:** Execute na ordem data → providers → router → telas. Telas dependem de providers; providers dependem de models e MockData. Quebrar essa ordem causa erros de compilação difíceis de depurar.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Listagem de produtos | Widget (HomeScreen) | Provider (filteredProductsProvider) | Renderização é UI; filtragem é estado derivado |
| Busca por nome | Provider (searchQueryProvider) | Widget (TextField) | Estado da query precisa sobreviver a rebuilds |
| Toggle grid/lista | Provider (viewModeProvider) | Widget (IconButton) | Estado precisa ser compartilhado entre HomeScreen e cards |
| Favoritar produto | Provider (favoritesProvider) | Widget (estrela) | Favoritesnotifier já existe e persiste em SharedPrefs |
| Detalhes do produto | Widget (ProductDetailScreen) | Provider (productsProvider) | Lookup por ID é derivação pura do provider |
| Preços por supermercado | Provider (pricesProvider) | Widget (ProductDetailScreen) | Dados read-only do MockData |
| Carrinho (CRUD) | Provider (cartProvider) | Widget (ShoppingListScreen) | Já existe — CartNotifier com SharedPrefs |
| Toggle combustível | Provider (fuelToggleProvider) | Widget (Switch) | Estado persistido, afeta múltiplas telas |
| Cálculo de comparação | Provider (comparisonResultsProvider) | Widget (PriceComparisonScreen) | Fórmula é lógica de negócio, não UI |
| Navegação entre tabs | Router (StatefulShellRoute) | Widget (FAB, botão "Comparar") | go_router 14.x gerencia branches |
| Informação nutricional | Widget (NutritionalInfoBottomSheet) | Model (NutritionalInfo) | UI pura — sem estado global necessário |

---

## Standard Stack

### Core (todos já instalados — nenhum pacote novo necessário)

| Library | Resolved Version | Purpose | Why Standard |
|---------|-----------------|---------|--------------|
| flutter_riverpod | 2.6.1 | State management | Course-prescribed; `NotifierProvider<T, S>` é o padrão desta fase |
| go_router | 14.8.1 | Declarative routing + subrotas | Course-prescribed; subrotas dentro de `StatefulShellBranch` são suportadas em 14.x |
| shared_preferences | 2.5.3 | Persistência do fuelToggle | Já usado em cartProvider e favoritesProvider — mesmo padrão |
| lucide_icons | 0.257.0 | Ícones (layoutGrid, list, scanLine, star, packageOpen, shoppingCart, trash2, x, info, search) | Único pacote de ícones autorizado |
| google_fonts | 6.3.2 | Tipografia Inter (herdada) | Já inicializado — sem ação necessária |
| intl | 0.19.0 | Formatação BRL (NumberFormat.currency) | Já instalado; usar para formatar preços `R$ X,XX` |

### Sem dependências novas

Esta fase não requer nenhum pacote adicional no pubspec.yaml. Todos os recursos necessários (Image.network, DraggableScrollableSheet, AlertDialog, Switch, SliverPersistentHeader) são widgets nativos do Flutter SDK. [VERIFIED: verificado contra pubspec.yaml existente e requisitos da fase]

---

## Package Legitimacy Audit

> Nenhum pacote novo será instalado nesta fase. Esta seção confirma que nenhuma adição ao pubspec.yaml é necessária.

**Packages removed due to slopcheck:** none
**Packages flagged as suspicious:** none

---

## Architecture Patterns

### System Architecture Diagram

```
User Input
    │
    ├─ TextField (search) ──► searchQueryProvider (NotifierProvider<String>)
    │                              │
    ├─ IconButton (grid/list) ──► viewModeProvider ──► HomeScreen build()
    │                                                        │
    │                         productsProvider ──────────────┤
    │                         (Provider<List<Product>>)      │
    │                              │                         │
    │                         filteredProductsProvider ──► SliverGrid / SliverList
    │                         (Provider<List<Product>>)         │
    │                              │                            │
    ├─ Tap card ──► context.push('/home/product/:id')    ProductCardGrid / ProductCardList
    │                    │                                    (favoritesProvider)
    │                    ▼
    │              ProductDetailScreen
    │              pricesProvider[productId] → todos os 4 supermercados
    │              FilledButton "Adicionar ao Carrinho"
    │                    │
    │                    ▼
    │              cartProvider (CartNotifier)
    │              SharedPrefs serialized
    │
    ├─ ShoppingListScreen (/lista)
    │   cartProvider.state (List<CartItem>)
    │   fuelToggleProvider (bool, SharedPrefs)
    │   totalEstimado = Σ(item.unitPrice * item.quantity)  [averagePrice]
    │   FilledButton "Comparar" → context.push('/lista/comparison')
    │
    └─ PriceComparisonScreen (/lista/comparison)
        comparisonResultsProvider (Provider<List<SupermarketTotal>>)
        ├── cartProvider
        ├── pricesProvider
        ├── vehicleProvider
        ├── fuelToggleProvider
        └── MockData.fuelPrice / MockData.supermarketDistances
        Output: List<SupermarketTotal> ordenada por totalCost asc
```

### Recommended Project Structure (arquivos novos/modificados nesta fase)

```
lib/
├── core/
│   ├── data/
│   │   └── mock_data.dart                    # MODIFY: + prices, fuelPrice, vehicle, supermarketDistances
│   └── providers/
│       ├── products_provider.dart            # NEW: Provider<List<Product>>
│       ├── prices_provider.dart              # NEW: Provider<Map<String,Map<String,double>>>
│       ├── vehicle_provider.dart             # NEW: Provider<Vehicle>
│       ├── search_query_notifier.dart        # NEW: NotifierProvider<SearchQueryNotifier, String>
│       ├── view_mode_notifier.dart           # NEW: NotifierProvider<ViewModeNotifier, ViewMode>
│       ├── fuel_toggle_notifier.dart         # NEW: NotifierProvider<FuelToggleNotifier, bool>
│       ├── filtered_products_provider.dart   # NEW: Provider<List<Product>> (derivado)
│       └── comparison_results_provider.dart  # NEW: Provider<List<SupermarketTotal>> (derivado)
├── features/
│   ├── home/
│   │   └── presentation/
│   │       ├── home_screen.dart              # MODIFY: redesign completo
│   │       ├── product_card_grid.dart        # NEW
│   │       ├── product_card_list.dart        # NEW
│   │       ├── product_detail_screen.dart    # NEW
│   │       └── nutritional_info_bottom_sheet.dart  # NEW
│   ├── profile/
│   │   └── domain/
│   │       ├── product.dart                  # MODIFY: + ean, subcategory, department, nutritionalInfo
│   │       ├── nutritional_info.dart         # NEW
│   │       └── vehicle.dart                  # READ-ONLY: já existe com campos corretos
│   ├── shopping_list/
│   │   └── presentation/
│   │       └── shopping_list_screen.dart     # MODIFY: implementação completa
│   └── price_comparison/
│       └── presentation/
│           └── price_comparison_screen.dart  # MODIFY: implementação completa
└── routing/
    ├── app_routes.dart                       # MODIFY: + productDetail, comparison subrotas
    └── app_router.dart                       # MODIFY: subrotas + tab rename Scanner
```

### Pattern 1: Provider Read-Only (MockData wrapper)

Usado para `productsProvider`, `pricesProvider`, `vehicleProvider`. Padrão mais simples — sem estado mutável.

```dart
// lib/core/providers/products_provider.dart
// Source: Riverpod official docs — Provider<T>
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/mock_data.dart';
import '../../features/profile/domain/product.dart';

final productsProvider = Provider<List<Product>>((ref) {
  return MockData.products;
});
```

### Pattern 2: Provider Derivado (filteredProductsProvider)

`Provider<T>` pode chamar `ref.watch` em outros providers — isso cria reatividade sem AsyncNotifier.

```dart
// lib/core/providers/filtered_products_provider.dart
// Source: [ASSUMED] — Riverpod docs (derivado síncrono)
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
           p.brand.toLowerCase().contains(query);
  }).toList();
});
```

### Pattern 3: NotifierProvider para estado simples (ViewMode, SearchQuery)

```dart
// lib/core/providers/view_mode_notifier.dart
// Source: [ASSUMED] — Riverpod Notifier pattern
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ViewMode { grid, list }

class ViewModeNotifier extends Notifier<ViewMode> {
  @override
  ViewMode build() => ViewMode.grid;

  void toggleToGrid() => state = ViewMode.grid;
  void toggleToList() => state = ViewMode.list;
}

final viewModeProvider = NotifierProvider<ViewModeNotifier, ViewMode>(ViewModeNotifier.new);
```

```dart
// lib/core/providers/search_query_notifier.dart
// Source: [ASSUMED] — Riverpod Notifier pattern
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void update(String query) => state = query;
  void clear() => state = '';
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);
```

### Pattern 4: FuelToggleNotifier com SharedPreferences (mesmo padrão de FavoritesNotifier)

```dart
// lib/core/providers/fuel_toggle_notifier.dart
// Source: [ASSUMED] — baseado em favorites_notifier.dart existente (verificado no codebase)
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../persistence/shared_preferences_provider.dart';

class FuelToggleNotifier extends Notifier<bool> {
  static const _key = 'lista_smart_fuel_toggle';

  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool(_key) ?? true;  // default: true (toggle ativo)
  }

  void toggle() {
    state = !state;
    ref.read(sharedPreferencesProvider).setBool(_key, state);
  }
}

final fuelToggleProvider = NotifierProvider<FuelToggleNotifier, bool>(FuelToggleNotifier.new);
```

### Pattern 5: comparisonResultsProvider (derivado complexo)

```dart
// lib/core/providers/comparison_results_provider.dart
// Source: [ASSUMED] — lógica baseada em D-03 do CONTEXT.md
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

### Pattern 6: Subrota dentro de StatefulShellBranch (go_router 14.x)

O go_router 14.x suporta subrotas (`routes:`) dentro de `GoRoute` que está dentro de `StatefulShellBranch`. A navegação preserva o branch ativo.

```dart
// lib/routing/app_router.dart — modificação (trecho relevante)
// Source: [ASSUMED] — go_router 14.x docs (subrotas em StatefulShellBranch)
StatefulShellBranch(
  navigatorKey: _tab0Key,
  routes: [
    GoRoute(
      path: AppRoutes.home,              // '/home'
      builder: (_, __) => const HomeScreen(),
      routes: [
        GoRoute(
          path: 'product/:productId',    // relativo → '/home/product/:productId'
          builder: (context, state) {
            final productId = state.pathParameters['productId']!;
            return ProductDetailScreen(productId: productId);
          },
        ),
      ],
    ),
  ],
),
StatefulShellBranch(
  navigatorKey: _tab1Key,
  routes: [
    GoRoute(
      path: AppRoutes.shoppingList,      // '/shopping-list'
      builder: (_, __) => const ShoppingListScreen(),
      routes: [
        GoRoute(
          path: 'comparison',            // relativo → '/shopping-list/comparison'
          builder: (_, __) => const PriceComparisonScreen(),
        ),
      ],
    ),
  ],
),
```

**CRITICAL:** O `path` da subrota é RELATIVO (sem `/` inicial). go_router concatena automaticamente. [ASSUMED — padrão documentado em go_router, verificar durante execução]

### Pattern 7: SliverPersistentHeader com delegate customizado

`SliverPersistentHeader` requer um `SliverPersistentHeaderDelegate`. Implementação mínima funcional:

```dart
// Source: [ASSUMED] — Flutter SDK docs
class _StickySearchBarDelegate extends SliverPersistentHeaderDelegate {
  const _StickySearchBarDelegate({required this.child, required this.height});
  final Widget child;
  final double height;

  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_StickySearchBarDelegate oldDelegate) =>
      oldDelegate.child != child || oldDelegate.height != height;
}

// Uso no CustomScrollView:
SliverPersistentHeader(
  pinned: true,
  delegate: _StickySearchBarDelegate(
    height: 64.0,  // spacingS(8) top + 48 TextField + spacingS(8) bottom
    child: ColoredBox(
      color: AppColors.background,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.spacingM,
          vertical: AppSizes.spacingS,
        ),
        child: TextField(/* ... */),
      ),
    ),
  ),
),
```

**IMPORTANTE:** `ColoredBox` ou `Container(color:)` no child é necessário para cobrir o conteúdo que passa por baixo quando `pinned: true`. Sem fundo, o conteúdo do scroll aparece atrás da barra de busca.

### Pattern 8: Image.network com loadingBuilder e errorBuilder

```dart
// Source: [ASSUMED] — Flutter SDK Image.network (standard Flutter pattern)
SizedBox(
  height: 200,
  child: Image.network(
    product.imageUrl,
    fit: BoxFit.contain,
    loadingBuilder: (context, child, loadingProgress) {
      if (loadingProgress == null) return child;
      return const ColoredBox(color: AppColors.surface);
    },
    errorBuilder: (context, error, stackTrace) {
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.packageOpen, size: 64, color: AppColors.textSecondary),
          SizedBox(height: AppSizes.spacingXS),
          Text('Imagem indisponível',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      );
    },
  ),
),
```

**Nota:** Para imageUrls vazias (`''`) como as atuais no MockData, `Image.network('')` dispara `errorBuilder` imediatamente. O fallback funciona sem URL válida.

### Pattern 9: FAB navegar para tab por índice

```dart
// Source: [ASSUMED] — go_router StatefulShellRoute docs
// No HomeScreen, via ConsumerWidget:
floatingActionButton: FloatingActionButton(
  backgroundColor: AppColors.primary,
  foregroundColor: AppColors.background,
  tooltip: 'Escanear nota fiscal',
  onPressed: () {
    // StatefulNavigationShell não é acessível diretamente de telas filhas.
    // O padrão é passar o navigationShell para baixo OU usar go_router context extension.
    // Alternativa mais simples: context.go(AppRoutes.scanner) onde scanner é '/scanner' (tab2)
    context.go(AppRoutes.scanner);
  },
  child: const Icon(LucideIcons.scanLine),
),
```

**ATENÇÃO:** Navegar para outro tab via FAB tem uma pegadinha — ver seção de Pitfalls.

### Pattern 10: CartNotifier — métodos a adicionar

`CartNotifier` existente tem `addItem`, `removeItem`, `clear`. Precisam ser adicionados:

```dart
// Incrementar quantidade
void incrementQuantity(String productId) {
  final idx = state.indexWhere((e) => e.productId == productId);
  if (idx < 0) return;
  state = [
    ...state.sublist(0, idx),
    state[idx].copyWith(quantity: state[idx].quantity + 1),
    ...state.sublist(idx + 1),
  ];
  _persist();
}

// Decrementar quantidade — remove se chegar a 0
void decrementQuantity(String productId) {
  final idx = state.indexWhere((e) => e.productId == productId);
  if (idx < 0) return;
  if (state[idx].quantity <= 1) {
    removeItem(productId);
    return;
  }
  state = [
    ...state.sublist(0, idx),
    state[idx].copyWith(quantity: state[idx].quantity - 1),
    ...state.sublist(idx + 1),
  ];
  _persist();
}
```

### Pattern 11: DraggableScrollableSheet como ModalBottomSheet

```dart
// Source: [ASSUMED] — Flutter Material docs
showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  builder: (_) => DraggableScrollableSheet(
    initialChildSize: 0.5,
    maxChildSize: 0.85,
    minChildSize: 0.3,
    builder: (context, scrollController) => Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusXL),
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: ListView(
        controller: scrollController,
        // conteúdo da tabela nutricional...
      ),
    ),
  ),
);
```

**CRÍTICO:** O `scrollController` do `DraggableScrollableSheet.builder` DEVE ser passado para o `ListView` interno. Sem isso, o scroll dentro do sheet não funciona e o usuário não consegue expandir o sheet.

### Pattern 12: BRL Currency Formatting

```dart
// Source: [ASSUMED] — intl package, já instalado (0.19.0)
import 'package:intl/intl.dart';

// Helper function (pode ser em um arquivo de utils ou inline)
String formatBRL(double value) {
  return NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 2,
  ).format(value);
}
// Output: "R$ 4,99", "R$ 38,90"
// Intl.defaultLocale = 'pt_BR' já está configurado em main.dart
```

### Pattern 13: Iniciais do usuário no badge

```dart
// Source: [ASSUMED] — lógica de string Dart
String _getInitials(String fullName) {
  final parts = fullName.trim().split(' ');
  if (parts.length == 1) return parts[0][0].toUpperCase();
  return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
}
// 'José Augusto' → 'JA'
// 'Maria' → 'M'
```

### Anti-Patterns a Evitar

- **Anti-pattern: `ref.watch` em event handler ou `initState`** — sempre `ref.read` em `onPressed`, `onChanged`, etc. `ref.watch` somente em `build()`.
- **Anti-pattern: `StateProvider<String>` para searchQuery** — CONTEXT.md D-12 define `NotifierProvider<SearchQueryNotifier, String>`. Usar `Notifier`, não `StateProvider` (depreciado).
- **Anti-pattern: `withOpacity()`** — usar `withValues(alpha:)`. Ex: `AppColors.primary.withValues(alpha: 0.1)`.
- **Anti-pattern: `StateNotifierProvider`** — proibido no projeto. Usar `NotifierProvider`.
- **Anti-pattern: Provider dentro de build()** — todos os providers declarados como top-level `final`.
- **Anti-pattern: hardcoded colors/sizes** — usar `AppColors.*` e `AppSizes.*` exclusivamente.
- **Anti-pattern: `context.read<T>()`** — usar `ref.read(provider)` via ConsumerWidget/ConsumerStatefulWidget.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Formatação de moeda BRL | Formatador manual de string | `NumberFormat.currency(locale: 'pt_BR')` do intl | Lida com separador de milhar, centavos, locale edge cases |
| Persistência do fuelToggle | Campo em memória | `SharedPreferences.setBool/getBool` | Mesmo padrão de FavoritesNotifier — consistente e testável |
| Scroll scroll do bottom sheet | ScrollController manual | `DraggableScrollableSheet` builder's `scrollController` | Coordina scroll interno com gesto de drag do sheet |
| Filtro de busca assíncrono | Stream/debounce manual | `Provider<List<Product>>` derivado síncrono | Filtragem de 12 produtos mock é O(n) — síncrono é ideal |
| Navegação entre tabs | Lógica manual de índice | `context.go(AppRoutes.scanner)` | go_router gerencia o estado do StatefulShellRoute |
| Menor preço de supermercado | Loop manual no widget | Derivação no `Provider` ou cálculo inline na lista mapeada | Separação de lógica de negócio da UI |

**Key insight:** Toda a lógica de dados (filtro, comparação, fuel cost) deve viver em providers, não em widgets. Widgets só lêem o resultado final via `ref.watch`.

---

## Common Pitfalls

### Pitfall 1: Subrota com `/` inicial quebra go_router

**O que vai errado:** Declarar subrota como `path: '/product/:productId'` (com `/`) em vez de `path: 'product/:productId'` (sem `/`).

**Por que acontece:** Em go_router 14.x, subrotas dentro de `GoRoute.routes` usam path **relativo**. O `/` inicial é reservado para rotas top-level. Com `/`, go_router trata como rota raiz independente e não a enxerga como filha de `/home`.

**Como evitar:** Sempre usar path relativo em subrotas: `'product/:productId'`. O go_router concatena automaticamente: `/home` + `product/:productId` = `/home/product/:productId`.

**Sinais de alerta:** Erro de assert do go_router ao iniciar o app; rota não encontrada ao chamar `context.push('/home/product/p01')`.

### Pitfall 2: SliverPersistentHeader sem fundo cobre conteúdo transparente

**O que vai errado:** O campo de busca fica "pinned" mas o conteúdo do scroll aparece atrás dele porque o delegate não tem cor de fundo.

**Por que acontece:** `SliverPersistentHeader(pinned: true)` não define automaticamente um fundo opaco — o Widget filho precisa preencher o fundo.

**Como evitar:** Envolver o filho em `ColoredBox(color: AppColors.background, child: ...)` ou `Container(color: AppColors.background, child: ...)`.

**Sinais de alerta:** Texto dos cards de produto aparece "sangrando" atrás do campo de busca durante scroll.

### Pitfall 3: Vehicle.fuelEfficiencyKmPerLiter vs fuelEfficiency

**O que vai errado:** CONTEXT.md D-05 menciona `fuelEfficiency: 12.0` como nome do campo, mas o model existente em `lib/features/profile/domain/vehicle.dart` usa `fuelEfficiencyKmPerLiter`. Usar o nome errado causa `NoSuchMethodError` em runtime.

**Por que acontece:** Inconsistência de nomenclatura entre o CONTEXT.md (escrito durante a discussão) e o model gerado anteriormente.

**Como evitar:** Usar `vehicle.fuelEfficiencyKmPerLiter` (nome real do campo no model). NÃO renomear o model — isso é out-of-scope e quebraria retrocompatibilidade.

**Sinais de alerta:** Erro de compilação se o campo for acessado com nome errado em Dart.

### Pitfall 4: MockData.products usa `Product` sem os campos novos

**O que vai errado:** Após adicionar `ean`, `subcategory`, `department`, `nutritionalInfo` ao model `Product`, os 12 itens estáticos em `MockData.products` não passam mais a compilar — faltam os novos campos required.

**Por que acontece:** `const Product(...)` em MockData precisa incluir todos os campos `required`. Se os novos campos forem `required`, os 12 constructors em MockData.products precisam ser atualizados. Se os campos forem nullable ou com default, não quebra — mas o planner deve escolher essa estratégia.

**Como evitar:** Estratégia recomendada: adicionar campos com defaults ou como nullable onde semanticamente faz sentido. `nutritionalInfo` pode ter valor default mock. `ean`, `subcategory`, `department` podem ter defaults (`''`). Isso permite adicionar os campos sem reescrever todos os 12 constructors.

**Sinais de alerta:** `Error: Too few positional arguments` ou `Missing required argument` nos constructors do MockData.

### Pitfall 5: FAB navegar para outro tab com `context.go` vs `context.push`

**O que vai errado:** Usar `context.push(AppRoutes.scanner)` para navegar para o tab do Scanner. `context.push` empilha a rota sobre o branch atual (tab0), não muda o tab ativo. O resultado visual parece correto mas o bottom nav não seleciona o tab correto.

**Por que acontece:** `context.push` faz push no Navigator root; `context.go` faz replace no location e deixa o StatefulShellRoute selecionar o branch correto.

**Como evitar:** Usar `context.go(AppRoutes.scanner)` (não `push`) para navegação entre tabs. Para subrotas dentro de tabs, usar `context.push`.

**Sinais de alerta:** Bottom nav não destaca o tab Scanner após toque no FAB.

### Pitfall 6: Image.network com URL vazia — não usar `if (url.isNotEmpty)`

**O que vai errado:** Proteger `Image.network` com `if (product.imageUrl.isNotEmpty)` e exibir o fallback manualmente. Isso cria dois code paths e é mais frágil.

**Por que acontece:** Tentativa de evitar `Image.network('')`, que tecnicamente funciona mas gera um erro de rede.

**Como evitar:** Sempre usar `Image.network` com `errorBuilder` declarado. Com URL vazia, o `errorBuilder` dispara automaticamente — é o comportamento correto e o único code path necessário.

### Pitfall 7: `ref.watch` em ConsumerWidget para shoppingList — reconstrução excessiva

**O que vai errado:** Usar `ref.watch(cartProvider)` no `build()` da `ShoppingListScreen` é correto, mas usar `ref.watch(comparisonResultsProvider)` também na ShoppingListScreen quando ela não precisa do resultado da comparação gera trabalho desnecessário.

**Como evitar:** `ShoppingListScreen` watch apenas `cartProvider` e `fuelToggleProvider`. O `comparisonResultsProvider` é watchado apenas em `PriceComparisonScreen`.

### Pitfall 8: AppRoutes precisa de nova rota para `/shopping-list` (não `/lista`)

**O que vai errado:** CONTEXT.md e UI-SPEC mencionam a rota como `/lista`. O `app_routes.dart` existente define `shoppingList = '/shopping-list'`. Se o executor usar `/lista` hardcoded, as rotas não batem.

**Por que acontece:** Inconsistência de nomenclatura entre a discussão e o código existente.

**Como evitar:** Usar `AppRoutes.shoppingList` (`'/shopping-list'`) como valor base. A subrota de comparação fica `'/shopping-list/comparison'`. Adicionar `AppRoutes.productDetail = '/home/product/:productId'` e `AppRoutes.comparison = '/shopping-list/comparison'` no `app_routes.dart`. NÃO mudar o valor de `shoppingList` — isso quebraria o router.

---

## Runtime State Inventory

> Esta fase não é rename/refactor/migration. Omitido.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter SDK | Toda a fase | ✓ | 3.32.7 | — |
| Dart SDK | Toda a fase | ✓ | 3.8.1 | — |
| flutter_riverpod | Providers | ✓ | 2.6.1 | — |
| go_router | Routing | ✓ | 14.8.1 | — |
| shared_preferences | fuelToggleProvider | ✓ | 2.5.3 | — |
| lucide_icons | Ícones | ✓ | 0.257.0 | — |
| intl | BRL formatting | ✓ | 0.19.0 | — |
| Image.network (Flutter SDK) | Imagens de produtos | ✓ | built-in | errorBuilder fallback com LucideIcons.packageOpen |

**Missing dependencies with no fallback:** nenhuma.

**Nota:** Image.network requer acesso à internet. Para dados acadêmicos mock, o comportamento com URLs vazias (`''`) dispara `errorBuilder` imediatamente — o app funciona offline sem problema.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | flutter_test (built-in, SDK 3.32.7) |
| Config file | `pubspec.yaml` (flutter_test: sdk: flutter) |
| Quick run command | `flutter test test/widget_test.dart` |
| Full suite command | `flutter test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| HOME-02 | filteredProductsProvider filtra por query | unit | `flutter test test/providers/filtered_products_provider_test.dart` | ❌ Wave 0 |
| SHOP-02 | CartNotifier.incrementQuantity / decrementQuantity | unit | `flutter test test/providers/cart_notifier_test.dart` | ❌ Wave 0 |
| COMP-01/02/03 | comparisonResultsProvider ordena por totalCost, calcula fuel | unit | `flutter test test/providers/comparison_results_provider_test.dart` | ❌ Wave 0 |
| HOME-04 | favoritesProvider toggle | unit | `flutter test test/providers/favorites_notifier_test.dart` | ❌ Wave 0 |
| SHOP-04/D-07 | fuelToggleProvider persiste em SharedPrefs | unit | `flutter test test/providers/fuel_toggle_notifier_test.dart` | ❌ Wave 0 |
| HOME-01/03/07 | HomeScreen renderiza grid/list, navega para detail | widget | `flutter test test/features/home/home_screen_test.dart` | ❌ Wave 0 |
| SHOP-01..05 | ShoppingListScreen com cart cheio/vazio | widget | `flutter test test/features/shopping_list/shopping_list_screen_test.dart` | ❌ Wave 0 |

### Sampling Rate

- **Por task commit:** `flutter test` (suite completa — projeto pequeno, < 5s)
- **Por wave merge:** `flutter test`
- **Phase gate:** Suite verde antes de `/gsd-verify-work`

### Wave 0 Gaps

- [ ] `test/providers/filtered_products_provider_test.dart` — cobre HOME-02
- [ ] `test/providers/cart_notifier_test.dart` — cobre SHOP-02 (métodos increment/decrement)
- [ ] `test/providers/comparison_results_provider_test.dart` — cobre COMP-01/02/03
- [ ] `test/providers/fuel_toggle_notifier_test.dart` — cobre SHOP-04/D-07
- [ ] `test/features/home/home_screen_test.dart` — cobre HOME-01/03/07
- [ ] `test/features/shopping_list/shopping_list_screen_test.dart` — cobre SHOP-01..05

---

## Security Domain

> Esta fase é um app Flutter acadêmico totalmente local. Não há autenticação real, rede backend, ou dados sensíveis de usuário. ASVS aplica-se de forma limitada.

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | não — login é mock | n/a |
| V3 Session Management | não — session é SharedPrefs local | n/a |
| V4 Access Control | não — app single-user | n/a |
| V5 Input Validation | sim — campo de busca (TextField) | Nenhuma injeção possível — dado vai apenas para filtro local |
| V6 Cryptography | não — sem dados sensíveis | n/a |

**Threat pattern relevante:** `Image.network` abre conexão de rede para URLs de imagem mock. URLs devem ser de domínios confiáveis (Open Food Facts, Wikipedia Commons). Com URLs vazias no mock atual, nenhuma conexão ocorre.

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `StateProvider<String>` para busca simples | `NotifierProvider<Notifier, String>` | Riverpod 2.0 (StateProvider depreciado) | `StateProvider` ainda compila mas é considerado legacy — evitar |
| `StateNotifierProvider` para listas | `NotifierProvider<Notifier, List<T>>` | Riverpod 2.0 | `StateNotifier` removido de exemplos oficiais — PROIBIDO neste projeto |
| `Navigator.push` para rotas | `context.push` / `context.go` (go_router) | go_router 14.x | `context.go` para tabs, `context.push` para sub-rotas |
| `withOpacity(double)` | `withValues(alpha: double)` | Flutter 3.x (deprecation aviso) | `withOpacity` ainda funciona mas deprecado — este projeto usa `withValues` |

---

## Codebase Audit (o que já existe vs o que falta)

### Já existe — não recriar

| Artefato | Localização | Estado |
|----------|-------------|--------|
| `CartNotifier` + `cartProvider` | `lib/core/providers/cart_notifier.dart` | Funcional. Adicionar `incrementQuantity`, `decrementQuantity` |
| `FavoritesNotifier` + `favoritesProvider` | `lib/core/providers/favorites_notifier.dart` | Funcional. Sem mudanças necessárias |
| `Vehicle` model | `lib/features/profile/domain/vehicle.dart` | Funcional. Campo: `fuelEfficiencyKmPerLiter` (NÃO `fuelEfficiency`) |
| `CartItem` model | `lib/features/shopping_list/domain/cart_item.dart` | Funcional. Sem mudanças necessárias |
| `MockData.supermarketDistances` | `lib/core/data/mock_data.dart` | Já tem os 4 supermercados com distâncias |
| `AppColors.*`, `AppSizes.*` | `lib/core/constants/` | Completo. Sem adições necessárias |
| `StatefulShellRoute.indexedStack` (5 tabs) | `lib/routing/app_router.dart` | Funcional. Modificar para subrotas + tab rename |
| `sharedPreferencesProvider` | `lib/core/persistence/shared_preferences_provider.dart` | Funcional. Injetado no main.dart |
| `intl` com `Intl.defaultLocale = 'pt_BR'` | `lib/main.dart` | Configurado |

### Não existe — criar do zero

| Artefato | Localização destino | Dependências |
|----------|---------------------|--------------|
| `NutritionalInfo` model | `lib/features/profile/domain/nutritional_info.dart` | Nenhuma |
| `Product` (extendido) | `lib/features/profile/domain/product.dart` | `NutritionalInfo` |
| `MockData.prices` | `lib/core/data/mock_data.dart` | IDs dos 12 products existentes |
| `MockData.fuelPrice` | `lib/core/data/mock_data.dart` | Nenhuma |
| `MockData.vehicle` | `lib/core/data/mock_data.dart` | `Vehicle` model |
| `productsProvider` | `lib/core/providers/products_provider.dart` | `Product`, `MockData` |
| `pricesProvider` | `lib/core/providers/prices_provider.dart` | `MockData` |
| `vehicleProvider` | `lib/core/providers/vehicle_provider.dart` | `Vehicle`, `MockData` |
| `searchQueryProvider` | `lib/core/providers/search_query_notifier.dart` | Nenhuma |
| `viewModeProvider` | `lib/core/providers/view_mode_notifier.dart` | Nenhuma |
| `fuelToggleProvider` | `lib/core/providers/fuel_toggle_notifier.dart` | `sharedPreferencesProvider` |
| `filteredProductsProvider` | `lib/core/providers/filtered_products_provider.dart` | `productsProvider`, `searchQueryProvider` |
| `SupermarketTotal` + `comparisonResultsProvider` | `lib/core/providers/comparison_results_provider.dart` | `cartProvider`, `pricesProvider`, `vehicleProvider`, `fuelToggleProvider`, `MockData` |
| `HomeScreen` (redesign) | `lib/features/home/presentation/home_screen.dart` | Todos os providers acima |
| `ProductCardGrid` | `lib/features/home/presentation/product_card_grid.dart` | `Product`, `favoritesProvider` |
| `ProductCardList` | `lib/features/home/presentation/product_card_list.dart` | `Product`, `favoritesProvider` |
| `ProductDetailScreen` | `lib/features/home/presentation/product_detail_screen.dart` | `productsProvider`, `pricesProvider`, `cartProvider` |
| `NutritionalInfoBottomSheet` | `lib/features/home/presentation/nutritional_info_bottom_sheet.dart` | `NutritionalInfo` |
| `ShoppingListScreen` (completo) | `lib/features/shopping_list/presentation/shopping_list_screen.dart` | `cartProvider`, `fuelToggleProvider` |
| `PriceComparisonScreen` (completo) | `lib/features/price_comparison/presentation/price_comparison_screen.dart` | `comparisonResultsProvider`, `fuelToggleProvider` |

### Mudanças críticas no Router

| Mudança | Tipo | Risco |
|---------|------|-------|
| Tab 2 label: "Comparar" → "Scanner" | `ScaffoldWithBottomNav` em `app_router.dart` | Baixo — visual only |
| Tab 2 ícone: `LucideIcons.barChart2` → `LucideIcons.scanLine` | `ScaffoldWithBottomNav` | Baixo |
| Adicionar subrota `/home/product/:productId` | `StatefulShellBranch` tab0 | Médio — path relativo, não absoluto |
| Adicionar subrota `/shopping-list/comparison` | `StatefulShellBranch` tab1 | Médio — path relativo |
| `AppRoutes`: adicionar `productDetail` e `comparisonResult` | `app_routes.dart` | Baixo |
| `PriceComparisonScreen` move de tab raiz → subrota de tab1 | Remover do tab2, adicionar em tab1 | ALTO — tab2 agora é Scanner placeholder |

**Decisão crítica D-04:** O `PriceComparisonScreen` que atualmente vive no tab2 (`/comparison`) deve ser:
1. Removido do tab2 como rota raiz
2. Colocado como subrota de tab1: `/shopping-list/comparison`
3. Tab2 vira Scanner placeholder (tela simples de placeholder, semelhante ao atual `StoreScreen` / `ProfileScreen` stubs)

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Subrota com path relativo (sem `/` inicial) é o padrão go_router 14.x para `StatefulShellBranch` | Architecture Patterns Pattern 6 | Rotas não funcionam; erro de assert ou rota não encontrada |
| A2 | `filteredProductsProvider` como `Provider<List<Product>>` (não `FutureProvider`) é correto pois a filtragem é síncrona | Architecture Patterns Pattern 2 | Sem risco — 12 produtos mock, sempre síncrono |
| A3 | `searchQueryProvider` via `NotifierProvider<SearchQueryNotifier, String>` (não `StateProvider`) conforme D-12 | Pattern 3 | `StateProvider` também funcionaria mas viola a convenção do projeto |
| A4 | `context.go(AppRoutes.scanner)` é o mecanismo correto para FAB navegar para tab Scanner | Pattern 9 / Pitfall 5 | Tab não muda; bottom nav não atualiza o índice selecionado |
| A5 | `DraggableScrollableSheet.builder` scrollController DEVE ser passado para o `ListView` filho | Pattern 11 | Scroll interno do bottom sheet não funciona |
| A6 | Fields novos no `Product` model devem ter defaults para não quebrar os 12 constructors do MockData | Pitfall 4 | Erro de compilação nos 12 constructors do MockData.products |
| A7 | `MockData.fuelPrice` deve ser `static const double` (não `static const Map`) | comparisonResultsProvider | Leve — apenas questão de tipo de declaração |

---

## Open Questions

1. **`PriceComparisonScreen` ainda existe como tab2?**
   - O que sabemos: D-04 diz que tab3 passa a ser Scanner (era Comparar). O router atual tem 5 tabs: Home, Lista, Comparar, Loja, Perfil.
   - O que precisa ser decidido: Comparar (tab2) vira Scanner placeholder. A rota `/comparison` existente no tab2 precisa ser substituída. O `PriceComparisonScreen` vai para subrota `/shopping-list/comparison`.
   - Recomendação: Manter `PriceComparisonScreen` como classe, mover para subrota. Criar `ScannerScreen` placeholder simples (ou reutilizar o `price_registration_screen.dart` existente como placeholder).

2. **`imageUrl` nos produtos mock — usar URLs reais?**
   - O que sabemos: D-11 permite URLs do Open Food Facts para fins acadêmicos. MockData.products atual tem `imageUrl: ''` em todos os 12 produtos.
   - O que está claro: O `errorBuilder` funciona com URL vazia — o app compila e exibe o fallback.
   - Recomendação: Popuar com URLs reais do Open Food Facts ou placeholder de imagens públicas para demonstração acadêmica. Se não houver tempo, manter `''` — o errorBuilder garante degradação graciosa.

3. **`CartItem.unitPrice` — usar `averagePrice` ou preço específico de supermercado?**
   - O que sabemos: `CartItem` tem `unitPrice`. Quando o usuário adiciona um produto da `HomeScreen` (que exibe `averagePrice`), qual preço usar?
   - Recomendação: Usar `product.averagePrice` como `unitPrice` no `CartItem`. O `comparisonResultsProvider` usa `MockData.prices[productId][supermarket]` para calcular o custo real por supermercado — o `unitPrice` no `CartItem` serve apenas para o "Total estimado" na `ShoppingListScreen` (valor aproximado, não de comparação).

---

## Sources

### Primary (HIGH confidence)

- Codebase existente: `lib/routing/app_router.dart` — StatefulShellRoute com 5 branches verificado
- Codebase existente: `lib/core/providers/favorites_notifier.dart` — padrão SharedPrefs + Notifier verificado
- Codebase existente: `lib/core/providers/cart_notifier.dart` — padrão Notifier + persistência verificado
- Codebase existente: `lib/features/profile/domain/vehicle.dart` — campo `fuelEfficiencyKmPerLiter` verificado
- Codebase existente: `lib/features/profile/domain/product.dart` — campos atuais verificados
- Codebase existente: `lib/core/data/mock_data.dart` — 12 produtos + supermarketDistances verificados
- `flutter pub deps` output — versões resolvidas verificadas (riverpod 2.6.1, go_router 14.8.1, intl 0.19.0)
- `.planning/phases/03-core-shopping-loop/03-CONTEXT.md` — 14 decisões locked
- `.planning/phases/03-core-shopping-loop/03-UI-SPEC.md` — contrato visual completo

### Secondary (MEDIUM confidence)

- CLAUDE.md — constraints de versão e padrões do projeto
- `.planning/REQUIREMENTS.md` — requisitos HOME-01..07, SHOP-01..05, COMP-01..03

### Tertiary (LOW confidence — assumed from training knowledge)

- go_router 14.x subrota com path relativo dentro de StatefulShellBranch [A1]
- DraggableScrollableSheet scrollController passagem para ListView [A5]
- `context.go` vs `context.push` para navegação entre tabs [A4]

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — versões verificadas via `flutter pub deps`
- Architecture (providers): HIGH — baseado em padrões existentes verificados no codebase
- Architecture (routing): MEDIUM — subrotas em StatefulShellBranch [ASSUMED] mas é padrão go_router documentado
- Pitfalls: HIGH — baseados em análise do codebase real + padrões Flutter conhecidos
- Codebase audit: HIGH — leitura direta de todos os arquivos relevantes

**Research date:** 2026-06-01
**Valid until:** 2026-07-01 (30 dias — stack estável, go_router e riverpod com versões pinadas)
