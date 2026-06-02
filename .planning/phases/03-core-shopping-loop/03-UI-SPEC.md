---
phase: 3
slug: core-shopping-loop
status: draft
shadcn_initialized: false
preset: none
created: 2026-06-01
---

# Phase 3 — UI Design Contract

> Visual and interaction contract para o Core Shopping Loop. Gerado por gsd-ui-researcher, verificado por gsd-ui-checker.
> Esta fase entrega: HomeScreen (redesign com SliverAppBar, busca, grid/list toggle, FAB), ProductDetailScreen, ShoppingListScreen, PriceComparisonScreen e NutritionalInfoBottomSheet.

---

## Design System

| Property | Value | Source |
|----------|-------|--------|
| Tool | Flutter nativo (Material 3 dark) | CLAUDE.md + app_theme.dart |
| Preset | não aplicável — Flutter, não React/Next.js | shadcn gate: N/A |
| Component library | Material 3 via `ThemeData(useMaterial3: true)` | `app_theme.dart` (existente) |
| Icon library | `lucide_icons ^0.257.0` | CLAUDE.md (blocker crítico — ^3.0.0 inexiste) |
| Font | Inter via `google_fonts ^6.1.0` — `GoogleFonts.interTextTheme` | `app_text_theme.dart` (existente) |

---

## Spacing Scale

Tokens já implementados em `lib/core/constants/app_sizes.dart`. O executor DEVE usar esses tokens, nunca valores literais.

| Token Flutter | Valor | Uso nesta fase |
|---------------|-------|----------------|
| `AppSizes.spacingXS` | 4.0 | Gap entre ícone e texto; gap entre tag chips no card de produto |
| `AppSizes.spacingS` | 8.0 | Gap interno dos cards de produto (imagem→texto); espaço entre linhas da tabela nutricional |
| `AppSizes.spacingM` | 16.0 | Padding horizontal das telas; espaço entre seções no ProductDetailScreen |
| `AppSizes.spacingL` | 24.0 | Padding interno dos cards glassmorphic; espaço entre card de supermercado na comparação |
| `AppSizes.spacingXL` | 32.0 | Espaço inferior do conteúdo scrollável (safe area + bottom bar) |

Tokens de border radius (já em `app_sizes.dart`):
- Card de produto (grid): `AppSizes.radiusL` (16.0)
- Card de produto (list): `AppSizes.radiusM` (12.0)
- Card de supermercado (comparação): `AppSizes.radiusL` (16.0)
- Card vencedor (comparação): `AppSizes.radiusL` (16.0) com borda `AppColors.primary`
- Bottom sheet (NutritionalInfo): `AppSizes.radiusXL` (24.0) no topo
- Botões principais: `AppSizes.radiusL` (16.0)
- Controles de quantidade (+/-): `AppSizes.radiusS` (8.0)
- Campo de busca: `AppSizes.radiusL` (16.0)
- Badge de iniciais do usuário: circular (border radius = metade da altura)

Exceções ao grid de 4px:
- Touch target mínimo de botões +/- de quantidade: 44×44px (Material 3 padrão)
- Imagem do produto no ProductDetailScreen: 200px de altura (valor decorativo/funcional fixo)
- FAB: tamanho padrão Material 3 (56×56px)
- Badge de iniciais: 36×36px (circular)

---

## Typography

Fonte única: Inter (herdada do `appTextTheme` via `GoogleFonts.interTextTheme`). O executor usa os estilos do `Theme.of(context).textTheme` sem sobreposição manual de família.

| Role | Estilo Material 3 | Tamanho aprox. | Weight | Line Height | Uso nesta fase |
|------|-------------------|---------------|--------|-------------|----------------|
| Heading | `headlineSmall` | 24sp | 600 (semibold) | 1.2 | Título do ProductDetailScreen, título do ShoppingListScreen, título do PriceComparisonScreen |
| Body label | `titleMedium` | 16sp | 400 (regular) | 1.5 | Nome do produto no card; preço no card de supermercado; total do carrinho |
| Body small | `bodyMedium` | 14sp | 400 (regular) | 1.5 | Marca/categoria no card; EAN; hint text do campo de busca; valores da tabela nutricional |
| Caption | `bodySmall` | 12sp | 400 (regular) | 1.5 | Tag chips do produto; distância em km na comparação; label "melhor preço" |

Regra: máximo 4 variantes tipográficas por tela. Cada tela abaixo usa no máximo 4.
Pesos declarados: 2 — 400 (regular) e 600 (semibold).

Cor de texto:
- Texto principal (nome do produto, preços, totais): `AppColors.textMain` (`#FAFAFA`)
- Texto secundário (marca, categoria, distância): `AppColors.textSecondary` (`#A1A1AA`)
- Texto de botões primários: `AppColors.background` (`#09090B`) — contraste escuro sobre fundo primary
- Texto do badge de vencedor: `AppColors.background` (`#09090B`) — sobre fundo `AppColors.primary`

