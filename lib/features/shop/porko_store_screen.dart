import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/global_providers.dart';
import '../../data/models/shop_item_model.dart';
import '../../data/models/mascot_model.dart';
import '../../widgets/porko_canvas_widget.dart';

// Tela da Lojinha do Porko com Vitrine, Guarda-Roupa e Mini-Palco de Preview Soft 3D
class PorkoStoreScreen extends ConsumerStatefulWidget {
  const PorkoStoreScreen({super.key});

  @override
  ConsumerState<PorkoStoreScreen> createState() => _PorkoStoreScreenState();
}

class _PorkoStoreScreenState extends ConsumerState<PorkoStoreScreen> {
  // Modo de exibição: 'shop' (Vitrine com tudo) ou 'closet' (Guarda-roupa somente possuídos)
  String _storeMode = 'shop';

  // Categoria atualmente selecionada
  CosmeticCategory _selectedCategory = CosmeticCategory.skin;

  static const _categories = [
    CosmeticCategory.skin,
    CosmeticCategory.hat,
    CosmeticCategory.cloth,
    CosmeticCategory.backdrop,
  ];

  String _categoryLabel(CosmeticCategory category) {
    switch (category) {
      case CosmeticCategory.skin:
        return 'Skins';
      case CosmeticCategory.hat:
        return 'Cabeça';
      case CosmeticCategory.cloth:
        return 'Roupas';
      case CosmeticCategory.backdrop:
        return 'Cenários';
    }
  }

  // Verifica se o item cosmético está atualmente vestido pelo mascote
  bool _isItemEquipped(ShopItem item, MascotModel mascot) {
    switch (item.category) {
      case CosmeticCategory.skin:
        return mascot.skinId == item.id;
      case CosmeticCategory.hat:
        return mascot.hatId == item.id;
      case CosmeticCategory.cloth:
        return mascot.clothId == item.id;
      case CosmeticCategory.backdrop:
        return mascot.backdropId == item.id ||
            (mascot.backdropId == null && item.id == 'backdrop_default');
    }
  }

  // Cria uma cópia temporária do mascote provando o item cosmético no mini-palco
  MascotModel _createPreviewMascot(ShopItem item, MascotModel baseMascot) {
    switch (item.category) {
      case CosmeticCategory.skin:
        return baseMascot.copyWith(skinId: item.id);
      case CosmeticCategory.hat:
        return baseMascot.copyWith(hatId: item.id);
      case CosmeticCategory.cloth:
        return baseMascot.copyWith(clothId: item.id);
      case CosmeticCategory.backdrop:
        return baseMascot.copyWith(backdropId: item.id);
    }
  }

