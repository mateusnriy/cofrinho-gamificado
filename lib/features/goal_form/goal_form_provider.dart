import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/goal_model.dart';
import '../../core/providers/global_providers.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/notification_service.dart';
import '../../data/repositories/goal_repository.dart';

class GoalFormState {
  final int currentStep; // 0 = Passo 1 (Identidade e Valor), 1 = Passo 2 (Ritmo de Economia)
  final String name;
  final String amountText;
  final DateTime? deadline;
  final int iconCodePoint;
  final int colorValue;
  final String? selectedEconomyMode; // 'daily', 'weekly', 'monthly'
  final String? note;
  final String? reminderTime;
  final bool isLoading;
  final String? errorMessage;

  const GoalFormState({
    this.currentStep = 0,
    this.name = '',
    this.amountText = '',
    this.deadline,
    int? iconCodePoint,
    int? colorValue,
    this.selectedEconomyMode,
    this.note,
    this.reminderTime,
    this.isLoading = false,
    this.errorMessage,
  })  : iconCodePoint = iconCodePoint ?? 0xe7e8,
        colorValue = colorValue ?? 0xFF10B981;

  GoalFormState copyWith({
    int? currentStep,
    String? name,
    String? amountText,
    DateTime? deadline,
    int? iconCodePoint,
    int? colorValue,
    String? selectedEconomyMode,
    String? note,
    String? reminderTime,
    bool clearReminder = false,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return GoalFormState(
      currentStep: currentStep ?? this.currentStep,
      name: name ?? this.name,
      amountText: amountText ?? this.amountText,
      deadline: deadline ?? this.deadline,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      colorValue: colorValue ?? this.colorValue,
      selectedEconomyMode: selectedEconomyMode ?? this.selectedEconomyMode,
      note: note ?? this.note,
      reminderTime: clearReminder ? null : (reminderTime ?? this.reminderTime),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  double? get parsedAmount {
    final cleaned = amountText
        .replaceAll('R\$', '')
        .replaceAll(' ', '')
        .replaceAll('.', '')
        .replaceAll(',', '.');
    return double.tryParse(cleaned);
  }

  /// Validação estrita do Passo 1 (Identidade e Valor)
  String? validateStep1({GoalModel? existingGoal}) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return 'Informe o nome da meta';
    }
    if (trimmedName.length > 40) {
      return 'O nome deve ter no máximo 40 caracteres';
    }

    final amount = parsedAmount;
    if (amount == null || amount <= 0) {
      return 'Informe um valor maior que zero';
    }

    if (existingGoal != null && amount < existingGoal.savedAmount) {
      return 'O novo valor não pode ser menor que o valor já economizado (${AppFormatters.currency(existingGoal.savedAmount)})';
    }

    // Se o usuário preencheu uma data limite, confere se é uma data futura
    if (deadline != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final selectedDate =
          DateTime(deadline!.year, deadline!.month, deadline!.day);

      if (!selectedDate.isAfter(today)) {
        return 'O prazo deve ser uma data futura';
      }
    }

    return null;
  }

  // Validação antes de salvar a meta
  String? validate({GoalModel? existingGoal}) {
    final step1Error = validateStep1(existingGoal: existingGoal);
    if (step1Error != null) return step1Error;

    // Se tiver prazo definido, exige escolha do ritmo se ainda não escolheu
    if (deadline != null && selectedEconomyMode == null) {
      return 'Selecione um ritmo de economia para continuar';
    }

    return null;
  }
}

class GoalFormNotifier extends StateNotifier<GoalFormState> {
  final GoalRepository _repo;

  GoalFormNotifier(this._repo) : super(const GoalFormState());

  void loadFromExisting(GoalModel goal) {
    state = GoalFormState(
      currentStep: 0,
      name: goal.name,
      amountText: goal.targetAmount.toStringAsFixed(2).replaceAll('.', ','),
      deadline: goal.deadline,
      iconCodePoint: goal.iconCodePoint,
      colorValue: goal.colorValue,
      selectedEconomyMode: 'weekly', // Padrão inteligente na edição
      note: goal.note,
      reminderTime: goal.reminderTime,
    );
  }

