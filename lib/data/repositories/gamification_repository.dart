import 'dart:math';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/badge_model.dart';

class GamificationRepository {
  static const String boxName = 'gamification';
  static const String _currentStreakKey = 'current_streak';
  static const String _longestStreakKey = 'longest_streak';
  static const String _lastDepositDateKey = 'last_deposit_date';
  static const String _unlockedBadgesKey = 'unlocked_badges';

  Box get _box => Hive.box(boxName);

  /// Retorna o streak atual de dias consecutivos (0 se nenhum depósito registrado ainda)
  int getCurrentStreak() {
    return (_box.get(_currentStreakKey) as int?) ?? 0;
  }

  /// Retorna o maior streak já conquistado
  int getLongestStreak() {
    return (_box.get(_longestStreakKey) as int?) ?? 0;
  }

  /// Retorna a data do último depósito registrado
  DateTime? getLastDepositDate() {
    final str = _box.get(_lastDepositDateKey) as String?;
    if (str == null) return null;
    return DateTime.tryParse(str);
  }

  /// Atualiza o streak com base na data do depósito
  /// Retorna o novo currentStreak após o cálculo
  Future<int> registerDepositDate(DateTime depositDate) async {
    final lastDate = getLastDepositDate();
    int currentStreak = getCurrentStreak();
    int longestStreak = getLongestStreak();

    if (lastDate == null) {
      // Primeiro depósito registrado
      currentStreak = 1;
      longestStreak = max(longestStreak, 1);
    } else {
      // Normaliza para comparação estrita de dias calendário (ignorando horas)
      final lastDay = DateTime(lastDate.year, lastDate.month, lastDate.day);
      final currentDay =
          DateTime(depositDate.year, depositDate.month, depositDate.day);
      final diffDays = currentDay.difference(lastDay).inDays;

      if (diffDays == 0) {
        // Mesmo dia calendário: não altera o streak
        return currentStreak;
      } else if (diffDays == 1) {
        // Dia consecutivo direto: incrementa streak
        currentStreak += 1;
        longestStreak = max(longestStreak, currentStreak);
      } else if (diffDays > 1) {
        // Intervalo de mais de 1 dia: streak reinicia em 1
        currentStreak = 1;
      } else {
        // Depósito com data anterior (retroativo): não altera streak futuro
        return currentStreak;
      }
    }

    await _box.put(_currentStreakKey, currentStreak);
    await _box.put(_longestStreakKey, longestStreak);
    await _box.put(_lastDepositDateKey, depositDate.toIso8601String());

    return currentStreak;
  }

  /// Retorna o mapa de badges desbloqueados com suas respectivas datas
  Map<String, DateTime> getUnlockedBadges() {
    final raw = _box.get(_unlockedBadgesKey);
    if (raw == null || raw is! Map) return {};
    final result = <String, DateTime>{};
    raw.forEach((key, value) {
      if (key is String && value is String) {
        final parsed = DateTime.tryParse(value);
        if (parsed != null) {
          result[key] = parsed;
        }
      }
    });
    return result;
  }

  /// Verifica se um determinado badge já está desbloqueado
  bool isBadgeUnlocked(String badgeId) {
    final unlocked = getUnlockedBadges();
    return unlocked.containsKey(badgeId);
  }

  /// Desbloqueia um badge de forma estritamente idempotente
  /// Retorna true se acabou de ser desbloqueado pela 1ª vez, false se já existia
  Future<bool> unlockBadge(String badgeId, [DateTime? date]) async {
    final current = Map<String, dynamic>.from((_box.get(_unlockedBadgesKey) as Map?) ?? {});
    if (current.containsKey(badgeId)) {
      return false; // Já estava desbloqueado
    }

    final unlockTime = date ?? DateTime.now();
    current[badgeId] = unlockTime.toIso8601String();
    await _box.put(_unlockedBadgesKey, current);
    return true;
  }

  /// Retorna todos os badges do catálogo com o status de desbloqueio do usuário
  List<UserBadge> getAllUserBadges() {
    final unlocked = getUnlockedBadges();
    return BadgeDefinition.all.map((def) {
      return UserBadge(
        definition: def,
        unlockedAt: unlocked[def.id],
      );
    }).toList();
  }

  /// Stream reativa de eventos da gamification_box
  Stream<BoxEvent> get watchAll => _box.watch();
}
