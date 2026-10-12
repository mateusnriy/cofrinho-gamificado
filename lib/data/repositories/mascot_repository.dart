import 'package:hive_flutter/hive_flutter.dart';
import '../models/mascot_model.dart';
import '../models/shop_item_model.dart';
import 'wallet_repository.dart';
import 'gamification_repository.dart';

// Gerencia tudo sobre o Porko: itens equipados, humor, carinho e compras
class MascotRepository {
  static const String boxName = 'mascot_box';
  static const String _mascotKey = 'equipped_mascot';
  static const String _unlockedCosmeticsKey = 'unlocked_cosmetics';

  Box get _box => Hive.box(boxName);

  // Pega o mascote salvo no celular com todos os seus atributos
  MascotModel getMascot() {
    final raw = _box.get(_mascotKey);
    if (raw is Map) {
      final mascot = MascotModel.fromMap(raw);
      return _applyDecayIfNeeded(mascot);
    }
    return const MascotModel();
  }

  // Aplica uma perda suave de humor se o usuário passar dias sem abrir o app
  MascotModel _applyDecayIfNeeded(MascotModel mascot) {
    if (mascot.lastInteractedAt == null) return mascot;

    final now = DateTime.now();
    final daysPassed = now.difference(mascot.lastInteractedAt!).inDays;

    if (daysPassed > 0) {
      // Perde 5% de felicidade e 4% de energia ao dia sem passar do chão seguro de 40%
      final newHappiness = (mascot.happiness - (daysPassed * 5.0)).clamp(40.0, 100.0);
      final newEnergy = (mascot.energy - (daysPassed * 4.0)).clamp(40.0, 100.0);
      return mascot.copyWith(
        happiness: newHappiness,
        energy: newEnergy,
        lastInteractedAt: now,
      );
    }
    return mascot;
  }

  // Salva os dados atualizados do mascote no armazenamento local
  Future<void> saveMascot(MascotModel mascot) async {
    await _box.put(_mascotKey, mascot.toMap());
  }

  // Altera o nome do mascote (ex: Porko, Piggy, etc)
  Future<MascotModel> renameMascot(String newName) async {
    final current = getMascot();
    final updated = current.copyWith(name: newName.trim());
    await saveMascot(updated);
    return updated;
  }

  // Faz carinho no Porko (ganha +5 de felicidade, respeitando o limite diário de 5)
  Future<bool> petMascot() async {
    final current = getMascot();
    final now = DateTime.now();
    final isNewDay = current.lastAffectionDate == null ||
        current.lastAffectionDate!.day != now.day ||
        current.lastAffectionDate!.month != now.month;

    final count = isNewDay ? 0 : current.dailyAffectionCount;
    if (count >= 5) return false; // Limite do dia atingido

    final updated = current.copyWith(
      happiness: current.happiness + 5.0,
      dailyAffectionCount: count + 1,
      lastAffectionDate: now,
      lastInteractedAt: now,
    );
    await saveMascot(updated);
    return true;
  }

  // Dá um petisco para o Porko (ganha +10 de energia)
  Future<bool> feedMascot() async {
    final current = getMascot();
    final now = DateTime.now();
    final isNewDay = current.lastAffectionDate == null ||
        current.lastAffectionDate!.day != now.day ||
        current.lastAffectionDate!.month != now.month;

    final count = isNewDay ? 0 : current.dailyAffectionCount;
    if (count >= 5) return false;

    final updated = current.copyWith(
      energy: current.energy + 10.0,
      dailyAffectionCount: count + 1,
      lastAffectionDate: now,
      lastInteractedAt: now,
    );
    await saveMascot(updated);
    return true;
  }

