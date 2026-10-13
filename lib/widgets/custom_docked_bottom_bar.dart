import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Barra de navegação inferior com 4 abas e o botão central (+) projetado para cima
class CustomDockedBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onFabPressed;

  const CustomDockedBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.onFabPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Cores fiéis ao protótipo v3
    final navBg = isDark ? const Color(0xFF12261A) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2F4A37) : const Color(0xFFE2E8E2);
    final activeColor = isDark ? const Color(0xFF00C853) : const Color(0xFF2E7D32);
    final inactiveColor = isDark ? const Color(0xFFA5D6A7) : const Color(0xFF566259);

    final fabGradient = isDark
        ? const LinearGradient(
            colors: [Color(0xFF00A844), Color(0xFF00C853)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF388E3C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    return Container(
      decoration: BoxDecoration(
        color: navBg,
        border: Border(top: BorderSide(color: borderColor, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 76,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Linha das 4 abas simétricas
              Row(
                children: [
                  // Aba 0: Início
                  Expanded(
                    child: _buildNavItem(
                      icon: Icons.home_rounded,
                      label: 'Início',
                      isActive: currentIndex == 0,
                      activeColor: activeColor,
                      inactiveColor: inactiveColor,
                      onTap: () => onTabSelected(0),
                    ),
                  ),

                  // Aba 1: Conquistas
                  Expanded(
                    child: _buildNavItem(
                      icon: Icons.emoji_events_rounded,
                      label: 'Conquistas',
                      isActive: currentIndex == 1,
                      activeColor: activeColor,
                      inactiveColor: inactiveColor,
                      onTap: () => onTabSelected(1),
                    ),
                  ),

                  // Espaço central reservado para o FAB projetado
                  const SizedBox(width: 72),

                  // Aba 2: Lojinha
                  Expanded(
                    child: _buildNavItem(
                      icon: Icons.storefront_rounded,
                      label: 'Lojinha',
                      tooltip: 'Porko Store',
                      isActive: currentIndex == 2,
                      activeColor: activeColor,
                      inactiveColor: inactiveColor,
                      onTap: () => onTabSelected(2),
                    ),
                  ),

                  // Aba 3: Mascote
                  Expanded(
                    child: _buildNavItem(
                      icon: Icons.pets_rounded,
                      label: 'Mascote',
                      isActive: currentIndex == 3,
                      activeColor: activeColor,
                      inactiveColor: inactiveColor,
                      onTap: () => onTabSelected(3),
                    ),
                  ),
                ],
              ),

              // Botão (+) central flutuante projetado para cima
              Positioned(
                top: -22,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    onFabPressed();
                  },
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: fabGradient,
                      border: Border.all(color: navBg, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: (isDark
                                  ? const Color(0xFF00C853)
                                  : const Color(0xFF2E7D32))
                              .withValues(alpha: 0.45),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Item individual de navegação com ícone, texto e indicador pontual
  Widget _buildNavItem({
    required IconData icon,
    required String label,
    String? tooltip,
    required bool isActive,
    required Color activeColor,
    required Color inactiveColor,
    required VoidCallback onTap,
  }) {
    final itemWidget = InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 24,
            color: isActive ? activeColor : inactiveColor,
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
              color: isActive ? activeColor : inactiveColor,
            ),
          ),
          const SizedBox(height: 2),
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? activeColor : Colors.transparent,
            ),
          ),
        ],
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip, child: itemWidget);
    }
    return itemWidget;
  }
}
