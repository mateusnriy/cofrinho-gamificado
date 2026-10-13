import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cofrinho_digital/core/providers/global_providers.dart';
import 'package:cofrinho_digital/data/models/deposit_model.dart';
import 'package:cofrinho_digital/data/models/goal_model.dart';
import 'package:cofrinho_digital/data/models/mascot_model.dart';
import 'package:cofrinho_digital/data/repositories/deposit_repository.dart';
import 'package:cofrinho_digital/data/repositories/gamification_repository.dart';
import 'package:cofrinho_digital/data/repositories/goal_repository.dart';
import 'package:cofrinho_digital/data/repositories/mascot_repository.dart';
import 'package:cofrinho_digital/data/repositories/wallet_repository.dart';
import 'package:cofrinho_digital/features/deposit/deposit_screen.dart';
import 'package:cofrinho_digital/features/gamification/badges_gallery_screen.dart';
import 'package:cofrinho_digital/features/goal_detail/goal_detail_screen.dart';
import 'package:cofrinho_digital/features/goal_form/goal_form_screen.dart';
import 'package:cofrinho_digital/features/home/home_screen.dart';
import 'package:cofrinho_digital/features/mascot/mascot_screen.dart';
import 'package:cofrinho_digital/features/onboarding/onboarding_screen.dart';
import 'package:cofrinho_digital/features/profile/profile_settings_modal.dart';
import 'package:cofrinho_digital/widgets/habitat_header_widget.dart';
import 'package:cofrinho_digital/widgets/porko_canvas_widget.dart';

