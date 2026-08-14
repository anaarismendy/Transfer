import 'package:flutter_test/flutter_test.dart';
import 'package:prueba_tecnica/core/errors/failures.dart';

import '../../support/harness.dart';

void main() {
  late Harness h;

  setUp(() async => h = await Harness.inMemory());

  test('borra un usuario sin movimientos', () async {
    final ana = await h.newUser();

    expect(failureOf(await h.deleteUser(ana.id)), isNull);
    expect(valueOf(await h.getUsers()), isEmpty);
  });

  test('no permite borrar el usuario de la sesion actual', () async {
    final ana = await h.newUser();
    await h.login('ana@test.com', 'Secreta123');

    expect(failureOf(await h.deleteUser(ana.id)), isA<ValidationFailure>());
    expect(valueOf(await h.getUsers()), hasLength(1));
  });

  test('no permite borrar un usuario con transferencias', () async {
    final ana = await h.newUser();
    final luis = await h.newUser(email: 'luis@test.com');
    await h.createTransfer(
      sourceUserId: ana.id,
      destinationUserId: luis.id,
      amountInCents: 5000,
    );

    expect(
      failureOf(await h.deleteUser(ana.id)),
      isA<UserHasTransfersFailure>(),
    );
  });
}
