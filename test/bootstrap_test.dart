import 'package:flutter_test/flutter_test.dart';
import 'package:prueba_tecnica/data/datasources/app_database.dart';
import 'package:prueba_tecnica/data/datasources/user_local_datasource.dart';
import 'package:prueba_tecnica/data/repositories/user_repository_impl.dart';
import 'package:prueba_tecnica/data/services/bcrypt_password_hasher.dart';
import 'package:prueba_tecnica/domain/entities/user.dart';
import 'package:prueba_tecnica/domain/usecases/seed_default_user.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Arranque real: base en disco, no en memoria. Verifica que el usuario
/// semilla queda usable, porque sin el no hay con que iniciar sesion.
void main() {
  late Database db;
  late UserRepositoryImpl users;
  late BcryptPasswordHasher hasher;

  setUp(() async {
    db = await AppDatabase.open();
    users = UserRepositoryImpl(UserLocalDataSource(db));
    hasher = BcryptPasswordHasher();
    // Base limpia: el archivo sobrevive entre corridas de test.
    await db.delete('transfers');
    await db.delete('users');
  });

  tearDown(() async {
    await db.close();
    await databaseFactory.deleteDatabase(db.path);
  });

  test('la base se crea en disco con las tres tablas', () async {
    final tables = await db.query('sqlite_master', where: "type = 'table'");
    final names = tables.map((t) => t['name']).toSet();

    expect(names, containsAll(['users', 'transfers', 'session']));
  });

  test('el usuario semilla puede autenticarse con las credenciales del README', () async {
    await SeedDefaultUser(users, hasher)();

    final found = await users.findByEmail(SeedDefaultUser.email);
    final admin = found.fold((f) => throw StateError(f.message), (u) => u);

    expect(admin, isA<User>());
    expect(
      hasher.verify(SeedDefaultUser.password, admin!.passwordHash),
      isTrue,
      reason: 'si esto falla, nadie puede entrar a la app',
    );
  });

  test('la semilla no duplica usuarios al reiniciar la app', () async {
    final seed = SeedDefaultUser(users, hasher);

    await seed();
    await seed();

    final all = await users.getAll();

    expect(all.fold((f) => throw StateError(f.message), (u) => u.length), 1);
  });
}
