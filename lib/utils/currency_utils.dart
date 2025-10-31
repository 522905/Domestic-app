// lib/utils/currency_utils.dart
import 'package:flutter/services.dart';

class IndianCurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    if (newValue.text.isEmpty) return newValue;
    String digitsOnly = newValue.text.replaceAll(',', '');
    String formatted = formatIndianNumber(digitsOnly);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

String formatIndianNumber(String number) {
  if (number.isEmpty) return '';
  final reversed = number.split('').reversed.join();
  String result = '';

  for (int i = 0; i < reversed.length; i++) {
    if (i == 3 || (i > 3 && (i - 3) % 2 == 0)) {
      result += ',';
    }
    result += reversed[i];
  }

  return result.split('').reversed.join();
}

String amountToWords(int amount) {
  if (amount == 0) return 'Zero Rupees';

  final ones = ['', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine'];
  final teens = ['Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen', 'Seventeen', 'Eighteen', 'Nineteen'];
  final tens = ['', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'];

  String convertHundreds(int num) {
    String result = '';
    if (num >= 100) {
      result += '${ones[num ~/ 100]} Hundred ';
      num %= 100;
    }
    if (num >= 20) {
      result += '${tens[num ~/ 10]} ';
      num %= 10;
    } else if (num >= 10) {
      result += '${teens[num - 10]} ';
      return result;
    }
    if (num > 0) result += '${ones[num]} ';
    return result;
  }

  String result = '';

  if (amount >= 10000000) {
    result += '${convertHundreds(amount ~/ 10000000)}Crore ';
    amount %= 10000000;
  }
  if (amount >= 100000) {
    result += '${convertHundreds(amount ~/ 100000)}Lakh ';
    amount %= 100000;
  }
  if (amount >= 1000) {
    result += '${convertHundreds(amount ~/ 1000)}Thousand ';
    amount %= 1000;
  }
  if (amount > 0) {
    result += convertHundreds(amount);
  }

  return '${result.trim()} Only';
}