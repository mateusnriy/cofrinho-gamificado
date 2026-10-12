import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../../data/models/goal_model.dart';
import '../../data/models/deposit_model.dart';
import '../../core/providers/global_providers.dart';
import '../../widgets/celebration_overlay.dart';
import '../../widgets/milestone_map_card.dart';
import '../../core/utils/notification_service.dart';
import '../deposit/deposit_screen.dart';
import '../goal_form/goal_form_screen.dart';
import 'goal_detail_provider.dart';

// Tela de Detalhes da Meta com 3 abas especializadas: Jornada, Evolução e Histórico
class GoalDetailScreen extends ConsumerStatefulWidget {
  final String goalId;

  const GoalDetailScreen({super.key, required this.goalId});

  @override
  ConsumerState<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends ConsumerState<GoalDetailScreen> {
  // Aba atualmente selecionada: 'j' (Jornada), 'e' (Evolução), 'h' (Histórico)
  String _activeTab = 'j';

  // Abre o bottom sheet para registrar depósito nesta meta
  void _openDepositSheet(BuildContext context, GoalModel goal) {
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

  // Estorna um depósito individualmente recalculando a meta de forma atômica
  Future<void> _deleteDeposit(DepositModel deposit, GoalModel goal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Remover depósito?'),
        content: Text(
          'O valor de ${AppFormatters.currency(deposit.amount)} será subtraído do total acumulado da meta.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            child: const Text('Remover', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      HapticFeedback.mediumImpact();
      final depositRepo = ref.read(depositRepositoryProvider);
      final goalRepo = ref.read(goalRepositoryProvider);
      final walletRepo = ref.read(walletRepositoryProvider);

      await depositRepo.delete(deposit.id);
      await goalRepo.removeDeposit(goal.id, deposit.amount);
      await walletRepo.deductCoins(deposit.amount.floor());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Depósito removido com sucesso!'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(milliseconds: 1500),
          ),
        );
      }
    }
  }

  // Diálogo de confirmação para exclusão permanente da meta
  Future<bool> _confirmDelete(BuildContext context, GoalModel goal) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Excluir meta permanentemente?'),
            content: Text(
              'Você está prestes a excluir a meta "${goal.name}".\n\nEsta ação é irreversível e todo o histórico de depósitos associados será permanentemente removido.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
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

  // Manipula as ações do menu superior (Editar, Arquivar, Excluir)
  Future<void> _handleMenuAction(String action, GoalModel goal) async {
    final repo = ref.read(goalRepositoryProvider);
    final depositRepo = ref.read(depositRepositoryProvider);

    if (action == 'edit') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => GoalFormScreen(existingGoal: goal)),
      );
    } else if (action == 'archive') {
      if (goal.reminderTime != null) {
        try {
          await NotificationService().cancelGoalReminder(goal.id.hashCode);
        } catch (_) {}
      }
      await repo.archive(goal.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Meta arquivada com sucesso')),
        );
        Navigator.pop(context);
      }
    } else if (action == 'delete') {
      final confirmed = await _confirmDelete(context, goal);
      if (confirmed && mounted) {
        if (goal.reminderTime != null) {
          try {
            await NotificationService().cancelGoalReminder(goal.id.hashCode);
          } catch (_) {}
        }
        await depositRepo.deleteAllByGoal(goal.id);
        await repo.delete(goal.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Meta "${goal.name}" excluída com sucesso')),
          );
          Navigator.pop(context);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final goal = ref.watch(goalByIdProvider(widget.goalId));
    final deposits = ref.watch(depositsByGoalProvider(widget.goalId));
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (goal == null) {
      return const Scaffold(
        body: Center(child: Text('Meta não encontrada')),
      );
    }

    final goalColor = Color(goal.colorValue);
    final daysLeft = goal.deadline?.difference(DateTime.now()).inDays.clamp(1, 9999);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1F14) : const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── 1. Header Dinâmico na Cor da Meta com Cantos de 36dp ──────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 52, 20, 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [goalColor, goalColor.withValues(alpha: 0.85)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Botão Voltar, Título e Menu de Ações (⋮)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.25),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                      const Text(
                        'Jornada da meta',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.25),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.more_vert_rounded, color: Colors.white, size: 20),
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        onSelected: (action) => _handleMenuAction(action, goal),
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_rounded, size: 18),
                                SizedBox(width: 8),
                                Text('✏️ Editar meta'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'archive',
                            child: Row(
                              children: [
                                Icon(Icons.archive_rounded, size: 18),
                                SizedBox(width: 8),
                                Text('📦 Arquivar meta'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Excluir meta', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Ícone, Nome da Meta e Saldo Acumulado
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          IconData(goal.iconCodePoint, fontFamily: 'MaterialIcons'),
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              goal.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              AppFormatters.currency(goal.savedAmount),
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w800,
                                fontSize: 24,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Card translúcido de progresso do header (#dHdr do protótipo)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                'Alvo ${AppFormatters.currency(goal.targetAmount)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white.withValues(alpha: 0.95),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${goal.progressPercent.toInt()}% • ${daysLeft != null ? '$daysLeft dias restantes' : 'sem prazo definido'}',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white.withValues(alpha: 0.95),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: goal.progress.clamp(0.0, 1.0),
                            minHeight: 8,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.25),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── 2. Segmented Control com as 3 Abas (Jornada, Evolução, Histórico)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1B2E22) : const Color(0xFFEEF3EE),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    _buildTabButton('j', 'Jornada', isDark),
                    _buildTabButton('e', 'Evolução', isDark),
                    _buildTabButton('h', 'Histórico', isDark),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── 3. Conteúdo Reativo da Aba Selecionada ─────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildActiveTabContent(goal, deposits, goalColor, isDark),
            ),
          ],
        ),
      ),

      // ── 4. Botão Fixo Inferior de Depósito ─────────────────────────────────
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF12261A) : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? const Color(0xFF2F4A37) : const Color(0xFFE2E8E2),
            ),
          ),
        ),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: goal.isCompleted ? null : () => _openDepositSheet(context, goal),
            style: ElevatedButton.styleFrom(
              backgroundColor: goalColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
            ),
            child: Text(
              goal.isCompleted ? '🏆 Meta Concluída!' : '💰 Depositar nesta meta',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Construtor do botão do segmented control
  Widget _buildTabButton(String tabKey, String label, bool isDark) {
    final isSelected = _activeTab == tabKey;
    return Expanded(
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _activeTab = tabKey);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFF243B2A) : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.10),
                      blurRadius: 6,
                    )
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: isSelected
                  ? (isDark ? Colors.white : const Color(0xFF1A1A1A))
                  : (isDark ? Colors.white60 : const Color(0xFF566259)),
            ),
          ),
        ),
      ),
    );
  }

  // Renderiza o corpo correspondente à aba ativa
  Widget _buildActiveTabContent(
    GoalModel goal,
    List<DepositModel> deposits,
    Color goalColor,
    bool isDark,
  ) {
    if (_activeTab == 'j') {
      return _buildJourneyTab(goal, goalColor, isDark);
    } else if (_activeTab == 'e') {
      return _buildEvolutionTab(goal, deposits, goalColor, isDark);
    } else {
      return _buildHistoryTab(goal, deposits, goalColor, isDark);
    }
  }

  // ── Aba 1: Jornada (4 Checkpoints: 25%, 50%, 75%, 100%) ───────────────────
  Widget _buildJourneyTab(GoalModel goal, Color goalColor, bool isDark) {
    return MilestoneMapCard(
      goal: goal,
      goalColor: goalColor,
    );
  }

  // ── Aba 2: Evolução (Gráfico Mensal em Barras) ─────────────────────────────
  Widget _buildEvolutionTab(
    GoalModel goal,
    List<DepositModel> deposits,
    Color goalColor,
    bool isDark,
  ) {
    if (deposits.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1B2E22) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? const Color(0xFF2F4A37) : const Color(0xFFE2E8E2),
          ),
        ),
        alignment: Alignment.center,
        child: Column(
          children: [
            const Text('🌱', style: TextStyle(fontSize: 36)),
            const SizedBox(height: 8),
            Text(
              'Sem depósitos ainda. O gráfico aparece após o primeiro.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                color: isDark ? Colors.white60 : const Color(0xFF566259),
              ),
            ),
          ],
        ),
      );
    }

    // Agrupa depósitos por mês (ex: Out, Nov)
    const monthNames = [
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
      'Dez',
    ];
    final Map<String, double> monthlySums = {};
    for (final d in deposits) {
      final mName = monthNames[(d.date.month - 1).clamp(0, 11)];
      final key = '$mName/${d.date.year.toString().substring(2)}';
      monthlySums[key] = (monthlySums[key] ?? 0.0) + d.amount;
    }

    final maxVal = monthlySums.values.fold<double>(0.0, (a, b) => a > b ? a : b);
    final rhythmLabel = switch (goal.rhythm) {
      'daily' => '☀️ Diário',
      'weekly' => '📅 Semanal',
      'monthly' => '🗓️ Mensal',
      _ => '🌱 No meu ritmo',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1B2E22) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? const Color(0xFF2F4A37) : const Color(0xFFE2E8E2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Guardado por mês',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'R\$ / mês',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 11,
                      color: isDark ? Colors.white60 : const Color(0xFF566259),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Barras estéticas verticais
              SizedBox(
                height: 160,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: monthlySums.entries.map((e) {
                    final heightFactor =
                        maxVal > 0 ? (e.value / maxVal).clamp(0.08, 1.0) : 0.1;
                    return Flexible(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            AppFormatters.currency(e.value),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: 30,
                            height: 110 * heightFactor,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  goalColor,
                                  goalColor.withValues(alpha: 0.5),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(10),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            e.key,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              color: isDark
                                  ? Colors.white70
                                  : const Color(0xFF1A1A1A),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Card de Resumo do Ritmo Escolhido (idêntico ao protótipo #dBody tab 'e')
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF243B2A) : const Color(0xFFEEF3EE),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ritmo escolhido',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 11,
                      color: isDark ? Colors.white60 : const Color(0xFF566259),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    rhythmLabel,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Total de depósitos',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 11,
                      color: isDark ? Colors.white60 : const Color(0xFF566259),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${deposits.length} registro${deposits.length == 1 ? '' : 's'}',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: goalColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Aba 3: Histórico (Depósitos com Estorno Individual) ───────────────────
  Widget _buildHistoryTab(
    GoalModel goal,
    List<DepositModel> deposits,
    Color goalColor,
    bool isDark,
  ) {
    if (deposits.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1B2E22) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? const Color(0xFF2F4A37) : const Color(0xFFE2E8E2),
          ),
        ),
        alignment: Alignment.center,
        child: Column(
          children: [
            const Text('🪙', style: TextStyle(fontSize: 36)),
            const SizedBox(height: 8),
            Text(
              'Cofrinho pronto para a primeira moeda!',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                color: isDark ? Colors.white60 : const Color(0xFF566259),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B2E22) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF2F4A37) : const Color(0xFFE2E8E2),
        ),
      ),
      child: Column(
        children: deposits.map((d) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF243B2A) : const Color(0xFFEEF3EE),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                // Ícone com seta de entrada
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: goalColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      '↓',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: goalColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Valor e Data
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppFormatters.currency(d.amount),
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        AppFormatters.date(d.date),
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 11,
                          color: isDark ? Colors.white60 : const Color(0xFF566259),
                        ),
                      ),
                      if (d.note != null && d.note!.isNotEmpty)
                        Text(
                          d.note!,
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: isDark ? Colors.white70 : const Color(0xFF566259),
                          ),
                        ),
                    ],
                  ),
                ),

                // Botão de lixeira para estorno seguro
                IconButton(
                  icon: const Text('🗑️', style: TextStyle(fontSize: 16)),
                  tooltip: 'Excluir depósito',
                  onPressed: () => _deleteDeposit(d, goal),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