Uso de semibold (600) restrito a:
- Preço total por supermercado na PriceComparisonScreen
- Total do carrinho na ShoppingListScreen
- Nome do produto no ProductDetailScreen (headlineSmall)
- Badge de iniciais do usuário (2 caracteres em destaque)

---

## Color

Tokens já implementados em `lib/core/constants/app_colors.dart`. O executor DEVE referenciar essas constantes.

| Role | Token Flutter | Hex | Proporção | Uso nesta fase |
|------|--------------|-----|-----------|----------------|
| Dominant (60%) | `AppColors.background` | `#09090B` | Fundo `Scaffold`, espaço entre cards | Fundo de todas as 4 telas |
| Secondary (30%) | `AppColors.surface` | `#18181B` | Cards de produto, cards de supermercado, bottom sheet, item da lista | Superfície dos containers de conteúdo |
| Surface elevated | `AppColors.surfaceElevated` | `#27272A` | Controles de quantidade, campo de busca (preenchimento interno) | Elementos ligeiramente elevados sobre surface |
| Accent (10%) | `AppColors.primary` | `#A3E615` | Reservado para elementos listados abaixo | Ver lista "Accent reserved for" |
| Destructive | `AppColors.error` | `#EF4444` | Ícone/confirmação de remoção de item do carrinho, botão "Limpar Carrinho" | Confirmação de ações irreversíveis |
| Success (suporte) | `AppColors.success` | `#22C55E` | Ícone de estrela favorito quando ativado | Estado ativo do favorito |

Accent (`#A3E615`) reservado exclusivamente para:
1. Borda e badge "Melhor preço" do card vencedor na `PriceComparisonScreen`
2. Botão "Adicionar ao Carrinho" (`FilledButton`) no `ProductDetailScreen`
3. Botão "Comparar Supermercados" (`FilledButton`) no `ShoppingListScreen`
4. Ícone do FAB (`LucideIcons.scanLine`) e cor de fundo do FAB
5. Switch "Considerar Custo de Deslocamento" quando ativo (`activeColor: AppColors.primary`)
6. Borda ativa do campo de busca quando em foco
7. Badge de iniciais do usuário (fundo `AppColors.primary`, texto `AppColors.background`)
8. Ícone de favorito ativo (`AppColors.success` — ver acima — é verde, não primary)

Glassmorphic card spec (herdado da Fase 2, aplicar em todos os cards desta fase):
```
color: AppColors.surface.withValues(alpha: 0.7)
border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1.0)
borderRadius: BorderRadius.circular(AppSizes.radiusL)  // 16.0 para cards de produto
```

Card vencedor da comparação (variante adicional):
```
color: AppColors.surface.withValues(alpha: 0.7)
border: Border.all(color: AppColors.primary, width: 2.0)  // borda primary, não branca
borderRadius: BorderRadius.circular(AppSizes.radiusL)
```

Estado de destaque do menor preço em ProductDetailScreen (linha de preço, não card completo):
```
// Apenas a linha do supermercado com menor preço recebe:
color: AppColors.primary.withValues(alpha: 0.1)  // fundo suave
// e o texto do preço em AppColors.primary
```

---

## Copywriting Contract

### HomeScreen

Ponto focal: o grid de produtos (SliverGrid 2 colunas).

| Elemento | Copy | Notas |
|----------|------|-------|
| Título da AppBar | `Home` | `Text('Home')` no SliverAppBar title |
| Hint text do campo de busca | `Buscar produtos...` | Cor `AppColors.textSecondary` |
| Tooltip do toggle grid | `Exibir em grade` | `IconButton` com `LucideIcons.layoutGrid` |
| Tooltip do toggle lista | `Exibir em lista` | `IconButton` com `LucideIcons.list` |
| Tooltip do FAB | `Escanear nota fiscal` | FAB com `LucideIcons.scanLine` |
| Estado vazio da busca | `Nenhum produto encontrado para "{query}"` | Centralizado, `bodyMedium`, `textSecondary` |
| Badge de iniciais | Iniciais do usuário (ex: `JA`) | 2 caracteres, fundo primary, texto background |

### ProductDetailScreen

Ponto focal: a seção de preços por supermercado com destaque do menor preço.

