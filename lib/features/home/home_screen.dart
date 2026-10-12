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

// Tela principal com habitat orgânico, 4 abas e o botão central (+) projetado
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // Guarda a aba atualmente selecionada
  int _currentTabIndex = 0;

  // Controle de exibição do total acumulado (privacidade temporizada de 3s)
  bool _showTotalAmount = false;
  Timer? _totalPrivacyTimer;

  @override
  void dispose() {
    _totalPrivacyTimer?.cancel();
    super.dispose();
  }

  // Alterna a exibição do total guardado com timer de 3 segundos
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

  // Abre a tela de criar nova meta financeira
  void _openGoalForm(BuildContext context, {GoalModel? goal}) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => GoalFormScreen(existingGoal: goal)),
    );
  }

  // Abre a tela de detalhes de uma meta ao tocar nela
  void _openDetail(BuildContext context, GoalModel goal) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => GoalDetailScreen(goalId: goal.id)),
    );
  }

  // Abre a tela para registrar um depósito na meta
  void _openDepositSheet(BuildContext context, GoalModel goal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DepositScreen(goal: goal),
    );
  }

  // Abre o modal de configurações de perfil e tema
  void _openProfileModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ProfileSettingsModal(),
    );
  }

  // Abre o menu deslizante central com as duas opções rápidas do botão (+)
  void _openQuickActionSheet(BuildContext context, List<GoalModel> goals) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final isDark = theme.brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1B2E22) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: isDark ? const Color(0xFF2F4A37) : const Color(0xFFE2E8E2),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 5,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              Text(
                'O que você deseja fazer?',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      ctx: ctx,
                      emoji: '💰',
                      title: 'Novo Depósito',
                      subtitle: 'Guardar moedinhas',
                      color: const Color(0xFF10B981),
                      onTap: () {
                        Navigator.pop(ctx);
                        if (goals.isEmpty) {
                          _openGoalForm(context);
                        } else {
                          _openDepositSheet(context, goals.first);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildActionCard(
                      ctx: ctx,
                      emoji: '🎯',
                      title: 'Nova Meta',
                      subtitle: 'Criar novo objetivo',
                      color: const Color(0xFF3B82F6),
                      onTap: () {
                        Navigator.pop(ctx);
                        _openGoalForm(context);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // Card com opção do menu rápido do botão (+)
  Widget _buildActionCard({
    required BuildContext ctx,
    required String emoji,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.30)),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Nunito',
                color: Colors.grey.shade600,
                fontSize: 11,
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
    final porkoMood = ref.watch(porkoMoodProvider);
    final equippedMascot = ref.watch(equippedMascotProvider);
    final streakData = ref.watch(streakProvider);
    final currentStreak = (streakData['currentStreak'] as int?) ?? 0;
    final walletBalance = ref.watch(walletBalanceProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Se estiver em outra aba selecionada, exibe a respectiva tela
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

  // Monta a tela inicial com o habitat no topo e a lista de metas
  Widget _buildHomeDashboard({
    required BuildContext context,
    required List<GoalModel> goals,
    required Map<String, dynamic> stats,
    required SortOrder sortOrder,
    required PorkoMood porkoMood,
    required MascotModel equippedMascot,
    required int coins,
    required int streakDays,
    required bool isDark,
  }) {
    final totalSaved = (stats['totalSaved'] as double?) ?? 0.0;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── 1. Habitat Natural Vivo do Porko (340px) ──────────────────────
          HabitatHeaderWidget(
            coins: coins,
            streakDays: streakDays,
            isDark: isDark,
            hasGoals: goals.isNotEmpty,
            mood: porkoMood,
            mascot: equippedMascot,
            onProfileTap: () => _openProfileModal(context),
            onCoinsTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Saldo: $coins Oinc Coins! Ganhe +1 por real poupado e +50 no 1º depósito do dia.',
                  ),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // ── 2. Seção "Minhas Metas" ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '🎯 Minhas metas',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    // Botão "👁️ Ver total" com privacidade
                    GestureDetector(
                      onTap: _toggleRevealTotal,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF243B2A) : const Color(0xFFEEF3EE),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: isDark ? const Color(0xFF2F4A37) : const Color(0xFFE2E8E2),
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
                            color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Menu popup de ordenação
                    PopupMenuButton<SortOrder>(
                      tooltip: 'Ordenar metas',
                      initialValue: sortOrder,
                      onSelected: (order) {
                        HapticFeedback.selectionClick();
                        ref.read(sortOrderProvider.notifier).setOrder(order);
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      color: isDark ? const Color(0xFF1B2E22) : Colors.white,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF243B2A) : const Color(0xFFEEF3EE),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: isDark ? const Color(0xFF2F4A37) : const Color(0xFFE2E8E2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _sortOrderLabel(sortOrder),
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(Icons.arrow_drop_down_rounded, size: 16),
                          ],
                        ),
                      ),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: SortOrder.createdAt,
                          child: Text('Mais recentes', style: TextStyle(fontSize: 13)),
                        ),
                        const PopupMenuItem(
                          value: SortOrder.deadline,
                          child: Text('Por prazo', style: TextStyle(fontSize: 13)),
                        ),
                        const PopupMenuItem(
                          value: SortOrder.progress,
                          child: Text('Por progresso', style: TextStyle(fontSize: 13)),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ── 3. Lista de Cards ou Estado Vazio ─────────────────────────────
          if (goals.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: Column(
                children: [
                  const Text(
                    'Comece a poupar hoje',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Crie a sua primeira meta financeira\ne acompanhe o seu progresso de forma inteligente.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 14,
                      color: isDark ? const Color(0xFFA5D6A7) : const Color(0xFF566259),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => _openGoalForm(context),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Criar primeira meta'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? const Color(0xFF00C853) : const Color(0xFF2E7D32),
                      foregroundColor: isDark ? const Color(0xFF04210F) : Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    ),
                  ),
                ],
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

  // Rótulo textual da ordenação escolhida
  String _sortOrderLabel(SortOrder order) {
    switch (order) {
      case SortOrder.deadline:
        return 'Prazo mais curto';
      case SortOrder.progress:
        return 'Maior progresso';
      case SortOrder.createdAt:
        return 'Mais recentes';
    }
  }
}
