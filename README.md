<p align="center">
  <img src="lib/assets/icon/logo.png" alt="Oinc Logo 3D" width="140"/>
</p>

<h1 align="center">🐷 Oinc — Meu cofrinho virtual</h1>

<p align="center">
  <strong>Transforme o hábito de poupar dinheiro em um jogo leve, gostoso e visual em Soft 3D — 100% offline e sem culpa!</strong>
</p>

<p align="center">
  <img alt="Flutter" src="https://img.shields.io/badge/Flutter-3.x-02569B?style=flat-square&logo=flutter&logoColor=white"/>
  <img alt="Dart" src="https://img.shields.io/badge/Dart-3.x-0175C2?style=flat-square&logo=dart&logoColor=white"/>
  <img alt="Hive" src="https://img.shields.io/badge/Hive-2.2.3-FFCA28?style=flat-square"/>
  <img alt="Riverpod" src="https://img.shields.io/badge/Riverpod-2.5.1-00BCD4?style=flat-square"/>
  <img alt="Design" src="https://img.shields.io/badge/Estilo-Soft%203D%20Claymorphism-FF8DA1?style=flat-square"/>
  <img alt="Offline" src="https://img.shields.io/badge/Modo-100%25%20Offline-success?style=flat-square"/>
  <img alt="Zero Anúncios" src="https://img.shields.io/badge/Anúncios-Zero-blueviolet?style=flat-square"/>
  <img alt="Licença" src="https://img.shields.io/badge/Licen%C3%A7a-MIT-green?style=flat-square"/>
</p>

<p align="center">
  📖 <strong><a href="APP-OVERVIEW.md">Clique aqui para ver o Guia Completo do Produto & ASO (APP-OVERVIEW.md)</a></strong>
</p>

---

## 👋 E aí! Boas-vindas ao Oinc!

Seja muito bem-vindo(a) ao repositório do **Oinc**! 

Sabe aquela sensação chata de tentar juntar dinheiro usando uma planilha fria ou um app bancário cheio de gráficos complicados, cobranças e notificações ansiosas? Pois é... eu também cansei disso.

Eu criei o **Oinc** para transformar a economia financeira em algo que dê **vontade de abrir todos os dias**: uma experiência visual encantadora com visual **Soft 3D (Claymorphism)**, um mascote carismático chamado **Porko** que reage aos seus hábitos, e um sistema de recompensas lúdico onde **você cuida do seu dinheiro na vida real enquanto cuida do seu cofrinho virtual no app**.

Tudo isso com um compromisso inegociável: **privacidade total**. O app é **100% offline-first**. Nada de login, nada de vincular conta bancária, nada de anúncios chatos e zero dados enviados para a nuvem. O dinheiro é seu, a privacidade é sua e o controle está na sua mão.

---

## 🎮 A Filosofia do Oinc: Poupar Sem Culpa

A maioria dos apps de finanças falha porque foca apenas na restrição e na culpa (*"você gastou demais!", "meta atrasada!"*). O Oinc parte de uma abordagem psicológica diferente:

- 🪙 **Duplo Loop de Recompensa:** Guardar dinheiro no mundo real gera recompensa imediata no jogo. Cada depósito registrado rende confetes a 60fps, alegra o mascote e te dá **Oinc Coins (`🪙`)** para usar na lojinha.
- 🐷 **Gamificação Anti-Culpa:** O Porko nunca "morre" nem fica triste de forma punitiva. Ele tem um piso de felicidade e energia de **40%**, garantindo que o app seja sempre um abraço acolhedor quando você voltar.
- 🌱 **No Seu Ritmo:** Tem metas com data marcada (ex: viagem de férias)? O app calcula as parcelas. Quer só guardar sem pressão (ex: reserva de emergência)? O modo **"No meu ritmo"** te deixa livre de cobranças de prazos.

---

## ✨ Um Passeio Pelas Funcionalidades

### 🏞️ 1. O Habitat Vivo & O Mascote Porko em Soft 3D
- **Claymorphism Procedural de 9 Camadas:** O [`PorkoCanvasWidget`](lib/widgets/porko_canvas_widget.dart) desenha o Porko puramente em código Flutter, com iluminação suave, reflexos táteis, bochechas coradas, respiração contínua e piscar de olhos natural.
- **Cenário Dinâmico Dia & Noite:** O [`HabitatHeaderWidget`](lib/widgets/habitat_header_widget.dart) muda de acordo com o tema. De dia temos sol e colinas ensolaradas; de noite, lua, estrelas cintilantes e uma caminha aconchegante para o Porko descansar.
- **Colapso Suave no Scroll (`340px -> 116px`):** O cabeçalho encolhe com transição suave conforme você navega pelas metas, mantendo o resumo de moedas e nível sempre acessível.

