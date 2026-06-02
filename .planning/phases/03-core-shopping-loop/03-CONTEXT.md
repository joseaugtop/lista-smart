---
phase: 3
name: core-shopping-loop
status: discussed
discussed_at: "2026-06-01"
---

# Phase 3 — Core Shopping Loop: Implementation Context

## Phase Goal

Implementar o loop central de compras: Home com produtos navegáveis, tela de detalhe de produto, lista de compras gerenciável, comparação de preços entre supermercados com custo de combustível opcional.

---

## Locked Decisions

### D-01 — Estrutura de Preços: Map Aninhado

**Decision:** `MockData.prices` usa `Map<String, Map<String, double>>` (productId → supermarket → price).

```dart
static const Map<String, Map<String, double>> prices = {
  'product_001': {'Bistek': 4.99, 'Giassi': 5.29, 'Angeloni': 5.49, 'Atacadão': 4.79},
  // ...
};
```

**Rationale:** Lookup O(1) por produto e supermercado. Simples de inicializar com dados mock. Compatível com Provider<T> read-only.

---

### D-02 — Supermercados na Comparação: Todos os 4

**Decision:** Comparação inclui Bistek, Giassi, Angeloni e Atacadão — os mesmos 4 de `MockData.supermarketDistances`.

**Rationale:** Consistência de dados. Atacadão já tem distância definida em Phase 2 mock data.

---

### D-03 — Escopo da Comparação: Carrinho Inteiro

**Decision:** Tela de Comparação calcula o **custo total do carrinho inteiro** por supermercado, não produto individual.

**Formula:**
```
totalCost(supermarket) = Σ(price[productId][supermarket] * quantity) + fuelCost(distance[supermarket])
fuelCost(distance) = (distance * 2 / fuelEfficiency) * fuelPrice  // ida e volta
```

**Rationale:** A proposta de valor do app é "qual supermercado é mais barato para minha lista". Produto individual não entrega isso.

---

### D-04 — Navigation Redesign: Bottom Nav Tab 3

**Decision:** Tab 3 renomeado de "Comparar" → "Scanner" (placeholder para Phase 4/5). Acesso à `PriceComparisonScreen` via **botão fixo no rodapé de `ShoppingListScreen`**, visível apenas quando `cart.isNotEmpty`.

**Bottom nav tabs:**
1. Home
2. Lista
3. Scanner (placeholder — FAB navega aqui também)
4. Coins

**Rationale:** Comparação faz sentido contextualmente após montar a lista, não como destino primário de navegação.

---

### D-05 — Veículo Padrão: Fiat Uno

**Decision:** `MockData.vehicle` = `Vehicle(model: 'Fiat Uno', fuelEfficiency: 12.0)` (km/L). Modelo `Vehicle` criado nesta fase.

```dart
@immutable
class Vehicle {
  final String model;
  final double fuelEfficiency; // km/L
  const Vehicle({required this.model, required this.fuelEfficiency});
}
```

---

### D-06 — Preço do Combustível: Fixo em MockData (Fase 3)

**Decision:** `MockData.fuelPrice = 6.50` (R$/L). Constante em Phase 3. Editável pelo usuário na Tela de Perfil em Phase 5.

**Implementação Phase 3:** Não criar UI de edição. Ler diretamente de `MockData.fuelPrice`.

---

### D-07 — Toggle Combustível: SharedPreferences

**Decision:** Switch "Considerar Custo de Deslocamento" persiste via SharedPreferences. Novo provider `fuelToggleProvider`.

```dart
// Provider dedicado — bool simples
final fuelToggleProvider = NotifierProvider<FuelToggleNotifier, bool>(FuelToggleNotifier.new);
```

**Key SharedPreferences:** `'lista_smart_fuel_toggle'` (default: `true`)

---

### D-08 — Tap no Card de Produto → ProductDetailScreen

**Decision:** Tap no card da Home navega para `ProductDetailScreen` (nova tela). Não para comparação direta.

**Rota:** `/home/product/:productId` — subrota de `/home` para manter back navigation.

**ProductDetailScreen contém:**
- Imagem do produto (`Image.network` com placeholder fallback)
- Nome, marca, departamento, categoria, subcategoria, EAN (mock)
- Preço por supermercado (tabela ou lista — todos os 4)
- Botão "Adicionar ao Carrinho" (incrementa quantidade se já existe)
- Botão "Ver Tabela Nutricional" (abre bottom sheet com dados mock)

---

### D-09 — Preços por Supermercado no ProductDetailScreen

**Decision:** `ProductDetailScreen` exibe preços de todos os 4 supermercados para aquele produto específico, usando `MockData.prices[productId]`. Destaca o menor preço.

