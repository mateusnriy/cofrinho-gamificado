// Estados de humor do Porko
enum PorkoMood {
  sleeping,
  neutral,
  happy,
  celebrating,
}

// Guarda os dados e o estado visual e emocional do mascote Porko
class MascotModel {
  // Nome personalizado dado pelo usuário (ex: "Porko")
  final String name;

  // Itens cosméticos equipados
  final String skinId;
  final String? hatId;
  final String? clothId;
  final String? backdropId;

  // Humor e energia (valores de 0 a 100 com pisos de segurança)
  final double happiness;
  final double energy;

  // Controle de limites diários de cuidados/carinho
  final int dailyAffectionCount;
  final DateTime? lastAffectionDate;
  final DateTime? lastInteractedAt;

  const MascotModel({
    this.name = 'Porko',
    this.skinId = 'pink_classic',
    this.hatId,
    this.clothId,
    this.backdropId,
    this.happiness = 90.0,
    this.energy = 85.0,
    this.dailyAffectionCount = 0,
    this.lastAffectionDate,
    this.lastInteractedAt,
  });

  // Gera uma cópia do mascote atualizando apenas os campos alterados
  MascotModel copyWith({
    String? name,
    String? skinId,
    String? hatId,
    bool clearHat = false,
    String? clothId,
    bool clearCloth = false,
    String? backdropId,
    bool clearBackdrop = false,
    double? happiness,
    double? energy,
    int? dailyAffectionCount,
    DateTime? lastAffectionDate,
    DateTime? lastInteractedAt,
  }) {
    return MascotModel(
      name: name ?? this.name,
      skinId: skinId ?? this.skinId,
      hatId: clearHat ? null : (hatId ?? this.hatId),
      clothId: clearCloth ? null : (clothId ?? this.clothId),
      backdropId: clearBackdrop ? 'backdrop_default' : (backdropId ?? this.backdropId),
      happiness: (happiness ?? this.happiness).clamp(40.0, 100.0),
      energy: (energy ?? this.energy).clamp(40.0, 100.0),
      dailyAffectionCount: dailyAffectionCount ?? this.dailyAffectionCount,
      lastAffectionDate: lastAffectionDate ?? this.lastAffectionDate,
      lastInteractedAt: lastInteractedAt ?? this.lastInteractedAt,
    );
  }

  // Converte os dados do mascote em um mapa para salvar no Hive
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'skinId': skinId,
      'hatId': hatId,
      'clothId': clothId,
      'backdropId': backdropId,
      'happiness': happiness,
      'energy': energy,
      'dailyAffectionCount': dailyAffectionCount,
      'lastAffectionDate': lastAffectionDate?.toIso8601String(),
      'lastInteractedAt': lastInteractedAt?.toIso8601String(),
    };
  }

  // Carrega o mascote a partir de um mapa lido do banco local
  factory MascotModel.fromMap(Map<dynamic, dynamic>? map) {
    if (map == null) return const MascotModel();
    return MascotModel(
      name: (map['name'] as String?) ?? 'Porko',
      skinId: (map['skinId'] as String?) ?? 'pink_classic',
      hatId: map['hatId'] as String?,
      clothId: map['clothId'] as String?,
      backdropId: map['backdropId'] as String?,
      happiness: ((map['happiness'] as num?)?.toDouble() ?? 90.0).clamp(40.0, 100.0),
      energy: ((map['energy'] as num?)?.toDouble() ?? 85.0).clamp(40.0, 100.0),
      dailyAffectionCount: (map['dailyAffectionCount'] as int?) ?? 0,
      lastAffectionDate: map['lastAffectionDate'] != null
          ? DateTime.tryParse(map['lastAffectionDate'] as String)
          : null,
      lastInteractedAt: map['lastInteractedAt'] != null
          ? DateTime.tryParse(map['lastInteractedAt'] as String)
          : null,
    );
  }

  // Frases que o mascote fala de acordo com o momento e humor
  static const Map<PorkoMood, List<String>> speechPhrases = {
    PorkoMood.sleeping: [
      'Zzz... Que tal começar guardando uma moedinha?',
      'Dormindo um pouquinho... Me acorde com um novo objetivo! 💤',
      'Sonhando com um futuro cheio de economias...',
    ],
    PorkoMood.neutral: [
      'Um passinho de cada vez! Como vamos poupar hoje?',
      'Oinc! Cada centavo guardado faz diferença! 🌱',
      'Estou pronto para torcer pelo seu sucesso financeiro!',
      'Planejamento e paciência transformam pequenos valores em grandes conquistas!',
    ],
    PorkoMood.happy: [
      'Você está imparável! Continue com esse ritmo! 🔥',
      'Uau! Sequência ativa! Vamos continuar poupando!',
      'Olha essa dedicação! Oinc, estou muito orgulhoso! ✨',
      'Constância é o segredo da prosperidade!',
    ],
    PorkoMood.celebrating: [
      'Oinc! Vitória incrível! Você é um verdadeiro campeão! 🏆',
      'Meta concluída! Que momento glorioso e merecido! 🎉',
      'Celebração total! Parabéns por essa conquista épica!',
      'Oinc oinc! Seus sonhos estão se tornando realidade!',
    ],
  };

  // Pega uma frase padrão para exibir quando necessário
  static String getDefaultPhrase(PorkoMood mood) {
    final list = speechPhrases[mood] ?? speechPhrases[PorkoMood.neutral]!;
    return list.first;
  }
}
