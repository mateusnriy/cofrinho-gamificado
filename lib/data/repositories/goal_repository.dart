import 'package:hive_flutter/hive_flutter.dart';
import '../models/goal_model.dart';

class GoalRepository {
  static const String _boxName = 'goals';

  Box<GoalModel> get _box => Hive.box<GoalModel>(_boxName);

  // ── Leitura ──────────────────────────────────────────────────────────────

  /// Retorna todas as metas ativas (não arquivadas), ordenadas conforme critério
  List<GoalModel> getActive({SortOrder order = SortOrder.createdAt}) {
    final goals = _box.values
        .where((g) => !g.isArchived)
        .toList();

    switch (order) {
      case SortOrder.deadline:
        goals.sort((a, b) => a.deadline.compareTo(b.deadline));
      case SortOrder.progress:
        goals.sort((a, b) => b.progress.compareTo(a.progress));
      case SortOrder.createdAt:
        goals.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return goals;
  }

  /// Retorna metas arquivadas
  List<GoalModel> getArchived() {
    return _box.values.where((g) => g.isArchived).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Busca meta por ID. Retorna null se não encontrar.
  GoalModel? getById(String id) {
    try {
      return _box.values.firstWhere((g) => g.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Stream que notifica mudanças na box de metas (para reatividade)
  Stream<BoxEvent> get watchAll => _box.watch();

  // ── Escrita ───────────────────────────────────────────────────────────────

  /// Persiste uma nova meta
  Future<void> save(GoalModel goal) async {
    await _box.put(goal.id, goal);
  }

  /// Atualiza uma meta existente
  Future<void> update(GoalModel goal) async {
    await _box.put(goal.id, goal);
  }

  /// Adiciona valor ao savedAmount e persiste
  Future<void> addDeposit(String goalId, double amount) async {
    final goal = getById(goalId);
    if (goal == null) return;

    final updated = goal.copyWith(
      savedAmount: goal.savedAmount + amount,
    );
    await _box.put(goalId, updated);
  }

  /// Arquiva uma meta (não exclui, preserva histórico)
  Future<void> archive(String goalId) async {
    final goal = getById(goalId);
    if (goal == null) return;
    final updated = goal.copyWith(isArchived: true);
    await _box.put(goalId, updated);
  }

  /// Exclui permanentemente uma meta
  Future<void> delete(String goalId) async {
    await _box.delete(goalId);
  }

  /// Estatísticas gerais de patrimônio consolidado
  Map<String, dynamic> getStats() {
    final active = getActive();
    final totalTarget = active.fold<double>(0, (s, g) => s + g.targetAmount);
    final totalSaved = active.fold<double>(0, (s, g) => s + g.savedAmount);
    final completed = active.where((g) => g.isCompleted).length;

    return {
      'totalGoals': active.length,
      'totalTarget': totalTarget,
      'totalSaved': totalSaved,
      'completed': completed,
      'overallProgress': totalTarget > 0
          ? (totalSaved / totalTarget).clamp(0.0, 1.0)
          : 0.0,
    };
  }
}

enum SortOrder { createdAt, deadline, progress }
