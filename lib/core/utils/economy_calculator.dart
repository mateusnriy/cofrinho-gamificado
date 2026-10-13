import '../utils/formatters.dart';

/// Representa uma modalidade de economia sugerida
class EconomyModality {
  final String title;
  final String subtitle;
  final double amount;
  final String formattedAmount;
  final String period;
  final String description;
  final String iconAsset; // nome do ícone semântico

  const EconomyModality({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.formattedAmount,
    required this.period,
    required this.description,
    required this.iconAsset,
  });
}

class EconomyCalculator {
  // Calcula sugestões de quanto poupar por dia, semana ou mês
  static List<EconomyModality> calculate({
    required double targetAmount,
    required double savedAmount,
    DateTime? deadline,
  }) {
    final remaining = (targetAmount - savedAmount).clamp(0.0, double.infinity);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDay = deadline != null
        ? DateTime(deadline.year, deadline.month, deadline.day)
        : today.add(const Duration(days: 30));
    final daysLeft = targetDay.difference(today).inDays.clamp(1, 36500);

    // Evita divisão por zero
    final weeksLeft = (daysLeft / 7).ceilToDouble().clamp(1.0, double.infinity);
    final monthsLeft =
        (daysLeft / 30).ceilToDouble().clamp(1.0, double.infinity);

    final daily = ((remaining / daysLeft) * 100).ceilToDouble() / 100;
    final weekly = ((remaining / weeksLeft) * 100).ceilToDouble() / 100;
    final monthly = ((remaining / monthsLeft) * 100).ceilToDouble() / 100;

    return [
      EconomyModality(
        title: 'Economia Diária',
        subtitle: 'Consistência todo dia',
        amount: daily,
        formattedAmount: AppFormatters.currency(daily),
        period: 'por dia',
        description:
            'Guarde ${AppFormatters.currency(daily)} todos os dias durante '
            '$daysLeft dias e você atingirá sua meta.',
        iconAsset: 'daily',
      ),
      EconomyModality(
        title: 'Desafio Semanal',
        subtitle: 'Um depósito por semana',
        amount: weekly,
        formattedAmount: AppFormatters.currency(weekly),
        period: 'por semana',
        description:
            'Separe ${AppFormatters.currency(weekly)} por semana durante '
            '${weeksLeft.toInt()} semanas para alcançar seu objetivo.',
        iconAsset: 'weekly',
      ),
      EconomyModality(
        title: 'Depósito Mensal',
        subtitle: 'Planejamento no salário',
        amount: monthly,
        formattedAmount: AppFormatters.currency(monthly),
        period: 'por mês',
        description:
            'Reserve ${AppFormatters.currency(monthly)} por mês durante '
            '${monthsLeft.toInt()} meses e chegará lá.',
        iconAsset: 'monthly',
      ),
    ];
  }

  // Avalia se o ritmo da meta está em dia, atrasado ou concluído
  static GoalHealth evaluateHealth({
    required double targetAmount,
    required double savedAmount,
    DateTime? deadline,
  }) {
    if (targetAmount == 0) return GoalHealth.undefined;

    final progress = savedAmount / targetAmount;
    if (progress >= 1.0) return GoalHealth.completed;

    if (deadline == null) return GoalHealth.onTrack;

    final daysLeft = deadline.difference(DateTime.now()).inDays;
    if (daysLeft < 0) return GoalHealth.overdue;

    // Progresso esperado considerando tempo decorrido
    final totalDays = deadline
        .difference(DateTime.now().subtract(const Duration(days: 1)))
        .inDays;
    final expectedProgress =
        totalDays > 0 ? (1 - (daysLeft / totalDays)).clamp(0.0, 1.0) : 1.0;

    if (progress >= expectedProgress * 0.85) return GoalHealth.onTrack;
    if (progress >= expectedProgress * 0.5) return GoalHealth.slightlyBehind;
    return GoalHealth.atRisk;
  }
}

enum GoalHealth {
  onTrack,
  slightlyBehind,
  atRisk,
  overdue,
  completed,
  undefined,
}

extension GoalHealthExtension on GoalHealth {
  String get label {
    switch (this) {
      case GoalHealth.onTrack:
        return 'No caminho certo';
      case GoalHealth.slightlyBehind:
        return 'Ligeiramente atrasado';
      case GoalHealth.atRisk:
        return 'Em risco';
      case GoalHealth.overdue:
        return 'Prazo encerrado';
      case GoalHealth.completed:
        return 'Concluída!';
      case GoalHealth.undefined:
        return '';
    }
  }
}
