import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cofrinho_digital/data/models/goal_model.dart';
import 'package:cofrinho_digital/data/models/deposit_model.dart';
import 'package:cofrinho_digital/data/models/mascot_model.dart';
import 'package:cofrinho_digital/data/repositories/goal_repository.dart';
import 'package:cofrinho_digital/data/repositories/deposit_repository.dart';
import 'package:cofrinho_digital/data/repositories/gamification_repository.dart';
import 'package:cofrinho_digital/data/repositories/wallet_repository.dart';
import 'package:cofrinho_digital/data/repositories/mascot_repository.dart';
import 'package:cofrinho_digital/core/providers/global_providers.dart';
import 'package:cofrinho_digital/widgets/porko_canvas_widget.dart';
import 'package:cofrinho_digital/features/home/home_screen.dart';

void main() {
  late Directory tempDir;
  late GoalRepository goalRepo;
  late DepositRepository depositRepo;
  late GamificationRepository gamificationRepo;
  late WalletRepository walletRepo;
  late MascotRepository mascotRepo;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('porko_test_');
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
    mascotRepo = MascotRepository();
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Story 5.2: MascotModel e MascotRepository - Unit Tests', () {
    test('Inicializa com skin padrão rosa e persiste customizações no Hive',
        () async {
      final initial = mascotRepo.getMascot();
      expect(initial.skinId, equals('pink_classic'));
      expect(initial.hatId, isNull);

      final updated = await mascotRepo.equipItem(
        category: 'skin',
        itemId: 'golden',
      );
      expect(updated.skinId, equals('golden'));

      final fromBox = mascotRepo.getMascot();
      expect(fromBox.skinId, equals('golden'));

      await mascotRepo.equipItem(category: 'hat', itemId: 'hat_cap');
      expect(mascotRepo.getMascot().hatId, equals('hat_cap'));
    });
  });

  group('Story 5.2: porkoMoodProvider - State Evaluation Tests', () {
    test('Sem metas ativas: humor sleeping', () async {
      final containerRef = ProviderContainer(
        overrides: [
          goalRepositoryProvider.overrideWithValue(goalRepo),
          gamificationRepositoryProvider.overrideWithValue(gamificationRepo),
          walletRepositoryProvider.overrideWithValue(walletRepo),
          mascotRepositoryProvider.overrideWithValue(mascotRepo),
        ],
      );

      final mood = containerRef.read(porkoMoodProvider);
      expect(mood, equals(PorkoMood.sleeping));
    });

    test('Com meta ativa e sem streak alto: humor neutral', () async {
      await goalRepo.create(GoalModel(
        id: 'g-neutral',
        name: 'Meta Teste',
        targetAmount: 500.0,
        deadline: DateTime.now().add(const Duration(days: 30)),
        iconCodePoint: Icons.savings_rounded.codePoint,
        colorValue: 0xFF10B981,
        createdAt: DateTime.now(),
      ));

      final containerRef = ProviderContainer(
        overrides: [
          goalRepositoryProvider.overrideWithValue(goalRepo),
          gamificationRepositoryProvider.overrideWithValue(gamificationRepo),
          walletRepositoryProvider.overrideWithValue(walletRepo),
          mascotRepositoryProvider.overrideWithValue(mascotRepo),
        ],
      );

      final mood = containerRef.read(porkoMoodProvider);
      expect(mood, equals(PorkoMood.neutral));
    });

    test('Com streak >= 3: humor happy', () async {
      await goalRepo.create(GoalModel(
        id: 'g-happy',
        name: 'Meta Ativa',
        targetAmount: 500.0,
        deadline: DateTime.now().add(const Duration(days: 30)),
        iconCodePoint: Icons.savings_rounded.codePoint,
        colorValue: 0xFF10B981,
        createdAt: DateTime.now(),
      ));

      await gamificationRepo.registerDepositDate(DateTime(2026, 10, 1));
      await gamificationRepo.registerDepositDate(DateTime(2026, 10, 2));
      await gamificationRepo.registerDepositDate(DateTime(2026, 10, 3));

      final containerRef = ProviderContainer(
        overrides: [
          goalRepositoryProvider.overrideWithValue(goalRepo),
          gamificationRepositoryProvider.overrideWithValue(gamificationRepo),
          walletRepositoryProvider.overrideWithValue(walletRepo),
          mascotRepositoryProvider.overrideWithValue(mascotRepo),
        ],
      );

      final mood = containerRef.read(porkoMoodProvider);
      expect(mood, equals(PorkoMood.happy));
    });

    test('Com meta concluída (100%): humor celebrating', () async {
      await goalRepo.create(GoalModel(
        id: 'g-celebrating',
        name: 'Meta Vencida',
        targetAmount: 500.0,
        savedAmount: 500.0,
        deadline: DateTime.now().add(const Duration(days: 10)),
        iconCodePoint: Icons.check_circle_rounded.codePoint,
        colorValue: 0xFF10B981,
        createdAt: DateTime.now(),
      ));

      final containerRef = ProviderContainer(
        overrides: [
          goalRepositoryProvider.overrideWithValue(goalRepo),
          gamificationRepositoryProvider.overrideWithValue(gamificationRepo),
          walletRepositoryProvider.overrideWithValue(walletRepo),
          mascotRepositoryProvider.overrideWithValue(mascotRepo),
        ],
      );

      final mood = containerRef.read(porkoMoodProvider);
      expect(mood, equals(PorkoMood.celebrating));
    });
  });

  group('Story 5.2: PorkoCanvasWidget - Widget Tests', () {
    testWidgets('Renderiza balao de fala, mascote e pilula de humor',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PorkoCanvasWidget(
              mood: PorkoMood.happy,
              mascot: MascotModel(),
            ),
          ),
        ),
      );

      expect(find.byType(PorkoCanvasWidget), findsOneWidget);
      expect(find.textContaining('Porko • Animado!'), findsOneWidget);
      expect(find.textContaining('🔥'), findsOneWidget);

      // Toca no mascote para disparar micro-animação
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.byType(PorkoCanvasWidget), findsOneWidget);
    });

    testWidgets('HomeScreen integra PorkoCanvasWidget no Dashboard',
        (tester) async {
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

      // No estado vazio, o Porko sonolento deve estar visível
      expect(find.byType(PorkoCanvasWidget), findsOneWidget);
      expect(find.textContaining('Porko • Sonolento'), findsOneWidget);
      expect(find.textContaining('Zzz...'), findsOneWidget);
    });
  });
}
