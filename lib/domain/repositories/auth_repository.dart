import '../../core/result.dart';

/// Solo la sesion. Validar credenciales es una regla de negocio y vive en
/// el caso de uso, que combina UserRepository + PasswordHasher.
abstract class AuthRepository {
  Future<Result<void>> saveSession(String userId);
  Future<Result<String?>> currentSessionUserId();
  Future<Result<void>> clearSession();
}
