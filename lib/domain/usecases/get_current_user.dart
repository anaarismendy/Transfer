import 'package:injectable/injectable.dart';

import 'package:prueba_tecnica/core/result.dart';
import 'package:prueba_tecnica/domain/entities/user.dart';
import 'package:prueba_tecnica/domain/repositories/auth_repository.dart';
import 'package:prueba_tecnica/domain/repositories/user_repository.dart';

@lazySingleton
class GetCurrentUser {
  final AuthRepository _auth;
  final UserRepository _users;
  GetCurrentUser(this._auth, this._users);

  Future<Result<User?>> call() async {
    final session = await _auth.currentSessionUserId();
    return switch (session) {
      Err(:final failure) => Err(failure),
      Ok(value: final userId) =>
        userId == null ? const Ok(null) : await _users.getById(userId),
    };
  }
}
