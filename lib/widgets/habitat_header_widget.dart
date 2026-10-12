import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/models/mascot_model.dart';
import 'porko_canvas_widget.dart';

/// Cabeçalho imersivo com o habitat natural vivo do Porko (céu dia/noite, sol, lua,
/// decorações de cenário `#sceneDeco`, caminhada Soft 3D e colapso suave no scroll `340px -> 116px`).
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
  final double collapseProgress; // 0.0 (340px expandido) a 1.0 (116px compacto)

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
    this.collapseProgress = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    final t = collapseProgress.clamp(0.0, 1.0);
    final currentHeight = lerpDouble(340.0, 116.0, t)!;
    final sceneOpacity = (1.0 - (t * 1.45)).clamp(0.0, 1.0);

    // Lê nome e avatar personalizados da box 'settings' se aberta
    String userName = 'Ana';
    String userAvatar = '🐷';
    if (Hive.isBoxOpen('settings')) {
      final box = Hive.box('settings');
      userName = (box.get('user_name', defaultValue: 'Ana') as String?)?.trim() ?? 'Ana';
      if (userName.isEmpty) userName = 'Ana';
      userAvatar = (box.get('user_avatar', defaultValue: '🐷') as String?) ?? '🐷';
    }

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

    return AnimatedContainer(
      duration: const Duration(milliseconds: 90),
      height: currentHeight,
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
            // ── Camada Cenográfica (Oculta suavemente durante o scroll) ──────
            if (sceneOpacity > 0.02)
              Opacity(
                opacity: sceneOpacity,
                child: Stack(
                  children: [
                    // Dia
                    if (!isDark) ...[
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

                    // Noite
                    if (isDark) ...[
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
                      const Positioned(
                        bottom: 30,
                        left: 24,
                        child: Text('🛏️', style: TextStyle(fontSize: 42)),
                      ),
                    ],

                    // Decoração do Cenário Equipado (#sceneDeco)
                    ..._buildSceneDecorations(mascot.backdropId),

                    // Mascote Porko Soft 3D Vivo no Centro da Grama
                    Positioned(
                      bottom: 20,
                      left: 0,
                      right: 0,
                      child: PorkoCanvasWidget(
                        mood: mood,
                        mascot: mascot,
                        showEmptySign: !hasGoals,
                        enableWalking: true,
                        onTap: onPorkoTap,
                      ),
                    ),
                  ],
                ),
              ),

            // ── Barra Superior Integrada Responsiva (TopBar) ────────────────
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Perfil do usuário com Flexible para evitar overflow em 320px
                    Flexible(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          onProfileTap();
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const RadialGradient(
                                  center: Alignment(-0.3, -0.35),
                                  colors: [Color(0xFFFFDCE5), Color(0xFFFF8DA1)],
                                ),
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.22),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  userAvatar,
                                  style: const TextStyle(fontSize: 22),
                                ),
                              ),
                            ),
                            const SizedBox(width: 9),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Olá, $userName!',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      height: 1.1,
                                    ),
                                  ),
                                  Text(
                                    'Nível 3 • Poupador(a)',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: 'Nunito',
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFFA7F3D0)
                                          .withValues(alpha: 0.95),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Pílulas translúcidas com blur (Moedas, Streak, Tema)
                    Row(
                      mainAxisSize: MainAxisSize.min,
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
                                tooltip: isDark
                                    ? 'Mudar para modo claro'
                                    : 'Mudar para modo escuro',
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

  /// Renderiza decorações cenográficas no gramado conforme o cenário equipado (#sceneDeco)
  List<Widget> _buildSceneDecorations(String? backdropId) {
    switch (backdropId) {
      case 'backdrop_beach':
      case 'bg_beach':
        return const [
          Positioned(
            bottom: 34,
            right: 22,
            child: Text('🏖️', style: TextStyle(fontSize: 34)),
          ),
          Positioned(
            bottom: 44,
            left: 24,
            child: Text('🌴', style: TextStyle(fontSize: 30)),
          ),
        ];
      case 'backdrop_park':
      case 'bg_park':
        return const [
          Positioned(
            bottom: 34,
            right: 20,
            child: Text('🌳', style: TextStyle(fontSize: 36)),
          ),
          Positioned(
            bottom: 42,
            left: 20,
            child: Text('🌲', style: TextStyle(fontSize: 30)),
          ),
        ];
      case 'backdrop_city':
        return const [
          Positioned(
            bottom: 34,
            right: 22,
            child: Text('🌆', style: TextStyle(fontSize: 32)),
          ),
          Positioned(
            bottom: 40,
            left: 24,
            child: Text('✨', style: TextStyle(fontSize: 24)),
          ),
        ];
      default:
        return const [];
    }
  }

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
