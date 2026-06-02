# Phase 3 Discussion Log

**Date:** 2026-06-01
**Participants:** José Augusto + Claude
**Gray Areas Discussed:** 4

---

## Gray Area 1 — Preços por Supermercado

**Question:** Como estruturar dados de preços? Quais supermercados? Escopo da comparação?

**Discussion:**
- Estrutura: Map aninhado `Map<String, Map<String, double>>` (productId → supermarket → price)
- Supermercados: todos os 4 (Bistek, Giassi, Angeloni, Atacadão) — consistência com supermarketDistances
- Escopo: carrinho inteiro, não produto individual — entrega a proposta de valor real

**Decision:** D-01, D-02, D-03

---

## Gray Area 2 — Navegação para Comparação

**Question:** Como usuário acessa PriceComparisonScreen? Bottom nav "Comparar" ou outro caminho?

**Discussion (free text from user):**
> "bottom nav 'Comparar' → 'Scanner'; comparison only via button in Lista screen (≥1 item); empty state solved by design"

**Decision:** D-04 — Tab 3 vira Scanner. Comparação acessada via botão fixo em ShoppingListScreen.

---

## Gray Area 3 — Cálculo de Combustível

**Question:** Dados do veículo? Preço do combustível? Toggle persiste?

**Discussion:**
- Veículo: Fiat Uno, 12km/L como default em MockData
- Preço: R$6,50/L fixo em MockData fase 3, editável no Perfil (fase 5)
- Toggle: persiste em SharedPreferences via FuelToggleNotifier

**Decision:** D-05, D-06, D-07

---

## Gray Area 4 — Navegação e Layout

**Question:** Tap no card → detalhe ou comparação? Busca como? Badge SliverAppBar? FAB?

**Discussion:**
- Tap card → ProductDetailScreen (detalhe, não comparação direta)
- ProductDetailScreen também mostra preços por supermercado + tabela nutricional (bottom sheet)
- Extensões do model Product: EAN, subcategoria, departamento, NutritionalInfo
- Imagens: Image.network com fallback (sem novo pacote)
- Busca: sempre visível no header (não ícone toggle)
- SliverAppBar: leading = iniciais badge, actions = grid/list icons
- FAB: navega para Scanner tab

**Decision:** D-08 a D-14
