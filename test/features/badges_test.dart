import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cofrinho_digital/data/models/goal_model.dart';
import 'package:cofrinho_digital/data/models/deposit_model.dart';
import 'package:cofrinho_digital/data/models/badge_model.dart';
import 'package:cofrinho_digital/data/repositories/goal_repository.dart';
import 'package:cofrinho_digital/data/repositories/deposit_repository.dart';
import 'package:cofrinho_digital/data/repositories/gamification_repository.dart';
import 'package:cofrinho_digital/domain/usecases/register_deposit_use_case.dart';
import 'package:cofrinho_digital/domain/usecases/evaluate_badges_use_case.dart';
import 'package:cofrinho_digital/core/providers/global_providers.dart';
import 'package:cofrinho_digital/features/gamification/badges_gallery_screen.dart';
import 'package:cofrinho_digital/features/home/home_screen.dart';

void main() {
  late Directory tempDir;
  late GoalRepository goalRepo;
  late DepositRepository depositRepo;
  late GamificationRepository gamificationRepo;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('badges_test_');
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

    goalRepo = GoalRepository();
    depositRepo = DepositRepository();
    gamificationRepo = GamificationRepository();
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Story 4.3: Concessão e Galeria de Badges - Unit Tests', () {
    test('EvaluateBadgesUseCase desbloqueia primeiro depósito e é estritamente idempotente',
        () async {
      final evaluator = EvaluateBadgesUseCase(
        goalRepo: goalRepo,
        depositRepo: depositRepo,
        gamificationRepo: gamificationRepo,
      );

      // Estado inicial sem depósitos
      var unlocked = await evaluator.execute();
      expect(unlocked, isEmpty);
      expect(gamificationRepo.isBadgeUnlocked('first_deposit'), isFalse);

      // Registra primeiro depósito
      final deposit = DepositModel(
        id: 'dep-1',
        goalId: 'g-1',
        amount: 100.0,
        date: DateTime.now(),
      );
      await depositRepo.save(deposit);

      // Avaliação deve desbloquear 'first_deposit'
      unlocked = await evaluator.execute();
      expect(unlocked.length, equals(1));
      expect(unlocked.first.id, equals('first_deposit'));
      expect(gamificationRepo.isBadgeUnlocked('first_deposit'), isTrue);

      // Reavaliação: não deve duplicar (idempotência)
      final reevaluated = await evaluator.execute();
      expect(reevaluated, isEmpty);
      expect(gamificationRepo.isBadgeUnlocked('first_deposit'), isTrue);
    });

    test('Desbloqueia badges de streak_3 e streak_7 conforme a sequência', () async {
      final evaluator = EvaluateBadgesUseCase(
        goalRepo: goalRepo,
        depositRepo: depositRepo,
        gamificationRepo: gamificationRepo,
      );

      // Simula 3 dias consecutivos
      await gamificationRepo.registerDepositDate(DateTime(2026, 10, 1));
      await gamificationRepo.registerDepositDate(DateTime(2026, 10, 2));
      await gamificationRepo.registerDepositDate(DateTime(2026, 10, 3));

      expect(gamificationRepo.getCurrentStreak(), equals(3));

      var unlocked = await evaluator.execute();
      expect(unlocked.any((b) => b.id == 'streak_3'), isTrue);
      expect(gamificationRepo.isBadgeUnlocked('streak_3'), isTrue);
      expect(gamificationRepo.isBadgeUnlocked('streak_7'), isFalse);

      // Avança para 7 dias
      await gamificationRepo.registerDepositDate(DateTime(2026, 10, 4));
      await gamificationRepo.registerDepositDate(DateTime(2026, 10, 5));
      await gamificationRepo.registerDepositDate(DateTime(2026, 10, 6));
      await gamificationRepo.registerDepositDate(DateTime(2026, 10, 7));

      expect(gamificationRepo.getCurrentStreak(), equals(7));

      unlocked = await evaluator.execute();
      expect(unlocked.any((b) => b.id == 'streak_7'), isTrue);
      expect(gamificationRepo.isBadgeUnlocked('streak_7'), isTrue);
    });

    test('Desbloqueia halfway e goal_completed ao progredir e concluir meta',
        () async {
      final evaluator = EvaluateBadgesUseCase(
        goalRepo: goalRepo,
        depositRepo: depositRepo,
        gamificationRepo: gamificationRepo,
      );

      final goal = GoalModel(
        id: 'g-progress',
        name: 'Viagem',
        targetAmount: 1000.0,
        savedAmount: 500.0, // 50%
        deadline: DateTime.now().add(const Duration(days: 30)),
        iconCodePoint: Icons.flight_rounded.codePoint,
        colorValue: 0xFF10B981,
        createdAt: DateTime.now(),
      );
      await goalRepo.create(goal);

      var unlocked = await evaluator.execute();
      expect(unlocked.any((b) => b.id == 'halfway'), isTrue);
      expect(gamificationRepo.isBadgeUnlocked('halfway'), isTrue);
      expect(gamificationRepo.isBadgeUnlocked('goal_completed'), isFalse);

      // Atualiza para 100%
      goal.savedAmount = 1000.0;
      await goalRepo.update(goal);

      unlocked = await evaluator.execute();
      expect(unlocked.any((b) => b.id == 'goal_completed'), isTrue);
      expect(gamificationRepo.isBadgeUnlocked('goal_completed'), isTrue);
    });

    test('Desbloqueia collector ao atingir 3 metas ativas simultâneas', () async {
      final evaluator = EvaluateBadgesUseCase(
        goalRepo: goalRepo,
        depositRepo: depositRepo,
        gamificationRepo: gamificationRepo,
      );

      for (int i = 1; i <= 3; i++) {
        await goalRepo.create(GoalModel(
          id: 'goal-$i',
          name: 'Meta $i',
          targetAmount: 500.0,
          deadline: DateTime.now().add(const Duration(days: 20)),
          iconCodePoint: Icons.star_rounded.codePoint,
          colorValue: 0xFF10B981,
          createdAt: DateTime.now(),
        ));
      }

      final unlocked = await evaluator.execute();
      expect(unlocked.any((b) => b.id == 'collector'), isTrue);
      expect(gamificationRepo.isBadgeUnlocked('collector'), isTrue);
    });

    test('RegisterDepositUseCase integra concessão e retorna newBadges no resultado',
        () async {
      final useCase = RegisterDepositUseCase(
        goalRepo: goalRepo,
        depositRepo: depositRepo,
        gamificationRepo: gamificationRepo,
      );

      final goal = GoalModel(
        id: 'g-deposit-test',
        name: 'Notebook',
        targetAmount: 1000.0,
        deadline: DateTime.now().add(const Duration(days: 30)),
        iconCodePoint: Icons.laptop_rounded.codePoint,
        colorValue: 0xFF10B981,
        createdAt: DateTime.now(),
      );
      await goalRepo.create(goal);

      final result = await useCase.execute(
        goalId: goal.id,
        amount: 500.0, // Desbloqueia first_deposit e halfway simultaneamente!
      );

      expect(result, isNotNull);
      expect(result!.newBadges.length, greaterThanOrEqualTo(2));
      expect(result.newBadges.any((b) => b.id == 'first_deposit'), isTrue);
      expect(result.newBadges.any((b) => b.id == 'halfway'), isTrue);
      expect(gamificationRepo.isBadgeUnlocked('first_deposit'), isTrue);
      expect(gamificationRepo.isBadgeUnlocked('halfway'), isTrue);
    });
  });

  group('Story 4.3: BadgesGalleryScreen - Widget Tests', () {
    testWidgets('Renderiza galeria de badges com contadores, títulos e tags de status',
        (tester) async {
      // Pré-desbloqueia 1 badge
      await gamificationRepo.unlockBadge('first_deposit');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gamificationRepositoryProvider.overrideWithValue(gamificationRepo),
          ],
          child: const MaterialApp(
            home: BadgesGalleryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Galeria de Conquistas'), findsOneWidget);
      expect(find.text('Coleção de Emblemas'), findsOneWidget);
      expect(find.text('1 de 8 conquistas desbloqueadas'), findsOneWidget);
      expect(find.text('Todas as Conquistas'), findsOneWidget);

      // Primeiro Passo deve estar desbloqueado
      expect(find.text('Primeiro Passo'), findsOneWidget);
      expect(find.text('Desbloqueado ✨'), findsOneWidget);

      // Outros devem estar bloqueados
      expect(find.text('Bloqueado'), findsNWidgets(7));
    });

    testWidgets('Tocar em um badge abre modal de detalhes e fecha com botão',
        (tester) async {
      await gamificationRepo.unlockBadge('first_deposit', DateTime(2026, 10, 11));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gamificationRepositoryProvider.overrideWithValue(gamificationRepo),
          ],
          child: const MaterialApp(
            home: BadgesGalleryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Clica no badge Primeiro Passo
      await tester.tap(find.text('Primeiro Passo'));
      await tester.pumpAndSettle();

      // Modal aberto com descrição e botão Fechar
      expect(find.textContaining('Registrou o primeiro depósito'), findsOneWidget);
      expect(find.text('Fechar'), findsOneWidget);

      // Clica em Fechar
      await tester.tap(find.text('Fechar'));
      await tester.pumpAndSettle();

      expect(find.text('Fechar'), findsNothing);
    });

    testWidgets('HomeScreen possui botão de acesso à Galeria de Conquistas',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            goalRepositoryProvider.overrideWithValue(goalRepo),
            depositRepositoryProvider.overrideWithValue(depositRepo),
            gamificationRepositoryProvider.overrideWithValue(gamificationRepo),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Encontra o botão com tooltip 'Galeria de Conquistas'
      final trophyFinder = find.byTooltip('Galeria de Conquistas');
      expect(trophyFinder, findsOneWidget);

      // Clica para navegar à galeria
      await tester.tap(trophyFinder);
      await tester.pumpAndSettle();

      expect(find.byType(BadgesGalleryScreen), findsOneWidget);
    });
  });
}
