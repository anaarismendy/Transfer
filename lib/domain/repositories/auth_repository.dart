import 'package:prueba_tecnica/core/result.dart';

abstract class AuthRepository {
  Future<Result<void>> saveSession(String userId);
  Future<Result<String?>> currentSessionUserId();
  Future<Result<void>> clearSession();
}
