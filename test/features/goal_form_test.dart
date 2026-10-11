import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
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
    tempDir = await Directory.systemTemp.createTemp('goal_form_test_');
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

  group('GoalFormNotifier - Step 1 Validation Tests', () {
    test('Deve barrar nome vazio', () {
      final notifier = GoalFormNotifier(repository);
      notifier.setAmount('500');
      notifier.setDeadline(DateTime.now().add(const Duration(days: 30)));

      final success = notifier.nextStep();
      expect(success, isFalse);
      expect(notifier.state.errorMessage, equals('Informe o nome da meta'));
      expect(notifier.state.currentStep, equals(0));
    });

    test('Deve barrar nome com mais de 40 caracteres', () {
      final notifier = GoalFormNotifier(repository);
      notifier.setName('A' * 41);
      notifier.setAmount('500');
      notifier.setDeadline(DateTime.now().add(const Duration(days: 30)));

      final success = notifier.nextStep();
      expect(success, isFalse);
      expect(notifier.state.errorMessage,
          equals('O nome deve ter no máximo 40 caracteres'));
      expect(notifier.state.currentStep, equals(0));
    });

    test('Deve barrar valor <= 0', () {
      final notifier = GoalFormNotifier(repository);
      notifier.setName('Viagem');
      notifier.setAmount('0');
      notifier.setDeadline(DateTime.now().add(const Duration(days: 30)));

      final success = notifier.nextStep();
      expect(success, isFalse);
      expect(notifier.state.errorMessage, equals('Informe um valor maior que zero'));
      expect(notifier.state.currentStep, equals(0));
    });

    test('Deve barrar prazo sem seleção ou retroativo/hoje', () {
      final notifier = GoalFormNotifier(repository);
      notifier.setName('Viagem');
      notifier.setAmount('500');

      // Sem prazo
      var success = notifier.nextStep();
      expect(success, isFalse);
      expect(notifier.state.errorMessage,
          equals('Selecione a data limite da meta'));

      // Prazo para hoje
      final now = DateTime.now();
      notifier.setDeadline(DateTime(now.year, now.month, now.day));
      success = notifier.nextStep();
      expect(success, isFalse);
      expect(notifier.state.errorMessage,
          equals('O prazo deve ser uma data futura'));
      expect(notifier.state.currentStep, equals(0));
    });

    test('Deve avançar para Passo 2 quando todos os campos do Passo 1 forem válidos',
        () {
      final notifier = GoalFormNotifier(repository);
      notifier.setName('Celular Novo');
      notifier.setAmount('2500,00');
      notifier.setDeadline(DateTime.now().add(const Duration(days: 60)));

      final success = notifier.nextStep();
      expect(success, isTrue);
      expect(notifier.state.errorMessage, isNull);
      expect(notifier.state.currentStep, equals(1));
    });
  });

  group('GoalFormScreen Widget Tests', () {
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

    testWidgets('Deve exibir cabeçalho de passos e campos do Passo 1',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('Identidade e Valor'), findsOneWidget);
      expect(find.text('Ritmo de Economia'), findsOneWidget);
      expect(find.text('Nome da meta *'), findsOneWidget);
      expect(find.text('Valor alvo da meta *'), findsOneWidget);
      expect(find.text('Data limite (Prazo) *'), findsOneWidget);
      expect(find.text('Continuar para o Ritmo'), findsOneWidget);
    });

    testWidgets('Tentar avançar sem preencher campos deve exibir erro na tela',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      final continueButton = find.text('Continuar para o Ritmo');
      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      // Verifica exibição do banner de erro
      expect(find.text('Informe o nome da meta'), findsOneWidget);
    });
  });
}
