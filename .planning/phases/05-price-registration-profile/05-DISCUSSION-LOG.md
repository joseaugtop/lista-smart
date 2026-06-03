# Phase 5: Price Registration + Profile - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-02
**Phase:** 5-price-registration-profile
**Areas discussed:** Fluxo das 3 etapas, Animação de Confete, Dados do Veículo no Perfil, Conteúdo da Nota Mock

---

## Fluxo das 3 Etapas

| Option | Description | Selected |
|--------|-------------|----------|
| PageView dentro de ScannerScreen | ConsumerStatefulWidget com PageController. Sem rotas novas. Back volta etapa anterior via controller. | ✓ |
| 3 sub-rotas go_router | /scanner → /scanner/confirm → /scanner/celebration. Mais flex mas mais boilerplate. | |
| Você decide | Claude escolhe. | |

**User's choice:** PageView dentro de ScannerScreen

---

| Option | Description | Selected |
|--------|-------------|----------|
| Visuais distintos, mesmo resultado | QR mostra LucideIcons.qrCode; Foto mostra LucideIcons.camera. Ambos → 2s loading. | ✓ |
| Idênticos | Mesmos ícones, mais simples. | |
| Você decide | Claude escolhe. | |

**User's choice:** Visuais distintos, mesmo resultado

---

| Option | Description | Selected |
|--------|-------------|----------|
| Overlay com blur + CircularProgressIndicator | Mesmo padrão da ShoppingListScreen. | ✓ |
| Substituir conteúdo da tela por fullscreen loading | Tela inteira vira loading. Mais simples. | |

**User's choice:** Overlay com blur

---

| Option | Description | Selected |
|--------|-------------|----------|
| Botão 'Ir para Home' + context.go('/home') | Limpa stack, vai para tab Home. | |
| Botão 'Ir para Home' + volta para tab Scanner resetada | Permanece na tab Scanner, reseta PageView para etapa 1. | ✓ |

**User's choice:** Volta para tab Scanner resetada

---

## Animação de Confete

| Option | Description | Selected |
|--------|-------------|----------|
| Package confetti: ^0.7.0 | 10 linhas de código, visual profissional, 1 dep extra. | ✓ |
| Animação manual com CustomPainter | Zero dep, ~100 linhas de física de partículas. | |
| Simples — sem confete | Só anima '+10 moedas'. | |

**User's choice:** Package confetti: ^0.7.0
**Notes:** Usuário pediu explicação do que é o package confetti antes de decidir. Após explicação (ConfettiWidget + ConfettiController API), escolheu o package.

---

| Option | Description | Selected |
|--------|-------------|----------|
| Automaticamente ao entrar na etapa 3 | initState dispara _controller.play(). | ✓ |
| Após animação de entrada da tela | Delay 300ms para não sobrepor animações. | |

**User's choice:** Automaticamente ao entrar na etapa 3

---

## Dados do Veículo no Perfil

| Option | Description | Selected |
|--------|-------------|----------|
| Estender User com vehicleModel + fuelEfficiency | UserNotifier já persiste. Zero boilerplate extra. | ✓ |
| VehicleNotifier separado | Novo provider, chave própria. Mais verboso. | |
| Você decide | Claude escolhe. | |

**User's choice:** Estender User com vehicleModel + fuelEfficiency

---

| Option | Description | Selected |
|--------|-------------|----------|
| SnackBar 'Perfil atualizado!' | Consistente com StoreScreen. | ✓ |
| Sem feedback | Salva silenciosamente. | |

**User's choice:** SnackBar 'Perfil atualizado!'

---

| Option | Description | Selected |
|--------|-------------|----------|
| Tela normal na tab 4 | ProfileScreen já na tab 4. Badge → context.go('/profile'). | ✓ |
| Modal fullscreen via context.push | Badge abre modal, tab abre normal. | |

**User's choice:** Tela normal na tab 4

---

## Conteúdo da Nota Mock (Etapa 2)

| Option | Description | Selected |
|--------|-------------|----------|
| Nota fixa — sempre o mesmo receipt | Bistek, hoje, R$87,43, 3-4 itens fixos. Zero lógica. | ✓ |
| Nota aleatória entre os 4 supermercados | Sorteia supermercado e itens. Mais dinâmico. | |
| Você decide | Claude escolhe. | |

**User's choice:** Nota fixa

---

| Option | Description | Selected |
|--------|-------------|----------|
| Totalmente fixas / mockadas | '47 buscas', '12 notas', 'R$342 economia'. | |
| Parcialmente derivadas | Notas = contagem real de transações coinProvider; outros fixos. | ✓ |

**User's choice:** Parcialmente derivadas — notas escaneadas derivadas de `coinProvider.transactions` onde `description == 'Cadastro de nota fiscal'`; demais stats fixas.

---

## Claude's Discretion

- Layout interno do ProfileScreen (scroll vs. SliverAppBar)
- Organização visual dos campos de edição (seções separadas por Card vs. lista contínua)
- Ícone representativo de cada stat de impacto

## Deferred Ideas

None — discussion stayed within phase scope.
