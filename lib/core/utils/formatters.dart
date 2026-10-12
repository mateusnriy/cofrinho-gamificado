import 'package:intl/intl.dart';

// Funções para formatar valores em reais, porcentagens e datas
class AppFormatters {
  static final _currencyFormatter = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 2,
  );

  // Formata o valor em dinheiro brasileiro: R$ 1.250,00
  static String currency(double value) {
    return _currencyFormatter.format(value).replaceAll('\u00A0', ' ');
  }

  // Formata o valor de forma resumida para cards: R$ 1,2k
  static String currencyCompact(double value) {
    if (value >= 1000) {
      return 'R\$ ${(value / 1000).toStringAsFixed(1)}k';
    }
    return currency(value);
  }

  // Formata a data no padrão brasileiro: 25/12/2026
  static String date(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year;
    return '$d/$m/$y';
  }

  // Formata a data e a hora: 25/12/2026 • 14:30
  static String dateTime(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year;
    final h = date.hour.toString().padLeft(2, '0');
    final min = date.minute.toString().padLeft(2, '0');
    return '$d/$m/$y • $h:$min';
  }

  // Formata o mês e ano por extenso: dezembro 2026
  static String monthYear(DateTime date) {
    const months = [
      'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
      'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  // Formata o texto de dias que faltam: "3 dias restantes", "Hoje!" ou "No meu ritmo"
  static String daysRemaining(DateTime? deadline) {
    if (deadline == null) return 'No meu ritmo';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final deadlineDay = DateTime(deadline.year, deadline.month, deadline.day);
    final diff = deadlineDay.difference(today).inDays;

    if (diff < 0) return 'Prazo encerrado';
    if (diff == 0) return 'Vence hoje!';
    if (diff == 1) return '1 dia restante';
    return '$diff dias restantes';
  }

  // Devolve o percentual formatado como texto (ex: 75%)
  static String percent(double value) {
    final clamped = value.clamp(0.0, 100.0);
    return '${clamped.toStringAsFixed(0)}%';
  }
}
