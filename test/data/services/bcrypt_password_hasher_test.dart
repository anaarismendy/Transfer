import 'package:flutter_test/flutter_test.dart';
import 'package:prueba_tecnica/data/services/bcrypt_password_hasher.dart';

void main() {
  final hasher = BcryptPasswordHasher();

  test('acepta la contrasena correcta y rechaza la incorrecta', () {
    final hash = hasher.hash('Admin123');

    expect(hasher.verify('Admin123', hash), isTrue);
    expect(hasher.verify('admin123', hash), isFalse);
  });

  test('el hash nunca contiene la contrasena en claro', () {
    expect(hasher.hash('Admin123'), isNot(contains('Admin123')));
  });

  test('dos hashes de la misma contrasena difieren por el salt', () {
    expect(hasher.hash('Admin123'), isNot(hasher.hash('Admin123')));
  });
}