### 🎯 2. Criando Metas em 3 Passos
Nada de formulários gigantes! A criação é guiada pelo [`GoalFormScreen`](lib/features/goal_form/goal_form_screen.dart):
1. **Passo 1 — O Sonho:** Dê um nome, escolha um dos 8 ícones representativos, uma das 6 cores vibrantes, o valor-alvo e o prazo (com atalhos rápidos ou o botão **Sem prazo — vou guardando no meu ritmo**).
2. **Passo 2 — O Plano:** O app calcula na hora quanto guardar por **dia**, **semana** ou **mês**, ou trava automaticamente no ritmo livre caso você não tenha prazo fixo.
3. **Passo 3 — Com o Porko:** O mascote aparece na tela para revisar tudo com você antes de confirmar.

### ☰ 3. Minhas Metas & Filtro Sanduíche
- **Cards Táteis:** Cada meta no [`GoalCard`](lib/widgets/goal_card.dart) mostra o progresso visual, dias restantes, ritmo sugerido e o botão direto **`💰 Depositar ›`**.
- **Menu Sanduíche Esperto:** No topo da [`HomeScreen`](lib/features/home/home_screen.dart), toque no ícone `☰` para filtrar por status (*Todas*, *No ritmo*, *Atrasadas*, *Concluídas*, *Sem prazo*) e ordenar por *Mais recentes*, *Prazo* ou *Maior progresso*.

### 📊 4. Detalhe da Meta em 3 Abas & Depósito Rápido
Ao abrir uma meta no [`GoalDetailScreen`](lib/features/goal_detail/goal_detail_screen.dart), você tem:
- **Aba Jornada:** Uma trilha de marcos em **25%, 50%, 75% e 100%** com recompensas crescentes em Oinc Coins e mensagens carinhosas do Porko.
- **Aba Histórico:** Extrato transparente dos depósitos, permitindo excluir lançamentos com **estorno atômico de moedas**.
- **Aba Evolução:** Gráfico de barras interativo mês a mês e resumo de projeção.
- **Depósitos Fáceis ([`DepositScreen`](lib/features/deposit/deposit_screen.dart)):** Botão de valor sugerido pelo seu ritmo, atalhos rápidos (`+R$ 10`, `+R$ 25`, `+R$ 50`, `+R$ 100`, `+R$ 200`) e seletor horizontal para trocar de meta sem voltar à tela inicial.

### 🐾 5. Cantinho do Mascote & Lojinha
- **Cuidado Diário ([`MascotScreen`](lib/features/mascot/mascot_screen.dart)):** Grid 2x2 com ações táteis (*Fazer carinho*, *Alimentar*, *Brincar* e *Chamar*) com limites diários salvos no banco.
- **Porko Store ([`PorkoStoreScreen`](lib/features/shop/porko_store_screen.dart)):** 16 itens cosméticos (peles temáticas como o *Porko de Ouro*, chapéus, gravatas, óculos e cenários como *Arco-íris* e *Plantinhas*) que você experimenta ao vivo no mini-palco 3D antes de comprar com suas Oinc Coins conquistadas.

### ⚙️ 6. Perfil, Acessibilidade & Privacidade
No [`ProfileSettingsModal`](lib/features/profile/profile_settings_modal.dart), você encontra 7 seções completas:
- **Identidade:** Troque seu nome e escolha entre 8 avatares animados.
- **Acessibilidade:** Suporte a **Reduzir Animações e Movimento** (WCAG 2.1) e alternância do tema Claro/Escuro.
- **Modo Privacidade:** Oculte seus saldos com um toque (`R$ •••••`).
- **Backup Local:** Exporte e copie todo o seu histórico em formato **JSON** direto para a área de transferência.

---

## 🛠️ Tecnologias Utilizadas

Escolhi tecnologias modernas, estáveis e pensadas para máxima performance offline:

