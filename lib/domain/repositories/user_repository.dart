import 'package:prueba_tecnica/core/result.dart';
import 'package:prueba_tecnica/domain/entities/user.dart';

abstract class UserRepository {
  Future<Result<List<User>>> getAll();
  Future<Result<User?>> getById(String id);
  Future<Result<User?>> findByEmail(String email);

  Future<Result<User>> create({
    required String name,
    required String email,
    required String passwordHash,
    required int balanceInCents,
  });

  Future<Result<User>> update(User user);
  Future<Result<void>> delete(String id);
}