| Elemento | Copy | Notas |
|----------|------|-------|
| Título da AppBar | `Detalhes do Produto` | AppBar padrão com back arrow |
| Label seção de preços | `Preços por Supermercado` | `titleMedium`, cor `textMain` |
| Destaque menor preço | `Melhor preço` | `bodySmall`, chip/badge em primary |
| CTA primário | `Adicionar ao Carrinho` | `FilledButton`, fundo primary, texto background |
| CTA nutricional | `Ver Tabela Nutricional` | `OutlinedButton`, borda `textSecondary` |
| Label EAN | `EAN:` | Prefixo inline, `bodySmall`, `textSecondary` |
| Label departamento | `Departamento:` | Prefixo inline, `bodySmall`, `textSecondary` |
| Label categoria | `Categoria:` | Prefixo inline, `bodySmall`, `textSecondary` |
| Label subcategoria | `Subcategoria:` | Prefixo inline, `bodySmall`, `textSecondary` |
| Estado de imagem falha | Ícone `LucideIcons.packageOpen`, cor `textSecondary`, tamanho 64px + `Text('Imagem indisponível', style: bodySmall, color: textSecondary)` abaixo do ícone | `errorBuilder` do `Image.network` |

### ShoppingListScreen

Ponto focal: a lista de itens do carrinho com controles de quantidade.

| Elemento | Copy | Notas |
|----------|------|-------|
| Título da AppBar | `Minha Lista` | AppBar padrão |
| Label total do carrinho | `Total estimado` | `bodySmall`, `textSecondary` |
| Valor do total | `R$ 0,00` | `titleMedium`, semibold, `textMain` |
| Label switch de combustível | `Considerar deslocamento` | Inline com Switch |
| Label sublabel do switch | `Fiat Uno · 12 km/L · R$ 6,50/L` | `bodySmall`, `textSecondary` (mock info do veículo) |
| CTA comparação | `Comparar Supermercados` | `FilledButton` full-width, visível apenas se `cart.isNotEmpty` |
| Estado vazio do carrinho | `Sua lista está vazia` | `headlineSmall`, centralizado |
| Sublabel estado vazio | `Adicione produtos na tela Home` | `bodyMedium`, `textSecondary` |
| Confirmação limpar carrinho | Título: `Limpar carrinho?` / Corpo: `Todos os itens serão removidos.` / Botões: `Manter Itens` e `Limpar Carrinho` | `AlertDialog` padrão Material 3; `Limpar Carrinho` em `AppColors.error` |
| Botão limpar (AppBar action) | sem texto — `LucideIcons.trash2`, tooltip `Limpar carrinho` | Visível apenas se `cart.isNotEmpty` |
| Tooltip remover item individual | `Remover item` | `IconButton` `LucideIcons.x` |
| Ação destrutiva: remover item | sem confirmação — remoção direta com ícone X | Quantity → 0 via botão "-" remove automaticamente |
| Ação destrutiva: limpar tudo | `AlertDialog` com confirmação | Botão `Limpar Carrinho` em `AppColors.error` |

### PriceComparisonScreen

Ponto focal: o card vencedor (primeiro da lista, borda primary).

| Elemento | Copy | Notas |
|----------|------|-------|
| Título da AppBar | `Comparação de Preços` | AppBar com back arrow |
| Label seção de resultados | `Resultado por Supermercado` | `titleMedium` |
| Label custo dos produtos | `Produtos` | `bodySmall`, `textSecondary` |
| Label custo de combustível | `Combustível (ida e volta)` | `bodySmall`, `textSecondary`; visível apenas se toggle ativo |
| Label total por supermercado | `Total` | `bodySmall`, `textSecondary` antes do valor |
| Badge vencedor | `Melhor opção` | chip/badge, fundo `AppColors.primary`, texto `AppColors.background` |
| Distância | `X,X km` | `bodySmall`, `textSecondary` |
| Estado sem combustível | linha de combustível omitida do card | quando toggle desativado |

### NutritionalInfoBottomSheet

Ponto focal: a tabela de nutrientes (6 linhas).

| Elemento | Copy | Notas |
|----------|------|-------|
| Título do bottom sheet | `Informação Nutricional` | `headlineSmall` |
| Subtítulo | `Porção: {servingSize}` | `bodySmall`, `textSecondary` |
| Label calorias | `Valor Energético` | Linha da tabela |
| Unidade calorias | `kcal` | Inline após valor |
| Label proteínas | `Proteínas` | Linha da tabela |
| Unidade proteínas | `g` | Inline após valor |
| Label carboidratos | `Carboidratos` | Linha da tabela |
| Unidade carboidratos | `g` | Inline após valor |
| Label gorduras totais | `Gorduras Totais` | Linha da tabela |
| Unidade gorduras | `g` | Inline após valor |
| Label fibras | `Fibra Alimentar` | Linha da tabela |
| Unidade fibras | `g` | Inline após valor |
| Label sódio | `Sódio` | Linha da tabela |
| Unidade sódio | `mg` | Inline após valor |
| Botão fechar | `Fechar Tabela` | `TextButton` na parte inferior |

---

## Component Inventory

Widgets a implementar ou modificar nesta fase:

| Widget/Arquivo | Tipo | Status | Ação |
|----------------|------|--------|------|
| `lib/features/home/presentation/home_screen.dart` | Tela | Placeholder (stub básico) | Redesign completo com SliverAppBar, busca, grid/list toggle, FAB |
| `lib/features/home/presentation/product_card_grid.dart` | Widget | Novo | Card de produto em modo grid (imagem + nome + marca + tag + preço médio + botão estrela) |
| `lib/features/home/presentation/product_card_list.dart` | Widget | Novo | Card de produto em modo lista (imagem menor + info inline + botão estrela) |
| `lib/features/home/presentation/product_detail_screen.dart` | Tela | Novo | Rota `/home/product/:productId` |
| `lib/features/home/presentation/nutritional_info_bottom_sheet.dart` | Widget | Novo | Bottom sheet com tabela nutricional |
| `lib/features/shopping_list/presentation/shopping_list_screen.dart` | Tela | Placeholder | Implementar completo com lista de itens, controles +/-, total, botão "Comparar" |
| `lib/features/price_comparison/presentation/price_comparison_screen.dart` | Tela | Placeholder | Implementar completo com resultados ordenados, destaque vencedor, fuel breakdown |
| `lib/features/profile/domain/product.dart` | Model | Existente | Adicionar campos: `ean`, `subcategory`, `department`, `nutritionalInfo` |
| `lib/features/profile/domain/nutritional_info.dart` | Model | Novo | `NutritionalInfo` com 6 campos + `servingSize` |
| `lib/core/data/mock_data.dart` | Dados | Existente | Adicionar `MockData.prices`, `MockData.fuelPrice`, `MockData.vehicle`, `MockData.supermarketDistances`; estender `MockData.products` |
| `lib/core/providers/search_query_notifier.dart` | Provider | Novo | `NotifierProvider<SearchQueryNotifier, String>` |
| `lib/core/providers/view_mode_notifier.dart` | Provider | Novo | `NotifierProvider<ViewModeNotifier, ViewMode>` — `enum ViewMode { grid, list }` |
| `lib/core/providers/fuel_toggle_notifier.dart` | Provider | Novo | `NotifierProvider<FuelToggleNotifier, bool>` — SharedPrefs key `lista_smart_fuel_toggle` |
| `lib/core/providers/products_provider.dart` | Provider | Novo | `Provider<List<Product>>` — `MockData.products` |
| `lib/core/providers/prices_provider.dart` | Provider | Novo | `Provider<Map<String, Map<String, double>>>` — `MockData.prices` |
| `lib/core/providers/vehicle_provider.dart` | Provider | Novo | `Provider<Vehicle>` — `MockData.vehicle` |
| `lib/core/providers/filtered_products_provider.dart` | Provider | Novo | `Provider<List<Product>>` — derivado de `productsProvider` + `searchQueryProvider` |
| `lib/core/providers/comparison_results_provider.dart` | Provider | Novo | `Provider<List<SupermarketTotal>>` — derivado de cart × prices × fuel |
| `lib/routing/app_router.dart` | Roteamento | Existente | Adicionar subrota `/home/product/:productId` e rota `/lista/comparison` |

---

## Interaction States

### HomeScreen — Estados principais

```
Estado inicial (busca vazia, grid):
  - SliverAppBar expandida com badge de iniciais (leading), título "Home", ícones grid/list (actions)
  - Campo de busca visível abaixo da AppBar (SliverPersistentHeader ou expanded area)
  - GridView de produtos com 2 colunas
  - Ícone de grid ativo (primary), ícone de lista inativo (textSecondary)
  - FAB visível no canto inferior direito

Estado busca com query:
  - Campo de busca preenchido
  - Lista filtrada reativamente (sem debounce — filtragem síncrona)
  - Se nenhum resultado: texto "Nenhum produto encontrado para "{query}""

Estado lista (viewMode = list):
  - ListView com cards em modo horizontal (imagem à esquerda, info à direita)
  - Ícone de lista ativo (primary), ícone de grid inativo (textSecondary)

Estado favorito:
  - LucideIcons.star preenchido + AppColors.success quando favoritado
  - LucideIcons.star outline + AppColors.textSecondary quando não favoritado
  - Toggle sem animação elaborada — apenas troca de ícone e cor
```

### ProductDetailScreen — Estados principais

```
Estado carregando imagem:
  - Placeholder: Container(color: AppColors.surface) durante carregamento

Estado imagem com erro:
  - Icon(LucideIcons.packageOpen, size: 64, color: AppColors.textSecondary)
  - Text('Imagem indisponível', style: bodySmall, color: textSecondary) abaixo do ícone
  - Centralizado dentro do espaço de imagem

Estado produto já no carrinho:
  - Botão "Adicionar ao Carrinho" muda para "Adicionar mais" (mesma aparência)
  - Sem disable — sempre permite adicionar mais unidades

Estado preço mínimo destacado:
  - A linha do supermercado com menor preço recebe:
    - Fundo: AppColors.primary.withValues(alpha: 0.1)
    - Texto do preço: AppColors.primary (weight 600)
    - Chip "Melhor preço" à direita do nome do supermercado
```

