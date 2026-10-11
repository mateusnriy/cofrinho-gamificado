import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/badge_model.dart';
import '../../data/models/mascot_model.dart';
import '../../data/repositories/goal_repository.dart';
import '../../data/repositories/deposit_repository.dart';
import '../../data/repositories/gamification_repository.dart';
import '../../data/repositories/wallet_repository.dart';
import '../../data/repositories/mascot_repository.dart';
import '../../domain/usecases/register_deposit_use_case.dart';
import '../../domain/usecases/evaluate_badges_use_case.dart';

final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  return GoalRepository();
});

final depositRepositoryProvider = Provider<DepositRepository>((ref) {
  return DepositRepository();
});

final gamificationRepositoryProvider = Provider<GamificationRepository>((ref) {
  return GamificationRepository();
});

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepository();
});

final mascotRepositoryProvider = Provider<MascotRepository>((ref) {
  return MascotRepository();
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

final walletBoxChangesProvider = StreamProvider<void>((ref) {
  final repo = ref.watch(walletRepositoryProvider);
  return repo.watchAll.map((_) {});
});

final walletBalanceProvider = Provider<int>((ref) {
  final repo = ref.watch(walletRepositoryProvider);
  ref.watch(walletBoxChangesProvider);
  return repo.getBalance();
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
  final walletRepo = ref.watch(walletRepositoryProvider);
  return RegisterDepositUseCase(
    goalRepo: goalRepo,
    depositRepo: depositRepo,
    gamificationRepo: gamificationRepo,
    walletRepo: walletRepo,
  );
});

final evaluateBadgesUseCaseProvider = Provider<EvaluateBadgesUseCase>((ref) {
  final goalRepo = ref.watch(goalRepositoryProvider);
  final depositRepo = ref.watch(depositRepositoryProvider);
  final gamificationRepo = ref.watch(gamificationRepositoryProvider);
  return EvaluateBadgesUseCase(
    goalRepo: goalRepo,
    depositRepo: depositRepo,
    gamificationRepo: gamificationRepo,
  );
});

final badgesProvider = Provider<List<UserBadge>>((ref) {
  final repo = ref.watch(gamificationRepositoryProvider);
  ref.watch(gamificationBoxChangesProvider);
  return repo.getAllUserBadges();
});

final mascotBoxChangesProvider = StreamProvider<void>((ref) {
  final repo = ref.watch(mascotRepositoryProvider);
  return repo.watchAll.map((_) {});
});

final equippedMascotProvider = Provider<MascotModel>((ref) {
  final repo = ref.watch(mascotRepositoryProvider);
  ref.watch(mascotBoxChangesProvider);
  return repo.getMascot();
});

final mascotInventoryProvider = Provider<List<String>>((ref) {
  final repo = ref.watch(mascotRepositoryProvider);
  ref.watch(mascotBoxChangesProvider);
  return repo.getUnlockedItemIds();
});

final porkoMoodProvider = Provider<PorkoMood>((ref) {
  final goalRepo = ref.watch(goalRepositoryProvider);
  ref.watch(goalBoxChangesProvider);
  final goals = goalRepo.getAll().where((g) => !g.isArchived).toList();

  if (goals.isEmpty) {
    return PorkoMood.sleeping;
  }

  final streakData = ref.watch(streakProvider);
  final currentStreak = (streakData['currentStreak'] as int?) ?? 0;
  final lastDate = streakData['lastDepositDate'] as DateTime?;

  final hasCompleted = goals.any((g) => g.isCompleted);
  if (hasCompleted || currentStreak >= 7) {
    return PorkoMood.celebrating;
  }

  final now = DateTime.now();
  final depositedToday = lastDate != null &&
      lastDate.year == now.year &&
      lastDate.month == now.month &&
      lastDate.day == now.day;

  if (currentStreak >= 3 || depositedToday) {
    return PorkoMood.happy;
  }

  return PorkoMood.neutral;
});
