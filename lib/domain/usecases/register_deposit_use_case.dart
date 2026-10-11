import 'package:uuid/uuid.dart';
import '../../data/models/deposit_model.dart';
import '../../data/models/goal_model.dart';
import '../../data/models/badge_model.dart';
import '../../data/repositories/deposit_repository.dart';
import '../../data/repositories/goal_repository.dart';
import '../../data/repositories/gamification_repository.dart';
import '../../core/utils/notification_service.dart';
import 'evaluate_badges_use_case.dart';

class DepositResult {
  final GoalModel goal;
  final DepositModel deposit;
  final double amount;
  final int coinsEarned;
  final bool isGoalCompleted;
  final int milestonesBefore;
  final int milestonesAfter;
  final bool newMilestoneReached;
  final int currentStreak;
  final List<BadgeDefinition> newBadges;

  const DepositResult({
    required this.goal,
    required this.deposit,
    required this.amount,
    required this.coinsEarned,
    required this.isGoalCompleted,
    required this.milestonesBefore,
    required this.milestonesAfter,
    required this.newMilestoneReached,
    this.currentStreak = 1,
    this.newBadges = const [],
  });
}

class RegisterDepositUseCase {
  final GoalRepository _goalRepo;
  final DepositRepository _depositRepo;
  final GamificationRepository? _gamificationRepo;

  RegisterDepositUseCase({
    required GoalRepository goalRepo,
    required DepositRepository depositRepo,
    GamificationRepository? gamificationRepo,
  })  : _goalRepo = goalRepo,
        _depositRepo = depositRepo,
        _gamificationRepo = gamificationRepo;

  Future<DepositResult?> execute({
    required String goalId,
    required double amount,
    String? note,
  }) async {
    if (amount <= 0) return null;

    final goal = _goalRepo.getById(goalId);
    if (goal == null) return null;

    final remaining = goal.remainingAmount;
    if (amount > remaining) return null;

    final milestonesBefore = goal.completedMilestonesCount;

    final deposit = DepositModel(
      id: const Uuid().v4(),
      goalId: goalId,
      amount: amount,
      date: DateTime.now(),
      note: note?.trim().isEmpty == true ? null : note?.trim(),
    );

    // Transação atômica local: grava depósito, incrementa saldo e atualiza streak (ARCH-4)
    await _depositRepo.save(deposit);
    await _goalRepo.addDeposit(goalId, amount);

    int currentStreak = 1;
    List<BadgeDefinition> newBadges = [];

    if (_gamificationRepo != null) {
      try {
        currentStreak =
            await _gamificationRepo!.registerDepositDate(deposit.date);
        final evaluateBadges = EvaluateBadgesUseCase(
          goalRepo: _goalRepo,
          depositRepo: _depositRepo,
          gamificationRepo: _gamificationRepo!,
        );
        newBadges = await evaluateBadges.execute();
      } catch (_) {}
    }

    final updatedGoal = _goalRepo.getById(goalId) ?? goal;
    final milestonesAfter = updatedGoal.completedMilestonesCount;
    final coinsEarned = amount.floor();

    // Se a meta foi concluída com este depósito, cancela lembretes diários e celebra (AD-5)
    if (updatedGoal.isCompleted) {
      if (updatedGoal.reminderTime != null) {
        try {
          await NotificationService()
              .cancelGoalReminder(updatedGoal.id.hashCode);
        } catch (_) {}
      }
      try {
        await NotificationService().showCompletionNotification(
          goalName: updatedGoal.name,
        );
      } catch (_) {}
    }

    return DepositResult(
      goal: updatedGoal,
      deposit: deposit,
      amount: amount,
      coinsEarned: coinsEarned,
      isGoalCompleted: updatedGoal.isCompleted,
      milestonesBefore: milestonesBefore,
      milestonesAfter: milestonesAfter,
      newMilestoneReached: milestonesAfter > milestonesBefore,
      currentStreak: currentStreak,
      newBadges: newBadges,
    );
  }
}
