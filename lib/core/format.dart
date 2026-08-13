String _two(int value) => value.toString().padLeft(2, '0');

String formatMoney(int amountInCents) {
  final pesos = amountInCents ~/ 100;
  final cents = amountInCents % 100;

  final digits = pesos.toString();
  final grouped = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) grouped.write('.');
    grouped.write(digits[i]);
  }

  return cents == 0 ? '\$$grouped' : '\$$grouped,${_two(cents)}';
}

String formatDateTime(DateTime value) =>
    '${_two(value.day)}/${_two(value.month)}/${value.year}  ${_two(value.hour)}:${_two(value.minute)}';

int? parsePesosToCents(String input) {
  final pesos = int.tryParse(input.replaceAll(RegExp(r'[^0-9]'), ''));
  return pesos == null ? null : pesos * 100;
}
