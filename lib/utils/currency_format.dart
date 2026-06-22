/// Formats [value] with Indian digit grouping, e.g. `1,00,000.00`.
String formatInrAmount(double value, {bool includeSymbol = false}) {
  final negative = value < 0;
  final parts = value.abs().toStringAsFixed(2).split('.');
  final formatted = '${_formatIndianInteger(parts[0])}.${parts[1]}';
  final withSign = negative ? '-$formatted' : formatted;
  return includeSymbol ? '₹ $withSign' : withSign;
}

String _formatIndianInteger(String digits) {
  if (digits.length <= 3) return digits;

  final lastThree = digits.substring(digits.length - 3);
  var remaining = digits.substring(0, digits.length - 3);

  final groups = <String>[];
  while (remaining.isNotEmpty) {
    if (remaining.length <= 2) {
      groups.insert(0, remaining);
      break;
    }
    groups.insert(0, remaining.substring(remaining.length - 2));
    remaining = remaining.substring(0, remaining.length - 2);
  }

  return '${groups.join(',')},$lastThree';
}
