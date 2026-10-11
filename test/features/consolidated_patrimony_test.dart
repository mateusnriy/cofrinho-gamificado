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
import 'package:cofrinho_digital/features/home/home_screen.dart';
import 'package:cofrinho_digital/features/home/home_provider.dart';

void main() {
  late Directory tempDir;
  late GoalRepository goalRepo;
  late DepositRepository depositRepo;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('patrimony_test_');
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
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Story 3.1 - Repositório: Consolidação de Patrimônio', () {
    test('Calcula corretamente o total economizado, alvos e percentual global',
        () async {
      final goal1 = GoalModel(
        id: 'pat-1',
        name: 'Celular Novo',
        targetAmount: 2000.0,
        savedAmount: 500.0,
        deadline: DateTime.now().add(const Duration(days: 30)),
        iconCodePoint: Icons.phone_android_rounded.codePoint,
        colorValue: 0xFF10B981,
        createdAt: DateTime.now(),
      );

      final goal2 = GoalModel(
        id: 'pat-2',
        name: 'Viagem de Férias',
        targetAmount: 3000.0,
        savedAmount: 1500.0,
        deadline: DateTime.now().add(const Duration(days: 90)),
        iconCodePoint: Icons.flight_takeoff_rounded.codePoint,
        colorValue: 0xFF3B82F6,
        createdAt: DateTime.now(),
      );

      await goalRepo.save(goal1);
      await goalRepo.save(goal2);

      final stats = goalRepo.getStats();

      expect(stats['totalGoals'], 2);
      expect(stats['totalTarget'], 5000.0);
      expect(stats['totalSaved'], 2000.0);
      expect(stats['completed'], 0);
      expect(stats['overallProgress'], 0.4); // 2000 / 5000 = 40%
    });

    test('Identifica metas concluídas e limita o progresso global em 1.0 (clamp)',
        () async {
      final goalA = GoalModel(
        id: 'pat-a',
        name: 'Livro de Finanças',
        targetAmount: 100.0,
        savedAmount: 100.0, // 100% concluída
        deadline: DateTime.now().add(const Duration(days: 10)),
        iconCodePoint: Icons.book_rounded.codePoint,
        colorValue: 0xFF10B981,
        createdAt: DateTime.now(),
      );

      final goalB = GoalModel(
        id: 'pat-b',
        name: 'Curso Online',
        targetAmount: 200.0,
        savedAmount: 250.0, // Acima de 100%
        deadline: DateTime.now().add(const Duration(days: 20)),
        iconCodePoint: Icons.school_rounded.codePoint,
        colorValue: 0xFFF59E0B,
        createdAt: DateTime.now(),
      );

      await goalRepo.save(goalA);
      await goalRepo.save(goalB);

      final stats = goalRepo.getStats();

      expect(stats['totalGoals'], 2);
      expect(stats['completed'], 2);
      expect(stats['totalSaved'], 350.0);
      expect(stats['totalTarget'], 300.0);
      expect(stats['overallProgress'], 1.0); // Clamped em 1.0
    });

    test('Ignora metas arquivadas na consolidação patrimonial', () async {
      final activeGoal = GoalModel(
        id: 'act-1',
        name: 'Fundo de Emergência',
        targetAmount: 1000.0,
        savedAmount: 400.0,
        deadline: DateTime.now().add(const Duration(days: 45)),
        iconCodePoint: Icons.security_rounded.codePoint,
        colorValue: 0xFF10B981,
        createdAt: DateTime.now(),
      );

      final archivedGoal = GoalModel(
        id: 'arc-1',
        name: 'Meta Antiga Desistida',
        targetAmount: 5000.0,
        savedAmount: 200.0,
        deadline: DateTime.now().add(const Duration(days: 10)),
        iconCodePoint: Icons.archive_rounded.codePoint,
        colorValue: 0xFF6B7280,
        createdAt: DateTime.now(),
        isArchived: true,
      );

      await goalRepo.save(activeGoal);
      await goalRepo.save(archivedGoal);

      final stats = goalRepo.getStats();

      expect(stats['totalGoals'], 1);
      expect(stats['totalTarget'], 1000.0);
      expect(stats['totalSaved'], 400.0);
      expect(stats['overallProgress'], 0.4);
    });
  });

  group('Story 3.1 - Interface Gráfica: Banner de Resumo Patrimonial', () {
    testWidgets('Exibe o banner consolidado quando há metas ativas',
        (tester) async {
      final goal = GoalModel(
        id: 'ui-pat-1',
        name: 'Reforma da Casa',
        targetAmount: 10000.0,
        savedAmount: 3500.0,
        deadline: DateTime.now().add(const Duration(days: 120)),
        iconCodePoint: Icons.home_rounded.codePoint,
        colorValue: 0xFF8B5CF6,
        createdAt: DateTime.now(),
      );
      await goalRepo.save(goal);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            goalRepositoryProvider.overrideWithValue(goalRepo),
            depositRepositoryProvider.overrideWithValue(depositRepo),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Banner patrimonial deve estar visível
      expect(find.text('Patrimônio Guardado'), findsOneWidget);
      expect(find.text('R\$ 3.500,00'), findsOneWidget);
      expect(find.text('35%'), findsOneWidget);
      expect(find.text('De R\$ 10.000,00 em 1 meta'), findsOneWidget);
    });

    testWidgets('Atualiza os valores de forma reativa após adição de depósito',
        (tester) async {
      final goal = GoalModel(
        id: 'ui-pat-react',
        name: 'Reserva',
        targetAmount: 1000.0,
        savedAmount: 200.0,
        deadline: DateTime.now().add(const Duration(days: 30)),
        iconCodePoint: Icons.savings_rounded.codePoint,
        colorValue: 0xFF10B981,
        createdAt: DateTime.now(),
      );
      await goalRepo.save(goal);

      final container = ProviderContainer(
        overrides: [
          goalRepositoryProvider.overrideWithValue(goalRepo),
          depositRepositoryProvider.overrideWithValue(depositRepo),
        ],
      );

      expect(container.read(goalStatsProvider)['totalSaved'], 200.0);
      expect(container.read(goalStatsProvider)['overallProgress'], 0.2);

      // Adiciona depósito e atualiza meta
      await goalRepo.addDeposit(goal.id, 300.0);

      // Provider reflete o novo saldo e progresso
      expect(container.read(goalStatsProvider)['totalSaved'], 500.0);
      expect(container.read(goalStatsProvider)['overallProgress'], 0.5);
    });
  });
}
