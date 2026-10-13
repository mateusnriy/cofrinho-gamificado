<p align="center">
  <img src="lib/assets/icon/logo.png" alt="Oinc Logo" width="130"/>
</p>

<h1 align="center">🐷 Oinc — Meu cofrinho virtual</h1>

<p align="center">
  <strong>Transforme o hábito de poupar dinheiro em uma jornada divertida, visual em Soft 3D e 100% offline.</strong>
</p>

<p align="center">
  <img alt="Flutter" src="https://img.shields.io/badge/Flutter-3.x-02569B?style=flat-square&logo=flutter&logoColor=white"/>
  <img alt="Dart" src="https://img.shields.io/badge/Dart-3.x-0175C2?style=flat-square&logo=dart&logoColor=white"/>
  <img alt="Hive" src="https://img.shields.io/badge/Hive-2.2.3-FFCA28?style=flat-square"/>
  <img alt="Riverpod" src="https://img.shields.io/badge/Riverpod-2.5.1-00BCD4?style=flat-square"/>
  <img alt="Design" src="https://img.shields.io/badge/Design-Soft%203D%20Claymorphism-FF8DA1?style=flat-square"/>
  <img alt="Offline-First" src="https://img.shields.io/badge/Modo-100%25%20Offline-success?style=flat-square"/>
  <img alt="Sem Anúncios" src="https://img.shields.io/badge/Anúncios-Zero-blueviolet?style=flat-square"/>
  <img alt="License" src="https://img.shields.io/badge/licença-MIT-green?style=flat-square"/>
</p>

<p align="center">
  📖 <strong><a href="APP-OVERVIEW.md">Leia o Guia Oficial do Produto e Publicação (APP-OVERVIEW.md)</a></strong>
</p>

---

## 📋 Sobre o Projeto

O **Oinc — Meu cofrinho virtual** é um aplicativo multiplataforma (**Android, iOS e Web**) gratuito e **100% offline-first**, focado em educação financeira prática e gamificação comportamental acolhedora (*anti-culpa*). Desenvolvido em **Flutter** com estética **Soft 3D (Claymorphism)**, o aplicativo combate a procrastinação financeira criando um **duplo loop de recompensa**: você poupa dinheiro na vida real enquanto cuida, interage e personaliza o seu mascote **Porko** e o seu habitat natural.

A cada economia registrada, você ganha **Oinc Coins (`🪙`)** para desbloquear peles, chapéus, roupas e decorações de cenário na **Porko Store**, conquista insígnias colecionáveis, avança em trilhas de marcos (*milestones*) e mantém sequências diárias (*streaks* `🔥`).

Tudo isso com **privacidade absoluta**: sem logins, sem vínculo bancário, sem coleta de dados na nuvem e sem anúncios. Seus dados permanecem exclusivamente no seu dispositivo.

---

## 🎯 O Que o Oinc Resolve?

1. **Gratificação imediata ao poupar:** Guardar dinheiro deixa de parecer uma perda imediata e passa a gerar celebrações a 60fps com chuva de confetes, evolução do mascote e moedas virtuais.
2. **Planejamento financeiro descomplicado (Com ou Sem Prazo):** O aplicativo calcula automaticamente quanto guardar por **dia**, **semana** ou **mês** para atingir sua meta no prazo — ou permite poupar livremente na modalidade **🌱 No meu ritmo (Sem prazo)**.
3. **Gamificação acolhedora e anti-culpa:** O bem-estar do mascote Porko possui um piso protetor de `40%`, incentivando a consistência positiva sem punições frustrantes.
4. **Privacidade, Acessibilidade e Ergonomia Mobile:** Suporte a **Modo Privacidade** (ocultar valores em `R$`), **Redução de Animações e Movimento** (WCAG 2.1), alvos de toque $\ge 48\text{dp}$, responsividade de `320px` a telas largas e **Backup Local JSON**.

---

## ✨ Funcionalidades Principais

