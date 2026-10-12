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
import 'package:cofrinho_digital/widgets/milestone_map_card.dart';
import 'package:cofrinho_digital/features/goal_detail/goal_detail_screen.dart';

void main() {
  late Directory tempDir;
  late GoalRepository goalRepo;
  late DepositRepository depositRepo;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('milestone_map_test_');
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

  group('Story 4.2: MilestoneMapCard Tests', () {
    testWidgets('Exibe 4 marcos com 0 conquistados e próximo marco destacado em meta nova',
        (tester) async {
      final goal = GoalModel(
        id: 'goal-zero',
        name: 'Curso de Flutter',
        targetAmount: 1000.0,
        savedAmount: 0.0,
        deadline: DateTime.now().add(const Duration(days: 30)),
        iconCodePoint: Icons.school_rounded.codePoint,
        colorValue: 0xFF10B981,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MilestoneMapCard(
              goal: goal,
              goalColor: const Color(0xFF10B981),
            ),
          ),
        ),
      );

      expect(find.text('Trilha de Marcos'), findsOneWidget);
      expect(find.text('0 de 4 marcos conquistados'), findsOneWidget);
      expect(find.text('0/4'), findsOneWidget);

      // Títulos dos marcos
      expect(find.textContaining('Primeiro Passo'), findsOneWidget);
      expect(find.textContaining('Metade do Caminho'), findsOneWidget);
      expect(find.textContaining('Reta Final'), findsOneWidget);
      expect(find.textContaining('Meta Conquistada!'), findsOneWidget);

      // O marco de 25% é o próximo alvo
      expect(find.textContaining('Próximo marco: faltam R\$ 250,00'), findsOneWidget);

      // Os outros 3 estão aguardando
      expect(find.text('Aguardando marco anterior'), findsNWidgets(3));
    });

    testWidgets('Exibe marcos conquistados e próximo alvo para meta com 35% de progresso',
        (tester) async {
      final goal = GoalModel(
        id: 'goal-prog',
        name: 'Reserva',
        targetAmount: 1000.0,
        savedAmount: 350.0, // Atingiu 250 (25%), faltam 150 para 500 (50%)
        deadline: DateTime.now().add(const Duration(days: 45)),
        iconCodePoint: Icons.savings_rounded.codePoint,
        colorValue: 0xFF3B82F6,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MilestoneMapCard(
              goal: goal,
              goalColor: const Color(0xFF3B82F6),
            ),
          ),
        ),
      );

      expect(find.text('1 de 4 marcos conquistados'), findsOneWidget);
      expect(find.text('1/4'), findsOneWidget);

      // Marco 1 conquistado
      expect(find.text('Marco conquistado!'), findsOneWidget);

      // Marco 2 é o próximo alvo
      expect(find.textContaining('Próximo marco: faltam R\$ 150,00'), findsOneWidget);

      // Marcos 3 e 4 aguardando
      expect(find.text('Aguardando marco anterior'), findsNWidgets(2));
    });

    testWidgets('Exibe todos os 4 marcos conquistados e selo festivo quando 100%',
        (tester) async {
      final goal = GoalModel(
        id: 'goal-done',
        name: 'Meta Completa',
        targetAmount: 1000.0,
        savedAmount: 1000.0,
        deadline: DateTime.now().add(const Duration(days: 10)),
        iconCodePoint: Icons.done_all_rounded.codePoint,
        colorValue: 0xFF10B981,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MilestoneMapCard(
              goal: goal,
              goalColor: const Color(0xFF10B981),
            ),
          ),
        ),
      );

      expect(find.text('4 de 4 marcos conquistados'), findsOneWidget);
      expect(find.text('🎉 100% Concluído'), findsOneWidget);

      // Todos os 4 conquistados
      expect(find.text('Marco conquistado!'), findsNWidgets(4));
      expect(find.text('Aguardando marco anterior'), findsNothing);
    });

    testWidgets('Tocar em um marco exibe modal de detalhes com informações e fecha com botão',
        (tester) async {
      final goal = GoalModel(
        id: 'goal-modal',
        name: 'Viagem',
        targetAmount: 1000.0,
        savedAmount: 250.0,
        deadline: DateTime.now().add(const Duration(days: 20)),
        iconCodePoint: Icons.flight_rounded.codePoint,
        colorValue: 0xFF10B981,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MilestoneMapCard(
              goal: goal,
              goalColor: const Color(0xFF10B981),
            ),
          ),
        ),
      );

      // Toca no primeiro marco (25%)
      await tester.tap(find.textContaining('Primeiro Passo'));
      await tester.pumpAndSettle();

      // Modal aberto
      expect(find.textContaining('O início da jornada'), findsOneWidget);
      expect(find.text('Entendido'), findsOneWidget);

      // Clica em "Entendido" para fechar
      await tester.tap(find.text('Entendido'));
      await tester.pumpAndSettle();

      expect(find.text('Entendido'), findsNothing);
    });

    testWidgets('GoalDetailScreen integra MilestoneMapCard com sucesso',
        (tester) async {
      final goal = GoalModel(
        id: 'goal-detail-integration',
        name: 'Meta Integração',
        targetAmount: 800.0,
        savedAmount: 200.0,
        deadline: DateTime.now().add(const Duration(days: 30)),
        iconCodePoint: Icons.home_rounded.codePoint,
        colorValue: 0xFF10B981,
        createdAt: DateTime.now(),
      );

      await tester.runAsync(() async {
        await goalRepo.create(goal);
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            goalRepositoryProvider.overrideWithValue(goalRepo),
            depositRepositoryProvider.overrideWithValue(depositRepo),
          ],
          child: MaterialApp(
            home: GoalDetailScreen(goalId: goal.id),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verifica que MilestoneMapCard foi renderizado dentro de GoalDetailScreen
      expect(find.byType(MilestoneMapCard), findsOneWidget);
      expect(find.text('Trilha de Marcos'), findsOneWidget);
      expect(find.text('1 de 4 marcos conquistados'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });
  });
}