### ShoppingListScreen — Estados principais

```
Estado vazio (cart.isEmpty):
  - Ícone LucideIcons.shoppingCart, tamanho 64px, cor textSecondary
  - Texto "Sua lista está vazia"
  - Subtítulo "Adicione produtos na tela Home"
  - Botão "Comparar Supermercados" OCULTO
  - Botão limpar (AppBar action) OCULTO

Estado com itens (cart.isNotEmpty):
  - ListView de CartItems com controles +/- e ícone de remoção
  - Seção de total fixada antes do botão inferior
  - Switch "Considerar deslocamento" visível
  - Botão "Comparar Supermercados" VISÍVEL (fixed bottom, full-width)
  - Botão limpar (AppBar action) VISÍVEL

Interação +/- de quantidade:
  - Botão "-" com quantity = 1: remove item do carrinho diretamente (sem confirmação)
  - Botão "-" com quantity > 1: decrementa quantity
  - Botão "+": incrementa quantity
  - Valor de quantity exibido entre os dois botões (bodyMedium, textMain)

Interação limpar carrinho:
  - Toque no ícone lixeira → AlertDialog "Limpar carrinho?"
  - Botão "Manter Itens": fecha dialog, mantém carrinho intacto
  - Botão "Limpar Carrinho": cor AppColors.error → CartNotifier.clearCart() → dialog fecha
```

### PriceComparisonScreen — Estados principais

```
Estado padrão (4 supermercados ordenados):
  - Cards ordenados do mais barato ao mais caro (menor totalCost first)
  - Primeiro card: borda AppColors.primary (2px), badge "Melhor opção"
  - Demais cards: borda padrão (white 0.1, 1px)

Estado com combustível (fuelToggle = true):
  - Cada card exibe: linha "Produtos: R$ X,XX" + linha "Combustível (ida e volta): R$ X,XX" + linha "Total: R$ X,XX" em destaque
  - Distância exibida: "X,X km"

Estado sem combustível (fuelToggle = false):
  - Linha de combustível OMITIDA dos cards
  - "Total" é apenas a soma dos produtos
  - Ordenação recalculada sem fuelCost

Fórmula de cálculo (referência para executor):
  fuelCost(supermarket) = (distance[supermarket] * 2 / 12.0) * 6.50
  totalCost(supermarket) = Σ(price[productId][supermarket] * quantity) + (fuelToggle ? fuelCost : 0)
```

### NutritionalInfoBottomSheet — Estados

```
Estado padrão:
  - DraggableScrollableSheet ou showModalBottomSheet com initialChildSize: 0.5, maxChildSize: 0.85
  - Tabela com 6 linhas de nutrientes
  - Handle visual no topo (retângulo 32×4px, cor textSecondary.withValues(0.4), radiusS)
  - Botão "Fechar Tabela" no final do conteúdo scrollável
```

---

## Layout Structure

### HomeScreen

```
Scaffold(
  backgroundColor: AppColors.background,
  floatingActionButton: FAB(
    icon: LucideIcons.scanLine,
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.background,
    tooltip: 'Escanear nota fiscal',
    onPressed: → navega para tab Scanner (índice 2),
  ),
  body: CustomScrollView(
    slivers: [
      SliverAppBar(
        pinned: true,
        backgroundColor: AppColors.background,
        leading: GestureDetector(
          onTap: → context.push('/profile'),
          child: Container(
            36×36, circular,
            color: AppColors.primary,
            child: Text('JA', style: bodySmall, weight: 600, color: background),
          ),
        ),
        title: Text('Home'),
        actions: [
          IconButton(LucideIcons.layoutGrid, tooltip: 'Exibir em grade'),
          IconButton(LucideIcons.list, tooltip: 'Exibir em lista'),
        ],
      ),
      SliverPersistentHeader(
        // Campo de busca sempre visível
        pinned: true,
        delegate: _SearchBarDelegate(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: spacingM, vertical: spacingS),
            child: TextField(
              hint: 'Buscar produtos...',
              prefixIcon: LucideIcons.search,
              filled: true,
              fillColor: AppColors.surfaceElevated,
              border: radiusL,
              focusedBorder: primary,
            ),
          ),
        ),
      ),
      // Conteúdo: grid ou lista
      viewMode == grid
        ? SliverPadding(
            padding: EdgeInsets.all(spacingM),
            sliver: SliverGrid(
              crossAxisCount: 2,
              mainAxisSpacing: spacingS,
              crossAxisSpacing: spacingS,
              childAspectRatio: 0.72,  // produto com imagem quadrada + info abaixo
            ),
          )
        : SliverList(
            // product_card_list: horizontal layout
          ),
    ],
  ),
)
```