### 🏞️ Habitat Vivo & Mascote Porko em Soft 3D (Claymorphism)
- **Renderização Procedural de 9 Camadas:** O [`PorkoCanvasWidget`](lib/widgets/porko_canvas_widget.dart) desenha o mascote com esferas volumétricas, iluminação especular radial, sombra projetada no chão, respiração contínua, piscar natural e caminhada suave pelo cenário.
- **Habitat Colapsável (`340px -> 116px`):** O [`HabitatHeaderWidget`](lib/widgets/habitat_header_widget.dart) alterna entre **Céu Diurno** (sol e nuvens) e **Céu Noturno** (lua, estrelas cintilantes e caminha aconchegante), exibindo decorações de cenário equipadas (`🪴 Vasos`, `🎏 Bandeirinhas`, `🌈 Arco-íris`, `✨ Estrelas`) e encolhendo suavemente durante a rolagem.

### 🎯 Wizard de Metas em 3 Passos & Dashboard com Filtro Sanduíche (`☰`)
- **Criação Guiada em 3 Passos ([`GoalFormScreen`](lib/features/goal_form/goal_form_screen.dart)):**
  1. **Passo 1 — Seu Sonho:** Escolha entre 8 ícones, 6 cores vibrantes, valor-alvo e prazo (chips rápidos de `3m`, `6m`, `1 ano`, `2 anos`, calendário ou o botão **Sem prazo — vou guardando no meu ritmo**).
  2. **Passo 2 — Seu Plano:** Compare projeções em tempo real nos cards **Diário**, **Semanal**, **Mensal** ou **🌱 No meu ritmo**, e ative lembretes locais.
  3. **Passo 3 — Revisão com o Porko:** Confirme todos os detalhes da meta acompanhado pelo mascote Soft 3D.
- **Cards de Meta Táteis ([`GoalCard`](lib/widgets/goal_card.dart)):** Exibem ícone em caixa Soft 3D, barra de progresso, ritmo recomendado em destaque, prazo restante e botão direto **`💰 Depositar ›`**.
- **Filtro Tipo Menu Sanduíche (`☰`) ([`HomeScreen`](lib/features/home/home_screen.dart)):** Filtre suas metas por status (*Todas*, *No ritmo*, *Atrasadas*, *Concluídas*, *Sem prazo definido*) e ordene por *Mais recentes*, *Prazo mais próximo* ou *Maior progresso (%)*.

### 📊 Detalhe da Meta em 3 Abas & Depósitos Inteligentes
- **Tela de Detalhes ([`GoalDetailScreen`](lib/features/goal_detail/goal_detail_screen.dart)):**
  - **Cabeçalho Imersivo:** Valor acumulado, percentual e card translúcido com *Faltam*, *Status* e *Prazo*.
  - **Aba Jornada ([`MilestoneMapCard`](lib/widgets/milestone_map_card.dart)):** Checkpoints de `25%`, `50%`, `75%` e `100%` com recompensas de `+25` a `+150 🪙` e caixa de incentivo do Porko.
  - **Aba Histórico:** Lista completa de aportes com notas, datas e **exclusão com estorno atômico de Oinc Coins**.
  - **Aba Evolução:** Gráfico mensal interativo (`fl_chart`) e resumo completo do plano.
- **Tela de Depósito ([`DepositScreen`](lib/features/deposit/deposit_screen.dart)):**
  - Botão em destaque **⭐ Sugerido pelo seu ritmo**, chips rápidos (`+R$ 10`, `+R$ 25`, `+R$ 50`, `+R$ 100`, `+R$ 200`), seletor horizontal para alternar de meta sem sair da tela e suporte a registro *Hoje* ou *Ontem* (resgate de streak).

