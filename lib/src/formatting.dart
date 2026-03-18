part of '../main.dart';

String _formatEntryDate(DateTime dateTime) {
  final month = _monthLabel(dateTime.month);

  return '${dateTime.day} $month ${dateTime.year}';
}

String _formatWeight3(double value) {
  final truncated = (value * 1000).floorToDouble() / 1000;
  return truncated.toStringAsFixed(3);
}

String _formatCurrency(double value) {
  final formatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '',
    decimalDigits: 2,
  );

  return formatter.format(value);
}

String _monthLabel(int month) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  return months[(month - 1).clamp(0, 11)];
}
