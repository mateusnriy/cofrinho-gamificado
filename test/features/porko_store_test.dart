import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cofrinho_digital/data/models/goal_model.dart';
import 'package:cofrinho_digital/data/models/deposit_model.dart';
import 'package:cofrinho_digital/data/models/shop_item_model.dart';
import 'package:cofrinho_digital/data/repositories/goal_repository.dart';
import 'package:cofrinho_digital/data/repositories/deposit_repository.dart';
import 'package:cofrinho_digital/data/repositories/gamification_repository.dart';
import 'package:cofrinho_digital/data/repositories/wallet_repository.dart';
import 'package:cofrinho_digital/data/repositories/mascot_repository.dart';
import 'package:cofrinho_digital/core/providers/global_providers.dart';
import 'package:cofrinho_digital/features/shop/porko_store_screen.dart';
import 'package:cofrinho_digital/features/home/home_screen.dart';

void main() {
  late Directory tempDir;
  late GoalRepository goalRepo;
  late DepositRepository depositRepo;
  late GamificationRepository gamificationRepo;
  late WalletRepository walletRepo;
  late MascotRepository mascotRepo;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('store_test_');
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

  group('Story 5.3: Porko Store & Guarda-Roupa - Unit Tests', () {
    test('Compra item com saldo suficiente, debita carteira e desbloqueia badge stylish',
        () async {
      await walletRepo.addCoins(300);
      expect(walletRepo.getBalance(), equals(300));

      final hatCap = ShopCatalog.findById('hat_cap')!; // Preço: 150
      expect(mascotRepo.isItemUnlocked(hatCap.id), isFalse);

      final success = await mascotRepo.buyItem(
        item: hatCap,
        walletRepo: walletRepo,
        gamificationRepo: gamificationRepo,
      );

      expect(success, isTrue);
      expect(walletRepo.getBalance(), equals(150));
      expect(mascotRepo.isItemUnlocked(hatCap.id), isTrue);
      expect(mascotRepo.getMascot().hatId, equals(hatCap.id));

      // Verifica se o badge 'stylish' foi concedido
      expect(gamificationRepo.isBadgeUnlocked('stylish'), isTrue);
    });

    test('Bloqueia compra quando saldo e insuficiente', () async {
      await walletRepo.addCoins(100);
      final crown = ShopCatalog.findById('hat_crown')!; // Preço: 2500

      final success = await mascotRepo.buyItem(
        item: crown,
        walletRepo: walletRepo,
        gamificationRepo: gamificationRepo,
      );

      expect(success, isFalse);
      expect(walletRepo.getBalance(), equals(100)); // Não alterou saldo
      expect(mascotRepo.isItemUnlocked(crown.id), isFalse);
    });

    test('Equipar e desequipar itens do inventario funciona perfeitamente',
        () async {
      // Itens gratuitos padrao já comecam desbloqueados
      expect(mascotRepo.isItemUnlocked('pink_classic'), isTrue);
      expect(mascotRepo.isItemUnlocked('backdrop_default'), isTrue);

      // Equipa e desequipa chapeu
      await mascotRepo.equipItem(category: 'hat', itemId: 'hat_cap');
      expect(mascotRepo.getMascot().hatId, equals('hat_cap'));

      // Tocar novamente no mesmo chapeu desequipa
      await mascotRepo.equipItem(category: 'hat', itemId: 'hat_cap');
      expect(mascotRepo.getMascot().hatId, isNull);
    });
  });

  group('Story 5.3: PorkoStoreScreen - Widget Tests', () {
    testWidgets('Renderiza vitrine de itens cosméticos com abas e saldo',
        (tester) async {
      await walletRepo.addCoins(600);

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
            home: PorkoStoreScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Porko Store'), findsOneWidget);
      expect(find.text('600 Coins'), findsOneWidget);
      expect(find.text('Skins'), findsOneWidget);
      expect(find.text('Cabeça'), findsOneWidget);
      expect(find.text('Roupas'), findsOneWidget);
      expect(find.text('Cenários'), findsOneWidget);

      // Na aba Skins, a skin Rosa Clássico deve estar equipada
      expect(find.text('Rosa Clássico'), findsOneWidget);
      expect(find.text('Equipado ✨'), findsOneWidget);
    });

    testWidgets('Compra de item com confirmacao atualiza estado para Equipado',
        (tester) async {
      await walletRepo.addCoins(800);

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
            home: PorkoStoreScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Clica no botão de comprar a skin Porko Chocolate (500 coins)
      final buyButton = find.textContaining('500');
      expect(buyButton, findsOneWidget);
      await tester.tap(buyButton);
      await tester.pumpAndSettle();

      // Diálogo de confirmação aberto
      expect(find.text('Confirmar Compra'), findsOneWidget);

      // Confirma a compra
      await tester.tap(find.text('Confirmar Compra'));
      await tester.pumpAndSettle();

      // Saldo reduziu para 300 e item agora está Equipado
      expect(find.text('300 Coins'), findsOneWidget);
      expect(find.text('Equipado ✨'), findsWidgets);
    });

    testWidgets('HomeScreen possui atalho funcional para a Porko Store',
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

      // Encontra o botão com tooltip 'Porko Store'
      final storeFinder = find.byTooltip('Porko Store');
      expect(storeFinder, findsOneWidget);

      // Clica para navegar à loja
      await tester.tap(storeFinder);
      await tester.pumpAndSettle();

      expect(find.byType(PorkoStoreScreen), findsOneWidget);
    });
  });
}