### 🐾 Cantinho do Mascote, Porko Store & Conquistas
- **Cantinho do Mascote ([`MascotScreen`](lib/features/mascot/mascot_screen.dart)):** Palco Soft 3D interativo, edição do nome do mascote, barras de *Felicidade* e *Energia* (com piso anti-culpa de `40%`) e **Grid 2x2 de Cuidados Diários** (*Fazer carinho*, *Alimentar*, *Brincar* e *Chamar*) com limites diários persistidos.
- **Lojinha do Porko ([`PorkoStoreScreen`](lib/features/shop/porko_store_screen.dart)):** 16 itens cosméticos em 4 categorias (*Peles*, *Chapéus*, *Roupas* e *Cenários*) com palco de experimentação ao vivo antes da compra.
- **Galeria de Conquistas ([`BadgesGalleryScreen`](lib/features/gamification/badges_gallery_screen.dart)):** 8 medalhas colecionáveis com barra de progresso e contadores de depósitos, streaks e metas concluídas.

### ⚙️ Perfil e Ajustes Expandido (7 Seções)
- **Modal Completo ([`ProfileSettingsModal`](lib/features/profile/profile_settings_modal.dart)):**
  1. **Perfil e Identidade:** Edição ao vivo de apelido e escolha entre 8 avatares;
  2. **Aparência e Acessibilidade:** Alternância entre Modo Claro (Céu Dia), Modo Escuro (Céu Noite) e **Reduzir Animações e Movimento**;
  3. **Preferências Financeiras:** Escolha do ritmo padrão (*Diário*, *Semanal*, *Mensal*, *No meu ritmo*) e **Modo Privacidade (`R$ •••••`)**;
  4. **Sons, Vibração e Lembretes:** Controle de efeitos táteis e horário de notificações locais;
  5. **Privacidade e Backup Local:** Geração e cópia de **Resumo JSON 100% Offline** para a área de transferência;
  6. **Resumo da Conta:** Estatísticas consolidadas de patrimônio, metas, streaks e Oinc Coins;
  7. **Zona de Perigo:** Reinicialização segura de dados com dupla confirmação.

---

## 🛠️ Tecnologias & Dependências