  void setName(String value) =>
      state = state.copyWith(name: value, clearError: true);
  void setAmount(String value) =>
      state = state.copyWith(amountText: value, clearError: true);
  // Define a data limite escolhida
  void setDeadline(DateTime value) =>
      state = state.copyWith(deadline: value, clearError: true);

  // Remove a data limite para deixar a meta no ritmo livre
  void setDeadlineNull() {
    state = GoalFormState(
      currentStep: state.currentStep,
      name: state.name,
      amountText: state.amountText,
      deadline: null,
      iconCodePoint: state.iconCodePoint,
      colorValue: state.colorValue,
      selectedEconomyMode: 'free',
      note: state.note,
      reminderTime: state.reminderTime,
      isLoading: state.isLoading,
      errorMessage: null,
    );
  }
  void setIcon(int codePoint) =>
      state = state.copyWith(iconCodePoint: codePoint);
  void setColor(int colorValue) =>
      state = state.copyWith(colorValue: colorValue);
  void setEconomyMode(String mode) {
    HapticFeedback.lightImpact();
    state = state.copyWith(selectedEconomyMode: mode, clearError: true);
  }
  void setNote(String? value) => state = state.copyWith(note: value);
  void setReminder(String? value) =>
      state = state.copyWith(reminderTime: value, clearReminder: value == null);

  bool nextStep({GoalModel? existingGoal}) {
    final error = state.validateStep1(existingGoal: existingGoal);
    if (error != null) {
      HapticFeedback.vibrate();
      state = state.copyWith(errorMessage: error);
      return false;
    }

    HapticFeedback.lightImpact();
    state = state.copyWith(currentStep: 1, clearError: true);
    return true;
  }

  void previousStep() {
    HapticFeedback.lightImpact();
    state = state.copyWith(currentStep: 0, clearError: true);
  }

  void goToStep(int step) {
    HapticFeedback.lightImpact();
    state = state.copyWith(currentStep: step, clearError: true);
  }

  Future<bool> save({String? existingId}) async {
    final existingGoal = existingId != null ? _repo.getById(existingId) : null;
    final error = state.validate(existingGoal: existingGoal);
    if (error != null) {
      HapticFeedback.vibrate();
      state = state.copyWith(errorMessage: error);
      return false;
    }

    state = state.copyWith(isLoading: true);

    final goal = GoalModel(
      id: existingId ?? const Uuid().v4(),
      name: state.name.trim(),
      targetAmount: state.parsedAmount!,
      deadline: state.deadline,
      iconCodePoint: state.iconCodePoint,
      colorValue: state.colorValue,
      note: state.note?.trim().isEmpty == true ? null : state.note?.trim(),
      reminderTime: state.reminderTime,
      createdAt: existingGoal?.createdAt ?? DateTime.now(),
      savedAmount: existingGoal?.savedAmount ?? 0.0,
      isArchived: existingGoal?.isArchived ?? false,
      rhythm: state.selectedEconomyMode ?? 'free',
    );

    await _repo.save(goal);

    // Gerencia agendamento defensivo de notificações locais (AD-5)
    try {
      if (existingGoal?.reminderTime != null &&
          existingGoal?.reminderTime != goal.reminderTime) {
        await NotificationService().cancelGoalReminder(goal.id.hashCode);
      }

      if (goal.reminderTime != null && !goal.isCompleted && !goal.isArchived) {
        await NotificationService().scheduleGoalReminder(
          notificationId: goal.id.hashCode,
          goalName: goal.name,
          timeStr: goal.reminderTime!,
        );
      }
    } catch (_) {
      // Isolamento defensivo: falha no serviço nativo não compromete persistência
    }

    if (mounted) {
      state = state.copyWith(isLoading: false);
    }
    return true;
  }
}

final goalFormProvider =
    StateNotifierProvider.autoDispose<GoalFormNotifier, GoalFormState>((ref) {
  final repo = ref.watch(goalRepositoryProvider);
  return GoalFormNotifier(repo);
});
