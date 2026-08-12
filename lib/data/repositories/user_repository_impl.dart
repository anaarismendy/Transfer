import 'package:injectable/injectable.dart';

import '../../core/errors/failures.dart';
import '../../core/result.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/user_local_datasource.dart';

@LazySingleton(as: UserRepository)
class UserRepositoryImpl implements UserRepository {
  final UserLocalDataSource _local;
  UserRepositoryImpl(this._local);

  @override
  Future<Result<List<User>>> getAll() async {
    try {
      return Ok(_local.getAll());
    } catch (_) {
      return const Err(StorageFailure());
    }
  }

  @override
  Future<Result<User?>> findByEmail(String email) async {
    try {
      return Ok(_local.findByEmail(email));
    } catch (_) {
      return const Err(StorageFailure());
    }
  }

  @override
  Future<Result<User>> create({
    required String name,
    required String email,
    required String passwordHash,
  }) async {
    try {
      final user = User(
        // ponytail: id por timestamp. Suficiente para una app local de un solo
        // proceso; si algun dia hay sincronizacion entre dispositivos, cambiar
        // a uuid v4.
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: name.trim(),
        email: email.trim().toLowerCase(),
        passwordHash: passwordHash,
      );
      await _local.save(user);
      return Ok(user);
    } catch (_) {
      return const Err(StorageFailure());
    }
  }

  @override
  Future<Result<User>> update(User user) async {
    try {
      if (_local.getById(user.id) == null) return const Err(NotFoundFailure());
      await _local.save(user);
      return Ok(user);
    } catch (_) {
      return const Err(StorageFailure());
    }
  }

  @override
  Future<Result<void>> delete(String id) async {
    try {
      if (_local.getById(id) == null) return const Err(NotFoundFailure());
      await _local.delete(id);
      return const Ok(null);
    } catch (_) {
      return const Err(StorageFailure());
    }
  }
}
