import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/providers/global_providers.dart';
import '../../data/models/goal_model.dart';
import '../../data/models/mascot_model.dart';
import '../../data/repositories/goal_repository.dart';
import '../../widgets/goal_card.dart';
import '../../widgets/custom_docked_bottom_bar.dart';
import '../../widgets/habitat_header_widget.dart';
import '../goal_form/goal_form_screen.dart';
import '../goal_detail/goal_detail_screen.dart';
import '../deposit/deposit_screen.dart';
import '../gamification/badges_gallery_screen.dart';
import '../shop/porko_store_screen.dart';
import '../mascot/mascot_screen.dart';
import '../profile/profile_settings_modal.dart';
import 'home_provider.dart';

/// Tela principal com habitat orgânico Soft 3D, colapso suave no scroll (340px -> 116px),
/// filtro de metas tipo menu sanduíche (☰), 4 abas e botão central (+) projetado.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentTabIndex = 0;

  // Controle de exibição do total acumulado (privacidade temporizada de 3s)
  bool _showTotalAmount = false;
  Timer? _totalPrivacyTimer;

  // Controle de colapso suave do Habitat (340px -> 116px) durante o scroll
  final ScrollController _scrollController = ScrollController();
  double _collapseProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final offset = _scrollController.offset;
    final nextProgress = (offset / 180.0).clamp(0.0, 1.0);
    if ((nextProgress - _collapseProgress).abs() > 0.02) {
      setState(() => _collapseProgress = nextProgress);
    }
  }

  @override
  void dispose() {
    _totalPrivacyTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleRevealTotal() {
    HapticFeedback.lightImpact();
    setState(() {
      _showTotalAmount = !_showTotalAmount;
    });

    if (_showTotalAmount) {
      _totalPrivacyTimer?.cancel();
      _totalPrivacyTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() => _showTotalAmount = false);
        }
      });
    }
  }

  void _openGoalForm(BuildContext context, {GoalModel? goal}) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => GoalFormScreen(existingGoal: goal)),
    );
  }

  void _openDetail(BuildContext context, GoalModel goal) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => GoalDetailScreen(goalId: goal.id)),
    );
  }

  void _openDepositSheet(BuildContext context, GoalModel goal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DepositScreen(goal: goal),
    );
  }

  void _openProfileModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ProfileSettingsModal(),
    );
  }

  /// Abre o Menu Sanduíche (☰) de Filtro e Ordenação das Metas (AUD-06)
  void _openHamburgerFilterSheet(BuildContext context) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Consumer(
          builder: (ctx, sheetRef, _) {
            final isDark = Theme.of(ctx).brightness == Brightness.dark;
            final currentFilter = sheetRef.watch(goalFilterProvider);
            final currentSort = sheetRef.watch(sortOrderProvider);
            final primary =
                isDark ? const Color(0xFF00C853) : const Color(0xFF2E7D32);

            return Container(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 28),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1B2E22) : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(32)),
                border: Border.all(
                  color:
                      isDark ? const Color(0xFF2F4A37) : const Color(0xFFE2E8E2),
                ),
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 44,
                          height: 5,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.menu_rounded, color: primary, size: 22),
                              const SizedBox(width: 8),
                              Text(
                                'Filtrar & Ordenar Metas',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF1A1A1A),
                                ),
                              ),
                            ],
                          ),
                          if (currentFilter != GoalFilter.all ||
                              currentSort != SortOrder.createdAt)
                            TextButton(
                              onPressed: () {
                                sheetRef
                                    .read(goalFilterProvider.notifier)
                                    .setFilter(GoalFilter.all);
                                sheetRef
                                    .read(sortOrderProvider.notifier)
                                    .setOrder(SortOrder.createdAt);
                              },
                              child: Text(
                                'Limpar filtros',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: primary,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'FILTRAR POR STATUS OU RITMO',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: isDark
                              ? const Color(0xFFA5D6A7)
                              : const Color(0xFF566259),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildFilterChip(
                            label: '📋 Todas',
                            selected: currentFilter == GoalFilter.all,
                            isDark: isDark,
                            primary: primary,
                            onTap: () {
                              sheetRef
                                  .read(goalFilterProvider.notifier)
                                  .setFilter(GoalFilter.all);
                            },
                          ),
                          _buildFilterChip(
                            label: '⏳ Em andamento',
                            selected: currentFilter == GoalFilter.inProgress,
                            isDark: isDark,
                            primary: primary,
                            onTap: () {
                              sheetRef
                                  .read(goalFilterProvider.notifier)
                                  .setFilter(GoalFilter.inProgress);
                            },
                          ),
                          _buildFilterChip(
                            label: '🏆 Concluídas',
                            selected: currentFilter == GoalFilter.completed,
                            isDark: isDark,
                            primary: primary,
                            onTap: () {
                              sheetRef
                                  .read(goalFilterProvider.notifier)
                                  .setFilter(GoalFilter.completed);
                            },
                          ),
                          _buildFilterChip(
                            label: '📅 Com prazo',
                            selected: currentFilter == GoalFilter.withDeadline,
                            isDark: isDark,
                            primary: primary,
                            onTap: () {
                              sheetRef
                                  .read(goalFilterProvider.notifier)
                                  .setFilter(GoalFilter.withDeadline);
                            },
                          ),
                          _buildFilterChip(
                            label: '🌱 No meu ritmo',
                            selected: currentFilter == GoalFilter.freePace,
                            isDark: isDark,
                            primary: primary,
                            onTap: () {
                              sheetRef
                                  .read(goalFilterProvider.notifier)
                                  .setFilter(GoalFilter.freePace);
                            },
                          ),
                          _buildFilterChip(
                            label: '📦 Arquivadas',
                            selected: currentFilter == GoalFilter.archived,
                            isDark: isDark,
                            primary: primary,
                            onTap: () {
                              sheetRef
                                  .read(goalFilterProvider.notifier)
                                  .setFilter(GoalFilter.archived);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'ORDENAR POR',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: isDark
                              ? const Color(0xFFA5D6A7)
                              : const Color(0xFF566259),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildSortOptionTile(
                        title: 'Mais recentes',
                        subtitle: 'Metas criadas por último no topo',
                        icon: Icons.schedule_rounded,
                        selected: currentSort == SortOrder.createdAt,
                        isDark: isDark,
                        primary: primary,
                        onTap: () {
                          sheetRef
                              .read(sortOrderProvider.notifier)
                              .setOrder(SortOrder.createdAt);
                          Navigator.pop(ctx);
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildSortOptionTile(
                        title: 'Por prazo',
                        subtitle: 'Prazo mais curto primeiro',
                        icon: Icons.event_available_rounded,
                        selected: currentSort == SortOrder.deadline,
                        isDark: isDark,
                        primary: primary,
                        onTap: () {
                          sheetRef
                              .read(sortOrderProvider.notifier)
                              .setOrder(SortOrder.deadline);
                          Navigator.pop(ctx);
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildSortOptionTile(
                        title: 'Por progresso',
                        subtitle: 'Maior porcentagem concluída no topo',
                        icon: Icons.trending_up_rounded,
                        selected: currentSort == SortOrder.progress,
                        isDark: isDark,
                        primary: primary,
                        onTap: () {
                          sheetRef
                              .read(sortOrderProvider.notifier)
                              .setOrder(SortOrder.progress);
                          Navigator.pop(ctx);
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildSortOptionTile(
                        title: 'Maior valor guardado',
                        subtitle: 'Maior saldo acumulado em R\$ no topo',
                        icon: Icons.savings_rounded,
                        selected: currentSort == SortOrder.savedAmount,
                        isDark: isDark,
                        primary: primary,
                        onTap: () {
                          sheetRef
                              .read(sortOrderProvider.notifier)
                              .setOrder(SortOrder.savedAmount);
                          Navigator.pop(ctx);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required bool isDark,
    required Color primary,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? primary
              : (isDark ? const Color(0xFF243B2A) : const Color(0xFFEEF3EE)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? primary
                : (isDark ? const Color(0xFF2F4A37) : const Color(0xFFE2E8E2)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected
                ? (isDark ? const Color(0xFF04210F) : Colors.white)
                : (isDark ? Colors.white : const Color(0xFF1A1A1A)),
          ),
        ),
      ),
    );
  }

  Widget _buildSortOptionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool selected,
    required bool isDark,
    required Color primary,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: selected
              ? primary.withValues(alpha: 0.14)
              : (isDark ? const Color(0xFF243B2A) : const Color(0xFFEEF3EE)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? primary
                : (isDark ? const Color(0xFF2F4A37) : const Color(0xFFE2E8E2)),
            width: selected ? 1.8 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: selected
                  ? primary
                  : (isDark ? const Color(0xFFA5D6A7) : const Color(0xFF566259)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFFA5D6A7)
                          : const Color(0xFF566259),
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle_rounded, color: primary, size: 20),
          ],
        ),
      ),
    );
  }

  /// Abre o menu rápido do botão central (+) idêntico ao `#fabSheet` do protótipo (empilhado em Column)
  void _openQuickActionSheet(BuildContext context, List<GoalModel> goals) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final isDark = theme.brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1B2E22) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(
              color: isDark ? const Color(0xFF2F4A37) : const Color(0xFFE2E8E2),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
                Text(
                  'O que você quer fazer?',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Escolha uma ação rápida para o seu cofrinho:',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? const Color(0xFFA5D6A7)
                        : const Color(0xFF566259),
                  ),
                ),
                const SizedBox(height: 14),
                _buildFabActionRowCard(
                  isDark: isDark,
                  emoji: '💰',
                  title: 'Novo Depósito',
                  subtitle:
                      'Guardar dinheiro em uma meta existente e ganhar Oinc Coins',
                  gradientColors: const [Color(0xFF2E7D32), Color(0xFF66BB6A)],
                  onTap: () {
                    Navigator.pop(ctx);
                    if (goals.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              const Text('Crie uma meta primeiro para depositar! 🎯'),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                      _openGoalForm(context);
                    } else {
                      _openDepositSheet(context, goals.first);
                    }
                  },
                ),
                const SizedBox(height: 10),
                _buildFabActionRowCard(
                  isDark: isDark,
                  emoji: '🎯',
                  title: 'Nova Meta',
                  subtitle:
                      'Criar um novo objetivo com prazo ou no seu próprio ritmo',
                  gradientColors: const [Color(0xFF1565C0), Color(0xFF42A5F5)],
                  onTap: () {
                    Navigator.pop(ctx);
                    _openGoalForm(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFabActionRowCard({
    required bool isDark,
    required String emoji,
    required String title,
    required String subtitle,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF243B2A) : const Color(0xFFEEF3EE),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? const Color(0xFF2F4A37) : const Color(0xFFE2E8E2),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: gradientColors.first.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFFA5D6A7)
                          : const Color(0xFF566259),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '›',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: isDark
                    ? const Color(0xFFA5D6A7)
                    : const Color(0xFF566259),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final goals = ref.watch(homeGoalsProvider);
    final stats = ref.watch(goalStatsProvider);
    final sortOrder = ref.watch(sortOrderProvider);
    final goalFilter = ref.watch(goalFilterProvider);
    final porkoMood = ref.watch(porkoMoodProvider);
    final equippedMascot = ref.watch(equippedMascotProvider);
    final streakData = ref.watch(streakProvider);
    final currentStreak = (streakData['currentStreak'] as int?) ?? 0;
    final walletBalance = ref.watch(walletBalanceProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget activeBody;
    switch (_currentTabIndex) {
      case 1:
        activeBody = const BadgesGalleryScreen();
        break;
      case 2:
        activeBody = const PorkoStoreScreen();
        break;
      case 3:
        activeBody = const MascotScreen();
        break;
      case 0:
      default:
        activeBody = _buildHomeDashboard(
          context: context,
          goals: goals,
          stats: stats,
          sortOrder: sortOrder,
          goalFilter: goalFilter,
          porkoMood: porkoMood,
          equippedMascot: equippedMascot,
          coins: walletBalance,
          streakDays: currentStreak,
          isDark: isDark,
        );
        break;
    }

    return Scaffold(
      body: activeBody,
      bottomNavigationBar: CustomDockedBottomBar(
        currentIndex: _currentTabIndex,
        onTabSelected: (index) {
          setState(() => _currentTabIndex = index);
        },
        onFabPressed: () => _openQuickActionSheet(context, goals),
      ),
    );
  }

  Widget _buildHomeDashboard({
    required BuildContext context,
    required List<GoalModel> goals,
    required Map<String, dynamic> stats,
    required SortOrder sortOrder,
    required GoalFilter goalFilter,
    required PorkoMood porkoMood,
    required MascotModel equippedMascot,
    required int coins,
    required int streakDays,
    required bool isDark,
  }) {
    final totalSaved = (stats['totalSaved'] as double?) ?? 0.0;
    final totalActiveGoals = (stats['totalGoals'] as int?) ?? 0;
    final hasCustomFilterOrSort =
        goalFilter != GoalFilter.all || sortOrder != SortOrder.createdAt;
    final primary = isDark ? const Color(0xFF00C853) : const Color(0xFF2E7D32);

    return SingleChildScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── 1. Habitat Natural Vivo do Porko (340px -> 116px no scroll) ───
          HabitatHeaderWidget(
            coins: coins,
            streakDays: streakDays,
            isDark: isDark,
            hasGoals: totalActiveGoals > 0,
            mood: porkoMood,
            mascot: equippedMascot,
            collapseProgress: _collapseProgress,
            onProfileTap: () => _openProfileModal(context),
            onCoinsTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Saldo: $coins Oinc Coins! Ganhe +1 por real poupado e +50 no 1º depósito do dia.',
                  ),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
              setState(() => _currentTabIndex = 2);
            },
            onThemeToggle: () {
              ref.read(themeProvider.notifier).toggleTheme();
            },
            onPorkoTap: () {
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    porkoMood == PorkoMood.sleeping
                        ? 'Oinc! O Porko acordou para dizer oi! 💤'
                        : 'Oinc! Continue poupando todos os dias! 🪙',
                  ),
                  duration: const Duration(milliseconds: 1800),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // ── 2. Cabeçalho "🎯 Minhas metas" + Ver Total + Menu Sanduíche (☰) + Nova ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Flexible(
                  child: Text(
                    '🎯 Minhas metas',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Pílula "👁️ Ver total" (Timer de 3s)
                    GestureDetector(
                      onTap: _toggleRevealTotal,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF243B2A)
                              : const Color(0xFFEEF3EE),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF2F4A37)
                                : const Color(0xFFE2E8E2),
                          ),
                        ),
                        child: Text(
                          _showTotalAmount
                              ? '💰 ${AppFormatters.currency(totalSaved)}'
                              : '👁️ Ver total',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF1A1A1A),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Botão de Filtro do Tipo Menu Sanduíche (☰) (AUD-06)
                    Tooltip(
                      message: 'Ordenar metas',
                      child: Semantics(
                        button: true,
                        label: 'Menu sanduíche para filtrar e ordenar metas',
                        child: InkWell(
                          onTap: () => _openHamburgerFilterSheet(context),
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 36,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF243B2A)
                                      : const Color(0xFFEEF3EE),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: hasCustomFilterOrSort
                                        ? primary
                                        : (isDark
                                            ? const Color(0xFF2F4A37)
                                            : const Color(0xFFE2E8E2)),
                                    width: hasCustomFilterOrSort ? 1.6 : 1.0,
                                  ),
                                ),
                                child: Icon(
                                  Icons.menu_rounded,
                                  size: 20,
                                  color: hasCustomFilterOrSort
                                      ? primary
                                      : (isDark
                                          ? Colors.white
                                          : const Color(0xFF1A1A1A)),
                                ),
                              ),
                              if (hasCustomFilterOrSort)
                                Positioned(
                                  top: -2,
                                  right: -2,
                                  child: Container(
                                    width: 9,
                                    height: 9,
                                    decoration: BoxDecoration(
                                      color: primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isDark
                                            ? const Color(0xFF0D1F14)
                                            : Colors.white,
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Botão "+ Nova" idêntico ao protótipo
                    InkWell(
                      onTap: () => _openGoalForm(context),
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '+ Nova',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── 3. Lista de Cards ou Estado Vazio (.empty-card com borda tracejada) ──
          if (goals.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: _DashedEmptyCard(
                isDark: isDark,
                isFilteredEmpty:
                    totalActiveGoals > 0 && goalFilter != GoalFilter.all,
                onActionTap: () {
                  if (totalActiveGoals > 0 && goalFilter != GoalFilter.all) {
                    ref
                        .read(goalFilterProvider.notifier)
                        .setFilter(GoalFilter.all);
                  } else {
                    _openGoalForm(context);
                  }
                },
              ),
            ),
          ] else ...[
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              itemCount: goals.length,
              itemBuilder: (context, index) {
                final goal = goals[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GoalCard(
                    goal: goal,
                    onTap: () => _openDetail(context, goal),
                    onAddDeposit: () => _openDepositSheet(context, goal),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

/// Card de Estado Vazio idêntico a `.empty-card` do protótipo (borda 2px dashed)
class _DashedEmptyCard extends StatelessWidget {
  final bool isDark;
  final bool isFilteredEmpty;
  final VoidCallback onActionTap;

  const _DashedEmptyCard({
    required this.isDark,
    required this.isFilteredEmpty,
    required this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = isDark ? const Color(0xFF00C853) : const Color(0xFF2E7D32);
    final borderColor =
        isDark ? const Color(0xFF2F4A37) : const Color(0xFFCBD5E1);

    return CustomPaint(
      painter: _DashedRRectPainter(
        color: borderColor,
        radius: 26,
        strokeWidth: 2,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1B2E22) : Colors.white,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Column(
          children: [
            Text(
              isFilteredEmpty ? '🔍' : '🌱',
              style: const TextStyle(fontSize: 42),
            ),
            const SizedBox(height: 8),
            Text(
              isFilteredEmpty
                  ? 'Nenhuma meta neste filtro'
                  : 'Seu cofrinho está vazio!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF1A1A1A),
              ),
            ),
            if (!isFilteredEmpty) ...[
              const SizedBox(height: 2),
              Text(
                'Comece a poupar hoje',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: primary,
                ),
              ),
            ],
            const SizedBox(height: 6),
            Text(
              isFilteredEmpty
                  ? 'Altere ou limpe o filtro do menu sanduíche (☰) para ver suas outras metas.'
                  : 'Crie sua primeira meta em menos de 1 minuto. O Porko vai cuidar das suas economias e te recompensar a cada depósito!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color:
                    isDark ? const Color(0xFFA5D6A7) : const Color(0xFF566259),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onActionTap,
                icon: Icon(
                  isFilteredEmpty ? Icons.filter_alt_off_rounded : Icons.add_rounded,
                  size: 18,
                ),
                label: Text(
                  isFilteredEmpty ? 'Mostrar todas as metas' : 'Criar primeira meta',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor:
                      isDark ? const Color(0xFF04210F) : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double strokeWidth;

  _DashedRRectPainter({
    required this.color,
    required this.radius,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);

    const dashWidth = 7.0;
    const dashSpace = 5.0;
    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final next = (distance + dashWidth).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRRectPainter old) =>
      old.color != color ||
      old.radius != radius ||
      old.strokeWidth != strokeWidth;
}
