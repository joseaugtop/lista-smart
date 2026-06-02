---
phase: 2
slug: auth-state-layer
status: draft
shadcn_initialized: false
preset: none
created: 2026-06-01
---

# Phase 2 — UI Design Contract

> Visual and interaction contract para a Auth + State Layer. Gerado por gsd-ui-researcher, verificado por gsd-ui-checker.
> Esta fase entrega: tela de login simulada (glassmorphic) + auth guard ativo via RouterNotifier + 4 Notifiers globais com persistência.

---

## Design System

| Property | Value | Source |
|----------|-------|--------|
| Tool | Flutter nativo (Material 3 dark) | CONTEXT.md + CLAUDE.md |
| Preset | não aplicável — Flutter, não React/Next.js | shadcn gate: N/A |
| Component library | Material 3 via `ThemeData(useMaterial3: true)` | `app_theme.dart` |
| Icon library | `lucide_icons ^0.257.0` | CLAUDE.md (blocker crítico) |
| Font | Inter via `google_fonts ^6.1.0` — `GoogleFonts.interTextTheme` | `app_text_theme.dart` |

---

## Spacing Scale

Tokens já implementados em `lib/core/constants/app_sizes.dart`. O executor DEVE usar esses tokens, nunca valores literais.

| Token Flutter | Valor | Uso nesta fase |
|---------------|-------|----------------|
| `AppSizes.spacingXS` | 4.0 | Gap entre ícone e rótulo do campo de formulário |
| `AppSizes.spacingS` | 8.0 | Padding interno do `TextFormField`; gap entre título e subtítulo |
| `AppSizes.spacingM` | 16.0 | Padding lateral do card glassmorphic; espaço entre campos de formulário |
| `AppSizes.spacingL` | 24.0 | Padding vertical interno do card; espaço entre botão "Avançar" e último campo |
| `AppSizes.spacingXL` | 32.0 | Margem superior do card em relação ao topo da tela |

Exceções:
- Touch target mínimo do `IconButton` (toggle de senha): 44px (Material 3 padrão, não sobrepõe o token)
- `CircularProgressIndicator` durante loading: 24px de diâmetro (Material 3 padrão)
- Blobs de fundo: 200px e 120px de diâmetro (valores decorativos fora da grade funcional)

Tokens de border radius (já em `app_sizes.dart`):
- Card glassmorphic: `AppSizes.radiusXL` (24.0)
- `TextFormField`: `AppSizes.radiusM` (12.0)
- Botão "Avançar": `AppSizes.radiusL` (16.0)

---

## Typography

Fonte única: Inter (herdada do `appTextTheme` via `GoogleFonts.interTextTheme`). O executor usa os estilos do `Theme.of(context).textTheme` sem sobreposição manual de família.

| Role | Estilo Material 3 | Tamanho aprox. | Weight | Line Height | Uso nesta fase |
|------|-------------------|---------------|--------|-------------|----------------|
| Display | `displaySmall` | 36sp | 400 (regular) | 1.2 | "Lista Smart" — nome do app no topo da tela |
| Body label | `titleMedium` | 16sp | 500 (medium) | 1.5 | Subtítulo "Faça compras mais inteligentes" |
| Input text | `bodyMedium` | 14sp | 400 (regular) | 1.5 | Texto digitado nos campos email/senha |
| Button | `labelLarge` | 14sp | 600 (semibold) | 1.0 | Rótulo do botão "Avançar" |

Regra: máximo 4 variantes tipográficas por tela. Esta tela usa exatamente 4 acima.

Cor de texto:
- Texto principal (nome do app, rótulos de campo): `AppColors.textMain` (`#FAFAFA`)
- Texto secundário (subtítulo, hint text): `AppColors.textSecondary` (`#A1A1AA`)
- Texto do botão "Avançar": `AppColors.background` (`#09090B`) — contraste escuro sobre fundo primary

---

## Color

Tokens já implementados em `lib/core/constants/app_colors.dart`. O executor DEVE referenciar essas constantes.

| Role | Token Flutter | Hex | Proporção | Uso nesta fase |
|------|--------------|-----|-----------|----------------|
| Dominant (60%) | `AppColors.background` | `#09090B` | Fundo `Scaffold` + camada base do `Stack` | Fundo da tela de login; cor de fundo do card com opacity |
| Secondary (30%) | `AppColors.surface` | `#18181B` | Card glassmorphic com `opacity: 0.7` | Container central do formulário de login |
| Accent (10%) | `AppColors.primary` | `#A3E615` | Reservado para elementos listados abaixo | Ver lista "Accent reserved for" |
| Destructive | `AppColors.error` | `#EF4444` | Ausente nesta fase — sem ações destrutivas | N/A nesta fase |
| Success (suporte) | `AppColors.success` | `#22C55E` | Ausente nesta fase | N/A nesta fase |

