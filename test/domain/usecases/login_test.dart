import 'package:flutter_test/flutter_test.dart';
import 'package:prueba_tecnica/core/errors/failures.dart';

import '../../support/harness.dart';

void main() {
  late Harness h;

  setUp(() async => h = await Harness.inMemory());

  test(
    'entra con las credenciales correctas y deja la sesion abierta',
    () async {
      final created = await h.newUser();

      final user = valueOf(await h.login('ana@test.com', 'Secreta123'));

      expect(user.id, created.id);
      expect(valueOf(await h.getCurrentUser())?.id, created.id);
    },
  );

  test('acepta el correo con otras mayusculas', () async {
    await h.newUser();

    expect(failureOf(await h.login('ANA@TEST.COM', 'Secreta123')), isNull);
  });

  test('rechaza la contrasena incorrecta', () async {
    await h.newUser();

    expect(
      failureOf(await h.login('ana@test.com', 'Equivocada1')),
      isA<InvalidCredentialsFailure>(),
    );
  });

  test('usuario inexistente y contrasena mala dan el mismo error', () async {
    await h.newUser();

    final noExiste = failureOf(await h.login('nadie@test.com', 'Secreta123'))!;
    final malaClave = failureOf(await h.login('ana@test.com', 'Equivocada1'))!;

    expect(
      noExiste.message,
      malaClave.message,
      reason: 'mensajes distintos revelarian que correos estan registrados',
    );
  });

  test('rechaza campos vacios sin consultar la base', () async {
    expect(failureOf(await h.login('', '')), isA<InvalidCredentialsFailure>());
  });

  test('un login fallido no abre sesion', () async {
    await h.newUser();

    await h.login('ana@test.com', 'Equivocada1');

    expect(valueOf(await h.getCurrentUser()), isNull);
  });
}
