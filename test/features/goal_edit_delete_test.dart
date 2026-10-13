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
import 'package:cofrinho_digital/features/goal_form/goal_form_provider.dart';
import 'package:cofrinho_digital/features/goal_detail/goal_detail_screen.dart';

void main() {
  late Directory tempDir;
  late GoalRepository goalRepo;
  late DepositRepository depositRepo;
  late GoalModel initialGoal;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('edit_delete_test_');
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

    initialGoal = GoalModel(
      id: 'goal-edit-123',
      name: 'Comprar Notebook',
      targetAmount: 5000.0,
      savedAmount: 1500.0, // R$ 1.500 já economizados
      deadline: DateTime.now().add(const Duration(days: 60)),
      iconCodePoint: Icons.laptop_mac_rounded.codePoint,
      colorValue: 0xFF8B5CF6,
      createdAt: DateTime(2026, 9, 1, 10, 0),
    );
    await goalRepo.save(initialGoal);

    // Salva depósitos associados
    await depositRepo.save(DepositModel(
      id: 'dep-assoc-1',
      goalId: initialGoal.id,
      amount: 1000.0,
      date: DateTime(2026, 9, 15),
    ));
    await depositRepo.save(DepositModel(
      id: 'dep-assoc-2',
      goalId: initialGoal.id,
      amount: 500.0,
      date: DateTime(2026, 9, 30),
    ));

    // Salva depósito de outra meta
    await depositRepo.save(DepositModel(
      id: 'dep-other-goal',
      goalId: 'other-goal-777',
      amount: 200.0,
      date: DateTime.now(),
    ));
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

  group('Story 2.4 - Validações de Edição de Metas', () {
    test('Bloqueia valor-alvo menor que o saldo acumulado (savedAmount)', () {
      final container = ProviderContainer(
        overrides: [
          goalRepositoryProvider.overrideWithValue(goalRepo),
        ],
      );

      final notifier = container.read(goalFormProvider.notifier);
      notifier.loadFromExisting(initialGoal);

      // Tenta definir alvo de R$ 1.200 (menor que os R$ 1.500 já economizados)
      notifier.setAmount('1200,00');

      final canAdvance = notifier.nextStep(existingGoal: initialGoal);
      expect(canAdvance, isFalse);

      final state = container.read(goalFormProvider);
      expect(state.errorMessage, contains('O novo valor não pode ser menor'));
      expect(state.errorMessage, contains('R\$ 1.500,00'));
      expect(state.currentStep, 0); // Permanece no passo 1
    });

    test('Permite avançar e salvar quando valor-alvo é maior ou igual ao saldo economizado',
        () async {
      final container = ProviderContainer(
        overrides: [
          goalRepositoryProvider.overrideWithValue(goalRepo),
        ],
      );

      final notifier = container.read(goalFormProvider.notifier);
      notifier.loadFromExisting(initialGoal);

      // Aumenta a meta para R$ 6.000
      notifier.setAmount('6000,00');
      notifier.setName('Notebook Gamer Pro');

      final canAdvance = notifier.nextStep(existingGoal: initialGoal);
      expect(canAdvance, isTrue);

      final saved = await notifier.save(existingId: initialGoal.id);
      expect(saved, isTrue);

      final updated = goalRepo.getById(initialGoal.id);
      expect(updated, isNotNull);
      expect(updated!.targetAmount, 6000.0);
      expect(updated.name, 'Notebook Gamer Pro');
      // Invariantes preservados
      expect(updated.savedAmount, 1500.0);
      expect(updated.createdAt, initialGoal.createdAt);
      expect(updated.isArchived, isFalse);
    });
  });

  group('Story 2.4 - Exclusão Segura em Cascata', () {
    test('Exclusão de meta remove todos os depósitos associados sem afetar outros',
        () async {
      expect(depositRepo.getByGoal(initialGoal.id).length, 2);
      expect(depositRepo.getByGoal('other-goal-777').length, 1);

      // Executa exclusão em cascata
      await depositRepo.deleteAllByGoal(initialGoal.id);
      await goalRepo.delete(initialGoal.id);

      // Meta foi removida
      expect(goalRepo.getById(initialGoal.id), isNull);

      // Depósitos associados foram apagados
      expect(depositRepo.getByGoal(initialGoal.id).length, 0);

      // Depósitos de outras metas permanecem intactos
      expect(depositRepo.getByGoal('other-goal-777').length, 1);
    });

    testWidgets('Diálogo de exclusão cancelada mantém a meta intacta',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            goalRepositoryProvider.overrideWithValue(goalRepo),
            depositRepositoryProvider.overrideWithValue(depositRepo),
          ],
          child: MaterialApp(
            home: GoalDetailScreen(goalId: initialGoal.id),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Abre menu popup
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      // Clica em 'Excluir meta'
      await tester.tap(find.text('Excluir meta'));
      await tester.pumpAndSettle();

      // Diálogo de confirmação deve estar visível
      expect(find.text('Excluir meta permanentemente?'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);

      // Clica em Cancelar
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      // Meta ainda existe no repositório
      expect(goalRepo.getById(initialGoal.id), isNotNull);
      expect(depositRepo.getByGoal(initialGoal.id).length, 2);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Diálogo de exclusão confirmada apaga meta e depósitos',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            goalRepositoryProvider.overrideWithValue(goalRepo),
            depositRepositoryProvider.overrideWithValue(depositRepo),
          ],
          child: MaterialApp(
            home: GoalDetailScreen(goalId: initialGoal.id),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Abre menu popup
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      // Clica em 'Excluir meta'
      await tester.tap(find.text('Excluir meta'));
      await tester.pumpAndSettle();

      // Clica em Excluir
      await tester.tap(find.text('Excluir'));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();

      // Meta e depósitos foram removidos do repositório
      expect(goalRepo.getById(initialGoal.id), isNull);
      expect(depositRepo.getByGoal(initialGoal.id).length, 0);

      await tester.pumpWidget(const SizedBox());
    });
  });
}
