import 'package:injectable/injectable.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import 'package:prueba_tecnica/core/errors/failures.dart';
import 'package:prueba_tecnica/core/result.dart';
import 'package:prueba_tecnica/domain/entities/user.dart';
import 'package:prueba_tecnica/domain/repositories/user_repository.dart';
import 'package:prueba_tecnica/data/datasources/user_local_datasource.dart';

@LazySingleton(as: UserRepository)
class UserRepositoryImpl implements UserRepository {
  final UserLocalDataSource _local;
  UserRepositoryImpl(this._local);

  @override
  Future<Result<List<User>>> getAll() async {
    try {
      return Ok(await _local.getAll());
    } catch (_) {
      return const Err(StorageFailure());
    }
  }

  @override
  Future<Result<User?>> getById(String id) async {
    try {
      return Ok(await _local.getById(id));
    } catch (_) {
      return const Err(StorageFailure());
    }
  }

  @override
  Future<Result<User?>> findByEmail(String email) async {
    try {
      return Ok(await _local.findByEmail(email));
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
    final user = User(
      id: const Uuid().v4(),
      name: name.trim(),
      email: email.trim().toLowerCase(),
      passwordHash: passwordHash,
    );

    try {
      await _local.insert(user);
      return Ok(user);
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError('users.email')) {
        return const Err(DuplicateEmailFailure());
      }
      return const Err(StorageFailure());
    } catch (_) {
      return const Err(StorageFailure());
    }
  }

  @override
  Future<Result<User>> update(User user) async {
    try {
      final affected = await _local.update(user);
      return affected == 0 ? const Err(NotFoundFailure()) : Ok(user);
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError('users.email')) {
        return const Err(DuplicateEmailFailure());
      }
      return const Err(StorageFailure());
    } catch (_) {
      return const Err(StorageFailure());
    }
  }

  @override
  Future<Result<void>> delete(String id) async {
    try {
      final affected = await _local.delete(id);
      return affected == 0 ? const Err(NotFoundFailure()) : const Ok(null);
    } on DatabaseException catch (_) {
      return const Err(UserHasTransfersFailure());
    } catch (_) {
      return const Err(StorageFailure());
    }
  }
}
