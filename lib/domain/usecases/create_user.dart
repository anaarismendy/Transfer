import 'package:injectable/injectable.dart';

import 'package:prueba_tecnica/core/result.dart';
import 'package:prueba_tecnica/domain/entities/user.dart';
import 'package:prueba_tecnica/domain/opening_balance.dart';
import 'package:prueba_tecnica/domain/repositories/user_repository.dart';
import 'package:prueba_tecnica/domain/services/password_hasher.dart';
import 'package:prueba_tecnica/domain/validation.dart';

@lazySingleton
class CreateUser {
  final UserRepository _users;
  final PasswordHasher _hasher;
  CreateUser(this._users, this._hasher);

  Future<Result<User>> call({
    required String name,
    required String email,
    required String password,
  }) async {
    final invalid = validateUserInput(
      name: name,
      email: email,
      password: password,
    );
    if (invalid != null) return Err(invalid);

    return _users.create(
      name: name,
      email: email,
      passwordHash: _hasher.hash(password),
      balanceInCents: openingBalanceInCents,
    );
  }
}
