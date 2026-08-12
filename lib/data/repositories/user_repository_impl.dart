import 'package:injectable/injectable.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

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
      return Ok(await _local.getAll());
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
      // uuid v4 y no un timestamp: en Windows el reloj tiene resolucion de
      // milisegundos, asi que dos creaciones seguidas generaban el mismo id.
      id: const Uuid().v4(),
      name: name.trim(),
      email: email.trim().toLowerCase(),
      passwordHash: passwordHash,
    );

    try {
      await _local.insert(user);
      return Ok(user);
    } on DatabaseException catch (e) {
      // El UNIQUE de la columna email es lo que garantiza que no haya
      // duplicados, no un chequeo previo en Dart: entre el chequeo y el
      // insert cabe otra escritura.
      //
      // Se nombra la columna a proposito: sin ella una colision de llave
      // primaria se reportaria como "correo duplicado" y mandaria a depurar
      // al lugar equivocado.
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
      // Borrar una fila por id solo puede fallar por la llave foranea de
      // transfers; cualquier otro error de esquema saldria en desarrollo.
      return const Err(UserHasTransfersFailure());
    } catch (_) {
      return const Err(StorageFailure());
    }
  }
}
