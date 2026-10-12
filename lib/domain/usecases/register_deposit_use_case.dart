import 'package:uuid/uuid.dart';
import '../../data/models/deposit_model.dart';
import '../../data/models/goal_model.dart';
import '../../data/models/badge_model.dart';
import '../../data/repositories/deposit_repository.dart';
import '../../data/repositories/goal_repository.dart';
import '../../data/repositories/gamification_repository.dart';
import '../../data/repositories/wallet_repository.dart';
import '../../data/repositories/mascot_repository.dart';
import '../../core/utils/notification_service.dart';
import 'evaluate_badges_use_case.dart';

// Guarda o resultado de um depósito feito com sucesso
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
  final bool dailyBonusEarned;

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
    this.dailyBonusEarned = false,
  });
}

// Registra um depósito na meta, atualiza moedas, sequencia e anima o mascote
class RegisterDepositUseCase {
  final GoalRepository _goalRepo;
  final DepositRepository _depositRepo;
  final GamificationRepository? _gamificationRepo;
  final WalletRepository? _walletRepo;
  final MascotRepository? _mascotRepo;

  RegisterDepositUseCase({
    required GoalRepository goalRepo,
    required DepositRepository depositRepo,
    GamificationRepository? gamificationRepo,
    WalletRepository? walletRepo,
    MascotRepository? mascotRepo,
  })  : _goalRepo = goalRepo,
        _depositRepo = depositRepo,
        _gamificationRepo = gamificationRepo,
        _walletRepo = walletRepo,
        _mascotRepo = mascotRepo;

  // Executa o registro de um depósito com validações, pontuação e bônus
  Future<DepositResult?> execute({
    required String goalId,
    required double amount,
    DateTime? date,
    String? note,
  }) async {
    if (amount <= 0) return null;

    final goal = _goalRepo.getById(goalId);
    if (goal == null) return null;

    final remaining = goal.remainingAmount;
    if (amount > remaining) return null;

    final milestonesBefore = goal.completedMilestonesCount;
    final depositDate = date ?? DateTime.now();

    final deposit = DepositModel(
      id: const Uuid().v4(),
      goalId: goalId,
      amount: amount,
      date: depositDate,
      note: note?.trim().isEmpty == true ? null : note?.trim(),
    );

    // Salva o registro do depósito e atualiza o saldo da meta
    await _depositRepo.save(deposit);
    await _goalRepo.addDeposit(goalId, amount);

    int currentStreak = 1;
    List<BadgeDefinition> newBadges = [];

    // Atualiza a sequência diária e verifica conquistas destravadas
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

    int coinsEarned = amount.floor();
    bool dailyBonusEarned = false;

    // Concede moedas Oinc Coins e bônus diário se aplicável
    if (_walletRepo != null) {
      try {
        await _walletRepo!.addCoins(coinsEarned);
        dailyBonusEarned =
            await _walletRepo!.claimDailyBonusIfEligible(deposit.date);
        if (dailyBonusEarned) {
          coinsEarned += 50;
        }
      } catch (_) {}
    }

    // Se a meta foi atingida, dispara a notificação de comemoração
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

    // Faz o mascote Porko comemorar o depósito com muita alegria
    if (_mascotRepo != null) {
      try {
        await _mascotRepo!.celebrateDeposit();
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
      dailyBonusEarned: dailyBonusEarned,
    );
  }
}
