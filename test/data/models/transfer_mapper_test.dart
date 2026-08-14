import 'package:flutter_test/flutter_test.dart';
import 'package:prueba_tecnica/data/models/transfer_mapper.dart';
import 'package:prueba_tecnica/domain/entities/transfer.dart';

void main() {
  test('la transferencia sobrevive el viaje de ida y vuelta', () {
    final original = Transfer(
      id: 't1',
      sourceUserId: '1',
      destinationUserId: '2',
      amountInCents: 150000,
      createdAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
      description: 'Arriendo',
    );

    final restored = transferFromRow(original.toRow());

    expect(restored, original);
  });

  test('la descripcion nula se conserva nula', () {
    final original = Transfer(
      id: 't2',
      sourceUserId: '1',
      destinationUserId: '2',
      amountInCents: 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
    );

    expect(transferFromRow(original.toRow()).description, isNull);
  });

  test('una fila corrupta lanza en vez de devolver datos basura', () {
    expect(
      () => transferFromRow({'id': 't1', 'amount_in_cents': 'mucho'}),
      throwsFormatException,
    );
  });
}
