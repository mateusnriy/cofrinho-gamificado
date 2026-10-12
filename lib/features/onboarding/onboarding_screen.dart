import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../data/models/mascot_model.dart';
import '../../widgets/porko_canvas_widget.dart';
import '../home/home_screen.dart';
import '../goal_form/goal_form_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutBack,
      ),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboardingAndStartGoal() async {
    HapticFeedback.mediumImpact();
    final settingsBox = Hive.box('settings');
    await settingsBox.put('has_seen_onboarding', true);

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const GoalFormScreen()),
    );
  }

  Future<void> _completeOnboardingAndGoHome() async {
    HapticFeedback.lightImpact();
    final settingsBox = Hive.box('settings');
    await settingsBox.put('has_seen_onboarding', true);

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFF00C853) : const Color(0xFF2E7D32);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1F14) : const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      // Pílula de Identidade Oinc
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.savings_rounded,
                              size: 16,
                              color: primaryColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Oinc — Meu cofrinho virtual',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      // Palco Soft 3D do Mascote Porko
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: _buildPorko3DHero(isDark),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        'Olá! Eu sou o Porko 🐷\nBem-vindo ao Oinc!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Transforme o hábito de poupar em uma jornada leve, visual em 3D e 100% livre de culpa.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                          color: isDark
                              ? const Color(0xFFA5D6A7)
                              : const Color(0xFF566259),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildBenefitItem(
                        icon: Icons.track_changes_rounded,
                        iconColor: const Color(0xFF10B981),
                        title: 'Metas com Propósito',
                        description:
                            'Defina seus objetivos e acompanhe sua evolução em tempo real com 4 marcos automáticos.',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),
                      _buildBenefitItem(
                        icon: Icons.calendar_today_rounded,
                        iconColor: const Color(0xFF3B82F6),
                        title: 'Projeções Inteligentes',
                        description:
                            'Descubra quanto poupar por dia, semana ou mês — ou guarde no seu próprio ritmo sem pressão.',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),
                      _buildBenefitItem(
                        icon: Icons.emoji_events_rounded,
                        iconColor: const Color(0xFFF59E0B),
                        title: 'Gamificação & Recompensas',
                        description:
                            'Ganhe Oinc Coins a cada depósito, desbloqueie medalhas 3D e vista o Porko na lojinha!',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // Botões na Zona do Polegar
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    onPressed: _completeOnboardingAndStartGoal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      elevation: 4,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Criar Primeira Meta',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 20),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _completeOnboardingAndGoHome,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      foregroundColor: isDark
                          ? const Color(0xFFA5D6A7)
                          : const Color(0xFF566259),
                    ),
                    child: const Text(
                      'Explorar o aplicativo primeiro',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPorko3DHero(bool isDark) {
    return Container(
      width: 170,
      height: 150,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [Color(0xFF0B1A2E), Color(0xFF0F3A26), Color(0xFF1B5E20)]
              : const [Color(0xFF7DD3FC), Color(0xFF86EFAC), Color(0xFF34D399)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const PorkoCanvasWidget(
            mood: PorkoMood.happy,
            mascot: MascotModel(),
            compact: true,
          ),
          Positioned(
            right: 12,
            top: 12,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFFF59E0B),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.star_rounded,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B2E22) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF2F4A37) : const Color(0xFFE2E8E2),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 22,
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
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12.5,
                    height: 1.35,
                    color: isDark
                        ? const Color(0xFFA5D6A7)
                        : const Color(0xFF566259),
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
