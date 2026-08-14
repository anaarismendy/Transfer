sealed class Failure {
  final String message;
  const Failure(this.message);
}

class StorageFailure extends Failure {
  const StorageFailure([super.message = 'Error al acceder al almacenamiento']);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class InvalidCredentialsFailure extends Failure {
  const InvalidCredentialsFailure([
    super.message = 'Usuario o contrasena incorrectos',
  ]);
}

class DuplicateEmailFailure extends Failure {
  const DuplicateEmailFailure([
    super.message = 'Ya existe un usuario con ese correo',
  ]);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'No encontrado']);
}

class SameUserTransferFailure extends Failure {
  const SameUserTransferFailure([
    super.message = 'El origen y el destino no pueden ser el mismo usuario',
  ]);
}

class InsufficientFundsFailure extends Failure {
  const InsufficientFundsFailure([
    super.message = 'El saldo no alcanza para esta transferencia',
  ]);
}

class InvalidAmountFailure extends Failure {
  const InvalidAmountFailure([
    super.message = 'El valor debe ser mayor a cero',
  ]);
}

class UserHasTransfersFailure extends Failure {
  const UserHasTransfersFailure([
    super.message =
        'No se puede eliminar un usuario con transferencias registradas',
  ]);
}
