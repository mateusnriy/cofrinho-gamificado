import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cofrinho_digital/data/models/goal_model.dart';
import 'package:cofrinho_digital/data/models/deposit_model.dart';
import 'package:cofrinho_digital/data/repositories/goal_repository.dart';
import 'package:cofrinho_digital/data/repositories/deposit_repository.dart';
import 'package:cofrinho_digital/data/repositories/gamification_repository.dart';
import 'package:cofrinho_digital/domain/usecases/register_deposit_use_case.dart';
import 'package:cofrinho_digital/core/providers/global_providers.dart';
import 'package:cofrinho_digital/features/home/home_screen.dart';

void main() {
  late Directory tempDir;
  late GoalRepository goalRepo;
  late DepositRepository depositRepo;
  late GamificationRepository gamificationRepo;
  late RegisterDepositUseCase registerUseCase;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('streak_test_');
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
    await Hive.openBox('mascot_box');

    goalRepo = GoalRepository();
    depositRepo = DepositRepository();
    gamificationRepo = GamificationRepository();
    registerUseCase = RegisterDepositUseCase(
      goalRepo: goalRepo,
      depositRepo: depositRepo,
      gamificationRepo: gamificationRepo,
    );
  });

  tearDown(() async {
    try {
      await Hive.close();
    } catch (_) {}
    try {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  group('Story 4.1 - Repositório: Motor de Cálculo de Streaks', () {
    test('Inicia streak com 1 no primeiro depósito', () async {
      expect(gamificationRepo.getCurrentStreak(), 0);
      expect(gamificationRepo.getLongestStreak(), 0);

      final streak =
          await gamificationRepo.registerDepositDate(DateTime(2026, 10, 10, 10, 0));

      expect(streak, 1);
      expect(gamificationRepo.getCurrentStreak(), 1);
      expect(gamificationRepo.getLongestStreak(), 1);
    });

    test('Mantém o mesmo streak ao registrar múltiplos depósitos no mesmo dia',
        () async {
      final day1Morning = DateTime(2026, 10, 10, 8, 30);
      final day1Night = DateTime(2026, 10, 10, 22, 15);

      await gamificationRepo.registerDepositDate(day1Morning);
      expect(gamificationRepo.getCurrentStreak(), 1);

      final streakAfterSecond =
          await gamificationRepo.registerDepositDate(day1Night);
      expect(streakAfterSecond, 1);
      expect(gamificationRepo.getCurrentStreak(), 1);
    });

    test('Incrementa streak em +1 para depósitos em dias consecutivos', () async {
      final day1 = DateTime(2026, 10, 10, 14, 0);
      final day2 = DateTime(2026, 10, 11, 9, 30);
      final day3 = DateTime(2026, 10, 12, 18, 0);

      await gamificationRepo.registerDepositDate(day1);
      expect(gamificationRepo.getCurrentStreak(), 1);

      await gamificationRepo.registerDepositDate(day2);
      expect(gamificationRepo.getCurrentStreak(), 2);
      expect(gamificationRepo.getLongestStreak(), 2);

      await gamificationRepo.registerDepositDate(day3);
      expect(gamificationRepo.getCurrentStreak(), 3);
      expect(gamificationRepo.getLongestStreak(), 3);
    });

    test('Reseta o streak para 1 ao quebrar a sequência de dias consecutivos',
        () async {
      final day1 = DateTime(2026, 10, 1, 10, 0);
      final day2 = DateTime(2026, 10, 2, 11, 0);
      final day5 = DateTime(2026, 10, 5, 12, 0); // 3 dias de intervalo!

      await gamificationRepo.registerDepositDate(day1);
      await gamificationRepo.registerDepositDate(day2);
      expect(gamificationRepo.getCurrentStreak(), 2);
      expect(gamificationRepo.getLongestStreak(), 2);

      // Depósito no dia 5 quebra a corrente
      final newStreak = await gamificationRepo.registerDepositDate(day5);
      expect(newStreak, 1);
      expect(gamificationRepo.getCurrentStreak(), 1);
      // O recorde (longestStreak) deve ser preservado!
      expect(gamificationRepo.getLongestStreak(), 2);
    });
  });

  group('Story 4.1 - Transação Atômica via RegisterDepositUseCase', () {
    test('Atualiza streak de forma atômica ao realizar depósito válido', () async {
      final goal = GoalModel(
        id: 'goal-streak-test',
        name: 'Celular Novo',
        targetAmount: 1000.0,
        savedAmount: 0.0,
        deadline: DateTime.now().add(const Duration(days: 30)),
        iconCodePoint: Icons.phone_android_rounded.codePoint,
        colorValue: 0xFF10B981,
        createdAt: DateTime.now(),
      );
      await goalRepo.save(goal);

      final result = await registerUseCase.execute(
        goalId: goal.id,
        amount: 50.0,
        note: 'Primeiro aporte',
      );

      expect(result, isNotNull);
      expect(result!.currentStreak, 1);
      expect(gamificationRepo.getCurrentStreak(), 1);
    });
  });

  group('Story 4.1 - Interface Gráfica: Badge 🔥 no Dashboard', () {
    testWidgets('Não exibe badge de fogo quando streak é 0', (tester) async {
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

      expect(find.text('🔥'), findsNothing);
    });

    testWidgets('Exibe badge de fogo com dias quando streak > 0',
        (tester) async {
      await tester.runAsync(() async {
        await gamificationRepo.registerDepositDate(DateTime.now());
      });

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

      expect(find.text('🔥'), findsOneWidget);
      expect(find.text('1 d'), findsOneWidget);
    });
  });
}
