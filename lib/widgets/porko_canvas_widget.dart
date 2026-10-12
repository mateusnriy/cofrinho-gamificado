import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/models/mascot_model.dart';

// Desenha o mascote Porko e seu habitat de forma interativa e com visual suave em 3D
class PorkoCanvasWidget extends StatefulWidget {
  final PorkoMood mood;
  final MascotModel mascot;
  final bool showEmptySign;
  final VoidCallback? onTap;
  final bool compact; // Para exibir miniaturizado no header colapsado

  const PorkoCanvasWidget({
    super.key,
    required this.mood,
    required this.mascot,
    this.showEmptySign = false,
    this.onTap,
    this.compact = false,
  });

  @override
  State<PorkoCanvasWidget> createState() => _PorkoCanvasWidgetState();
}

class _PorkoCanvasWidgetState extends State<PorkoCanvasWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _bounceAnim;
  bool _isCelebratingTemporary = false;

  @override
  void initState() {
    super.initState();

    // Controlador para o pulinho e animação de respiração do Porko
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _bounceAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.18)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.18, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 55,
      ),
    ]).animate(_animController);
  }

  @override
  void didUpdateWidget(covariant PorkoCanvasWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Se o humor virou celebração (ex: após depósito), dispara a festa
    if (widget.mood == PorkoMood.celebrating &&
        oldWidget.mood != PorkoMood.celebrating) {
      _triggerCelebrationJump();
    }
  }

  // Faz o Porko acordar, comemorar com pulo e voltar ao normal
  void _triggerCelebrationJump() {
    setState(() => _isCelebratingTemporary = true);
    _animController.forward(from: 0.0);
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) {
        setState(() => _isCelebratingTemporary = false);
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // Ao tocar no Porko, dá uma resposta tátil e faz ele pular
  void _handleTap() {
    HapticFeedback.lightImpact();
    final disableAnimations = MediaQuery.of(context).disableAnimations;
    if (!disableAnimations) {
      _animController.forward(from: 0.0);
    }
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Se estiver em celebração temporária, força o humor comemorativo
    final activeMood = _isCelebratingTemporary
        ? PorkoMood.celebrating
        : widget.mood;

    final height = widget.compact ? 90.0 : 170.0;
    final width = widget.compact ? 120.0 : 220.0;

    return Center(
      child: GestureDetector(
        onTap: _handleTap,
        behavior: HitTestBehavior.opaque,
        child: ScaleTransition(
          scale: _bounceAnim,
          child: SizedBox(
            width: width,
            height: height,
            child: CustomPaint(
              painter: _PorkoSoft3DPainter(
                mood: activeMood,
                mascot: widget.mascot,
                showSign: widget.showEmptySign,
                isDark: isDark,
                compact: widget.compact,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Pintor que desenha o mascote com gradientes para dar efeito de relevo e profundidade Soft 3D
class _PorkoSoft3DPainter extends CustomPainter {
  final PorkoMood mood;
  final MascotModel mascot;
  final bool showSign;
  final bool isDark;
  final bool compact;

  _PorkoSoft3DPainter({
    required this.mood,
    required this.mascot,
    required this.showSign,
    required this.isDark,
    required this.compact,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 + (compact ? 2 : 10);
    final scale = compact ? 0.65 : 1.0;

    // Define as cores de acordo com a skin do Porko
    late final Color bodyLight;
    late final Color bodyBase;
    late final Color bodyShadow;
    late final Color snoutColor;
    late final Color blushColor;

    switch (mascot.skinId) {
      case 'chocolate':
        bodyLight = const Color(0xFFA1887F);
        bodyBase = const Color(0xFF8D6E63);
        bodyShadow = const Color(0xFF5D4037);
        snoutColor = const Color(0xFFBCAAA4);
        blushColor = const Color(0xFF8D6E63).withValues(alpha: 0.5);
        break;
      case 'golden':
        bodyLight = const Color(0xFFFFF9C4);
        bodyBase = const Color(0xFFFFD54F);
        bodyShadow = const Color(0xFFFFA000);
        snoutColor = const Color(0xFFFFE082);
        blushColor = const Color(0xFFFFB74D).withValues(alpha: 0.6);
        break;
      case 'cyberpunk':
        bodyLight = const Color(0xFFF472B6);
        bodyBase = const Color(0xFFEC4899);
        bodyShadow = const Color(0xFFBE185D);
        snoutColor = const Color(0xFF06B6D4);
        blushColor = const Color(0xFF06B6D4).withValues(alpha: 0.4);
        break;
      case 'pink_classic':
      default:
        bodyLight = const Color(0xFFFFD1DC);
        bodyBase = const Color(0xFFFF9AA2);
        bodyShadow = const Color(0xFFE57388);
        snoutColor = const Color(0xFFFF7597);
        blushColor = const Color(0xFFFF4081).withValues(alpha: 0.35);
        break;
    }

    // 1. Sombra suave no chão
    final floorShadowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.black.withValues(alpha: isDark ? 0.28 : 0.14),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCenter(
        center: Offset(cx, cy + (38 * scale)),
        width: 100 * scale,
        height: 24 * scale,
      ));

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy + (38 * scale)),
        width: 100 * scale,
        height: 22 * scale,
      ),
      floorShadowPaint,
    );

    // 2. Capa de herói (desenhada atrás do corpo se estiver equipada)
    if (mascot.clothId == 'cloth_cape') {
      _drawHeroCape(canvas, cx, cy, scale);
    }

    // 3. Orelhas em 3D
    _drawEars(canvas, cx, cy, scale, bodyBase, bodyShadow, snoutColor);

    // 4. Corpo esférico com degradê volumétrico
    final bodyRect = Rect.fromCenter(
      center: Offset(cx, cy),
      width: 96 * scale,
      height: 82 * scale,
    );

    final bodyPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.25, -0.35),
        radius: 0.85,
        colors: [bodyLight, bodyBase, bodyShadow],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(bodyRect);

    canvas.drawOval(bodyRect, bodyPaint);

    // 5. Patinhas na base
    _drawPaws(canvas, cx, cy, scale, bodyShadow);

    // 6. Roupas do mascote sobre o corpo
    if (mascot.clothId != null && mascot.clothId != 'cloth_cape') {
      _drawClothes(canvas, cx, cy, scale, mascot.clothId!);
    }

    // 7. Bochechas coradas
    final blushPaint = Paint()..color = blushColor;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx - (32 * scale), cy + (6 * scale)),
        width: 16 * scale,
        height: 9 * scale,
      ),
      blushPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx + (32 * scale), cy + (6 * scale)),
        width: 16 * scale,
        height: 9 * scale,
      ),
      blushPaint,
    );

    // 8. Focinho com relevo suave
    final snoutRect = Rect.fromCenter(
      center: Offset(cx, cy + (9 * scale)),
      width: 36 * scale,
      height: 24 * scale,
    );
    final snoutPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.2, -0.3),
        radius: 0.8,
        colors: [
          snoutColor.withValues(alpha: 1.0),
          Color.lerp(snoutColor, Colors.black, 0.15)!,
        ],
      ).createShader(snoutRect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(snoutRect, Radius.circular(12 * scale)),
      snoutPaint,
    );

    // Narinas do porquinho
    final nostrilPaint = Paint()
      ..color = const Color(0xFF4A0E17).withValues(alpha: 0.45);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx - (7 * scale), cy + (9 * scale)),
        width: 5 * scale,
        height: 8 * scale,
      ),
      nostrilPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx + (7 * scale), cy + (9 * scale)),
        width: 5 * scale,
        height: 8 * scale,
      ),
      nostrilPaint,
    );

    // 9. Olhos expressivos conforme o humor
    _drawEyes(canvas, cx, cy, scale);

    // 10. Chapéus e acessórios de cabeça
    if (mascot.hatId != null) {
      _drawHat(canvas, cx, cy, scale, mascot.hatId!);
    }

    // 11. Se estiver sem metas, desenha o Porko segurando a plaquinha
    if (showSign && !compact) {
      _drawSignboard(canvas, cx, cy, scale);
    }

    // 12. Efeito de confetes festivos se estiver celebrando
    if (mood == PorkoMood.celebrating) {
      _drawCelebrationEffects(canvas, cx, cy, scale);
    }
  }

  // Desenha as orelhas pontudinhas do porco
  void _drawEars(Canvas canvas, double cx, double cy, double scale,
      Color bodyBase, Color bodyShadow, Color snoutColor) {
    final earOuterPaint = Paint()..color = bodyShadow;
    final earInnerPaint = Paint()..color = snoutColor.withValues(alpha: 0.7);

    // Orelha esquerda
    final leftEar = Path()
      ..moveTo(cx - (36 * scale), cy - (20 * scale))
      ..lineTo(cx - (52 * scale), cy - (46 * scale))
      ..lineTo(cx - (18 * scale), cy - (36 * scale))
      ..close();
    canvas.drawPath(leftEar, earOuterPaint);

    final leftEarInner = Path()
      ..moveTo(cx - (34 * scale), cy - (22 * scale))
      ..lineTo(cx - (46 * scale), cy - (42 * scale))
      ..lineTo(cx - (22 * scale), cy - (34 * scale))
      ..close();
    canvas.drawPath(leftEarInner, earInnerPaint);

    // Orelha direita
    final rightEar = Path()
      ..moveTo(cx + (36 * scale), cy - (20 * scale))
      ..lineTo(cx + (52 * scale), cy - (46 * scale))
      ..lineTo(cx + (18 * scale), cy - (36 * scale))
      ..close();
    canvas.drawPath(rightEar, earOuterPaint);

    final rightEarInner = Path()
      ..moveTo(cx + (34 * scale), cy - (22 * scale))
      ..lineTo(cx + (46 * scale), cy - (42 * scale))
      ..lineTo(cx + (22 * scale), cy - (34 * scale))
      ..close();
    canvas.drawPath(rightEarInner, earInnerPaint);
  }

  // Desenha as patinhas fofas do porco
  void _drawPaws(
      Canvas canvas, double cx, double cy, double scale, Color shadowColor) {
    final pawPaint = Paint()..color = shadowColor.withValues(alpha: 0.9);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx - (24 * scale), cy + (34 * scale)),
        width: 18 * scale,
        height: 12 * scale,
      ),
      pawPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx + (24 * scale), cy + (34 * scale)),
        width: 18 * scale,
        height: 12 * scale,
      ),
      pawPaint,
    );
  }

  // Desenha os olhinhos de acordo com o estado de sono, tranquilidade ou festa
  void _drawEyes(Canvas canvas, double cx, double cy, double scale) {
    final strokePaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8 * scale
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()..color = const Color(0xFF1E293B);
    final shinePaint = Paint()..color = Colors.white;

    switch (mood) {
      case PorkoMood.sleeping:
        // Olhinhos fechados dormindo com serene Zzz
        final leftEye = Path()
          ..moveTo(cx - (24 * scale), cy - (8 * scale))
          ..quadraticBezierTo(
              cx - (18 * scale), cy - (4 * scale), cx - (12 * scale), cy - (8 * scale));
        final rightEye = Path()
          ..moveTo(cx + (12 * scale), cy - (8 * scale))
          ..quadraticBezierTo(
              cx + (18 * scale), cy - (4 * scale), cx + (24 * scale), cy - (8 * scale));
        canvas.drawPath(leftEye, strokePaint);
        canvas.drawPath(rightEye, strokePaint);

        // Letrinhas Zzz subindo
        if (!compact) {
          final zTextPainter = TextPainter(
            text: const TextSpan(
              text: 'Zzz...',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          zTextPainter.paint(canvas, Offset(cx + (32 * scale), cy - (46 * scale)));
        }
        break;

      case PorkoMood.neutral:
        // Olhos curiosos abertos com brilho
        canvas.drawCircle(
            Offset(cx - (18 * scale), cy - (9 * scale)), 5.2 * scale, fillPaint);
        canvas.drawCircle(
            Offset(cx + (18 * scale), cy - (9 * scale)), 5.2 * scale, fillPaint);
        canvas.drawCircle(
            Offset(cx - (16 * scale), cy - (11 * scale)), 1.8 * scale, shinePaint);
        canvas.drawCircle(
            Offset(cx + (20 * scale), cy - (11 * scale)), 1.8 * scale, shinePaint);
        break;

      case PorkoMood.happy:
        // Olhinhos arqueados de alegria
        final leftHappy = Path()
          ..moveTo(cx - (24 * scale), cy - (6 * scale))
          ..quadraticBezierTo(
              cx - (18 * scale), cy - (15 * scale), cx - (12 * scale), cy - (6 * scale));
        final rightHappy = Path()
          ..moveTo(cx + (12 * scale), cy - (6 * scale))
          ..quadraticBezierTo(
              cx + (18 * scale), cy - (15 * scale), cx + (24 * scale), cy - (6 * scale));
        canvas.drawPath(leftHappy, strokePaint..strokeWidth = 3.0 * scale);
        canvas.drawPath(rightHappy, strokePaint);
        break;

      case PorkoMood.celebrating:
        // Olhos felizes reluzentes
        final leftCeleb = Path()
          ..moveTo(cx - (24 * scale), cy - (6 * scale))
          ..quadraticBezierTo(
              cx - (18 * scale), cy - (16 * scale), cx - (11 * scale), cy - (6 * scale));
        final rightCeleb = Path()
          ..moveTo(cx + (11 * scale), cy - (6 * scale))
          ..quadraticBezierTo(
              cx + (18 * scale), cy - (16 * scale), cx + (24 * scale), cy - (6 * scale));
        canvas.drawPath(leftCeleb, strokePaint..strokeWidth = 3.4 * scale);
        canvas.drawPath(rightCeleb, strokePaint);
        break;
    }
  }

  // Desenha chapéus e adereços de cabeça
  void _drawHat(Canvas canvas, double cx, double cy, double scale, String hatId) {
    switch (hatId) {
      case 'hat_crown':
        // Coroa de rei dourada com joias
        final crownPath = Path()
          ..moveTo(cx - (26 * scale), cy - (32 * scale))
          ..lineTo(cx - (30 * scale), cy - (52 * scale))
          ..lineTo(cx - (12 * scale), cy - (42 * scale))
          ..lineTo(cx, cy - (56 * scale))
          ..lineTo(cx + (12 * scale), cy - (42 * scale))
          ..lineTo(cx + (30 * scale), cy - (52 * scale))
          ..lineTo(cx + (26 * scale), cy - (32 * scale))
          ..close();
        final crownPaint = Paint()..color = const Color(0xFFF59E0B);
        canvas.drawPath(crownPath, crownPaint);

        // Joia vermelha central
        canvas.drawCircle(Offset(cx, cy - (42 * scale)), 3 * scale,
            Paint()..color = const Color(0xFFEF4444));
        break;

      case 'hat_tophat':
        // Cartola elegante preta com faixa roxa
        final brimRect = Rect.fromCenter(
          center: Offset(cx, cy - (34 * scale)),
          width: 54 * scale,
          height: 8 * scale,
        );
        canvas.drawRRect(
            RRect.fromRectAndRadius(brimRect, Radius.circular(4 * scale)),
            Paint()..color = const Color(0xFF1E293B));

        final bodyRect = Rect.fromLTWH(
          cx - (18 * scale),
          cy - (62 * scale),
          36 * scale,
          28 * scale,
        );
        canvas.drawRect(bodyRect, Paint()..color = const Color(0xFF334155));

        // Faixa da cartola
        canvas.drawRect(
          Rect.fromLTWH(
              cx - (18 * scale), cy - (40 * scale), 36 * scale, 6 * scale),
          Paint()..color = const Color(0xFF8B5CF6),
        );
        break;

      case 'hat_cap':
        // Boné azul com aba
        final capRect = Rect.fromCenter(
          center: Offset(cx, cy - (34 * scale)),
          width: 46 * scale,
          height: 20 * scale,
        );
        canvas.drawOval(capRect, Paint()..color = const Color(0xFF3B82F6));
        final visorRect = Rect.fromLTWH(
            cx - (12 * scale), cy - (32 * scale), 38 * scale, 6 * scale);
        canvas.drawRRect(
            RRect.fromRectAndRadius(visorRect, Radius.circular(3 * scale)),
            Paint()..color = const Color(0xFF1D4ED8));
        break;

      case 'hat_glasses':
        // Óculos escuros estilosos de chefe
        final glassesPaint = Paint()..color = const Color(0xFF0F172A);
        final leftGlass = RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(cx - (18 * scale), cy - (8 * scale)),
              width: 22 * scale,
              height: 16 * scale),
          Radius.circular(6 * scale),
        );
        final rightGlass = RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(cx + (18 * scale), cy - (8 * scale)),
              width: 22 * scale,
              height: 16 * scale),
          Radius.circular(6 * scale),
        );
        canvas.drawRRect(leftGlass, glassesPaint);
        canvas.drawRRect(rightGlass, glassesPaint);

        // Ponte dos óculos
        canvas.drawLine(
          Offset(cx - (8 * scale), cy - (9 * scale)),
          Offset(cx + (8 * scale), cy - (9 * scale)),
          Paint()
            ..color = const Color(0xFF0F172A)
            ..strokeWidth = 3 * scale,
        );
        break;

      case 'hat_beanie':
        // Gorro quentinho com pompom
        final beanieRect = Rect.fromCenter(
          center: Offset(cx, cy - (36 * scale)),
          width: 50 * scale,
          height: 24 * scale,
        );
        canvas.drawOval(beanieRect, Paint()..color = const Color(0xFF06B6D4));
        // Pompom
        canvas.drawCircle(Offset(cx, cy - (48 * scale)), 7 * scale,
            Paint()..color = Colors.white);
        break;
    }
  }

  // Desenha roupinhas no tronco do porquinho
  void _drawClothes(
      Canvas canvas, double cx, double cy, double scale, String clothId) {
    switch (clothId) {
      case 'cloth_bowtie':
        // Gravata borboleta vermelha elegante
        final bowPaint = Paint()..color = const Color(0xFFEF4444);
        final bowPath = Path()
          ..moveTo(cx - (14 * scale), cy + (22 * scale))
          ..lineTo(cx + (14 * scale), cy + (28 * scale))
          ..lineTo(cx + (14 * scale), cy + (22 * scale))
          ..lineTo(cx - (14 * scale), cy + (28 * scale))
          ..close();
        canvas.drawPath(bowPath, bowPaint);
        canvas.drawCircle(
            Offset(cx, cy + (25 * scale)), 4 * scale, Paint()..color = Colors.white);
        break;

      case 'cloth_tshirt':
        // Camisetinha verde água
        final shirtRect = Rect.fromCenter(
          center: Offset(cx, cy + (24 * scale)),
          width: 68 * scale,
          height: 28 * scale,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(shirtRect, Radius.circular(10 * scale)),
          Paint()..color = const Color(0xFF10B981),
        );
        break;

      case 'cloth_jacket':
        // Jaquetinha de couro preta com zíper
        final jacketRect = Rect.fromCenter(
          center: Offset(cx, cy + (24 * scale)),
          width: 72 * scale,
          height: 30 * scale,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(jacketRect, Radius.circular(10 * scale)),
          Paint()..color = const Color(0xFF334155),
        );
        canvas.drawLine(
          Offset(cx, cy + (12 * scale)),
          Offset(cx, cy + (36 * scale)),
          Paint()
            ..color = const Color(0xFF94A3B8)
            ..strokeWidth = 2 * scale,
        );
        break;
    }
  }

  // Capa de herói esvoaçante
  void _drawHeroCape(Canvas canvas, double cx, double cy, double scale) {
    final capePath = Path()
      ..moveTo(cx - (36 * scale), cy)
      ..lineTo(cx - (50 * scale), cy + (44 * scale))
      ..lineTo(cx + (50 * scale), cy + (44 * scale))
      ..lineTo(cx + (36 * scale), cy)
      ..close();
    canvas.drawPath(capePath, Paint()..color = const Color(0xFFF97316));
  }

  // Plaquinha de madeira amigável para quando o usuário não possui metas (idêntica ao protótipo v3)
  void _drawSignboard(Canvas canvas, double cx, double cy, double scale) {
    canvas.save();
    // Posiciona ao lado direito do porquinho e inclina em 6 graus
    canvas.translate(cx + (50 * scale), cy - (4 * scale));
    canvas.rotate(0.10); // ~6 graus

    final boardRect = Rect.fromCenter(
      center: Offset.zero,
      width: 104 * scale,
      height: 38 * scale,
    );

    // Fundo da plaquinha (#FEF3C7)
    final woodPaint = Paint()..color = const Color(0xFFFEF3C7);
    canvas.drawRRect(
      RRect.fromRectAndRadius(boardRect, Radius.circular(10 * scale)),
      woodPaint,
    );

    // Borda da placa (#B45309)
    canvas.drawRRect(
      RRect.fromRectAndRadius(boardRect, Radius.circular(10 * scale)),
      Paint()
        ..color = const Color(0xFFB45309)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5 * scale,
    );

    // Texto da plaquinha (#78350F)
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'Crie sua 1ª meta!\n🪙',
        style: TextStyle(
          color: Color(0xFF78350F),
          fontSize: 10,
          fontWeight: FontWeight.w800,
          height: 1.15,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 100 * scale);

    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -textPainter.height / 2),
    );

    canvas.restore();
  }

  // Desenha estrelinhas e confetes para comemoração
  void _drawCelebrationEffects(
      Canvas canvas, double cx, double cy, double scale) {
    final colors = [
      const Color(0xFFF59E0B),
      const Color(0xFF10B981),
      const Color(0xFFEC4899),
      const Color(0xFF3B82F6),
    ];

    final offsets = [
      Offset(cx - (45 * scale), cy - (40 * scale)),
      Offset(cx + (45 * scale), cy - (42 * scale)),
      Offset(cx - (30 * scale), cy - (60 * scale)),
      Offset(cx + (32 * scale), cy - (58 * scale)),
      Offset(cx - (60 * scale), cy - (10 * scale)),
      Offset(cx + (60 * scale), cy - (8 * scale)),
    ];

    for (int i = 0; i < offsets.length; i++) {
      final p = Paint()..color = colors[i % colors.length];
      canvas.drawCircle(offsets[i], 3.5 * scale, p);
    }
  }

  @override
  bool shouldRepaint(_PorkoSoft3DPainter old) =>
      old.mood != mood ||
      old.mascot.skinId != mascot.skinId ||
      old.mascot.hatId != mascot.hatId ||
      old.mascot.clothId != mascot.clothId ||
      old.showSign != showSign ||
      old.isDark != isDark ||
      old.compact != compact;
}