### ProductDetailScreen

```
Scaffold(
  backgroundColor: AppColors.background,
  appBar: AppBar(title: Text('Detalhes do Produto')),
  body: SingleChildScrollView(
    child: Column(
      children: [
        // Imagem do produto
        SizedBox(
          height: 200,
          child: Image.network(
            product.imageUrl,
            fit: BoxFit.contain,
            errorBuilder: → Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.packageOpen, size: 64, color: AppColors.textSecondary),
                SizedBox(height: spacingXS),
                Text('Imagem indisponível', style: bodySmall, color: textSecondary),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nome + marca
              Text(product.name, style: headlineSmall, weight: 600),
              SizedBox(height: spacingXS),
              Text(product.brand, style: bodyMedium, color: textSecondary),
              SizedBox(height: spacingM),
              // Metadados (departamento, categoria, subcategoria, EAN)
              _MetadataRow('Departamento:', product.department),
              _MetadataRow('Categoria:', product.category),
              _MetadataRow('Subcategoria:', product.subcategory),
              _MetadataRow('EAN:', product.ean),
              SizedBox(height: spacingM),
              // Seção de preços por supermercado
              Text('Preços por Supermercado', style: titleMedium),
              SizedBox(height: spacingS),
              // 4 linhas de preço (glassmorphic cards)
              ...supermarkets.map((s) => _PriceRow(s, isLowest: s == lowestPriceSupermarket)),
              SizedBox(height: spacingM),
              // Botão nutricional
              OutlinedButton.icon(
                icon: LucideIcons.info,
                label: Text('Ver Tabela Nutricional'),
                onPressed: → showModalBottomSheet(NutritionalInfoBottomSheet),
              ),
              SizedBox(height: spacingM),
              // Botão CTA principal
              FilledButton(
                width: double.infinity,
                style: backgroundColor: primary, foreground: background,
                label: 'Adicionar ao Carrinho',
                onPressed: → CartNotifier.addItem(product),
              ),
            ],
          ),
        ),
      ],
    ),
  ),
)
```

### ShoppingListScreen

```
Scaffold(
  backgroundColor: AppColors.background,
  appBar: AppBar(
    title: Text('Minha Lista'),
    actions: [
      if (cart.isNotEmpty)
        IconButton(LucideIcons.trash2, tooltip: 'Limpar carrinho', → showDialog(confirmClear)),
    ],
  ),
  body: cart.isEmpty
    ? Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.shoppingCart, 64px, textSecondary),
            SizedBox(height: spacingM),
            Text('Sua lista está vazia', style: headlineSmall),
            SizedBox(height: spacingXS),
            Text('Adicione produtos na tela Home', style: bodyMedium, color: textSecondary),
          ],
        ),
      )
    : Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.all(spacingM),
              separatorBuilder: → SizedBox(height: spacingS),
              itemBuilder: → CartItemCard(item, +/-, remove),
            ),
          ),
          // Footer fixo
          Container(
            padding: EdgeInsets.all(spacingM),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(white.withValues(0.1))),
            ),
            child: Column(
              children: [
                // Switch de combustível
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Considerar deslocamento', style: bodyMedium),
                        Text('Fiat Uno · 12 km/L · R$ 6,50/L', style: bodySmall, color: textSecondary),
                      ],
                    ),
                    Spacer(),
                    Switch(activeColor: primary, value: fuelToggle, onChanged: → fuelToggleNotifier),
                  ],
                ),
                SizedBox(height: spacingS),
                // Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total estimado', style: bodySmall, color: textSecondary),
                    Text('R$ X,XX', style: titleMedium, weight: 600),
                  ],
                ),
                SizedBox(height: spacingM),
                // Botão Comparar
                FilledButton(
                  width: double.infinity,
                  style: backgroundColor: primary, foreground: background,
                  label: 'Comparar Supermercados',
                  onPressed: → context.push('/lista/comparison'),
                ),
              ],
            ),
          ),
        ],
      ),
)
```

### PriceComparisonScreen

