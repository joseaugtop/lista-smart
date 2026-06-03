# Phase 5: Price Registration + Profile - Context

**Gathered:** 2026-06-02
**Status:** Ready for planning

<domain>
## Phase Boundary

Dois flows independentes entregues em paralelo:
1. **Cadastro de nota fiscal simulada** — ScannerScreen recebe 3 etapas via PageView (scan → confirmar nota → celebrar +10 moedas com confete)
2. **Tela de Perfil editável** — ProfileScreen com campos de usuário + veículo + estatísticas de impacto mockadas

Reqs: PREG-01, PREG-02, PREG-03, PREG-04, PROF-01, PROF-02, PROF-03

</domain>

<decisions>
## Implementation Decisions

### D-01 — Estrutura do Fluxo de 3 Etapas

**Decision:** PageView com PageController dentro de `ScannerScreen` (ConsumerStatefulWidget). Sem sub-rotas — as 3 etapas são widgets filhos do PageView, navegados via `_controller.nextPage()`. Back button do sistema volta à etapa anterior via controller.

**Etapas:**
- Página 0: Escolha de método (QR Code ou Foto do Cupom)
- Página 1: Confirmação da nota mock
- Página 2: Celebração com confete

**Rationale:** Padrão Flutter para wizards curtos. Sem boilerplate de roteamento. Mantém estado local entre etapas.

---

### D-02 — Etapa 1: Dois Botões com Visuais Distintos, Mesmo Flow

**Decision:** Dois botões com ícones diferentes:
- "Escanear QR Code" → `LucideIcons.qrCode`
- "Foto do Cupom" → `LucideIcons.camera`

Ambos disparam o mesmo loading de 2 segundos. Loading = overlay com blur + `CircularProgressIndicator(color: AppColors.primary)` — mesmo padrão do `ShoppingListScreen._compareWithLoading()`.

---

### D-03 — Confete: Package `confetti: ^0.7.0`

**Decision:** Usar `confetti: ^0.7.0` do pub.dev. `ConfettiController` iniciado com `duration: Duration(seconds: 3)`. `ConfettiWidget` dispara automaticamente no `initState` da página 2 (via `_confettiController.play()`). Sem delay adicional — dispara imediatamente ao entrar na página.

**pubspec.yaml:** adicionar `confetti: ^0.7.0` às dependencies.

---

### D-04 — Etapa 2: Nota Fiscal Fixa

**Decision:** Dados hardcoded em `MockData` (ou constante local):
- Supermercado: "Bistek Supermercados"
- Data: data atual via `DateTime.now()` formatada com `DateFormat('dd/MM/yyyy')`
- Total: R$ 87,43
- Itens: 3-4 produtos de `MockData.products` (ex: pão, leite, banana + mais 1)

Ao confirmar, chama `ref.read(coinProvider.notifier).addCoins(10, 'Cadastro de nota fiscal')`.

---

### D-05 — Retorno Após Etapa 3

**Decision:** Botão "Voltar para Home" na etapa 3 navega via `context.go(AppRoutes.scanner)` com `pageController.jumpToPage(0)` para resetar para a etapa 1. Permanece na tab Scanner (não salta para tab Home), tab visualmente resetada para próximo uso.

**Rationale:** Menos disruptivo em termos de navegação de abas. Usuário pode escanear outra nota imediatamente.

---

### D-06 — Veículo no Perfil: Estender Modelo User

**Decision:** Adicionar dois campos ao domínio `User`:
- `String vehicleModel` (default: `'Fiat Uno'` de `MockData.user`)
- `double fuelEfficiency` (default: `12.0` de `MockData.vehicle`)

`UserNotifier` já persiste via SharedPreferences — `updateProfile()` atualiza todos os campos de uma vez. `ProfileScreen` lê de `userNotifierProvider` e salva via `ref.read(userNotifierProvider.notifier).updateProfile(...)`.

**Migração de MockData.vehicle:** `ShoppingListScreen` e `PriceComparisonScreen` que usam `MockData.vehicle` passam a ler `ref.watch(userNotifierProvider)?.fuelEfficiency` (com fallback para `MockData.vehicle.fuelEfficiencyKmPerLiter`).

---

### D-07 — Feedback ao Salvar Perfil

**Decision:** SnackBar `'Perfil atualizado!'` com `AppColors.primary` como `backgroundColor` — consistente com padrão de SnackBars positivos no app. Botão "Salvar Alterações" fica habilitado sempre (sem dirty-state tracking).

---

### D-08 — Navegação para o Perfil

**Decision:** `ProfileScreen` é tela normal na tab 4 (já registrada no router). Badge de iniciais no header da `HomeScreen` chama `context.go(AppRoutes.profile)`. Sem modal — sem diferenciação por ponto de entrada.

---

### D-09 — Estatísticas de Impacto (PROF-03): Parcialmente Derivadas

**Decision:**
- **Notas escaneadas:** contagem real de transações em `coinProvider.state.transactions` onde `description == 'Cadastro de nota fiscal'`
- **Buscas efetuadas:** fixo mockado (ex: 47)
- **Economia estimada:** fixo mockado (ex: R$ 342,00)

Formato: cards de stats com ícone + valor + label (ex: `LucideIcons.fileText` + "12" + "notas escaneadas").

