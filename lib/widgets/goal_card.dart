import 'package:flutter/material.dart';
import '../../data/models/goal_model.dart';
import '../../core/utils/formatters.dart';

class GoalCard extends StatelessWidget {
  final GoalModel goal;
  final VoidCallback onTap;
  final VoidCallback? onAddDeposit;

  const GoalCard({
    super.key,
    required this.goal,
    required this.onTap,
    this.onAddDeposit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final goalColor = Color(goal.colorValue);
    final progress = goal.progress;
    final isCompleted = goal.isCompleted;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ícone com cor da meta
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: goalColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        IconData(goal.iconCodePoint,
                            fontFamily: 'MaterialIcons'),
                        color: goalColor,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 16),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            goal.name,
                            style: theme.textTheme.headlineSmall
                                ?.copyWith(fontSize: 17),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          // UX-DR2: Indicador de dias restantes em pílula
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isCompleted
                                  ? const Color(0xFF10B981)
                                      .withValues(alpha: 0.12)
                                  : _deadlineColor(context, goal)
                                      .withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isCompleted
                                  ? '🎉 Meta atingida!'
                                  : AppFormatters.daysRemaining(goal.deadline),
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                color: isCompleted
                                    ? const Color(0xFF10B981)
                                    : _deadlineColor(context, goal),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (onAddDeposit != null && !isCompleted)
                      Container(
                        decoration: BoxDecoration(
                          color: goalColor.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: onAddDeposit,
                          icon: const Icon(Icons.add_rounded),
                          color: goalColor,
                          tooltip: 'Adicionar depósito',
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 20),

                // Textos de valores
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Guardado', style: theme.textTheme.bodySmall),
                        const SizedBox(height: 2),
                        Text(
                          AppFormatters.currency(goal.savedAmount),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontSize: 22,
                            color: isCompleted
                                ? const Color(0xFF10B981)
                                : theme.textTheme.headlineLarge?.color,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Meta', style: theme.textTheme.bodySmall),
                            const SizedBox(width: 4),
                            Text('(${goal.progressPercent.toInt()}%)', style: theme.textTheme.bodySmall),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppFormatters.currency(goal.targetAmount),
                          style: theme.textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // UX-DR2: Barra de progresso com nós visuais de milestone (25%, 50%, 75%, 100%)
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.centerLeft,
                  children: [
                    // Fundo da barra
                    Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: goalColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    // Progresso preenchido
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.easeOutQuart,
                          height: 10,
                          width: constraints.maxWidth * progress,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                goalColor.withValues(alpha: 0.7),
                                isCompleted
                                    ? const Color(0xFF10B981)
                                    : goalColor,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        );
                      },
                    ),
                    // Nós dos 4 Milestones
                    Positioned.fill(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.maxWidth;
                          final milestones = [0.25, 0.50, 0.75, 1.0];

                          return Stack(
                            clipBehavior: Clip.none,
                            children: milestones.map((m) {
                              final isReached = progress >= m;
                              final leftPos = (width * m) - 5;

                              return Positioned(
                                left: leftPos.clamp(0.0, width - 10),
                                top: 0,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isReached ? Colors.white : Colors.white70,
                                    border: Border.all(
                                      color: isReached
                                          ? goalColor
                                          : goalColor.withValues(alpha: 0.35),
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.1),
                                        blurRadius: 3,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Rótulos dos 4 Marcos de Progresso (Story 1.5)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMilestoneLabel('25%', goal.milestoneAmounts[0], progress >= 0.25, goalColor),
                    _buildMilestoneLabel('50%', goal.milestoneAmounts[1], progress >= 0.50, goalColor),
                    _buildMilestoneLabel('75%', goal.milestoneAmounts[2], progress >= 0.75, goalColor),
                    _buildMilestoneLabel('100%', goal.milestoneAmounts[3], progress >= 1.00, goalColor),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMilestoneLabel(
      String label, double amount, bool reached, Color goalColor) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: reached ? FontWeight.w700 : FontWeight.w500,
        color: reached ? goalColor : const Color(0xFF94A3B8),
      ),
    );
  }

  // Escolhe a cor do texto do prazo (vermelho se venceu/acabando, cinza neutro se tranquilo)
  Color _deadlineColor(BuildContext context, GoalModel goal) {
    final days = goal.daysRemaining;
    if (days == null) return const Color(0xFF10B981);
    if (days <= 0) return const Color(0xFFEF4444);
    if (days <= 7) return const Color(0xFFF59E0B);
    return const Color(0xFF64748B);
  }
}
