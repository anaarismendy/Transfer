import 'package:injectable/injectable.dart';

import 'package:prueba_tecnica/core/errors/failures.dart';
import 'package:prueba_tecnica/core/result.dart';
import 'package:prueba_tecnica/domain/repositories/auth_repository.dart';
import 'package:prueba_tecnica/data/datasources/session_local_datasource.dart';

@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  final SessionLocalDataSource _session;
  AuthRepositoryImpl(this._session);

  @override
  Future<Result<void>> saveSession(String userId) async {
    try {
      await _session.save(userId);
      return const Ok(null);
    } catch (_) {
      return const Err(StorageFailure());
    }
  }

  @override
  Future<Result<String?>> currentSessionUserId() async {
    try {
      return Ok(await _session.read());
    } catch (_) {
      return const Err(StorageFailure());
    }
  }

  @override
  Future<Result<void>> clearSession() async {
    try {
      await _session.clear();
      return const Ok(null);
    } catch (_) {
      return const Err(StorageFailure());
    }
  }
}
