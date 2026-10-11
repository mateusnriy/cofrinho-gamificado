import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/goal_repository.dart';
import '../../data/repositories/deposit_repository.dart';
import '../../data/repositories/gamification_repository.dart';
import '../../domain/usecases/register_deposit_use_case.dart';

final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  return GoalRepository();
});

final depositRepositoryProvider = Provider<DepositRepository>((ref) {
  return DepositRepository();
});

final gamificationRepositoryProvider = Provider<GamificationRepository>((ref) {
  return GamificationRepository();
});

final goalBoxChangesProvider = StreamProvider<void>((ref) {
  final repo = ref.watch(goalRepositoryProvider);
  return repo.watchAll.map((_) {});
});

final depositBoxChangesProvider = StreamProvider<void>((ref) {
  final repo = ref.watch(depositRepositoryProvider);
  return repo.watchAll.map((_) {});
});

final gamificationBoxChangesProvider = StreamProvider<void>((ref) {
  final repo = ref.watch(gamificationRepositoryProvider);
  return repo.watchAll.map((_) {});
});

final streakProvider = Provider<Map<String, dynamic>>((ref) {
  final repo = ref.watch(gamificationRepositoryProvider);
  ref.watch(gamificationBoxChangesProvider);
  return {
    'currentStreak': repo.getCurrentStreak(),
    'longestStreak': repo.getLongestStreak(),
    'lastDepositDate': repo.getLastDepositDate(),
  };
});

final registerDepositUseCaseProvider = Provider<RegisterDepositUseCase>((ref) {
  final goalRepo = ref.watch(goalRepositoryProvider);
  final depositRepo = ref.watch(depositRepositoryProvider);
  final gamificationRepo = ref.watch(gamificationRepositoryProvider);
  return RegisterDepositUseCase(
    goalRepo: goalRepo,
    depositRepo: depositRepo,
    gamificationRepo: gamificationRepo,
  );
});
