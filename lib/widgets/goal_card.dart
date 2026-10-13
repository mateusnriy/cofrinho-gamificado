import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/models/goal_model.dart';
import '../core/utils/formatters.dart';

/// Card de Meta (`.goal-card`) idêntico ao protótipo `prototype_oinc.html` em Soft 3D,
/// sem margem horizontal duplicada, com pílula `${pct}%`, subtítulo de ritmo + prazo,
/// barra `.pbar` de 10px com marcos (25%, 50%, 75%, 100%) e rodapé com botão `💰 Depositar ›`.
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

  String _paceLabel(String? rhythm) {
    switch (rhythm) {
      case 'daily':
        return 'Diário';
      case 'weekly':
        return 'Semanal';
      case 'monthly':
        return 'Mensal';
      case 'free':
      default:
        return goal.deadline == null ? 'No meu ritmo' : 'Semanal';
    }
  }

  /// Mapeia os codePoints de ícones das metas para os emojis 3D do protótipo quando aplicável
  String? _emojiForCodePoint(int codePoint) {
    if (codePoint == Icons.beach_access_rounded.codePoint ||
        codePoint == Icons.flight_takeoff_rounded.codePoint) {
      return '🏖️';
    }
    if (codePoint == Icons.sports_esports_rounded.codePoint ||
        codePoint == Icons.videogame_asset_rounded.codePoint) {
      return '🎮';
    }
    if (codePoint == Icons.smartphone_rounded.codePoint ||
        codePoint == Icons.phone_iphone_rounded.codePoint ||
        codePoint == Icons.phone_android_rounded.codePoint ||
        codePoint == Icons.computer_rounded.codePoint) {
      return '📱';
    }
    if (codePoint == Icons.directions_car_rounded.codePoint) {
      return '🚗';
    }
    if (codePoint == Icons.home_rounded.codePoint) {
      return '🏠';
    }
    if (codePoint == Icons.school_rounded.codePoint ||
        codePoint == Icons.menu_book_rounded.codePoint) {
      return '🎓';
    }
    if (codePoint == Icons.music_note_rounded.codePoint) {
      return '🎸';
    }
    if (codePoint == Icons.auto_awesome_rounded.codePoint ||
        codePoint == Icons.savings_rounded.codePoint) {
      return '✨';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final goalColor = Color(goal.colorValue);
    final progress = goal.progress;
    final pctInt = goal.progressPercent.round().clamp(0, 100);
    final isCompleted = goal.isCompleted;
    final emoji = _emojiForCodePoint(goal.iconCodePoint);
    final subColor = isDark ? const Color(0xFFA5D6A7) : const Color(0xFF566259);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B2E22) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF2F4A37) : const Color(0xFFE2E8E2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 1. Topo: Ícone .goal-ico (48x48) + Nome & Subtítulo + Pílula % ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: goalColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: goalColor.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: emoji != null
                            ? Text(emoji, style: const TextStyle(fontSize: 24))
                            : Icon(
                                IconData(
                                  goal.iconCodePoint,
                                  fontFamily: 'MaterialIcons',
                                ),
                                color: goalColor,
                                size: 24,
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            goal.name,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_paceLabel(goal.rhythm)} • ${isCompleted ? "🎉 Meta atingida!" : AppFormatters.daysRemaining(goal.deadline)}',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: isCompleted
                                  ? const Color(0xFF10B981)
                                  : subColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Pílula de porcentagem idêntica ao protótipo
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: goalColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$pctInt%',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: goalColor,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ── 2. Linha de Valores (Guardado vs. Meta) ─────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Guardado',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: subColor,
                            ),
                          ),
                          Text(
                            AppFormatters.currency(goal.savedAmount),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: isCompleted
                                  ? const Color(0xFF10B981)
                                  : (isDark ? Colors.white : const Color(0xFF1A1A1A)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Meta',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: subColor,
                          ),
                        ),
                        Text(
                          'de ${AppFormatters.currency(goal.targetAmount)}',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: subColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // ── 3. Barra de Progresso Soft 3D (.pbar 10px) ──────────────
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    height: 10,
                    color: isDark
                        ? const Color(0xFF243B2A)
                        : const Color(0xFFEEF3EE),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Stack(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 550),
                              curve: Curves.easeOutCubic,
                              height: 10,
                              width: constraints.maxWidth * progress,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    goalColor.withValues(alpha: 0.82),
                                    isCompleted
                                        ? const Color(0xFF10B981)
                                        : goalColor,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                // Rótulos discretos dos 4 marcos (25%, 50%, 75%, 100%)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMilestoneLabel('25%', progress >= 0.25, goalColor, subColor),
                    _buildMilestoneLabel('50%', progress >= 0.50, goalColor, subColor),
                    _buildMilestoneLabel('75%', progress >= 0.75, goalColor, subColor),
                    _buildMilestoneLabel('100%', progress >= 1.00, goalColor, subColor),
                  ],
                ),

                const SizedBox(height: 10),

                // ── 4. Rodapé Idêntico ao Protótipo: Faltam R$ X + Botão 💰 Depositar › ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        isCompleted
                            ? '🎉 Meta concluída!'
                            : 'Faltam ${AppFormatters.currency(goal.remainingAmount)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: isCompleted
                              ? const Color(0xFF10B981)
                              : subColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        if (onAddDeposit != null) {
                          onAddDeposit!();
                        } else {
                          onTap();
                        }
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Semantics(
                        button: true,
                        label: 'Depositar na meta ${goal.name}',
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF243B2A)
                                : const Color(0xFFEEF3EE),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF2F4A37)
                                  : const Color(0xFFE2E8E2),
                            ),
                          ),
                          child: Text(
                            '💰 Depositar ›',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? const Color(0xFF00C853)
                                  : const Color(0xFF2E7D32),
                            ),
                          ),
                        ),
                      ),
                    ),
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
    String label,
    bool reached,
    Color goalColor,
    Color subColor,
  ) {
    return Text(
      label,
      style: TextStyle(
        fontFamily: 'Nunito',
        fontSize: 10,
        fontWeight: reached ? FontWeight.w800 : FontWeight.w600,
        color: reached ? goalColor : subColor.withValues(alpha: 0.6),
      ),
    );
  }
}
