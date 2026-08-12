/// Contrato en domain para que la capa de dominio no importe bcrypt.
/// La implementacion vive en data/services.
abstract class PasswordHasher {
  String hash(String password);
  bool verify(String password, String hash);
}
