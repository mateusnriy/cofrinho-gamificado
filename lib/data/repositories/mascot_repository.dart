import 'package:hive_flutter/hive_flutter.dart';
import '../models/mascot_model.dart';

class MascotRepository {
  static const String boxName = 'mascot_box';
  static const String _mascotKey = 'equipped_mascot';

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
        updated = current.copyWith(hatId: itemId);
        break;
      case 'cloth':
        updated = current.copyWith(clothId: itemId);
        break;
      case 'backdrop':
        updated = current.copyWith(backdropId: itemId);
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
