import 'package:hive/hive.dart';

part 'goal_model.g.dart';

@HiveType(typeId: 0)
class GoalModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  double targetAmount;

  @HiveField(3)
  DateTime deadline;

  @HiveField(4)
  double savedAmount;

  @HiveField(5)
  int iconCodePoint; // IconData.codePoint

  @HiveField(6)
  int colorValue; // Color.value

  @HiveField(7)
  bool isArchived;

  @HiveField(8)
  DateTime createdAt;

  @HiveField(9)
  String? reminderTime; // "08:00" ou null

  @HiveField(10)
  String? note; // descrição opcional da meta

  GoalModel({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.deadline,
    this.savedAmount = 0.0,
    required this.iconCodePoint,
    required this.colorValue,
    this.isArchived = false,
    required this.createdAt,
    this.reminderTime,
    this.note,
  });

  /// Progresso de 0.0 a 1.0
  double get progress =>
      targetAmount > 0 ? (savedAmount / targetAmount).clamp(0.0, 1.0) : 0.0;

  /// Progresso em porcentagem de 0 a 100
  double get progressPercent => progress * 100;

  /// Valor ainda necessário para atingir a meta
  double get remainingAmount =>
      (targetAmount - savedAmount).clamp(0.0, double.infinity);

  /// Dias restantes até o prazo
  int get daysRemaining =>
      deadline.difference(DateTime.now()).inDays.clamp(0, 99999);

  /// Meta foi atingida
  bool get isCompleted => savedAmount >= targetAmount;

  /// 4 marcos automáticos de progresso (25%, 50%, 75%, 100%)
  List<double> get milestoneAmounts => [
        targetAmount * 0.25,
        targetAmount * 0.50,
        targetAmount * 0.75,
        targetAmount * 1.00,
      ];

  /// Quantos marcos já foram conquistados (0 a 4)
  int get completedMilestonesCount {
    if (targetAmount <= 0) return 0;
    int count = 0;
    for (final milestone in milestoneAmounts) {
      if (savedAmount >= milestone) count++;
    }
    return count;
  }

  /// Cria uma cópia com campos alterados
  GoalModel copyWith({
    String? id,
    String? name,
    double? targetAmount,
    DateTime? deadline,
    double? savedAmount,
    int? iconCodePoint,
    int? colorValue,
    bool? isArchived,
    DateTime? createdAt,
    String? reminderTime,
    String? note,
  }) {
    return GoalModel(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      deadline: deadline ?? this.deadline,
      savedAmount: savedAmount ?? this.savedAmount,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      colorValue: colorValue ?? this.colorValue,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      reminderTime: reminderTime,
      note: note ?? this.note,
    );
  }
}
