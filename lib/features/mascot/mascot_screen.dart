import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/global_providers.dart';
import '../../data/models/mascot_model.dart';
import '../shop/porko_store_screen.dart';

// Tela do Cantinho do Mascote idêntica ao protótipo v3 (cuidados com afeto, bem-estar anti-culpa e personalização)
class MascotScreen extends ConsumerStatefulWidget {
  const MascotScreen({super.key});

  @override
  ConsumerState<MascotScreen> createState() => _MascotScreenState();
}

class _MascotScreenState extends ConsumerState<MascotScreen> {
  // Limites e contadores locais dos 4 cuidados diários conforme especificado
  int _petCount = 0;
  int _feedCount = 0;
  int _playCount = 0;
  int _callCount = 0;

  static const int _petMax = 3;
  static const int _feedMax = 2;
  static const int _playMax = 2;
  static const int _callMax = 3;

  // Abre diálogo simples para alterar o nome do mascote
  void _openRenameDialog(BuildContext context, MascotModel mascot) {
    HapticFeedback.selectionClick();
    final controller = TextEditingController(text: mascot.name);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1B2E22) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Nome do mascote',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 16,
          decoration: InputDecoration(
            hintText: 'Dê um nome ao seu Porko...',
            filled: true,
            fillColor: isDark ? const Color(0xFF243B2A) : const Color(0xFFEEF3EE),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: isDark ? Colors.white60 : const Color(0xFF566259),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                final messenger = ScaffoldMessenger.of(context);
                await ref.read(mascotRepositoryProvider).renameMascot(newName);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Nome atualizado! ✨'),
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(milliseconds: 1500),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFBE185D),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Salvar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Executa uma das 4 ações de afeto com feedback sonoro/tátil e limites diários
  Future<void> _handleCareAction({
    required String actionKey,
    required String label,
    required String emoji,
    required Future<bool> Function() action,
  }) async {
    HapticFeedback.mediumImpact();

    // Validação estrita dos limites diários decididos
    bool canProceed = false;
    if (actionKey == 'pet' && _petCount < _petMax) {
      _petCount++;
      canProceed = true;
    } else if (actionKey == 'feed' && _feedCount < _feedMax) {
      _feedCount++;
      canProceed = true;
    } else if (actionKey == 'play' && _playCount < _playMax) {
      _playCount++;
      canProceed = true;
    } else if (actionKey == 'call' && _callCount < _callMax) {
      _callCount++;
      canProceed = true;
    }

    if (!canProceed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Limite de $label atingido por hoje! 💤'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 1500),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() {});
    await action();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$emoji O Porko adorou!'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 1500),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  // Aplica uma cor de pele rápida diretamente no Porko
  Future<void> _applySkin(String skinId) async {
    HapticFeedback.selectionClick();
    await ref.read(mascotRepositoryProvider).equipItem(
      category: 'skin',
      itemId: skinId,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cor aplicada ✨'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(milliseconds: 1200),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mascot = ref.watch(equippedMascotProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Respeita estritamente o piso inegociável de 40% de felicidade e 35% de energia
    final happinessPct = (mascot.happiness.clamp(40.0, 100.0)).round();
    final energyPct = (mascot.energy.clamp(35.0, 100.0)).round();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1F14) : const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── 1. Header Magenta com Cantos de 36dp e Avatar Integrado ──────
            Semantics(
              label: 'Cantinho do Mascote',
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 52, 20, 24),
                decoration: BoxDecoration(
                  gradient: isDark
                      ? const LinearGradient(
                          colors: [Color(0xFF831843), Color(0xFF9D174D), Color(0xFFBE185D)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : const LinearGradient(
                          colors: [Color(0xFFBE185D), Color(0xFFEC4899), Color(0xFFF472B6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🐷 Cantinho do Mascote',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Card translúcido integrado do mascote
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.20),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
                      ),
                      child: Row(
                        children: [
                          // Avatar esférico com degradê radial Soft 3D
                          Container(
                            width: 60,
                            height: 60,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                center: Alignment(-0.3, -0.4),
                                radius: 0.9,
                                colors: [Color(0xFFFFD1DC), Color(0xFFFF8DA1), Color(0xFFE06079)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 8,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text('🐷', style: TextStyle(fontSize: 32)),
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Nome do mascote e tempo de adoção
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        mascot.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    InkWell(
                                      onTap: () => _openRenameDialog(context, mascot),
                                      borderRadius: BorderRadius.circular(20),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.30),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: const Text(
                                          'Renomear ✏️',
                                          style: TextStyle(
                                            fontFamily: 'Nunito',
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Adotado em 10/10/2026 • 4 meses de cofrinho',
                                  style: TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: 11,
                                    color: Colors.white.withValues(alpha: 0.90),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── 2. Card de Bem-Estar com Mecânica Anti-Culpa ──────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1B2E22) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? const Color(0xFF2F4A37) : const Color(0xFFE2E8E2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
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
                          'Bem-estar',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Depositou hoje 🎉',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDark ? const Color(0xFFA5D6A7) : const Color(0xFF566259),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Barra de Felicidade (mínimo 40%)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '💖 Felicidade',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '$happinessPct%',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        height: 10,
                        color: isDark ? const Color(0xFF243B2A) : const Color(0xFFEEF3EE),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: (happinessPct / 100.0).clamp(0.0, 1.0),
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFFF472B6), Color(0xFFE11D48)],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Barra de Energia (mínimo 35%)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '⚡ Energia',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '$energyPct%',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        height: 10,
                        color: isDark ? const Color(0xFF243B2A) : const Color(0xFFEEF3EE),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: (energyPct / 100.0).clamp(0.0, 1.0),
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),
                    Text(
                      'Sobe com depósitos e carinho; cai devagar sem depósitos, nunca abaixo de 40%. O Porko só fica com saudade 🥺, sem culpa.',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 11,
                        color: isDark ? const Color(0xFFA5D6A7) : const Color(0xFF566259),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── 3. Seção "Cuidados de hoje" (4 Ações com Limites Diários) ────
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Cuidados de hoje',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 10),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  // Ação 1: Acariciar
                  Expanded(
                    child: _buildCareActionItem(
                      emoji: '❤️',
                      label: 'Acariciar',
                      count: _petCount,
                      max: _petMax,
                      isDark: isDark,
                      onTap: () => _handleCareAction(
                        actionKey: 'pet',
                        label: 'Acariciar',
                        emoji: '❤️',
                        action: () => ref.read(mascotRepositoryProvider).petMascot(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Ação 2: Alimentar
                  Expanded(
                    child: _buildCareActionItem(
                      emoji: '🍎',
                      label: 'Alimentar',
                      count: _feedCount,
                      max: _feedMax,
                      isDark: isDark,
                      onTap: () => _handleCareAction(
                        actionKey: 'feed',
                        label: 'Alimentar',
                        emoji: '🍎',
                        action: () => ref.read(mascotRepositoryProvider).feedMascot(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Ação 3: Brincar
                  Expanded(
                    child: _buildCareActionItem(
                      emoji: '🎾',
                      label: 'Brincar',
                      count: _playCount,
                      max: _playMax,
                      isDark: isDark,
                      onTap: () => _handleCareAction(
                        actionKey: 'play',
                        label: 'Brincar',
                        emoji: '🎾',
                        action: () => ref.read(mascotRepositoryProvider).playWithMascot(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Ação 4: Chamar
                  Expanded(
                    child: _buildCareActionItem(
                      emoji: '📣',
                      label: 'Chamar',
                      count: _callCount,
                      max: _callMax,
                      isDark: isDark,
                      onTap: () => _handleCareAction(
                        actionKey: 'call',
                        label: 'Chamar',
                        emoji: '📣',
                        action: () => ref.read(mascotRepositoryProvider).callMascot(),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── 4. Card de Aparência (3 Skins Rápidas & Guarda-Roupa) ─────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1B2E22) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? const Color(0xFF2F4A37) : const Color(0xFFE2E8E2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Aparência',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Swatches de 3 cores com degradê radial
                    Row(
                      children: [
                        _buildSkinSwatch(
                          id: 'pink_classic',
                          label: 'Rosa Clássico',
                          isSelected: mascot.skinId == 'pink_classic',
                          colors: const [Color(0xFFFFD1DC), Color(0xFFFF8DA1), Color(0xFFE06079)],
                          onTap: () => _applySkin('pink_classic'),
                        ),
                        const SizedBox(width: 14),
                        _buildSkinSwatch(
                          id: 'chocolate',
                          label: 'Chocolate Doce',
                          isSelected: mascot.skinId == 'chocolate',
                          colors: const [Color(0xFFC8A58F), Color(0xFF8D6E63), Color(0xFF5D4037)],
                          onTap: () => _applySkin('chocolate'),
                        ),
                        const SizedBox(width: 14),
                        _buildSkinSwatch(
                          id: 'golden',
                          label: 'Dourado Lendário',
                          isSelected: mascot.skinId == 'golden',
                          colors: const [Color(0xFFFFF2A8), Color(0xFFFFD54F), Color(0xFFF59E0B)],
                          onTap: () => _applySkin('golden'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Botão que abre o guarda-roupa na Porko Store
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const PorkoStoreScreen()),
                          );
                        },
                        icon: const Text('👗', style: TextStyle(fontSize: 16)),
                        label: const Text(
                          'Abrir guarda-roupa',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? const Color(0xFF243B2A) : const Color(0xFFEEF3EE),
                          foregroundColor: isDark ? Colors.white : const Color(0xFF1A1A1A),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── 5. Card de Personalidade ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1B2E22) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? const Color(0xFF2F4A37) : const Color(0xFFE2E8E2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Personalidade',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildTraitChip('🐷 Econômico e otimista', isDark),
                        _buildTraitChip('🍏 Adora maçãs', isDark),
                        _buildTraitChip('💤 Dorminhoco', isDark),
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

  // Item de botão de cuidado diário com indicador n/max
  Widget _buildCareActionItem({
    required String emoji,
    required String label,
    required int count,
    required int max,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final isMaxReached = count >= max;
    return InkWell(
      onTap: isMaxReached ? null : onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isMaxReached ? 0.45 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1B2E22) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? const Color(0xFF2F4A37) : const Color(0xFFE2E8E2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$count/$max',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFFA5D6A7) : const Color(0xFF566259),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Amostra esférica de cor de pele
  Widget _buildSkinSwatch({
    required String id,
    required String label,
    required bool isSelected,
    required List<Color> colors,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: const Alignment(-0.3, -0.4),
            radius: 0.9,
            colors: colors,
          ),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: isSelected ? 3 : 0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colors.last.withValues(alpha: 0.6),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
      ),
    );
  }

  // Chip de traço de personalidade
  Widget _buildTraitChip(String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF243B2A) : const Color(0xFFEEF3EE),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF2F4A37) : const Color(0xFFE2E8E2),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : const Color(0xFF1A1A1A),
        ),
      ),
    );
  }
}
