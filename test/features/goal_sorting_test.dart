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
import 'package:cofrinho_digital/data/repositories/mascot_repository.dart';
import 'package:cofrinho_digital/core/providers/global_providers.dart';
import 'package:cofrinho_digital/features/home/home_screen.dart';
import 'package:cofrinho_digital/features/home/home_provider.dart';

void main() {
  late Directory tempDir;
  late GoalRepository goalRepo;
  late DepositRepository depositRepo;
  late GoalModel goalRecentLowProgress;
  late GoalModel goalMidDeadlineHighProgress;
  late GoalModel goalOldUrgentDeadline;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('sorting_test_');
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
    await Hive.openBox('badges');
    await Hive.openBox('mascot_box');

    goalRepo = GoalRepository();
    depositRepo = DepositRepository();

    final baseTime = DateTime(2026, 10, 1, 10, 0);

    // Meta 1: Mais recente (criada em 10/10), prazo longo (60 dias), progresso baixo (10%)
    goalRecentLowProgress = GoalModel(
      id: 'sort-recent',
      name: 'Meta Recente',
      targetAmount: 1000.0,
      savedAmount: 100.0, // 10%
      deadline: DateTime.now().add(const Duration(days: 60)),
      iconCodePoint: Icons.computer_rounded.codePoint,
      colorValue: 0xFF10B981,
      createdAt: baseTime.add(const Duration(days: 10)),
    );

    // Meta 2: Criada intermediária (05/10), prazo médio (30 dias), progresso alto (80%)
    goalMidDeadlineHighProgress = GoalModel(
      id: 'sort-high-prog',
      name: 'Meta Alto Progresso',
      targetAmount: 1000.0,
      savedAmount: 800.0, // 80%
      deadline: DateTime.now().add(const Duration(days: 30)),
      iconCodePoint: Icons.flight_takeoff_rounded.codePoint,
      colorValue: 0xFF3B82F6,
      createdAt: baseTime.add(const Duration(days: 5)),
    );

    // Meta 3: Mais antiga (01/10), prazo mais urgente (5 dias), progresso médio (50%)
    goalOldUrgentDeadline = GoalModel(
      id: 'sort-urgent',
      name: 'Meta Urgente',
      targetAmount: 1000.0,
      savedAmount: 500.0, // 50%
      deadline: DateTime.now().add(const Duration(days: 5)),
      iconCodePoint: Icons.alarm_rounded.codePoint,
      colorValue: 0xFFEF4444,
      createdAt: baseTime,
    );

    await goalRepo.save(goalRecentLowProgress);
    await goalRepo.save(goalMidDeadlineHighProgress);
    await goalRepo.save(goalOldUrgentDeadline);
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

  group('Story 3.2 - Repositório: Regras de Ordenação de Metas', () {
    test('Ordena por createdAt (Mais recentes no topo)', () {
      final list = goalRepo.getActive(order: SortOrder.createdAt);
      expect(list.length, 3);
      expect(list[0].id, 'sort-recent');
      expect(list[1].id, 'sort-high-prog');
      expect(list[2].id, 'sort-urgent');
    });

    test('Ordena por deadline (Prazos mais próximos no topo)', () {
      final list = goalRepo.getActive(order: SortOrder.deadline);
      expect(list.length, 3);
      expect(list[0].id, 'sort-urgent'); // 5 dias
      expect(list[1].id, 'sort-high-prog'); // 30 dias
      expect(list[2].id, 'sort-recent'); // 60 dias
    });

    test('Ordena por progress (Maior porcentagem concluída no topo)', () {
      final list = goalRepo.getActive(order: SortOrder.progress);
      expect(list.length, 3);
      expect(list[0].id, 'sort-high-prog'); // 80%
      expect(list[1].id, 'sort-urgent'); // 50%
      expect(list[2].id, 'sort-recent'); // 10%
    });
  });

  group('Story 3.2 - SortOrderNotifier e Persistência no Hive', () {
    test('Inicializa com SortOrder.createdAt quando nada estiver salvo', () {
      final notifier = SortOrderNotifier();
      expect(notifier.state, SortOrder.createdAt);
    });

    test('Persiste a preferência selecionada no Hive e restaura na inicialização',
        () async {
      final notifier = SortOrderNotifier();

      // Altera para 'deadline'
      await notifier.setOrder(SortOrder.deadline);
      expect(notifier.state, SortOrder.deadline);

      final settingsBox = Hive.box('settings');
      expect(settingsBox.get('goal_sort_order'), 'deadline');

      // Cria uma nova instância para simular reabertura do app
      final restoredNotifier = SortOrderNotifier();
      expect(restoredNotifier.state, SortOrder.deadline);

      // Altera para 'progress'
      await restoredNotifier.setOrder(SortOrder.progress);
      expect(settingsBox.get('goal_sort_order'), 'progress');

      final finalNotifier = SortOrderNotifier();
      expect(finalNotifier.state, SortOrder.progress);
    });
  });

  group('Story 3.2 - Interface Gráfica: Menu de Ordenação no Dashboard', () {
    testWidgets('Alterna ordenação via PopupMenuButton na HomeScreen',
        (tester) async {
      final gamificationRepo = GamificationRepository();
      final walletRepo = WalletRepository();
      final mascotRepo = MascotRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            goalRepositoryProvider.overrideWithValue(goalRepo),
            depositRepositoryProvider.overrideWithValue(depositRepo),
            gamificationRepositoryProvider.overrideWithValue(gamificationRepo),
            walletRepositoryProvider.overrideWithValue(walletRepo),
            mascotRepositoryProvider.overrideWithValue(mascotRepo),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Abre menu sanduíche de filtro e ordenação (Sprint 3 - AUD-08)
      final filterButton = find.byIcon(Icons.menu_rounded);
      expect(filterButton, findsOneWidget);
      await tester.tap(filterButton);
      await tester.pumpAndSettle();

      // Opções do sheet devem estar visíveis com ícones e labels
      expect(find.text('Filtrar e Ordenar Metas'), findsOneWidget);
      expect(find.text('Mais recentes'), findsWidgets);
      expect(find.text('Prazo mais próximo'), findsOneWidget);
      expect(find.text('Maior progresso (%)'), findsOneWidget);

      // Seleciona "Prazo mais próximo"
      await tester.tap(find.text('Prazo mais próximo'));
      await tester.pumpAndSettle();

      // Verifica se a preferência foi salva no Hive
      final settingsBox = Hive.box('settings');
      expect(settingsBox.get('goal_sort_order'), 'deadline');
    });
  });
}
