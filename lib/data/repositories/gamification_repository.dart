import 'dart:math';
import 'package:hive_flutter/hive_flutter.dart';

class GamificationRepository {
  static const String boxName = 'gamification';
  static const String _currentStreakKey = 'current_streak';
  static const String _longestStreakKey = 'longest_streak';
  static const String _lastDepositDateKey = 'last_deposit_date';

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

  /// Stream reativa de eventos da gamification_box
  Stream<BoxEvent> get watchAll => _box.watch();
}
