import 'package:flutter_test/flutter_test.dart';
import 'package:prueba_tecnica/core/format.dart';

void main() {
  group('formatMoney', () {
    test('agrupa miles con punto, como en Colombia', () {
      expect(formatMoney(100), r'$1');
      expect(formatMoney(150000 * 100), r'$150.000');
      expect(formatMoney(1234567 * 100), r'$1.234.567');
    });

    test('muestra centavos solo cuando existen', () {
      expect(formatMoney(500000), r'$5.000');
      expect(formatMoney(500050), r'$5.000,50');
    });

    test('un saldo negativo se agrupa bien', () {
      expect(formatMoney(-500000 * 100), r'-$500.000');
    });
  });

  group('fechas', () {
    test('la fecha usa dos digitos', () {
      expect(formatDateTime(DateTime(2026, 8, 3, 9, 5)), '03/08/2026  09:05');
    });

    test('la fecha relativa distingue hoy, ayer y el resto', () {
      final now = DateTime(2026, 8, 13, 15, 0);

      expect(
        formatRelative(DateTime(2026, 8, 13, 10, 32), now: now),
        'Hoy, 10:32',
      );
      expect(
        formatRelative(DateTime(2026, 8, 12, 18, 50), now: now),
        'Ayer, 18:50',
      );
      expect(
        formatRelative(DateTime(2026, 8, 10, 11, 5), now: now),
        '10/08, 11:05',
      );
    });
  });

  group('teclado', () {
    test('convierte pesos escritos a centavos', () {
      expect(parsePesosToCents('150000'), 15000000);
      expect(parsePesosToCents('1.500'), 150000);
      expect(parsePesosToCents(''), isNull);
    });

    test('se muestra agrupado y con coma decimal', () {
      expect(formatKeypadAmount(''), '0');
      expect(formatKeypadAmount('150000'), '150.000');
      expect(formatKeypadAmount('1500.5'), '1.500,5');
    });

    test('convierte a centavos y rechaza el cero', () {
      expect(parseKeypadToCents('150000'), 15000000);
      expect(parseKeypadToCents('1500.5'), 150050);
      expect(parseKeypadToCents('1500.55'), 150055);
      expect(parseKeypadToCents('0'), isNull);
      expect(parseKeypadToCents(''), isNull);
    });
  });
}
