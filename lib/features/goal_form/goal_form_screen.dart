import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/economy_calculator.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/goal_model.dart';
import '../../widgets/economy_suggestions_card.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Meta' : 'Nova Meta'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (formState.currentStep == 1) {
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
                // Indicador visual de progresso de 2 passos
                _buildStepHeader(context, formState.currentStep),

                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
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
                      child: formState.currentStep == 0
                          ? _buildStep1(context, formState, isEditing)
                          : _buildStep2(context, formState, isEditing),
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

  Widget _buildStepHeader(BuildContext context, int currentStep) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          _buildStepItem(
            stepNumber: '1',
            title: 'Identidade e Valor',
            isActive: currentStep == 0,
            isCompleted: currentStep > 0,
            theme: theme,
          ),
          Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              color: currentStep > 0
                  ? theme.colorScheme.primary
                  : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
            ),
          ),
          _buildStepItem(
            stepNumber: '2',
            title: 'Ritmo de Economia',
            isActive: currentStep == 1,
            isCompleted: false,
            theme: theme,
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
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (isActive || isCompleted)
                ? primaryColor
                : theme.disabledColor.withValues(alpha: 0.15),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                : Text(
                    stepNumber,
                    style: TextStyle(
                      color: isActive ? Colors.white : theme.disabledColor,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
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
      BuildContext context, GoalFormState formState, bool isEditing) {
    return Column(
      key: const ValueKey('step_1'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _IconColorPicker(formState: formState),
        const SizedBox(height: 24),
        _buildLabel(context, 'Nome da meta *'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _nameController,
          maxLength: 40,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'Ex: Viagem para Europa, Celular Novo...',
            prefixIcon: Icon(Icons.edit_rounded),
          ),
          onChanged: (v) => ref.read(goalFormProvider.notifier).setName(v),
        ),
        const SizedBox(height: 16),
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
            hintText: '0,00',
            prefixText: 'R\$ ',
            prefixIcon: Icon(Icons.attach_money_rounded),
          ),
          onChanged: (v) => ref.read(goalFormProvider.notifier).setAmount(v),
        ),
        const SizedBox(height: 20),
        _buildLabel(context, 'Data limite (Prazo) *'),
        const SizedBox(height: 8),
        _DeadlinePicker(
          selected: formState.deadline,
          onChanged: (date) {
            ref.read(goalFormProvider.notifier).setDeadline(date);
          },
        ),
        if (formState.errorMessage != null) ...[
          const SizedBox(height: 20),
          _buildErrorBanner(formState.errorMessage!),
        ],
        const SizedBox(height: 32),
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
      BuildContext context, GoalFormState formState, bool isEditing) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Color(formState.colorValue).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  IconData(formState.iconCodePoint, fontFamily: 'MaterialIcons'),
                  color: Color(formState.colorValue),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formState.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Alvo: ${AppFormatters.currency(formState.parsedAmount ?? 0)} • Prazo: ${formState.deadline != null ? AppFormatters.date(formState.deadline!) : ""}',
                      style: TextStyle(
                        fontSize: 13,
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
        const SizedBox(height: 24),

        // Sugestões de Ritmo com seleção obrigatória
        EconomySuggestionsCard(
          modalities: modalities,
          selectedMode: formState.selectedEconomyMode,
          onSelectMode: (mode) =>
              ref.read(goalFormProvider.notifier).setEconomyMode(mode),
        ),
        const SizedBox(height: 24),

        _buildLabel(context, 'Lembrete diário (opcional)'),
        const SizedBox(height: 8),
        _ReminderPicker(
          selected: formState.reminderTime,
          onChanged: (time) =>
              ref.read(goalFormProvider.notifier).setReminder(time),
        ),
        const SizedBox(height: 20),

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

        const SizedBox(height: 32),
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
              child: const Text('Voltar'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: (formState.isLoading ||
                        formState.selectedEconomyMode == null)
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
                    : Text(isEditing ? 'Guardar alterações' : 'Salvar Meta'),
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
          const Icon(Icons.error_outline_rounded,
              color: Color(0xFFEF4444), size: 20),
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
            fontWeight: FontWeight.w600,
          ),
    );
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final success = await ref.read(goalFormProvider.notifier).save(
          existingId: widget.existingGoal?.id,
        );
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.existingGoal != null
                ? 'Meta atualizada com sucesso!'
                : 'Meta criada com sucesso! 4 marcos gerados.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    }
  }
}

class _IconColorPicker extends ConsumerWidget {
  final GoalFormState formState;

  const _IconColorPicker({required this.formState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedColor = Color(formState.colorValue);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => _showIconPicker(context, ref),
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: selectedColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selectedColor.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    IconData(formState.iconCodePoint,
                        fontFamily: 'MaterialIcons'),
                    color: selectedColor,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ícone e cor',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Toque no ícone para trocar',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: AppTheme.goalColors.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, index) {
                final color = AppTheme.goalColors[index];
                final isSelected = color.toARGB32() == formState.colorValue;
                return GestureDetector(
                  onTap: () => ref
                      .read(goalFormProvider.notifier)
                      .setColor(color.toARGB32()),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(
                              color: Colors.white,
                              width: 2.5,
                            )
                          : null,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.5),
                                blurRadius: 8,
                                spreadRadius: 1,
                              )
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check_rounded,
                            color: Colors.white, size: 18)
                        : null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
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
            const Text('Escolha um ícone',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                    child: Icon(icon,
                        color: isSelected
                            ? Color(formState.colorValue)
                            : Theme.of(context).disabledColor),
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
  final ValueChanged<DateTime> onChanged;

  const _DeadlinePicker({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
          builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context)
                  .colorScheme
                  .copyWith(primary: Theme.of(context).colorScheme.primary),
            ),
            child: child!,
          ),
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).inputDecorationTheme.fillColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected != null
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).disabledColor.withValues(alpha: 0.2),
            width: selected != null ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              color: selected != null
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).disabledColor,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              selected != null
                  ? AppFormatters.date(selected!)
                  : 'Selecione uma data futura',
              style: TextStyle(
                fontSize: 16,
                color: selected != null
                    ? Theme.of(context).textTheme.bodyLarge?.color
                    : Theme.of(context).disabledColor,
              ),
            ),
            const Spacer(),
            if (selected != null)
              Text(
                AppFormatters.daysRemaining(selected!),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
      ),
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
                    color:
                        Theme.of(context).disabledColor.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.notifications_rounded,
                      color: selected != null
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).disabledColor,
                      size: 20),
                  const SizedBox(width: 12),
                  Text(
                    selected != null
                        ? 'Diariamente às $selected'
                        : 'Sem lembrete',
                    style: TextStyle(
                      fontSize: 16,
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
