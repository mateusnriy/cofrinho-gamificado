import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../core/utils/economy_calculator.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/goal_model.dart';
import '../../data/models/deposit_model.dart';
import '../../core/providers/global_providers.dart';
import '../../widgets/celebration_overlay.dart';
import '../../widgets/economy_suggestions_card.dart';
import '../../core/utils/notification_service.dart';
import '../deposit/deposit_screen.dart';
import '../goal_form/goal_form_screen.dart';
import 'goal_detail_provider.dart';

class GoalDetailScreen extends ConsumerWidget {
  final String goalId;

  const GoalDetailScreen({super.key, required this.goalId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goal = ref.watch(goalByIdProvider(goalId));
    final deposits = ref.watch(depositsByGoalProvider(goalId));

    if (goal == null) {
      return const Scaffold(
        body: Center(child: Text('Meta não encontrada')),
      );
    }

    final goalColor = Color(goal.colorValue);
    final modalities = EconomyCalculator.calculate(
      targetAmount: goal.targetAmount,
      savedAmount: goal.savedAmount,
      deadline: goal.deadline,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(goal.name, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GoalFormScreen(existingGoal: goal),
              ),
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (action) => _handleAction(context, ref, action, goal),
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'archive',
                child: Row(children: [
                  Icon(Icons.archive_rounded, size: 18),
                  SizedBox(width: 10),
                  Text('Arquivar meta'),
                ]),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(children: [
                  Icon(Icons.delete_outline_rounded,
                      size: 18, color: Colors.red),
                  SizedBox(width: 10),
                  Text('Excluir meta', style: TextStyle(color: Colors.red)),
                ]),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProgressCard(goal: goal, goalColor: goalColor),
            const SizedBox(height: 16),
            if (!goal.isCompleted) ...[
              EconomySuggestionsCard(modalities: modalities),
              const SizedBox(height: 16),
            ],
            if (deposits.isNotEmpty) ...[
              _MonthlyChart(goalId: goalId, goalColor: goalColor),
              const SizedBox(height: 16),
            ],
            _DepositHistory(
              deposits: deposits,
              goalId: goalId,
              goal: goal,
              goalColor: goalColor,
              onAddDeposit: () => _openDepositSheet(context, ref, goal),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      floatingActionButton: goal.isCompleted
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openDepositSheet(context, ref, goal),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Depositar'),
              backgroundColor: goalColor,
              foregroundColor: Colors.white,
            ),
    );
  }

  void _openDepositSheet(BuildContext context, WidgetRef ref, GoalModel goal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DepositScreen(
        goal: goal,
        onDepositSaved: () {
          final updated = ref.read(goalByIdProvider(goal.id));
          if (updated != null && updated.isCompleted) {
            Future.delayed(const Duration(milliseconds: 400), () {
              if (context.mounted) {
                CelebrationOverlay.show(context, updated.name);
              }
            });
          }
        },
      ),
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    String action,
    GoalModel goal,
  ) async {
    final repo = ref.read(goalRepositoryProvider);
    final depositRepo = ref.read(depositRepositoryProvider);

    if (action == 'archive') {
      if (goal.reminderTime != null) {
        try {
          await NotificationService().cancelGoalReminder(goal.id.hashCode);
        } catch (_) {}
      }
      await repo.archive(goal.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Meta arquivada')),
        );
        Navigator.of(context).pop();
      }
    } else if (action == 'delete') {
      final confirmed = await _confirmDelete(context, goal);
      if (confirmed && context.mounted) {
        if (goal.reminderTime != null) {
          try {
            await NotificationService().cancelGoalReminder(goal.id.hashCode);
          } catch (_) {}
        }
        await depositRepo.deleteAllByGoal(goal.id);
        await repo.delete(goal.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Meta "${goal.name}" excluída com sucesso')),
          );
          Navigator.of(context).pop();
        }
      }
    }
  }

  Future<bool> _confirmDelete(BuildContext context, GoalModel goal) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Excluir meta permanentemente?'),
            content: Text(
              'Você está prestes a excluir a meta "${goal.name}".\n\nEsta ação é irreversível e todo o histórico de depósitos associados será permanentemente removido.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
                child: const Text('Excluir'),
              ),
            ],
          ),
        ) ??
        false;
  }
}

class _ProgressCard extends StatelessWidget {
  final GoalModel goal;
  final Color goalColor;

  const _ProgressCard({required this.goal, required this.goalColor});

