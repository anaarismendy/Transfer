import 'package:flutter_test/flutter_test.dart';
import 'package:prueba_tecnica/domain/entities/user.dart';
import 'package:prueba_tecnica/domain/usecases/seed_default_user.dart';

import '../../support/harness.dart';

void main() {
  late Harness h;

  setUp(() async => h = await Harness.inMemory());

  test(
    'el usuario semilla puede autenticarse con las credenciales del README',
    () async {
      await h.seedDefaultUser();

      final admin = valueOf(await h.users.findByEmail(SeedDefaultUser.email));

      expect(admin, isA<User>());
      expect(
        h.hasher.verify(SeedDefaultUser.password, admin!.passwordHash),
        isTrue,
        reason: 'si esto falla, nadie puede entrar a la app',
      );
    },
  );

  test('no duplica usuarios al reiniciar la app', () async {
    await h.seedDefaultUser();
    await h.seedDefaultUser();

    expect(valueOf(await h.users.getAll()), hasLength(1));
  });
}
