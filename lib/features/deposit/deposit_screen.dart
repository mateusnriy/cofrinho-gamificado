import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/utils/formatters.dart';
import '../../data/models/deposit_model.dart';
import '../../data/models/goal_model.dart';
import '../../core/providers/global_providers.dart';
import '../../widgets/celebration_overlay.dart';

class DepositScreen extends ConsumerStatefulWidget {
  final GoalModel goal;
  final VoidCallback? onDepositSaved;

  const DepositScreen({
    super.key,
    required this.goal,
    this.onDepositSaved,
  });

  @override
  ConsumerState<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends ConsumerState<DepositScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  bool _isLoading = false;

  // UX-DR3: Chips de valores rápidos
  static const _quickValues = [10.0, 25.0, 50.0, 100.0, 200.0];

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  double? get _parsedAmount {
    final text = _amountController.text
        .replaceAll('R\$', '')
        .replaceAll(' ', '')
        .replaceAll('.', '')
        .replaceAll(',', '.');
    return double.tryParse(text);
  }

  bool get _isAmountValid {
    final amount = _parsedAmount;
    if (amount == null || amount <= 0) return false;
    if (amount > widget.goal.remainingAmount) return false;
    return true;
  }

  String? get _validationError {
    final text = _amountController.text.trim();
    if (text.isEmpty) return null;

    final amount = _parsedAmount;
    if (amount == null || amount <= 0) {
      return 'Informe um valor maior que zero';
    }
    if (amount > widget.goal.remainingAmount) {
      return 'O valor não pode ultrapassar o saldo restante (${AppFormatters.currency(widget.goal.remainingAmount)})';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final goal = widget.goal;
    final goalColor = Color(goal.colorValue);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final maxAvailableHeight = MediaQuery.of(context).size.height * 0.85;
    final amount = _parsedAmount;
    final errorMessage = _validationError;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxAvailableHeight),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: goalColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        IconData(goal.iconCodePoint,
                            fontFamily: 'MaterialIcons'),
                        color: goalColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Registrar Depósito',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          Text(
                            goal.name,
                            style: Theme.of(context).textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _MiniProgressBar(goal: goal, goalColor: goalColor),
                const SizedBox(height: 20),
                Text(
                  'Valor depositado *',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _amountController,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: false,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                  ],
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                  decoration: InputDecoration(
                    hintText: '0,00',
                    prefixText: 'R\$ ',
                    prefixStyle: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: goalColor,
                    ),
                    suffixIcon: _amountController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _amountController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: goalColor, width: 2),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),

                // UX-DR3: Chips de valores rápidos (+R$ 10 a +R$ 200)
                SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    children: _quickValues.map((value) {
                      final isWithinBudget =
                          value <= widget.goal.remainingAmount;

                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          label: Text('+R\$ ${value.toStringAsFixed(0)}'),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            _amountController.text =
                                value.toStringAsFixed(2).replaceAll('.', ',');
                            setState(() {});
                          },
                          backgroundColor: isWithinBudget
                              ? goalColor.withValues(alpha: 0.1)
                              : Colors.grey.withValues(alpha: 0.1),
                          labelStyle: TextStyle(
                            color: isWithinBudget
                                ? goalColor
                                : Theme.of(context).disabledColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                          side: BorderSide(
                            color: isWithinBudget
                                ? goalColor.withValues(alpha: 0.3)
                                : Colors.transparent,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                // UX-DR3: Contador de Oinc Coins em tempo real
                if (_isAmountValid && amount != null && amount > 0) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🪙', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Text(
                          '+${amount.floor()} Oinc Coins serão adicionadas!',
                          style: const TextStyle(
                            color: Color(0xFF92400E),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            color: Color(0xFFEF4444), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            errorMessage,
                            style: const TextStyle(
                              color: Color(0xFFB91C1C),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                Text(
                  'Observação (opcional)',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _noteController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Ex: Economia do cafezinho, bônus...',
                    prefixIcon: Icon(Icons.notes_rounded),
                  ),
                ),

                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: (_isLoading || !_isAmountValid) ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: goalColor,
                    disabledBackgroundColor:
                        goalColor.withValues(alpha: 0.35),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Confirmar Depósito',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    final amount = _parsedAmount;
    if (amount == null || !_isAmountValid) return;

    HapticFeedback.mediumImpact();

    setState(() {
      _isLoading = true;
    });

    final useCase = ref.read(registerDepositUseCaseProvider);
    final result = await useCase.execute(
      goalId: widget.goal.id,
      amount: amount,
      note: _noteController.text,
    );

    setState(() => _isLoading = false);

    if (result != null && mounted) {
      if (result.newMilestoneReached ||
          result.isGoalCompleted ||
          result.newBadges.isNotEmpty) {
        HapticFeedback.heavyImpact();
      } else {
        HapticFeedback.mediumImpact();
      }

      final rootNav = Navigator.of(context);
      rootNav.pop();
      widget.onDepositSaved?.call();

      if (rootNav.context.mounted) {
        if (result.isGoalCompleted) {
          CelebrationOverlay.showGoalCompleted(
            rootNav.context,
            goalName: widget.goal.name,
          );
        } else if (result.newBadges.isNotEmpty) {
          CelebrationOverlay.showBadgeUnlocked(
            rootNav.context,
            badgeTitle: result.newBadges.first.title,
          );
        } else if (result.newMilestoneReached) {
          CelebrationOverlay.showMilestoneReached(
            rootNav.context,
            goalName: widget.goal.name,
            milestonePercent: result.milestonesAfter * 25,
          );
        }
      }

      final milestoneMessage = result.newMilestoneReached
          ? ' 🎯 Novo marco de ${result.milestonesAfter * 25}% atingido!'
          : '';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Depósito de ${AppFormatters.currency(amount)} registrado! 🪙 +${result.coinsEarned} Oinc Coins!$milestoneMessage',
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }
}

class _MiniProgressBar extends StatelessWidget {
  final GoalModel goal;
  final Color goalColor;

  const _MiniProgressBar({required this.goal, required this.goalColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppFormatters.currency(goal.savedAmount),
              style: TextStyle(
                color: goalColor,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            Text(
              '${AppFormatters.percent(goal.progressPercent)} de ${AppFormatters.currency(goal.targetAmount)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: goal.progress,
            minHeight: 8,
            backgroundColor: goalColor.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation<Color>(goalColor),
          ),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            'Faltam ${AppFormatters.currency(goal.remainingAmount)}',
            style:
                Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12),
          ),
        ),
      ],
    );
  }
}
