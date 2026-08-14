import 'package:injectable/injectable.dart';

import 'package:prueba_tecnica/core/errors/failures.dart';
import 'package:prueba_tecnica/core/result.dart';
import 'package:prueba_tecnica/domain/entities/transfer.dart';
import 'package:prueba_tecnica/domain/repositories/transfer_repository.dart';
import 'package:prueba_tecnica/domain/repositories/user_repository.dart';

@lazySingleton
class CreateTransfer {
  final TransferRepository _transfers;
  final UserRepository _users;
  CreateTransfer(this._transfers, this._users);

  Future<Result<Transfer>> call({
    required String sourceUserId,
    required String destinationUserId,
    required int amountInCents,
    String? description,
  }) async {
    if (amountInCents <= 0) return const Err(InvalidAmountFailure());
    if (sourceUserId == destinationUserId) {
      return const Err(SameUserTransferFailure());
    }

    for (final id in [sourceUserId, destinationUserId]) {
      final found = await _users.getById(id);
      switch (found) {
        case Err(:final failure):
          return Err(failure);
        case Ok(:final value):
          if (value == null) {
            return const Err(
              NotFoundFailure('El usuario seleccionado ya no existe'),
            );
          }
          // El CHECK de la tabla tambien lo impide, pero desde aca el mensaje
          // dice que fue el saldo y no un error generico de base.
          if (id == sourceUserId && value.balanceInCents < amountInCents) {
            return const Err(InsufficientFundsFailure());
          }
      }
    }

    return _transfers.create(
      sourceUserId: sourceUserId,
      destinationUserId: destinationUserId,
      amountInCents: amountInCents,
      description: description,
    );
  }
}
