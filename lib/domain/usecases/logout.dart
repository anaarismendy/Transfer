import 'package:injectable/injectable.dart';

import 'package:prueba_tecnica/core/result.dart';
import 'package:prueba_tecnica/domain/repositories/auth_repository.dart';

@lazySingleton
class Logout {
  final AuthRepository _auth;
  Logout(this._auth);

  Future<Result<void>> call() => _auth.clearSession();
}