  // Brinca com o Porko (ganha +8 de felicidade e +5 de energia)
  Future<bool> playWithMascot() async {
    final current = getMascot();
    final now = DateTime.now();
    final isNewDay = current.lastAffectionDate == null ||
        current.lastAffectionDate!.day != now.day ||
        current.lastAffectionDate!.month != now.month;

    final count = isNewDay ? 0 : current.dailyAffectionCount;
    if (count >= 5) return false;

    final updated = current.copyWith(
      happiness: current.happiness + 8.0,
      energy: current.energy + 5.0,
      dailyAffectionCount: count + 1,
      lastAffectionDate: now,
      lastInteractedAt: now,
    );
    await saveMascot(updated);
    return true;
  }

  // Chama o Porko com carinho (ganha +4 de energia)
  Future<bool> callMascot() async {
    final current = getMascot();
    final now = DateTime.now();
    final isNewDay = current.lastAffectionDate == null ||
        current.lastAffectionDate!.day != now.day ||
        current.lastAffectionDate!.month != now.month;

    final count = isNewDay ? 0 : current.dailyAffectionCount;
    if (count >= 5) return false;

    final updated = current.copyWith(
      energy: current.energy + 4.0,
      dailyAffectionCount: count + 1,
      lastAffectionDate: now,
      lastInteractedAt: now,
    );
    await saveMascot(updated);
    return true;
  }

  // Deixa o Porko super feliz quando um depósito é registrado
  Future<void> celebrateDeposit() async {
    final current = getMascot();
    final updated = current.copyWith(
      happiness: 100.0,
      energy: current.energy + 15.0,
      lastInteractedAt: DateTime.now(),
    );
    await saveMascot(updated);
  }

  // Pega todos os itens já comprados e liberados pelo usuário
  List<String> getUnlockedItemIds() {
    final raw = _box.get(_unlockedCosmeticsKey);
    final Set<String> defaultUnlocked = {'pink_classic', 'backdrop_default'};

    if (raw is List) {
      final list = raw.whereType<String>().toSet();
      list.addAll(defaultUnlocked);
      return list.toList();
    }
    return defaultUnlocked.toList();
  }

  // Verifica se o usuário já tem um item específico liberado
  bool isItemUnlocked(String itemId) {
    final unlocked = getUnlockedItemIds();
    return unlocked.contains(itemId);
  }

  // Compra um item da lojinha gastando moedas Oinc Coins
  Future<bool> buyItem({
    required ShopItem item,
    required WalletRepository walletRepo,
    GamificationRepository? gamificationRepo,
  }) async {
    if (isItemUnlocked(item.id)) {
      await equipItem(category: item.category.name, itemId: item.id);
      return true;
    }

    final balance = walletRepo.getBalance();
    if (balance < item.price) {
      return false;
    }

    await walletRepo.deductCoins(item.price);

    final currentUnlocked = getUnlockedItemIds().toSet();
    currentUnlocked.add(item.id);
    await _box.put(_unlockedCosmeticsKey, currentUnlocked.toList());

    await equipItem(category: item.category.name, itemId: item.id);

    if (gamificationRepo != null) {
      try {
        await gamificationRepo.unlockBadge('stylish');
      } catch (_) {}
    }

    return true;
  }

  // Coloca ou tira uma roupa ou acessório do mascote
  Future<MascotModel> equipItem({
    required String category,
    required String? itemId,
  }) async {
    final current = getMascot();
    late final MascotModel updated;

    switch (category) {
      case 'skin':
        updated = current.copyWith(skinId: itemId ?? 'pink_classic');
        break;
      case 'hat':
        updated = current.copyWith(
          hatId: current.hatId == itemId ? null : itemId,
          clearHat: current.hatId == itemId,
        );
        break;
      case 'cloth':
        updated = current.copyWith(
          clothId: current.clothId == itemId ? null : itemId,
          clearCloth: current.clothId == itemId,
        );
        break;
      case 'backdrop':
        updated = current.copyWith(
          backdropId: current.backdropId == itemId ? 'backdrop_default' : itemId,
          clearBackdrop: current.backdropId == itemId,
        );
        break;
      default:
        updated = current;
    }

    await saveMascot(updated);
    return updated;
  }

  // Fica de olho nas alterações do mascote para atualizar a tela na hora
  Stream<BoxEvent> get watchAll => _box.watch();
}
