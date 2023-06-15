import 'package:flutter/services.dart';

class NumberLimitInputFormatter extends TextInputFormatter {
  final int maxValue;

  NumberLimitInputFormatter(this.maxValue);

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    if (newValue.text.isNotEmpty) {
      final parsedValue = int.tryParse(newValue.text);
      if (parsedValue != null && parsedValue > maxValue) {
        // Truncate the value to the maximum allowed
        final truncatedValue = TextEditingValue(
          text: maxValue.toString(),
          selection: newValue.selection,
        );
        return truncatedValue;
      }
    }
    return newValue;
  }
}
