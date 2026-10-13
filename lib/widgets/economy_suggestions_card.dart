import 'package:flutter/material.dart';
import '../../core/utils/economy_calculator.dart';

class EconomySuggestionsCard extends StatelessWidget {
  final List<EconomyModality> modalities;
  final String? selectedMode;
  final ValueChanged<String>? onSelectMode;
  final bool hasDeadline;

  const EconomySuggestionsCard({
    super.key,
    required this.modalities,
    this.selectedMode,
    this.onSelectMode,
    this.hasDeadline = true,
  });

  @override
  Widget build(BuildContext context) {
    final isFreeSelected = selectedMode == 'free' || !hasDeadline;

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
            hasDeadline
                ? 'Calculamos quanto guardar até seu prazo:'
                : 'Meta sem prazo: você guarda no seu próprio ritmo!',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        const SizedBox(height: 14),
        ...modalities.asMap().entries.map(
          (entry) {
            final modality = entry.value;
            final isSelected = hasDeadline && selectedMode == modality.iconAsset;

            return _ModalityTile(
              modality: modality,
              index: entry.key,
              isSelected: isSelected,
              isDisabled: !hasDeadline,
              onTap: (hasDeadline && onSelectMode != null)
                  ? () => onSelectMode!(modality.iconAsset)
                  : null,
            );
          },
        ),
        // 4º Card do Protótipo: "🌱 No meu ritmo" (Decisão 1.1)
        _FreeRhythmTile(
          isSelected: isFreeSelected,
          onTap: onSelectMode != null ? () => onSelectMode!('free') : null,
        ),
      ],
    );
  }
}

class _ModalityTile extends StatelessWidget {
  final EconomyModality modality;
  final int index;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback? onTap;

  const _ModalityTile({
    required this.modality,
    required this.index,
    this.isSelected = false,
    this.isDisabled = false,
    this.onTap,
  });

  static const _emojis = ['☀️', '📅', '🗓️'];

  static const _colors = [
    Color(0xFF2E7D32), // Emerald / Primária Oinc
    Color(0xFF0288D1), // Azul
    Color(0xFF7B1FA2), // Roxo
  ];

  @override
  Widget build(BuildContext context) {
    final color = _colors[index % _colors.length];
    final emoji = _emojis[index % _emojis.length];
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Opacity(
      opacity: isDisabled ? 0.45 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF132E1C) : const Color(0xFFE8F5E9))
              : (isDark ? const Color(0xFF243B2A) : const Color(0xFFEEF3EE)),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? const Color(0xFF2E7D32) : Colors.transparent,
            width: 2.0,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isDisabled ? null : onTap,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Text(emoji, style: const TextStyle(fontSize: 22)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              modality.title,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.check_circle_rounded,
                                color: Color(0xFF2E7D32),
                                size: 17,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          modality.description,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        isDisabled ? 'Defina um prazo' : modality.formattedAmount,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: isDark ? const Color(0xFF00C853) : const Color(0xFF2E7D32),
                          fontWeight: FontWeight.w800,
                          fontSize: isDisabled ? 12 : 15,
                        ),
                      ),
                      if (!isDisabled)
                        Text(
                          modality.period,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FreeRhythmTile extends StatelessWidget {
  final bool isSelected;
  final VoidCallback? onTap;

  const _FreeRhythmTile({
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isSelected
            ? (isDark ? const Color(0xFF132E1C) : const Color(0xFFE8F5E9))
            : (isDark ? const Color(0xFF243B2A) : const Color(0xFFEEF3EE)),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSelected ? const Color(0xFF2E7D32) : Colors.transparent,
          width: 2.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: const Text('🌱', style: TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'No meu ritmo',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF2E7D32),
                              size: 17,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Deposite quanto e quando quiser, sem pressão',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Livre',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: isDark ? const Color(0xFF00C853) : const Color(0xFF2E7D32),
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
