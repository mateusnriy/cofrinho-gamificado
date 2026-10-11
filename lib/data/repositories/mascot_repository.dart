import 'package:hive_flutter/hive_flutter.dart';
import '../models/mascot_model.dart';
import '../models/shop_item_model.dart';
import 'wallet_repository.dart';
import 'gamification_repository.dart';

class MascotRepository {
  static const String boxName = 'mascot_box';
  static const String _mascotKey = 'equipped_mascot';
  static const String _unlockedCosmeticsKey = 'unlocked_cosmetics';

  Box get _box => Hive.box(boxName);

  /// Retorna o mascote atual com seus itens equipados
  MascotModel getMascot() {
    final raw = _box.get(_mascotKey);
    if (raw is Map) {
      return MascotModel.fromMap(raw);
    }
    return const MascotModel();
  }

  /// Salva as configurações de itens do mascote
  Future<void> saveMascot(MascotModel mascot) async {
    await _box.put(_mascotKey, mascot.toMap());
  }

  /// Retorna a lista de IDs de todos os itens já comprados/desbloqueados pelo usuário
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

  /// Verifica se um determinado item cosmético já está desbloqueado no inventário
  bool isItemUnlocked(String itemId) {
    final unlocked = getUnlockedItemIds();
    return unlocked.contains(itemId);
  }

  /// Realiza a compra de um item da loja com Oinc Coins de forma atômica e segura.
  /// Se a compra for bem-sucedida, deduz as moedas, adiciona ao inventário, equipa o item
  /// e concede o badge 'stylish'.
  Future<bool> buyItem({
    required ShopItem item,
    required WalletRepository walletRepo,
    GamificationRepository? gamificationRepo,
  }) async {
    // Se o item já pertence ao inventário
    if (isItemUnlocked(item.id)) {
      await equipItem(category: item.category.name, itemId: item.id);
      return true;
    }

    // Valida saldo suficiente
    final balance = walletRepo.getBalance();
    if (balance < item.price) {
      return false; // Saldo insuficiente
    }

    // Deduz moedas da carteira
    await walletRepo.deductCoins(item.price);

    // Adiciona ao inventário no Hive
    final currentUnlocked = getUnlockedItemIds().toSet();
    currentUnlocked.add(item.id);
    await _box.put(_unlockedCosmeticsKey, currentUnlocked.toList());

    // Equipa automaticamente o novo item adquirido
    await equipItem(category: item.category.name, itemId: item.id);

    // Concede o badge 'stylish' (Estiloso) ao usuário
    if (gamificationRepo != null) {
      try {
        await gamificationRepo.unlockBadge('stylish');
      } catch (_) {}
    }

    return true;
  }

  /// Equipa ou desequipa um item cosmético em uma categoria específica
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
        // Tocar no mesmo item equipado desequipa
        updated = current.copyWith(
          hatId: current.hatId == itemId ? null : itemId,
        );
        break;
      case 'cloth':
        updated = current.copyWith(
          clothId: current.clothId == itemId ? null : itemId,
        );
        break;
      case 'backdrop':
        updated = current.copyWith(
          backdropId: current.backdropId == itemId ? 'backdrop_default' : itemId,
        );
        break;
      default:
        updated = current;
    }

    await saveMascot(updated);
    return updated;
  }

  /// Stream reativa de alterações no estado do mascote
  Stream<BoxEvent> get watchAll => _box.watch();
}
