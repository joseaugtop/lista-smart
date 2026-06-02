# Phase 2: Auth + State Layer - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-02
**Phase:** 02-auth-state-layer
**Areas discussed:** Login screen visual, Comportamento do login, Estrutura dos dados mock

---

## Login Screen Visual

| Option | Description | Selected |
|--------|-------------|----------|
| Blobs coloridos com blur | BackdropFilter blur, 2-3 círculos grandes, card glassmorphic | ✓ |
| Fundo sólido + círculos sutis | Sem blur real, mais simples | |
| Sem card — campos soltos | Clean mas menos impactante | |

**Campo senha toggle:** Sim — LucideIcons.eye / eyeOff ✓

**Logo:** Nome "Lista Smart" + subtítulo no topo ✓

**Notes:** Visual premium condizente com design system dark glassmorphic. Blobs verde-limão no topo-direito e inferior-esquerdo.

---

## Comportamento do Login

| Option | Description | Selected |
|--------|-------------|----------|
| Valida campos não-vazios | Erro inline se campos vazios | |
| Aceita qualquer entrada | Qualquer toque em "Avançar" loga | ✓ |

**Transição:** Breve loading state ~500ms antes de navegar ✓ (não instantâneo)

**Botão:** FilledButton largura total, background #A3E615, texto escuro ✓

**Notes:** Auth 100% simulado — sem validação. Loading state de 500ms dá sensação de "real" para avaliação acadêmica.

---

## Estrutura dos Dados Mock

| Option | Description | Selected |
|--------|-------------|----------|
| Um arquivo central mock_data.dart | Todos dados em um lugar | ✓ |
| Por feature: mock_xxx.dart | Isolado por feature | |

**Quantidade produtos:** 10-15 produtos ✓

**Saldo inicial José Augusto:** 750 moedas (nível Prata) ✓

**Categorias:** Laticínios, Frutas e verduras, Limpeza e higiene, Padaria e granel ✓ (todas 4)

**Supermercados:** 4 — Bistek, Giassi, Angeloni + Atacadão (usuário optou por adicionar 4º)

---

## Claude's Discretion

- Estrutura interna do UserNotifier (User? vs AsyncValue<User>)
- Nomes das chaves SharedPreferences
- Ordem dos campos no formulário

## Deferred Ideas

- **Toggle de tema claro/escuro na aba de Perfil** — Phase 5. Dark permanece padrão; usuário quer opção de alternar via ThemeMode persistido no SharedPreferences.
