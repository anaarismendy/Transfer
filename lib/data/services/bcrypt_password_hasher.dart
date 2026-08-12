import 'package:bcrypt/bcrypt.dart';
import 'package:injectable/injectable.dart';

import '../../domain/services/password_hasher.dart';

/// bcrypt y no SHA-256: SHA esta disenado para ser rapido, lo que lo hace
/// malo para contrasenas. bcrypt es lento a proposito y genera el salt solo,
/// embebido en el hash resultante.
@LazySingleton(as: PasswordHasher)
class BcryptPasswordHasher implements PasswordHasher {
  @override
  String hash(String password) => BCrypt.hashpw(password, BCrypt.gensalt());

  @override
  bool verify(String password, String hash) => BCrypt.checkpw(password, hash);
}
