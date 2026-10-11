import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../../core/providers/theme_provider.dart';
import '../../data/models/goal_model.dart';
import '../../data/repositories/goal_repository.dart';
import '../../widgets/goal_card.dart';
import '../goal_form/goal_form_screen.dart';
import '../goal_detail/goal_detail_screen.dart';
import '../deposit/deposit_screen.dart';
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
    // Escuta mudanças de tema para disparar rebuild reativo
    ref.watch(themeProvider);
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
                  tooltip: 'Filtrar',
                  initialValue: sortOrder,
                  onSelected: (order) =>
                      ref.read(sortOrderProvider.notifier).state = order,
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                        value: SortOrder.createdAt,
                        child: Text('Mais recentes')),
                    PopupMenuItem(
                        value: SortOrder.deadline, child: Text('Por prazo')),
                    PopupMenuItem(
                        value: SortOrder.progress,
                        child: Text('Por progresso')),
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
                'Património Guardado',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500),
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
                      fontSize: 13),
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
          const SizedBox(height: 24),
          Text(
            'De ${AppFormatters.currency(totalTarget)} em metas globais',
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Stack(
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  return Container(
                    height: 6,
                    width:
                        constraints.maxWidth * overallProgress.clamp(0.0, 1.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF34D399),
                      borderRadius: BorderRadius.circular(6),
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
