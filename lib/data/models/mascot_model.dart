enum PorkoMood {
  sleeping,
  neutral,
  happy,
  celebrating,
}

class MascotModel {
  final String skinId;
  final String? hatId;
  final String? clothId;
  final String? backdropId;

  const MascotModel({
    this.skinId = 'pink_classic',
    this.hatId,
    this.clothId,
    this.backdropId,
  });

  MascotModel copyWith({
    String? skinId,
    String? hatId,
    String? clothId,
    String? backdropId,
  }) {
    return MascotModel(
      skinId: skinId ?? this.skinId,
      hatId: hatId ?? this.hatId,
      clothId: clothId ?? this.clothId,
      backdropId: backdropId ?? this.backdropId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'skinId': skinId,
      'hatId': hatId,
      'clothId': clothId,
      'backdropId': backdropId,
    };
  }

  factory MascotModel.fromMap(Map<dynamic, dynamic>? map) {
    if (map == null) return const MascotModel();
    return MascotModel(
      skinId: (map['skinId'] as String?) ?? 'pink_classic',
      hatId: map['hatId'] as String?,
      clothId: map['clothId'] as String?,
      backdropId: map['backdropId'] as String?,
    );
  }

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

  static String getDefaultPhrase(PorkoMood mood) {
    final list = speechPhrases[mood] ?? speechPhrases[PorkoMood.neutral]!;
    return list.first;
  }
}
