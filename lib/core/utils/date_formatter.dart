import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static String toDisplay(DateTime date) =>
      DateFormat('d/M/yyyy').format(date);

  static String toDisplayWithTime(DateTime date) =>
      DateFormat('d/M/yyyy • HH:mm').format(date);

  static String toPeriodLabel(DateTime date, String period) {
    switch (period) {
      case 'dia':
        return DateFormat('d/M/yyyy').format(date);
      case 'semana':
        return 'Semana ${weekNumber(date)} • ${date.year}';
      case 'quincenal':
        final q = date.day <= 15 ? '1ra quincena' : '2da quincena';
        return '$q ${DateFormat('MMMM yyyy', 'es').format(date)}';
      case 'mensual':
        return DateFormat('MMMM yyyy', 'es').format(date);
      default:
        return DateFormat('d/M/yyyy').format(date);
    }
  }

  static int weekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final diff = date.difference(firstDayOfYear).inDays;
    return ((diff + firstDayOfYear.weekday - 1) / 7).ceil();
  }

  static String hourLabel(DateTime date) =>
      DateFormat('HH\'h\'').format(date);
}
