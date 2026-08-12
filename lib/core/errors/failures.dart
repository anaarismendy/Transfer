/// Errores de negocio. Sellada para que el `switch` en la UI sea exhaustivo:
/// si agregas un Failure nuevo, el compilador te obliga a manejarlo.
sealed class Failure {
  final String message;
  const Failure(this.message);
}

class StorageFailure extends Failure {
  const StorageFailure([super.message = 'Error al acceder al almacenamiento']);
}

/// Mismo mensaje para "no existe" y "contraseña incorrecta": distinguirlos
/// permitiria averiguar que correos estan registrados.
class InvalidCredentialsFailure extends Failure {
  const InvalidCredentialsFailure([super.message = 'Usuario o contrasena incorrectos']);
}

class DuplicateEmailFailure extends Failure {
  const DuplicateEmailFailure([super.message = 'Ya existe un usuario con ese correo']);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'No encontrado']);
}

class SameUserTransferFailure extends Failure {
  const SameUserTransferFailure([super.message = 'El origen y el destino no pueden ser el mismo usuario']);
}

class InvalidAmountFailure extends Failure {
  const InvalidAmountFailure([super.message = 'El valor debe ser mayor a cero']);
}

/// La llave foranea de `transfers` impide borrar un usuario con movimientos:
/// dejaria transferencias apuntando a alguien que no existe.
class UserHasTransfersFailure extends Failure {
  const UserHasTransfersFailure([
    super.message = 'No se puede eliminar un usuario con transferencias registradas',
  ]);
}
