# Lista Smart

## What This Is

Lista Smart é um aplicativo Flutter para Android e iOS que combina lista de compras inteligente com comparação de preços entre supermercados e rastreamento de economia em combustível. O app usa um sistema de gamificação com "Smart Coins" para recompensar usuários que cadastram notas fiscais, incentivando a contribuição de dados de preços. É um projeto acadêmico de Desenvolvimento Mobile (Unesc, Fase 5) com foco em demonstrar arquitetura limpa, design system sofisticado e fluência nativa Flutter.

## Core Value

Ajudar usuários a fazer compras mais baratas mostrando qual supermercado tem o menor preço final, incluindo o custo de deslocamento por combustível.

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] App Flutter nativo Android/iOS com dark mode luxuoso (glassmorphic)
- [ ] Tela de Login com autenticação local simulada (dados mock de José Augusto)
- [ ] Home Dashboard com grid/list switchável de produtos, busca e FAB
- [ ] Cards de produto com favoritos, preço médio e navegação adaptativa (mobile vs tablet)
- [ ] Tela de Lista de Compras com controle de quantidade, custo de deslocamento e limpeza com confirmação
- [ ] Tela de Comparação de Preços entre supermercados (Bistek, Giassi, Angeloni) com custo de combustível somado
- [ ] Loja Smart Coins com saldo, barra de progresso de nível, pacotes de moedas e histórico de transações
- [ ] Fluxo de Cadastro de Preço em 3 etapas (scan/foto → confirmação de dados mock → celebração com confete + +10 moedas)
- [ ] Tela de Perfil com edição de dados, configuração de veículo e estatísticas de impacto social
- [ ] Gerenciamento de estado global via Riverpod (user, cart, favorites, coinTransactions)
- [ ] Persistência local com shared_preferences (carrinho, favoritos, sessão)
- [ ] Roteamento declarativo com go_router com transições fluidas

### Out of Scope

- Backend real / API REST — projeto é fully local/mocked por escolha acadêmica
- Pagamentos reais de moedas — pacotes são demonstrativos
- Câmera real para scan de QR/foto — substituída por simulação com progress indicator
- Geolocalização real — distâncias são fictícias/simuladas
- Push notifications — fora do escopo académico
- Autenticação OAuth / Firebase — login é simulado instantaneamente

## Context

- Projeto acadêmico: Unesc, curso de Desenvolvimento Mobile, 5ª fase
- Desenvolvedor: José Augusto Pereira da Rocha
- Plataforma alvo: Android & iOS (Flutter)
- Todos os dados são mocks — nenhuma chamada de rede real é necessária
- O app usa o usuário "José Augusto" como dados default de login simulado
- Design system definido: dark carbono (#09090B), primary verde-limão (#A3E615), surface cards (#18181B)
- Stack definido pelo enunciado da disciplina — não negociável

## Constraints

- **Tech Stack**: Flutter + Riverpod + go_router + shared_preferences — definido pelo enunciado
- **Dados**: Totalmente local/mocked — sem backend, sem rede
- **Ícones**: lucide_icons obrigatório
- **Fontes**: google_fonts obrigatório
- **Plataformas**: Android & iOS nativos apenas (sem web/desktop)
- **Versões**: flutter_riverpod ^2.5.1, go_router ^14.0.0

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Riverpod para state management | Definido pelo enunciado; clean, testável, sem boilerplate excessivo | — Pending |
| go_router para navegação | Declarativo, suporta deep linking e transições customizadas | — Pending |
| shared_preferences para persistência | Suficiente para dados simples sem banco relacional | — Pending |
| Dados totalmente mockados | Projeto acadêmico — foco está em UI/UX e arquitetura, não em infra | — Pending |
| Design system dark glassmórfico | Diferenciação visual para avaliação acadêmica | — Pending |
| Gamificação com Smart Coins | Demonstra feature complexa com estado transacional | — Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-05-25 after initialization*
