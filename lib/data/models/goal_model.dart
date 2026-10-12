import 'package:hive/hive.dart';

part 'goal_model.g.dart';

// Guarda os dados de uma meta financeira no aplicativo
@HiveType(typeId: 0)
class GoalModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  double targetAmount;

  // Data limite para alcançar a meta (opcional no ritmo livre)
  @HiveField(3)
  DateTime? deadline;

  @HiveField(4)
  double savedAmount;

  @HiveField(5)
  int iconCodePoint;

  @HiveField(6)
  int colorValue;

  @HiveField(7)
  bool isArchived;

  @HiveField(8)
  DateTime createdAt;

  @HiveField(9)
  String? reminderTime;

  @HiveField(10)
  String? note;

  // Ritmo escolhido: 'free' (livre), 'daily', 'weekly' ou 'monthly'
  @HiveField(11)
  String? rhythm;

  GoalModel({
    required this.id,
    required this.name,
    required this.targetAmount,
    this.deadline,
    this.savedAmount = 0.0,
    required this.iconCodePoint,
    required this.colorValue,
    this.isArchived = false,
    required this.createdAt,
    this.reminderTime,
    this.note,
    this.rhythm,
  });

  // Calcula o progresso de 0.0 a 1.0 para barras de carregamento
  double get progress =>
      targetAmount > 0 ? (savedAmount / targetAmount).clamp(0.0, 1.0) : 0.0;

  // Devolve o progresso em porcentagem de 0 a 100
  double get progressPercent => progress * 100;

  // Valor que ainda falta guardar para completar a meta
  double get remainingAmount =>
      (targetAmount - savedAmount).clamp(0.0, double.infinity);

  // Quantidade de dias restantes até o prazo (ou null se for meta sem prazo)
  int? get daysRemaining =>
      deadline?.difference(DateTime.now()).inDays.clamp(0, 99999);

  // Confere se o valor guardado atingiu ou passou o valor alvo
  bool get isCompleted => savedAmount >= targetAmount;

  // Valores dos 4 marcos da jornada (25%, 50%, 75% e 100%)
  List<double> get milestoneAmounts => [
        targetAmount * 0.25,
        targetAmount * 0.50,
        targetAmount * 0.75,
        targetAmount * 1.00,
      ];

  // Quantos marcos o usuário já conquistou nesta meta
  int get completedMilestonesCount {
    if (targetAmount <= 0) return 0;
    int count = 0;
    for (final milestone in milestoneAmounts) {
      if (savedAmount >= milestone) count++;
    }
    return count;
  }

  // Gera uma cópia da meta alterando apenas os dados fornecidos
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
    String? rhythm,
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
      reminderTime: reminderTime ?? this.reminderTime,
      note: note ?? this.note,
      rhythm: rhythm ?? this.rhythm,
    );
  }
}
