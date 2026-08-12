import '../../domain/entities/user.dart';

/// Traduccion entidad <-> mapa persistido. Vive en data para que `User` no
/// sepa nada de como se guarda.
extension UserMapper on User {
  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'email': email,
        'passwordHash': passwordHash,
      };
}

/// Leer del disco es una frontera de confianza: el archivo puede estar
/// corrupto o venir de una version anterior del modelo. Si algo no cuadra
/// lanza, y el repositorio lo traduce a StorageFailure.
User userFromMap(Map<dynamic, dynamic> map) {
  final id = map['id'];
  final name = map['name'];
  final email = map['email'];
  final passwordHash = map['passwordHash'];

  if (id is! String || name is! String || email is! String || passwordHash is! String) {
    throw const FormatException('Registro de usuario invalido');
  }

  return User(id: id, name: name, email: email, passwordHash: passwordHash);
}
