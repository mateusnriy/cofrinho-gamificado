import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum CelebrationType {
  goalCompleted,
  milestoneReached,
  badgeUnlocked,
}

class CelebrationOverlay extends StatefulWidget {
  final String title;
  final String subtitle;
  final String emoji;
  final Color accentColor;
  final VoidCallback onDismiss;

  const CelebrationOverlay({
    super.key,
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.accentColor,
    required this.onDismiss,
  });

  /// Exibe celebração clássica de meta atingida (mantém compatibilidade)
  static void show(BuildContext context, String goalName) {
    showGoalCompleted(context, goalName: goalName);
  }

  /// Exibe celebração épica de conclusão de meta
  static void showGoalCompleted(
    BuildContext context, {
    required String goalName,
    OverlayState? overlayState,
    VoidCallback? onDismiss,
  }) {
    _insertOverlay(
      context,
      overlayState: overlayState,
      title: 'Meta Atingida!',
      subtitle: 'Parabéns! Você concluiu a meta\n"$goalName"',
      emoji: '🏆',
      accentColor: const Color(0xFF10B981),
      onDismiss: onDismiss,
    );
  }

  /// Exibe celebração ao alcançar um novo marco (25%, 50%, 75%)
  static void showMilestoneReached(
    BuildContext context, {
    required String goalName,
    required int milestonePercent,
    OverlayState? overlayState,
    VoidCallback? onDismiss,
  }) {
    _insertOverlay(
      context,
      overlayState: overlayState,
      title: 'Novo Marco Conquistado!',
      subtitle: 'Você atingiu o marco de $milestonePercent% da meta\n"$goalName"',
      emoji: '🎯',
      accentColor: const Color(0xFF3B82F6),
      onDismiss: onDismiss,
    );
  }

  /// Exibe celebração ao desbloquear uma conquista (badge)
  static void showBadgeUnlocked(
    BuildContext context, {
    required String badgeTitle,
    OverlayState? overlayState,
    VoidCallback? onDismiss,
  }) {
    _insertOverlay(
      context,
      overlayState: overlayState,
      title: 'Conquista Desbloqueada!',
      subtitle: 'Você desbloqueou o emblema lendário\n"$badgeTitle"',
      emoji: '🏅',
      accentColor: const Color(0xFFF59E0B),
      onDismiss: onDismiss,
    );
  }

  static void _insertOverlay(
    BuildContext context, {
    OverlayState? overlayState,
    required String title,
    required String subtitle,
    required String emoji,
    required Color accentColor,
    VoidCallback? onDismiss,
  }) {
    final overlay = overlayState ??
        Overlay.maybeOf(context) ??
        Navigator.maybeOf(context)?.overlay;
    if (overlay == null) return;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => CelebrationOverlay(
        title: title,
        subtitle: subtitle,
        emoji: emoji,
        accentColor: accentColor,
        onDismiss: () {
          try {
            entry.remove();
          } catch (_) {}
          onDismiss?.call();
        },
      ),
    );

    overlay.insert(entry);
  }

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay>
    with TickerProviderStateMixin {
  late AnimationController _bgController;
  late AnimationController _contentController;
  late AnimationController _confettiController;
  late Animation<double> _bgFade;
  late Animation<double> _contentScale;
  late Animation<double> _contentFade;

  final List<_ConfettiParticle> _particles = [];
  final Random _random = Random();
  bool _isDismissed = false;

  @override
  void initState() {
    super.initState();

    HapticFeedback.heavyImpact();

    // 70 partículas de confetes físicas para 60fps
    for (int i = 0; i < 70; i++) {
      _particles.add(_ConfettiParticle(random: _random));
    }

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _bgFade = CurvedAnimation(parent: _bgController, curve: Curves.easeIn);

    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _contentScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOutBack),
    );
    _contentFade =
        CurvedAnimation(parent: _contentController, curve: Curves.easeIn);

    // Duração total de 2 segundos conforme PRD FR-21
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _bgController.forward();
    _contentController.forward();
    _confettiController.forward();

    // Auto-dismiss em 2.2 segundos para garantir o fade completo
    _autoDismissTimer = Timer(const Duration(milliseconds: 2200), () {
      if (mounted) _dismiss();
    });
  }

  Timer? _autoDismissTimer;

  void _dismiss() {
    _autoDismissTimer?.cancel();
    if (_isDismissed) return;
    _isDismissed = true;
    _bgController.reverse().then((_) {
      if (mounted) {
        widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _bgController.dispose();
    _contentController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: _dismiss,
      behavior: HitTestBehavior.opaque,
      child: FadeTransition(
        opacity: _bgFade,
        child: Stack(
          children: [
            // Backdrop escuro suave
            Container(
              color: Colors.black.withValues(alpha: 0.65),
              width: double.infinity,
              height: double.infinity,
            ),

            // Pintura de Confetes a 60fps
            AnimatedBuilder(
              animation: _confettiController,
              builder: (_, __) {
                return CustomPaint(
                  painter: _ConfettiPainter(
                    particles: _particles,
                    progress: _confettiController.value,
                    screenSize: size,
                  ),
                  child: const SizedBox.expand(),
                );
              },
            ),

            // Modal Central Ilustrado
            Center(
              child: FadeTransition(
                opacity: _contentFade,
                child: ScaleTransition(
                  scale: _contentScale,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 28),
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: widget.accentColor.withValues(alpha: 0.3),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.7, end: 1.15),
                          duration: const Duration(milliseconds: 700),
                          curve: Curves.elasticOut,
                          builder: (_, scale, child) =>
                              Transform.scale(scale: scale, child: child),
                          child: Text(
                            widget.emoji,
                            style: const TextStyle(fontSize: 60),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.subtitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: isDark ? Colors.white70 : Colors.black54,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _dismiss,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.accentColor,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(180, 48),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Continuar ✨',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfettiParticle {
  late double x;
  late double y;
  late double size;
  late Color color;
  late double speed;
  late double angle;
  late double rotation;
  late double rotationSpeed;

  static const _colors = [
    Color(0xFF10B981), // Emerald
    Color(0xFF3B82F6), // Blue
    Color(0xFFF59E0B), // Amber
    Color(0xFFEC4899), // Pink
    Color(0xFF8B5CF6), // Purple
    Color(0xFFEF4444), // Red
    Color(0xFFFFD700), // Gold
  ];

  _ConfettiParticle({required Random random}) {
    x = random.nextDouble();
    y = -random.nextDouble() * 0.4;
    size = 6 + random.nextDouble() * 8;
    color = _colors[random.nextInt(_colors.length)];
    speed = 0.4 + random.nextDouble() * 0.6;
    angle = (random.nextDouble() - 0.5) * 0.9;
    rotation = random.nextDouble() * 2 * pi;
    rotationSpeed = (random.nextDouble() - 0.5) * 0.3;
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;
  final Size screenSize;

  _ConfettiPainter({
    required this.particles,
    required this.progress,
    required this.screenSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final currentY = (p.y + progress * p.speed) % 1.2;
      final currentX = p.x + sin(progress * 3.5 + p.angle) * 0.06;
      final currentRotation = p.rotation + progress * p.rotationSpeed * 12;

      if (currentY < 0) continue;

      final cx = currentX * size.width;
      final cy = currentY * size.height;

      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(currentRotation);

      final paint = Paint()
        ..color = p.color.withValues(alpha: (1.0 - progress * 0.4).clamp(0.0, 1.0));

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.size,
            height: p.size * 0.55,
          ),
          const Radius.circular(2),
        ),
        paint,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}