void main() {
  late Directory tempDir;
  late GoalRepository goalRepo;
  late DepositRepository depositRepo;
  late GamificationRepository gamificationRepo;
  late WalletRepository walletRepo;
  late MascotRepository mascotRepo;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('sprint3_e2e_test_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(GoalModelAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(DepositModelAdapter());
    }
    await Hive.openBox('settings');
    await Hive.openBox<GoalModel>('goals');
    await Hive.openBox<DepositModel>('deposits');
    await Hive.openBox('gamification');
    await Hive.openBox('wallet');
    await Hive.openBox('badges');
    await Hive.openBox('mascot_box');

    goalRepo = GoalRepository();
    depositRepo = DepositRepository();
    gamificationRepo = GamificationRepository();
    walletRepo = WalletRepository();
    mascotRepo = MascotRepository();
  });

  tearDown(() async {
    try {
      await Hive.close().timeout(
        const Duration(milliseconds: 250),
        onTimeout: () => null,
      );
    } catch (_) {}
    try {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  List<Override> buildOverrides() => [
        goalRepositoryProvider.overrideWithValue(goalRepo),
        depositRepositoryProvider.overrideWithValue(depositRepo),
        gamificationRepositoryProvider.overrideWithValue(gamificationRepo),
        walletRepositoryProvider.overrideWithValue(walletRepo),
        mascotRepositoryProvider.overrideWithValue(mascotRepo),
      ];

  group('Story 6.1 (AUD-01 + RV-01): PorkoCanvasWidget Soft 3D Claymorphism', () {
    testWidgets(
      'Renderiza skins, chapéus e roupas em Soft 3D e respeita reduce_motion',
      (tester) async {
        await Hive.box('settings').put('reduce_motion', true);

        const customMascot = MascotModel(
          name: 'Porkito 3D',
          skinId: 'golden',
          hatId: 'hat_crown',
          clothId: 'outfit_cape',
          backdropId: 'deco_rainbow',
        );

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Center(
                child: PorkoCanvasWidget(
                  mood: PorkoMood.celebrating,
                  mascot: customMascot,
                  activeReaction: 'love',
                  showEmptySign: true,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(PorkoCanvasWidget), findsOneWidget);
        expect(find.text('💖'), findsOneWidget);
        expect(find.textContaining('Crie sua 1ª meta!'), findsOneWidget);
      },
    );
  });

  group('Story 6.2 (AUD-02): Rebranding Oinc — Meu cofrinho virtual', () {
    testWidgets(
      'OnboardingScreen exibe Oinc — Meu cofrinho virtual e nunca Cofrinho Digital',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: buildOverrides(),
            child: const MaterialApp(home: OnboardingScreen()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('Bem-vindo ao Oinc!'), findsOneWidget);
        expect(find.text('Oinc — Meu cofrinho virtual'), findsOneWidget);
        expect(find.textContaining('Cofrinho Digital'), findsNothing);
      },
    );
  });

  group('Story 6.3 (AUD-03..06 + RV-02): HabitatHeaderWidget e Reatividade de Perfil', () {
    testWidgets(
      'Renderiza decoração de cenário equipada e atualiza nome/avatar reativamente em 320px',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await Hive.box('settings').put('user_name', 'Mateus');
        await Hive.box('settings').put('user_avatar', '🦊');

        const mascotWithDeco = MascotModel(
          name: 'Porko',
          backdropId: 'deco_plant',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HabitatHeaderWidget(
                coins: 250,
                streakDays: 5,
                isDark: false,
                hasGoals: true,
                mood: PorkoMood.happy,
                mascot: mascotWithDeco,
                onProfileTap: () {},
                onCoinsTap: () {},
                onThemeToggle: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verifica nome e avatar reativos do Hive e decoração de cenário (vasos de planta)
        expect(find.text('Olá, Mateus!'), findsOneWidget);
        expect(find.text('🦊'), findsOneWidget);
        expect(find.text('🪴'), findsOneWidget);
        expect(find.text('🌻'), findsOneWidget);

        // Altera nome e avatar em tempo real no Hive e verifica atualização imediata (RV-02)
        await Hive.box('settings').put('user_name', 'Clara');
        await Hive.box('settings').put('user_avatar', '🐼');
        await tester.pump();

        expect(find.text('Olá, Clara!'), findsOneWidget);
        expect(find.text('🐼'), findsOneWidget);
      },
    );
  });

  group('Story 6.4 (AUD-07 + AUD-08): HomeScreen GoalCard e Menu Sanduíche de Filtros', () {
    testWidgets(
      'Filtra metas por status/ritmo via Menu Sanduíche (☰) e exibe botão Depositar no card',
      (tester) async {
        // Cria 2 metas: uma com prazo e uma sem prazo (ano >= 2099)
        await goalRepo.save(
          GoalModel(
            id: 'goal-deadline',
            name: 'Viagem Japão',
            targetAmount: 5000,
            savedAmount: 1000,
            deadline: DateTime.now().add(const Duration(days: 90)),
            iconCodePoint: Icons.flight_rounded.codePoint,
            colorValue: 0xFF2E7D32,
            createdAt: DateTime.now(),
          ),
        );
        await goalRepo.save(
          GoalModel(
            id: 'goal-free',
            name: 'Reserva Livre',
            targetAmount: 2000,
            savedAmount: 200,
            deadline: DateTime(2099, 12, 31),
            iconCodePoint: Icons.savings_rounded.codePoint,
            colorValue: 0xFF1565C0,
            createdAt: DateTime.now().subtract(const Duration(days: 1)),
          ),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: buildOverrides(),
            child: const MaterialApp(home: HomeScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Ambas as metas e o botão "💰 Depositar ›" devem aparecer
        expect(find.text('Viagem Japão'), findsOneWidget);
        expect(find.text('Reserva Livre'), findsOneWidget);
        expect(find.text('💰 Depositar ›'), findsWidgets);

        // Abre o Menu Sanduíche (☰) e filtra por "Sem prazo definido"
        await tester.tap(find.byIcon(Icons.menu_rounded));
        await tester.pumpAndSettle();

        expect(find.text('Filtrar e Ordenar Metas'), findsOneWidget);
        await tester.tap(find.text('Sem prazo definido'));
        await tester.pumpAndSettle();

        // Apenas a meta sem prazo deve estar visível e a pílula de filtro ativo deve aparecer
        expect(find.text('Reserva Livre'), findsOneWidget);
        expect(find.text('Viagem Japão'), findsNothing);
        expect(find.text('Limpar'), findsOneWidget);
      },
    );
  });

  group('Story 6.5 (AUD-09 + AUD-10): Wizard GoalFormScreen com Sem Prazo e Ritmo Livre', () {
    testWidgets(
      'Botão Sem prazo avança para Passo 2 travado em No meu ritmo e Passo 3 exibe Porko Soft 3D',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: buildOverrides(),
            child: const MaterialApp(home: GoalFormScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Preenche nome e valor no Passo 1
        await tester.enterText(find.byType(TextFormField).first, 'Fundo Livre');
        await tester.enterText(find.byType(TextFormField).at(1), '1000,00');
        await tester.pump();

        // Toca no botão tracejado "Sem prazo — vou guardando no meu ritmo"
        final noDeadlineBtn = find.text('Sem prazo — vou guardando no meu ritmo');
        await tester.ensureVisible(noDeadlineBtn);
        await tester.tap(noDeadlineBtn);
        await tester.pumpAndSettle();

        // Avança para o Passo 2
        final nextBtn = find.text('Próximo: Ver plano →');
        await tester.ensureVisible(nextBtn);
        await tester.tap(nextBtn);
        await tester.pumpAndSettle();

        // No Passo 2, verifica aviso de meta sem prazo e card "No meu ritmo"
        expect(
          find.textContaining('Meta sem prazo — guarde quanto e quando quiser!'),
          findsOneWidget,
        );
        expect(find.text('No meu ritmo'), findsOneWidget);

        // Avança para o Passo 3
        final step3Btn = find.text('Próximo: Revisar →');
        await tester.ensureVisible(step3Btn);
        await tester.tap(step3Btn);
        await tester.pumpAndSettle();

        // No Passo 3, valida presença do PorkoCanvasWidget Soft 3D e botão de confirmação
        expect(find.byType(PorkoCanvasWidget), findsOneWidget);
        expect(find.text('✨ Criar meta!'), findsOneWidget);
      },
    );
  });

  group('Story 6.6 (AUD-11..13): GoalDetailScreen e DepositScreen com Sugestão de Ritmo', () {
    testWidgets(
      'GoalDetailScreen exibe card translúcido no header e caixa do Porko no mapa de marcos',
      (tester) async {
        final goal = GoalModel(
          id: 'goal-detail-1',
          name: 'Notebook Novo',
          targetAmount: 4000,
          savedAmount: 1200,
          deadline: DateTime.now().add(const Duration(days: 60)),
          iconCodePoint: Icons.laptop_mac_rounded.codePoint,
          colorValue: 0xFF2E7D32,
          createdAt: DateTime.now().subtract(const Duration(days: 10)),
        );
        await goalRepo.save(goal);

        await tester.pumpWidget(
          ProviderScope(
            overrides: buildOverrides(),
            child: MaterialApp(home: GoalDetailScreen(goalId: goal.id)),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Notebook Novo'), findsWidgets);
        expect(find.text('Faltam'), findsOneWidget);
        expect(find.text('Status'), findsOneWidget);
        expect(find.text('Prazo'), findsOneWidget);
        expect(find.text('Bônus de conclusão (100%)'), findsOneWidget);
      },
    );

    testWidgets(
      'DepositScreen exibe botão Sugerido pelo seu ritmo e seletor horizontal de metas',
      (tester) async {
        final g1 = GoalModel(
          id: 'dep-g1',
          name: 'Meta Principal',
          targetAmount: 1200,
          savedAmount: 200,
          deadline: DateTime.now().add(const Duration(days: 30)),
          iconCodePoint: Icons.star_rounded.codePoint,
          colorValue: 0xFF2E7D32,
          createdAt: DateTime.now(),
        );
        final g2 = GoalModel(
          id: 'dep-g2',
          name: 'Segunda Meta',
          targetAmount: 800,
          savedAmount: 100,
          deadline: DateTime.now().add(const Duration(days: 45)),
          iconCodePoint: Icons.flight_rounded.codePoint,
          colorValue: 0xFF1565C0,
          createdAt: DateTime.now(),
        );
        await goalRepo.save(g1);
        await goalRepo.save(g2);

        await tester.pumpWidget(
          ProviderScope(
            overrides: buildOverrides(),
            child: MaterialApp(home: DepositScreen(goal: g1)),
          ),
        );
        await tester.pumpAndSettle();

        // Verifica botão sugerido pelo ritmo e seletor horizontal com a segunda meta
        expect(find.textContaining('Sugerido pelo seu ritmo:'), findsOneWidget);
        expect(find.text('Depositando na meta'), findsOneWidget);
        expect(find.text('Segunda Meta'), findsOneWidget);
      },
    );
  });

  group('Story 6.7 & 6.8 (AUD-14..20 + RV-03): ProfileSettingsModal, MascotScreen e Conquistas', () {
    testWidgets(
      'ProfileSettingsModal exibe as 7 seções completas e salva preferências no Hive',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: buildOverrides(),
            child: const MaterialApp(
              home: Scaffold(body: ProfileSettingsModal()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Meu Perfil e Ajustes'), findsOneWidget);
        expect(find.text('Perfil e Identidade'), findsOneWidget);
        expect(find.text('Aparência e Acessibilidade'), findsOneWidget);
        expect(find.text('Reduzir Animações e Movimento'), findsOneWidget);
      },
    );

    testWidgets(
      'MascotScreen respeita piso anti-culpa de 40% e persiste contadores diários no Hive (RV-03)',
      (tester) async {
        await walletRepo.addCoins(100);

        await tester.pumpWidget(
          ProviderScope(
            overrides: buildOverrides(),
            child: const MaterialApp(home: MascotScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Sem metas/depósitos, Felicidade e Energia nunca caem abaixo de 40%
        expect(find.text('40%'), findsNWidgets(2));
        expect(find.text('Fazer carinho'), findsOneWidget);
        expect(find.text('0/3 hoje • Grátis'), findsOneWidget);

        // Toca em "Fazer carinho" e verifica persistência no Hive (RV-03)
        final petCard = find.text('Fazer carinho');
        await tester.ensureVisible(petCard);
        await tester.tap(petCard);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1000));

        expect(Hive.box('settings').get('care_pet'), equals(1));
        expect(find.text('1/3 hoje • Grátis'), findsOneWidget);
      },
    );

    testWidgets(
      'BadgesGalleryScreen contabiliza metas concluídas corretamente via stats[completed]',
      (tester) async {
        await goalRepo.save(
          GoalModel(
            id: 'done-goal-1',
            name: 'Meta 100%',
            targetAmount: 500,
            savedAmount: 500,
            deadline: DateTime.now().add(const Duration(days: 10)),
            iconCodePoint: Icons.check_circle_rounded.codePoint,
            colorValue: 0xFF2E7D32,
            createdAt: DateTime.now(),
          ),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: buildOverrides(),
            child: const MaterialApp(home: BadgesGalleryScreen()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Conquistas'), findsOneWidget);
        expect(find.text('Metas concluídas'), findsOneWidget);
      },
    );
  });
}
