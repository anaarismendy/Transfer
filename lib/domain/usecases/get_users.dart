import 'package:injectable/injectable.dart';

import 'package:prueba_tecnica/core/result.dart';
import 'package:prueba_tecnica/domain/entities/user.dart';
import 'package:prueba_tecnica/domain/repositories/user_repository.dart';

@lazySingleton
class GetUsers {
  final UserRepository _users;
  GetUsers(this._users);

  Future<Result<List<User>>> call() => _users.getAll();
}
