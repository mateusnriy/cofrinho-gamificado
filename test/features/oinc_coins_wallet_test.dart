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
import 'package:cofrinho_digital/data/repositories/wallet_repository.dart';
import 'package:cofrinho_digital/domain/usecases/register_deposit_use_case.dart';
import 'package:cofrinho_digital/core/providers/global_providers.dart';
import 'package:cofrinho_digital/features/home/home_screen.dart';

void main() {
  late Directory tempDir;
  late GoalRepository goalRepo;
  late DepositRepository depositRepo;
  late GamificationRepository gamificationRepo;
  late WalletRepository walletRepo;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wallet_test_');
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
    walletRepo = WalletRepository();
  });

  tearDown(() async {
    try {
      await Hive.close().timeout(const Duration(milliseconds: 200), onTimeout: () => null);
    } catch (_) {}
    try {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  group('Story 5.1: WalletRepository - Unit Tests', () {
    test('Inicializa com saldo 0 e adiciona moedas corretamente', () async {
      expect(walletRepo.getBalance(), equals(0));

      final balance1 = await walletRepo.addCoins(45);
      expect(balance1, equals(45));
      expect(walletRepo.getBalance(), equals(45));

      final balance2 = await walletRepo.addCoins(25);
      expect(balance2, equals(70));
      expect(walletRepo.getBalance(), equals(70));
    });

    test('Deduz moedas respeitando a invariante de saldo não-negativo (RN-13)',
        () async {
      await walletRepo.addCoins(50);
      expect(walletRepo.getBalance(), equals(50));

      final afterDeduct = await walletRepo.deductCoins(20);
      expect(afterDeduct, equals(30));
      expect(walletRepo.getBalance(), equals(30));

      // Tenta deduzir mais moedas do que tem: trava em 0
      final clamped = await walletRepo.deductCoins(100);
      expect(clamped, equals(0));
      expect(walletRepo.getBalance(), equals(0));
    });

    test('claimDailyBonusIfEligible concede +50 apenas no primeiro depósito de cada dia',
        () async {
      final day1 = DateTime(2026, 10, 11, 9, 30);
      final day1Second = DateTime(2026, 10, 11, 14, 00);
      final day2 = DateTime(2026, 10, 12, 10, 15);

      // Primeiro resgate no dia 1
      final bonus1 = await walletRepo.claimDailyBonusIfEligible(day1);
      expect(bonus1, isTrue);
      expect(walletRepo.getBalance(), equals(50));

      // Segundo resgate no mesmo dia 1: não concede
      final bonus2 = await walletRepo.claimDailyBonusIfEligible(day1Second);
      expect(bonus2, isFalse);
      expect(walletRepo.getBalance(), equals(50));

      // Resgate no dia 2: concede novamente
      final bonus3 = await walletRepo.claimDailyBonusIfEligible(day2);
      expect(bonus3, isTrue);
      expect(walletRepo.getBalance(), equals(100));
    });
  });

  group('Story 5.1: RegisterDepositUseCase com Oinc Coins', () {
    test('Calcula moedas base por real depositado e adiciona bonus diario no 1o deposito',
        () async {
      final useCase = RegisterDepositUseCase(
        goalRepo: goalRepo,
        depositRepo: depositRepo,
        gamificationRepo: gamificationRepo,
        walletRepo: walletRepo,
      );

      final goal = GoalModel(
        id: 'g-coins-1',
        name: 'Férias',
        targetAmount: 500.0,
        deadline: DateTime.now().add(const Duration(days: 30)),
        iconCodePoint: Icons.beach_access_rounded.codePoint,
        colorValue: 0xFF10B981,
        createdAt: DateTime.now(),
      );
      await goalRepo.create(goal);

      // 1º depósito do dia de R$ 35,80: 35 moedas base + 50 bônus = 85
      final result1 = await useCase.execute(
        goalId: goal.id,
        amount: 35.80,
      );

      expect(result1, isNotNull);
      expect(result1!.dailyBonusEarned, isTrue);
      expect(result1.coinsEarned, equals(85));
      expect(walletRepo.getBalance(), equals(85));

      // 2º depósito do mesmo dia de R$ 20,00: 20 moedas base + 0 bônus = 20
      final result2 = await useCase.execute(
        goalId: goal.id,
        amount: 20.0,
      );

      expect(result2, isNotNull);
      expect(result2!.dailyBonusEarned, isFalse);
      expect(result2.coinsEarned, equals(20));
      expect(walletRepo.getBalance(), equals(105));
    });
  });

  group('Story 5.1: HomeScreen - Widget Tests para Oinc Coins', () {
    testWidgets('Exibe pilula de saldo de Oinc Coins no cabecalho e responde ao toque',
        (tester) async {
      await tester.runAsync(() async {
        await walletRepo.addCoins(135);
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            goalRepositoryProvider.overrideWithValue(goalRepo),
            depositRepositoryProvider.overrideWithValue(depositRepo),
            gamificationRepositoryProvider.overrideWithValue(gamificationRepo),
            walletRepositoryProvider.overrideWithValue(walletRepo),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Encontra a pílula de saldo com ícone de moeda e o valor 135
      expect(find.text('🪙'), findsWidgets);
      expect(find.text('135'), findsOneWidget);

      // Toca na pílula de moedas para exibir o SnackBar
      await tester.tap(find.text('135'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Saldo: 135 Oinc Coins'), findsOneWidget);
    });
  });
}
