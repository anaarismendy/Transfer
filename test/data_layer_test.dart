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

      final restored = userFromRow(original.toRow());

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.email, original.email);
      expect(restored.passwordHash, original.passwordHash);
    });

    test('las columnas usan snake_case, como la tabla', () {
      const user = User(
        id: '1',
        name: 'Ana',
        email: 'a@b.c',
        passwordHash: 'h',
      );

      expect(
        user.toRow().keys,
        containsAll(['id', 'name', 'email', 'password_hash']),
      );
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

      final restored = transferFromRow(original.toRow());

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

      expect(transferFromRow(original.toRow()).description, isNull);
    });

    test('una fila corrupta lanza en vez de devolver datos basura', () {
      expect(() => userFromRow({'id': '1'}), throwsFormatException);
      expect(
        () => transferFromRow({'id': 't1', 'amount_in_cents': 'mucho'}),
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
