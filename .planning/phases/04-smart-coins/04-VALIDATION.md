---
phase: 4
slug: smart-coins
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-02
---

# Phase 4 — Validation Strategy

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test (built-in) |
| **Quick run** | `flutter test` |
| **Estimated runtime** | ~5s |

## Sampling Rate

- After every task: `flutter test`
- Before verify-work: full suite green

## Per-Task Verification Map

| Req ID | Behavior | Test Type | Command | File Exists | Status |
|--------|----------|-----------|---------|-------------|--------|
| COIN-01 | Saldo + nível badge renderiza corretamente | widget | `flutter test test/features/smart_coins/store_screen_test.dart` | ❌ | ⬜ pending |
| COIN-02 | TweenAnimationBuilder progress bar presente | widget | `flutter test test/features/smart_coins/store_screen_test.dart` | ❌ | ⬜ pending |
| COIN-03 | 3 pacotes renderizam com bônus e chip Demonstrativo | widget | `flutter test test/features/smart_coins/store_screen_test.dart` | ❌ | ⬜ pending |
| COIN-04 | Histórico lista transações com cor correta | widget | `flutter test test/features/smart_coins/store_screen_test.dart` | ❌ | ⬜ pending |
| D-04 | CoinNotifier.spendCoins decrementa + registra tx negativa | unit | `flutter test test/providers/coin_notifier_test.dart` | ✅ exists | ⬜ extend |

## Wave 0 Requirements

- [ ] `test/features/smart_coins/store_screen_test.dart` — cobre COIN-01/02/03/04
- [ ] `test/providers/coin_notifier_test.dart` — estender com spendCoins test

## Manual-Only Verifications

| Behavior | Requirement | Why Manual |
|----------|-------------|------------|
| Barra de progresso anima ao entrar na tela | COIN-02 | Animação em widget test não verifica suavidade visual |
| Chip "Demonstrativo" visível no card | COIN-03 | Pode ser verificado via widget test — prioridade baixa |

## Validation Sign-Off

- [ ] Wave 0 cobre COIN-01/02/03/04
- [ ] coin_notifier_test extendido com spendCoins
- [ ] Suite completa verde
- [ ] `nyquist_compliant: true`