| Tecnologia | O que faz no projeto? |
| :--- | :--- |
| **[Flutter 3.x](https://flutter.dev)** | Framework multiplataforma de alta fidelidade visual (Android, iOS e Web). |
| **[Dart ≥ 3.0](https://dart.dev)** | Linguagem tipada, moderna e segura com suporte a pattern matching e records. |
| **[Flutter Riverpod 2.5](https://riverpod.dev)** | Gerenciamento de estado reativo, testável e sem boilerplate desnecessário. |
| **[Hive NoSQL 2.2](https://pub.dev/packages/hive)** | Banco de dados local ultra-rápido, leve e 100% offline-first. |
| **[fl_chart](https://pub.dev/packages/fl_chart)** | Gráficos fluidos para visualização de depósitos e evolução financeira. |
| **[flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications)** | Notificações e lembretes locais agendados no próprio celular, sem backend. |
| **[intl](https://pub.dev/packages/intl)** | Formatação de moeda no padrão brasileiro (`pt_BR` / R$) e datas. |

---

## 📁 Estrutura do Projeto

Organizei o código seguindo os princípios de **Clean Architecture** com modularização **Feature-First**:

```text
lib/
├── app/
│   └── app.dart                           # MaterialApp, rotas e tema do aplicativo
├── assets/
│   └── icon/logo.png                      # Ícone oficial 3D do mascote Porko (1024x1024)
├── core/
│   ├── providers/                         # Providers globais (Riverpod) e controle de tema
│   ├── theme/                             # Cores, gradientes, tipografia (Poppins/Quicksand)
│   └── utils/                             # Formatação BRL, calculadora de ritmo e notificações
├── data/
│   ├── models/                            # Modelos de dados com TypeAdapters do Hive
│   └── repositories/                      # Repositórios locais (Metas, Depósitos, Mascote, Loja)
├── domain/
│   └── usecases/                          # Regras de negócio puras (RegisterDeposit, EvaluateBadges)
├── features/
│   ├── deposit/                           # Tela de depósitos e atalhos rápidos
│   ├── gamification/                      # Galeria de conquistas colecionáveis
│   ├── goal_detail/                       # Detalhes da meta em 3 abas (Jornada, Histórico, Evolução)
│   ├── goal_form/                         # Wizard de criação de metas em 3 passos
│   ├── home/                              # Dashboard com resumo, metas e menu sanduíche
│   ├── mascot/                            # Cantinho do Mascote (afeto diário e bem-estar)
│   ├── onboarding/                        # Telas de boas-vindas do Oinc
│   ├── profile/                           # Modal de ajustes (7 seções e backup JSON)
│   ├── shop/                              # Lojinha de cosméticos e cenários com preview 3D
│   └── splash/                            # Abertura animada com identidade visual do Oinc
├── widgets/
│   ├── celebration_overlay.dart           # Chuva de confetes a 60fps
│   ├── custom_docked_bottom_bar.dart      # Barra inferior de 4 abas com botão (+) projetado
│   ├── economy_suggestions_card.dart      # Seletor inteligente de ritmo financeiro
│   ├── goal_card.dart                     # Card de meta Soft 3D com atalho de depósito
│   ├── habitat_header_widget.dart         # Cabeçalho vivo com cenário e colapso no scroll
│   ├── milestone_map_card.dart            # Trilha visual de checkpoints (25% a 100%)
│   └── porko_canvas_widget.dart           # Renderizador volumétrico Soft 3D do Porko
└── main.dart                              # Bootstrap do Hive e inicialização do Flutter
```

---

## 🚀 Como Rodar o Projeto

### Pré-requisitos
- **Flutter SDK** instalado (versão `≥ 3.0.0`)
- **Git** configurado
- Um emulador (Android/iOS) ou o navegador Chrome/Edge

### Passo a Passo

```bash
# 1. Clone o repositório
git clone https://github.com/mateusnriy/cofrinho-gamificado.git
cd cofrinho-gamificado

# 2. Baixe as dependências
flutter pub get

# 3. (Opcional) Regere os adaptadores do Hive se fizer alterações nos modelos
dart run build_runner build --delete-conflicting-outputs

# 4. Inicie o aplicativo
flutter run
```

### 🌐 Build para Web
Para gerar o build de produção para a Web preservando todos os ícones das metas:

```bash
flutter build web --no-tree-shake-icons
```

---

## 🧪 Qualidade & Testes

A estabilidade do app é garantida por **19 suítes de testes automatizados**, cobrindo regras de negócio, persistência no Hive, acessibilidade e testes de integração de ponta a ponta (E2E):

```bash
# Verificar qualidade do código e lint (zero erros e zero warnings!)
dart analyze

# Rodar todos os testes automatizados
flutter test
```

---

## 🌿 Versionamento & Git Flow

O repositório segue estritamente o modelo **Git Flow** e a convenção de **Commits Semânticos**:
- `main`: Branch de produção estável;
- `develop`: Branch de integração contínua;
- `feature/*` / `chore/*`: Branches de trabalho mescladas via merge sem fast-forward (`--no-ff`).

---

## 👨‍💻 Autor

Desenvolvido com carinho e dedicação por:

**Mateus Neri**  
- GitHub: [@mateusnriy](https://github.com/mateusnriy)  
- Projeto: [cofrinho-gamificado](https://github.com/mateusnriy/cofrinho-gamificado)

---

## 📄 Licença

Este projeto é de código aberto sob a licença [MIT](LICENSE). Sinta-se à vontade para clonar, estudar, sugerir melhorias ou usar como inspiração para os seus próprios projetos! 🐷✨
