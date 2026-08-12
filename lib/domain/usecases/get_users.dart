import 'package:injectable/injectable.dart';

import '../../core/result.dart';
import '../entities/user.dart';
import '../repositories/user_repository.dart';

@lazySingleton
class GetUsers {
  final UserRepository _users;
  GetUsers(this._users);

  Future<Result<List<User>>> call() => _users.getAll();
}
