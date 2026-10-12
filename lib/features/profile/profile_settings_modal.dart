import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/providers/global_providers.dart';
import '../mascot/mascot_screen.dart';

// Modal deslizante de configurações do usuário e preferências do aplicativo
class ProfileSettingsModal extends ConsumerWidget {
  const ProfileSettingsModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeProvider);
    final mascot = ref.watch(equippedMascotProvider);
    final walletBalance = ref.watch(walletBalanceProvider);
    final streakData = ref.watch(streakProvider);
    final currentStreak = (streakData['currentStreak'] as int?) ?? 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pílula cinza para puxar o modal
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),

          // Cabeçalho com avatar e nome
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                child: const Text(
                  '🐷',
                  style: TextStyle(fontSize: 26),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Poupador Oinc',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '🪙 $walletBalance moedas • 🔥 $currentStreak dias seguidos',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Seletor de Tema (Automático, Claro, Escuro)
          Text(
            'Tema Visual',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildThemeChoice(
                  label: 'Auto',
                  icon: Icons.brightness_auto_rounded,
                  isSelected: themeMode == ThemeMode.system,
                  onTap: () => ref.read(themeProvider.notifier).setTheme(ThemeMode.system),
                  context: context,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildThemeChoice(
                  label: 'Claro',
                  icon: Icons.light_mode_rounded,
                  isSelected: themeMode == ThemeMode.light,
                  onTap: () => ref.read(themeProvider.notifier).setTheme(ThemeMode.light),
                  context: context,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildThemeChoice(
                  label: 'Escuro',
                  icon: Icons.dark_mode_rounded,
                  isSelected: themeMode == ThemeMode.dark,
                  onTap: () => ref.read(themeProvider.notifier).setTheme(ThemeMode.dark),
                  context: context,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Atalho rápido para o cantinho do mascote
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.pets_rounded, color: Color(0xFF10B981)),
            ),
            title: Text('Configurar Mascote (${mascot.name})'),
            subtitle: const Text('Mude o nome, cuide do humor e veja os status'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MascotScreen()),
              );
            },
          ),
          const Divider(height: 24),

          // Informações de versão e privacidade
          Center(
            child: Text(
              'Oinc • Cofrinho 100% Offline e Privado',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  // Card tátil de escolha de tema
  Widget _buildThemeChoice({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required BuildContext context,
  }) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? primary.withValues(alpha: 0.15)
              : theme.cardTheme.color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? primary : Colors.grey.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? primary : Colors.grey,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? primary : theme.textTheme.bodyMedium?.color,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
