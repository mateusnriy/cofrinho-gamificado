import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/utils/formatters.dart';
import '../data/models/goal_model.dart';

class MilestoneMapCard extends StatelessWidget {
  final GoalModel goal;
  final Color goalColor;

  const MilestoneMapCard({
    super.key,
    required this.goal,
    required this.goalColor,
  });

  static const List<_MilestoneInfo> _milestoneMetadata = [
    _MilestoneInfo(
      percent: 0.25,
      percentText: '25%',
      title: 'Primeiro Passo',
      description: 'O início da jornada para transformar o sonho em realidade!',
      icon: Icons.flag_rounded,
    ),
    _MilestoneInfo(
      percent: 0.50,
      percentText: '50%',
      title: 'Metade do Caminho',
      description: '50% conquistado! Você já está no controle das suas economias.',
      icon: Icons.trending_up_rounded,
    ),
    _MilestoneInfo(
      percent: 0.75,
      percentText: '75%',
      title: 'Reta Final',
      description: 'Quase lá! Falta muito pouco para o objetivo final.',
      icon: Icons.star_rounded,
    ),
    _MilestoneInfo(
      percent: 1.00,
      percentText: '100%',
      title: 'Meta Conquistada!',
      description: 'Vitória total! Você atingiu o objetivo com perseverança.',
      icon: Icons.emoji_events_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final milestoneAmounts = goal.milestoneAmounts;
    final saved = goal.savedAmount;
    final completedCount = goal.completedMilestonesCount;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color ??
            (isDark ? const Color(0xFF1E293B) : Colors.white),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho da Trilha
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: goalColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.explore_rounded,
                  color: goalColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trilha de Marcos',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$completedCount de 4 marcos conquistados',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color
                            ?.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: completedCount == 4
                      ? const Color(0xFF10B981).withValues(alpha: 0.12)
                      : goalColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  completedCount == 4 ? '🎉 100% Concluído' : '$completedCount/4',
                  style: TextStyle(
                    color: completedCount == 4
                        ? const Color(0xFF10B981)
                        : goalColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Lista de Marcos da Trilha
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _milestoneMetadata.length,
            itemBuilder: (context, index) {
              final meta = _milestoneMetadata[index];
              final targetForMilestone = index < milestoneAmounts.length
                  ? milestoneAmounts[index]
                  : goal.targetAmount * meta.percent;
              final isReached = saved >= targetForMilestone;
              final isNextTarget = !isReached &&
                  (index == 0 || saved >= milestoneAmounts[index - 1]);
              final isLast = index == _milestoneMetadata.length - 1;

              return _MilestoneItemWidget(
                info: meta,
                targetAmount: targetForMilestone,
                savedAmount: saved,
                isReached: isReached,
                isNextTarget: isNextTarget,
                isLast: isLast,
                goalColor: goalColor,
              );
            },
          ),

          const SizedBox(height: 8),

          // Caixa de incentivo do Porko (idêntica ao protótipo #dBody tab 'j')
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF243B2A) : const Color(0xFFEEF3EE),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Text('🐷', style: TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    goal.isCompleted
                        ? 'Parabéns! Você concluiu 100% desta jornada com o Porko! 🎉'
                        : 'Você já percorreu ${goal.progressPercent.toInt()}% do caminho. Continue firme — cada depósito aproxima você da conquista!',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : const Color(0xFF566259),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MilestoneInfo {
  final double percent;
  final String percentText;
  final String title;
  final String description;
  final IconData icon;

  const _MilestoneInfo({
    required this.percent,
    required this.percentText,
    required this.title,
    required this.description,
    required this.icon,
  });
}

class _MilestoneItemWidget extends StatelessWidget {
  final _MilestoneInfo info;
  final double targetAmount;
  final double savedAmount;
  final bool isReached;
  final bool isNextTarget;
  final bool isLast;
  final Color goalColor;

  const _MilestoneItemWidget({
    required this.info,
    required this.targetAmount,
    required this.savedAmount,
    required this.isReached,
    required this.isNextTarget,
    required this.isLast,
    required this.goalColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remainingForThis = (targetAmount - savedAmount).clamp(0.0, double.infinity);

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        _showMilestoneDetailsModal(context, theme, remainingForThis);
      },
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nó e Linha Conectora
            Column(
              children: [
                _buildMilestoneNode(theme),
                if (!isLast)
                  Container(
                    width: 3,
                    height: 52,
                    decoration: BoxDecoration(
                      color: isReached
                          ? goalColor
                          : (isNextTarget
                              ? goalColor.withValues(alpha: 0.3)
                              : theme.dividerColor.withValues(alpha: 0.15)),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),

            // Informações do Marco
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            '${info.percentText} — ${info.title}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: isReached || isNextTarget
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              color: isReached
                                  ? goalColor
                                  : (isNextTarget
                                      ? theme.textTheme.bodyMedium?.color
                                      : theme.textTheme.bodyMedium?.color
                                          ?.withValues(alpha: 0.6)),
                            ),
                          ),
                        ),
                        Text(
                          AppFormatters.currency(targetAmount),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isReached
                                ? goalColor
                                : theme.textTheme.bodyMedium?.color
                                    ?.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Badge de Estado do Marco
                    if (isReached)
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              size: 13,
                              color: Color(0xFF10B981),
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Marco conquistado!',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (isNextTarget)
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: goalColor.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: goalColor.withValues(alpha: 0.25),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.flag_circle_rounded,
                              size: 13,
                              color: goalColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Próximo marco: faltam ${AppFormatters.currency(remainingForThis)}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: goalColor,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Text(
                        'Aguardando marco anterior',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.textTheme.bodySmall?.color
                              ?.withValues(alpha: 0.5),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMilestoneNode(ThemeData theme) {
    if (isReached) {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: goalColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: goalColor.withValues(alpha: 0.35),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.check_rounded,
          color: Colors.white,
          size: 18,
        ),
      );
    }

    if (isNextTarget) {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: goalColor.withValues(alpha: 0.12),
          shape: BoxShape.circle,
          border: Border.all(color: goalColor, width: 2.5),
        ),
        child: Icon(
          info.icon,
          color: goalColor,
          size: 16,
        ),
      );
    }

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? const Color(0xFF334155)
            : const Color(0xFFF1F5F9),
        shape: BoxShape.circle,
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Icon(
        Icons.lock_outline_rounded,
        color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.4),
        size: 15,
      ),
    );
  }

  void _showMilestoneDetailsModal(
    BuildContext context,
    ThemeData theme,
    double remainingForThis,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isReached
                          ? const Color(0xFF10B981).withValues(alpha: 0.15)
                          : goalColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isReached ? Icons.emoji_events_rounded : info.icon,
                      color: isReached ? const Color(0xFF10B981) : goalColor,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${info.percentText} • ${info.title}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          AppFormatters.currency(targetAmount),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: goalColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                info.description,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
              ),
              const SizedBox(height: 16),
              if (isReached)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle, color: Color(0xFF10B981)),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Parabéns! Você já ultrapassou este marco com sucesso!',
                          style: TextStyle(
                            color: Color(0xFF10B981),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: goalColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    isNextTarget
                        ? 'Faltam ${AppFormatters.currency(remainingForThis)} para alcançar este marco!'
                        : 'Valor total deste marco: ${AppFormatters.currency(targetAmount)}',
                    style: TextStyle(
                      color: goalColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: goalColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Entendido',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }
}