Accent (`#A3E615`) reservado exclusivamente para:
1. Texto do nome "Lista Smart" (identidade visual, topo da tela)
2. Background do botão `FilledButton` "Avançar"
3. Cor dos blobs decorativos de fundo (`color: AppColors.primary.withValues(alpha: 0.3)`)
4. `CircularProgressIndicator(color: AppColors.primary)` durante loading state
5. Borda ativa do `TextFormField` quando em foco (`focusedBorder`)

Glassmorphic card spec:
```
color: AppColors.surface.withValues(alpha: 0.7)
border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1.0)
borderRadius: BorderRadius.circular(AppSizes.radiusXL)  // 24.0
```

Blobs de fundo spec (via `BackdropFilter`):
- Blob 1 (grande, canto superior direito): `AppColors.primary.withValues(alpha: 0.25)`, diâmetro 200px
- Blob 2 (menor, canto inferior esquerdo): `AppColors.primary.withValues(alpha: 0.15)`, diâmetro 120px
- Blur: `ImageFilter.blur(sigmaX: 60, sigmaY: 60)` aplicado via `BackdropFilter`

---

## Copywriting Contract

Esta fase tem uma única tela com interação de usuário: LoginScreen.

| Elemento | Copy | Notas |
|----------|------|-------|
| Nome do app (display) | `Lista Smart` | Fonte display, cor primary |
| Subtítulo da tela | `Faça compras mais inteligentes` | Cor textSecondary |
| Label do campo email | `E-mail` | Hint text no TextFormField |
| Hint text do campo email | `seu@email.com` | Cor textSecondary |
| Label do campo senha | `Senha` | Hint text no TextFormField |
| Hint text do campo senha | `••••••••` | Cor textSecondary |
| Tooltip do toggle de visibilidade | `Mostrar senha` / `Ocultar senha` | Acessibilidade |
| CTA primário | `Avançar` | FilledButton largura total |
| Loading state (durante 500ms) | sem texto — apenas `CircularProgressIndicator` | Botão desabilitado durante loading |
| Estado vazio | não aplicável — sem dados a exibir no formulário | N/A |
| Estado de erro | não aplicável — sem validação de formulário (D-05) | N/A — qualquer input avança |
| Ações destrutivas | nenhuma nesta fase | N/A |

---

## Component Inventory

Widgets a implementar ou modificar nesta fase:

| Widget/Arquivo | Tipo | Status | Ação |
|----------------|------|--------|------|
| `lib/features/auth/presentation/login_screen.dart` | Tela | Placeholder (stub) | Implementar completo com glassmorphic layout |
| `lib/routing/router_notifier.dart` | Lógica de roteamento | Existente com bug CR-02 | Corrigir: usar `ChangeNotifier` com lista de listeners |
| `lib/routing/app_router.dart` | Provider de roteamento | Existente com bug CR-03 | Corrigir: `ref.read(.notifier)` em vez de `ref.watch` |
| `lib/core/providers/user_notifier.dart` | Provider Riverpod | Novo | Criar `NotifierProvider<UserNotifier, User?>` |
| `lib/core/providers/cart_notifier.dart` | Provider Riverpod | Novo | Criar `NotifierProvider<CartNotifier, List<CartItem>>` |
| `lib/core/providers/favorites_notifier.dart` | Provider Riverpod | Novo | Criar `NotifierProvider<FavoritesNotifier, List<String>>` |
| `lib/core/providers/coin_notifier.dart` | Provider Riverpod | Novo | Criar `NotifierProvider<CoinNotifier, CoinState>` |
| `lib/core/data/mock_data.dart` | Dados estáticos | Novo | Criar com `MockData.user`, `MockData.products`, etc. |

---

## Interaction States

### LoginScreen — Fluxo principal

```
Estado inicial (idle):
  - Campos email e senha vazios, hint text visível
  - Botão "Avançar" ativo (sem validação)
  - Ícone LucideIcons.eyeOff no sufixo da senha (senha oculta por padrão)

Estado digitando:
  - Borda focada do campo ativa em AppColors.primary (#A3E615)
  - Cursor de texto visível em AppColors.primary

Estado loading (500ms após toque em "Avançar"):
  - Botão "Avançar" substituído por CircularProgressIndicator(color: AppColors.primary)
  - Campos desabilitados (não interativos durante loading)

Estado autenticado (após Future.delayed):
  - UserNotifier preenchido com MockData.user (José Augusto)
  - RouterNotifier.redirect() detecta user != null → retorna '/home'
  - GoRouter navega automaticamente para /home (sem interação manual)
```

### RouterNotifier — Auth guard

```
Usuário null + rota qualquer → redirect para '/login'
Usuário não-null + rota '/login' → redirect para '/home'
Usuário não-null + qualquer outra rota → null (sem redirect)
```

---

## Layout Structure

### LoginScreen

