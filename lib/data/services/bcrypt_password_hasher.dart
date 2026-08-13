import 'package:bcrypt/bcrypt.dart';
import 'package:injectable/injectable.dart';

import 'package:prueba_tecnica/domain/services/password_hasher.dart';

@LazySingleton(as: PasswordHasher)
class BcryptPasswordHasher implements PasswordHasher {
  @override
  String hash(String password) => BCrypt.hashpw(password, BCrypt.gensalt());

  @override
  bool verify(String password, String hash) => BCrypt.checkpw(password, hash);
}
