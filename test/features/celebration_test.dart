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
import 'package:cofrinho_digital/core/providers/global_providers.dart';
import 'package:cofrinho_digital/widgets/celebration_overlay.dart';
import 'package:cofrinho_digital/features/deposit/deposit_screen.dart';

void main() {
  late Directory tempDir;
  late GoalRepository goalRepo;
  late DepositRepository depositRepo;
  late GamificationRepository gamificationRepo;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('celebration_test_');
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

  group('Story 4.4: CelebrationOverlay Tests', () {
    testWidgets('showGoalCompleted renderiza modal com trofeu, nome da meta e botao continuar',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () => CelebrationOverlay.showGoalCompleted(
                    context,
                    goalName: 'Novo Carro',
                  ),
                  child: const Text('Disparar'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Disparar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('🏆'), findsOneWidget);
      expect(find.text('Meta Atingida!'), findsOneWidget);
      expect(find.textContaining('Novo Carro'), findsOneWidget);
      expect(find.text('Continuar ✨'), findsOneWidget);

      // Clica em Continuar para fechar
      await tester.tap(find.text('Continuar ✨'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Meta Atingida!'), findsNothing);
    });

    testWidgets('showMilestoneReached renderiza modal com alvo e percentual',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () => CelebrationOverlay.showMilestoneReached(
                    context,
                    goalName: 'Reserva de Emergência',
                    milestonePercent: 50,
                  ),
                  child: const Text('Disparar Marco'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Disparar Marco'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('🎯'), findsOneWidget);
      expect(find.text('Novo Marco Conquistado!'), findsOneWidget);
      expect(find.textContaining('50% da meta'), findsOneWidget);
    });

    testWidgets('showBadgeUnlocked renderiza modal com emblema e titulo do badge',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () => CelebrationOverlay.showBadgeUnlocked(
                    context,
                    badgeTitle: 'Semana de Ouro',
                  ),
                  child: const Text('Disparar Badge'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Disparar Badge'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('🏅'), findsOneWidget);
      expect(find.text('Conquista Desbloqueada!'), findsOneWidget);
      expect(find.textContaining('Semana de Ouro'), findsOneWidget);
    });

    testWidgets('Auto-dismiss fecha o overlay suavemente apos duracao do timer',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () => CelebrationOverlay.showGoalCompleted(
                    context,
                    goalName: 'Auto Dismiss Test',
                  ),
                  child: const Text('Disparar'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Disparar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Meta Atingida!'), findsOneWidget);

      // Aguarda o auto-dismiss de 2.2s + fade out
      await tester.pump(const Duration(milliseconds: 2300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Meta Atingida!'), findsNothing);
    });

    testWidgets('DepositScreen dispara celebracao ao concluir a meta',
        (tester) async {
      final goal = GoalModel(
        id: 'goal-celeb',
        name: 'Celular Novo',
        targetAmount: 500.0,
        savedAmount: 400.0,
        deadline: DateTime.now().add(const Duration(days: 30)),
        iconCodePoint: Icons.phone_android_rounded.codePoint,
        colorValue: 0xFF10B981,
        createdAt: DateTime.now(),
      );
      await goalRepo.create(goal);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            goalRepositoryProvider.overrideWithValue(goalRepo),
            depositRepositoryProvider.overrideWithValue(depositRepo),
            gamificationRepositoryProvider.overrideWithValue(gamificationRepo),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    builder: (_) => DepositScreen(goal: goal),
                  ),
                  child: const Text('Abrir Depósito'),
                ),
              ),
            ),
          ),
        ),
      );

      // Abre bottom sheet de depósito
      await tester.tap(find.text('Abrir Depósito'));
      await tester.pumpAndSettle();

      // Clica no chip de R$ 100 para completar os 500
      await tester.tap(find.text('+R\$ 100'));
      await tester.pumpAndSettle();

      // Clica no botão de confirmar depósito
      await tester.tap(find.text('Confirmar Depósito'));
      await tester.pumpAndSettle();

      // Verifica que o overlay de celebração foi aberto
      expect(find.text('Meta Atingida!'), findsOneWidget);
      expect(find.textContaining('Celular Novo'), findsOneWidget);
    });
  });
}
