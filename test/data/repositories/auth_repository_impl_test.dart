import 'package:flutter_test/flutter_test.dart';

import '../../support/harness.dart';

void main() {
  late Harness h;

  setUp(() async => h = await Harness.inMemory());

  Future<String?> current() async =>
      valueOf(await h.auth.currentSessionUserId());

  test('guarda, lee y limpia', () async {
    expect(await current(), isNull);

    await h.auth.saveSession('user-1');
    expect(await current(), 'user-1');

    await h.auth.clearSession();
    expect(await current(), isNull);
  });

  test('guardar dos veces reemplaza, no acumula', () async {
    await h.auth.saveSession('user-1');
    await h.auth.saveSession('user-2');

    expect(await current(), 'user-2');
  });
}
