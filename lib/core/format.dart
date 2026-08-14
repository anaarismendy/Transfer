String _two(int value) => value.toString().padLeft(2, '0');

String _group(String digits) {
  final grouped = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) grouped.write('.');
    grouped.write(digits[i]);
  }
  return grouped.toString();
}

String formatMoney(int amountInCents) {
  final sign = amountInCents < 0 ? '-' : '';
  final absolute = amountInCents.abs();
  final pesos = absolute ~/ 100;
  final cents = absolute % 100;
  final grouped = _group(pesos.toString());

  return cents == 0 ? '$sign\$$grouped' : '$sign\$$grouped,${_two(cents)}';
}

String formatDateTime(DateTime value) =>
    '${_two(value.day)}/${_two(value.month)}/${value.year}  ${_two(value.hour)}:${_two(value.minute)}';

String formatRelative(DateTime value, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  final today = DateTime(reference.year, reference.month, reference.day);
  final day = DateTime(value.year, value.month, value.day);
  final hour = '${_two(value.hour)}:${_two(value.minute)}';

  final diff = today.difference(day).inDays;
  if (diff == 0) return 'Hoy, $hour';
  if (diff == 1) return 'Ayer, $hour';
  return '${_two(value.day)}/${_two(value.month)}, $hour';
}

int? parsePesosToCents(String input) {
  final pesos = int.tryParse(input.replaceAll(RegExp(r'[^0-9]'), ''));
  return pesos == null ? null : pesos * 100;
}

String formatKeypadAmount(String raw) {
  if (raw.isEmpty) return '0';

  final parts = raw.split('.');
  final grouped = _group(parts[0].isEmpty ? '0' : parts[0]);

  return parts.length == 1 ? grouped : '$grouped,${parts[1]}';
}

int? parseKeypadToCents(String raw) {
  if (raw.isEmpty) return null;

  final parts = raw.split('.');
  final pesos = parts[0].isEmpty ? 0 : int.tryParse(parts[0]);
  if (pesos == null) return null;

  final cents = parts.length > 1 && parts[1].isNotEmpty
      ? int.parse(parts[1].padRight(2, '0').substring(0, 2))
      : 0;

  final total = pesos * 100 + cents;
  return total == 0 ? null : total;
}
