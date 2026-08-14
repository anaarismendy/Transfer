import 'package:injectable/injectable.dart';

import 'package:prueba_tecnica/core/errors/failures.dart';
import 'package:prueba_tecnica/core/result.dart';
import 'package:prueba_tecnica/domain/repositories/auth_repository.dart';
import 'package:prueba_tecnica/domain/repositories/user_repository.dart';

@lazySingleton
class DeleteUser {
  final UserRepository _users;
  final AuthRepository _auth;
  DeleteUser(this._users, this._auth);

  Future<Result<void>> call(String id) async {
    final session = await _auth.currentSessionUserId();
    switch (session) {
      case Err(:final failure):
        return Err(failure);
      case Ok(:final value):
        if (value == id) {
          return const Err(
            ValidationFailure(
              'No puedes eliminar el usuario con el que iniciaste sesion',
            ),
          );
        }
    }
    return _users.delete(id);
  }
}
