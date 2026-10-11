import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cofrinho_digital/data/models/goal_model.dart';
import 'package:cofrinho_digital/data/models/deposit_model.dart';
import 'package:cofrinho_digital/data/repositories/goal_repository.dart';
import 'package:cofrinho_digital/data/repositories/deposit_repository.dart';
import 'package:cofrinho_digital/domain/usecases/register_deposit_use_case.dart';
import 'package:cofrinho_digital/features/goal_form/goal_form_provider.dart';

void main() {
  late Directory tempDir;
  late GoalRepository goalRepo;
  late DepositRepository depositRepo;
  late RegisterDepositUseCase registerUseCase;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('reminder_test_');
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
    registerUseCase = RegisterDepositUseCase(
      goalRepo: goalRepo,
      depositRepo: depositRepo,
    );
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Story 3.3 - Lembretes Locais e Ciclo de Vida', () {
    test('Salva meta com horário de lembrete diário configurado', () async {
      final notifier = GoalFormNotifier(goalRepo);
      notifier.setName('Reserva da Casa');
      notifier.setAmount('5000,00');
      notifier.setDeadline(DateTime.now().add(const Duration(days: 90)));
      notifier.setReminder('08:30');
      notifier.setEconomyMode('daily');

      final saved = await notifier.save();
      expect(saved, isTrue);

      final goals = goalRepo.getActive();
      expect(goals.length, 1);
      expect(goals.first.reminderTime, '08:30');
      expect(goals.first.name, 'Reserva da Casa');
    });

    test('Permite editar e remover o lembrete diário configurado', () async {
      final initialGoal = GoalModel(
        id: 'goal-rem-1',
        name: 'Curso de Flutter',
        targetAmount: 500.0,
        savedAmount: 100.0,
        deadline: DateTime.now().add(const Duration(days: 30)),
        iconCodePoint: Icons.school_rounded.codePoint,
        colorValue: 0xFF10B981,
        createdAt: DateTime.now(),
        reminderTime: '10:00',
      );
      await goalRepo.save(initialGoal);

      final notifier = GoalFormNotifier(goalRepo);
      notifier.loadFromExisting(initialGoal);
      expect(notifier.state.reminderTime, '10:00');

      // Remove o lembrete
      notifier.setReminder(null);
      expect(notifier.state.reminderTime, isNull);

      final updated = await notifier.save(existingId: initialGoal.id);
      expect(updated, isTrue);

      final savedGoal = goalRepo.getById(initialGoal.id);
      expect(savedGoal?.reminderTime, isNull);
    });

    test('Cancelamento defensivo ao concluir 100% da meta via depósito',
        () async {
      final goal = GoalModel(
        id: 'goal-rem-complete',
        name: 'Bicicleta Nova',
        targetAmount: 1000.0,
        savedAmount: 900.0, // Faltam apenas R$ 100
        deadline: DateTime.now().add(const Duration(days: 15)),
        iconCodePoint: Icons.directions_bike_rounded.codePoint,
        colorValue: 0xFFF59E0B,
        createdAt: DateTime.now(),
        reminderTime: '07:00',
      );
      await goalRepo.save(goal);

      // Registra depósito de R$ 100 completando 100% da meta
      final result = await registerUseCase.execute(
        goalId: goal.id,
        amount: 100.0,
        note: 'Última parcela!',
      );

      expect(result, isNotNull);
      expect(result!.isGoalCompleted, isTrue);
      expect(result.goal.savedAmount, 1000.0);
      expect(result.goal.isCompleted, isTrue);
    });

    test('Cancelamento ao arquivar meta com lembrete', () async {
      final goal = GoalModel(
        id: 'goal-rem-archive',
        name: 'Meta para Arquivar',
        targetAmount: 2000.0,
        savedAmount: 300.0,
        deadline: DateTime.now().add(const Duration(days: 40)),
        iconCodePoint: Icons.work_rounded.codePoint,
        colorValue: 0xFF6B7280,
        createdAt: DateTime.now(),
        reminderTime: '12:00',
      );
      await goalRepo.save(goal);

      await goalRepo.archive(goal.id);

      final archived = goalRepo.getById(goal.id);
      expect(archived?.isArchived, isTrue);
    });
  });
}
