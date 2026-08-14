import 'package:flutter_test/flutter_test.dart';
import 'package:prueba_tecnica/core/errors/failures.dart';
import 'package:prueba_tecnica/domain/entities/user.dart';
import 'package:prueba_tecnica/domain/opening_balance.dart';

import '../../support/harness.dart';

void main() {
  late Harness h;
  late User ana;

  setUp(() async {
    h = await Harness.inMemory();
    ana = await h.newUser();
  });

  Future<User> luis() => h.newUser(name: 'Luis', email: 'luis@test.com');

  test('registra la transferencia', () async {
    final destino = await luis();

    final t = valueOf(
      await h.createTransfer(
        sourceUserId: ana.id,
        destinationUserId: destino.id,
        amountInCents: 150000,
        description: 'Arriendo',
      ),
    );

    expect(t.amountInCents, 150000);
    expect(t.description, 'Arriendo');
    expect(valueOf(await h.getTransfers()), hasLength(1));
  });

  test('sin saldo suficiente el mensaje habla del saldo', () async {
    final destino = await luis();

    final failure = failureOf(
      await h.createTransfer(
        sourceUserId: ana.id,
        destinationUserId: destino.id,
        amountInCents: openingBalanceInCents + 1,
      ),
    );

    expect(failure, isA<InsufficientFundsFailure>());
    expect(valueOf(await h.getTransfers()), isEmpty);
  });

  test('se puede enviar el saldo completo', () async {
    final destino = await luis();

    final everything = await h.createTransfer(
      sourceUserId: ana.id,
      destinationUserId: destino.id,
      amountInCents: openingBalanceInCents,
    );

    expect(failureOf(everything), isNull, reason: 'el limite es inclusivo');
  });

  test('rechaza valor cero o negativo con un error especifico', () async {
    final destino = await luis();

    for (final amount in [0, -100]) {
      expect(
        failureOf(
          await h.createTransfer(
            sourceUserId: ana.id,
            destinationUserId: destino.id,
            amountInCents: amount,
          ),
        ),
        isA<InvalidAmountFailure>(),
      );
    }
  });

  test('rechaza origen igual a destino con un error especifico', () async {
    expect(
      failureOf(
        await h.createTransfer(
          sourceUserId: ana.id,
          destinationUserId: ana.id,
          amountInCents: 100,
        ),
      ),
      isA<SameUserTransferFailure>(),
    );
  });

  test('rechaza un destino que no existe con un error especifico', () async {
    expect(
      failureOf(
        await h.createTransfer(
          sourceUserId: ana.id,
          destinationUserId: 'fantasma',
          amountInCents: 100,
        ),
      ),
      isA<NotFoundFailure>(),
    );
  });

  test('una transferencia rechazada no queda registrada', () async {
    await h.createTransfer(
      sourceUserId: ana.id,
      destinationUserId: ana.id,
      amountInCents: 100,
    );

    expect(valueOf(await h.getTransfers()), isEmpty);
  });
}
