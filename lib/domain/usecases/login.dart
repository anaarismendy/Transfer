import 'package:injectable/injectable.dart';

import 'package:prueba_tecnica/core/errors/failures.dart';
import 'package:prueba_tecnica/core/result.dart';
import 'package:prueba_tecnica/domain/entities/user.dart';
import 'package:prueba_tecnica/domain/repositories/auth_repository.dart';
import 'package:prueba_tecnica/domain/repositories/user_repository.dart';
import 'package:prueba_tecnica/domain/services/password_hasher.dart';

@lazySingleton
class Login {
  final UserRepository _users;
  final AuthRepository _auth;
  final PasswordHasher _hasher;
  Login(this._users, this._auth, this._hasher);

  Future<Result<User>> call(String email, String password) async {
    if (email.trim().isEmpty || password.isEmpty) {
      return const Err(InvalidCredentialsFailure());
    }

    final found = await _users.findByEmail(email);
    switch (found) {
      case Err(:final failure):
        return Err(failure);
      case Ok(:final value):
        if (value == null || !_hasher.verify(password, value.passwordHash)) {
          return const Err(InvalidCredentialsFailure());
        }
        final saved = await _auth.saveSession(value.id);
        return switch (saved) {
          Err(:final failure) => Err(failure),
          Ok() => Ok(value),
        };
    }
  }
}
