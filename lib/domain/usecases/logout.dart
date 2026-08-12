import 'package:injectable/injectable.dart';

import '../../core/result.dart';
import '../repositories/auth_repository.dart';

@lazySingleton
class Logout {
  final AuthRepository _auth;
  Logout(this._auth);

  Future<Result<void>> call() => _auth.clearSession();
}
