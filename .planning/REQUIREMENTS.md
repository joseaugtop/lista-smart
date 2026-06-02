# Requirements: Lista Smart

**Defined:** 2026-05-25
**Core Value:** Ajudar usuários a fazer compras mais baratas mostrando qual supermercado tem o menor preço final, incluindo o custo de deslocamento por combustível.

## v1 Requirements

### Foundation

- [x] **FOUN-01**: App Flutter compila e roda no Android e iOS sem erros (pubspec correto com lucide_icons: ^0.257.0)
- [x] **FOUN-02**: Design system dark glassmórfico implementado: cores (#09090B background, #A3E615 primary, #18181B surface), typography google_fonts Inter, tema escuro sem clash de ColorScheme
- [x] **FOUN-03**: Navegação com 5 abas via StatefulShellRoute.indexedStack preserva estado de scroll entre trocas de aba
- [x] **FOUN-04**: Modelos de dados tipados implementados: User, Vehicle, Product, CartItem, CoinTransaction com toJson/fromJson
- [x] **FOUN-05**: Persistência local via shared_preferences inicializada antes de runApp() e injetada via ProviderScope.overrides

### Authentication

- [ ] **AUTH-01**: Usuário vê tela de login com campos email/senha estilizados (ícones Lucide, círculos desfocados de fundo)
- [ ] **AUTH-02**: Ao pressionar "Avançar", estado global de user é preenchido instantaneamente com dados de José Augusto e app navega para Home
- [ ] **AUTH-03**: RouterNotifier redireciona para /login automaticamente se user for null

### Home

- [ ] **HOME-01**: Usuário pode alternar exibição de produtos entre grid e lista com um controle toggleável
- [ ] **HOME-02**: Usuário pode buscar produtos pelo nome com filtro reativo no header
- [ ] **HOME-03**: Cards de produto exibem imagem, marca, nome, tag e preço médio
- [ ] **HOME-04**: Usuário pode favoritar/desfavoritar produto com botão estrela que muda de cor dinamicamente
- [ ] **HOME-05**: FAB no canto inferior direito navega para fluxo de Cadastro de Preço
- [ ] **HOME-06**: Badge com iniciais do usuário no header navega para tela de Perfil
- [ ] **HOME-07**: Em mobile, toque no card navega para tela de detalhes/comparação; em tablet, abre split view lateral

### Shopping List

- [ ] **SHOP-01**: Usuário pode ver todos os itens adicionados ao carrinho com nome, marca e imagem
- [ ] **SHOP-02**: Usuário pode aumentar ou diminuir quantidade de cada item com controle +/- inline
- [ ] **SHOP-03**: Usuário pode remover item do carrinho individualmente (swipe-to-delete ou ícone lixeira)
- [ ] **SHOP-04**: Usuário pode ativar switch "Considerar Custo de Deslocamento" que calcula custo de combustível usando eficiência do veículo do usuário
- [ ] **SHOP-05**: Usuário pode limpar o carrinho inteiro com botão que exige confirmação via dialog do sistema

### Price Comparison

- [ ] **COMP-01**: Usuário vê preços do produto buscado em pelo menos 3 supermercados (Bistek, Giassi, Angeloni) com dados mockados
- [ ] **COMP-02**: Estabelecimento com menor preço final é visualmente destacado como vencedor
- [ ] **COMP-03**: Cada linha de comparação exibe: preço do produto + distância em km + custo de combustível = preço total

### Smart Coins

- [ ] **COIN-01**: Usuário vê saldo atual de moedas com indicador visual de nível (Bronze/Prata/Ouro)
- [ ] **COIN-02**: Barra de progresso animada (TweenAnimationBuilder) indica quanto falta para próximo nível
- [ ] **COIN-03**: Usuário vê 3 pacotes de moedas demonstrativos (100, 500, 1000 moedas) em grid com bônus indicados
- [ ] **COIN-04**: Usuário vê histórico de transações de moedas com ícones coloridos (verde = ganho, vermelho = resgate)

### Price Registration

- [ ] **PREG-01**: Etapa 1 — Usuário escolhe entre "Escanear QR Code" ou "Foto do Cupom", ambos simulam processamento com progress indicator por 2 segundos
- [ ] **PREG-02**: Etapa 2 — Usuário vê dados mockados de nota fiscal (supermercado, data, valor total, itens) e confirma com botão "Confirmar e Ganhar Moedas"
- [ ] **PREG-03**: Etapa 3 — Tela de celebração exibe animação de confete, mostra +10 moedas adicionadas ao saldo e botão para retornar à Home
- [ ] **PREG-04**: Ao confirmar (etapa 2), saldo de moedas do usuário é incrementado em +10 e transação é registrada no histórico

### Profile

- [ ] **PROF-01**: Usuário pode visualizar e editar nome, email e endereço
- [ ] **PROF-02**: Usuário pode editar modelo do veículo e consumo médio (km/L) com campos integrados ao botão "Salvar Alterações"
- [ ] **PROF-03**: Tela de Perfil exibe estatísticas de impacto social mockadas: buscas efetuadas, notas escaneadas, valor estimado de economia

## v2 Requirements

### Smart Coins Extras

- **COIN-V2-01**: Resgate de dinheiro real (PIX mock) — deduz saldo e registra transação com valor monetário
- **COIN-V2-02**: Pacotes de moedas com fluxo de compra simulado (diálogo de confirmação + transação)

### Authentication Extras

- **AUTH-V2-01**: Guard de rota com auth redirect via RouterNotifier (já existe em v1 mas com mock — v2 seria com sessão persistida real)

### Social

- **SOCL-V2-01**: Compartilhamento de lista de compras via link
- **SOCL-V2-02**: Leaderboard de colaboradores com mais notas escaneadas

## Out of Scope

| Feature | Reason |
|---------|--------|
| Backend real / API REST | Projeto acadêmico fully local/mocked por escolha |
| Câmera real (QR/foto) | Plataforma-específico, dias de integração, mock entrega 100% do valor de demo |
| Geolocalização real (GPS) | Distâncias hardcoded em constants — suficiente para simulação |
| Push notifications | Fora do escopo da disciplina |
| Autenticação OAuth / Firebase | Login simulado é suficiente para projeto acadêmico |
| Dark mode toggle | Dark mode fixo — requisito do design system não negociável |
| Onboarding carousel | Adiciona complexidade sem valor avaliativo |
| Pagamentos reais | Pacotes são demonstrativos — sem integração de pagamento |
| lucide_icons: ^3.0.0 | Versão inexistente no pub.dev — usar ^0.257.0 (blocker crítico) |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| FOUN-01 | Phase 1 — Foundation | Complete |
| FOUN-02 | Phase 1 — Foundation | Complete |
| FOUN-03 | Phase 1 — Foundation | Complete |
| FOUN-04 | Phase 1 — Foundation | Complete |
| FOUN-05 | Phase 1 — Foundation | Complete |
| AUTH-01 | Phase 2 — Auth + State Layer | Pending |
| AUTH-02 | Phase 2 — Auth + State Layer | Pending |
| AUTH-03 | Phase 2 — Auth + State Layer | Pending |
| HOME-01 | Phase 3 — Core Shopping Loop | Pending |
| HOME-02 | Phase 3 — Core Shopping Loop | Pending |
| HOME-03 | Phase 3 — Core Shopping Loop | Pending |
| HOME-04 | Phase 3 — Core Shopping Loop | Pending |
| HOME-05 | Phase 3 — Core Shopping Loop | Pending |
| HOME-06 | Phase 3 — Core Shopping Loop | Pending |
| HOME-07 | Phase 3 — Core Shopping Loop | Pending |
| SHOP-01 | Phase 3 — Core Shopping Loop | Pending |
| SHOP-02 | Phase 3 — Core Shopping Loop | Pending |
| SHOP-03 | Phase 3 — Core Shopping Loop | Pending |
| SHOP-04 | Phase 3 — Core Shopping Loop | Pending |
| SHOP-05 | Phase 3 — Core Shopping Loop | Pending |
| COMP-01 | Phase 3 — Core Shopping Loop | Pending |
| COMP-02 | Phase 3 — Core Shopping Loop | Pending |
| COMP-03 | Phase 3 — Core Shopping Loop | Pending |
| COIN-01 | Phase 4 — Smart Coins | Pending |
| COIN-02 | Phase 4 — Smart Coins | Pending |
| COIN-03 | Phase 4 — Smart Coins | Pending |
| COIN-04 | Phase 4 — Smart Coins | Pending |
| PREG-01 | Phase 5 — Price Registration + Profile | Pending |
| PREG-02 | Phase 5 — Price Registration + Profile | Pending |
| PREG-03 | Phase 5 — Price Registration + Profile | Pending |
| PREG-04 | Phase 5 — Price Registration + Profile | Pending |
| PROF-01 | Phase 5 — Price Registration + Profile | Pending |
| PROF-02 | Phase 5 — Price Registration + Profile | Pending |
| PROF-03 | Phase 5 — Price Registration + Profile | Pending |

**Coverage:**

- v1 requirements: 34 total
- Mapped to phases: 34
- Unmapped: 0 ✓

---
*Requirements defined: 2026-05-25*
*Last updated: 2026-05-25 — traceability updated with phase names after ROADMAP.md created*
