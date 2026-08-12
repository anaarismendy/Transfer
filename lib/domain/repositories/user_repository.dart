import '../../core/result.dart';
import '../entities/user.dart';

abstract class UserRepository {
  Future<Result<List<User>>> getAll();
  Future<Result<User?>> getById(String id);
  Future<Result<User?>> findByEmail(String email);

  Future<Result<User>> create({
    required String name,
    required String email,
    required String passwordHash,
  });

  Future<Result<User>> update(User user);
  Future<Result<void>> delete(String id);
}
