import 'package:flutter_test/flutter_test.dart';
import 'package:prueba_tecnica/data/models/transfer_mapper.dart';
import 'package:prueba_tecnica/data/models/user_mapper.dart';
import 'package:prueba_tecnica/data/services/bcrypt_password_hasher.dart';
import 'package:prueba_tecnica/domain/entities/transfer.dart';
import 'package:prueba_tecnica/domain/entities/user.dart';

void main() {
  group('mappers', () {
    test('usuario sobrevive el viaje de ida y vuelta', () {
      const original = User(
        id: '1',
        name: 'Ana',
        email: 'ana@test.com',
        passwordHash: r'$2a$10$abc',
      );

      final restored = userFromMap(original.toMap());

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.email, original.email);
      expect(restored.passwordHash, original.passwordHash);
    });

    test('transferencia sobrevive el viaje de ida y vuelta', () {
      final original = Transfer(
        id: 't1',
        sourceUserId: '1',
        destinationUserId: '2',
        amountInCents: 150000,
        createdAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
        description: 'Arriendo',
      );

      final restored = transferFromMap(original.toMap());

      expect(restored.amountInCents, 150000);
      expect(restored.createdAt, original.createdAt);
      expect(restored.description, 'Arriendo');
    });

    test('descripcion nula se conserva nula', () {
      final original = Transfer(
        id: 't2',
        sourceUserId: '1',
        destinationUserId: '2',
        amountInCents: 1,
        createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      );

      expect(transferFromMap(original.toMap()).description, isNull);
    });

    test('un registro corrupto lanza en vez de devolver datos basura', () {
      expect(() => userFromMap({'id': '1'}), throwsFormatException);
      expect(
        () => transferFromMap({'id': 't1', 'amountInCents': 'mucho'}),
        throwsFormatException,
      );
    });
  });

  group('BcryptPasswordHasher', () {
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
  });
}
