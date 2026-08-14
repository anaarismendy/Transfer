import 'package:flutter_test/flutter_test.dart';
import 'package:prueba_tecnica/core/errors/failures.dart';
import 'package:prueba_tecnica/domain/entities/user.dart';
import 'package:prueba_tecnica/domain/opening_balance.dart';

import '../../support/harness.dart';

void main() {
  late Harness h;

  setUp(() async => h = await Harness.inMemory());

  test('se crea y se recupera', () async {
    await h.newUserRaw('Ana', 'ana@test.com');

    expect(valueOf(await h.users.getAll()).single.name, 'Ana');
  });

  test('nace con el cupo de apertura que se le pase', () async {
    final ana = await h.newUserRaw('Ana', 'ana@test.com');

    expect(ana.balanceInCents, openingBalanceInCents);
    expect(await h.balanceOf(ana.id), openingBalanceInCents);
  });

  test('el UNIQUE de la base rechaza un correo repetido', () async {
    await h.newUserRaw('Ana', 'ana@test.com');

    final again = await h.users.create(
      name: 'Otra Ana',
      email: 'ana@test.com',
      passwordHash: 'hash',
      balanceInCents: 0,
    );

    expect(failureOf(again), isA<DuplicateEmailFailure>());
  });

  test('el correo repetido tambien se detecta con otras mayusculas', () async {
    await h.newUserRaw('Ana', 'ana@test.com');

    final again = await h.users.create(
      name: 'Otra Ana',
      email: 'ANA@TEST.COM',
      passwordHash: 'hash',
      balanceInCents: 0,
    );

    expect(failureOf(again), isA<DuplicateEmailFailure>());
  });

  test('findByEmail ignora mayusculas y espacios', () async {
    await h.newUserRaw('Ana', 'ana@test.com');

    final found = await h.users.findByEmail('  ANA@test.com  ');

    expect(valueOf(found)?.name, 'Ana');
  });

  test('editar un usuario que no existe da NotFound', () async {
    const ghost = User(
      id: 'nope',
      name: 'X',
      email: 'x@x.co',
      passwordHash: 'h',
    );

    expect(failureOf(await h.users.update(ghost)), isA<NotFoundFailure>());
  });

  test('editar no pisa el saldo', () async {
    final ana = await h.newUserRaw('Ana', 'ana@test.com');
    final luis = await h.newUserRaw('Luis', 'luis@test.com');
    await h.transfers.create(
      sourceUserId: ana.id,
      destinationUserId: luis.id,
      amountInCents: 150000,
    );

    await h.users.update(ana.copyWith(name: 'Ana Maria'));

    expect(await h.balanceOf(ana.id), openingBalanceInCents - 150000);
  });

  test('borrar un usuario que no existe da NotFound', () async {
    expect(failureOf(await h.users.delete('nope')), isA<NotFoundFailure>());
  });

  test('se puede borrar un usuario sin movimientos', () async {
    final ana = await h.newUserRaw('Ana', 'ana@test.com');

    expect(failureOf(await h.users.delete(ana.id)), isNull);
  });

  test('la llave foranea impide borrar un usuario con movimientos', () async {
    final ana = await h.newUserRaw('Ana', 'ana@test.com');
    final luis = await h.newUserRaw('Luis', 'luis@test.com');
    await h.transfers.create(
      sourceUserId: ana.id,
      destinationUserId: luis.id,
      amountInCents: 100,
    );

    expect(
      failureOf(await h.users.delete(ana.id)),
      isA<UserHasTransfersFailure>(),
    );
  });

  test(
    'un fallo que no sea la llave foranea no culpa a las transferencias',
    () async {
      final ana = await h.newUserRaw('Ana', 'ana@test.com');
      await h.db.close();

      expect(failureOf(await h.users.delete(ana.id)), isA<StorageFailure>());
    },
  );
}
