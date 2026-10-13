import '../../data/models/badge_model.dart';
import '../../data/repositories/goal_repository.dart';
import '../../data/repositories/deposit_repository.dart';
import '../../data/repositories/gamification_repository.dart';

class EvaluateBadgesUseCase {
  final GoalRepository goalRepo;
  final DepositRepository depositRepo;
  final GamificationRepository gamificationRepo;

  EvaluateBadgesUseCase({
    required this.goalRepo,
    required this.depositRepo,
    required this.gamificationRepo,
  });

  /// Avalia todas as regras de badges de forma idempotente.
  /// Retorna a lista de badges que foram DESBLOQUEADOS NESTA EXECUÇÃO.
  Future<List<BadgeDefinition>> execute() async {
    final newlyUnlocked = <BadgeDefinition>[];
    final now = DateTime.now();

    final allGoals = goalRepo.getAll();
    final activeGoals = allGoals.where((g) => !g.isArchived).toList();
    final totalDeposits = depositRepo.getAll().length;
    final currentStreak = gamificationRepo.getCurrentStreak();
    final longestStreak = gamificationRepo.getLongestStreak();
    final maxStreak = currentStreak > longestStreak ? currentStreak : longestStreak;

    // 1. Primeiro Passo: primeiro depósito registrado
    if (totalDeposits >= 1) {
      if (await gamificationRepo.unlockBadge('first_deposit', now)) {
        final def = BadgeDefinition.findById('first_deposit');
        if (def != null) newlyUnlocked.add(def);
      }
    }

    // 2. Ritmo Constante: streak de 3 dias
    if (maxStreak >= 3) {
      if (await gamificationRepo.unlockBadge('streak_3', now)) {
        final def = BadgeDefinition.findById('streak_3');
        if (def != null) newlyUnlocked.add(def);
      }
    }

    // 3. Semana de Ouro: streak de 7 dias
    if (maxStreak >= 7) {
      if (await gamificationRepo.unlockBadge('streak_7', now)) {
        final def = BadgeDefinition.findById('streak_7');
        if (def != null) newlyUnlocked.add(def);
      }
    }

    // 4. Mestre da Disciplina: streak de 30 dias
    if (maxStreak >= 30) {
      if (await gamificationRepo.unlockBadge('streak_30', now)) {
        final def = BadgeDefinition.findById('streak_30');
        if (def != null) newlyUnlocked.add(def);
      }
    }

    // 5. Meio Caminho Andado: 50% de qualquer meta
    final hasHalfway = allGoals.any((g) => g.progress >= 0.50);
    if (hasHalfway) {
      if (await gamificationRepo.unlockBadge('halfway', now)) {
        final def = BadgeDefinition.findById('halfway');
        if (def != null) newlyUnlocked.add(def);
      }
    }

    // 6. Sonho Realizado: 100% de qualquer meta
    final hasCompleted = allGoals.any((g) => g.isCompleted);
    if (hasCompleted) {
      if (await gamificationRepo.unlockBadge('goal_completed', now)) {
        final def = BadgeDefinition.findById('goal_completed');
        if (def != null) newlyUnlocked.add(def);
      }
    }

    // 7. Colecionador: 3 ou mais metas ativas simultâneas
    if (activeGoals.length >= 3) {
      if (await gamificationRepo.unlockBadge('collector', now)) {
        final def = BadgeDefinition.findById('collector');
        if (def != null) newlyUnlocked.add(def);
      }
    }

    return newlyUnlocked;
  }
}
