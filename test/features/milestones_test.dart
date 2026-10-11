import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cofrinho_digital/data/models/goal_model.dart';
import 'package:cofrinho_digital/data/models/deposit_model.dart';
import 'package:cofrinho_digital/data/repositories/goal_repository.dart';
import 'package:cofrinho_digital/widgets/goal_card.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('milestones_test_');
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
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Milestones Automatic Generation Unit Tests', () {
    test('Gera automaticamente 4 marcos de 25%, 50%, 75% e 100% do valor-alvo', () {
      final goal = GoalModel(
        id: 'goal-1',
        name: 'Notebook Novo',
        targetAmount: 2000.0,
        deadline: DateTime.now().add(const Duration(days: 60)),
        iconCodePoint: Icons.laptop_mac_rounded.codePoint,
        colorValue: 0xFF10B981,
        createdAt: DateTime.now(),
      );

      final milestones = goal.milestoneAmounts;
      expect(milestones.length, equals(4));
      expect(milestones[0], equals(500.0));
      expect(milestones[1], equals(1000.0));
      expect(milestones[2], equals(1500.0));
      expect(milestones[3], equals(2000.0));
    });

    test('Calcula completedMilestonesCount corretamente conforme o saldo economizado', () {
      final goal = GoalModel(
        id: 'goal-2',
        name: 'Viagem',
        targetAmount: 1000.0,
        savedAmount: 0.0,
        deadline: DateTime.now().add(const Duration(days: 90)),
        iconCodePoint: Icons.flight_takeoff_rounded.codePoint,
        colorValue: 0xFF3B82F6,
        createdAt: DateTime.now(),
      );

      // Com saldo 0: 0 marcos
      expect(goal.completedMilestonesCount, equals(0));

      // Com saldo 250 (25%): 1 marco
      goal.savedAmount = 250.0;
      expect(goal.completedMilestonesCount, equals(1));

      // Com saldo 600 (ultrapassou 50%): 2 marcos
      goal.savedAmount = 600.0;
      expect(goal.completedMilestonesCount, equals(2));

      // Com saldo 800 (ultrapassou 75%): 3 marcos
      goal.savedAmount = 800.0;
      expect(goal.completedMilestonesCount, equals(3));

      // Com saldo 1000 (100%): 4 marcos
      goal.savedAmount = 1000.0;
      expect(goal.completedMilestonesCount, equals(4));
    });
  });

  group('GoalCard Milestone Nodes & Pill Widget Tests', () {
    testWidgets('GoalCard deve exibir os 4 rótulos de marcos (25%, 50%, 75%, 100%)',
        (WidgetTester tester) async {
      final goal = GoalModel(
        id: 'goal-3',
        name: 'Carro Novo',
        targetAmount: 40000.0,
        savedAmount: 15000.0,
        deadline: DateTime.now().add(const Duration(days: 300)),
        iconCodePoint: Icons.directions_car_rounded.codePoint,
        colorValue: 0xFF8B5CF6,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GoalCard(
              goal: goal,
              onTap: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verifica exibição dos rótulos dos marcos
      expect(find.text('25%'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
      expect(find.text('75%'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);

      // Verifica exibição do nome e valores
      expect(find.text('Carro Novo'), findsOneWidget);
      expect(find.text('Guardado'), findsOneWidget);
      expect(find.text('Meta'), findsOneWidget);
    });
  });
}
