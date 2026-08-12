import 'package:injectable/injectable.dart';

import '../../core/errors/failures.dart';
import '../../core/result.dart';
import '../entities/user.dart';
import '../repositories/user_repository.dart';
import '../services/password_hasher.dart';
import '../validation.dart';

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
        return _users.update(
          value.copyWith(
            name: name.trim(),
            email: email.trim().toLowerCase(),
            passwordHash: newPassword == null ? null : _hasher.hash(newPassword),
          ),
        );
    }
  }
}
