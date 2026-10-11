import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cofrinho_digital/core/utils/economy_calculator.dart';
import 'package:cofrinho_digital/data/models/goal_model.dart';
import 'package:cofrinho_digital/data/models/deposit_model.dart';
import 'package:cofrinho_digital/data/repositories/goal_repository.dart';
import 'package:cofrinho_digital/core/providers/global_providers.dart';
import 'package:cofrinho_digital/features/goal_form/goal_form_provider.dart';
import 'package:cofrinho_digital/features/goal_form/goal_form_screen.dart';

void main() {
  late Directory tempDir;
  late GoalRepository repository;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('economy_test_');
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
    repository = GoalRepository();
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('EconomyCalculator Mathematical Precision Tests', () {
    test('Calcula corretamente modalidades para meta de R\$ 300 em 30 dias', () {
      final now = DateTime.now();
      final deadline = now.add(const Duration(days: 30));

      final modalities = EconomyCalculator.calculate(
        targetAmount: 300.0,
        savedAmount: 0.0,
        deadline: deadline,
      );

      expect(modalities.length, equals(3));

      // Diário: 300 / 30 = 10.0
      expect(modalities[0].iconAsset, equals('daily'));
      expect(modalities[0].amount, equals(10.0));
      expect(modalities[0].period, equals('por dia'));

      // Semanal: ceil(30/7) = 5 semanas -> 300 / 5 = 60.0
      expect(modalities[1].iconAsset, equals('weekly'));
      expect(modalities[1].amount, equals(60.0));
      expect(modalities[1].period, equals('por semana'));

      // Mensal: ceil(30/30) = 1 mês -> 300 / 1 = 300.0
      expect(modalities[2].iconAsset, equals('monthly'));
      expect(modalities[2].amount, equals(300.0));
      expect(modalities[2].period, equals('por mês'));
    });

    test('Arredonda para cima nos centavos (ceil) para evitar déficit no saldo', () {
      final now = DateTime.now();
      final deadline = now.add(const Duration(days: 3));

      final modalities = EconomyCalculator.calculate(
        targetAmount: 100.0,
        savedAmount: 0.0,
        deadline: deadline,
      );

      // 100 / 3 = 33.3333... -> ceilToCents = 33.34
      expect(modalities[0].amount, equals(33.34));
    });
  });

  group('GoalFormNotifier - Step 2 & Economy Mode Selection Tests', () {
    test('Salvar é bloqueado se nenhum modo de economia foi selecionado',
        () async {
      final notifier = GoalFormNotifier(repository);
      notifier.setName('Fundo de Emergência');
      notifier.setAmount('5000');
      notifier.setDeadline(DateTime.now().add(const Duration(days: 90)));

      // Avança para Passo 2
      final step1Success = notifier.nextStep();
      expect(step1Success, isTrue);
      expect(notifier.state.currentStep, equals(1));
      expect(notifier.state.selectedEconomyMode, isNull);

      // Tenta salvar sem modo
      final saved = await notifier.save();
      expect(saved, isFalse);
      expect(notifier.state.errorMessage,
          equals('Selecione um ritmo de economia para continuar'));
    });

    test('Salvar tem sucesso após selecionar modalidade de economia', () async {
      final notifier = GoalFormNotifier(repository);
      notifier.setName('Fundo de Emergência');
      notifier.setAmount('5000');
      notifier.setDeadline(DateTime.now().add(const Duration(days: 90)));
      notifier.nextStep();

      // Seleciona modalidade semanal
      notifier.setEconomyMode('weekly');
      expect(notifier.state.selectedEconomyMode, equals('weekly'));

      // Salva
      final saved = await notifier.save();
      expect(saved, isTrue);

      // Verifica persistência na box de metas
      final goals = repository.getActive();
      expect(goals.length, equals(1));
      expect(goals.first.name, equals('Fundo de Emergência'));
      expect(goals.first.targetAmount, equals(5000.0));
    });
  });

  group('GoalFormScreen Passo 2 Widget Tests', () {
    Widget buildWidget() {
      return ProviderScope(
        overrides: [
          goalRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(
          home: GoalFormScreen(),
        ),
      );
    }

    testWidgets('Navega para Passo 2 e permite selecionar modalidade de economia',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Preenche dados do Passo 1
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Ex: Viagem para Europa, Celular Novo...'),
          'Curso Flutter');
      await tester.enterText(
          find.widgetWithText(TextFormField, '0,00'), '450,00');

      // Avança para Passo 2
      final continueButton = find.text('Continuar para o Ritmo');
      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      // Verifica exibição do Passo 2 e das modalidades
      expect(find.text('Escolha seu ritmo de economia *'), findsOneWidget);
      expect(find.text('Economia Diária'), findsOneWidget);
      expect(find.text('Desafio Semanal'), findsOneWidget);
      expect(find.text('Depósito Mensal'), findsOneWidget);

      // Botão Salvar Meta deve estar desabilitado antes de selecionar ritmo
      final saveButtonFinder = find.widgetWithText(ElevatedButton, 'Salvar Meta');
      expect(saveButtonFinder, findsOneWidget);
      final ElevatedButton saveButtonBefore =
          tester.widget(saveButtonFinder) as ElevatedButton;
      expect(saveButtonBefore.onPressed, isNull);

      // Toca na modalidade Semanal
      await tester.tap(find.text('Desafio Semanal'));
      await tester.pumpAndSettle();

      // Botão Salvar Meta agora deve estar habilitado
      final ElevatedButton saveButtonAfter =
          tester.widget(saveButtonFinder) as ElevatedButton;
      expect(saveButtonAfter.onPressed, isNotNull);
    });
  });
}