```
Scaffold(
  backgroundColor: AppColors.background,
  appBar: AppBar(title: Text('Comparação de Preços')),
  body: ListView.separated(
    padding: EdgeInsets.all(spacingM),
    separatorBuilder: → SizedBox(height: spacingS),
    itemBuilder: (context, index) {
      final result = comparisonResults[index];  // ordenado cheapest-first
      final isWinner = index == 0;
      return Container(
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(radiusL),
          border: Border.all(
            color: isWinner ? AppColors.primary : Colors.white.withValues(alpha: 0.1),
            width: isWinner ? 2.0 : 1.0,
          ),
        ),
        padding: EdgeInsets.all(spacingM),
        child: Column(
          children: [
            Row(
              children: [
                Text(result.supermarket, style: titleMedium),
                Spacer(),
                if (isWinner)
                  Chip(
                    label: Text('Melhor opção', style: bodySmall, color: background),
                    backgroundColor: primary,
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
            SizedBox(height: spacingS),
            _ComparisonRow('Produtos', formatBRL(result.productsCost)),
            if (fuelToggle) ...[
              _ComparisonRow(
                'Combustível (ida e volta)',
                formatBRL(result.fuelCost),
                subtitle: '${result.distanceKm.toStringAsFixed(1)} km',
              ),
            ],
            Divider(color: white.withValues(alpha: 0.08)),
            _ComparisonRow(
              'Total',
              formatBRL(result.totalCost),
              isTotal: true,  // weight 600, primary se winner
            ),
          ],
        ),
      );
    },
  ),
)
```

### NutritionalInfoBottomSheet

```
showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  builder: (_) => DraggableScrollableSheet(
    initialChildSize: 0.5,
    maxChildSize: 0.85,
    minChildSize: 0.3,
    builder: (_, controller) => Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(radiusXL)),
        border: Border.all(color: white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          // Handle
          SizedBox(height: spacingS),
          Container(width: 32, height: 4, color: textSecondary.withValues(alpha: 0.4), borderRadius: radiusS),
          SizedBox(height: spacingM),
          // Título
          Text('Informação Nutricional', style: headlineSmall),
          SizedBox(height: spacingXS),
          Text('Porção: ${info.servingSize}', style: bodySmall, color: textSecondary),
          SizedBox(height: spacingM),
          Expanded(
            child: ListView(
              controller: controller,
              children: [
                _NutriRow('Valor Energético', info.calories, 'kcal'),
                _NutriRow('Proteínas', info.protein, 'g'),
                _NutriRow('Carboidratos', info.carbs, 'g'),
                _NutriRow('Gorduras Totais', info.fat, 'g'),
                _NutriRow('Fibra Alimentar', info.fiber, 'g'),
                _NutriRow('Sódio', info.sodium, 'mg'),
                SizedBox(height: spacingM),
                TextButton(
                  label: 'Fechar Tabela',
                  onPressed: → Navigator.pop(context),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  ),
)
```

---

## Accessibility

