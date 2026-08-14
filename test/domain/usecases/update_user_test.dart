import 'package:flutter_test/flutter_test.dart';
import 'package:prueba_tecnica/core/errors/failures.dart';

import '../../support/harness.dart';

void main() {
  late Harness h;

  setUp(() async => h = await Harness.inMemory());

  test(
    'cambia el nombre y conserva la contrasena si no se envia una nueva',
    () async {
      final ana = await h.newUser();

      final updated = valueOf(
        await h.updateUser(id: ana.id, name: 'Ana Maria', email: ana.email),
      );

      expect(updated.name, 'Ana Maria');
      expect(updated.passwordHash, ana.passwordHash);
      expect(failureOf(await h.login('ana@test.com', 'Secreta123')), isNull);
    },
  );

  test('cambia la contrasena cuando se envia una nueva', () async {
    final ana = await h.newUser();

    await h.updateUser(
      id: ana.id,
      name: ana.name,
      email: ana.email,
      newPassword: 'NuevaClave1',
    );

    expect(
      failureOf(await h.login('ana@test.com', 'Secreta123')),
      isA<InvalidCredentialsFailure>(),
    );
    expect(failureOf(await h.login('ana@test.com', 'NuevaClave1')), isNull);
  });

  test('rechaza una contrasena nueva demasiado corta', () async {
    final ana = await h.newUser();

    final r = await h.updateUser(
      id: ana.id,
      name: ana.name,
      email: ana.email,
      newPassword: 'x',
    );

    expect(failureOf(r), isA<ValidationFailure>());
  });

  test('un usuario inexistente da NotFound', () async {
    final r = await h.updateUser(id: 'fantasma', name: 'X', email: 'x@y.co');

    expect(failureOf(r), isA<NotFoundFailure>());
  });
}
