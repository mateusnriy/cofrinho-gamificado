import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/models/mascot_model.dart';

/// Renderiza o mascote Porko em Soft 3D (Claymorphism) de 9 camadas volumétricas,
/// idêntico ao protótipo `prototype_oinc.html`, com ciclo de vida contínuo
/// (respiração/flutuação `bob`, piscar natural, caminhada opcional no habitat e reações táteis).
class PorkoCanvasWidget extends StatefulWidget {
  final PorkoMood mood;
  final MascotModel mascot;
  final bool showEmptySign;
  final VoidCallback? onTap;
  final bool compact;
  final bool enableWalking;
  final String? activeReaction; // 'jump', 'love', 'eat', 'call'

  const PorkoCanvasWidget({
    super.key,
    required this.mood,
    required this.mascot,
    this.showEmptySign = false,
    this.onTap,
    this.compact = false,
    this.enableWalking = false,
    this.activeReaction,
  });

  @override
  State<PorkoCanvasWidget> createState() => _PorkoCanvasWidgetState();
}

class _PorkoCanvasWidgetState extends State<PorkoCanvasWidget>
    with TickerProviderStateMixin {
  late AnimationController _jumpController;
  late Animation<double> _bounceAnim;
  late AnimationController _idleController;

  bool _isCelebratingTemporary = false;
  bool _isBlinking = false;
  Timer? _blinkTimer;

  // Verifica se estamos rodando em ambiente de testes ou com "Reduzir Movimento" ativo (WCAG 2.1 / NFR11)
  bool get _isTestEnvironment {
    final bindingName = WidgetsBinding.instance.runtimeType.toString();
    final isTest =
        bindingName.contains('Test') || bindingName.contains('Automated');
    final reduceMotion = Hive.isBoxOpen('settings') &&
        (Hive.box('settings').get('reduce_motion') == true);
    return isTest || reduceMotion;
  }

  @override
  void initState() {
    super.initState();

    // Controlador de pulo reativo ao toque ou celebração
    _jumpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 680),
    );

    _bounceAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.16)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.16, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 55,
      ),
    ]).animate(_jumpController);

    // Controlador contínuo de vida Soft 3D (bobbing, respiração, orelhas e caminhada)
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );

    if (!_isTestEnvironment) {
      _idleController.repeat();
      _scheduleNextBlink();
    } else {
      _idleController.value = 0.25;
    }
  }

  void _scheduleNextBlink() {
    _blinkTimer?.cancel();
    if (!mounted || _isTestEnvironment) return;
    _blinkTimer = Timer(const Duration(milliseconds: 3600), () {
      if (!mounted) return;
      if (widget.mood != PorkoMood.sleeping) {
        setState(() => _isBlinking = true);
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) {
            setState(() => _isBlinking = false);
            _scheduleNextBlink();
          }
        });
      } else {
        _scheduleNextBlink();
      }
    });
  }

  @override
  void didUpdateWidget(covariant PorkoCanvasWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mood == PorkoMood.celebrating &&
        oldWidget.mood != PorkoMood.celebrating) {
      _triggerCelebrationJump();
    } else if (widget.activeReaction != null &&
        widget.activeReaction != oldWidget.activeReaction) {
      if (!_isTestEnvironment) {
        _jumpController.forward(from: 0.0);
      }
    }
  }

  void _triggerCelebrationJump() {
    setState(() => _isCelebratingTemporary = true);
    _jumpController.forward(from: 0.0);
    if (!_isTestEnvironment) {
      Future.delayed(const Duration(milliseconds: 3500), () {
        if (mounted) {
          setState(() => _isCelebratingTemporary = false);
        }
      });
    }
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _jumpController.dispose();
    _idleController.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    final disableAnimations = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (!disableAnimations) {
      _jumpController.forward(from: 0.0);
    }
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final disableAnimations = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    final activeMood = _isCelebratingTemporary
        ? PorkoMood.celebrating
        : widget.mood;

    final height = widget.compact ? 94.0 : 168.0;
    final width = widget.compact ? 124.0 : 230.0;

    return Center(
      child: GestureDetector(
        onTap: _handleTap,
        behavior: HitTestBehavior.opaque,
        child: ScaleTransition(
          scale: _bounceAnim,
          child: AnimatedBuilder(
            animation: Listenable.merge([_idleController, _jumpController]),
            builder: (context, _) {
              final phase = disableAnimations ? 0.25 : _idleController.value;
              final jumpProgress = _jumpController.value;

              // Deslocamento horizontal suave quando caminhando no habitat
              double walkX = 0.0;
              if (widget.enableWalking &&
                  !widget.compact &&
                  !disableAnimations &&
                  activeMood != PorkoMood.sleeping &&
                  !widget.showEmptySign) {
                walkX = math.sin(phase * 2 * math.pi) * 18.0;
              }

              return Transform.translate(
                offset: Offset(walkX, 0),
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
                      idlePhase: phase,
                      jumpProgress: jumpProgress,
                      isBlinking: _isBlinking,
                      activeReaction: widget.activeReaction,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Pintor Soft 3D (Claymorphism) de 9 camadas que replica fielmente `.porko`
/// do protótipo `prototype_oinc.html` com volume esférico, chanfro luminoso,
/// orelhas arredondadas em 3D, focinho esculpido, olhos com duplo brilho e boca expressiva.
class _PorkoSoft3DPainter extends CustomPainter {
  final PorkoMood mood;
  final MascotModel mascot;
  final bool showSign;
  final bool isDark;
  final bool compact;
  final double idlePhase;
  final double jumpProgress;
  final bool isBlinking;
  final String? activeReaction;

  _PorkoSoft3DPainter({
    required this.mood,
    required this.mascot,
    required this.showSign,
    required this.isDark,
    required this.compact,
    required this.idlePhase,
    required this.jumpProgress,
    required this.isBlinking,
    this.activeReaction,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scale = compact ? 0.66 : 1.05;
    final cx = size.width / 2;

    // Movimento vertical contínuo (bobbing / respiração) + pulo reativo
    final bobWave = math.sin(idlePhase * 2 * math.pi);
    final jumpLift = math.sin(jumpProgress * math.pi) * (-14.0 * scale);
    final sleepFactor = mood == PorkoMood.sleeping ? 0.35 : 1.0;
    final bobY = (bobWave * -4.2 * scale * sleepFactor) + jumpLift;

    final baseCy = size.height / 2 + (compact ? 4.0 : 12.0);
    final cy = baseCy + bobY;

    // Paleta de cores 3D por skin (idêntica aos tokens CSS --skinHi, --skinMid, --skinLo, --snoutA, --snoutB)
    late final Color skinHi;
    late final Color skinMid;
    late final Color skinLo;
    late final Color skinDeepShadow;
    late final Color snoutA;
    late final Color snoutB;
    late final Color earCavityHi;
    late final Color earCavityLo;
    late final Color blushColor;

    switch (mascot.skinId) {
      case 'chocolate':
      case 'skin_choc':
        skinHi = const Color(0xFFD7B8A6);
        skinMid = const Color(0xFF8D6E63);
        skinLo = const Color(0xFF4E342E);
        skinDeepShadow = const Color(0xFF2D1B17);
        snoutA = const Color(0xFFBCAAA4);
        snoutB = const Color(0xFF795548);
        earCavityHi = const Color(0xFFA1887F);
        earCavityLo = const Color(0xFF5D4037);
        blushColor = const Color(0xFFFF8A80).withValues(alpha: 0.45);
        break;
      case 'golden':
      case 'skin_gold':
        skinHi = const Color(0xFFFFF9C4);
        skinMid = const Color(0xFFFFD54F);
        skinLo = const Color(0xFFD97706);
        skinDeepShadow = const Color(0xFF92400E);
        snoutA = const Color(0xFFFFE082);
        snoutB = const Color(0xFFF59E0B);
        earCavityHi = const Color(0xFFFFCA28);
        earCavityLo = const Color(0xFFB45309);
        blushColor = const Color(0xFFFF7043).withValues(alpha: 0.48);
        break;
      case 'cyberpunk':
        skinHi = const Color(0xFFFBCFE8);
        skinMid = const Color(0xFFEC4899);
        skinLo = const Color(0xFF9D174D);
        skinDeepShadow = const Color(0xFF500724);
        snoutA = const Color(0xFF67E8F9);
        snoutB = const Color(0xFF0891B2);
        earCavityHi = const Color(0xFF22D3EE);
        earCavityLo = const Color(0xFF0E7490);
        blushColor = const Color(0xFF22D3EE).withValues(alpha: 0.55);
        break;
      case 'pink_classic':
      default:
        skinHi = const Color(0xFFFFDCE5);
        skinMid = const Color(0xFFFF8DA1);
        skinLo = const Color(0xFFD94E6A);
        skinDeepShadow = const Color(0xFF881D36);
        snoutA = const Color(0xFFFFB3C4);
        snoutB = const Color(0xFFFF6686);
        earCavityHi = const Color(0xFFFF7592);
        earCavityLo = const Color(0xFFC93B5B);
        blushColor = const Color(0xFFFF4D7D).withValues(alpha: 0.55);
        break;
    }

    // ── CAMADA 1: Sombra Elíptica no Chão (.shadow-g) ───────────────────────
    final shadowScale = (1.0 - ((-bobY) / (75.0 * scale))).clamp(0.75, 1.12);
    final shadowCenter = Offset(cx, baseCy + (45 * scale));
    final shadowRect = Rect.fromCenter(
      center: shadowCenter,
      width: 86 * scale * shadowScale,
      height: 18 * scale * shadowScale,
    );
    canvas.drawOval(
      shadowRect,
      Paint()
        ..color = Colors.black.withValues(alpha: isDark ? 0.42 : 0.26)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 5.5 * scale),
    );
    // Núcleo mais denso de oclusão de ambiente sob as patinhas
    canvas.drawOval(
      Rect.fromCenter(
        center: shadowCenter,
        width: 56 * scale * shadowScale,
        height: 10 * scale * shadowScale,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: isDark ? 0.35 : 0.18)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2.5 * scale),
    );

    // ── Capa de Herói (atrás do corpo Esférico se equipada) ─────────────────
    if (mascot.clothId == 'cloth_cape') {
      _drawHeroCape3D(canvas, cx, cy, scale, bobWave);
    }

    // ── CAMADA 2: Orelhas Arredondadas 3D (.ear.l e .ear.r + .ear::after) ───
    _drawRounded3DEars(
      canvas: canvas,
      cx: cx,
      cy: cy,
      scale: scale,
      bobWave: bobWave,
      skinHi: skinHi,
      skinMid: skinMid,
      skinLo: skinLo,
      skinDeepShadow: skinDeepShadow,
      earCavityHi: earCavityHi,
      earCavityLo: earCavityLo,
    );

    // ── CAMADA 3: Patinhas Inferiores 3D com Casquinhos ─────────────────────
    _draw3DFeet(
      canvas: canvas,
      cx: cx,
      cy: cy,
      scale: scale,
      skinHi: skinHi,
      skinMid: skinMid,
      skinLo: skinLo,
      skinDeepShadow: skinDeepShadow,
    );

    // ── CAMADA 4: Corpo Esférico Soft 3D (.body - 96x90px Claymorphism) ─────
    _draw3DSphereBody(
      canvas: canvas,
      cx: cx,
      cy: cy,
      scale: scale,
      bobWave: bobWave,
      skinHi: skinHi,
      skinMid: skinMid,
      skinLo: skinLo,
      skinDeepShadow: skinDeepShadow,
    );

    // ── Braços Laterais Gordinhos 3D ────────────────────────────────────────
    _draw3DArms(
      canvas: canvas,
      cx: cx,
      cy: cy,
      scale: scale,
      bobWave: bobWave,
      skinHi: skinHi,
      skinMid: skinMid,
      skinLo: skinLo,
      isCelebrating: mood == PorkoMood.celebrating || jumpProgress > 0.1,
    );

    // ── CAMADA 5: Roupas 3D (.slot-cloth) sobre o tronco ────────────────────
    if (mascot.clothId != null) {
      _draw3DClothes(canvas, cx, cy, scale, mascot.clothId!);
    }

    // ── CAMADA 6: Bochechas Volumétricas Esfumaçadas (.cheek.l e .cheek.r) ──
    _draw3DCheeks(canvas, cx, cy, scale, blushColor);

    // ── CAMADA 7: Olhos Profundos 3D com Duplo Brilho (.eye + .eye::after) ──
    _draw3DEyes(canvas, cx, cy, scale);

    // ── CAMADA 8: Focinho Esculpido em Relevo 3D (.snout + .nostril) ────────
    _draw3DSnout(
      canvas: canvas,
      cx: cx,
      cy: cy,
      scale: scale,
      snoutA: snoutA,
      snoutB: snoutB,
      skinDeepShadow: skinDeepShadow,
    );

    // ── CAMADA 8.2: Boca Expressiva 3D (.mouth) ─────────────────────────────
    _draw3DMouth(canvas, cx, cy, scale);

    // ── CAMADA 9: Acessórios de Cabeça 3D (.slot-head) ──────────────────────
    if (mascot.hatId != null) {
      _draw3DHat(canvas, cx, cy, scale, mascot.hatId!);
    }

    // ── Plaquinha de Madeira 3D quando sem metas (.signboard) ───────────────
    if (showSign && !compact) {
      _drawSignboard3D(canvas, cx, cy, scale);
    }

    // ── Partículas Reativas (Confetes, Corações, Maçã, Música) ──────────────
    if (mood == PorkoMood.celebrating || jumpProgress > 0.05) {
      _drawCelebrationEffects(canvas, cx, cy, scale);
    }
    if (activeReaction != null && !compact) {
      _drawReactionParticles(canvas, cx, cy, scale, activeReaction!);
    }
  }

  /// Desenha as orelhas arredondadas Soft 3D idênticas a `.ear` e `.ear::after` do protótipo
  void _drawRounded3DEars({
    required Canvas canvas,
    required double cx,
    required double cy,
    required double scale,
    required double bobWave,
    required Color skinHi,
    required Color skinMid,
    required Color skinLo,
    required Color skinDeepShadow,
    required Color earCavityHi,
    required Color earCavityLo,
  }) {
    final earWiggle = bobWave * 0.045;

    for (final isLeft in [true, false]) {
      final sign = isLeft ? -1.0 : 1.0;
      canvas.save();
      canvas.translate(cx + (sign * 29 * scale), cy - (31 * scale));
      canvas.rotate(sign * (0.42 + earWiggle)); // ±24 graus + balanço vivo

      final earRect = Rect.fromCenter(
        center: Offset.zero,
        width: 28 * scale,
        height: 33 * scale,
      );

      final earRRect = RRect.fromRectAndCorners(
        earRect,
        topLeft: Radius.circular(16 * scale),
        topRight: Radius.circular(16 * scale),
        bottomLeft: Radius.circular(isLeft ? 15 * scale : 5 * scale),
        bottomRight: Radius.circular(isLeft ? 5 * scale : 15 * scale),
      );

      // Sombra projetada da orelha sobre a cabeça
      canvas.drawRRect(
        earRRect.shift(Offset(0, 3 * scale)),
        Paint()
          ..color = skinDeepShadow.withValues(alpha: 0.30)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3.5 * scale),
      );

      // Volume 3D principal da orelha
      final earPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [skinHi, skinMid, skinLo],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(earRect);
      canvas.drawRRect(earRRect, earPaint);

      // Rim light superior na borda da orelha (chanfro 3D)
      canvas.drawRRect(
        earRRect.deflate(0.8 * scale),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4 * scale
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.65),
              Colors.transparent,
              skinDeepShadow.withValues(alpha: 0.25),
            ],
          ).createShader(earRect),
      );

      // Cavidade interna 3D da orelha (.ear::after)
      final innerRect = Rect.fromCenter(
        center: Offset(0, 2.5 * scale),
        width: 15 * scale,
        height: 19 * scale,
      );
      final innerRRect = RRect.fromRectAndCorners(
        innerRect,
        topLeft: Radius.circular(10 * scale),
        topRight: Radius.circular(10 * scale),
        bottomLeft: Radius.circular(isLeft ? 9 * scale : 3 * scale),
        bottomRight: Radius.circular(isLeft ? 3 * scale : 9 * scale),
      );

      canvas.drawRRect(
        innerRRect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [earCavityLo, earCavityHi],
          ).createShader(innerRect),
      );

      canvas.restore();
    }
  }

  /// Desenha as patinhas inferiores gordinhas 3D com casquinhos esculpidos
  void _draw3DFeet({
    required Canvas canvas,
    required double cx,
    required double cy,
    required double scale,
    required Color skinHi,
    required Color skinMid,
    required Color skinLo,
    required Color skinDeepShadow,
  }) {
    for (final sign in [-1.0, 1.0]) {
      final footCenter = Offset(cx + (sign * 22 * scale), cy + (38 * scale));
      final footRect = Rect.fromCenter(
        center: footCenter,
        width: 22 * scale,
        height: 15 * scale,
      );
      final footRRect = RRect.fromRectAndRadius(
        footRect,
        Radius.circular(9 * scale),
      );

      // Sombra da patinha
      canvas.drawRRect(
        footRRect.shift(Offset(0, 2 * scale)),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.22)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2.5 * scale),
      );

      // Volume esférico da patinha
      canvas.drawRRect(
        footRRect,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.3, -0.4),
            radius: 0.9,
            colors: [skinHi, skinMid, skinLo],
          ).createShader(footRect),
      );

      // Detalhe de casquinho na ponta inferior
      final hoofRect = Rect.fromCenter(
        center: Offset(footCenter.dx, footCenter.dy + (3.5 * scale)),
        width: 14 * scale,
        height: 5.5 * scale,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(hoofRect, Radius.circular(3 * scale)),
        Paint()..color = skinDeepShadow.withValues(alpha: 0.45),
      );
    }
  }

  /// Desenha o corpo esférico Soft 3D (.body) com 4 camadas de sombreamento Claymorphism
  void _draw3DSphereBody({
    required Canvas canvas,
    required double cx,
    required double cy,
    required double scale,
    required double bobWave,
    required Color skinHi,
    required Color skinMid,
    required Color skinLo,
    required Color skinDeepShadow,
  }) {
    // Leve squash-and-stretch respiratório
    final squashX = 1.0 + (bobWave * 0.014);
    final squashY = 1.0 - (bobWave * 0.014);

    final bodyRect = Rect.fromCenter(
      center: Offset(cx, cy),
      width: 96 * scale * squashX,
      height: 88 * scale * squashY,
    );

    final bodyRRect = RRect.fromRectAndCorners(
      bodyRect,
      topLeft: Radius.elliptical(48 * scale, 46 * scale),
      topRight: Radius.elliptical(48 * scale, 46 * scale),
      bottomLeft: Radius.elliptical(45 * scale, 42 * scale),
      bottomRight: Radius.elliptical(45 * scale, 42 * scale),
    );

    // 1. Drop shadow volumétrico externo do corpo (0 8px 18px rgba(0,0,0,0.18))
    canvas.drawRRect(
      bodyRRect.shift(Offset(0, 6 * scale)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.20)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 7 * scale),
    );

    // 2. Gradiente radial 3-stops principal (circle at 32% 28%, skinHi 0%, skinMid 55%, skinLo 100%)
    final basePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.36, -0.44),
        radius: 0.95,
        colors: [skinHi, skinMid, skinLo],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(bodyRect);
    canvas.drawRRect(bodyRRect, basePaint);

    // 3. Sombra interna inferior-direita (inset -8px -10px 18px rgba(0,0,0,0.18))
    canvas.save();
    canvas.clipRRect(bodyRRect);
    final innerShadowPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.25, -0.30),
        radius: 0.92,
        colors: [
          Colors.transparent,
          Colors.transparent,
          skinDeepShadow.withValues(alpha: 0.34),
        ],
        stops: const [0.0, 0.68, 1.0],
      ).createShader(bodyRect);
    canvas.drawRect(bodyRect, innerShadowPaint);

    // 4. Rim Light superior-esquerdo (inset 6px 6px 14px rgba(255,255,255,0.65))
    final rimRect = bodyRect. translate(-3 * scale, -3 * scale);
    canvas.drawRRect(
      bodyRRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2 * scale
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.72),
            Colors.white.withValues(alpha: 0.15),
            Colors.transparent,
            skinDeepShadow.withValues(alpha: 0.25),
          ],
          stops: const [0.0, 0.35, 0.65, 1.0],
        ).createShader(rimRect),
    );

    // 5. Brilho Especular Soft 3D (reflexo acetinado de clay/porcelana no topo esquerdo)
    canvas.save();
    canvas.translate(cx - (21 * scale), cy - (23 * scale));
    canvas.rotate(-0.48);
    final specularRect = Rect.fromCenter(
      center: Offset.zero,
      width: 24 * scale,
      height: 11 * scale,
    );
    canvas.drawOval(
      specularRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.62),
            Colors.white.withValues(alpha: 0.08),
          ],
        ).createShader(specularRect)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2.2 * scale),
    );
    canvas.restore();

    canvas.restore();
  }

  /// Desenha os bracinhos laterais 3D do Porko
  void _draw3DArms({
    required Canvas canvas,
    required double cx,
    required double cy,
    required double scale,
    required double bobWave,
    required Color skinHi,
    required Color skinMid,
    required Color skinLo,
    required bool isCelebrating,
  }) {
    for (final isLeft in [true, false]) {
      final sign = isLeft ? -1.0 : 1.0;
      canvas.save();
      canvas.translate(cx + (sign * 42 * scale), cy + (8 * scale));
      final waveAngle = isCelebrating
          ? sign * (-0.65 + bobWave * 0.25)
          : sign * (0.28 + bobWave * 0.06);
      canvas.rotate(waveAngle);

      final armRect = Rect.fromCenter(
        center: Offset.zero,
        width: 16 * scale,
        height: 22 * scale,
      );
      final armRRect = RRect.fromRectAndRadius(
        armRect,
        Radius.circular(9 * scale),
      );

      // Sombra do bracinho no corpo
      canvas.drawRRect(
        armRRect.shift(Offset(-sign * 2 * scale, 2 * scale)),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.16)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2.5 * scale),
      );

      // Volume 3D do bracinho
      canvas.drawRRect(
        armRRect,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.3, -0.35),
            radius: 0.9,
            colors: [skinHi, skinMid, skinLo],
          ).createShader(armRect),
      );

      // Brilho superior no bracinho
      canvas.drawCircle(
        Offset(-2 * scale, -4 * scale),
        2.5 * scale,
        Paint()..color = Colors.white.withValues(alpha: 0.38),
      );

      canvas.restore();
    }
  }

  /// Desenha as bochechas rosadas esfumaçadas (.cheek.l e .cheek.r)
  void _draw3DCheeks(
    Canvas canvas,
    double cx,
    double cy,
    double scale,
    Color blushColor,
  ) {
    final cheekPaint = Paint()
      ..color = blushColor
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3.2 * scale);

    for (final sign in [-1.0, 1.0]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx + (sign * 30 * scale), cy + (6 * scale)),
          width: 16 * scale,
          height: 10 * scale,
        ),
        cheekPaint,
      );
    }
  }

  /// Desenha os olhos profundos em 3D (.eye e .eye::after) com duplo catchlight
  void _draw3DEyes(Canvas canvas, double cx, double cy, double scale) {
    final eyeY = cy - (7 * scale);

    if (mood == PorkoMood.sleeping || isBlinking) {
      // Pálpebras fechadas em relevo 3D
      final lidPaint = Paint()
        ..color = const Color(0xFF2B161B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.8 * scale
        ..strokeCap = StrokeCap.round;

      final lidHighlightPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4 * scale
        ..strokeCap = StrokeCap.round;

      for (final sign in [-1.0, 1.0]) {
        final ex = cx + (sign * 19 * scale);
        final path = Path()
          ..moveTo(ex - (6 * scale), eyeY)
          ..quadraticBezierTo(ex, eyeY + (5.5 * scale), ex + (6 * scale), eyeY);
        canvas.drawPath(path.shift(Offset(0, 1.2 * scale)), lidHighlightPaint);
        canvas.drawPath(path, lidPaint);
      }

      if (mood == PorkoMood.sleeping && !compact) {
        final zTextPainter = TextPainter(
          text: TextSpan(
            text: 'zZz',
            style: TextStyle(
              color: isDark ? const Color(0xFFBAE6FD) : const Color(0xFF475569),
              fontSize: 13 * scale,
              fontWeight: FontWeight.w900,
              shadows: const [
                Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
              ],
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        zTextPainter.paint(
          canvas,
          Offset(cx + (34 * scale), cy - (48 * scale)),
        );
      }
      return;
    }

    // Olhos abertos 3D (.eye: 11x13px, radial-gradient(#3a2a2d -> #140c0e))
    for (final sign in [-1.0, 1.0]) {
      final ex = cx + (sign * 19 * scale);
      final eyeRect = Rect.fromCenter(
        center: Offset(ex, eyeY),
        width: 11.5 * scale,
        height: 13.8 * scale,
      );

      // Rim highlight da cavidade ocular inferior (0 2px 3px rgba(255,255,255,.4))
      canvas.drawOval(
        eyeRect.shift(Offset(0, 1.6 * scale)),
        Paint()..color = Colors.white.withValues(alpha: 0.48),
      );

      // Globo ocular 3D escuro profundo
      canvas.drawOval(
        eyeRect,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(-0.3, -0.35),
            radius: 0.85,
            colors: [
              Color(0xFF4A353B),
              Color(0xFF140C0E),
            ],
          ).createShader(eyeRect),
      );

      // Catchlight principal brilhante (.eye::after 4x4px)
      canvas.drawCircle(
        Offset(ex - (1.8 * scale), eyeY - (2.6 * scale)),
        2.3 * scale,
        Paint()..color = Colors.white,
      );

      // Catchlight secundário inferior-direito para efeito 3D cristalino
      canvas.drawCircle(
        Offset(ex + (2.0 * scale), eyeY + (2.4 * scale)),
        1.1 * scale,
        Paint()..color = Colors.white.withValues(alpha: 0.85),
      );

      // Sobrancelha/arco de alegria sutil quando feliz ou celebrando
      if (mood == PorkoMood.happy || mood == PorkoMood.celebrating) {
        final browPath = Path()
          ..moveTo(ex - (5.5 * scale), eyeY - (9.5 * scale))
          ..quadraticBezierTo(
            ex,
            eyeY - (12.5 * scale),
            ex + (5.5 * scale),
            eyeY - (9.5 * scale),
          );
        canvas.drawPath(
          browPath,
          Paint()
            ..color = const Color(0xFF6B1D2F).withValues(alpha: 0.55)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.8 * scale
            ..strokeCap = StrokeCap.round,
        );
      }
    }
  }

  /// Desenha o focinho esculpido em 3D (.snout + .nostril) com sombra projetada e bisel iluminado
  void _draw3DSnout({
    required Canvas canvas,
    required double cx,
    required double cy,
    required double scale,
    required Color snoutA,
    required Color snoutB,
    required Color skinDeepShadow,
  }) {
    final snoutCenter = Offset(cx, cy + (7.5 * scale));
    final snoutRect = Rect.fromCenter(
      center: snoutCenter,
      width: 40 * scale,
      height: 28 * scale,
    );
    final snoutRRect = RRect.fromRectAndRadius(
      snoutRect,
      Radius.circular(15 * scale),
    );

    // 1. Sombra projetada do focinho sobre o rosto (0 4px 8px rgba(0,0,0,0.18))
    canvas.drawRRect(
      snoutRRect.shift(Offset(0, 3.8 * scale)),
      Paint()
        ..color = skinDeepShadow.withValues(alpha: 0.32)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4.0 * scale),
    );

    // 2. Volume 3D do focinho (radial-gradient(circle at 35% 30%, var(--snoutA), var(--snoutB)))
    canvas.drawRRect(
      snoutRRect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.38),
          radius: 0.92,
          colors: [
            snoutA,
            snoutB,
            Color.lerp(snoutB, skinDeepShadow, 0.28)!,
          ],
          stops: const [0.0, 0.65, 1.0],
        ).createShader(snoutRect),
    );

    // 3. Chanfro luminoso superior (inset 2px 3px 5px rgba(255,255,255,0.6))
    canvas.drawRRect(
      snoutRRect.deflate(0.9 * scale),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6 * scale
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.72),
            Colors.transparent,
            skinDeepShadow.withValues(alpha: 0.28),
          ],
        ).createShader(snoutRect),
    );

    // 4. Brilho especular na ponta superior esquerda do focinho
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx - (9 * scale), snoutCenter.dy - (7.5 * scale)),
        width: 11 * scale,
        height: 4.5 * scale,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.45),
    );

    // 5. Narinas esculpidas em profundidade (.nostril)
    for (final sign in [-1.0, 1.0]) {
      final nx = cx + (sign * 7.5 * scale);
      final ny = snoutCenter.dy + (0.5 * scale);
      final nostrilRect = Rect.fromCenter(
        center: Offset(nx, ny),
        width: 6.2 * scale,
        height: 8.8 * scale,
      );

      // Borda inferior iluminada da cavidade da narina
      canvas.drawOval(
        nostrilRect.shift(Offset(0, 1.0 * scale)),
        Paint()..color = Colors.white.withValues(alpha: 0.35),
      );

      // Cavidade interna escura
      canvas.drawOval(
        nostrilRect,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF420A14),
              Color(0xFF7D192C),
            ],
          ).createShader(nostrilRect),
      );
    }
  }

  /// Desenha a boca 3D expressiva (.mouth) logo abaixo do focinho
  void _draw3DMouth(Canvas canvas, double cx, double cy, double scale) {
    final mouthY = cy + (24.5 * scale);

    if (mood == PorkoMood.sleeping) {
      // Boquinha serena dormindo
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, mouthY + (1.5 * scale)),
          width: 6 * scale,
          height: 4.5 * scale,
        ),
        Paint()..color = const Color(0xFF6B1D2F).withValues(alpha: 0.75),
      );
      return;
    }

    if (mood == PorkoMood.celebrating ||
        activeReaction == 'eat' ||
        activeReaction == 'call') {
      // Boca aberta alegre 3D com linguinha
      final openRect = Rect.fromCenter(
        center: Offset(cx, mouthY + (2 * scale)),
        width: 15 * scale,
        height: 10 * scale,
      );
      final openRRect = RRect.fromRectAndCorners(
        openRect,
        topLeft: Radius.circular(3 * scale),
        topRight: Radius.circular(3 * scale),
        bottomLeft: Radius.circular(9 * scale),
        bottomRight: Radius.circular(9 * scale),
      );
      canvas.drawRRect(
        openRRect,
        Paint()..color = const Color(0xFF5A1224),
      );
      // Linguinha rosa
      canvas.save();
      canvas.clipRRect(openRRect);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, mouthY + (6.5 * scale)),
          width: 11 * scale,
          height: 7 * scale,
        ),
        Paint()..color = const Color(0xFFFF7597),
      );
      canvas.restore();
      return;
    }

    // Sorriso curvo 3D clássico (.mouth do protótipo: 14x7px, #6b1d2f)
    final smilePath = Path()
      ..moveTo(cx - (7.5 * scale), mouthY)
      ..quadraticBezierTo(
        cx,
        mouthY + (6.8 * scale),
        cx + (7.5 * scale),
        mouthY,
      );

    // Highlight do lábio inferior
    canvas.drawPath(
      smilePath.shift(Offset(0, 1.4 * scale)),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.42)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 * scale
        ..strokeCap = StrokeCap.round,
    );

    // Traço escuro da boca
    canvas.drawPath(
      smilePath,
      Paint()
        ..color = const Color(0xFF6B1D2F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5 * scale
        ..strokeCap = StrokeCap.round,
    );
  }

  /// Desenha chapéus e acessórios de cabeça em Soft 3D (.slot-head)
  void _draw3DHat(
    Canvas canvas,
    double cx,
    double cy,
    double scale,
    String hatId,
  ) {
    switch (hatId) {
      case 'hat_crown':
        final crownPath = Path()
          ..moveTo(cx - (25 * scale), cy - (35 * scale))
          ..lineTo(cx - (29 * scale), cy - (55 * scale))
          ..lineTo(cx - (12 * scale), cy - (44 * scale))
          ..lineTo(cx, cy - (59 * scale))
          ..lineTo(cx + (12 * scale), cy - (44 * scale))
          ..lineTo(cx + (29 * scale), cy - (55 * scale))
          ..lineTo(cx + (25 * scale), cy - (35 * scale))
          ..close();

        // Sombra da coroa na cabeça
        canvas.drawPath(
          crownPath.shift(Offset(0, 3 * scale)),
          Paint()
            ..color = Colors.black.withValues(alpha: 0.25)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3 * scale),
        );

        // Gradiente metálico 3D de ouro
        final crownRect = Rect.fromLTWH(
          cx - (30 * scale),
          cy - (60 * scale),
          60 * scale,
          26 * scale,
        );
        canvas.drawPath(
          crownPath,
          Paint()
            ..shader = const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFEF08A),
                Color(0xFFF59E0B),
                Color(0xFFB45309),
              ],
            ).createShader(crownRect),
        );

        // Joias 3D
        canvas.drawCircle(
          Offset(cx, cy - (43 * scale)),
          3.4 * scale,
          Paint()..color = const Color(0xFFEF4444),
        );
        canvas.drawCircle(
          Offset(cx - (14 * scale), cy - (40 * scale)),
          2.4 * scale,
          Paint()..color = const Color(0xFF10B981),
        );
        canvas.drawCircle(
          Offset(cx + (14 * scale), cy - (40 * scale)),
          2.4 * scale,
          Paint()..color = const Color(0xFF3B82F6),
        );
        break;

      case 'hat_tophat':
        final brimRect = Rect.fromCenter(
          center: Offset(cx, cy - (35 * scale)),
          width: 56 * scale,
          height: 9 * scale,
        );
        final cylinderRect = Rect.fromLTWH(
          cx - (19 * scale),
          cy - (63 * scale),
          38 * scale,
          28 * scale,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(cylinderRect, Radius.circular(5 * scale)),
          Paint()
            ..shader = const LinearGradient(
              colors: [Color(0xFF475569), Color(0xFF0F172A)],
            ).createShader(cylinderRect),
        );
        // Faixa roxa acetinada
        canvas.drawRect(
          Rect.fromLTWH(
            cx - (19 * scale),
            cy - (42 * scale),
            38 * scale,
            6 * scale,
          ),
          Paint()..color = const Color(0xFF8B5CF6),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(brimRect, Radius.circular(5 * scale)),
          Paint()..color = const Color(0xFF1E293B),
        );
        break;

      case 'hat_cap':
        final capRect = Rect.fromCenter(
          center: Offset(cx, cy - (36 * scale)),
          width: 48 * scale,
          height: 22 * scale,
        );
        canvas.drawOval(
          capRect,
          Paint()
            ..shader = const RadialGradient(
              center: Alignment(-0.3, -0.4),
              colors: [Color(0xFF60A5FA), Color(0xFF1D4ED8)],
            ).createShader(capRect),
        );
        final visorRect = Rect.fromLTWH(
          cx - (8 * scale),
          cy - (33 * scale),
          38 * scale,
          7 * scale,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(visorRect, Radius.circular(4 * scale)),
          Paint()..color = const Color(0xFF1E40AF),
        );
        break;

      case 'hat_glasses':
        for (final sign in [-1.0, 1.0]) {
          final lensRect = Rect.fromCenter(
            center: Offset(cx + (sign * 19 * scale), cy - (7 * scale)),
            width: 23 * scale,
            height: 16 * scale,
          );
          final lensRRect = RRect.fromRectAndRadius(
            lensRect,
            Radius.circular(5 * scale),
          );
          canvas.drawRRect(
            lensRRect,
            Paint()
              ..shader = const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF334155), Color(0xFF020617)],
              ).createShader(lensRect),
          );
          // Reflexo diagonal branco 3D na lente
          canvas.drawLine(
            Offset(lensRect.left + (4 * scale), lensRect.bottom - (4 * scale)),
            Offset(lensRect.left + (11 * scale), lensRect.top + (4 * scale)),
            Paint()
              ..color = Colors.white.withValues(alpha: 0.55)
              ..strokeWidth = 2.2 * scale
              ..strokeCap = StrokeCap.round,
          );
        }
        // Ponte dourada
        canvas.drawLine(
          Offset(cx - (8 * scale), cy - (8 * scale)),
          Offset(cx + (8 * scale), cy - (8 * scale)),
          Paint()
            ..color = const Color(0xFFFBBF24)
            ..strokeWidth = 2.8 * scale,
        );
        break;

      case 'hat_grad':
        // Chapéu de formatura (mortarboard) 3D
        final boardPath = Path()
          ..moveTo(cx, cy - (56 * scale))
          ..lineTo(cx + (34 * scale), cy - (44 * scale))
          ..lineTo(cx, cy - (34 * scale))
          ..lineTo(cx - (34 * scale), cy - (44 * scale))
          ..close();
        canvas.drawPath(boardPath, Paint()..color = const Color(0xFF1E293B));
        // Tassel dourado
        canvas.drawLine(
          Offset(cx, cy - (45 * scale)),
          Offset(cx + (24 * scale), cy - (34 * scale)),
          Paint()
            ..color = const Color(0xFFFBBF24)
            ..strokeWidth = 2.2 * scale,
        );
        break;

      case 'hat_chef':
        // Chapéu de Chef branco 3D
        final baseRect = Rect.fromCenter(
          center: Offset(cx, cy - (36 * scale)),
          width: 40 * scale,
          height: 10 * scale,
        );
        canvas.drawCircle(
          Offset(cx - (10 * scale), cy - (46 * scale)),
          11 * scale,
          Paint()..color = Colors.white,
        );
        canvas.drawCircle(
          Offset(cx + (10 * scale), cy - (46 * scale)),
          11 * scale,
          Paint()..color = Colors.white,
        );
        canvas.drawCircle(
          Offset(cx, cy - (50 * scale)),
          13 * scale,
          Paint()..color = const Color(0xFFF8FAFC),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(baseRect, Radius.circular(4 * scale)),
          Paint()..color = const Color(0xFFE2E8F0),
        );
        break;

      case 'hat_beanie':
        final beanieRect = Rect.fromCenter(
          center: Offset(cx, cy - (36 * scale)),
          width: 50 * scale,
          height: 24 * scale,
        );
        canvas.drawOval(
          beanieRect,
          Paint()
            ..shader = const RadialGradient(
              center: Alignment(-0.3, -0.4),
              colors: [Color(0xFF67E8F9), Color(0xFF0891B2)],
            ).createShader(beanieRect),
        );
        canvas.drawCircle(
          Offset(cx, cy - (49 * scale)),
          7.5 * scale,
          Paint()..color = Colors.white,
        );
        break;
    }
  }

  /// Desenha roupinhas 3D (.slot-cloth) sobre o tronco do Porko
  void _draw3DClothes(
    Canvas canvas,
    double cx,
    double cy,
    double scale,
    String clothId,
  ) {
    switch (clothId) {
      case 'cloth_bowtie':
      case 'cloth_bow':
        final bowY = cy + (31 * scale);
        final leftWing = Path()
          ..moveTo(cx, bowY)
          ..lineTo(cx - (15 * scale), bowY - (7 * scale))
          ..lineTo(cx - (15 * scale), bowY + (7 * scale))
          ..close();
        final rightWing = Path()
          ..moveTo(cx, bowY)
          ..lineTo(cx + (15 * scale), bowY - (7 * scale))
          ..lineTo(cx + (15 * scale), bowY + (7 * scale))
          ..close();

        // Sombra da gravata
        canvas.drawPath(
          leftWing.shift(Offset(0, 2 * scale)),
          Paint()..color = Colors.black26,
        );
        canvas.drawPath(
          rightWing.shift(Offset(0, 2 * scale)),
          Paint()..color = Colors.black26,
        );

        final bowPaint = Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF87171), Color(0xFFDC2626)],
          ).createShader(
            Rect.fromCenter(
              center: Offset(cx, bowY),
              width: 30 * scale,
              height: 14 * scale,
            ),
          );
        canvas.drawPath(leftWing, bowPaint);
        canvas.drawPath(rightWing, bowPaint);
        canvas.drawCircle(
          Offset(cx, bowY),
          4.2 * scale,
          Paint()..color = const Color(0xFFB91C1C),
        );
        break;

      case 'cloth_scarf':
        // Cachecol vermelho 3D aconchegante
        final scarfRect = Rect.fromCenter(
          center: Offset(cx, cy + (30 * scale)),
          width: 64 * scale,
          height: 12 * scale,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(scarfRect, Radius.circular(6 * scale)),
          Paint()
            ..shader = const LinearGradient(
              colors: [Color(0xFFEF4444), Color(0xFFB91C1C)],
            ).createShader(scarfRect),
        );
        // Ponta caída do cachecol
        final tailRect = Rect.fromLTWH(
          cx + (10 * scale),
          cy + (30 * scale),
          12 * scale,
          18 * scale,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(tailRect, Radius.circular(4 * scale)),
          Paint()..color = const Color(0xFFDC2626),
        );
        break;

      case 'cloth_tshirt':
        final shirtRect = Rect.fromCenter(
          center: Offset(cx, cy + (31 * scale)),
          width: 74 * scale,
          height: 22 * scale,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(shirtRect, Radius.circular(11 * scale)),
          Paint()
            ..shader = const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF34D399), Color(0xFF059669)],
            ).createShader(shirtRect),
        );
        break;

      case 'cloth_tie':
      case 'cloth_suit':
        // Gravata executiva vermelha 3D
        final tieY = cy + (29 * scale);
        final tiePath = Path()
          ..moveTo(cx - (3.5 * scale), tieY)
          ..lineTo(cx + (3.5 * scale), tieY)
          ..lineTo(cx + (5.5 * scale), tieY + (14 * scale))
          ..lineTo(cx, tieY + (19 * scale))
          ..lineTo(cx - (5.5 * scale), tieY + (14 * scale))
          ..close();
        canvas.drawPath(tiePath, Paint()..color = const Color(0xFFDC2626));
        break;

      case 'cloth_jacket':
        final jacketRect = Rect.fromCenter(
          center: Offset(cx, cy + (31 * scale)),
          width: 76 * scale,
          height: 24 * scale,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(jacketRect, Radius.circular(11 * scale)),
          Paint()
            ..shader = const LinearGradient(
              colors: [Color(0xFF334155), Color(0xFF0F172A)],
            ).createShader(jacketRect),
        );
        // Zíper metálico central
        canvas.drawLine(
          Offset(cx, jacketRect.top + (2 * scale)),
          Offset(cx, jacketRect.bottom - (2 * scale)),
          Paint()
            ..color = const Color(0xFF94A3B8)
            ..strokeWidth = 2.2 * scale,
        );
        break;
    }
  }

  /// Capa de herói 3D esvoaçante atrás do corpo
  void _drawHeroCape3D(
    Canvas canvas,
    double cx,
    double cy,
    double scale,
    double bobWave,
  ) {
    final flutter = bobWave * 4.0 * scale;
    final capePath = Path()
      ..moveTo(cx - (34 * scale), cy - (4 * scale))
      ..quadraticBezierTo(
        cx - (54 * scale),
        cy + (22 * scale),
        cx - (52 * scale) + flutter,
        cy + (44 * scale),
      )
      ..lineTo(cx + (52 * scale) + flutter, cy + (44 * scale))
      ..quadraticBezierTo(
        cx + (54 * scale),
        cy + (22 * scale),
        cx + (34 * scale),
        cy - (4 * scale),
      )
      ..close();

    final capeRect = Rect.fromCenter(
      center: Offset(cx, cy + (20 * scale)),
      width: 108 * scale,
      height: 52 * scale,
    );
    canvas.drawPath(
      capePath,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFEF4444), Color(0xFFB91C1C)],
        ).createShader(capeRect),
    );
  }

  /// Plaquinha de madeira 3D amigável para quando o usuário não possui metas (.signboard)
  void _drawSignboard3D(Canvas canvas, double cx, double cy, double scale) {
    canvas.save();
    canvas.translate(cx + (54 * scale), cy - (4 * scale));
    canvas.rotate(0.10); // ~6 graus

    final boardRect = Rect.fromCenter(
      center: Offset.zero,
      width: 102 * scale,
      height: 36 * scale,
    );
    final boardRRect = RRect.fromRectAndRadius(
      boardRect,
      Radius.circular(10 * scale),
    );

    // Sombra 3D da plaquinha
    canvas.drawRRect(
      boardRRect.shift(Offset(0, 4 * scale)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.25)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 * scale),
    );

    // Fundo da plaquinha (#FEF3C7)
    canvas.drawRRect(
      boardRRect,
      Paint()..color = const Color(0xFFFEF3C7),
    );

    // Borda da placa (#B45309)
    canvas.drawRRect(
      boardRRect,
      Paint()
        ..color = const Color(0xFFB45309)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5 * scale,
    );

    final textPainter = TextPainter(
      text: TextSpan(
        text: 'Crie sua 1ª meta!\n🪙',
        style: TextStyle(
          color: const Color(0xFF78350F),
          fontSize: 9.8 * scale,
          fontWeight: FontWeight.w800,
          height: 1.15,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 96 * scale);

    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -textPainter.height / 2),
    );

    canvas.restore();
  }

  /// Confetes festivos 3D ao redor do Porko
  void _drawCelebrationEffects(
    Canvas canvas,
    double cx,
    double cy,
    double scale,
  ) {
    final colors = [
      const Color(0xFFF59E0B),
      const Color(0xFF10B981),
      const Color(0xFFEC4899),
      const Color(0xFF3B82F6),
    ];

    final offsets = [
      Offset(cx - (48 * scale), cy - (42 * scale)),
      Offset(cx + (48 * scale), cy - (44 * scale)),
      Offset(cx - (32 * scale), cy - (62 * scale)),
      Offset(cx + (34 * scale), cy - (60 * scale)),
      Offset(cx - (62 * scale), cy - (12 * scale)),
      Offset(cx + (62 * scale), cy - (10 * scale)),
    ];

    for (int i = 0; i < offsets.length; i++) {
      final p = Paint()..color = colors[i % colors.length];
      canvas.drawCircle(offsets[i], 3.8 * scale, p);
    }
  }

  /// Desenha partículas de reação de cuidado (❤️, 🍎, 🎾, 📣)
  void _drawReactionParticles(
    Canvas canvas,
    double cx,
    double cy,
    double scale,
    String reaction,
  ) {
    String symbol = '❤️';
    if (reaction == 'eat') symbol = '🍎';
    if (reaction == 'play') symbol = '🎾';
    if (reaction == 'call') symbol = '🎵';

    final tp = TextPainter(
      text: TextSpan(
        text: symbol,
        style: TextStyle(fontSize: 20 * scale),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(canvas, Offset(cx + (36 * scale), cy - (56 * scale)));
  }

  @override
  bool shouldRepaint(_PorkoSoft3DPainter old) =>
      old.mood != mood ||
      old.mascot.skinId != mascot.skinId ||
      old.mascot.hatId != mascot.hatId ||
      old.mascot.clothId != mascot.clothId ||
      old.showSign != showSign ||
      old.isDark != isDark ||
      old.compact != compact ||
      old.idlePhase != idlePhase ||
      old.jumpProgress != jumpProgress ||
      old.isBlinking != isBlinking ||
      old.activeReaction != activeReaction;
}
