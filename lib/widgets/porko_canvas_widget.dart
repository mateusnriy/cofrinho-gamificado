import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/models/mascot_model.dart';

class PorkoCanvasWidget extends StatefulWidget {
  final PorkoMood mood;
  final MascotModel mascot;
  final VoidCallback? onTap;

  const PorkoCanvasWidget({
    super.key,
    required this.mood,
    required this.mascot,
    this.onTap,
  });

  @override
  State<PorkoCanvasWidget> createState() => _PorkoCanvasWidgetState();
}

class _PorkoCanvasWidgetState extends State<PorkoCanvasWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;
  late String _currentPhrase;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _currentPhrase = MascotModel.getDefaultPhrase(widget.mood);

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.15)
            .chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.15, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 60,
      ),
    ]).animate(_bounceController);
  }

  @override
  void didUpdateWidget(covariant PorkoCanvasWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mood != widget.mood) {
      _currentPhrase = MascotModel.getDefaultPhrase(widget.mood);
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    _bounceController.forward(from: 0.0);

    final phrases = MascotModel.speechPhrases[widget.mood] ??
        MascotModel.speechPhrases[PorkoMood.neutral]!;
    setState(() {
      _currentPhrase = phrases[_random.nextInt(phrases.length)];
    });

    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ??
            (isDark ? const Color(0xFF1E293B) : Colors.white),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Balão de fala (Speech Bubble)
          _buildSpeechBubble(context, isDark),
          const SizedBox(height: 12),

          // Mascote Interativo com micro-animação
          GestureDetector(
            onTap: _handleTap,
            behavior: HitTestBehavior.opaque,
            child: ScaleTransition(
              scale: _bounceAnimation,
              child: SizedBox(
                width: 150,
                height: 120,
                child: CustomPaint(
                  painter: _PorkoPainter(
                    mood: widget.mood,
                    skinId: widget.mascot.skinId,
                    hatId: widget.mascot.hatId,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Pílula com o estado de humor do Porko
          _buildMoodPill(context),
        ],
      ),
    );
  }

  Widget _buildSpeechBubble(BuildContext context, bool isDark) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              _currentPhrase,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : const Color(0xFF334155),
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodPill(BuildContext context) {
    late final String label;
    late final Color color;
    late final String emoji;

    switch (widget.mood) {
      case PorkoMood.sleeping:
        label = 'Sonolento';
        color = const Color(0xFF64748B);
        emoji = '💤';
        break;
      case PorkoMood.neutral:
        label = 'Tranquilo';
        color = const Color(0xFF10B981);
        emoji = '🌱';
        break;
      case PorkoMood.happy:
        label = 'Animado!';
        color = const Color(0xFFF59E0B);
        emoji = '🔥';
        break;
      case PorkoMood.celebrating:
        label = 'Radiante!';
        color = const Color(0xFF8B5CF6);
        emoji = '🎉';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            'Porko • $label',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _PorkoPainter extends CustomPainter {
  final PorkoMood mood;
  final String skinId;
  final String? hatId;

  _PorkoPainter({
    required this.mood,
    required this.skinId,
    this.hatId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 + 10;

    // Paleta de cores da Skin
    late final Color bodyColor;
    late final Color bodyShadeColor;
    late final Color snoutColor;
    late final Color blushColor;

    if (skinId == 'chocolate') {
      bodyColor = const Color(0xFF8D6E63);
      bodyShadeColor = const Color(0xFF6D4C41);
      snoutColor = const Color(0xFFA1887F);
      blushColor = const Color(0xFFBCAAA4);
    } else if (skinId == 'golden') {
      bodyColor = const Color(0xFFFFD54F);
      bodyShadeColor = const Color(0xFFFFA000);
      snoutColor = const Color(0xFFFFE082);
      blushColor = const Color(0xFFFFB74D);
    } else if (skinId == 'cyberpunk') {
      bodyColor = const Color(0xFFEC4899);
      bodyShadeColor = const Color(0xFFBE185D);
      snoutColor = const Color(0xFF06B6D4);
      blushColor = const Color(0xFFF472B6);
    } else {
      // Rosa clássico (pink_classic)
      bodyColor = const Color(0xFFFFB6C1);
      bodyShadeColor = const Color(0xFFF48FB1);
      snoutColor = const Color(0xFFFF8DA1);
      blushColor = const Color(0xFFFF80AB);
    }

    // 1. Sombra projetada no chão
    final shadowPaint = Paint()..color = Colors.black.withValues(alpha: 0.08);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy + 38),
        width: 88,
        height: 16,
      ),
      shadowPaint,
    );

    // 2. Orelhas do Porquinho
    final earPaint = Paint()..color = bodyShadeColor;
    final earInnerPaint = Paint()..color = snoutColor.withValues(alpha: 0.6);

    // Orelha esquerda
    final leftEarPath = Path()
      ..moveTo(cx - 36, cy - 20)
      ..lineTo(cx - 48, cy - 44)
      ..lineTo(cx - 20, cy - 35)
      ..close();
    canvas.drawPath(leftEarPath, earPaint);

    final leftEarInner = Path()
      ..moveTo(cx - 34, cy - 22)
      ..lineTo(cx - 44, cy - 40)
      ..lineTo(cx - 23, cy - 33)
      ..close();
    canvas.drawPath(leftEarInner, earInnerPaint);

    // Orelha direita
    final rightEarPath = Path()
      ..moveTo(cx + 36, cy - 20)
      ..lineTo(cx + 48, cy - 44)
      ..lineTo(cx + 20, cy - 35)
      ..close();
    canvas.drawPath(rightEarPath, earPaint);

    final rightEarInner = Path()
      ..moveTo(cx + 34, cy - 22)
      ..lineTo(cx + 44, cy - 40)
      ..lineTo(cx + 23, cy - 33)
      ..close();
    canvas.drawPath(rightEarInner, earInnerPaint);

    // 3. Cabeça / Corpo do Porquinho
    final bodyPaint = Paint()..color = bodyColor;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: 92, height: 76),
      bodyPaint,
    );

    // 4. Bochechas coradas (Blush)
    final blushPaint = Paint()..color = blushColor.withValues(alpha: 0.45);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - 30, cy + 4), width: 14, height: 8),
      blushPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + 30, cy + 4), width: 14, height: 8),
      blushPaint,
    );

    // 5. Olhos adaptados ao humor
    _drawEyes(canvas, cx, cy);

    // 6. Focinho Oval
    final snoutPaint = Paint()..color = snoutColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy + 8), width: 34, height: 22),
        const Radius.circular(11),
      ),
      snoutPaint,
    );

    // Narinas
    final nostrilPaint = Paint()..color = const Color(0xFF881337).withValues(alpha: 0.35);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - 7, cy + 8), width: 5, height: 8),
      nostrilPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + 7, cy + 8), width: 5, height: 8),
      nostrilPaint,
    );

    // 7. Sorriso abaixo do focinho
    if (mood != PorkoMood.sleeping) {
      final smilePaint = Paint()
        ..color = const Color(0xFF4C0519).withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;

      final smilePath = Path()
        ..moveTo(cx - 6, cy + 24)
        ..quadraticBezierTo(cx, cy + 28, cx + 6, cy + 24);
      canvas.drawPath(smilePath, smilePaint);
    }
  }

  void _drawEyes(Canvas canvas, double cx, double cy) {
    final strokePaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()..color = const Color(0xFF1E293B);
    final shinePaint = Paint()..color = Colors.white;

    switch (mood) {
      case PorkoMood.sleeping:
        // Olhos fechados em traço curvo sereno
        final leftEye = Path()
          ..moveTo(cx - 24, cy - 8)
          ..quadraticBezierTo(cx - 18, cy - 4, cx - 12, cy - 8);
        final rightEye = Path()
          ..moveTo(cx + 12, cy - 8)
          ..quadraticBezierTo(cx + 18, cy - 4, cx + 24, cy - 8);
        canvas.drawPath(leftEye, strokePaint);
        canvas.drawPath(rightEye, strokePaint);
        break;

      case PorkoMood.neutral:
        // Olhinhos redondos abertos e curiosos
        canvas.drawCircle(Offset(cx - 18, cy - 8), 5, fillPaint);
        canvas.drawCircle(Offset(cx + 18, cy - 8), 5, fillPaint);
        // Brilho nos olhos
        canvas.drawCircle(Offset(cx - 16, cy - 10), 1.8, shinePaint);
        canvas.drawCircle(Offset(cx + 20, cy - 10), 1.8, shinePaint);
        break;

      case PorkoMood.happy:
        // Olhos em arco de felicidade ^_^
        final leftHappy = Path()
          ..moveTo(cx - 24, cy - 6)
          ..quadraticBezierTo(cx - 18, cy - 14, cx - 12, cy - 6);
        final rightHappy = Path()
          ..moveTo(cx + 12, cy - 6)
          ..quadraticBezierTo(cx + 18, cy - 14, cx + 24, cy - 6);
        canvas.drawPath(leftHappy, strokePaint);
        canvas.drawPath(rightHappy, strokePaint);
        break;

      case PorkoMood.celebrating:
        // Olhos brilhantes reluzentes com estrelinhas ✨
        final leftCeleb = Path()
          ..moveTo(cx - 25, cy - 6)
          ..quadraticBezierTo(cx - 18, cy - 15, cx - 11, cy - 6);
        final rightCeleb = Path()
          ..moveTo(cx + 11, cy - 6)
          ..quadraticBezierTo(cx + 18, cy - 15, cx + 25, cy - 6);
        canvas.drawPath(leftCeleb, strokePaint..strokeWidth = 3.0);
        canvas.drawPath(rightCeleb, strokePaint..strokeWidth = 3.0);

        // Estrelinhas no canto dos olhos
        final starPaint = Paint()..color = const Color(0xFFF59E0B);
        canvas.drawCircle(Offset(cx - 30, cy - 16), 2.5, starPaint);
        canvas.drawCircle(Offset(cx + 30, cy - 16), 2.5, starPaint);
        break;
    }
  }

  @override
  bool shouldRepaint(_PorkoPainter old) =>
      old.mood != mood || old.skinId != skinId || old.hatId != hatId;
}
