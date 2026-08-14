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
import 'package:prueba_tecnica/data/services/bcrypt_password_hasher.dart';
import 'package:prueba_tecnica/domain/entities/user.dart';
import 'package:prueba_tecnica/domain/opening_balance.dart';
import 'package:prueba_tecnica/domain/usecases/create_transfer.dart';
import 'package:prueba_tecnica/domain/usecases/create_user.dart';
import 'package:prueba_tecnica/domain/usecases/delete_user.dart';
import 'package:prueba_tecnica/domain/usecases/get_current_user.dart';
import 'package:prueba_tecnica/domain/usecases/get_transfers.dart';
import 'package:prueba_tecnica/domain/usecases/get_users.dart';
import 'package:prueba_tecnica/domain/usecases/login.dart';
import 'package:prueba_tecnica/domain/usecases/logout.dart';
import 'package:prueba_tecnica/domain/usecases/update_user.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Los casos de uso se prueban contra la base real en memoria en vez de
/// contra mocks: cubre tambien que las reglas de dominio y las restricciones
/// del esquema no se contradigan.
void main() {
  late Database db;
  late AuthRepositoryImpl auth;
  late Login login;
  late Logout logout;
  late GetCurrentUser getCurrentUser;
  late GetUsers getUsers;
  late CreateUser createUser;
  late UpdateUser updateUser;
  late DeleteUser deleteUser;
  late CreateTransfer createTransfer;
  late GetTransfers getTransfers;

  Failure? failureOf(Result<Object?> r) => r.fold((f) => f, (_) => null);
  T valueOf<T>(Result<T> r) =>
      r.fold((f) => throw StateError(f.message), (v) => v);

  setUp(() async {
    db = await AppDatabase.openInMemory();
    final hasher = BcryptPasswordHasher();
    final users = UserRepositoryImpl(UserLocalDataSource(db));
    final transfers = TransferRepositoryImpl(TransferLocalDataSource(db));
    auth = AuthRepositoryImpl(SessionLocalDataSource(db));

    login = Login(users, auth, hasher);
    logout = Logout(auth);
    getCurrentUser = GetCurrentUser(auth, users);
    getUsers = GetUsers(users);
    createUser = CreateUser(users, hasher);
    updateUser = UpdateUser(users, hasher);
    deleteUser = DeleteUser(users, auth);
    createTransfer = CreateTransfer(transfers, users);
    getTransfers = GetTransfers(transfers);
  });

  tearDown(() => db.close());

  Future<User> newUser([String email = 'ana@test.com']) async => valueOf(
    await createUser(name: 'Ana', email: email, password: 'Secreta123'),
  );

  group('CreateUser', () {
    test('crea el usuario y guarda un hash, no la contrasena', () async {
      final user = await newUser();

      expect(user.email, 'ana@test.com');
      expect(user.passwordHash, isNot('Secreta123'));
      expect(user.passwordHash, startsWith(r'$2'));
    });

    test('rechaza nombre vacio', () async {
      final r = await createUser(
        name: '   ',
        email: 'a@b.co',
        password: 'Secreta123',
      );

      expect(failureOf(r), isA<ValidationFailure>());
    });

    test('rechaza correo con formato invalido', () async {
      final r = await createUser(
        name: 'Ana',
        email: 'no-es-correo',
        password: 'Secreta123',
      );

      expect(failureOf(r), isA<ValidationFailure>());
    });

    test('rechaza contrasena corta', () async {
      final r = await createUser(
        name: 'Ana',
        email: 'a@b.co',
        password: 'corta',
      );

      expect(failureOf(r), isA<ValidationFailure>());
    });

    test('rechaza correo duplicado', () async {
      await newUser();

      final r = await createUser(
        name: 'Otra',
        email: 'ana@test.com',
        password: 'Secreta123',
      );

      expect(failureOf(r), isA<DuplicateEmailFailure>());
    });

    test('normaliza el correo a minusculas', () async {
      final user = valueOf(
        await createUser(
          name: 'Ana',
          email: '  ANA@Test.COM ',
          password: 'Secreta123',
        ),
      );

      expect(user.email, 'ana@test.com');
    });
  });

  group('Login', () {
    test(
      'entra con las credenciales correctas y deja la sesion abierta',
      () async {
        final created = await newUser();

        final user = valueOf(await login('ana@test.com', 'Secreta123'));

        expect(user.id, created.id);
        expect(valueOf(await getCurrentUser())?.id, created.id);
      },
    );

    test('acepta el correo con otras mayusculas', () async {
      await newUser();

      expect(failureOf(await login('ANA@TEST.COM', 'Secreta123')), isNull);
    });

    test('rechaza la contrasena incorrecta', () async {
      await newUser();

      expect(
        failureOf(await login('ana@test.com', 'Equivocada1')),
        isA<InvalidCredentialsFailure>(),
      );
    });

    test('usuario inexistente y contrasena mala dan el mismo error', () async {
      await newUser();

      final noExiste = failureOf(await login('nadie@test.com', 'Secreta123'))!;
      final malaClave = failureOf(await login('ana@test.com', 'Equivocada1'))!;

      expect(
        noExiste.message,
        malaClave.message,
        reason: 'mensajes distintos revelarian que correos estan registrados',
      );
    });

    test('rechaza campos vacios sin consultar la base', () async {
      expect(failureOf(await login('', '')), isA<InvalidCredentialsFailure>());
    });

    test('un login fallido no abre sesion', () async {
      await newUser();

      await login('ana@test.com', 'Equivocada1');

      expect(valueOf(await getCurrentUser()), isNull);
    });
  });

  group('Logout', () {
    test('cierra la sesion', () async {
      await newUser();
      await login('ana@test.com', 'Secreta123');

      await logout();

      expect(valueOf(await getCurrentUser()), isNull);
    });
  });

  group('GetCurrentUser', () {
    test('sin sesion devuelve nulo', () async {
      expect(valueOf(await getCurrentUser()), isNull);
    });

    test(
      'si la sesion apunta a un usuario que ya no existe, devuelve nulo',
      () async {
        await auth.saveSession('fantasma');

        expect(
          valueOf(await getCurrentUser()),
          isNull,
          reason: 'una sesion huerfana debe mandar al login, no romper la app',
        );
      },
    );
  });

  group('UpdateUser', () {
    test(
      'cambia el nombre y conserva la contrasena si no se envia una nueva',
      () async {
        final ana = await newUser();

        final updated = valueOf(
          await updateUser(id: ana.id, name: 'Ana Maria', email: ana.email),
        );

        expect(updated.name, 'Ana Maria');
        expect(updated.passwordHash, ana.passwordHash);
        expect(failureOf(await login('ana@test.com', 'Secreta123')), isNull);
      },
    );

    test('cambia la contrasena cuando se envia una nueva', () async {
      final ana = await newUser();

      await updateUser(
        id: ana.id,
        name: ana.name,
        email: ana.email,
        newPassword: 'NuevaClave1',
      );

      expect(
        failureOf(await login('ana@test.com', 'Secreta123')),
        isA<InvalidCredentialsFailure>(),
      );
      expect(failureOf(await login('ana@test.com', 'NuevaClave1')), isNull);
    });

    test('rechaza una contrasena nueva demasiado corta', () async {
      final ana = await newUser();

      final r = await updateUser(
        id: ana.id,
        name: ana.name,
        email: ana.email,
        newPassword: 'x',
      );

      expect(failureOf(r), isA<ValidationFailure>());
    });

    test('un usuario inexistente da NotFound', () async {
      final r = await updateUser(id: 'fantasma', name: 'X', email: 'x@y.co');

      expect(failureOf(r), isA<NotFoundFailure>());
    });
  });

  group('DeleteUser', () {
    test('borra un usuario sin movimientos', () async {
      final ana = await newUser();

      expect(failureOf(await deleteUser(ana.id)), isNull);
      expect(valueOf(await getUsers()), isEmpty);
    });

    test('no permite borrar el usuario de la sesion actual', () async {
      final ana = await newUser();
      await login('ana@test.com', 'Secreta123');

      expect(failureOf(await deleteUser(ana.id)), isA<ValidationFailure>());
      expect(valueOf(await getUsers()), hasLength(1));
    });

    test('no permite borrar un usuario con transferencias', () async {
      final ana = await newUser();
      final luis = await newUser('luis@test.com');
      await createTransfer(
        sourceUserId: ana.id,
        destinationUserId: luis.id,
        amountInCents: 5000,
      );

      expect(
        failureOf(await deleteUser(ana.id)),
        isA<UserHasTransfersFailure>(),
      );
    });
  });

  group('CreateTransfer', () {
    test('registra la transferencia', () async {
      final ana = await newUser();
      final luis = await newUser('luis@test.com');

      final t = valueOf(
        await createTransfer(
          sourceUserId: ana.id,
          destinationUserId: luis.id,
          amountInCents: 150000,
          description: 'Arriendo',
        ),
      );

      expect(t.amountInCents, 150000);
      expect(t.description, 'Arriendo');
      expect(valueOf(await getTransfers()), hasLength(1));
    });

    test('sin saldo suficiente el mensaje habla del saldo', () async {
      final ana = await newUser();
      final luis = await newUser('luis@test.com');

      final failure = failureOf(
        await createTransfer(
          sourceUserId: ana.id,
          destinationUserId: luis.id,
          amountInCents: openingBalanceInCents + 1,
        ),
      );

      expect(failure, isA<InsufficientFundsFailure>());
      expect(valueOf(await getTransfers()), isEmpty);
    });

    test('se puede enviar el saldo completo', () async {
      final ana = await newUser();
      final luis = await newUser('luis@test.com');

      final everything = await createTransfer(
        sourceUserId: ana.id,
        destinationUserId: luis.id,
        amountInCents: openingBalanceInCents,
      );

      expect(failureOf(everything), isNull, reason: 'el limite es inclusivo');
    });

    test('rechaza valor cero o negativo con un error especifico', () async {
      final ana = await newUser();
      final luis = await newUser('luis@test.com');

      expect(
        failureOf(
          await createTransfer(
            sourceUserId: ana.id,
            destinationUserId: luis.id,
            amountInCents: 0,
          ),
        ),
        isA<InvalidAmountFailure>(),
      );
      expect(
        failureOf(
          await createTransfer(
            sourceUserId: ana.id,
            destinationUserId: luis.id,
            amountInCents: -100,
          ),
        ),
        isA<InvalidAmountFailure>(),
      );
    });

    test('rechaza origen igual a destino con un error especifico', () async {
      final ana = await newUser();

      expect(
        failureOf(
          await createTransfer(
            sourceUserId: ana.id,
            destinationUserId: ana.id,
            amountInCents: 100,
          ),
        ),
        isA<SameUserTransferFailure>(),
      );
    });

    test('rechaza un destino que no existe con un error especifico', () async {
      final ana = await newUser();

      expect(
        failureOf(
          await createTransfer(
            sourceUserId: ana.id,
            destinationUserId: 'fantasma',
            amountInCents: 100,
          ),
        ),
        isA<NotFoundFailure>(),
      );
    });

    test('una transferencia rechazada no queda registrada', () async {
      final ana = await newUser();

      await createTransfer(
        sourceUserId: ana.id,
        destinationUserId: ana.id,
        amountInCents: 100,
      );

      expect(valueOf(await getTransfers()), isEmpty);
    });
  });
}