| Tecnologia | Versão | Função no Projeto |
| :--- | :--- | :--- |
| [Flutter SDK](https://flutter.dev) | 3.x | Framework UI multiplataforma (Android, iOS, Web) |
| [Dart](https://dart.dev) | ≥ 3.0.0 | Linguagem fortemente tipada |
| [Flutter Riverpod](https://riverpod.dev) | ^2.5.1 | Gerenciamento de estado reativo e injeção de dependências |
| [Hive](https://pub.dev/packages/hive) + [hive_flutter](https://pub.dev/packages/hive_flutter) | ^2.2.3 / ^1.1.0 | Banco de dados NoSQL local de alta velocidade (100% offline-first) |
| [fl_chart](https://pub.dev/packages/fl_chart) | ^0.68.0 | Gráficos interativos de evolução mensal |
| [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications) | ^17.2.2 | Agendamento de lembretes diários locais sem servidor externo |
| [timezone](https://pub.dev/packages/timezone) + [flutter_timezone](https://pub.dev/packages/flutter_timezone) | ^0.9.2 / ^5.0.2 | Precisão de fuso horário para notificações locais |
| [intl](https://pub.dev/packages/intl) | ^0.20.2 | Formatação monetária (`pt_BR` / BRL) e datas |
| [uuid](https://pub.dev/packages/uuid) | ^4.4.0 | Geração de identificadores únicos para metas e depósitos |

---

## 🏗️ Arquitetura do Projeto

O código-fonte adota **Clean Architecture** combinada com organização **Feature-First**:

```text
lib/
├── app/
│   └── app.dart                           # Configuração raiz do MaterialApp, temas e navegação inicial
├── assets/
│   └── icon/logo.png                      # Ícone oficial do Oinc
├── core/
│   ├── providers/                         # Providers globais Riverpod e controle de tema Claro/Escuro
│   ├── theme/                             # Tokens de design v3.2, tipografia (Poppins/Quicksand/Nunito) e cores
│   └── utils/                             # Calculadora de ritmo financeiro, formatadores BRL e notificações
├── data/
│   ├── models/                            # Modelos persistentes Hive (GoalModel, DepositModel, MascotModel, etc.)
│   └── repositories/                      # Repositórios locais (Metas, Depósitos, Gamificação, Carteira, Mascote)
├── domain/
│   └── usecases/                          # Casos de uso atômicos (RegisterDepositUseCase, EvaluateBadgesUseCase)
├── features/
│   ├── deposit/                           # Tela de depósito com sugestão de ritmo e seletor rápido de metas
│   ├── gamification/                      # Galeria de conquistas (BadgesGalleryScreen)
│   ├── goal_detail/                       # Detalhe da meta em 3 abas (Jornada, Histórico, Evolução)
│   ├── goal_form/                         # Wizard de criação/edição de metas em 3 passos (com/sem prazo)
│   ├── home/                              # Dashboard principal, resumo consolidado e filtro Menu Sanduíche (☰)
│   ├── mascot/                            # Cantinho do Mascote com palco Soft 3D e Grid 2x2 de cuidados
│   ├── onboarding/                        # Boas-vindas e apresentação interativa do Oinc
│   ├── profile/                           # Modal de Perfil e Ajustes com 7 seções e backup JSON offline
│   ├── shop/                              # Porko Store com 4 categorias e preview ao vivo
│   └── splash/                            # Splash screen animada com identidade Oinc
├── widgets/
│   ├── celebration_overlay.dart           # Overlay de celebração e chuva de confetes a 60fps
│   ├── custom_docked_bottom_bar.dart      # Barra inferior de 4 abas com botão central (+) projetado
│   ├── economy_suggestions_card.dart      # Seletor de ritmo (Diário, Semanal, Mensal, No meu ritmo)
│   ├── goal_card.dart                     # Card de meta Soft 3D com atalho direto de depósito
│   ├── habitat_header_widget.dart         # Cabeçalho colapsável (340px -> 116px) com cenário Dia/Noite
│   ├── milestone_map_card.dart            # Trilha visual de marcos (25%, 50%, 75%, 100%)
│   └── porko_canvas_widget.dart           # Renderizador Soft 3D (Claymorphism) de 9 camadas do mascote Porko
└── main.dart                              # Inicialização do Hive, adaptadores e bootstrap da aplicação
```

---

## 🚀 Como Executar Localmente

### Pré-requisitos
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (versão `>= 3.0.0`)
- Navegador Chrome/Edge (para execução Web) ou Emulador Android / iOS Simulator
- Git instalado

### Passo a Passo

```bash
# 1. Clone o repositório
git clone https://github.com/mateusnriy/cofrinho-gamificado.git
cd cofrinho-gamificado

# 2. Instale as dependências
flutter pub get

# 3. (Opcional) Regere os adaptadores Hive caso modifique os modelos
dart run build_runner build --delete-conflicting-outputs

# 4. Execute no dispositivo ou navegador
flutter run
```

### 🌐 Build para Web (Produção Local)
Como os ícones personalizados das metas são instanciados dinamicamente a partir dos códigos salvos no Hive, utilize a flag `--no-tree-shake-icons` ao gerar o build web:

```bash
flutter build web --no-tree-shake-icons
```

---

## 🧪 Qualidade & Testes Automatizados

O projeto conta com **19 suítes de testes automatizados** em [`test/features/`](test/features/) cobrindo regras de negócio, persistência Hive, gamificação, responsividade em viewports compactos (`320px`), acessibilidade (`reduce_motion`) e fluxos E2E:

```bash
# Executar análise estática (0 erros / 0 avisos)
dart analyze

# Executar todas as suítes de testes
flutter test
```

---

## 👥 Autor

| Desenvolvedor | Papel | GitHub |
| :--- | :--- | :--- |
| **Mateus Neri** | Engenharia de Software, Arquitetura & UI/UX | [@mateusnriy](https://github.com/mateusnriy) |

---

## 📄 Licença

Este projeto é distribuído sob a licença **MIT**.
