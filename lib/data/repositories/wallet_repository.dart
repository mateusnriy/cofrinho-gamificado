import 'dart:math';
import 'package:hive_flutter/hive_flutter.dart';

class WalletRepository {
  static const String boxName = 'wallet';
  static const String _balanceKey = 'oinc_coins_balance';
  static const String _lastDailyBonusDateKey = 'last_daily_bonus_date';

  Box get _box => Hive.box(boxName);

  /// Retorna o saldo atual de Oinc Coins (mínimo 0)
  int getBalance() {
    final val = _box.get(_balanceKey);
    if (val is int) return max(0, val);
    return 0;
  }

  /// Adiciona moedas à carteira e persiste no Hive
  Future<int> addCoins(int count) async {
    if (count <= 0) return getBalance();
    final newBalance = getBalance() + count;
    await _box.put(_balanceKey, newBalance);
    return newBalance;
  }

  /// Deduz moedas da carteira, respeitando a invariante de saldo não-negativo (RN-13)
  Future<int> deductCoins(int count) async {
    if (count <= 0) return getBalance();
    final current = getBalance();
    final newBalance = max(0, current - count);
    await _box.put(_balanceKey, newBalance);
    return newBalance;
  }

  /// Retorna a data em que o bônus diário foi resgatado pela última vez
  DateTime? getLastDailyBonusDate() {
    final str = _box.get(_lastDailyBonusDateKey) as String?;
    if (str == null) return null;
    return DateTime.tryParse(str);
  }

  /// Avalia e concede o bônus diário (+50 Oinc Coins) se este for o primeiro depósito do dia civil.
  /// Retorna true se o bônus foi concedido, false se o usuário já havia resgatado hoje.
  Future<bool> claimDailyBonusIfEligible(DateTime depositDate) async {
    final lastDate = getLastDailyBonusDate();
    final currentDay =
        DateTime(depositDate.year, depositDate.month, depositDate.day);

    if (lastDate != null) {
      final lastDay = DateTime(lastDate.year, lastDate.month, lastDate.day);
      if (lastDay.isAtSameMomentAs(currentDay) || lastDay.isAfter(currentDay)) {
        return false; // Já resgatou bônus diário hoje
      }
    }

    // Primeiro depósito do dia: concede bônus de +50 moedas
    await addCoins(50);
    await _box.put(_lastDailyBonusDateKey, depositDate.toIso8601String());
    return true;
  }

  /// Stream reativa de alterações na carteira
  Stream<BoxEvent> get watchAll => _box.watch();
}
