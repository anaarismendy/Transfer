import 'package:flutter_test/flutter_test.dart';
import 'package:prueba_tecnica/core/errors/failures.dart';

import '../../support/harness.dart';

void main() {
  late Harness h;

  setUp(() async => h = await Harness.inMemory());

  test('crea el usuario y guarda un hash, no la contrasena', () async {
    final user = await h.newUser();

    expect(user.email, 'ana@test.com');
    expect(user.passwordHash, isNot('Secreta123'));
    expect(user.passwordHash, startsWith(r'$2'));
  });

  test('rechaza nombre vacio', () async {
    final r = await h.createUser(
      name: '   ',
      email: 'a@b.co',
      password: 'Secreta123',
    );

    expect(failureOf(r), isA<ValidationFailure>());
  });

  test('rechaza correo con formato invalido', () async {
    final r = await h.createUser(
      name: 'Ana',
      email: 'no-es-correo',
      password: 'Secreta123',
    );

    expect(failureOf(r), isA<ValidationFailure>());
  });

  test('rechaza contrasena corta', () async {
    final r = await h.createUser(
      name: 'Ana',
      email: 'a@b.co',
      password: 'corta',
    );

    expect(failureOf(r), isA<ValidationFailure>());
  });

  test('rechaza correo duplicado', () async {
    await h.newUser();

    final r = await h.createUser(
      name: 'Otra',
      email: 'ana@test.com',
      password: 'Secreta123',
    );

    expect(failureOf(r), isA<DuplicateEmailFailure>());
  });

  test('normaliza el correo a minusculas', () async {
    final user = await h.newUser(email: '  ANA@Test.COM ');

    expect(user.email, 'ana@test.com');
  });
}
