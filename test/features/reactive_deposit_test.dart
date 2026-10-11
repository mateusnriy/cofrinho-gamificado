import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cofrinho_digital/data/models/goal_model.dart';
import 'package:cofrinho_digital/data/models/deposit_model.dart';
import 'package:cofrinho_digital/data/repositories/goal_repository.dart';
import 'package:cofrinho_digital/data/repositories/deposit_repository.dart';
import 'package:cofrinho_digital/domain/usecases/register_deposit_use_case.dart';
import 'package:cofrinho_digital/core/providers/global_providers.dart';
import 'package:cofrinho_digital/features/home/home_provider.dart';
import 'package:cofrinho_digital/features/goal_detail/goal_detail_provider.dart';
import 'package:cofrinho_digital/core/utils/economy_calculator.dart';

void main() {
  late Directory tempDir;
  late GoalRepository goalRepo;
  late DepositRepository depositRepo;
  late RegisterDepositUseCase useCase;
  late GoalModel testGoal;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('reactive_test_');
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

    goalRepo = GoalRepository();
    depositRepo = DepositRepository();
    useCase = RegisterDepositUseCase(
      goalRepo: goalRepo,
      depositRepo: depositRepo,
    );

    testGoal = GoalModel(
      id: 'react-goal-1',
      name: 'PlayStation 5',
      targetAmount: 4000.0,
      savedAmount: 900.0, // Próximo ao marco de 25% (1000.0)
      deadline: DateTime.now().add(const Duration(days: 60)),
      iconCodePoint: Icons.sports_esports_rounded.codePoint,
      colorValue: 0xFF10B981,
      createdAt: DateTime.now(),
    );
    await goalRepo.save(testGoal);
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('RegisterDepositUseCase Unit Tests (ARCH-4)', () {
    test('Executa transação atômica de depósito e detecta marco alcançado',
        () async {
      // Depósito de 150.0 leva de 900.0 para 1050.0 (ultrapassa 25% = 1000.0)
      final result = await useCase.execute(
        goalId: testGoal.id,
        amount: 150.0,
        note: 'Bônus do trabalho',
      );

      expect(result, isNotNull);
      expect(result!.amount, equals(150.0));
      expect(result.coinsEarned, equals(150));
      expect(result.goal.savedAmount, equals(1050.0));
      expect(result.milestonesBefore, equals(0));
      expect(result.milestonesAfter, equals(1));
      expect(result.newMilestoneReached, isTrue);
      expect(result.isGoalCompleted, isFalse);

      // Valida persistência na caixa de depósitos
      final deposits = depositRepo.getByGoal(testGoal.id);
      expect(deposits.length, equals(1));
      expect(deposits.first.amount, equals(150.0));
      expect(deposits.first.note, equals('Bônus do trabalho'));
    });

    test('Detecta conclusão da meta (100%) quando valor atinge o alvo',
        () async {
      testGoal.savedAmount = 3900.0;
      await goalRepo.update(testGoal);

      final result = await useCase.execute(
        goalId: testGoal.id,
        amount: 100.0,
      );

      expect(result, isNotNull);
      expect(result!.isGoalCompleted, isTrue);
      expect(result.milestonesAfter, equals(4));
      expect(result.newMilestoneReached, isTrue);
    });

    test('Bloqueia e retorna null se valor for maior que o saldo restante',
        () async {
      // Restam 4000 - 900 = 3100
      final result = await useCase.execute(
        goalId: testGoal.id,
        amount: 3200.0,
      );

      expect(result, isNull);
    });
  });

  group('Provedores Reativos & Recálculo de Projeções (Story 2.2)', () {
    test('Provedores atualizam reativamente e projeções recalculam com saldo reduzido',
        () async {
      final container = ProviderContainer(
        overrides: [
          goalRepositoryProvider.overrideWithValue(goalRepo),
          depositRepositoryProvider.overrideWithValue(depositRepo),
        ],
      );

      // Estado inicial
      final initialGoals = container.read(homeGoalsProvider);
      expect(initialGoals.first.savedAmount, equals(900.0));

      final initialStats = container.read(goalStatsProvider);
      expect(initialStats['totalSaved'], equals(900.0));

      // Projeções antes do depósito (faltam 3100)
      final projectionsBefore = EconomyCalculator.calculate(
        targetAmount: testGoal.targetAmount,
        savedAmount: testGoal.savedAmount,
        deadline: testGoal.deadline,
      );
      final dailyBefore = projectionsBefore[0].amount;

      // Executa depósito de R$ 500
      await useCase.execute(
        goalId: testGoal.id,
        amount: 500.0,
      );

      // Dispara ciclo do container
      container.pump();

      // Provedores reativos atualizados imediatamente (< 200ms)
      final updatedGoals = container.read(homeGoalsProvider);
      expect(updatedGoals.first.savedAmount, equals(1400.0));

      final updatedStats = container.read(goalStatsProvider);
      expect(updatedStats['totalSaved'], equals(1400.0));

      final updatedDetailGoal =
          container.read(goalByIdProvider(testGoal.id));
      expect(updatedDetailGoal?.savedAmount, equals(1400.0));

      final updatedDeposits =
          container.read(depositsByGoalProvider(testGoal.id));
      expect(updatedDeposits.length, equals(1));
      expect(updatedDeposits.first.amount, equals(500.0));

      // Recálculo de projeções com novo saldo restante menor (faltam 2600)
      final projectionsAfter = EconomyCalculator.calculate(
        targetAmount: testGoal.targetAmount,
        savedAmount: updatedDetailGoal!.savedAmount,
        deadline: testGoal.deadline,
      );
      final dailyAfter = projectionsAfter[0].amount;

      // A necessidade diária de economia deve ter diminuído
      expect(dailyAfter, lessThan(dailyBefore));
    });
  });
}
