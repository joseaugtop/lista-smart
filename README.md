# Lista Smart

Aplicativo Flutter para Android e iOS que combina lista de compras inteligente com comparação de preços entre supermercados e rastreamento de economia em combustível.

Projeto acadêmico — Desenvolvimento Mobile, Unesc Fase 5.

## O que faz

- **Lista de compras** — adiciona, remove e organiza itens
- **Comparação de preços** — mostra qual supermercado tem o menor preço final incluindo custo de deslocamento por combustível
- **Smart Coins** — sistema de gamificação que recompensa usuários que cadastram notas fiscais com moedas virtuais
- **Perfil** — cadastro de veículo para cálculo de custo de combustível

Todos os dados são locais/mockados — sem backend, sem rede.

## Stack

| Pacote | Versão | Uso |
|--------|--------|-----|
| Flutter | 3.x | Framework |
| flutter_riverpod | ^2.5.1 | Gerenciamento de estado |
| go_router | ^14.0.0 | Navegação declarativa |
| shared_preferences | ^2.2.0 | Persistência local |
| lucide_icons | ^0.257.0 | Ícones |
| google_fonts | ^6.1.0 | Tipografia (Inter/Poppins) |

## Estrutura

```
lib/
├── core/
│   ├── constants/     # cores, tamanhos
│   ├── persistence/   # SharedPreferences provider
│   └── theme/         # AppTheme, AppTextTheme
├── features/
│   ├── auth/          # login + domínio de usuário
│   ├── home/          # tela inicial
│   ├── price_comparison/   # comparação entre mercados
│   ├── price_registration/ # cadastro de preços/NF
│   ├── profile/       # perfil + veículo
│   ├── shopping_list/ # lista de compras
│   └── smart_coins/   # loja de recompensas
├── routing/           # GoRouter + RouterNotifier
├── app.dart           # ProviderScope + MaterialApp.router
└── main.dart          # inicialização SharedPreferences
```

## Como rodar

### Pré-requisitos

- Flutter 3.x instalado em path **sem espaços** (ex: `C:\flutter`)
- Android Studio com Android SDK instalado
- Dispositivo Android com depuração USB ativada **ou** emulador configurado

> **Windows:** se seu Flutter está em `C:\Users\Nome Sobrenome\flutter`, o build vai falhar por causa dos espaços no path. Mova para `C:\flutter`.

### Passos

```powershell
# 1. Abre PowerShell e configura o ambiente
$env:PUB_CACHE = "C:\pub-cache"          # evita erros de path com espaços
$env:PATH = "C:\flutter\bin;" + $env:PATH

# 2. Entra no projeto
cd "caminho\para\lista_smart"

# 3. Baixa dependências
flutter pub get

# 4. Roda no dispositivo conectado
flutter run
```

### Depuração USB (Android)

1. Configurações → Sobre o telefone → toque 7x em **Número da versão**
2. Configurações → Opções do desenvolvedor → **Depuração USB** → Ligar
3. Conecta o cabo USB e aceita a permissão no celular
4. `flutter devices` deve listar o dispositivo
5. `flutter run`

### Emulador

```powershell
flutter emulators                        # lista emuladores disponíveis
flutter emulators --launch <id>          # inicia o emulador
flutter run                              # roda após emulador abrir
```
