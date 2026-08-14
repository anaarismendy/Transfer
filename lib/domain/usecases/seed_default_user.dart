import 'package:injectable/injectable.dart';

import 'package:prueba_tecnica/domain/opening_balance.dart';
import 'package:prueba_tecnica/domain/repositories/user_repository.dart';
import 'package:prueba_tecnica/domain/services/password_hasher.dart';

@injectable
class SeedDefaultUser {
  static const email = 'admin@test.com';
  static const password = 'Admin123';

  final UserRepository _users;
  final PasswordHasher _hasher;
  SeedDefaultUser(this._users, this._hasher);

  Future<void> call() async {
    final existing = await _users.getAll();
    final isEmpty = existing.fold((_) => false, (users) => users.isEmpty);
    if (!isEmpty) return;

    await _users.create(
      name: 'Administrador',
      email: email,
      passwordHash: _hasher.hash(password),
      balanceInCents: openingBalanceInCents,
    );
  }
}
