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
        } else if (saved == 'savedAmount') {
          state = SortOrder.savedAmount;
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

// ── Notifier de filtro de metas (Menu Sanduíche ☰) ─────────────────────────
class GoalFilterNotifier extends StateNotifier<GoalFilter> {
  static const _boxName = 'settings';
  static const _filterKey = 'goal_status_filter';

  GoalFilterNotifier() : super(GoalFilter.all) {
    _loadFilter();
  }

  void _loadFilter() {
    try {
      if (Hive.isBoxOpen(_boxName)) {
        final box = Hive.box(_boxName);
        final saved = box.get(_filterKey) as String?;
        if (saved != null) {
          state = GoalFilter.values.firstWhere(
            (f) => f.name == saved,
            orElse: () => GoalFilter.all,
          );
        }
      }
    } catch (_) {
      state = GoalFilter.all;
    }
  }

  Future<void> setFilter(GoalFilter filter) async {
    HapticFeedback.selectionClick();
    state = filter;
    try {
      if (Hive.isBoxOpen(_boxName)) {
        final box = Hive.box(_boxName);
        await box.put(_filterKey, filter.name);
      }
    } catch (_) {}
  }
}

final goalFilterProvider =
    StateNotifierProvider<GoalFilterNotifier, GoalFilter>((ref) {
  return GoalFilterNotifier();
});

// ── Provider principal da Home com filtro + ordenação e reatividade ─────────
final homeGoalsProvider = Provider<List<GoalModel>>((ref) {
  final repo = ref.watch(goalRepositoryProvider);
  final order = ref.watch(sortOrderProvider);
  final filter = ref.watch(goalFilterProvider);

  ref.watch(goalBoxChangesProvider);
  ref.watch(depositBoxChangesProvider);

  if (filter == GoalFilter.archived) {
    return repo.sortGoals(repo.getArchived(), order);
  }

  final active = repo.getActive(order: order);
  switch (filter) {
    case GoalFilter.inProgress:
      return active.where((g) => !g.isCompleted).toList();
    case GoalFilter.completed:
      return active.where((g) => g.isCompleted).toList();
    case GoalFilter.withDeadline:
      return active.where((g) => g.deadline != null).toList();
    case GoalFilter.freePace:
      return active
          .where((g) => g.deadline == null || g.rhythm == 'free')
          .toList();
    case GoalFilter.all:
    case GoalFilter.archived:
      return active;
  }
});

// ── Provider de estatísticas gerais com reatividade imediata ─────────────
final goalStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final repo = ref.watch(goalRepositoryProvider);
  ref.watch(goalBoxChangesProvider);
  ref.watch(depositBoxChangesProvider);
  return repo.getStats();
});
