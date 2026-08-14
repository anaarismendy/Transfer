import 'package:flutter_test/flutter_test.dart';

import '../../support/harness.dart';

void main() {
  test('cierra la sesion', () async {
    final h = await Harness.inMemory();
    await h.newUser();
    await h.login('ana@test.com', 'Secreta123');

    await h.logout();

    expect(valueOf(await h.getCurrentUser()), isNull);
  });
}