---

### Claude's Discretion

- Layout interno do ProfileScreen (scroll vs. SliverAppBar)
- Organização visual dos campos de edição (seções separadas por Card vs. lista contínua)
- Ícone representativo de cada stat de impacto

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requisitos
- `.planning/REQUIREMENTS.md` — PREG-01 a PREG-04, PROF-01 a PROF-03 (seção Phase 5)
- `.planning/ROADMAP.md` — Phase 5 success criteria (5 itens)

### Providers e Domínio Existentes
- `lib/core/providers/coin_notifier.dart` — `coinProvider`, `addCoins()`, `spendCoins()`, `CoinLevel` enum, `coinLevelOf()`, `coinLevelProgress()`
- `lib/core/providers/user_notifier.dart` — `userNotifierProvider`, `UserNotifier` — PRECISA de novo método `updateProfile()`
- `lib/features/auth/domain/user.dart` — modelo User — PRECISA de 2 novos campos: `vehicleModel`, `fuelEfficiency`
- `lib/features/profile/domain/vehicle.dart` — Vehicle model (referência apenas — não será provider separado)
- `lib/core/data/mock_data.dart` — `MockData.vehicle`, `MockData.user`, `MockData.products` — nota mock usa produtos daqui

### Telas Existentes (Placeholders a Substituir)
- `lib/features/price_registration/presentation/scanner_screen.dart` — ScannerScreen placeholder (Tab 2) — SUBSTITUIR pelo PageView de 3 etapas
- `lib/features/profile/presentation/profile_screen.dart` — ProfileScreen placeholder (Tab 4) — SUBSTITUIR pela tela completa

### Padrões de Referência
- `lib/features/shopping_list/presentation/shopping_list_screen.dart` — overlay de loading com blur (D-02 replica este padrão)
- `lib/features/smart_coins/presentation/store_screen.dart` — padrão SnackBar positivo, glassmorphic cards
- `lib/features/auth/presentation/login_screen.dart` — padrão ConsumerStatefulWidget, glassmorphic, campos TextField estilizados
- `lib/core/constants/app_colors.dart` — tokens obrigatórios (`AppColors.*`)
- `lib/core/constants/app_sizes.dart` — tokens obrigatórios (`AppSizes.*`)

### Roteamento
- `lib/routing/app_router.dart` — `StatefulShellRoute.indexedStack`, rotas `/scanner` e `/profile` já registradas
- `lib/routing/app_routes.dart` — `AppRoutes.scanner`, `AppRoutes.profile`

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `BackdropFilter(ImageFilter.blur(...))` + `Container(color: Colors.black.withValues(alpha:0.6))` — overlay de loading (ShoppingListScreen) — reutilizar na etapa 1 (D-02)
- `ConsumerStatefulWidget` pattern — ShoppingListScreen, HomeScreen — padrão para ScannerScreen (precisa de `PageController` + `ConfettiController` + `_loading` bool)
- SnackBar com `ScaffoldMessenger.of(context).showSnackBar(...)` — StoreScreen `_PackageCard` — reutilizar para "Perfil atualizado!"
- `DateFormat('dd/MM/yyyy', 'pt_BR')` — StoreScreen histórico — usar para data da nota mock

### Established Patterns
- `withValues(alpha:)` — NUNCA `withOpacity()` — enforced em toda a codebase
- `AppColors.*` / `AppSizes.*` — sem literais de cor ou espaçamento
- `ref.watch` apenas em `build()` — `ref.read` apenas em handlers
- `NotifierProvider<T, S>` — nunca `StateNotifierProvider`
- `LucideIcons.*` — ícones obrigatórios (pacote `lucide_icons: ^0.257.0`)

### Integration Points
- `coinProvider.notifier.addCoins(10, 'Cadastro de nota fiscal')` — chamado ao confirmar etapa 2 (PREG-04)
- `userNotifierProvider` — `ProfileScreen` lê e salva dados do perfil + veículo
- `userNotifierProvider` — badge de iniciais na `HomeScreen` (HOME-06) já implementado — navega para `/profile` com `context.go(AppRoutes.profile)`
- `MockData.products` — etapa 2 exibe 3-4 itens da lista existente de produtos

</code_context>

<specifics>
## Specific Ideas

- **Confete:** `ConfettiWidget` com `blastDirectionality: BlastDirectionality.explosive`, cores usando `AppColors.primary` + secundárias festivas (laranja, rosa, amarelo)
- **Etapa 1 layout:** dois cards grandes centralizados (glassmorphic), um para QR e outro para Foto, com ícone grande + texto
- **Etapa 2 layout:** card de nota fiscal (glassmorphic) com supermercado no topo + lista de itens + total em destaque + botão "Confirmar e Ganhar Moedas" em `AppColors.primary`
- **Etapa 3 layout:** ConfettiWidget no topo da tela + ícone grande de moeda animado (TweenAnimationBuilder scale) + "+10 Smart Coins" em headline + botão "Voltar para Home"
- **ProfileScreen:** AppBar com avatar/iniciais do usuário (Container circular, AppColors.primary), ScrollView com seções "Dados Pessoais" e "Veículo" e "Impacto Social"

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 5-price-registration-profile*
*Context gathered: 2026-06-02*
