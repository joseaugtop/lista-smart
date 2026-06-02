---
phase: 4
name: smart-coins
status: planned
planned_at: "2026-06-02"
---

# Phase 4 — Smart Coins: Implementation Context

## Phase Goal

Implementar a tela Smart Coins completa: exibir saldo, nível visual (Bronze/Prata/Ouro), barra de progresso animada, grid de pacotes demonstrativos e histórico de transações. Tornar `coinProvider` a fonte única de verdade para saldo de moedas.

---

## Locked Decisions

### D-01 — CoinProvider como fonte única de verdade

**Decision:** `coinProvider` (CoinState com balance + transactions) é a fonte única de saldo. `userNotifierProvider.coinBalance` é usado apenas para seed inicial. ShoppingListScreen e qualquer outra tela que exibe ou consome moedas lê de `coinProvider`.

**Rationale:** Phase 3 adicionou `UserNotifier.spendCoins()` que deduz do `user.coinBalance` mas não registra CoinTransaction nem atualiza `coinProvider`. Isso cria divergência. A solução correta é mover toda lógica de gasto para `CoinNotifier.spendCoins()`.

---

### D-02 — Sistema de Níveis: Bronze / Prata / Ouro

**Decision:**
```
Bronze : balance < 500
Prata  : 500 ≤ balance < 1500
Ouro   : balance ≥ 1500
```

**Progress bar:**
- Bronze → Prata: `balance / 500.0` (clamp 0.0–1.0)
- Prata  → Ouro:  `(balance - 500) / 1000.0` (clamp 0.0–1.0)
- Ouro: `1.0` (max atingido)

**Cores dos níveis:**
- Bronze: `Color(0xFFCD7F32)`
- Prata:  `Color(0xFFC0C0C0)`
- Ouro:   `Color(0xFFFFD700)`

---

### D-03 — Pacotes Demonstrativos (sem compra real)

**Decision:** 3 cards fixos: 100 moedas (sem bônus), 500 moedas (+50 bônus), 1000 moedas (+200 bônus). Chip "Demonstrativo" em cada card. Botão "Obter" abre `SnackBar` informando que é demonstrativo. Sem fluxo de pagamento.

**Rationale:** COIN-03 especifica "demonstrativos". Out of scope: pagamentos reais.

---

### D-04 — CoinNotifier.spendCoins

**Decision:** Adicionar método `void spendCoins(int amount, String description)` ao CoinNotifier que:
1. Registra CoinTransaction com amount negativo
2. Decrementa balance
3. Persiste via _persist()

`UserNotifier.spendCoins()` (adicionado na Phase 3) deve ser removido ou delegado para `CoinNotifier.spendCoins()` para evitar duplicação.

---

### D-05 — Histórico: ícone por tipo de transação

**Decision:**
- amount > 0: `LucideIcons.plus` + `AppColors.success`
- amount < 0: `LucideIcons.minus` + `AppColors.error`

Valor formatado como `+N` ou `-N` (sem R$, são moedas).

---

## Providers Existentes (reutilizar)

| Provider | Estado | Localização |
|----------|--------|-------------|
| `coinProvider` | `CoinState(balance, transactions)` | `lib/core/providers/coin_notifier.dart` |
| `userNotifierProvider` | `User?` | `lib/core/providers/user_notifier.dart` |

## Screens

| Screen | Route | Ação |
|--------|-------|------|
| `StoreScreen` | `/store` (tab 4) | Redesign completo — manter nome da classe |

## Constraints Carried Forward

- No `withOpacity()` → `withValues(alpha:)`
- `ref.watch` só em `build()`
- `AppColors.*` / `AppSizes.*` — sem literais
- `TweenAnimationBuilder` para barra de progresso (COIN-02 exige)
