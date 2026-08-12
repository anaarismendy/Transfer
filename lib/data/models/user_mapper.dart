import '../../domain/entities/user.dart';

/// Traduccion entidad <-> fila de la tabla `users`. Vive en data para que
/// `User` no sepa nada de columnas ni de SQL.
extension UserMapper on User {
  Map<String, Object?> toRow() => {
        'id': id,
        'name': name,
        'email': email,
        'password_hash': passwordHash,
      };
}

/// Leer de la base es una frontera de confianza: la fila puede venir de una
/// version anterior del esquema. Si algo no cuadra lanza, y el repositorio
/// lo traduce a StorageFailure.
User userFromRow(Map<String, Object?> row) {
  final id = row['id'];
  final name = row['name'];
  final email = row['email'];
  final passwordHash = row['password_hash'];

  if (id is! String || name is! String || email is! String || passwordHash is! String) {
    throw const FormatException('Fila de usuario invalida');
  }

  return User(id: id, name: name, email: email, passwordHash: passwordHash);
}
