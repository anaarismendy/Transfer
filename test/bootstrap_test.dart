import 'package:flutter_test/flutter_test.dart';
import 'package:prueba_tecnica/data/datasources/app_database.dart';
import 'package:prueba_tecnica/data/datasources/user_local_datasource.dart';
import 'package:prueba_tecnica/data/repositories/user_repository_impl.dart';
import 'package:prueba_tecnica/data/services/bcrypt_password_hasher.dart';
import 'package:prueba_tecnica/domain/entities/user.dart';
import 'package:prueba_tecnica/domain/opening_balance.dart';
import 'package:prueba_tecnica/domain/usecases/seed_default_user.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database db;
  late UserRepositoryImpl users;
  late BcryptPasswordHasher hasher;

  setUp(() async {
    db = await AppDatabase.open();
    users = UserRepositoryImpl(UserLocalDataSource(db));
    hasher = BcryptPasswordHasher();
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

  test(
    'el usuario semilla puede autenticarse con las credenciales del README',
    () async {
      await SeedDefaultUser(users, hasher)();

      final found = await users.findByEmail(SeedDefaultUser.email);
      final admin = found.fold((f) => throw StateError(f.message), (u) => u);

      expect(admin, isA<User>());
      expect(
        hasher.verify(SeedDefaultUser.password, admin!.passwordHash),
        isTrue,
        reason: 'si esto falla, nadie puede entrar a la app',
      );
    },
  );

  test('la semilla no duplica usuarios al reiniciar la app', () async {
    final seed = SeedDefaultUser(users, hasher);

    await seed();
    await seed();

    final all = await users.getAll();

    expect(all.fold((f) => throw StateError(f.message), (u) => u.length), 1);
  });

  test('una base vieja con datos sobrevive a la migracion', () async {
    final path = db.path;
    await db.close();
    await databaseFactory.deleteDatabase(path);

    final old = await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(version: 1),
    );
    await old.execute('''
      CREATE TABLE users (
        id            TEXT PRIMARY KEY,
        name          TEXT NOT NULL,
        email         TEXT NOT NULL COLLATE NOCASE UNIQUE,
        password_hash TEXT NOT NULL
      )
    ''');
    await old.execute('''
      CREATE TABLE transfers (
        id                  TEXT PRIMARY KEY,
        source_user_id      TEXT NOT NULL REFERENCES users(id),
        destination_user_id TEXT NOT NULL REFERENCES users(id),
        amount_in_cents     INTEGER NOT NULL CHECK (amount_in_cents > 0),
        description         TEXT,
        created_at          INTEGER NOT NULL,
        CHECK (source_user_id <> destination_user_id)
      )
    ''');
    await old.execute(
      'CREATE TABLE session (key TEXT PRIMARY KEY, value TEXT NOT NULL)',
    );
    await old.insert('users', {
      'id': 'ana',
      'name': 'Ana',
      'email': 'ana@test.com',
      'password_hash': 'h',
    });
    await old.insert('users', {
      'id': 'luis',
      'name': 'Luis',
      'email': 'luis@test.com',
      'password_hash': 'h',
    });
    await old.insert('transfers', {
      'id': 't1',
      'source_user_id': 'ana',
      'destination_user_id': 'luis',
      'amount_in_cents': 400000,
      'created_at': 1,
    });
    await old.close();

    db = await AppDatabase.open();
    users = UserRepositoryImpl(UserLocalDataSource(db));

    final migrated = await users.getAll().then(
      (r) => r.fold((f) => throw StateError(f.message), (u) => u),
    );

    expect(migrated, hasLength(2), reason: 'nadie se pierde');
    expect(
      migrated.firstWhere((u) => u.id == 'ana').balanceInCents,
      openingBalanceInCents - 400000,
    );
    expect(
      migrated.firstWhere((u) => u.id == 'luis').balanceInCents,
      openingBalanceInCents + 400000,
    );
    expect(
      await db.query('transfers').then((r) => r.length),
      1,
      reason: 'el historial no se toca',
    );
  });
}
