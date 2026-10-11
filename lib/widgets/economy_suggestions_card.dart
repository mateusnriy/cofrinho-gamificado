import 'package:flutter/material.dart';
import '../../core/utils/economy_calculator.dart';

class EconomySuggestionsCard extends StatelessWidget {
  final List<EconomyModality> modalities;
  final String? selectedMode;
  final ValueChanged<String>? onSelectMode;

  const EconomySuggestionsCard({
    super.key,
    required this.modalities,
    this.selectedMode,
    this.onSelectMode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Escolha seu ritmo de economia *',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Selecione uma das opções abaixo para guiar seus depósitos:',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        const SizedBox(height: 14),
        ...modalities.asMap().entries.map(
          (entry) {
            final modality = entry.value;
            final isSelected = selectedMode == modality.iconAsset;

            return _ModalityTile(
              modality: modality,
              index: entry.key,
              isSelected: isSelected,
              onTap: onSelectMode != null
                  ? () => onSelectMode!(modality.iconAsset)
                  : null,
            );
          },
        ),
      ],
    );
  }
}

class _ModalityTile extends StatelessWidget {
  final EconomyModality modality;
  final int index;
  final bool isSelected;
  final VoidCallback? onTap;

  const _ModalityTile({
    required this.modality,
    required this.index,
    this.isSelected = false,
    this.onTap,
  });

  static const _icons = [
    Icons.wb_sunny_rounded, // Solzinho diário
    Icons.calendar_view_week_rounded, // Semanal
    Icons.savings_rounded, // Cofre mensal
  ];

  static const _colors = [
    Color(0xFF10B981), // Emerald
    Color(0xFF3B82F6), // Azul
    Color(0xFF8B5CF6), // Roxo
  ];

  @override
  Widget build(BuildContext context) {
    final color = _colors[index % _colors.length];
    final icon = _icons[index % _icons.length];
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected
            ? color.withValues(alpha: isDark ? 0.20 : 0.08)
            : theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? color : color.withValues(alpha: 0.20),
          width: isSelected ? 2.0 : 1.0,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            modality.title,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: 6),
                            Icon(Icons.check_circle_rounded,
                                color: color, size: 18),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        modality.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      modality.formattedAmount,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      modality.period,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
