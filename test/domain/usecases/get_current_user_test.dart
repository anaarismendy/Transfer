import 'package:flutter_test/flutter_test.dart';

import '../../support/harness.dart';

void main() {
  late Harness h;

  setUp(() async => h = await Harness.inMemory());

  test('sin sesion devuelve nulo', () async {
    expect(valueOf(await h.getCurrentUser()), isNull);
  });

  test(
    'si la sesion apunta a un usuario que ya no existe, devuelve nulo',
    () async {
      await h.auth.saveSession('fantasma');

      expect(
        valueOf(await h.getCurrentUser()),
        isNull,
        reason: 'una sesion huerfana debe mandar al login, no romper la app',
      );
    },
  );
}
