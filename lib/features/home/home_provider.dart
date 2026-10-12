import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/goal_model.dart';
import '../../data/repositories/goal_repository.dart';
import '../../core/providers/global_providers.dart';

// ── Notifier de ordenação com persistência no Hive ────────────────────────
class SortOrderNotifier extends StateNotifier<SortOrder> {
  static const _boxName = 'settings';
  static const _sortOrderKey = 'goal_sort_order';

  SortOrderNotifier() : super(SortOrder.createdAt) {
    _loadSortOrder();
  }

  void _loadSortOrder() {
    try {
      if (Hive.isBoxOpen(_boxName)) {
        final box = Hive.box(_boxName);
        final saved = box.get(_sortOrderKey) as String?;
        if (saved == 'deadline') {
          state = SortOrder.deadline;
        } else if (saved == 'progress') {
          state = SortOrder.progress;
        } else {
          state = SortOrder.createdAt;
        }
      }
    } catch (_) {
      state = SortOrder.createdAt;
    }
  }

  Future<void> setOrder(SortOrder order) async {
    HapticFeedback.lightImpact();
    state = order;
    try {
      if (Hive.isBoxOpen(_boxName)) {
        final box = Hive.box(_boxName);
        await box.put(_sortOrderKey, order.name);
      }
    } catch (_) {}
  }
}

final sortOrderProvider =
    StateNotifierProvider<SortOrderNotifier, SortOrder>((ref) {
  return SortOrderNotifier();
});

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