  @override
  Widget build(BuildContext context) {
    final health = EconomyCalculator.evaluateHealth(
      targetAmount: goal.targetAmount,
      savedAmount: goal.savedAmount,
      deadline: goal.deadline,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [goalColor, goalColor.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  IconData(goal.iconCodePoint, fontFamily: 'MaterialIcons'),
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (goal.note != null)
                      Text(
                        goal.note!,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  health.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Economizado',
                      style: TextStyle(color: Colors.white60, fontSize: 12)),
                  Text(
                    AppFormatters.currency(goal.savedAmount),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Meta',
                      style: TextStyle(color: Colors.white60, fontSize: 12)),
                  Text(
                    AppFormatters.currency(goal.targetAmount),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: goal.progress,
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${AppFormatters.percent(goal.progressPercent)} concluído',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              Text(
                goal.isCompleted
                    ? '🎉 Concluída!'
                    : AppFormatters.daysRemaining(goal.deadline),
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
          if (!goal.isCompleted) ...[
            const SizedBox(height: 8),
            Text(
              'Faltam ${AppFormatters.currency(goal.remainingAmount)}',
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MonthlyChart extends ConsumerWidget {
  final String goalId;
  final Color goalColor;

  const _MonthlyChart({required this.goalId, required this.goalColor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthly = ref.watch(monthlyDepositsProvider(goalId));

    if (monthly.isEmpty) return const SizedBox.shrink();

    final sortedKeys = monthly.keys.toList()..sort();
    final bars = sortedKeys.asMap().entries.map((entry) {
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: monthly[entry.value]!,
            color: goalColor,
            width: 20,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ],
      );
    }).toList();

    final maxY = monthly.values.reduce((a, b) => a > b ? a : b) * 1.2;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Depósitos por mês',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                barGroups: bars,
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(
                  show: true,
                  drawVerticalLine: false,
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, _) => Text(
                        AppFormatters.currencyCompact(value),
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= sortedKeys.length) {
                          return const SizedBox.shrink();
                        }
                        final key = sortedKeys[idx];
                        final parts = key.split('-');
                        final months = [
                          '',
                          'Jan',
                          'Fev',
                          'Mar',
                          'Abr',
                          'Mai',
                          'Jun',
                          'Jul',
                          'Ago',
                          'Set',
                          'Out',
                          'Nov',
                          'Dez'
                        ];
                        final month = int.tryParse(parts[1]) ?? 0;
                        return Text(
                          months[month],
                          style: const TextStyle(fontSize: 11),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DepositHistory extends ConsumerWidget {
  final List<DepositModel> deposits;
  final String goalId;
  final GoalModel goal;
  final Color goalColor;
  final VoidCallback? onAddDeposit;

  const _DepositHistory({
    required this.deposits,
    required this.goalId,
    required this.goal,
    required this.goalColor,
    this.onAddDeposit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Garante rigorosamente a ordenação cronológica decrescente (mais recente primeiro)
    final sortedDeposits = [...deposits]
      ..sort((a, b) => b.date.compareTo(a.date));

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Histórico de Depósitos',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: goalColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    sortedDeposits.isEmpty
                        ? '0 depósitos'
                        : '${sortedDeposits.length} depósito${sortedDeposits.length != 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: goalColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (sortedDeposits.isEmpty)
            _EmptyDepositState(
              goal: goal,
              goalColor: goalColor,
              onAddDeposit: onAddDeposit,
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sortedDeposits.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
                indent: 16,
                endIndent: 16,
              ),
              itemBuilder: (_, index) {
                final deposit = sortedDeposits[index];
                return _DepositTile(
                  deposit: deposit,
                  goalColor: goalColor,
                  onDelete: () => _deleteDeposit(context, ref, deposit),
                );
              },
            ),
        ],
      ),
    );
  }

  Future<void> _deleteDeposit(
    BuildContext context,
    WidgetRef ref,
    DepositModel deposit,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remover depósito?'),
        content: Text(
          'Deseja remover o depósito de ${AppFormatters.currency(deposit.amount)} realizado em ${AppFormatters.dateTime(deposit.date)}?\n\nO saldo acumulado da meta será recalculado.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final depositRepo = ref.read(depositRepositoryProvider);
      final goalRepo = ref.read(goalRepositoryProvider);

      await depositRepo.delete(deposit.id);
      final remaining = depositRepo.getTotalByGoal(goalId);
      final updatedGoal = goal.copyWith(savedAmount: remaining);
      await goalRepo.update(updatedGoal);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Depósito de ${AppFormatters.currency(deposit.amount)} removido.',
            ),
          ),
        );
      }
    }
  }
}

class _EmptyDepositState extends StatelessWidget {
  final GoalModel goal;
  final Color goalColor;
  final VoidCallback? onAddDeposit;

  const _EmptyDepositState({
    required this.goal,
    required this.goalColor,
    this.onAddDeposit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: goalColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.savings_outlined,
                size: 44,
                color: goalColor,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Cofrinho pronto para a primeira moeda!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Toda grande conquista começa com o primeiro passo. Registre seu primeiro depósito para iniciar seu progresso e ganhar Oinc Coins!',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
              textAlign: TextAlign.center,
            ),
            if (!goal.isCompleted && onAddDeposit != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onAddDeposit,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Fazer Primeiro Depósito'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: goalColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DepositTile extends StatelessWidget {
  final DepositModel deposit;
  final Color goalColor;
  final VoidCallback onDelete;

  const _DepositTile({
    required this.deposit,
    required this.goalColor,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hasNote = deposit.note != null && deposit.note!.trim().isNotEmpty;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: goalColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.arrow_downward_rounded,
              color: goalColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppFormatters.currency(deposit.amount),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: goalColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppFormatters.dateTime(deposit.date),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                      ),
                ),
                if (hasNote) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.notes_rounded,
                          size: 13,
                          color: isDark ? Colors.white60 : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            deposit.note!,
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: isDark
                                  ? Colors.white70
                                  : Colors.grey.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.delete_outline_rounded,
              size: 20,
              color: Colors.grey.shade400,
            ),
            onPressed: onDelete,
            tooltip: 'Remover depósito',
          ),
        ],
      ),
    );
  }
}
