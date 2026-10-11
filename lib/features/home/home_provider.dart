import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/goal_model.dart';
import '../../data/repositories/goal_repository.dart';
import '../../core/providers/global_providers.dart';

// ── Provider de ordenação ─────────────────────────────────────────────────
final sortOrderProvider =
    StateProvider<SortOrder>((ref) => SortOrder.createdAt);

// ── Provider principal da Home com reatividade imediata (< 200ms) ──────────
final homeGoalsProvider = Provider<List<GoalModel>>((ref) {
  final repo = ref.watch(goalRepositoryProvider);
  final order = ref.watch(sortOrderProvider);

  // Observa mudanças nas boxes de metas e depósitos
  ref.watch(goalBoxChangesProvider);
  ref.watch(depositBoxChangesProvider);

  return repo.getActive(order: order);
});

// ── Provider de estatísticas gerais com reatividade imediata ─────────────
final goalStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final repo = ref.watch(goalRepositoryProvider);
  ref.watch(goalBoxChangesProvider);
  ref.watch(depositBoxChangesProvider);
  return repo.getStats();
});