```
Scaffold(
  backgroundColor: AppColors.background,
  body: Stack(
    children: [
      // Camada 1: blobs decorativos (BackdropFilter)
      Positioned(top: -50, right: -50,
        child: ClipOval(Container(200x200, primary.withValues(0.25)))
      ),
      Positioned(bottom: -30, left: -30,
        child: ClipOval(Container(120x120, primary.withValues(0.15)))
      ),
      BackdropFilter(blur: 60),

      // Camada 2: conteúdo centralizado
      Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: AppSizes.spacingM),
          child: Column(
            children: [
              // Título
              Text('Lista Smart', style: displaySmall, color: primary),
              SizedBox(height: AppSizes.spacingS),
              Text('Faça compras mais inteligentes', style: titleMedium),
              SizedBox(height: AppSizes.spacingXL),

              // Card glassmorphic
              Container(
                decoration: glassmorphicDecoration,
                padding: EdgeInsets.all(AppSizes.spacingL),
                child: Column(
                  children: [
                    // Campo email
                    TextFormField(prefixIcon: LucideIcons.mail),
                    SizedBox(height: AppSizes.spacingM),
                    // Campo senha com toggle
                    TextFormField(
                      prefixIcon: LucideIcons.lock,
                      suffixIcon: IconButton(
                        icon: isVisible ? LucideIcons.eye : LucideIcons.eyeOff,
                      ),
                    ),
                    SizedBox(height: AppSizes.spacingL),
                    // Botão ou loading
                    isLoading
                      ? CircularProgressIndicator(color: primary)
                      : FilledButton(width: double.infinity, 'Avançar'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  ),
)
```

---

## Accessibility

| Elemento | Requisito |
|----------|-----------|
| Campos de formulário | `TextFormField` com `labelText` ou `hintText` — acessível via TalkBack/VoiceOver |
| Toggle de visibilidade da senha | `Tooltip('Mostrar senha')` / `Tooltip('Ocultar senha')` no `IconButton` |
| Botão "Avançar" desabilitado | `FilledButton.onPressed = null` durante loading — semanticamente desabilitado |
| Contraste de texto | textMain (#FAFAFA) sobre background (#09090B): ratio ≥ 15:1. Texto escuro do botão (#09090B) sobre primary (#A3E615): ratio ≥ 7:1 |
| Touch targets | Mínimo 44x44px para todos os `IconButton` |

---

## Registry Safety

Esta fase usa Flutter com Material 3. Não há shadcn, npm registries ou third-party component registries.

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| pub.dev (lucide_icons ^0.257.0) | `LucideIcons.mail`, `LucideIcons.lock`, `LucideIcons.eye`, `LucideIcons.eyeOff` | não aplicável — pacote pub.dev verificado na Fase 1 |
| pub.dev (google_fonts ^6.1.0) | `GoogleFonts.interTextTheme` (já inicializado) | não aplicável — verificado na Fase 1 |

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
| Cor accent (#A3E615) | app_colors.dart + CONTEXT.md D-01, D-04 | `AppColors.primary` |
| Cor error (#EF4444) | app_colors.dart | `AppColors.error` |
| Spacing tokens | app_sizes.dart | `AppSizes.*` existentes |
| Glassmorphic card spec | CONTEXT.md D-01 + specifics | `surface.withValues(0.7)` + borda branca 10% |
| Blobs decorativos | CONTEXT.md D-01 + specifics | ClipOval + BackdropFilter blur 60 |
| Título "Lista Smart" em primary | CONTEXT.md D-02 | identidade visual sem ícone separado |
| Toggle de senha (eye/eyeOff) | CONTEXT.md D-03 | `LucideIcons.eye` / `LucideIcons.eyeOff` |
| FilledButton background primary | CONTEXT.md D-04 | `AppColors.primary`, texto `AppColors.background` |
| Sem validação de formulário | CONTEXT.md D-05 | qualquer toque avança |
| Loading 500ms + CircularProgressIndicator | CONTEXT.md D-06 | `Future.delayed(Duration(milliseconds: 500))` |
| Redirect via RouterNotifier | CONTEXT.md D-07, D-08, D-09, D-10 | ChangeNotifier + ref.read(.notifier) |
| mock_data.dart com MockData.user | CONTEXT.md D-11 | arquivo único de constantes estáticas |
| 750 moedas iniciais (nível Prata) | CONTEXT.md D-14 | `coinBalance = 750` em MockData.user |
| Persistência de CartNotifier e FavoritesNotifier | CONTEXT.md D-15 | SharedPreferences sobrevive ao restart |
| CTA "Avançar" | CONTEXT.md D-04 | FilledButton full-width |
| Sem validação / sem estado de erro | CONTEXT.md D-05 | auth 100% simulado |

**Decisões pré-populadas de upstream:** 20
**Decisões requerendo input do usuário:** 0
**Defaults aplicados:** 0

---

*Fase: 2 — Auth + State Layer*
*UI-SPEC gerado: 2026-06-01*
*Gerado por: gsd-ui-researcher*
