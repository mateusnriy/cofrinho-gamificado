import 'package:hive_flutter/hive_flutter.dart';
import '../models/deposit_model.dart';

class DepositRepository {
  static const String _boxName = 'deposits';

  Box<DepositModel> get _box => Hive.box<DepositModel>(_boxName);

  // ── Leitura ──────────────────────────────────────────────────────────────

  /// Retorna todos os depósitos de uma meta, do mais recente ao mais antigo
  List<DepositModel> getByGoal(String goalId) {
    return _box.values
        .where((d) => d.goalId == goalId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Total depositado em uma meta (recalcula a partir dos depósitos)
  double getTotalByGoal(String goalId) {
    return _box.values
        .where((d) => d.goalId == goalId)
        .fold(0.0, (sum, d) => sum + d.amount);
  }

  /// Depósitos agrupados por mês para gráfico
  /// Retorna mapa de "yyyy-MM" -> valor total
  Map<String, double> getMonthlyByGoal(String goalId) {
    final deposits = getByGoal(goalId);
    final Map<String, double> monthly = {};

    for (final d in deposits) {
      final key =
          '${d.date.year}-${d.date.month.toString().padLeft(2, '0')}';
      monthly[key] = (monthly[key] ?? 0) + d.amount;
    }

    return monthly;
  }

  /// Stream que notifica mudanças na box de depósitos (para reatividade imediata)
  Stream<BoxEvent> get watchAll => _box.watch();

  // ── Escrita ───────────────────────────────────────────────────────────────

  /// Persiste um novo depósito
  Future<void> save(DepositModel deposit) async {
    await _box.put(deposit.id, deposit);
  }

  /// Exclui um depósito específico
  Future<void> delete(String depositId) async {
    await _box.delete(depositId);
  }

  /// Exclui todos os depósitos de uma meta (ao excluir a meta)
  Future<void> deleteAllByGoal(String goalId) async {
    final keys = _box.values
        .where((d) => d.goalId == goalId)
        .map((d) => d.id)
        .toList();
    await _box.deleteAll(keys);
  }
}
