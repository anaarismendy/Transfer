import 'package:prueba_tecnica/domain/entities/user.dart';

extension UserMapper on User {
  Map<String, Object?> toRow() => {
    'id': id,
    'name': name,
    'email': email,
    'password_hash': passwordHash,
    'balance_in_cents': balanceInCents,
  };
}

User userFromRow(Map<String, Object?> row) {
  final id = row['id'];
  final name = row['name'];
  final email = row['email'];
  final passwordHash = row['password_hash'];
  final balance = row['balance_in_cents'];

  if (id is! String ||
      name is! String ||
      email is! String ||
      passwordHash is! String ||
      balance is! int) {
    throw const FormatException('Fila de usuario invalida');
  }

  return User(
    id: id,
    name: name,
    email: email,
    passwordHash: passwordHash,
    balanceInCents: balance,
  );
}
