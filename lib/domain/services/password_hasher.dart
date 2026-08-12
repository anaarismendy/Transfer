abstract class PasswordHasher {
  String hash(String password);
  bool verify(String password, String hash);
}
