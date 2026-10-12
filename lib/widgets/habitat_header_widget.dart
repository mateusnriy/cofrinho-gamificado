import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/models/mascot_model.dart';
import 'porko_canvas_widget.dart';

// Cabeçalho imersivo com o habitat natural vivo do Porko (céu dia/noite, sol, lua e topbar)
class HabitatHeaderWidget extends StatelessWidget {
  final int coins;
  final int streakDays;
  final bool isDark;
  final bool hasGoals;
  final PorkoMood mood;
  final MascotModel mascot;
  final VoidCallback onProfileTap;
  final VoidCallback onCoinsTap;
  final VoidCallback onThemeToggle;
  final VoidCallback? onPorkoTap;

  const HabitatHeaderWidget({
    super.key,
    required this.coins,
    required this.streakDays,
    required this.isDark,
    required this.hasGoals,
    required this.mood,
    required this.mascot,
    required this.onProfileTap,
    required this.onCoinsTap,
    required this.onThemeToggle,
    this.onPorkoTap,
  });

  @override
  Widget build(BuildContext context) {
    // Gradientes fiéis ao protótipo v3 (prototype_oinc.html)
    const daySkyGradient = LinearGradient(
      colors: [
        Color(0xFF7DD3FC),
        Color(0xFFBAE6FD),
        Color(0xFF86EFAC),
        Color(0xFF34D399),
        Color(0xFF2E7D32),
      ],
      stops: [0.0, 0.38, 0.39, 0.70, 1.0],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );

    const nightSkyGradient = LinearGradient(
      colors: [
        Color(0xFF050B14),
        Color(0xFF0B1A2E),
        Color(0xFF0F3A26),
        Color(0xFF0D2D1D),
        Color(0xFF071A10),
      ],
      stops: [0.0, 0.38, 0.39, 0.70, 1.0],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );

    return Container(
      height: 340,
      decoration: BoxDecoration(
        gradient: isDark ? nightSkyGradient : daySkyGradient,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.22),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
        child: Stack(
          children: [
            // ── Camada Cenográfica: Dia ──────────────────────────────────────
            if (!isDark) ...[
              // Sol brilhante radiante
              Positioned(
                top: 66,
                right: 26,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [Color(0xFFFFF59D), Color(0xFFFBBF24)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFBBF24).withValues(alpha: 0.7),
                        blurRadius: 36,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),

              // Nuvens cenográficas
              const Positioned(
                top: 76,
                left: 24,
                child: Text('☁️', style: TextStyle(fontSize: 28)),
              ),
              const Positioned(
                top: 108,
                left: 170,
                child: Text('☁️', style: TextStyle(fontSize: 20)),
              ),

              // Colinas verdes orgânicas
              Positioned(
                bottom: -40,
                left: -50,
                child: Container(
                  width: 260,
                  height: 150,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(150),
                  ),
                ),
              ),
              Positioned(
                bottom: -50,
                right: -40,
                child: Container(
                  width: 290,
                  height: 160,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B5E20).withValues(alpha: 0.50),
                    borderRadius: BorderRadius.circular(160),
                  ),
                ),
              ),
            ],

            // ── Camada Cenográfica: Noite ────────────────────────────────────
            if (isDark) ...[
              // Lua crescente brilhante
              Positioned(
                top: 66,
                right: 28,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      center: Alignment(-0.35, -0.35),
                      colors: [Color(0xFFFEF9C3), Color(0xFFFDE68A)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFDE047).withValues(alpha: 0.55),
                        blurRadius: 32,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),

              // Estrelas cintilantes
              const Positioned(
                top: 82,
                left: 32,
                child: Text('✨', style: TextStyle(fontSize: 14)),
              ),
              const Positioned(
                top: 118,
                left: 110,
                child: Text('⭐', style: TextStyle(fontSize: 12)),
              ),
              const Positioned(
                top: 90,
                left: 220,
                child: Text('✨', style: TextStyle(fontSize: 13)),
              ),
              const Positioned(
                top: 136,
                left: 280,
                child: Text('⭐', style: TextStyle(fontSize: 12)),
              ),

              // Caminha aconchegante no canto da grama
              const Positioned(
                bottom: 30,
                left: 24,
                child: Text('🛏️', style: TextStyle(fontSize: 42)),
              ),
            ],

            // ── Mascote Porko Soft 3D no Centro da Grama ────────────────────
            Positioned(
              bottom: 22,
              left: 0,
              right: 0,
              child: PorkoCanvasWidget(
                mood: mood,
                mascot: mascot,
                showEmptySign: !hasGoals,
                onTap: onPorkoTap,
              ),
            ),

            // ── Barra Superior Integrada (TopBar) ───────────────────────────
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Perfil do usuário (Avatar + Saudação + Nível)
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        onProfileTap();
                      },
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFFFD1DC),
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text('🐷', style: TextStyle(fontSize: 22)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Olá, Ana!',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  height: 1.1,
                                ),
                              ),
                              Text(
                                'Nível 3 • Poupadora',
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFA7F3D0).withValues(alpha: 0.95),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Pílulas translúcidas com blur (Moedas, Streak, Tema)
                    Row(
                      children: [
                        // Pílula 1: Oinc Coins
                        _buildBlurPill(
                          onTap: onCoinsTap,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🪙', style: TextStyle(fontSize: 13)),
                              const SizedBox(width: 4),
                              Text(
                                '$coins',
                                style: const TextStyle(
                                  fontFamily: 'Quicksand',
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFDE68A),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),

                        // Pílula 2: Streak diário (apenas se streak > 0)
                        if (streakDays > 0) ...[
                          _buildBlurPill(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('🔥', style: TextStyle(fontSize: 13)),
                                const SizedBox(width: 4),
                                Text(
                                  '$streakDays d',
                                  style: const TextStyle(
                                    fontFamily: 'Quicksand',
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFFDE68A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],

                        // Pílula 3: Botão de Tema (Sol / Lua)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                            child: Container(
                              width: 38,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.28),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.22),
                                  width: 1,
                                ),
                              ),
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                iconSize: 16,
                                tooltip: isDark ? 'Mudar para modo claro' : 'Mudar para modo escuro',
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  onThemeToggle();
                                },
                                icon: Text(
                                  isDark ? '☀️' : '🌙',
                                  style: const TextStyle(fontSize: 14),
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
          ],
        ),
      ),
    );
  }

  // Pílula translúcida com efeito blur e borda suave
  Widget _buildBlurPill({
    required Widget child,
    VoidCallback? onTap,
    double? width,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            width: width,
            height: 36,
            padding: EdgeInsets.symmetric(
              horizontal: width != null ? 0 : 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.22),
                width: 1,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