  // Abre o bottom sheet com o mini-palco de preview do Porko vestindo o item
  void _openPreviewSheet(
    BuildContext context,
    ShopItem item,
    bool isOwned,
    bool isEquipped,
    bool canAfford,
    MascotModel mascot,
    int balance,
  ) {
    HapticFeedback.selectionClick();
    final previewMascot = _createPreviewMascot(item, mascot);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1B2E22) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 5,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),

              // Mini-Palco de Preview com o Porko ao vivo
              Container(
                height: 176,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7DD3FC), Color(0xFF86EFAC), Color(0xFF34D399)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: PorkoCanvasWidget(
                    mood: ref.watch(porkoMoodProvider),
                    mascot: previewMascot,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Nome e Preço
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      item.name,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF243B2A) : const Color(0xFFEEF3EE),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isOwned ? 'Adquirido ✓' : '🪙 ${item.price} Coins',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isDark ? const Color(0xFF00C853) : const Color(0xFF2E7D32),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              // Descrição do cosmético
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  item.description,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    color: isDark ? Colors.white70 : const Color(0xFF566259),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Botão de ação (Comprar ou Equipar/Remover)
              SizedBox(
                width: double.infinity,
                child: isOwned
                    ? ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await _equipItem(item, isEquipped);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isEquipped
                              ? (isDark ? const Color(0xFF243B2A) : const Color(0xFFE2E8E2))
                              : const Color(0xFF2E7D32),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          isEquipped ? 'Remover do Porko' : 'Equipar no Porko ✨',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold,
                            color: isEquipped
                                ? (isDark ? Colors.white : const Color(0xFF1A1A1A))
                                : Colors.white,
                          ),
                        ),
                      )
                    : ElevatedButton(
                        onPressed: canAfford
                            ? () async {
                                Navigator.pop(ctx);
                                await _buyItem(item);
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          disabledBackgroundColor: Colors.grey.withValues(alpha: 0.3),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          canAfford
                              ? 'Confirmar Compra'
                              : 'Faltam ${item.price - balance} moedas',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
              ),

              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  // Equipa ou desequipa o item cosmético no mascote
  Future<void> _equipItem(ShopItem item, bool isEquipped) async {
    HapticFeedback.selectionClick();
    final mascotRepo = ref.read(mascotRepositoryProvider);
    await mascotRepo.equipItem(
      category: item.category.name,
      itemId: item.id,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEquipped
                ? '${item.name} desequipado.'
                : '${item.name} equipado no Porko! ✨',
          ),
          duration: const Duration(milliseconds: 1500),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  // Efetua a compra do item cosmético com debito das Oinc Coins
  Future<void> _buyItem(ShopItem item) async {
    HapticFeedback.mediumImpact();
    final mascotRepo = ref.read(mascotRepositoryProvider);
    final walletRepo = ref.read(walletRepositoryProvider);
    final gamificationRepo = ref.read(gamificationRepositoryProvider);

    final success = await mascotRepo.buyItem(
      item: item,
      walletRepo: walletRepo,
      gamificationRepo: gamificationRepo,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🛍️ ${item.name} comprado e equipado com sucesso!'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Saldo insuficiente de Oinc Coins!'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final balance = ref.watch(walletBalanceProvider);
    final mascot = ref.watch(equippedMascotProvider);
    final inventory = ref.watch(mascotInventoryProvider);

    // Filtra itens por categoria e por modo de visualização (Vitrine vs Guarda-roupa)
    final allCategoryItems = ShopCatalog.getByCategory(_selectedCategory);
    final displayedItems = _storeMode == 'closet'
        ? allCategoryItems.where((i) => inventory.contains(i.id) || i.isFree).toList()
        : allCategoryItems;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1F14) : const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── 1. Header com Gradiente Roxo Mágico e Cantos de 36dp ─────────
            Semantics(
              label: 'Porko Store',
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 52, 20, 20),
                decoration: BoxDecoration(
                  gradient: isDark
                      ? const LinearGradient(
                          colors: [Color(0xFF4A148C), Color(0xFF6B21A8), Color(0xFF7E22CE)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : const LinearGradient(
                          colors: [Color(0xFF6B21A8), Color(0xFF8B5CF6), Color(0xFFA855F7)],
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
                  children: [
                    // Título e Saldo de Moedas
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Text('🛍️ ', style: TextStyle(fontSize: 22)),
                            Text(
                              'Porko Store',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        // Pílula com o saldo de moedas em destaque
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              const Text('🪙', style: TextStyle(fontSize: 14)),
                              const SizedBox(width: 6),
                              Text(
                                '$balance Coins',
                                style: const TextStyle(
                                  fontFamily: 'Quicksand',
                                  color: Color(0xFFFDE68A),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Segmented Control: Vitrine vs Guarda-roupa
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => setState(() => _storeMode = 'shop'),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: _storeMode == 'shop'
                                      ? (isDark ? const Color(0xFF1B2E22) : Colors.white)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: _storeMode == 'shop'
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.15),
                                            blurRadius: 6,
                                          )
                                        ]
                                      : null,
                                ),
                                child: Text(
                                  'Vitrine',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: _storeMode == 'shop'
                                        ? (isDark ? Colors.white : const Color(0xFF1A1A1A))
                                        : Colors.white70,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: InkWell(
                              onTap: () => setState(() => _storeMode = 'closet'),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: _storeMode == 'closet'
                                      ? (isDark ? const Color(0xFF1B2E22) : Colors.white)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: _storeMode == 'closet'
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.15),
                                            blurRadius: 6,
                                          )
                                        ]
                                      : null,
                                ),
                                child: Text(
                                  'Guarda-roupa',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: _storeMode == 'closet'
                                        ? (isDark ? Colors.white : const Color(0xFF1A1A1A))
                                        : Colors.white70,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // ── 2. Carrossel Horizontal de Chips de Categorias ────────────────
            SizedBox(
              height: 40,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = _selectedCategory == cat;
                  return InkWell(
                    onTap: () => setState(() => _selectedCategory = cat),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark ? const Color(0xFF00C853) : const Color(0xFF2E7D32))
                            : (isDark ? const Color(0xFF243B2A) : const Color(0xFFEEF3EE)),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? Colors.transparent
                              : (isDark ? const Color(0xFF2F4A37) : const Color(0xFFE2E8E2)),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _categoryLabel(cat),
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? Colors.white70 : const Color(0xFF566259)),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // ── 3. Grid de Itens Cosméticos ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: displayedItems.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(32),
                      alignment: Alignment.center,
                      child: Text(
                        'Nenhum item por aqui ainda.',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          color: isDark ? Colors.white60 : const Color(0xFF566259),
                          fontSize: 14,
                        ),
                      ),
                    )
                  : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.82,
                      ),
                      itemCount: displayedItems.length,
                      itemBuilder: (context, index) {
                        final item = displayedItems[index];
                        final isOwned = inventory.contains(item.id) || item.isFree;
                        final isEquipped = _isItemEquipped(item, mascot);
                        final canAfford = balance >= item.price;

                        return _buildItemCard(
                          item: item,
                          isOwned: isOwned,
                          isEquipped: isEquipped,
                          canAfford: canAfford,
                          isDark: isDark,
                          onTap: () => _openPreviewSheet(
                            context,
                            item,
                            isOwned,
                            isEquipped,
                            canAfford,
                            mascot,
                            balance,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // Card individual do produto no grid
  Widget _buildItemCard({
    required ShopItem item,
    required bool isOwned,
    required bool isEquipped,
    required bool canAfford,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1B2E22) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isEquipped
                ? (isDark ? const Color(0xFF00C853) : const Color(0xFF2E7D32))
                : (isDark ? const Color(0xFF2F4A37) : const Color(0xFFE2E8E2)),
            width: isEquipped ? 2 : 1,
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ícone ou emoji grande do item
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? const Color(0xFF243B2A) : const Color(0xFFEEF3EE),
              ),
              child: Center(
                child: Text(
                  _getItemEmoji(item),
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Nome do item
            Text(
              item.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),

            // Preço ou status
            Text(
              isEquipped
                  ? 'Equipado ✨'
                  : isOwned
                      ? 'Equipar'
                      : '🪙 ${item.price}',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.bold,
                fontSize: 11,
                color: isEquipped
                    ? (isDark ? const Color(0xFF00C853) : const Color(0xFF2E7D32))
                    : isOwned
                        ? (isDark ? const Color(0xFFA5D6A7) : const Color(0xFF566259))
                        : (isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getItemEmoji(ShopItem item) {
    switch (item.id) {
      case 'pink_classic':
        return '🐷';
      case 'chocolate':
        return '🍫';
      case 'golden':
        return '👑';
      case 'hat_cap':
        return '🧢';
      case 'hat_crown':
        return '👑';
      case 'hat_glasses':
        return '🕶️';
      case 'cloth_bow':
        return '🎀';
      case 'cloth_suit':
        return '👔';
      case 'cloth_cape':
        return '🦸';
      case 'backdrop_beach':
        return '🏖️';
      case 'backdrop_park':
        return '🌳';
      default:
        return '✨';
    }
  }
}
