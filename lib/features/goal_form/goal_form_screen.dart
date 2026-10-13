import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/global_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/economy_calculator.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/goal_model.dart';
import '../../data/models/mascot_model.dart';
import '../../widgets/celebration_overlay.dart';
import '../../widgets/economy_suggestions_card.dart';
import '../../widgets/porko_canvas_widget.dart';
import '../deposit/deposit_screen.dart';
import 'goal_form_provider.dart';

class GoalFormScreen extends ConsumerStatefulWidget {
  final GoalModel? existingGoal;

  const GoalFormScreen({super.key, this.existingGoal});

  @override
  ConsumerState<GoalFormScreen> createState() => _GoalFormScreenState();
}

class _GoalFormScreenState extends ConsumerState<GoalFormScreen> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  bool _created = false;
  GoalModel? _savedGoal;

  @override
  void initState() {
    super.initState();
    if (widget.existingGoal != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final notifier = ref.read(goalFormProvider.notifier);
        notifier.loadFromExisting(widget.existingGoal!);
        _nameController.text = widget.existingGoal!.name;
        _amountController.text = widget.existingGoal!.targetAmount
            .toStringAsFixed(2)
            .replaceAll('.', ',');
        _noteController.text = widget.existingGoal!.note ?? '';
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(goalFormProvider);
    final isEditing = widget.existingGoal != null;
    final activeStepIndex = _created ? 2 : formState.currentStep;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _created
              ? 'Tudo pronto!'
              : (isEditing ? 'Editar Meta' : 'Nova Meta'),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (!_created && formState.currentStep == 1) {
              ref.read(goalFormProvider.notifier).previousStep();
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                // Indicador visual de progresso de 3 passos (#dots do protótipo + títulos)
                _buildStepHeader(context, activeStepIndex),

                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.05, 0),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: _created
                          ? _buildStep3(context, _savedGoal)
                          : (formState.currentStep == 0
                              ? _buildStep1(context, formState, isEditing)
                              : _buildStep2(context, formState, isEditing)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepHeader(BuildContext context, int activeStepIndex) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF2F4A37) : const Color(0xFFE2E8E2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // 3 Pílulas Animadas (#dots do protótipo)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              final isCurrent = index == activeStepIndex;
              final isDone = index < activeStepIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isCurrent ? 26 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: (isCurrent || isDone)
                      ? const Color(0xFF2E7D32)
                      : (isDark
                          ? const Color(0xFF2F4A37)
                          : const Color(0xFFD5DDD5)),
                  borderRadius: BorderRadius.circular(99),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildStepItem(
                stepNumber: '1',
                title: 'Identidade e Valor',
                isActive: activeStepIndex == 0,
                isCompleted: activeStepIndex > 0,
                theme: theme,
              ),
              Expanded(
                child: Container(
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  color: activeStepIndex > 0
                      ? theme.colorScheme.primary
                      : (isDark
                          ? const Color(0xFF2F4A37)
                          : const Color(0xFFCBD5E1)),
                ),
              ),
              _buildStepItem(
                stepNumber: '2',
                title: 'Ritmo de Economia',
                isActive: activeStepIndex == 1,
                isCompleted: activeStepIndex > 1,
                theme: theme,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem({
    required String stepNumber,
    required String title,
    required bool isActive,
    required bool isCompleted,
    required ThemeData theme,
  }) {
    final primaryColor = theme.colorScheme.primary;

    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (isActive || isCompleted)
                ? primaryColor
                : theme.disabledColor.withValues(alpha: 0.15),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                : Text(
                    stepNumber,
                    style: TextStyle(
                      color: isActive ? Colors.white : theme.disabledColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive
                ? theme.textTheme.bodyLarge?.color
                : theme.disabledColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStep1(
    BuildContext context,
    GoalFormState formState,
    bool isEditing,
  ) {
    return Column(
      key: const ValueKey('step_1'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(context, 'Nome da meta *'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _nameController,
          maxLength: 40,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'Ex: Viagem para a praia',
            prefixIcon: Icon(Icons.edit_rounded),
          ),
          onChanged: (v) => ref.read(goalFormProvider.notifier).setName(v),
        ),
        const SizedBox(height: 12),
        _buildLabel(context, 'Valor alvo da meta *'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
            signed: false,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
          ],
          decoration: const InputDecoration(
            hintText: '1500,00',
            prefixText: 'R\$ ',
            prefixIcon: Icon(Icons.attach_money_rounded),
          ),
          onChanged: (v) => ref.read(goalFormProvider.notifier).setAmount(v),
        ),
        const SizedBox(height: 16),
        _buildLabel(context, 'Data limite (Prazo) (opcional)'),
        const SizedBox(height: 8),
        _DeadlinePicker(
          selected: formState.deadline,
          onChanged: (date) {
            if (date != null) {
              ref.read(goalFormProvider.notifier).setDeadline(date);
            } else {
              ref.read(goalFormProvider.notifier).setDeadlineNull();
            }
          },
        ),
        const SizedBox(height: 18),
        _IconColorPicker(formState: formState),
        if (formState.errorMessage != null) ...[
          const SizedBox(height: 20),
          _buildErrorBanner(formState.errorMessage!),
        ],
        const SizedBox(height: 28),
        ElevatedButton(
          onPressed: () {
            FocusScope.of(context).unfocus();
            ref
                .read(goalFormProvider.notifier)
                .nextStep(existingGoal: widget.existingGoal);
          },
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Continuar para o Ritmo'),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward_rounded, size: 20),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildStep2(
    BuildContext context,
    GoalFormState formState,
    bool isEditing,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasDeadline = formState.deadline != null;
    final modalities = EconomyCalculator.calculate(
      targetAmount: formState.parsedAmount ?? 0,
      savedAmount: widget.existingGoal?.savedAmount ?? 0,
      deadline:
          formState.deadline ?? DateTime.now().add(const Duration(days: 30)),
    );

    return Column(
      key: const ValueKey('step_2'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Resumo do Passo 1
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1B2E22) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? const Color(0xFF2F4A37) : const Color(0xFFE2E8E2),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Color(formState.colorValue).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  IconData(formState.iconCodePoint, fontFamily: 'MaterialIcons'),
                  color: Color(formState.colorValue),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formState.name,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Alvo: ${AppFormatters.currency(formState.parsedAmount ?? 0)} • ${hasDeadline ? 'Prazo: ${AppFormatters.date(formState.deadline!)}' : 'Sem prazo'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: () =>
                    ref.read(goalFormProvider.notifier).previousStep(),
                tooltip: 'Editar dados',
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Sugestões de Ritmo (4 opções empilhadas com trava automática quando Sem Prazo)
        EconomySuggestionsCard(
          modalities: modalities,
          selectedMode: formState.selectedEconomyMode,
          hasDeadline: hasDeadline,
          onSelectMode: (mode) =>
              ref.read(goalFormProvider.notifier).setEconomyMode(mode),
        ),
        const SizedBox(height: 20),

        _buildLabel(context, 'Lembrete diário (opcional)'),
        const SizedBox(height: 8),
        _ReminderPicker(
          selected: formState.reminderTime,
          onChanged: (time) =>
              ref.read(goalFormProvider.notifier).setReminder(time),
        ),
        const SizedBox(height: 18),

        _buildLabel(context, 'Observação / Motivação (opcional)'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _noteController,
          maxLines: 2,
          decoration: const InputDecoration(
            hintText: 'Ex: Juntando para realizar meu grande sonho...',
            prefixIcon: Icon(Icons.notes_rounded),
          ),
          onChanged: (v) => ref.read(goalFormProvider.notifier).setNote(v),
        ),

        if (formState.errorMessage != null) ...[
          const SizedBox(height: 20),
          _buildErrorBanner(formState.errorMessage!),
        ],

        const SizedBox(height: 28),
        Row(
          children: [
            OutlinedButton(
              onPressed: () =>
                  ref.read(goalFormProvider.notifier).previousStep(),
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('← Voltar'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: (formState.isLoading ||
                        (hasDeadline && formState.selectedEconomyMode == null))
                    ? null
                    : _save,
                child: formState.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(isEditing ? 'Guardar alterações' : 'Salvar Meta 🎉'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFEF4444),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFFB91C1C),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(BuildContext context, String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
    );
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final repo = ref.read(goalRepositoryProvider);
    final success = await ref.read(goalFormProvider.notifier).save(
          existingId: widget.existingGoal?.id,
        );
    if (success && mounted) {
      if (widget.existingGoal != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Meta atualizada com sucesso!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop();
      } else {
        HapticFeedback.heavyImpact();
        final allGoals = repo.getActive();
        final created = allGoals.isNotEmpty ? allGoals.last : null;
        setState(() {
          _created = true;
          _savedGoal = created;
        });
        if (created != null) {
          CelebrationOverlay.show(context, created.name);
        }
      }
    }
  }

  // ── Passo 3: Celebração Soft 3D, Resumo e Primeiro Depósito ────────────────
  Widget _buildStep3(BuildContext context, GoalModel? goal) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mascotState = ref.watch(mascotRepositoryProvider).getMascot();

    return Column(
      key: const ValueKey('step_3'),
      children: [
        const SizedBox(height: 12),
        // Mascote Porko Soft 3D Celebrando (substituindo emoji 2D — AUD-11)
        PorkoCanvasWidget(
          mascot: mascotState,
          mood: PorkoMood.celebrating,
          activeReaction: 'jump',
        ),
        const SizedBox(height: 16),
        const Text(
          'Meta criada! 🎉',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'O Porko já está torcendo por você. Que tal a primeira moedinha?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 13,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
        const SizedBox(height: 20),
        if (goal != null)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF243B2A) : const Color(0xFFEEF3EE),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Color(goal.colorValue).withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Color(goal.colorValue).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    IconData(goal.iconCodePoint, fontFamily: 'MaterialIcons'),
                    color: Color(goal.colorValue),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.name,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Alvo: ${AppFormatters.currency(goal.targetAmount)}',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              if (goal != null) {
                final rootContext = Navigator.of(context).context;
                Navigator.of(context).pop();
                showModalBottomSheet(
                  context: rootContext,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => DepositScreen(goal: goal),
                );
              } else {
                Navigator.of(context).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              '🪙 Fazer o 1º depósito',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Ver minhas metas',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _IconColorPicker extends ConsumerWidget {
  final GoalFormState formState;

  const _IconColorPicker({required this.formState});

  // Os 8 ícones principais do protótipo (🏖️ 🎮 📱 🚗 🏠 🎓 🎸 ✨) mapeados para MaterialIcons + emoji visual
  static final List<({String emoji, IconData icon})> _prototypeIcons = [
    (emoji: '🏖️', icon: Icons.beach_access_rounded),
    (emoji: '🎮', icon: Icons.sports_esports_rounded),
    (emoji: '📱', icon: Icons.phone_iphone_rounded),
    (emoji: '🚗', icon: Icons.directions_car_rounded),
    (emoji: '🏠', icon: Icons.home_rounded),
    (emoji: '🎓', icon: Icons.school_rounded),
    (emoji: '🎸', icon: Icons.music_note_rounded),
    (emoji: '✨', icon: Icons.savings_rounded),
  ];

  // As 6 cores canônicas do protótipo (.sw) + cores extras do tema
  static const List<Color> _prototypeColors = [
    Color(0xFF2E7D32),
    Color(0xFF0288D1),
    Color(0xFF7B1FA2),
    Color(0xFFF57C00),
    Color(0xFFD81B60),
    Color(0xFF00897B),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedColor = Color(formState.colorValue);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Ícone',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
            ),
            TextButton.icon(
              onPressed: () => _showIconPicker(context, ref),
              icon: Icon(
                IconData(formState.iconCodePoint, fontFamily: 'MaterialIcons'),
                size: 16,
                color: selectedColor,
              ),
              label: const Text(
                'Mais ícones',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Grade 4x2 visível diretamente no Passo 1 (.igrid do protótipo — AUD-11)
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _prototypeIcons.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.35,
          ),
          itemBuilder: (context, index) {
            final item = _prototypeIcons[index];
            final isSelected = item.icon.codePoint == formState.iconCodePoint;
            return InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                ref.read(goalFormProvider.notifier).setIcon(item.icon.codePoint);
              },
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark
                          ? const Color(0xFF132E1C)
                          : const Color(0xFFE8F5E9))
                      : (isDark
                          ? const Color(0xFF243B2A)
                          : const Color(0xFFEEF3EE)),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF2E7D32)
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  item.emoji,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        Text(
          'Cor',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _prototypeColors.map((color) {
            final isSelected = color.toARGB32() == formState.colorValue;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                ref.read(goalFormProvider.notifier).setColor(color.toARGB32());
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.transparent,
                    width: 3,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 16,
                      )
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _showIconPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Escolha um ícone',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 60,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemCount: AppTheme.goalIcons.length,
              itemBuilder: (_, index) {
                final icon = AppTheme.goalIcons[index];
                final isSelected = icon.codePoint == formState.iconCodePoint;
                return GestureDetector(
                  onTap: () {
                    ref.read(goalFormProvider.notifier).setIcon(icon.codePoint);
                    Navigator.pop(context);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Color(formState.colorValue).withValues(alpha: 0.15)
                          : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected
                          ? Border.all(
                              color: Color(formState.colorValue),
                              width: 2,
                            )
                          : null,
                    ),
                    child: Icon(
                      icon,
                      color: isSelected
                          ? Color(formState.colorValue)
                          : Theme.of(context).disabledColor,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _DeadlinePicker extends StatelessWidget {
  final DateTime? selected;
  final ValueChanged<DateTime?> onChanged;

  const _DeadlinePicker({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasNoDate = selected == null;

    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () async {
              final tomorrow = DateTime.now().add(const Duration(days: 1));
              final picked = await showDatePicker(
                context: context,
                initialDate: (selected != null && selected!.isAfter(tomorrow))
                    ? selected!
                    : tomorrow.add(const Duration(days: 30)),
                firstDate: tomorrow,
                lastDate: DateTime.now().add(const Duration(days: 3650)),
                locale: const Locale('pt', 'BR'),
              );
              if (picked != null) onChanged(picked);
            },
            borderRadius: BorderRadius.circular(14),
            child: Opacity(
              opacity: hasNoDate ? 0.55 : 1.0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: Theme.of(context).inputDecorationTheme.fillColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected != null
                        ? const Color(0xFF2E7D32)
                        : (isDark
                            ? const Color(0xFF2F4A37)
                            : const Color(0xFFE2E8E2)),
                    width: selected != null ? 2 : 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      color: selected != null
                          ? const Color(0xFF2E7D32)
                          : Theme.of(context).disabledColor,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        selected != null
                            ? AppFormatters.date(selected!)
                            : 'Escolher data...',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          color: selected != null
                              ? Theme.of(context).textTheme.bodyLarge?.color
                              : Theme.of(context).disabledColor,
                          fontWeight: selected != null
                              ? FontWeight.w700
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Botão "Sem prazo" tracejado idêntico ao protótipo (#noDateBtn)
        InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            if (hasNoDate) {
              onChanged(DateTime.now().add(const Duration(days: 90)));
            } else {
              onChanged(null);
            }
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: hasNoDate
                  ? (isDark
                      ? const Color(0xFF132E1C)
                      : const Color(0xFFE8F5E9))
                  : (isDark
                      ? const Color(0xFF243B2A)
                      : const Color(0xFFEEF3EE)),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: hasNoDate
                    ? const Color(0xFF2E7D32)
                    : (isDark
                        ? const Color(0xFF2F4A37)
                        : const Color(0xFFCBD5E1)),
                width: 2,
              ),
            ),
            child: Text(
              'Sem prazo',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: hasNoDate
                    ? (isDark
                        ? const Color(0xFF00C853)
                        : const Color(0xFF2E7D32))
                    : Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReminderPicker extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onChanged;

  const _ReminderPicker({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
              );
              if (picked != null) {
                onChanged(
                  '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}',
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Theme.of(context).inputDecorationTheme.fillColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).disabledColor.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.notifications_rounded,
                    color: selected != null
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).disabledColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    selected != null
                        ? 'Diariamente às $selected'
                        : 'Sem lembrete',
                    style: TextStyle(
                      fontSize: 15,
                      color: selected != null
                          ? Theme.of(context).textTheme.bodyLarge?.color
                          : Theme.of(context).disabledColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (selected != null) ...[
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => onChanged(null),
            tooltip: 'Remover lembrete',
          ),
        ],
      ],
    );
  }
}
