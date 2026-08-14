import 'package:flutter_test/flutter_test.dart';
import 'package:prueba_tecnica/data/models/user_mapper.dart';
import 'package:prueba_tecnica/domain/entities/user.dart';

void main() {
  test('el usuario sobrevive el viaje de ida y vuelta', () {
    const original = User(
      id: '1',
      name: 'Ana',
      email: 'ana@test.com',
      passwordHash: r'$2a$10$abc',
      balanceInCents: 250000,
    );

    final restored = userFromRow(original.toRow());

    expect(restored, original);
  });

  test('las columnas usan snake_case, como la tabla', () {
    const user = User(id: '1', name: 'Ana', email: 'a@b.c', passwordHash: 'h');

    expect(
      user.toRow().keys,
      containsAll(['id', 'name', 'email', 'password_hash', 'balance_in_cents']),
    );
  });

  test('una fila corrupta lanza en vez de devolver datos basura', () {
    expect(() => userFromRow({'id': '1'}), throwsFormatException);
  });

  test('una fila sin saldo lanza, no asume cero', () {
    const user = User(id: '1', name: 'Ana', email: 'a@b.c', passwordHash: 'h');
    final row = user.toRow()..remove('balance_in_cents');

    expect(() => userFromRow(row), throwsFormatException);
  });
}