---

### D-10 — Extensões do Model Product

**Decision:** `Product` ganha os campos:
```dart
final String ean;           // mock barcode string ex: '7891000315507'
final String subcategory;   // ex: 'Iogurte'
final String department;    // ex: 'Laticínios'
final NutritionalInfo nutritionalInfo; // ver abaixo
```

**NutritionalInfo (novo model):**
```dart
@immutable
class NutritionalInfo {
  final double calories;      // kcal por 100g
  final double protein;       // g
  final double carbs;         // g
  final double fat;           // g
  final double fiber;         // g
  final double sodium;        // mg
  final String servingSize;   // ex: '200ml'
}
```

---

### D-11 — Imagens: Image.network com Fallback

**Decision:** Imagens via `Image.network(product.imageUrl)` com `errorBuilder` retornando ícone `LucideIcons.packageOpen` (ou similar). Sem novo pacote de imagens.

**imageUrl mock:** URLs públicas de imagens de produtos reais (Open Food Facts ou similar — apenas para dados acadêmicos).

---

### D-12 — Busca na Home: Sempre Visível no Header

**Decision:** Campo de busca sempre visível como `SliverPersistentHeader` ou dentro do `SliverAppBar` expanded area — **não** como ícone que abre/fecha. Filtra produtos reativamente enquanto o usuário digita.

**Implementação:** `searchQueryProvider = StateProvider<String>((ref) => '')` + `filteredProductsProvider` derivado.

---

### D-13 — SliverAppBar da Home: Badge + Grid/List Toggle

**Decision:**
- `leading`: Widget circular com iniciais do usuário (ex: "JA") → navega para `/profile` (placeholder Phase 5)
- `title`: Text('Home')
- `actions`: [IconButton(grid), IconButton(list)] — toggle entre GridView e ListView

**viewModeProvider:** `StateProvider<ViewMode>((ref) => ViewMode.grid)` onde `enum ViewMode { grid, list }`.

---

### D-14 — FAB: Navega para Scanner Tab

**Decision:** FAB na Home navega para o tab Scanner (índice 2) via `DefaultTabController` ou `StatefulShellRoute` controller.

**Ícone:** `LucideIcons.scanLine` ou `LucideIcons.camera`

---

## Providers Novos Nesta Fase

| Provider | Tipo | State |
|----------|------|-------|
| `productsProvider` | `Provider<List<Product>>` | MockData.products (read-only) |
| `pricesProvider` | `Provider<Map<String, Map<String, double>>>` | MockData.prices (read-only) |
| `vehicleProvider` | `Provider<Vehicle>` | MockData.vehicle (read-only) |
| `searchQueryProvider` | `NotifierProvider<SearchQueryNotifier, String>` | query string |
| `filteredProductsProvider` | `Provider<List<Product>>` | derived from products + searchQuery |
| `viewModeProvider` | `NotifierProvider<ViewModeNotifier, ViewMode>` | grid/list enum |
| `fuelToggleProvider` | `NotifierProvider<FuelToggleNotifier, bool>` | SharedPrefs persisted |
| `comparisonResultsProvider` | `Provider<List<SupermarketTotal>>` | derived — cart × prices × fuel |

---

## Screens Novas Nesta Fase

| Screen | Route | Description |
|--------|-------|-------------|
| `HomeScreen` | `/home` | redesign com SliverAppBar, busca, grid/list, FAB |
| `ProductDetailScreen` | `/home/product/:productId` | detalhe + preços + carrinho + nutricional |
| `ShoppingListScreen` | `/lista` | gestão de carrinho + botão "Comparar" |
| `PriceComparisonScreen` | `/lista/comparison` | resultado total por supermercado + fuel |

`ScannerScreen` permanece placeholder (tab 3).

---

## Constraints Carried Forward

- Sem backend, sem rede — todos os dados de MockData
- lucide_icons ^0.257.0 — único pacote de ícones
- withValues(alpha:) — não withOpacity()
- Riverpod 2.x — não upgrade para 3.x
- go_router 14.x — não upgrade para 15+
- StateNotifierProvider proibido — usar Notifier/AsyncNotifier
- ref.watch apenas em build() — ref.read em handlers

---

## Open Questions (Deferred)

| Item | Deferred To |
|------|-------------|
| Preço de combustível editável pelo usuário | Phase 5 (Perfil) |
| Dados de veículo editáveis | Phase 5 (Perfil) |
| Integração real de scanner de código de barras | Phase 4 (Scanner) |
| Animações de celebração (confete) | Phase 4 (Scanner flow) |
