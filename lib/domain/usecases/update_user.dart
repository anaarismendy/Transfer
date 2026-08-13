import 'package:injectable/injectable.dart';

import 'package:prueba_tecnica/core/errors/failures.dart';
import 'package:prueba_tecnica/core/result.dart';
import 'package:prueba_tecnica/domain/entities/user.dart';
import 'package:prueba_tecnica/domain/repositories/user_repository.dart';
import 'package:prueba_tecnica/domain/services/password_hasher.dart';
import 'package:prueba_tecnica/domain/validation.dart';

@lazySingleton
class UpdateUser {
  final UserRepository _users;
  final PasswordHasher _hasher;
  UpdateUser(this._users, this._hasher);

  Future<Result<User>> call({
    required String id,
    required String name,
    required String email,
    String? newPassword,
  }) async {
    final invalid = validateUserInput(name: name, email: email, password: newPassword);
    if (invalid != null) return Err(invalid);

    final existing = await _users.getById(id);
    switch (existing) {
      case Err(:final failure):
        return Err(failure);
      case Ok(:final value):
        if (value == null) return const Err(NotFoundFailure('El usuario no existe'));

        final actualizado = value.copyWith(
          name: name.trim(),
          email: email.trim().toLowerCase(),
        );

        return _users.update(
          newPassword == null
              ? actualizado
              : actualizado.copyWith(passwordHash: _hasher.hash(newPassword)),
        );
    }
  }
}
