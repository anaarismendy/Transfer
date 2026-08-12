import '../../domain/entities/user.dart';

extension UserMapper on User {
  Map<String, Object?> toRow() => {
        'id': id,
        'name': name,
        'email': email,
        'password_hash': passwordHash,
      };
}

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
