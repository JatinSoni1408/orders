part of '../main.dart';

String _formatEntryDate(DateTime dateTime) {
  return DateFormat('dd/MM/yy').format(dateTime);
}

String _formatWeight3(double value) {
  final formatter = NumberFormat('0.000############', 'en_IN');
  return formatter.format(value);
}

String _formatWeightFixed3(double value) {
  final formatter = NumberFormat('0.000', 'en_IN');
  return formatter.format(value);
}

String _formatCurrency(double value) {
  final formatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '',
    decimalDigits: 2,
  );

  return formatter.format(value);
}

double _roundCurrency2(double value) {
  return (value * 100).roundToDouble() / 100;
}

String _sanitizeDecimalInput(String value) {
  final buffer = StringBuffer();
  var hasDecimal = false;

  for (final rune in value.runes) {
    final char = String.fromCharCode(rune);
    final isDigit = char.codeUnitAt(0) >= 48 && char.codeUnitAt(0) <= 57;
    if (isDigit) {
      buffer.write(char);
      continue;
    }
    if (char == '.' && !hasDecimal) {
      buffer.write(char);
      hasDecimal = true;
    }
  }

  return buffer.toString();
}

double _parseFormattedDecimal(String value) {
  final cleaned = value.replaceAll(',', '').trim();
  return double.tryParse(cleaned) ?? 0;
}

String _formatIndianNumberInput(String value) {
  final sanitized = _sanitizeDecimalInput(value.replaceAll(',', ''));
  if (sanitized.isEmpty) {
    return '';
  }

  final parts = sanitized.split('.');
  final integerPart = parts.first;
  var decimalPart = parts.length > 1 ? parts[1] : '';
  final hasTrailingDecimal = sanitized.endsWith('.');
  if (decimalPart.length > 2) {
    decimalPart = decimalPart.substring(0, 2);
  }
  final integerValue =
      int.tryParse(integerPart.isEmpty ? '0' : integerPart) ?? 0;
  final formattedInteger = NumberFormat.decimalPattern(
    'en_IN',
  ).format(integerValue);

  if (hasTrailingDecimal) {
    return '$formattedInteger.';
  }
  if (decimalPart.isNotEmpty) {
    return '$formattedInteger.$decimalPart';
  }
  return formattedInteger;
}

class _IndianCurrencyInputFormatter extends TextInputFormatter {
  const _IndianCurrencyInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final formatted = _formatIndianNumberInput(newValue.text);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
      composing: TextRange.empty,
    );
  }
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
