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
import 'package:cofrinho_digital/features/deposit/deposit_screen.dart';

void main() {
  late Directory tempDir;
  late GoalRepository goalRepo;
  late DepositRepository depositRepo;
  late GoalModel testGoal;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('deposit_test_');
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
      id: 'goal-dep-1',
      name: 'Reserva de Emergência',
      targetAmount: 500.0,
      savedAmount: 100.0, // Faltam 400.0
      deadline: DateTime.now().add(const Duration(days: 30)),
      iconCodePoint: Icons.savings_rounded.codePoint,
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

  Widget createWidgetUnderTest({GoalModel? goal}) {
    return ProviderScope(
      overrides: [
        goalRepositoryProvider.overrideWithValue(goalRepo),
        depositRepositoryProvider.overrideWithValue(depositRepo),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: DepositScreen(
            goal: goal ?? testGoal,
          ),
        ),
      ),
    );
  }

  group('DepositScreen Story 2.1 Widget & Logic Tests', () {
    testWidgets('Deve exibir todos os chips de valores rápidos (+R\$ 10 a +R\$ 200)',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('+R\$ 10'), findsOneWidget);
      expect(find.text('+R\$ 25'), findsOneWidget);
      expect(find.text('+R\$ 50'), findsOneWidget);
      expect(find.text('+R\$ 100'), findsOneWidget);
      expect(find.text('+R\$ 200'), findsOneWidget);
    });

    testWidgets(
        'Tocar no chip rápido deve preencher o campo e exibir preview de Oinc Coins',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Clica no chip +R$ 50
      await tester.tap(find.text('+R\$ 50'));
      await tester.pumpAndSettle();

      // Verifica preenchimento do campo
      expect(find.text('50,00'), findsOneWidget);

      // Verifica preview dinâmico de Oinc Coins (UX-DR3)
      expect(find.text('+50 Oinc Coins serão adicionadas!'), findsOneWidget);

      // Botão Confirmar Depósito deve estar habilitado
      final buttonFinder =
          find.widgetWithText(ElevatedButton, 'Confirmar Depósito');
      final ElevatedButton button = tester.widget(buttonFinder);
      expect(button.onPressed, isNotNull);
    });

    testWidgets('Botão de confirmação deve estar desabilitado com campo vazio',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final buttonFinder =
          find.widgetWithText(ElevatedButton, 'Confirmar Depósito');
      final ElevatedButton button = tester.widget(buttonFinder);
      expect(button.onPressed, isNull);
    });

    testWidgets(
        'Digitar valor superior ao saldo restante deve bloquear botão e exibir erro',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // testGoal tem target 500 e saved 100 -> restante é 400
      // Digita 450,00 (excede 400)
      final inputFinder = find.byType(TextFormField).first;
      await tester.enterText(inputFinder, '450,00');
      await tester.pumpAndSettle();

      // Botão deve ser bloqueado
      final buttonFinder =
          find.widgetWithText(ElevatedButton, 'Confirmar Depósito');
      final ElevatedButton button = tester.widget(buttonFinder);
      expect(button.onPressed, isNull);

      // Verifica mensagem de erro contra limite de saldo
      expect(find.textContaining('O valor não pode ultrapassar o saldo restante'),
          findsOneWidget);
    });

    testWidgets(
        'Confirmar depósito válido deve salvar registro, atualizar meta e exibir feedback',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Toca no chip +R$ 100
      await tester.tap(find.text('+R\$ 100'));
      await tester.pumpAndSettle();

      // Toca no botão Confirmar Depósito
      final buttonFinder =
          find.widgetWithText(ElevatedButton, 'Confirmar Depósito');
      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();

      // Verifica que o depósito foi persistido no repositório
      final deposits = depositRepo.getByGoal(testGoal.id);
      expect(deposits.length, equals(1));
      expect(deposits.first.amount, equals(100.0));

      // Verifica que a meta teve seu saldo acumulado incrementado (100 + 100 = 200)
      final updatedGoal = goalRepo.getById(testGoal.id);
      expect(updatedGoal?.savedAmount, equals(200.0));
    });
  });
}
