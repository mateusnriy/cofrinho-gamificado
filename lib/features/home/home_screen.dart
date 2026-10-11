import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/providers/global_providers.dart';
import '../../data/models/goal_model.dart';
import '../../data/repositories/goal_repository.dart';
import '../../widgets/goal_card.dart';
import '../goal_form/goal_form_screen.dart';
import '../goal_detail/goal_detail_screen.dart';
import '../deposit/deposit_screen.dart';
import '../gamification/badges_gallery_screen.dart';
import 'home_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(homeGoalsProvider);
    final stats = ref.watch(goalStatsProvider);
    final sortOrder = ref.watch(sortOrderProvider);

    return Scaffold(
      body: goals.isEmpty
          ? _buildEmptyState(context, ref, sortOrder)
          : SafeArea(
              bottom: false,
              child: Center(
                // RESPONSIVIDADE: Evita esticar elementos em Tablets/Web
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: _buildCustomHeader(context, ref, sortOrder),
                      ),
                      SliverToBoxAdapter(
                        child: _PremiumSummaryBanner(stats: stats),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                        sliver: SliverToBoxAdapter(
                          child: Text(
                            'Minhas Metas',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.only(bottom: 120),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final goal = goals[index];
                              return GoalCard(
                                goal: goal,
                                onTap: () => _openDetail(context, goal),
                                onAddDeposit: () =>
                                    _openDepositSheet(context, ref, goal),
                              );
                            },
                            childCount: goals.length,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openGoalForm(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nova Meta'),
      ),
    );
  }

  Widget _buildCustomHeader(
      BuildContext context, WidgetRef ref, SortOrder sortOrder) {
    // Escuta mudanças de tema e streak para disparar rebuild reativo
    ref.watch(themeProvider);
    final streakData = ref.watch(streakProvider);
    final currentStreak = (streakData['currentStreak'] as int?) ?? 0;
    final walletBalance = ref.watch(walletBalanceProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // RESPONSIVIDADE: Expanded para não quebrar a tela em telemóveis finos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Olá, Bem-vindo! 👋',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Cofrinho Digital',
                  style: Theme.of(context).textTheme.headlineMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Text('🪙', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Saldo: $walletBalance Oinc Coins! Ganhe +1 por real poupado e +50 no 1º depósito do dia.',
                            ),
                          ),
                        ],
                      ),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                },
                child: Tooltip(
                  message: 'Saldo: $walletBalance Oinc Coins',
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFFF59E0B).withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '🪙',
                          style: TextStyle(fontSize: 13),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$walletBalance',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (currentStreak > 0)
                Tooltip(
                  message:
                      'Sequência de $currentStreak ${currentStreak == 1 ? 'dia' : 'dias'} consecutivos!',
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF97316), Color(0xFFEF4444)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFFF97316).withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '🔥',
                          style: TextStyle(fontSize: 13),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$currentStreak ${currentStreak == 1 ? 'dia' : 'dias'}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Container(
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                    )
                  ],
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.emoji_events_rounded,
                    color: Color(0xFFF59E0B),
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const BadgesGalleryScreen(),
                    ),
                  ),
                  tooltip: 'Galeria de Conquistas',
                ),
              ),
              Container(
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                    )
                  ],
                ),
                child: IconButton(
                  icon: Icon(
                    isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                  onPressed: () =>
                      ref.read(themeProvider.notifier).toggleTheme(),
                  tooltip: isDark ? 'Mudar para modo claro' : 'Mudar para modo escuro',
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                    )
                  ],
                ),
                child: PopupMenuButton<SortOrder>(
                  icon: Icon(Icons.tune_rounded,
                      color: Theme.of(context).textTheme.bodyLarge?.color),
                  tooltip: 'Ordenar metas',
                  initialValue: sortOrder,
                  onSelected: (order) =>
                      ref.read(sortOrderProvider.notifier).setOrder(order),
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: SortOrder.createdAt,
                      child: Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 18,
                            color: sortOrder == SortOrder.createdAt
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Mais recentes',
                              style: TextStyle(
                                fontWeight: sortOrder == SortOrder.createdAt
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (sortOrder == SortOrder.createdAt)
                            Icon(Icons.check_rounded,
                                size: 18,
                                color: Theme.of(context).colorScheme.primary),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: SortOrder.deadline,
                      child: Row(
                        children: [
                          Icon(
                            Icons.event_rounded,
                            size: 18,
                            color: sortOrder == SortOrder.deadline
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Por prazo',
                              style: TextStyle(
                                fontWeight: sortOrder == SortOrder.deadline
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (sortOrder == SortOrder.deadline)
                            Icon(Icons.check_rounded,
                                size: 18,
                                color: Theme.of(context).colorScheme.primary),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: SortOrder.progress,
                      child: Row(
                        children: [
                          Icon(
                            Icons.trending_up_rounded,
                            size: 18,
                            color: sortOrder == SortOrder.progress
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Por progresso',
                              style: TextStyle(
                                fontWeight: sortOrder == SortOrder.progress
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (sortOrder == SortOrder.progress)
                            Icon(Icons.check_rounded,
                                size: 18,
                                color: Theme.of(context).colorScheme.primary),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openDetail(BuildContext context, GoalModel goal) {
    Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => GoalDetailScreen(goalId: goal.id)));
  }

  void _openGoalForm(BuildContext context, {GoalModel? goal}) {
    Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => GoalFormScreen(existingGoal: goal)));
  }

  void _openDepositSheet(BuildContext context, WidgetRef ref, GoalModel goal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DepositScreen(goal: goal),
    );
  }

  Widget _buildEmptyState(
      BuildContext context, WidgetRef ref, SortOrder sortOrder) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              _buildCustomHeader(context, ref, sortOrder),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.savings_rounded,
                              size: 80,
                              color: Theme.of(context).colorScheme.primary),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'Comece a poupar hoje',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Crie a sua primeira meta financeira\ne acompanhe o seu progresso de forma inteligente.',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: const Color(0xFF64748B),
                                    height: 1.5,
                                  ),
                        ),
                        const SizedBox(height: 40),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 300),
                          child: ElevatedButton(
                            onPressed: () => _openGoalForm(context),
                            child: const Text('Criar primeira meta'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PremiumSummaryBanner extends StatelessWidget {
  final Map<String, dynamic> stats;

  const _PremiumSummaryBanner({required this.stats});

  @override
  Widget build(BuildContext context) {
    final totalSaved = (stats['totalSaved'] as double?) ?? 0;
    final totalTarget = (stats['totalTarget'] as double?) ?? 0;
    final overallProgress = (stats['overallProgress'] as double?) ?? 0;
    final totalGoals = (stats['totalGoals'] as int?) ?? 0;
    final completed = (stats['completed'] as int?) ?? 0;

    if (totalTarget == 0) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: isDark
            ? Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1.5)
            : null,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Patrimônio Guardado',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  AppFormatters.percent(overallProgress * 100),
                  style: const TextStyle(
                    color: Color(0xFF34D399),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            AppFormatters.currency(totalSaved),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'De ${AppFormatters.currency(totalTarget)} em $totalGoals meta${totalGoals != 1 ? 's' : ''}',
                style: const TextStyle(color: Colors.white60, fontSize: 13),
              ),
              if (completed > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 13,
                        color: Color(0xFF34D399),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$completed concluída${completed != 1 ? 's' : ''}',
                        style: const TextStyle(
                          color: Color(0xFF34D399),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  return Container(
                    height: 8,
                    width:
                        constraints.maxWidth * overallProgress.clamp(0.0, 1.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF34D399),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [
                        BoxShadow(color: Color(0xFF34D399), blurRadius: 8),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
