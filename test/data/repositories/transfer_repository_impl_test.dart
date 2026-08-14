import 'package:flutter_test/flutter_test.dart';
import 'package:prueba_tecnica/core/errors/failures.dart';
import 'package:prueba_tecnica/domain/entities/user.dart';
import 'package:prueba_tecnica/domain/opening_balance.dart';

import '../../support/harness.dart';

void main() {
  late Harness h;
  late User ana;
  late User luis;

  setUp(() async {
    h = await Harness.inMemory();
    ana = await h.newUserRaw('Ana', 'ana@test.com');
    luis = await h.newUserRaw('Luis', 'luis@test.com');
  });

  test('se registra y aparece en el historial', () async {
    await h.transfers.create(
      sourceUserId: ana.id,
      destinationUserId: luis.id,
      amountInCents: 150000,
      description: '  Arriendo  ',
    );

    final first = valueOf(await h.transfers.getAll()).single;

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
      await h.transfers.create(
        sourceUserId: ana.id,
        destinationUserId: luis.id,
        amountInCents: 100,
        description: '   ',
      );

      expect(valueOf(await h.transfers.getAll()).single.description, isNull);
    },
  );

  test('el CHECK de la base rechaza un valor de cero o negativo', () async {
    final zero = await h.transfers.create(
      sourceUserId: ana.id,
      destinationUserId: luis.id,
      amountInCents: 0,
    );

    expect(failureOf(zero), isA<StorageFailure>());
    expect(valueOf(await h.transfers.getAll()), isEmpty);
  });

  test('el CHECK de la base rechaza origen igual a destino', () async {
    final self = await h.transfers.create(
      sourceUserId: ana.id,
      destinationUserId: ana.id,
      amountInCents: 100,
    );

    expect(failureOf(self), isA<StorageFailure>());
  });

  test('la llave foranea rechaza un destino inexistente', () async {
    final ghost = await h.transfers.create(
      sourceUserId: ana.id,
      destinationUserId: 'no-existe',
      amountInCents: 100,
    );

    expect(failureOf(ghost), isA<StorageFailure>());
  });

  test('el historial viene con la mas reciente primero', () async {
    await h.transfers.create(
      sourceUserId: ana.id,
      destinationUserId: luis.id,
      amountInCents: 100,
    );
    await h.transfers.create(
      sourceUserId: ana.id,
      destinationUserId: luis.id,
      amountInCents: 200,
    );

    final list = valueOf(await h.transfers.getAll());

    expect(list.first.amountInCents, 200);
    expect(list.last.amountInCents, 100);
  });

  group('saldos', () {
    test('mueve los dos saldos', () async {
      await h.transfers.create(
        sourceUserId: ana.id,
        destinationUserId: luis.id,
        amountInCents: 150000,
      );

      expect(await h.balanceOf(ana.id), openingBalanceInCents - 150000);
      expect(await h.balanceOf(luis.id), openingBalanceInCents + 150000);
    });

    test('sin saldo suficiente no queda nada a medias', () async {
      final tooMuch = await h.transfers.create(
        sourceUserId: ana.id,
        destinationUserId: luis.id,
        amountInCents: openingBalanceInCents + 100,
      );

      expect(failureOf(tooMuch), isA<InsufficientFundsFailure>());
      expect(
        valueOf(await h.transfers.getAll()),
        isEmpty,
        reason: 'la transaccion se deshizo completa',
      );
      expect(await h.balanceOf(ana.id), openingBalanceInCents);
      expect(await h.balanceOf(luis.id), openingBalanceInCents);
    });
  });
}
