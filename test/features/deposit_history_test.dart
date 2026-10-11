import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cofrinho_digital/data/models/goal_model.dart';
import 'package:cofrinho_digital/data/models/deposit_model.dart';
import 'package:cofrinho_digital/data/repositories/goal_repository.dart';
import 'package:cofrinho_digital/data/repositories/deposit_repository.dart';
import 'package:cofrinho_digital/core/providers/global_providers.dart';
import 'package:cofrinho_digital/features/goal_detail/goal_detail_screen.dart';

void main() {
  late Directory tempDir;
  late GoalRepository goalRepo;
  late DepositRepository depositRepo;
  late GoalModel testGoal;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('history_test_');
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

    testGoal = GoalModel(
      id: 'history-goal-1',
      name: 'Viagem de Férias',
      targetAmount: 3000.0,
      savedAmount: 0.0,
      deadline: DateTime.now().add(const Duration(days: 90)),
      iconCodePoint: Icons.flight_takeoff_rounded.codePoint,
      colorValue: 0xFF3B82F6,
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

  Widget createWidgetUnderTest() {
    return ProviderScope(
      overrides: [
        goalRepositoryProvider.overrideWithValue(goalRepo),
        depositRepositoryProvider.overrideWithValue(depositRepo),
      ],
      child: MaterialApp(
        home: GoalDetailScreen(goalId: testGoal.id),
      ),
    );
  }

  group('Histórico de Depósitos - Repositório e Ordenação', () {
    test('Retorna depósitos em ordem cronológica estritamente decrescente',
        () async {
      final baseTime = DateTime(2026, 10, 10, 10, 0);

      final dep1 = DepositModel(
        id: 'dep-1',
        goalId: testGoal.id,
        amount: 50.0,
        date: baseTime,
        note: 'Primeiro aporte',
      );
      final dep2 = DepositModel(
        id: 'dep-2',
        goalId: testGoal.id,
        amount: 150.0,
        date: baseTime.add(const Duration(hours: 3)),
        note: 'Segundo aporte',
      );
      final dep3 = DepositModel(
        id: 'dep-3',
        goalId: testGoal.id,
        amount: 100.0,
        date: baseTime.add(const Duration(hours: 1)),
        note: 'Aporte intermediário',
      );

      await depositRepo.save(dep1);
      await depositRepo.save(dep2);
      await depositRepo.save(dep3);

      final history = depositRepo.getByGoal(testGoal.id);

      expect(history.length, 3);
      // O mais recente (dep2, 13:00) deve ser o primeiro
      expect(history[0].id, 'dep-2');
      expect(history[0].amount, 150.0);

      // O intermediário (dep3, 11:00) deve ser o segundo
      expect(history[1].id, 'dep-3');
      expect(history[1].amount, 100.0);

      // O mais antigo (dep1, 10:00) deve ser o último
      expect(history[2].id, 'dep-1');
      expect(history[2].amount, 50.0);
    });

    test('Filtra apenas depósitos da meta solicitada', () async {
      final depThisGoal = DepositModel(
        id: 'dep-this',
        goalId: testGoal.id,
        amount: 75.0,
        date: DateTime.now(),
      );
      final depOtherGoal = DepositModel(
        id: 'dep-other',
        goalId: 'other-goal-99',
        amount: 200.0,
        date: DateTime.now(),
      );

      await depositRepo.save(depThisGoal);
      await depositRepo.save(depOtherGoal);

      final result = depositRepo.getByGoal(testGoal.id);
      expect(result.length, 1);
      expect(result.first.id, 'dep-this');
      expect(result.first.amount, 75.0);
    });

    test('Exclusão de depósito recalcula total acumulado da meta', () async {
      final depA = DepositModel(
        id: 'dep-a',
        goalId: testGoal.id,
        amount: 100.0,
        date: DateTime.now(),
      );
      final depB = DepositModel(
        id: 'dep-b',
        goalId: testGoal.id,
        amount: 250.0,
        date: DateTime.now(),
      );

      await depositRepo.save(depA);
      await depositRepo.save(depB);
      await goalRepo.update(testGoal.copyWith(savedAmount: 350.0));

      expect(depositRepo.getTotalByGoal(testGoal.id), 350.0);

      // Remove depA
      await depositRepo.delete('dep-a');
      final newTotal = depositRepo.getTotalByGoal(testGoal.id);
      expect(newTotal, 250.0);

      await goalRepo.update(testGoal.copyWith(savedAmount: newTotal));
      final updatedGoal = goalRepo.getById(testGoal.id);
      expect(updatedGoal?.savedAmount, 250.0);
    });
  });

  group('Histórico de Depósitos - Interface Gráfica (Widgets)', () {
    testWidgets('Exibe estado vazio acolhedor quando zero depósitos',
        (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Histórico de Depósitos'), findsOneWidget);
      expect(find.text('0 depósitos'), findsOneWidget);
      expect(
          find.text('Cofrinho pronto para a primeira moeda!'), findsOneWidget);
      expect(find.text('Fazer Primeiro Depósito'), findsOneWidget);
    });

    testWidgets('Exibe lista ordenada com valores, datas e anotações',
        (tester) async {
      final dep1 = DepositModel(
        id: 'ui-dep-1',
        goalId: testGoal.id,
        amount: 80.0,
        date: DateTime(2026, 10, 11, 14, 30),
        note: 'Economia do café',
      );
      final dep2 = DepositModel(
        id: 'ui-dep-2',
        goalId: testGoal.id,
        amount: 200.0,
        date: DateTime(2026, 10, 11, 16, 00),
        note: 'Freelance fim de semana',
      );

      await depositRepo.save(dep1);
      await depositRepo.save(dep2);
      await goalRepo.update(testGoal.copyWith(savedAmount: 280.0));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Histórico de Depósitos'), findsOneWidget);
      expect(find.text('2 depósitos'), findsOneWidget);

      // Depósitos visíveis
      expect(find.text('Economia do café'), findsOneWidget);
      expect(find.text('Freelance fim de semana'), findsOneWidget);

      // Não exibe o estado vazio quando há depósitos
      expect(
          find.text('Cofrinho pronto para a primeira moeda!'), findsNothing);
    });
  });
}
