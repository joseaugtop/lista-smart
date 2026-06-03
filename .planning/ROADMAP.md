# Roadmap: Lista Smart

## Overview

Lista Smart é construído em cinco fases que entregam incrementalmente o valor central do app: ajudar o usuário a fazer compras mais baratas. A jornada começa com a fundação técnica obrigatória (Flutter + design system + navegação), evolui pela camada de autenticação e estado global, chega ao loop central de compras (home + lista + comparação de preços), adiciona o sistema de gamificação Smart Coins e finaliza com o fluxo de cadastro de preços e o perfil do usuário.

## Phases

**Phase Numbering:**

- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 1: Foundation** - Scaffolding Flutter, design system dark glassmórfico, navegação 5 abas, modelos de dados e persistência local (completed 2026-06-02)
- [ ] **Phase 2: Auth + State Layer** - Tela de login simulada, RouterNotifier, todos os Notifiers Riverpod e repositórios mockados
- [ ] **Phase 3: Core Shopping Loop** - Home dashboard, lista de compras e comparação de preços — a jornada principal do usuário ponta a ponta
- [ ] **Phase 4: Smart Coins** - Loja de moedas, barra de nível animada e histórico de transações
- [ ] **Phase 5: Price Registration + Profile** - Fluxo de 3 etapas de cadastro de nota com confete e tela de perfil com edição e estatísticas

## Phase Details

### Phase 1: Foundation

**Goal:** App compila e roda com design system, navegação e persistência prontos para receber features
**Mode:** mvp
**Depends on:** Nothing (first phase)
**Requirements:** FOUN-01, FOUN-02, FOUN-03, FOUN-04, FOUN-05
**Success Criteria**:

1. App instala e abre no Android e iOS sem erros de compilação, com lucide_icons ^0.257.0 e google_fonts resolvidos
2. Todas as telas mostram fundo #09090B, primary #A3E615 e tipografia Inter — sem clash de ColorScheme em modo escuro
3. Barra de navegação inferior com 5 abas preserva o estado de scroll de cada aba ao alternar entre elas
4. Modelos User, Vehicle, Product, CartItem e CoinTransaction serializam/desserializam corretamente via toJson/fromJson
5. SharedPreferences é inicializado antes de runApp() e injetado via ProviderScope.overrides sem erro de runtime

**Plans:** 2/2 plans complete

Plans:

- [x] 01-01-PLAN.md — pubspec + design system constants + theme + domain models + SharedPreferences sentinel + unit tests
- [x] 01-02-PLAN.md — routing layer (RouterNotifier, GoRouter, StatefulShellRoute) + main.dart bootstrap + placeholder screens + human verification

### Phase 2: Auth + State Layer

**Goal:** Usuário pode fazer login simulado e o app redireciona corretamente; todos os providers de estado global estão ativos e testáveis
**Mode:** mvp
**Depends on:** Phase 1
**Requirements:** AUTH-01, AUTH-02, AUTH-03
**Success Criteria**:

1. Tela de login exibe campos email/senha com ícones Lucide e circles desfocados de fundo conforme design
2. Ao pressionar "Avançar", o estado global do usuário é preenchido com dados de José Augusto e o app navega instantaneamente para Home
3. Ao limpar o estado do usuário (simular logout), RouterNotifier redireciona automaticamente para /login sem intervenção manual
4. UserNotifier, CartNotifier, FavoritesNotifier e CoinNotifier respondem a ações sem exceções de estado nulo

**Plans:** 3 plans
Plans:
**Wave 1**

- [ ] 02-01-PLAN.md — auth backbone: MockData + UserNotifier + fix CR-02/CR-03 no RouterNotifier/goRouterProvider + redirect ativo

**Wave 2** *(blocked on Wave 1 completion)*

- [ ] 02-02-PLAN.md — LoginScreen glassmorphic (blobs + BackdropFilter + campos Lucide + loading 500ms) + widget test
- [ ] 02-03-PLAN.md — state layer: CartNotifier + FavoritesNotifier + CoinNotifier com persistência + fix WR-02

### Phase 3: Core Shopping Loop

**Goal:** Usuário pode descobrir produtos, montar sua lista de compras e comparar preços finais entre supermercados com custo de combustível incluído
**Mode:** mvp
**Depends on:** Phase 2
**Requirements:** HOME-01, HOME-02, HOME-03, HOME-04, HOME-05, HOME-06, HOME-07, SHOP-01, SHOP-02, SHOP-03, SHOP-04, SHOP-05, COMP-01, COMP-02, COMP-03
**Success Criteria**:

