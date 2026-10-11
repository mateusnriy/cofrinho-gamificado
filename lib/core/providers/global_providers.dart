import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/goal_repository.dart';
import '../../data/repositories/deposit_repository.dart';
import '../../domain/usecases/register_deposit_use_case.dart';

final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  return GoalRepository();
});

final depositRepositoryProvider = Provider<DepositRepository>((ref) {
  return DepositRepository();
});

final goalBoxChangesProvider = StreamProvider<void>((ref) {
  final repo = ref.watch(goalRepositoryProvider);
  return repo.watchAll.map((_) {});
});

final depositBoxChangesProvider = StreamProvider<void>((ref) {
  final repo = ref.watch(depositRepositoryProvider);
  return repo.watchAll.map((_) {});
});

final registerDepositUseCaseProvider = Provider<RegisterDepositUseCase>((ref) {
  final goalRepo = ref.watch(goalRepositoryProvider);
  final depositRepo = ref.watch(depositRepositoryProvider);
  return RegisterDepositUseCase(
    goalRepo: goalRepo,
    depositRepo: depositRepo,
  );
});
