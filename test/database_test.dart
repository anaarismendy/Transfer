import 'package:flutter_test/flutter_test.dart';
import 'package:prueba_tecnica/core/errors/failures.dart';
import 'package:prueba_tecnica/core/result.dart';
import 'package:prueba_tecnica/data/datasources/app_database.dart';
import 'package:prueba_tecnica/data/datasources/session_local_datasource.dart';
import 'package:prueba_tecnica/data/datasources/transfer_local_datasource.dart';
import 'package:prueba_tecnica/data/datasources/user_local_datasource.dart';
import 'package:prueba_tecnica/data/repositories/auth_repository_impl.dart';
import 'package:prueba_tecnica/data/repositories/transfer_repository_impl.dart';
import 'package:prueba_tecnica/data/repositories/user_repository_impl.dart';
import 'package:prueba_tecnica/domain/entities/user.dart';
import 'package:prueba_tecnica/domain/opening_balance.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Ejercita el esquema real sobre una base en memoria. `flutter analyze` no
/// valida cadenas SQL, asi que sin esto el esquema viajaria sin ejecutarse.
void main() {
  late Database db;
  late UserRepositoryImpl users;
  late TransferRepositoryImpl transfers;
  late AuthRepositoryImpl auth;

  Failure? failureOf(Result<Object?> r) => r.fold((f) => f, (_) => null);

  setUp(() async {
    db = await AppDatabase.openInMemory();
    users = UserRepositoryImpl(UserLocalDataSource(db));
    transfers = TransferRepositoryImpl(TransferLocalDataSource(db));
    auth = AuthRepositoryImpl(SessionLocalDataSource(db));
  });

  tearDown(() => db.close());

  Future<User> createUser(String name, String email) async {
    final result = await users.create(
      name: name,
      email: email,
      passwordHash: 'hash',
      balanceInCents: openingBalanceInCents,
    );
    return result.fold((f) => throw StateError(f.message), (u) => u);
  }

  group('usuarios', () {
    test('se crea y se recupera', () async {
      await createUser('Ana', 'ana@test.com');

      final all = await users.getAll();

      expect(all.fold((_) => <User>[], (u) => u).single.name, 'Ana');
    });

    test('el UNIQUE de la base rechaza un correo repetido', () async {
      await createUser('Ana', 'ana@test.com');

      final again = await users.create(
        name: 'Otra Ana',
        email: 'ana@test.com',
        passwordHash: 'hash',
        balanceInCents: openingBalanceInCents,
      );

      expect(failureOf(again), isA<DuplicateEmailFailure>());
    });

    test(
      'el correo repetido tambien se detecta con otras mayusculas',
      () async {
        await createUser('Ana', 'ana@test.com');

        final again = await users.create(
          name: 'Otra Ana',
          email: 'ANA@TEST.COM',
          passwordHash: 'hash',
          balanceInCents: openingBalanceInCents,
        );

        expect(failureOf(again), isA<DuplicateEmailFailure>());
      },
    );

    test('findByEmail ignora mayusculas y espacios', () async {
      await createUser('Ana', 'ana@test.com');

      final found = await users.findByEmail('  ANA@test.com  ');

      expect(found.fold((_) => null, (u) => u?.name), 'Ana');
    });

    test('editar un usuario que no existe da NotFound', () async {
      const ghost = User(
        id: 'nope',
        name: 'X',
        email: 'x@x.co',
        passwordHash: 'h',
        balanceInCents: openingBalanceInCents,
      );

      expect(failureOf(await users.update(ghost)), isA<NotFoundFailure>());
    });

    test('borrar un usuario que no existe da NotFound', () async {
      expect(failureOf(await users.delete('nope')), isA<NotFoundFailure>());
    });

    test('se puede borrar un usuario sin movimientos', () async {
      final ana = await createUser('Ana', 'ana@test.com');

      expect(failureOf(await users.delete(ana.id)), isNull);
    });
  });

  group('transferencias', () {
    test('se registra y aparece en el historial', () async {
      final ana = await createUser('Ana', 'ana@test.com');
      final luis = await createUser('Luis', 'luis@test.com');

      await transfers.create(
        sourceUserId: ana.id,
        destinationUserId: luis.id,
        amountInCents: 150000,
        description: '  Arriendo  ',
      );

      final all = await transfers.getAll();
      final first = all.fold(
        (f) => throw StateError(f.message),
        (t) => t.single,
      );

      expect(first.amountInCents, 150000);
      expect(
        first.description,
        'Arriendo',
        reason: 'debe venir sin espacios sobrantes',
      );
    });

    test(
      'la descripcion vacia se guarda como nula, no como cadena vacia',
      () async {
        final ana = await createUser('Ana', 'ana@test.com');
        final luis = await createUser('Luis', 'luis@test.com');

        await transfers.create(
          sourceUserId: ana.id,
          destinationUserId: luis.id,
          amountInCents: 100,
          description: '   ',
        );

        final all = await transfers.getAll();

        expect(all.fold((_) => null, (t) => t.single.description), isNull);
      },
    );

    test('el CHECK de la base rechaza un valor de cero o negativo', () async {
      final ana = await createUser('Ana', 'ana@test.com');
      final luis = await createUser('Luis', 'luis@test.com');

      final zero = await transfers.create(
        sourceUserId: ana.id,
        destinationUserId: luis.id,
        amountInCents: 0,
      );

      expect(failureOf(zero), isA<StorageFailure>());
      expect(
        await transfers.getAll().then(
          (r) => r.fold((_) => -1, (t) => t.length),
        ),
        0,
      );
    });

    test('el CHECK de la base rechaza origen igual a destino', () async {
      final ana = await createUser('Ana', 'ana@test.com');

      final self = await transfers.create(
        sourceUserId: ana.id,
        destinationUserId: ana.id,
        amountInCents: 100,
      );

      expect(failureOf(self), isA<StorageFailure>());
    });

    test('la llave foranea rechaza un destino inexistente', () async {
      final ana = await createUser('Ana', 'ana@test.com');

      final ghost = await transfers.create(
        sourceUserId: ana.id,
        destinationUserId: 'no-existe',
        amountInCents: 100,
      );

      expect(failureOf(ghost), isA<StorageFailure>());
    });

    test('el historial viene con la mas reciente primero', () async {
      final ana = await createUser('Ana', 'ana@test.com');
      final luis = await createUser('Luis', 'luis@test.com');

      await transfers.create(
        sourceUserId: ana.id,
        destinationUserId: luis.id,
        amountInCents: 100,
      );
      await transfers.create(
        sourceUserId: ana.id,
        destinationUserId: luis.id,
        amountInCents: 200,
      );

      final all = await transfers.getAll();
      final list = all.fold((f) => throw StateError(f.message), (t) => t);

      expect(list.first.amountInCents, 200);
      expect(list.last.amountInCents, 100);
    });

    test('no se puede borrar un usuario con movimientos', () async {
      final ana = await createUser('Ana', 'ana@test.com');
      final luis = await createUser('Luis', 'luis@test.com');
      await transfers.create(
        sourceUserId: ana.id,
        destinationUserId: luis.id,
        amountInCents: 100,
      );

      expect(
        failureOf(await users.delete(ana.id)),
        isA<UserHasTransfersFailure>(),
      );
    });

    test(
      'un fallo de base que no sea la llave foranea no culpa a las transferencias',
      () async {
        final ana = await createUser('Ana', 'ana@test.com');
        await db.close();

        expect(failureOf(await users.delete(ana.id)), isA<StorageFailure>());
      },
    );
  });

  group('saldos', () {
    Future<int> balanceOf(String id) async {
      final found = await users.getById(id);
      return found.fold(
        (f) => throw StateError(f.message),
        (u) => u!.balanceInCents,
      );
    }

    test('la transferencia mueve los dos saldos', () async {
      final ana = await createUser('Ana', 'ana@test.com');
      final luis = await createUser('Luis', 'luis@test.com');

      await transfers.create(
        sourceUserId: ana.id,
        destinationUserId: luis.id,
        amountInCents: 150000,
      );

      expect(await balanceOf(ana.id), openingBalanceInCents - 150000);
      expect(await balanceOf(luis.id), openingBalanceInCents + 150000);
    });

    test('sin saldo suficiente no queda nada a medias', () async {
      final ana = await createUser('Ana', 'ana@test.com');
      final luis = await createUser('Luis', 'luis@test.com');

      final tooMuch = await transfers.create(
        sourceUserId: ana.id,
        destinationUserId: luis.id,
        amountInCents: openingBalanceInCents + 100,
      );

      expect(failureOf(tooMuch), isA<InsufficientFundsFailure>());
      expect(
        await transfers.getAll().then(
          (r) => r.fold((_) => -1, (t) => t.length),
        ),
        0,
        reason: 'la transaccion se deshizo completa',
      );
      expect(await balanceOf(ana.id), openingBalanceInCents);
      expect(await balanceOf(luis.id), openingBalanceInCents);
    });

    test('la migracion reconstruye el saldo desde el historial', () async {
      final ana = await createUser('Ana', 'ana@test.com');
      final luis = await createUser('Luis', 'luis@test.com');
      await transfers.create(
        sourceUserId: ana.id,
        destinationUserId: luis.id,
        amountInCents: 400000,
      );

      // Como quedaria una base vieja: la columna recien agregada arranca en 0.
      await db.execute('UPDATE users SET balance_in_cents = 0');
      await AppDatabase.recomputeBalances(db);

      expect(await balanceOf(ana.id), openingBalanceInCents - 400000);
      expect(await balanceOf(luis.id), openingBalanceInCents + 400000);
    });

    test('editar un usuario no pisa su saldo', () async {
      final ana = await createUser('Ana', 'ana@test.com');
      final luis = await createUser('Luis', 'luis@test.com');
      await transfers.create(
        sourceUserId: ana.id,
        destinationUserId: luis.id,
        amountInCents: 150000,
      );

      // La entidad que llega trae el saldo viejo, como pasaria con una pantalla
      // abierta desde antes de la transferencia.
      await users.update(ana.copyWith(name: 'Ana Maria'));

      expect(await balanceOf(ana.id), openingBalanceInCents - 150000);
    });
  });

  group('sesion', () {
    test('guarda, lee y limpia', () async {
      expect(
        await auth.currentSessionUserId().then(
          (r) => r.fold((_) => null, (id) => id),
        ),
        isNull,
      );

      await auth.saveSession('user-1');
      expect(
        await auth.currentSessionUserId().then(
          (r) => r.fold((_) => null, (id) => id),
        ),
        'user-1',
      );

      await auth.clearSession();
      expect(
        await auth.currentSessionUserId().then(
          (r) => r.fold((_) => null, (id) => id),
        ),
        isNull,
      );
    });

    test('iniciar sesion de nuevo sobrescribe en vez de fallar', () async {
      await auth.saveSession('user-1');
      await auth.saveSession('user-2');

      expect(
        await auth.currentSessionUserId().then(
          (r) => r.fold((_) => null, (id) => id),
        ),
        'user-2',
      );
    });
  });
}
