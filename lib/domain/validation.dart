import '../core/errors/failures.dart';

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

const passwordMinLength = 8;

Failure? validateName(String name) =>
    name.trim().isEmpty ? const ValidationFailure('El nombre es obligatorio') : null;

Failure? validateEmail(String email) => _emailPattern.hasMatch(email.trim())
    ? null
    : const ValidationFailure('El correo no tiene un formato valido');

Failure? validatePassword(String password) => password.length < passwordMinLength
    ? const ValidationFailure('La contrasena debe tener al menos $passwordMinLength caracteres')
    : null;

Failure? validateUserInput({
  required String name,
  required String email,
  String? password,
}) =>
    validateName(name) ??
    validateEmail(email) ??
    (password == null ? null : validatePassword(password));