1. Usuário alterna Home entre grid e lista; a busca por nome filtra produtos reativamente; cards exibem imagem, marca, preço médio e botão de favorito funcional
2. Usuário adiciona produto à lista, ajusta quantidade com +/-, remove por swipe/ícone e limpa o carrinho inteiro após confirmar dialog — tudo persiste via SharedPreferences
3. Tela de Comparação exibe Bistek, Giassi e Angeloni com preço do produto + distância + custo de combustível = preço total; o vencedor está visualmente destacado
4. Ativar "Considerar Custo de Deslocamento" na lista recalcula o total usando a eficiência de combustível do veículo do usuário
5. Em mobile, toque no card abre tela de comparação; FAB navega para cadastro de preço; badge de iniciais navega para perfil

**Plans:** 4 plans
Plans:
**Wave 1**

- [ ] 03-01-PLAN.md — models/MockData/providers backbone (Product, NutritionalInfo, prices, fuelPrice, vehicle, 8 providers) + provider tests

**Wave 2** *(blocked on Wave 1)*

- [ ] 03-02-PLAN.md — HomeScreen redesign + ProductDetailScreen + cards + bottom sheet + router subroutes + tab rename Scanner

**Wave 3** *(blocked on Wave 2)*

- [ ] 03-03-PLAN.md — ShoppingListScreen completa (cart CRUD inline, footer Switch+Total+Comparar, AlertDialog limpar) + widget test

**Wave 4** *(blocked on Wave 3)*

- [ ] 03-04-PLAN.md — PriceComparisonScreen (cards ordenados, vencedor destacado, breakdown produtos/combustível/total) + home_screen_test Wave 0
**UI hint**: yes

### Phase 4: Smart Coins

**Goal:** Usuário pode acompanhar seu saldo de moedas, progresso de nível e histórico de transações na Loja Smart Coins
**Mode:** mvp
**Depends on:** Phase 3
**Requirements:** COIN-01, COIN-02, COIN-03, COIN-04
**Success Criteria**:

1. Tela exibe saldo atual de moedas com indicador visual de nível (Bronze/Prata/Ouro) correspondente ao saldo
2. Barra de progresso anima suavemente com TweenAnimationBuilder mostrando quanto falta para o próximo nível
3. Grid exibe 3 pacotes demonstrativos (100, 500, 1000 moedas) com bônus indicados
4. Histórico lista todas as transações com ícone verde para ganhos e vermelho para resgates

**Plans:** TBD
**UI hint**: yes

### Phase 5: Price Registration + Profile

**Goal:** Usuário pode registrar nota fiscal simulada e ganhar moedas, além de visualizar e editar seu perfil completo com veículo e estatísticas de impacto
**Mode:** mvp
**Depends on:** Phase 4
**Requirements:** PREG-01, PREG-02, PREG-03, PREG-04, PROF-01, PROF-02, PROF-03
**Success Criteria**:

1. Etapa 1 simula escaneamento de QR/foto com progress indicator de 2 segundos antes de avançar
2. Etapa 2 exibe dados mockados de nota (supermercado, data, valor, itens) e ao confirmar, saldo de moedas aumenta +10 e transação aparece no histórico
3. Etapa 3 mostra animação de confete e exibe "+10 moedas" antes de retornar à Home
4. Tela de perfil permite editar nome, email, endereço, modelo do veículo e consumo (km/L) com botão "Salvar Alterações" persistindo via SharedPreferences
5. Estatísticas de impacto social mockadas (buscas efetuadas, notas escaneadas, economia estimada) são visíveis na tela de perfil

**Plans:** 2 plans

Plans:
**Wave 1** *(two independent vertical slices — no file overlap, run in parallel)*

- [x] 05-01-PLAN.md — Scanner vertical slice: confetti dep + shared scan-description constant + Wave 0 scanner/coin tests + 3-step ScannerScreen wizard (PREG-01..04)
- [x] 05-02-PLAN.md — Profile vertical slice: User model vehicle fields + UserNotifier.updateProfile + Wave 0 profile/provider tests + full ProfileScreen (PROF-01..03)
**UI hint**: yes

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4 → 5

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Foundation | 2/2 | Complete    | 2026-06-02 |
| 2. Auth + State Layer | 0/3 | Not started | - |
| 3. Core Shopping Loop | 0/TBD | Not started | - |
| 4. Smart Coins | 0/TBD | Not started | - |
| 5. Price Registration + Profile | 2/2 | Complete | 2026-06-03 |