| Elemento | Requisito |
|----------|-----------|
| Badge de iniciais do usuário | `Semantics(label: 'Perfil do usuário, iniciais JA', button: true)` |
| Campo de busca | `TextField` com `hintText` visível — acessível via TalkBack/VoiceOver |
| Ícones toggle grid/lista | `IconButton` com `tooltip` declarado — lido pelo TalkBack |
| FAB | `FloatingActionButton` com `tooltip: 'Escanear nota fiscal'` |
| Botões +/- de quantidade | Touch target mínimo 44×44px; `Semantics(label: 'Aumentar quantidade')` / `'Diminuir quantidade'` |
| Switch de combustível | `Switch` com `label` visual associado — Row com texto ao lado |
| Card vencedor da comparação | `Semantics(label: 'Melhor opção: {supermercado}, total R$ X,XX')` |
| Contraste de texto | textMain (#FAFAFA) sobre background (#09090B): ratio ≥ 15:1. Texto escuro (#09090B) sobre primary (#A3E615): ratio ≥ 7:1 |
| Ícone de imagem falha | `Semantics(label: 'Imagem indisponível')` no errorBuilder (wrapping o Column com ícone + texto) |
| Bottom sheet nutricional | `DraggableScrollableSheet` com handle visual — acessível via swipe gesture |
| Botão limpar carrinho (AppBar) | `Semantics(label: 'Limpar carrinho')` em `IconButton` com `LucideIcons.trash2` |

---

## Registry Safety

Esta fase usa Flutter com Material 3. Não há shadcn, npm registries ou third-party component registries.

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| pub.dev (lucide_icons ^0.257.0) | `LucideIcons.layoutGrid`, `LucideIcons.list`, `LucideIcons.search`, `LucideIcons.scanLine`, `LucideIcons.star`, `LucideIcons.packageOpen`, `LucideIcons.shoppingCart`, `LucideIcons.trash2`, `LucideIcons.x`, `LucideIcons.info` | não aplicável — pacote pub.dev verificado na Fase 1 |
| pub.dev (google_fonts ^6.1.0) | `GoogleFonts.interTextTheme` (já inicializado em app_text_theme.dart) | não aplicável — verificado na Fase 1 |
| pub.dev (shared_preferences ^2.2.0) | `SharedPreferences` para `fuelToggleProvider` (key: `lista_smart_fuel_toggle`) | não aplicável — verificado na Fase 1 |

---

## Checker Sign-Off

- [ ] Dimension 1 Copywriting: PASS
- [ ] Dimension 2 Visuals: PASS
- [ ] Dimension 3 Color: PASS
- [ ] Dimension 4 Typography: PASS
- [ ] Dimension 5 Spacing: PASS
- [ ] Dimension 6 Registry Safety: PASS

**Approval:** pending

---

## Pre-Population Audit

| Campo do contrato | Fonte | Decisão usada |
|-------------------|-------|---------------|
| Design system (Flutter/Material 3) | CLAUDE.md + app_theme.dart | Tech stack obrigatório |
| Font (Inter/google_fonts) | app_text_theme.dart | `GoogleFonts.interTextTheme` já implementado |
| Icon library (lucide_icons ^0.257.0) | CLAUDE.md | Versão crítica — ^3.0.0 inexiste |
| Cor dominant (#09090B) | app_colors.dart | `AppColors.background` |
| Cor secondary (#18181B) | app_colors.dart | `AppColors.surface` |
| Cor surfaceElevated (#27272A) | app_colors.dart | `AppColors.surfaceElevated` |
| Cor accent (#A3E615) | app_colors.dart + CONTEXT.md | `AppColors.primary` |
| Cor error (#EF4444) | app_colors.dart | `AppColors.error` — ações destrutivas |
| Cor success (#22C55E) | app_colors.dart | `AppColors.success` — favorito ativo |
| Spacing tokens | app_sizes.dart | `AppSizes.*` existentes |
| Glassmorphic card spec | 02-UI-SPEC.md (herdado) | `surface.withValues(0.7)` + borda branca 10% |
| Card vencedor: borda primary 2px | CONTEXT.md D-09 + critical_context | borda `AppColors.primary`, não branca |
| Estrutura de preços: Map aninhado | CONTEXT.md D-01 | `MockData.prices[productId][supermarket]` |
| 4 supermercados: Bistek/Giassi/Angeloni/Atacadão | CONTEXT.md D-02 | Consistência com MockData.supermarketDistances |
| Escopo de comparação: carrinho inteiro | CONTEXT.md D-03 | Fórmula completa com fuelCost |
| Bottom nav: tab 3 = Scanner | CONTEXT.md D-04 | Comparação via botão na ShoppingListScreen |
| Veículo: Fiat Uno, 12 km/L | CONTEXT.md D-05 | MockData.vehicle |
| Preço combustível: R$ 6,50/L fixo | CONTEXT.md D-06 | MockData.fuelPrice — editável na Phase 5 |
| Toggle combustível: SharedPrefs | CONTEXT.md D-07 | key `lista_smart_fuel_toggle`, default true |
| Tap card → ProductDetailScreen | CONTEXT.md D-08 | rota `/home/product/:productId` |
| Preços por supermercado com destaque | CONTEXT.md D-09 | menor preço com fundo primary 0.1 + texto primary |
| Product model: ean/subcategory/department/nutritionalInfo | CONTEXT.md D-10 | Novos campos no model existente |
| Image.network com errorBuilder | CONTEXT.md D-11 | `LucideIcons.packageOpen` fallback + texto "Imagem indisponível" |
| Busca sempre visível | CONTEXT.md D-12 | SliverPersistentHeader pinned |
| SliverAppBar: badge (leading) + grid/list (actions) | CONTEXT.md D-13 | Badge 36×36px circular, primary |
| FAB: LucideIcons.scanLine → Scanner tab | CONTEXT.md D-14 | Índice 2 da bottom nav |
| Botão "Comparar" visível apenas com cart.isNotEmpty | CONTEXT.md D-04 | Condicional no footer da ShoppingListScreen |
| "Limpar carrinho" com AlertDialog | REQUIREMENTS.md SHOP-05 | Confirmação antes de ação destrutiva |
| Remoção por quantity→0 (botão "-") sem confirmação | REQUIREMENTS.md SHOP-03 + UX padrão | Remoção direta por controle inline |
| Favorito: LucideIcons.star + AppColors.success | REQUIREMENTS.md HOME-04 | Verde para ativo, outline para inativo |
| Grid 2 colunas, childAspectRatio 0.72 | Default UX padrão Flutter | Proporção adequada para imagem + info |
| NutritionalInfo: 6 nutrientes + servingSize | CONTEXT.md D-10 | calories/protein/carbs/fat/fiber/sodium |
| Bottom sheet: DraggableScrollableSheet | UX padrão Material 3 | initialChildSize 0.5, max 0.85 |

**Decisões pré-populadas de upstream:** 31
**Decisões requerendo input do usuário:** 0
**Defaults aplicados:** 3 (grid 2 colunas, childAspectRatio, bottom sheet sizes)

---

*Fase: 3 — Core Shopping Loop*
*UI-SPEC gerado: 2026-06-01*
*UI-SPEC revisado: 2026-06-01 (checker revision — copywriting fixes)*
*Gerado por: gsd-ui-researcher*
