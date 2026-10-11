import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/global_providers.dart';
import '../../data/models/shop_item_model.dart';
import '../../data/models/mascot_model.dart';
import '../../widgets/porko_canvas_widget.dart';

class PorkoStoreScreen extends ConsumerStatefulWidget {
  const PorkoStoreScreen({super.key});

  @override
  ConsumerState<PorkoStoreScreen> createState() => _PorkoStoreScreenState();
}

class _PorkoStoreScreenState extends ConsumerState<PorkoStoreScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _categories = [
    CosmeticCategory.skin,
    CosmeticCategory.hat,
    CosmeticCategory.cloth,
    CosmeticCategory.backdrop,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
  }

  @override
  void dispose) {
    _tabController.dispose();
    super.dispose();
  }

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final balance = ref.watch(walletBalanceProvider);
    final mascot = ref.watch(equippedMascotProvider);
    final inventory = ref.watch(mascotInventoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Porko Store'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Text('🪙', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(
                  '$balance Coins',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Hub de Pré-visualização do Mascote em tempo real
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              children: [
                PorkoCanvasWidget(
                  mood: ref.watch(porkoMoodProvider),
                  mascot: mascot,
                ),
              ],
            ),
          ),

          // 2. Abas de Categorias da Loja
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(16),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(14),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
              tabs: _categories.map((c) => Tab(text: _categoryLabel(c))).toList(),
            ),
          ),

          const SizedBox(height: 12),

          // 3. Vitrine de Itens Cosméticos
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _categories.map((cat) {
                final items = ShopCatalog.getByCategory(cat);
                return _buildCategoryGrid(
                  items,
                  mascot,
                  inventory,
                  balance,
                  isDark,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid(
    List<ShopItem> items,
    MascotModel mascot,
    List<String> inventory,
    int balance,
    bool isDark,
  ) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.76,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isOwned = inventory.contains(item.id) || item.isFree;
        final isEquipped = _isItemEquipped(item, mascot);
        final canAfford = balance >= item.price;

        return _ShopItemCard(
          item: item,
          isOwned: isOwned,
          isEquipped: isEquipped,
          canAfford: canAfford,
          isDark: isDark,
          onTap: () => _handleItemAction(item, isOwned, isEquipped, canAfford),
        );
      },
    );
  }

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

  Future<void> _handleItemAction(
    ShopItem item,
    bool isOwned,
    bool isEquipped,
    bool canAfford,
  ) async {
    final mascotRepo = ref.read(mascotRepositoryProvider);
    final walletRepo = ref.read(walletRepositoryProvider);
    final gamificationRepo = ref.read(gamificationRepositoryProvider);

    if (isOwned) {
      HapticFeedback.selectionClick();
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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } else {
      if (!canAfford) {
        HapticFeedback.vibrate();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Saldo insuficiente! Você precisa de mais ${item.price - walletRepo.getBalance()} Oinc Coins.',
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        return;
      }

      // Diálogo de confirmação de compra
      final confirmed = await _confirmPurchase(item);
      if (confirmed == true && mounted) {
        final success = await mascotRepo.buyItem(
          item: item,
          walletRepo: walletRepo,
          gamificationRepo: gamificationRepo,
        );

        if (success && mounted) {
          HapticFeedback.heavyImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '🎉 Parabéns! ${item.name} comprado e equipado com sucesso!',
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    }
  }

  Future<bool?> _confirmPurchase(ShopItem item) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(item.icon, color: item.accentColor),
            const SizedBox(width: 8),
            Text('Comprar ${item.name}?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.description),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Text('🪙', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(
                    'Preço: ${item.price} Oinc Coins',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF92400E),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmar Compra'),
          ),
        ],
      ),
    );
  }
}

class _ShopItemCard extends StatelessWidget {
  final ShopItem item;
  final bool isOwned;
  final bool isEquipped;
  final bool canAfford;
  final bool isDark;
  final VoidCallback onTap;

  const _ShopItemCard({
    required this.item,
    required this.isOwned,
    required this.isEquipped,
    required this.canAfford,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color ??
            (isDark ? const Color(0xFF1E293B) : Colors.white),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isEquipped
              ? theme.colorScheme.primary
              : theme.dividerColor.withValues(alpha: 0.1),
          width: isEquipped ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Ícone decorativo com cor do item
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: item.accentColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              item.icon,
              color: item.accentColor,
              size: 26,
            ),
          ),
          const SizedBox(height: 6),

          // Título e descrição
          Column(
            children: [
              Text(
                item.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.description,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? Colors.white60 : Colors.black54,
                  height: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Botão de Ação / Preço
          SizedBox(
            width: double.infinity,
            height: 36,
            child: _buildActionButton(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(ThemeData theme) {
    if (isEquipped) {
      return ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
          padding: EdgeInsets.zero,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text('Equipado ✨', style: TextStyle(fontSize: 11)),
      );
    }

    if (isOwned) {
      return OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: theme.colorScheme.primary),
          foregroundColor: theme.colorScheme.primary,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text('Equipar', style: TextStyle(fontSize: 11)),
      );
    }

    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: canAfford ? const Color(0xFFF59E0B) : Colors.grey,
        foregroundColor: Colors.white,
        padding: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🪙 ', style: TextStyle(fontSize: 10)),
          Text(
            '${item.price}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
