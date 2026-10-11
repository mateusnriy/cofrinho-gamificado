import 'package:flutter/material.dart';

class BadgeDefinition {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const BadgeDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });

  static const List<BadgeDefinition> all = [
    BadgeDefinition(
      id: 'first_deposit',
      title: 'Primeiro Passo',
      description: 'Registrou o primeiro depósito em qualquer meta.',
      icon: Icons.savings_rounded,
      color: Color(0xFF10B981),
    ),
    BadgeDefinition(
      id: 'streak_3',
      title: 'Ritmo Constante',
      description: 'Alcançou um streak de 3 dias consecutivos.',
      icon: Icons.local_fire_department_rounded,
      color: Color(0xFFF59E0B),
    ),
    BadgeDefinition(
      id: 'streak_7',
      title: 'Semana de Ouro',
      description: 'Manteve o hábito ativo por 7 dias consecutivos.',
      icon: Icons.whatshot_rounded,
      color: Color(0xFFF97316),
    ),
    BadgeDefinition(
      id: 'streak_30',
      title: 'Mestre da Disciplina',
      description: 'Streak lendário de 30 dias consecutivos poupando!',
      icon: Icons.military_tech_rounded,
      color: Color(0xFF8B5CF6),
    ),
    BadgeDefinition(
      id: 'halfway',
      title: 'Meio Caminho Andado',
      description: 'Atingiu 50% do valor-alvo em uma meta.',
      icon: Icons.trending_up_rounded,
      color: Color(0xFF3B82F6),
    ),
    BadgeDefinition(
      id: 'goal_completed',
      title: 'Sonho Realizado',
      description: 'Alcançou 100% de uma meta com sucesso!',
      icon: Icons.emoji_events_rounded,
      color: Color(0xFFEAB308),
    ),
    BadgeDefinition(
      id: 'collector',
      title: 'Colecionador',
      description: 'Criou 3 ou mais metas ativas simultâneas.',
      icon: Icons.folder_special_rounded,
      color: Color(0xFF6366F1),
    ),
    BadgeDefinition(
      id: 'stylish',
      title: 'Estiloso',
      description: 'Comprou seu primeiro item cosmético na Porko Store.',
      icon: Icons.checkroom_rounded,
      color: Color(0xFFEC4899),
    ),
  ];

  static BadgeDefinition? findById(String id) {
    try {
      return all.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }
}

class UserBadge {
  final BadgeDefinition definition;
  final DateTime? unlockedAt;

  const UserBadge({
    required this.definition,
    this.unlockedAt,
  });

  bool get isUnlocked => unlockedAt != null;
}
