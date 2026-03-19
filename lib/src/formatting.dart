part of '../main.dart';

String _formatEntryDate(DateTime dateTime) {
  return DateFormat('dd/MM/yy').format(dateTime);
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

class _WordCapitalizeFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) {
      return newValue;
    }

    final buffer = StringBuffer();
    var capitalizeNext = true;

    for (var index = 0; index < text.length; index++) {
      final char = text[index];
      if (capitalizeNext) {
        buffer.write(char.toUpperCase());
      } else {
        buffer.write(char);
      }
      capitalizeNext = char.trim().isEmpty;
    }

    final formattedText = buffer.toString();
    if (formattedText == text) {
      return newValue;
    }

    return TextEditingValue(
      text: formattedText,
      selection: newValue.selection,
      composing: TextRange.empty,
    );
  }
}
